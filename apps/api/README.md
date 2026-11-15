# api/

Backend NestJS (REST API) và tiến trình nền.

## Bên trong

| Mục | Mô tả |
|---|---|
| `.env.example` | Mẫu biến môi trường của API (giá trị giả). |
| `openapi/` | Hợp đồng OpenAPI sinh ra từ API, được commit để thay đổi hiện trong PR. |
| `src/` | Mã nguồn của API. |
| `test/` | Kiểm thử tích hợp và e2e của API, chạy với Postgres thật. |

## Quy tắc

- SQL chỉ nằm trong `*.repository.ts`.
- Tenant lấy từ token, không từ body.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
