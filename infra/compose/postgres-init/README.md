# postgres-init/

Script khởi tạo Postgres dev, chạy một lần bằng superuser khi volume mới được tạo (`docker-entrypoint-initdb.d`).

## Bên trong

| Mục | Mô tả |
|---|---|
| `01-roles.sql` | Tạo `rentwell_migrator` (chủ CSDL và bảng) và `rentwell_app` (role ứng dụng, RLS có hiệu lực); quyền mặc định cho bảng, sequence, hàm tạo về sau. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
