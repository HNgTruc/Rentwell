# health/

Kiểm tra sức khỏe: `GET /v1/health` trả `{"data":{"status":"ok","db":"ok"}}` (200) hoặc `degraded` (503) khi CSDL không phản hồi. Không đọc bảng nghiệp vụ nên không cần ngữ cảnh tenant.

## Bên trong

| Mục | Mô tả |
|---|---|
| `health.controller.ts` | Route, đặt mã 200/503. |
| `health.module.ts` | Khai báo module. |
| `health.repository.ts` | `select 1` qua Kysely (SQL chỉ ở repository). |
| `health.service.ts` | Gộp kết quả; lỗi CSDL thành `degraded`, không ném ra ngoài. |
| `health.service.spec.ts` | Kiểm thử ca ổn và ca CSDL lỗi. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
