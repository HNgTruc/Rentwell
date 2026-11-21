# test/

Kiểm thử tích hợp và e2e của API, chạy với Postgres thật do Testcontainers dựng (nhóm `integration` trong `vitest.config.mts`, cần Docker). `pnpm test` chạy cả unit lẫn integration; `pnpm test:unit` chỉ chạy unit, không cần Docker.

## Bên trong

| Mục | Mô tả |
|---|---|
| `concurrency/` | Kiểm thử đồng thời: không bán quá tồn. |
| `helpers/` | Hàm hỗ trợ kiểm thử: dựng dữ liệu, đăng nhập giả, `withTenant`. |
| `integration/` | Gọi endpoint thật, kiểm tra luồng nghiệp vụ. |
| `isolation/` | Chứng minh cô lập dữ liệu giữa các cửa hàng (RLS). |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
