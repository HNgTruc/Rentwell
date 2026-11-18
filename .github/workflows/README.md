# workflows/

Workflow GitHub Actions.

## Bên trong

| Mục | Mô tả |
|---|---|
| `ci.yml` | Mỗi PR và mỗi lần đẩy lên `main`. Job `quality`: gốc repo sạch, migration đóng băng không bị sửa, Prettier, ESLint, typecheck, test, build, `pnpm audit` (chặn mức cao). Job `database`: Postgres qua Compose, migration (dbmate), seed, kiểm thử SQL/RLS, kiểm role ứng dụng không vượt được RLS. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
