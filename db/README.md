# db/

Mọi thứ về cơ sở dữ liệu PostgreSQL.

## Bên trong

| Mục | Mô tả |
|---|---|
| `migrations/` | Migration SQL thuần, đánh số tăng dần (`001_init.sql`, `002_...`). |
| `seeds/` | Dữ liệu mẫu cho phát triển và kiểm thử. |
| `tests/` | Kiểm thử SQL: RLS, ràng buộc tồn kho. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
