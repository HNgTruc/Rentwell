# src/

Mã nguồn của API.

## Bên trong

| Mục | Mô tả |
|---|---|
| `common/` | Thành phần dùng chung, không chứa nghiệp vụ. |
| `config/` | Đọc và kiểm tra biến môi trường (Zod); thiếu hoặc sai thì không khởi động. |
| `database/` | Cửa duy nhất vào PostgreSQL: kết nối, giao dịch, `SET LOCAL app.tenant_id`, kiểu sinh tự động. |
| `integrations/` | Dịch vụ bên ngoài, mỗi cái sau một giao diện để đổi nhà cung cấp dễ. |
| `jobs/` | Công việc nền (BullMQ), mỗi file một việc, chạy lại không gây hại. |
| `modules/` | Các module nghiệp vụ; mỗi thư mục là một ranh giới. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
