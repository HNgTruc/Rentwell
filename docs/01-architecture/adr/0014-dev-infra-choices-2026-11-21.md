# ADR 0014: Giả lập S3, email, hosting và thư viện kiểm thử DB

**Trạng thái:** Chấp nhận (2026-11-21) · **Người quyết:** chủ dự án, Claude đề xuất

## Bối cảnh

Sau P0 tuần 1 còn bốn điểm 🟡 trong `../tech-stack.md` chưa chốt:

- Image MinIO cộng đồng đã ngừng phát hành, dev chưa có giả lập lưu trữ kiểu S3 (cần trước P2: ảnh sản phẩm, giấy tờ xác minh).
- Dịch vụ email giao dịch khi chạy thật (dev đã có Mailpit).
- Hạ tầng chạy thật giai đoạn đầu.
- Hai thư viện chờ duyệt từ spike Kysely + RLS (ADR 0012): Testcontainers và kysely-codegen.

## Quyết định

| Hạng mục | Chọn | Ghi chú |
|---|---|---|
| Giả lập S3 khi dev | **Garage** chạy trong Docker Compose | Chỉ dùng ở `local` và `ci`. Chạy thật vẫn là S3-compatible (Cloudflare R2 hoặc S3). Code chỉ nói chuyện qua API S3 nên đổi nơi lưu không phải sửa code |
| Email khi chạy thật | **Resend** | Dev vẫn dùng Mailpit. Module `integrations/mail/` đặt sau một giao diện chung để đổi nhà cung cấp được |
| Hosting giai đoạn đầu | **Một VPS + Docker Compose + Caddy** (HTTPS tự động) | Chọn Caddy thay Traefik vì cấu hình ngắn hơn với số dịch vụ ít |
| Kiểm thử tích hợp | **Testcontainers** (Postgres thật, tạo mới mỗi lần chạy) | Thay cho việc chạy test trên Postgres dev dùng chung |
| Kiểu DB | **kysely-codegen** sinh kiểu TypeScript từ lược đồ sau mỗi migration | Kiểu luôn khớp `db/migrations/`, không viết tay |

## Phương án đã cân nhắc

- Giả lập S3: SeaweedFS (cấu hình phức tạp hơn nhu cầu dev); bucket R2 riêng cho dev (cần mạng và tài khoản, CI phải giữ khóa).
- Email: Amazon SES (rẻ khi gửi nhiều nhưng phải xin ra khỏi sandbox, cấu hình AWS nặng); SMTP chung chọn sau.
- Hosting: PaaS như Railway, Fly.io, Render (ít vận hành hơn nhưng đắt hơn khi có Postgres, Redis và worker).

## Hệ quả

- Thư viện mới (Testcontainers, kysely-codegen) được thêm ở bước làm tương ứng của P0, mỗi việc một nhánh; ghi phiên bản cụ thể lúc thêm.
- Garage giấy phép AGPL; chỉ dùng làm công cụ dev, không phân phối kèm sản phẩm.
- Testcontainers cần Docker ở máy dev và trên runner CI (GitHub Actions `ubuntu-latest` có sẵn).
- Khi chạy thật trên VPS: tự lo sao lưu (`pg_dump` định kỳ, thử khôi phục) và cập nhật bảo mật hệ điều hành. Khi cần mở rộng thì chuyển sang dịch vụ quản lý (tech-stack mục 7).
- Còn để ngỏ: chọn R2 hay S3 cho chạy thật (quyết ở P8).
