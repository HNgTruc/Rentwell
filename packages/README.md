# packages/

Mã dùng chung, không tự chạy.

## Bên trong

| Mục | Mô tả |
|---|---|
| `api-client/` | Client gọi API sinh từ OpenAPI, dùng cho web, admin, mobile. |
| `config/` | Cấu hình dùng chung: ESLint, tsconfig, Prettier. |
| `shared/` | Zod schema, kiểu, hằng số, hàm thuần (số đêm, giá); không phụ thuộc framework. |
| `ui/` | Thành phần giao diện dùng chung cho web và admin. |

## Quy tắc

- `packages/*` không phụ thuộc `apps/*`.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
