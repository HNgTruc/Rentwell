# Tổng quan lược đồ dữ liệu

**Trạng thái:** Đã duyệt (P1) · **Cập nhật lần cuối:** 2026-11-15

File nguồn sự thật: `schema-001-init.sql` (PostgreSQL 15+, 49 bảng; bản 47 bảng đã kiểm thử trên 16, phần thêm theo proposal-004 chưa chạy thử). Sơ đồ: `erd.md`.

## 1. Nhóm bảng

| Nhóm | Bảng |
|---|---|
| Cửa hàng và tài khoản | `tenants`, `users`, `memberships`, `customer_profiles`, `verification_documents`, `user_addresses`, `device_tokens` |
| Tệp | `files` |
| Danh mục | `brands`, `suppliers`, `categories`, `attribute_definitions`, `item_types`, `item_type_images`, `item_variants` |
| Giá và chính sách | `price_tiers`, `seasonal_prices`, `cancellation_policies`, `late_fee_rules`, `delivery_fee_rules`, `delivery_fee_tiers` |
| Tồn kho | `inventory_lots`, `inventory_movements`, `inventory_calendar` |
| Đơn thuê | `bookings`, `booking_items`, `booking_status_history`, `rental_contracts`, `extensions`, `fees` |
| Bàn giao | `handovers`, `handover_lines`, `handover_photos`, `damage_claims` |
| Tiền | `payments`, `deposits`, `refunds`, `payment_webhook_events` |
| Hỗ trợ và thông báo | `support_tickets`, `ticket_messages`, `notifications` |
| Hệ thống | `audit_logs` |

## 2. Quy tắc thiết kế

1. **Mọi bảng nghiệp vụ có `tenant_id`**, khóa ngoại ghép `(tenant_id, id)`.
2. **RLS bật trên mọi bảng nghiệp vụ**, chính sách dùng `app.tenant_id` và `app.is_super_admin`.
3. **Số tiền là số nguyên (`bigint`, đơn vị đồng)**, không dùng số thực.
4. **Khoảng thuê nửa mở `[start_date, end_date)`**; số đêm là `end_date - start_date`.
5. **Sổ cái chỉ thêm:** `inventory_movements`, `booking_status_history`, `audit_logs` có trigger cấm `UPDATE`/`DELETE`.
6. **`branch_stock.quantity_usable` (tồn theo từng chi nhánh) chỉ đổi qua `inventory_movements`**, không sửa trực tiếp.
7. **`updated_at` tự cập nhật bằng trigger.**
8. **Mã đơn vị hành chính:** dùng `province_code` và `ward_code` (Việt Nam hiện có hai cấp: tỉnh/thành phố và phường/xã).
9. **Snapshot khi đặt:** đơn lưu lại giá, số đêm đệm tại thời điểm đặt, để đổi bảng giá sau không làm sai đơn cũ.

## 3. Hàm và trigger quan trọng

| Tên | Việc |
|---|---|
| `reserve_inventory` | Giữ chỗ một biến thể trong kho của một chi nhánh cho các đêm trong khoảng |
| `release_inventory` | Nhả chỗ (theo chi nhánh) |
| `swap_booking_inventory` | Đổi size tại chi nhánh: nhả món cũ, giữ món mới, cùng kho, một giao dịch (đơn `confirmed` hoặc đang thuê `handed_over`) |
| `validate_transfer_movement` | Kiểm tra phiếu chuyển hàng trước khi ghi sổ (trạng thái, chi nhánh, món) |
| `forbid_booking_branch_change` | Không cho đổi chi nhánh của đơn đã tạo |
| `reserve_booking_inventory` | Giữ chỗ cho cả đơn (mọi dòng) |
| `release_booking_inventory` | Nhả chỗ cho cả đơn |
| `expire_holds` | Nhả các đơn giữ chỗ quá hạn (gọi mỗi phút bằng worker) |
| Trigger chặn liên tỉnh | Từ chối đơn giao khác tỉnh với cửa hàng (lỗi 23514) |

Ràng buộc then chốt: `CHECK (reserved <= capacity)` trên `inventory_calendar` (tên `inventory_not_oversold`). Mã lỗi **23514** được API ánh xạ thành "hết hàng" hoặc "ngoài vùng giao".

## 4. Quy ước migration

- Migration là SQL thuần, đánh số tăng dần: `001_init.sql`, `002_...sql`.
- **Không sửa migration đã áp** ở môi trường chung; thay đổi bằng migration mới.
- Mỗi migration có thể chạy lặp lại an toàn trên máy dev sạch.
- Thay đổi lược đồ phải kèm kiểm thử SQL trong `db/tests/` (RLS, ràng buộc).
- Role ứng dụng ở môi trường thật: không superuser, không owner bảng; migration chạy bằng role riêng.

## 5. Giới hạn đã biết

Xem mục "Giới hạn cần biết" trong `erd.md`.

## 6. Việc dữ liệu cần làm sau

- Thêm `btree_gist` để chặn giá mùa chồng lấn bằng ràng buộc loại trừ (nếu cần).
- Phân vùng (`PARTITION`) cho `inventory_calendar`, `audit_logs` nếu tăng trưởng lớn.
- Chỉ mục bổ sung dựa trên `EXPLAIN` ở P8.
