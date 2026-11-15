---
name: inventory-reservation
description: Làm việc với giữ chỗ, nhả chỗ, hết hạn giữ chỗ và biến động tồn kho (inventory_calendar, inventory_movements). Dùng khi chạm tạo đơn, hủy đơn, hư hỏng, mất, nhập kho.
---

# Giữ chỗ và tồn kho

Mô hình: `docs/02-database/erd.md`, `docs/03-api/booking-pricing.md` mục 7. Đây là phần quyết định "không đặt trùng", cần cẩn thận nhất.

## Mô hình

- `inventory_calendar` (biến thể × đêm): `capacity`, `reserved`, ràng buộc **`CHECK reserved <= capacity`** (tên `inventory_not_oversold`). Đây là chốt chặn cuối cùng ở CSDL.
- `inventory_movements`: sổ cái **chỉ thêm**; `item_variants.quantity_usable` chỉ đổi qua đây (nhập, hư, mất, sửa, loại bỏ).
- Đêm bị chiếm = `[start_date, end_date + buffer_nights)`; `buffer_nights` được snapshot vào `booking_items` để nhả đúng số đêm đã giữ.

## Hàm CSDL (gọi, không tự viết lại logic ở tầng ứng dụng)

| Hàm | Dùng khi |
|---|---|
| `reserve_booking_inventory(tenant, booking)` | Tạo đơn `hold`: giữ chỗ mọi dòng |
| `release_booking_inventory(tenant, booking)` | Hủy đơn: nhả chỗ |
| `expire_holds()` | Worker chạy mỗi phút: nhả đơn quá hạn chưa thanh toán |
| `reserve_inventory` / `release_inventory` | Cấp thấp cho một biến thể; ưu tiên hàm theo đơn |

## Quy trình tạo đơn (giữ chỗ)

1. Mở giao dịch, `SET LOCAL app.tenant_id`.
2. Tính giá lại ở server; tạo `bookings` (`hold`, `hold_expires_at`) và `booking_items`.
3. Gọi `reserve_booking_inventory`. Mã lỗi `23514` → **hoàn tác toàn bộ giao dịch**, trả 409 `OUT_OF_STOCK`. Không để đơn dở dang.
4. Khóa theo **thứ tự biến thể cố định** khi đơn nhiều dòng để tránh khóa chết.
5. Commit; trả đơn kèm liên kết thanh toán.

## Biến động tồn kho (hư, mất, nhập, sửa)

- Luôn thêm dòng `inventory_movements`, không sửa `quantity_usable` trực tiếp.
- Giảm tồn xuống dưới số đã đặt ở các đêm tương lai sẽ bị CSDL chặn: đừng bắt lỗi rồi bỏ qua; báo quản lý xử lý các đơn bị ảnh hưởng (đổi món, hủy, thông báo khách) trước.
- Ghi `audit_logs` cho điều chỉnh thủ công.

## Kiểm thử bắt buộc

- Đồng thời: N yêu cầu cùng giữ một biến thể còn K → đúng K thành công, không bao giờ `reserved > capacity` (kiểm thử tải k6 hoặc nhiều giao dịch song song).
- Hủy và hết hạn nhả đúng số lượng, đúng số đêm kể cả đêm đệm.
- Bất biến: `quantity_usable` = tổng `delta_usable` trong sổ cái.
- Sổ cái không `UPDATE`/`DELETE` được.
- Giữ chỗ nhiều dòng khi một dòng hết hàng: không dòng nào được giữ.

## Lưu ý

- Lịch tồn dùng `current_date`: múi giờ DB phải là `Asia/Ho_Chi_Minh`.
- Mỗi loại món phải có ít nhất một biến thể ("Mặc định" khi không có size/màu); ứng dụng tạo khi tạo loại món.
