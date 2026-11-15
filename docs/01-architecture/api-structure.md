# Cấu trúc phần API (backend)

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15
Liên quan: `monorepo-structure.md`, `system-architecture.md`, `docs/03-api/api-conventions.md`, ADR 0003 (modular monolith).

## 1. API là khối độc lập

- API là **một ứng dụng riêng** (`apps/api`): build, kiểm thử, đóng gói Docker và triển khai không phụ thuộc web, admin, mobile.
- Giao kết với client **chỉ qua hợp đồng OpenAPI**. Client không import mã của API; API không import mã của client.
- API chỉ dùng `packages/shared` (schema, kiểu, hàm thuần). Không phụ thuộc `packages/ui` hay `api-client`.
- Nhờ vậy sau này tách `apps/api` thành repo riêng chỉ là di chuyển thư mục và đổi nguồn `shared`; chưa cần làm ngay.

## 2. Sơ đồ thư mục

```
apps/api/
├── src/
│   ├── main.ts                     # Khởi động HTTP
│   ├── worker.ts                   # Khởi động tiến trình nền (cùng mã, khác điểm vào)
│   ├── app.module.ts
│   │
│   ├── config/                     # Biến môi trường, kiểm tra bằng Zod lúc khởi động
│   │   ├── env.schema.ts
│   │   └── config.module.ts
│   │
│   ├── common/                     # Dùng chung, không chứa nghiệp vụ
│   │   ├── guards/                 #   JwtAuthGuard, RolesGuard, TenantGuard
│   │   ├── interceptors/           #   request_id, logging, timeout
│   │   ├── filters/                #   Chuyển lỗi thành RFC 9457
│   │   ├── decorators/             #   @CurrentUser, @CurrentTenant, @Roles
│   │   ├── errors/                 #   Lớp lỗi nghiệp vụ + bảng mã lỗi ổn định
│   │   ├── idempotency/            #   Xử lý Idempotency-Key
│   │   └── pagination/             #   Con trỏ phân trang
│   │
│   ├── database/                   # Cửa duy nhất vào PostgreSQL
│   │   ├── database.module.ts
│   │   ├── transaction.ts          #   Mở giao dịch, SET LOCAL app.tenant_id
│   │   ├── types.generated.ts      #   Sinh tự động từ lược đồ (không sửa tay)
│   │   └── errors.ts               #   Ánh xạ mã Postgres (23505, 23514, 40001) sang lỗi nghiệp vụ
│   │
│   ├── modules/                    # Mỗi thư mục là một ranh giới nghiệp vụ
│   │   ├── auth/
│   │   ├── tenants/
│   │   ├── memberships/
│   │   ├── catalog/
│   │   ├── inventory/
│   │   ├── pricing/
│   │   ├── bookings/
│   │   ├── payments/
│   │   ├── handovers/
│   │   ├── support/
│   │   ├── notifications/
│   │   ├── files/
│   │   ├── reports/
│   │   └── audit/
│   │
│   ├── jobs/                       # Công việc nền (BullMQ), mỗi file một việc
│   │   ├── expire-holds.job.ts
│   │   ├── send-notification.job.ts
│   │   ├── reconcile-payments.job.ts
│   │   └── late-fee.job.ts
│   │
│   └── integrations/               # Dịch vụ bên ngoài, mỗi cái sau một giao diện
│       ├── payment/                #   cổng thanh toán (chưa chốt nhà cung cấp)
│       ├── storage/                #   S3/MinIO
│       ├── mail/                   #   gửi thư
│       └── maps/                   #   khoảng cách (chưa chốt nhà cung cấp)
│
├── test/
│   ├── integration/                # Gọi endpoint thật với Postgres thật
│   ├── isolation/                  # Kiểm thử cô lập tenant (RLS)
│   ├── concurrency/                # Giữ chỗ đồng thời
│   └── helpers/                    # Dựng dữ liệu, đăng nhập giả, withTenant
│
├── openapi/                        # Hợp đồng sinh ra (xem mục 7)
├── .env.example
├── nest-cli.json                   # Dockerfile của API ở infra/docker/api.Dockerfile
├── tsconfig.json
└── package.json
```

## 3. Khuôn của một module

```
modules/bookings/
├── bookings.module.ts
├── bookings.controller.ts          # Mỏng: nhận, kiểm tra, gọi service, trả
├── bookings.service.ts             # Nghiệp vụ; điều phối, không viết SQL
├── bookings.repository.ts          # Nơi DUY NHẤT viết SQL của module
├── bookings.policy.ts              # Ai được làm gì (quyền theo vai trò, sở hữu)
├── dto/                            # Schema đầu vào/đầu ra (Zod, dùng lại từ shared nếu có)
├── events/                         # Sự kiện miền phát ra (ví dụ BookingConfirmed)
├── bookings.service.spec.ts
└── index.ts                        # CHỈ xuất service công khai cho module khác
```

Quy tắc:

- Module khác chỉ import từ `index.ts`, không import sâu vào file nội bộ.
- Module không đọc bảng của module khác; cần dữ liệu thì gọi service công khai của nó.
- Việc phụ (gửi thư, ghi nhật ký, cập nhật báo cáo) đi qua sự kiện hoặc hàng đợi, không gọi chéo đồng bộ khi không cần.

## 4. Đường đi của một request

```
Client
  → interceptor: gán request_id, ghi nhật ký
  → JwtAuthGuard: xác thực token
  → TenantGuard: xác định cửa hàng từ token/phiên (KHÔNG từ body)
  → RolesGuard + policy: kiểm tra quyền
  → ValidationPipe (Zod): kiểm tra đầu vào
  → Controller
  → Service (mở giao dịch, SET LOCAL app.tenant_id)
  → Repository (SQL tham số hóa)
  → PostgreSQL (RLS lọc theo tenant)
  → Service: ghi audit nếu nhạy cảm, phát sự kiện
  → Controller: trả đúng DTO (không lộ cột nội bộ)
  ↳ Lỗi bất kỳ: filter chuyển thành RFC 9457 kèm mã lỗi ổn định và request_id
```

## 5. Phân tầng và ranh giới

| Tầng | Được làm | Không được làm |
|---|---|---|
| Controller | Kiểm tra đầu vào, gọi service, định dạng trả về | Nghiệp vụ, SQL |
| Service | Nghiệp vụ, mở giao dịch, gọi repository và service công khai khác | SQL, đọc `req` |
| Repository | SQL tham số hóa, ánh xạ dòng sang đối tượng | Nghiệp vụ, quyết định quyền |
| Policy | Quyết định quyền | Truy cập CSDL |
| Integration | Nói chuyện với dịch vụ ngoài sau một giao diện | Chứa nghiệp vụ |

Hàm thuần (tính giá, số đêm) nằm trong `packages/shared` hoặc `modules/pricing`, không phụ thuộc Nest hay CSDL.

## 6. Tiến trình nền (worker)

- Cùng mã nguồn với API nhưng **điểm vào khác** (`worker.ts`), chạy thành tiến trình riêng. Nhờ vậy API và worker mở rộng độc lập.
- Mỗi việc là một file trong `jobs/`, **idempotent** (chạy lại không gây hại), có thử lại và dead-letter.
- Việc gốc: `expire-holds` (mỗi phút), gửi thông báo, đối soát thanh toán, tính phí trễ.
- Job có tác động đến tiền hoặc tồn kho phải có kiểm thử chạy hai lần.

## 7. Hợp đồng OpenAPI

- Sinh từ decorator và schema Zod của API.
- File sinh ra nằm ở `apps/api/openapi/openapi.json` và **được commit**, để thay đổi hợp đồng hiện trong diff của PR.
- `packages/api-client` sinh từ file này. CI kiểm tra file đã cập nhật (sinh lại mà khác thì CI đỏ).
- Đổi hợp đồng phá vỡ client phải tăng phiên bản (`/v2`) hoặc đi qua quy trình ngừng dùng có thông báo.

## 8. Cấu hình và môi trường

- Tất cả biến môi trường khai báo trong `config/env.schema.ts`; thiếu hoặc sai thì **không khởi động**.
- Không đọc `process.env` rải rác; chỉ qua module `config`.
- `.env.example` liệt kê đủ biến với giá trị giả; ghi chú biến nào bắt buộc.
- Bí mật thật nằm ở môi trường chạy hoặc kho bí mật, không vào repo.
- Kết nối CSDL bằng **role ứng dụng** (không superuser, không owner bảng) để RLS có hiệu lực.

## 9. Bảo mật trong API

- Xác thực: token ngắn hạn + làm mới; mật khẩu băm bằng thuật toán mạnh (Argon2id hoặc tương đương, chốt ở ADR).
- Phân quyền hai lớp: vai trò (guard) và sở hữu (policy); RLS là lớp chặn cuối ở CSDL.
- Đầu vào: kiểm tra bằng Zod mọi nơi; từ chối trường lạ.
- Giới hạn tốc độ cho đăng nhập, đăng ký, webhook.
- Webhook: kiểm tra chữ ký trên body thô và chống trùng (skill `payment-webhook`).
- Không ghi bí mật, token, dữ liệu thẻ vào nhật ký.
- Tiêu đề bảo mật (helmet), CORS theo danh sách cho phép.
- Phụ thuộc: `pnpm audit` và dependabot.

## 10. Quan sát và gỡ lỗi

- Nhật ký có cấu trúc (JSON): `request_id`, `tenant_id`, `user_id`, tên module, thời gian.
- Lỗi nghiệp vụ trả mã ổn định (ví dụ `OUT_OF_STOCK`, `OUT_OF_DELIVERY_AREA`); lỗi không lường trước trả mã chung kèm `request_id`.
- Sentry nhận lỗi không xử lý, gắn `request_id` và tenant (không gắn dữ liệu cá nhân).
- `/health` (sống) và `/ready` (CSDL, Redis sẵn sàng) cho triển khai.

## 11. Kiểm thử

| Loại | Vị trí | Mục đích |
|---|---|---|
| Đơn vị | cạnh mã, `*.spec.ts` | Service, hàm thuần |
| Tích hợp | `test/integration/` | Endpoint với Postgres thật |
| Cô lập tenant | `test/isolation/` | Chứng minh RLS (skill `rls-isolation-test`) |
| Đồng thời | `test/concurrency/` | Không bán quá tồn |
| Hợp đồng | CI | OpenAPI không lệch |

## 12. Thêm tính năng vào API

1. Cần bảng/cột mới → thêm migration ở `db/migrations/`, sinh lại kiểu.
2. Thêm hoặc mở rộng module theo khuôn (skill `add-api-module`).
3. Thêm schema vào `packages/shared` nếu client dùng.
4. Viết kiểm thử gồm ca từ chối và ca tenant khác.
5. Sinh lại OpenAPI, commit cùng PR.
6. Cập nhật `docs/03-api/` nếu đổi quy ước.
7. Với việc nhạy cảm (tiền, quyền): rà bằng agent `tenant-isolation-reviewer` hoặc `pricing-reviewer`.

## 13. Tách thành repo riêng (khi nào, cách nào)

Chưa cần. Chỉ cân nhắc khi: đội backend tách khỏi đội frontend, hoặc chu kỳ phát hành lệch hẳn nhau. Khi đó:

1. Chuyển `apps/api`, `db/`, phần liên quan của `infra/` sang repo mới.
2. Phát hành `packages/shared` thành gói riêng để cả hai repo dùng.
3. Giữ OpenAPI làm hợp đồng; `api-client` sinh từ bản phát hành của API.
