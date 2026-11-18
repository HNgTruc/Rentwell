# migrations/

Migration SQL thuần, đánh số tăng dần (`001_init.sql`, `002_...`).

## Bên trong

| Mục | Mô tả |
|---|---|
| `001_init.sql` | Lược đồ khởi tạo: 49 bảng, RLS, hàm giữ chỗ tồn kho. Có dấu dbmate `-- migrate:up transaction:false` (file tự có BEGIN/COMMIT) và khối `-- migrate:down` rỗng. |

## Quy tắc

- Không sửa migration đã áp; thay đổi bằng migration mới. CI chặn bằng `infra/scripts/check-migrations-immutable.sh`.
- Chạy bằng dbmate: `pnpm db:migrate` (role `rentwell_migrator`, biến `DATABASE_MIGRATION_URL`). Mỗi file cần `-- migrate:up` và `-- migrate:down`.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
