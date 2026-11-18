# postgres-init/

Script khởi tạo Postgres dev, chạy một lần bằng superuser khi volume mới được tạo (`docker-entrypoint-initdb.d`).

## Bên trong

| Mục | Mô tả |
|---|---|
| `01-roles.sql` | Tạo `rentwell_migrator` (chủ CSDL và bảng) và `rentwell_app` (role ứng dụng, RLS có hiệu lực); quyền mặc định cho bảng, sequence, hàm tạo về sau. |
| `02-readonly-dev.sql` | **Chỉ dev:** `rentwell_readonly` (chỉ SELECT, BYPASSRLS, giao dịch mặc định chỉ đọc) cho MCP Postgres xem dữ liệu seed. Chạy lại an toàn trên volume đã có (lệnh ở đầu file). Không tạo ở staging, production. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
