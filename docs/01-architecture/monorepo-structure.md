# Cấu trúc mã nguồn (Monorepo)

**Trạng thái:** Đã kiểm ở P0 (v3, 2026-11-17: bỏ Turborepo, ADR 0010) · **Cập nhật lần cuối:** 2026-11-17

## Mục tiêu thiết kế

1. **Gốc repo gọn:** chỉ có file cấu hình bắt buộc; mọi thứ khác nằm trong thư mục có tên rõ ràng.
2. **Mỗi thứ một chỗ:** đọc tên thư mục là biết trong đó có gì và vì sao.
3. **Bảo mật dễ rà:** phần nhạy cảm (xác thực, tiền, quyền) gom ở vài nơi cố định.
4. **Sửa lỗi nhanh:** từ một lỗi lần ra ngay module, không phải đi qua nhiều tầng.
5. **Mở rộng không đập đi xây lại:** thêm app hay module mới là thêm thư mục, không sửa cấu trúc cũ.
6. **Không sinh file rác:** đầu ra build, log, tệp tải lên, dữ liệu tạm có chỗ riêng và bị `.gitignore`.

## Bố cục ngoài cùng (gốc repo)

```
<gốc repo>/
├── apps/  packages/  db/  infra/  docs/     # mã, dữ liệu, hạ tầng, tài liệu
├── storage/                                 # uploads/ (dev, không vào git); assets/ (commit): images/ videos/ logo/
├── workspace/                               # CHỈ file cấu hình công cụ
│   ├── package.json
│   ├── pnpm-workspace.yaml
│   ├── pnpm-lock.yaml
│   ├── lefthook.yml  commitlint.config.mjs
│   ├── .gitignore
│   ├── .editorconfig
│   └── .env.example
├── .claude/    .github/                      # cấu hình Claude Code, GitHub
└── README.md   CLAUDE.md
```

- Mọi lệnh `pnpm` chạy trong `workspace/`; CI đặt thư mục làm việc là `workspace/`.
- `.github/` bắt buộc ở gốc (GitHub chỉ đọc workflow ở đây). `.git/` do git quy định.
- **Đã kiểm ở P0 (2026-11-17, ADR 0010), vì cấu hình nằm ngoài thư mục chứa `apps/`:**
  1. pnpm chạy tốt. **Turborepo không chạy** (từ chối package ngoài thư mục chứa `turbo.json`) nên đã bỏ, dùng `pnpm -r`.
  2. `.gitignore` không tự áp cho `apps/`: đã xử lý bằng `core.excludesFile` qua `infra/scripts/setup-git.sh` (mỗi máy chạy một lần); đã kiểm `node_modules` trong `apps/` bị bỏ qua.
  3. `.editorconfig` không áp cho `apps/`: định dạng do Prettier (`packages/config/prettier.json`) đảm nhiệm.
  4. Node không tìm thấy công cụ cài ở `workspace/node_modules` khi chạy trong package: mỗi package tự khai báo `typescript`, `vitest`, `eslint`.
  5. lefthook tìm cấu hình ở gốc repo: hook nằm ở `infra/git-hooks/` (`core.hooksPath`) và trỏ tới `workspace/lefthook.yml`.

## Sơ đồ

```
rentwell/
│
├── apps/                          # Các ứng dụng chạy được (mỗi cái triển khai riêng)
│   ├── api/                       #   Backend NestJS + worker nền
│   ├── web/                       #   Web khách hàng (Next.js)
│   ├── admin/                     #   Quản trị cửa hàng + super admin (Next.js)
│   ├── mcp/                       #   Máy chủ MCP chỉ đọc (chưa làm, sau MVP; ADR 0007)
│   └── mobile/                    #   App khách và nhân viên (Expo)
│
├── packages/                      # Mã dùng chung, không tự chạy
│   ├── shared/                    #   Zod schema, kiểu, hằng số, hàm thuần (số đêm, giá)
│   ├── api-client/                #   Client sinh từ OpenAPI cho web, admin, mobile
│   ├── ui/                        #   Thành phần giao diện dùng chung (web, admin)
│   └── config/                    #   ESLint, tsconfig, prettier dùng chung
│
├── db/                            # Mọi thứ về cơ sở dữ liệu
│   ├── migrations/                #   SQL thuần đánh số, chỉ thêm, không sửa cái đã chạy
│   ├── seeds/                     #   Dữ liệu mẫu dev/test (không dữ liệu thật)
│   └── tests/                     #   Kiểm thử SQL: RLS, ràng buộc tồn kho
│
├── infra/                         # Hạ tầng và vận hành
│   ├── docker/                    #   Dockerfile từng app
│   ├── compose/                   #   dev và prod
│   └── scripts/                   #   Triển khai, sao lưu, khôi phục
│
├── docs/                          # Tài liệu (chỉ mục: docs/README.md)
├── .claude/                       # Cấu hình Claude Code (rules, commands, agents, skills)
├── .github/                       # CI/CD, mẫu PR, CODEOWNERS, dependabot
│
├── CLAUDE.md                      # Hướng dẫn cho Claude Code
├── README.md                      # Giới thiệu và cách chạy
└── workspace/                     # package.json, pnpm-workspace.yaml, lockfile, .gitignore, .editorconfig,
                                   # .env.example, lefthook.yml (xem "Bố cục ngoài cùng")
```

Gốc repo chỉ được phép có đúng các mục ở "Bố cục ngoài cùng" (danh sách cho phép; `infra/scripts/check-root.sh`). Có mục lạ ở gốc thì CI báo lỗi, xem mục "Giữ gốc sạch" bên dưới.

## Từng ứng dụng

### `apps/api` (backend, modular monolith)

```
apps/api/
├── src/
│   ├── main.ts                    # Khởi động HTTP
│   ├── worker.ts                  # Khởi động tiến trình nền (cùng mã, khác điểm vào)
│   ├── app.module.ts
│   ├── config/                    # Đọc và kiểm tra biến môi trường (Zod), lỗi thì không khởi động
│   ├── common/                    # Guard, interceptor, bộ lọc lỗi, decorator dùng chung
│   ├── database/                  # Kết nối, giao dịch, SET LOCAL app.tenant_id, kiểu sinh tự động
│   ├── modules/                   # Mỗi thư mục là một ranh giới nghiệp vụ
│   │   ├── auth/                  #   Đăng nhập, token, mật khẩu
│   │   ├── tenants/               #   Cửa hàng, điểm nhận/trả
│   │   ├── memberships/           #   Nhân viên, vai trò, lời mời
│   │   ├── catalog/               #   Danh mục, loại món, biến thể, ảnh
│   │   ├── inventory/             #   Lô, sổ cái, lịch tồn kho
│   │   ├── pricing/               #   Bảng giá, giá mùa, phí giao (hàm thuần)
│   │   ├── bookings/              #   Đơn thuê, giữ chỗ, hợp đồng, gia hạn
│   │   ├── payments/              #   Thanh toán, cọc, hoàn tiền, webhook
│   │   ├── handovers/             #   Bàn giao, hư hỏng, phí trễ
│   │   ├── support/               #   Phiếu hỗ trợ
│   │   ├── notifications/         #   Email, push, trong ứng dụng
│   │   ├── files/                 #   Presigned URL, quản lý tệp
│   │   ├── reports/               #   Báo cáo
│   │   └── audit/                 #   Nhật ký thao tác
│   ├── jobs/                      # Công việc nền BullMQ: expire-holds, thông báo, đối soát
│   └── integrations/              # Cổng thanh toán, lưu trữ, thư, bản đồ (sau giao diện)
├── test/                          # integration/, isolation/, concurrency/, helpers/
├── openapi/                       # Hợp đồng sinh ra, được commit
├── .env.example                   # Biến riêng của api
└── package.json
```

Mỗi module có cùng khuôn: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.repository.ts`, `dto/`, `*.spec.ts`.

### `apps/web` và `apps/admin` (Next.js, App Router)

```
apps/web/                          # admin/ có cấu trúc y hệt
├── src/
│   ├── app/                       # Route (trang, layout), mỏng, chỉ ghép
│   ├── features/                  # Theo nghiệp vụ: booking/, catalog/, account/ ...
│   │   └── booking/
│   │       ├── components/        #   Giao diện riêng của tính năng
│   │       ├── hooks/             #   TanStack Query, trạng thái
│   │       └── api.ts             #   Gọi api-client
│   ├── components/                # Giao diện dùng chung riêng của app này
│   ├── lib/                       # Tiện ích, cấu hình client
│   └── styles/
├── public/                        # Tài nguyên tĩnh công khai
├── .env.example
└── package.json
```

Nguyên tắc: `app/` chỉ định tuyến; logic nằm trong `features/`. Muốn thêm tính năng là thêm một thư mục trong `features/`.

### `apps/mobile` (Expo)

```
apps/mobile/
├── app/                           # Định tuyến (expo-router)
├── src/
│   ├── features/                  # Cùng cách chia như web
│   ├── components/
│   └── lib/
├── assets/
└── package.json
```

## Dữ liệu, hạ tầng, tài liệu

- **`db/migrations`**: là nguồn sự thật duy nhất của lược đồ. Migration đã chạy thì không sửa; muốn đổi thì thêm migration mới. Có kiểm thử trong `db/tests`.
- **`infra/`**: không chứa bí mật. Bí mật nằm ở biến môi trường của môi trường chạy hoặc kho bí mật.
- **`docs/`**: giữ nguyên bố cục đã có (overview, architecture, database, api, product, devops, roadmap, quality, guides).

## Quy tắc phụ thuộc

- `apps/*` được dùng `packages/*`. `packages/*` không phụ thuộc `apps/*`.
- `packages/shared` không phụ thuộc framework, chạy được cả client và server.
- Không import chéo giữa các `apps`.
- Trong `api`: controller gọi service, service gọi repository, **repository là nơi duy nhất viết SQL**.
- Module chỉ gọi module khác qua service công khai, không đọc bảng của nhau.
- Tính giá, tính số đêm là **hàm thuần** trong `packages/shared` hoặc `modules/pricing`.

## Đặt file mới ở đâu

| Cần thêm | Đặt ở |
|---|---|
| Endpoint, nghiệp vụ mới | `apps/api/src/modules/<module>/` |
| Bảng hoặc cột mới | `db/migrations/NNN_<mô tả>.sql` |
| Schema dùng cả client và server | `packages/shared/` |
| Trang web khách | `apps/web/src/app/` (route) + `features/` (logic) |
| Màn hình quản trị | `apps/admin/src/` tương tự |
| Màn hình mobile | `apps/mobile/` |
| Thành phần giao diện dùng cả web và admin | `packages/ui/` |
| Công việc nền | `apps/api/src/jobs/` |
| Dockerfile, script triển khai | `infra/docker/`, `infra/scripts/` |
| Quyết định kiến trúc | `docs/01-architecture/adr/` |
| Kiểm thử | cạnh mã (`*.spec.ts`), tích hợp ở `apps/api/test/`, SQL ở `db/tests/` |

## Bảo mật theo cấu trúc

- **Một cửa duy nhất vào CSDL:** `database/` + `repository`. Rà RLS và tenant chỉ cần xem hai chỗ này.
- **Phần nhạy cảm gom cố định:** `auth/`, `payments/`, `memberships/`, `common/` (guard). Các thư mục này gắn `CODEOWNERS` yêu cầu rà soát bắt buộc.
- **Không bí mật trong repo:** chỉ có `.env.example` (giá trị giả). `.env*` thật bị `.gitignore` và bị chặn đọc trong `.claude/settings.json`. CI chạy quét bí mật.
- **Biến môi trường kiểm tra khi khởi động** (`config/`): thiếu hoặc sai thì dừng, không chạy nửa vời.
- **Phụ thuộc:** `dependabot` bật; `pnpm audit` trong CI.
- **Migration cần rà soát** riêng vì đổi lược đồ và RLS.

## Sửa lỗi dễ theo cấu trúc

- Lỗi API: mã lỗi ổn định → module → service → repository. Một đường đi, không vòng.
- Lỗi dữ liệu: `db/migrations` cho biết lược đồ đúng; `db/tests` tái hiện.
- Lỗi giao diện: `features/<tên>` chứa trọn một tính năng.
- Lỗi tính tiền: hàm thuần có bảng ca kiểm thử, tái hiện bằng một ca mới.
- Mỗi request có `request_id` xuyên suốt nhật ký để lần dấu.

## Mở rộng và tối ưu

- **Thêm module:** thêm thư mục trong `modules/` theo khuôn (dùng skill `add-api-module`).
- **Thêm app:** thêm thư mục trong `apps/`, dùng lại `packages/*`.
- **Tách dịch vụ sau này:** module có ranh giới rõ nên tách tiến trình nền (`worker.ts`) hoặc `payments` thành dịch vụ riêng không cần viết lại; chỉ làm khi có số đo chứng minh cần.
- **Build:** `pnpm -r` chạy theo thứ tự phụ thuộc (không có bộ nhớ đệm như Turborepo, ADR 0010); xem lại nếu CI chậm.
- **Chạy nhẹ:** web và admin tách riêng nên tải riêng; `packages/ui` chỉ chứa phần dùng chung thật.

## Giữ gốc sạch (không sinh file rác)

1. **Đầu ra build và tạm vào trong từng app** và bị bỏ qua: `dist/`, `.next/`, `.turbo/`, `coverage/`, `*.log`, `tmp/`.
2. **Tệp người dùng tải lên không vào git.** Chạy thật: lưu trữ kiểu S3 (R2 hoặc S3) qua presigned URL. Phát triển: `storage/uploads/` (bị `storage/.gitignore` chặn). Chỉ tài nguyên tĩnh của sản phẩm (logo, ảnh mẫu) được commit, ở `storage/assets/`.
3. **Không lưu dữ liệu thật trong repo**, kể cả trong `seeds/`.
4. **Không tạo file ở gốc** ngoài danh sách cho phép ở trên. Ghi chú nháp để ngoài repo hoặc trong `docs/`.
5. **Script có chỗ riêng:** `infra/scripts/`, không để rải ở gốc.
6. **Kiểm tra tự động:** một bước CI (và `/check`) so danh sách mục ở gốc với danh sách cho phép; thừa thì lỗi.
7. **Bộ `.gitignore` chuẩn** ngay từ lần commit đầu: `node_modules/`, `dist/`, `.next/`, `.turbo/`, `coverage/`, `.env`, `.env.*` (trừ `.env.example`), `*.log`, `.DS_Store`, `.claude/settings.local.json`.

## README trong mỗi thư mục

Mọi thư mục đều có `README.md` mô tả: thư mục chứa gì, bảng các mục bên trong, quy tắc riêng. Mục đích: đọc README là biết file nằm đâu, không phải mở từng thư mục. Quy ước:

- Thêm hoặc xóa mục thì cập nhật bảng trong README của thư mục đó.
- Thư mục mới phải có `README.md` ngay khi tạo.
- Ngoại lệ: thư mục con của `.claude/` (`rules/`, `commands/`, `agents/`, `skills/`) không có README riêng vì Claude Code đọc mọi file `.md` ở đó như cấu hình; mô tả của chúng nằm trong `.claude/README.md`.

## Lệnh thường dùng (dự kiến)

| Lệnh | Việc |
|---|---|
| `pnpm install` | Cài phụ thuộc |
| `docker compose -f infra/compose/docker-compose.dev.yml up -d` | Bật Postgres, Redis, Mailpit |
| `pnpm db:migrate` | Chạy migration |
| `pnpm db:seed` | Nạp dữ liệu mẫu |
| `pnpm dev` | Chạy toàn bộ app ở chế độ phát triển |
| `pnpm lint && pnpm typecheck && pnpm test` | Kiểm tra chất lượng |
| `pnpm build` | Build toàn bộ |

## Thay đổi so với bản trước

- Gộp `config-eslint` và `config-typescript` thành một `packages/config`.
- Thêm `features/` cho web, admin, mobile để logic không rải rác.
- Thêm danh sách cho phép ở gốc và kiểm tra tự động.
- Thêm các mục: đặt file ở đâu, bảo mật, sửa lỗi, mở rộng.
- Thêm `CODEOWNERS`, `.nvmrc`, `.editorconfig`, `.env.example`.
