# helpers/

Hàm hỗ trợ kiểm thử: dựng dữ liệu, đăng nhập giả, `withTenant`.

## Bên trong

| Mục | Mô tả |
|---|---|
| `postgres.global-setup.ts` | Global setup của nhóm test `integration`: bật Postgres 16.16 tạm bằng Testcontainers, tạo role (`infra/compose/postgres-init/`), chạy migration bằng dbmate, nạp seed; đưa URL role ứng dụng qua `inject('appDatabaseUrl')`. Cần Docker (ADR 0014). |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
