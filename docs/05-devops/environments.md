# Môi trường

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-21

| Môi trường | Mục đích | Hạ tầng | Dữ liệu |
|---|---|---|---|
| `local` | Phát triển | Docker Compose (Postgres, Redis, Mailpit, Garage) | Seed giả |
| `ci` | Kiểm thử tự động | Dịch vụ tạm trong GitHub Actions, Testcontainers | Tạo mới mỗi lần chạy |
| `staging` | Thử trước khi phát hành | Giống production, quy mô nhỏ | Dữ liệu giả, không dùng dữ liệu thật |
| `production` | Người dùng thật | VPS + Docker Compose + Caddy (giai đoạn đầu, ADR 0014) | Dữ liệu thật, sao lưu |

## Dịch vụ cục bộ (Docker Compose)

| Dịch vụ | Dùng cho |
|---|---|
| PostgreSQL 16 | CSDL (timezone `Asia/Ho_Chi_Minh`) |
| Redis | Hàng đợi, giới hạn tần suất |
| Garage | Giả lập S3 (ảnh, tệp), thay MinIO đã ngừng phát hành image (ADR 0014); chưa thêm vào Compose |
| Mailpit | Hộp thư giả để xem email gửi ra |

## Biến môi trường

- Mỗi app có file `.env.example` liệt kê đủ biến; `.env` không commit.
- API kiểm tra biến bằng Zod khi khởi động, thiếu hoặc sai thì **dừng ngay** với thông báo rõ.
- Bí mật (khóa JWT, khóa cổng thanh toán, khóa S3) khác nhau giữa các môi trường; production lưu ở kho bí mật của nền tảng triển khai, không nằm trong repo.

Nhóm biến chính: `DATABASE_URL` (role ứng dụng), `DATABASE_MIGRATION_URL` (role migration), `REDIS_URL`, `JWT_*`, `S3_*`, `PAYMENT_*`, `MAIL_*`, `MAPS_*`, `SENTRY_DSN`.

## Quy tắc

- Không dùng dữ liệu thật ở `local` và `staging`.
- Cổng thanh toán: `local` và `staging` dùng sandbox.
- Hai role CSDL tách biệt: role **migration** (chủ sở hữu bảng) và role **ứng dụng** (không superuser, không owner) để RLS có hiệu lực.
- Múi giờ DB và server đều `Asia/Ho_Chi_Minh`; thời gian lưu dạng `timestamptz`.
