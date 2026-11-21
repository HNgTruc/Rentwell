# compose/

docker-compose cho dev (prod làm ở P8).

## Bên trong

| Mục | Mô tả |
|---|---|
| `docker-compose.dev.yml` | Postgres 16, Redis 7, Mailpit (xem thư ở http://localhost:8025), Garage (S3 ở http://127.0.0.1:3900). Cổng chỉ mở cho 127.0.0.1. Chạy: `pnpm db:up` trong `workspace/`, lần đầu thêm `pnpm storage:init`. |
| `garage/` | `garage.toml`: cấu hình Garage node đơn (ADR 0014); khóa là giá trị giả cho dev. |
| `postgres-init/` | Chạy một lần khi tạo volume: role `rentwell_migrator` (chủ bảng), `rentwell_app` (ứng dụng, không superuser, không chủ bảng) và `rentwell_readonly` (chỉ đọc, chỉ dev). |

## Quy tắc

- Mật khẩu ở đây là giá trị giả cho dev/CI. Môi trường thật dùng kho bí mật.
- Đổi file trong `postgres-init/` thì phải xóa volume để chạy lại: `docker compose -f ../infra/compose/docker-compose.dev.yml down -v` (mất dữ liệu dev).
- Lưu trữ tệp kiểu S3 là Garage (thay MinIO đã ngừng phát hành image). Ứng dụng kết nối path-style, region `garage`, bucket `rentwell-dev`; biến `S3_*` ở `docs/05-devops/environments.md`.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
