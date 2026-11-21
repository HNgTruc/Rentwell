# database/

Cửa duy nhất vào PostgreSQL: kết nối, giao dịch, `SET LOCAL app.tenant_id`, kiểu sinh tự động.

## Bên trong

| Mục | Mô tả |
|---|---|
| `database.module.ts` | Pool `pg` + Kysely có kiểu (token `DB`, kiểu `Database = Kysely<DB>`), đóng pool khi tắt app. |
| `db.generated.ts` | Kiểu bảng sinh bởi kysely-codegen (`pnpm db:codegen` sau mỗi migration). Không sửa tay, không định dạng bằng Prettier; CI kiểm khớp bằng `db:codegen:verify`. |
| `tenant-context.ts` | `withTenant(db, tenantId, fn)`: mở giao dịch, `set_config('app.tenant_id', $1, true)` (bằng `SET LOCAL`), chạy `fn`. ADR 0012. |
| `tenant-context.spec.ts` | Bảng ca cho `assertTenantId` (chỉ nhận UUID). |

## Quy tắc

- Kết nối bằng role ứng dụng (`DATABASE_URL`), không bằng role migration.
- Kiểu sinh tự động không sửa tay.
- Ánh xạ lỗi Postgres (23505, 23514, 40001) sang lỗi nghiệp vụ ở đây.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
