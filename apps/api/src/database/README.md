# database/

Cửa duy nhất vào PostgreSQL: kết nối, giao dịch, `SET LOCAL app.tenant_id`, kiểu sinh tự động.

## Bên trong

| Mục | Mô tả |
|---|---|
| `database.module.ts` | Pool `pg` + Kysely (token `DB`), đóng pool khi tắt app. Chưa có `withTenant` và kiểu sinh: làm ở spike P0 tuần 2. |

## Quy tắc

- Kết nối bằng role ứng dụng (`DATABASE_URL`), không bằng role migration.
- Kiểu sinh tự động không sửa tay.
- Ánh xạ lỗi Postgres (23505, 23514, 40001) sang lỗi nghiệp vụ ở đây.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
