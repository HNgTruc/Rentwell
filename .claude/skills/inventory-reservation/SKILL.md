---
name: inventory-reservation
description: Làm việc với giữ chỗ, nhả chỗ, hết hạn giữ chỗ, đổi size, chuyển hàng giữa chi nhánh và biến động tồn kho theo chi nhánh (branch_stock, inventory_calendar, inventory_movements, stock_transfers). Dùng khi chạm tạo đơn, hủy đơn, đổi size, hư hỏng, mất, nhập kho, chuyển kho.
---

# Giữ chỗ và tồn kho

Mô hình: `docs/02-database/erd.md`, `docs/02-database/proposal-003-branches.md` (chi nhánh, chuyển hàng, đổi size), `docs/03-api/booking-pricing.md` mục 7. Đây là phần quyết định "không đặt trùng", cần cẩn thận nhất.

## Mô hình

- **Mỗi chi nhánh một kho.** Đơn thuộc đúng một chi nhánh (`bookings.branch_id`, không đổi được sau khi tạo); giữ chỗ chỉ trong kho chi nhánh đó, không tách đơn.
- `branch_stock` (chi nhánh × biến thể): `quantity_usable`, **chỉ đổi qua `inventory_movements`** (trigger `apply_inventory_movement`).
- `inventory_calendar` (chi nhánh × biến thể × đêm, khóa chính `(branch_id, variant_id, night)`): `capacity`, `reserved`, ràng buộc **`CHECK reserved <= capacity`** (tên `inventory_not_oversold`). Đây là chốt chặn cuối cùng ở CSDL. `capacity` các đêm từ hôm nay tự đồng bộ theo `branch_stock` (trigger `sync_calendar_capacity`).
- `inventory_movements`: sổ cái **chỉ thêm**, luôn có `branch_id` (nhập, hư, mất, sửa, loại bỏ, `transfer_out`, `transfer_in`).
- Đêm bị chiếm = `[start_date, end_date + buffer_nights)`; `buffer_nights` được snapshot vào `booking_items` để nhả đúng số đêm đã giữ.

## Hàm CSDL (gọi, không tự viết lại logic ở tầng ứng dụng)

| Hàm | Dùng khi |
|---|---|
| `reserve_booking_inventory(tenant, booking)` | Tạo đơn `hold`: giữ chỗ mọi dòng |
| `release_booking_inventory(tenant, booking)` | Hủy đơn: nhả chỗ |
| `expire_holds()` | Worker chạy mỗi phút: nhả đơn quá hạn chưa thanh toán |
| `reserve_inventory` / `release_inventory` `(tenant, branch, variant, start, end, qty)` | Cấp thấp cho một biến thể tại một chi nhánh; ưu tiên hàm theo đơn |
| `swap_booking_inventory(tenant, booking, from_variant, to_variant, qty)` | Đổi size tại chi nhánh: chỉ đơn `confirmed`, cùng mẫu, cùng kho; sau đó app cập nhật `booking_items` và ghi `booking_item_swaps` trong cùng giao dịch |

## Quy trình tạo đơn (giữ chỗ)

1. Mở giao dịch, `SET LOCAL app.tenant_id`.
2. Tính giá lại ở server; tạo `bookings` (`hold`, `hold_expires_at`) và `booking_items`.
3. Gọi `reserve_booking_inventory`. Mã lỗi `23514` → **hoàn tác toàn bộ giao dịch**, trả 409 `OUT_OF_STOCK`. Không để đơn dở dang.
4. Khóa theo **thứ tự biến thể cố định** khi đơn nhiều dòng để tránh khóa chết.
5. Commit; trả đơn kèm liên kết thanh toán.

## Biến động tồn kho (hư, mất, nhập, sửa)

- Luôn thêm dòng `inventory_movements` (có `branch_id`), không sửa `branch_stock.quantity_usable` trực tiếp.
- Giảm tồn xuống dưới số đã đặt ở các đêm tương lai sẽ bị CSDL chặn: đừng bắt lỗi rồi bỏ qua; báo quản lý xử lý các đơn bị ảnh hưởng (đổi món, hủy, thông báo khách) trước.
- Ghi `audit_logs` cho điều chỉnh thủ công.

## Chuyển hàng giữa chi nhánh (nghiệp vụ Kho)

- Phiếu `stock_transfers`: `requested` → `approved` (manager) → `in_transit` → `received` (hoặc `rejected`, `cancelled`).
- Xuất: ghi `transfer_out` ở chi nhánh nguồn khi phiếu `approved` (trigger `validate_transfer_movement` chặn sai trạng thái, sai chi nhánh, món không thuộc phiếu), rồi chuyển phiếu sang `in_transit`.
- Nhận: ghi `transfer_in` ở chi nhánh đích khi phiếu `in_transit`, rồi `received`. Thiếu hoặc hỏng: ghi `lost`/`damaged` có `transfer_id`.
- Không xuất quá số còn trống cho các đêm tương lai: CSDL chặn bằng `inventory_not_oversold`; trả lỗi dễ hiểu, không bỏ qua.

## Kiểm thử bắt buộc

- Đồng thời: N yêu cầu cùng giữ một biến thể còn K → đúng K thành công, không bao giờ `reserved > capacity` (kiểm thử tải k6 hoặc nhiều giao dịch song song).
- Hủy và hết hạn nhả đúng số lượng, đúng số đêm kể cả đêm đệm.
- Bất biến: `branch_stock.quantity_usable` = tổng `delta_usable` trong sổ cái, theo từng (chi nhánh, biến thể).
- Kho riêng: giữ hết hàng ở chi nhánh A không ảnh hưởng chi nhánh B.
- Đổi size: hết size mới thì không đổi gì (giao dịch hoàn tác); tổng `reserved` không đổi.
- Chuyển kho: đúng thứ tự trạng thái; hàng đang chuyển không dùng được ở cả hai chi nhánh.
- Sổ cái không `UPDATE`/`DELETE` được.
- Giữ chỗ nhiều dòng khi một dòng hết hàng: không dòng nào được giữ.

## Lưu ý

- Lịch tồn dùng `current_date`: múi giờ DB phải là `Asia/Ho_Chi_Minh`.
- Mỗi loại món phải có ít nhất một biến thể ("Mặc định" khi không có size/màu); ứng dụng tạo khi tạo loại món.
