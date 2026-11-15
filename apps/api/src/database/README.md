# database/

Cửa duy nhất vào PostgreSQL: kết nối, giao dịch, `SET LOCAL app.tenant_id`, kiểu sinh tự động.

_Chưa có nội dung (sẽ làm ở giai đoạn tương ứng)._

## Quy tắc

- Kiểu sinh tự động không sửa tay.
- Ánh xạ lỗi Postgres (23505, 23514, 40001) sang lỗi nghiệp vụ ở đây.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
