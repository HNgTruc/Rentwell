---
paths:
  - "db/**"
  - "apps/api/src/database/**"
  - "apps/api/src/**/*.repository.ts"
---

# Quy tắc cơ sở dữ liệu

- Migration là SQL thuần, đánh số tăng dần (`002_...sql`). **Không sửa migration đã áp.**
- Bảng nghiệp vụ mới: có `tenant_id`, khóa ngoại ghép `(tenant_id, id)`, bật RLS và viết chính sách dùng `app.tenant_id` và `app.is_super_admin`.
- Tiền là `bigint` (đồng). Thời gian là `timestamptz`. Khoảng thuê là `[start_date, end_date)`.
- Sổ cái (`inventory_movements`, `booking_status_history`, `audit_logs`) chỉ thêm, có trigger cấm sửa/xóa.
- `item_variants.quantity_usable` chỉ đổi qua `inventory_movements`.
- Mỗi migration kèm kiểm thử trong `db/tests/` (RLS, ràng buộc).
- Repository là nơi duy nhất viết SQL; mọi truy vấn chạy trong giao dịch đã `SET LOCAL app.tenant_id`.
- Truy vấn tham số hóa, không nối chuỗi.
- Sau migration, chạy lại codegen kiểu (kysely-codegen).
