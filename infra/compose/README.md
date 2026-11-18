# compose/

docker-compose cho dev (prod làm ở P8).

## Bên trong

| Mục | Mô tả |
|---|---|
| `docker-compose.dev.yml` | Postgres 16, Redis 7, Mailpit (xem thư ở http://localhost:8025). Cổng chỉ mở cho 127.0.0.1. Chạy: `pnpm db:up` trong `workspace/`. |
| `postgres-init/` | Chạy một lần khi tạo volume: role `rentwell_migrator` (chủ bảng) và `rentwell_app` (ứng dụng, không superuser, không chủ bảng). |

## Quy tắc

- Mật khẩu ở đây là giá trị giả cho dev/CI. Môi trường thật dùng kho bí mật.
- Đổi file trong `postgres-init/` thì phải xóa volume để chạy lại: `docker compose -f ../infra/compose/docker-compose.dev.yml down -v` (mất dữ liệu dev).
- Chưa có lưu trữ tệp kiểu S3: image MinIO cộng đồng đã ngừng phát hành; chờ chốt thay thế trước P2.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
