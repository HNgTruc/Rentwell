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
| Garage v2.5 | Giả lập S3 (ảnh, tệp), thay MinIO đã ngừng phát hành image (ADR 0014). Lần đầu chạy `pnpm storage:init` |
| Mailpit | Hộp thư giả để xem email gửi ra |

## Biến môi trường

- Mỗi app có file `.env.example` liệt kê đủ biến; `.env` không commit.
- API kiểm tra biến bằng Zod khi khởi động, thiếu hoặc sai thì **dừng ngay** với thông báo rõ.
- Bí mật (khóa JWT, khóa cổng thanh toán, khóa S3) khác nhau giữa các môi trường; production lưu ở kho bí mật của nền tảng triển khai, không nằm trong repo.

Nhóm biến chính: `DATABASE_URL` (role ứng dụng), `DATABASE_MIGRATION_URL` (role migration), `REDIS_URL`, `JWT_*`, `S3_*` (dev: xem dưới), `PAYMENT_*`, `MAIL_*`, `MAPS_*`, `SENTRY_DSN`.

Giá trị `S3_*` khi dev (giả, khớp `infra/scripts/garage-init.sh`):

```
S3_ENDPOINT=http://127.0.0.1:3900
S3_REGION=garage
S3_BUCKET=rentwell-dev
S3_ACCESS_KEY_ID=GKce36af4d41dcddb051e67991
S3_SECRET_ACCESS_KEY=68f0ed1f6905645a112fbbbcf307aced149a8f3d3256605ee59fef0dcdf251b7
S3_FORCE_PATH_STYLE=true
```

## Quy tắc

- Không dùng dữ liệu thật ở `local` và `staging`.
- Cổng thanh toán: `local` và `staging` dùng sandbox.
- Hai role CSDL tách biệt: role **migration** (chủ sở hữu bảng) và role **ứng dụng** (không superuser, không owner) để RLS có hiệu lực.
- Múi giờ DB và server đều `Asia/Ho_Chi_Minh`; thời gian lưu dạng `timestamptz`.
