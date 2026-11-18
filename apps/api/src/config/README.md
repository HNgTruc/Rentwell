# config/

Đọc và kiểm tra biến môi trường (Zod); thiếu hoặc sai thì không khởi động.

## Bên trong

| Mục | Mô tả |
|---|---|
| `config.module.ts` | Module toàn cục, cung cấp `APP_CONFIG`. |
| `env.ts` | Lược đồ Zod và hàm thuần `parseEnv` (thông báo lỗi chỉ nêu tên biến, không in giá trị). |
| `env.spec.ts` | Kiểm thử bảng ca: mặc định, ép kiểu, từ chối giá trị sai, không lộ bí mật. |

## Quy tắc

- Không đọc `process.env` ở nơi khác.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
