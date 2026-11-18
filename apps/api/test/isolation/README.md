# isolation/

Chứng minh cô lập dữ liệu giữa các cửa hàng (RLS).

## Bên trong

| Mục | Mô tả |
|---|---|
| `rls-isolation.spec.ts` | Spike P0 (ADR 0012): `withTenant` trên Postgres thật. Không có ngữ cảnh thì 0 dòng; không rò giữa các giao dịch trên cùng kết nối, kể cả khi rollback; chạy song song không lẫn tenant; chặn ghi chéo tenant. |

## Chạy

Cần CSDL đã migrate và seed (`pnpm db:up && pnpm db:migrate && pnpm db:seed` trong `workspace/`), rồi đặt biến (giá trị giả của dev):

```
RLS_TEST_DATABASE_URL=postgres://rentwell_app:app_dev@127.0.0.1:5432/rentwell?sslmode=disable
```

Không có biến thì các ca này tự bỏ qua. CI job `database` có đặt biến này.

## Quy tắc

- Kết nối bằng role ứng dụng, không phải superuser.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
