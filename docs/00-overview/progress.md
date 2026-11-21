# Tiến độ dự án

**Cập nhật lần cuối:** 2026-11-21

## Cách dùng (để không lặp lại bước đã làm)

1. **Trước khi làm một việc**, đọc file này và mục tương ứng trong `../06-roadmap/roadmap.md`. Việc đã `[x]` thì không làm lại; chỉ kiểm tra khi có lý do.
2. **Làm xong việc nào** thì đổi `[ ]` thành `[x]` kèm ngày: `- [x] (2026-12-03) Docker Compose ...`.
3. **Nơi tick chính:** `../06-roadmap/roadmap.md` (từng công việc và tiêu chí hoàn thành). Mục 7 và mục 9 của `project-plan.md` là bản tóm tắt P0 và các quyết định; tick ở đó luôn khi xong.
4. **Giai đoạn xong khi** mọi tiêu chí hoàn thành (DoD) của nó đã `[x]`; khi đó tick dòng giai đoạn ở dưới.
5. Việc bị bỏ hoặc đổi hướng: gạch bỏ bằng `~~...~~` và ghi lý do ngắn, không xóa, để người sau biết đã cân nhắc.

## Giai đoạn thiết kế (trước P0)

- [x] (2026-11-14) Chốt tên dự án: Rentwell (chưa kiểm tra tên miền, mạng xã hội, nhãn hiệu)
- [x] (2026-11-14) Lược đồ cơ sở dữ liệu: 42 bảng, RLS, hàm giữ chỗ tồn kho (`db/migrations/001_init.sql`)
- [x] (2026-11-15) Phạm vi MVP và tầm nhìn (`scope-mvp.md`, `vision.md`)
- [x] (2026-11-15) Kế hoạch tổng và lộ trình P0 đến P8 (`project-plan.md`, `../06-roadmap/roadmap.md`)
- [x] (2026-11-15) Công nghệ đề xuất và kiến trúc (`../01-architecture/`); các điểm 🟡 chờ spike
- [x] (2026-11-15) Quy tắc tính giá, đặt thuê, quyền (`../03-api/`, `../04-product/`)
- [x] (2026-11-15) Cấu hình Claude Code: rules, commands, agents, skills (`.claude/`)
- [x] (2026-11-15) Cấu trúc thư mục dự án và bộ khung thư mục
- [x] (2026-11-15) README mô tả cho mọi thư mục
- [x] (2026-11-15) Nạp skill `ui-ux-pro-max` vào `.claude/skills/` (chờ chỉnh bối cảnh và chốt thương hiệu)
- [x] (2026-11-15) Quy tắc làm việc với Claude (có cổng thiết kế): không tự commit, hỏi trước khi thêm thành phần, làm đúng phần giao, làm theo chuẩn SEO (`../08-guides/working-agreement.md`, `../07-quality/seo.md`)

## Cổng thiết kế (người dùng thiết kế xong, Claude mới làm giao diện)

Công cụ: Figma (đọc qua MCP Figma). Thứ tự cần có: hệ thiết kế chung và màn admin đầu (đăng nhập, khung, quản lý nhân viên) **trước P1**; web khách **trước P3**; mobile **trước P6**.

- [ ] Thiết kế `apps/web` (khách) đã được người dùng duyệt
- [ ] Thiết kế `apps/admin` (quản trị) đã được người dùng duyệt
- [ ] Thiết kế `apps/mobile` (khách và nhân viên) đã được người dùng duyệt
- [ ] Hệ thiết kế chung (màu, phông, thành phần) đã được người dùng duyệt

## Tiến độ theo giai đoạn

| Xong | Giai đoạn | Thời lượng | Mốc |
|---|---|---|---|
| [ ] | P0 Khởi tạo và hạ tầng | 2 tuần | M1 Nền móng |
| [ ] | P1 Tenant, tài khoản, phân quyền | 4 tuần | M2 Cô lập tenant |
| [ ] | P2 Danh mục và tồn kho | 4 tuần | |
| [ ] | P3 Đặt thuê và tính giá | 5 tuần | M3 Đặt thuê đúng |
| [ ] | P4 Thanh toán và cọc | 3 tuần | |
| [ ] | P5 Bàn giao, giao nhận, trả đồ | 4 tuần | **M4 MVP web** |
| [ ] | P6 Mobile | 5 tuần | M5 Có app |
| [ ] | P7 CSKH, thông báo, báo cáo | 4 tuần | |
| [ ] | P8 Bảo mật, hiệu năng, ra mắt | 4 tuần | M6 Ra mắt beta |

## Việc cần quyết định (bản sao, tick tại `project-plan.md` mục 9)

- [x] (2026-11-19) Chọn cổng thanh toán: MoMo (ADR 0013), điều kiện: hộ kinh doanh đăng ký được; dự phòng payOS
- [x] (2026-11-15) Giảm theo bậc: từng dòng, giá mùa từng đêm trước rồi giảm bậc (ADR 0008)
- [x] (2026-11-15) Cơ sở cọc phần trăm: giá trị thay thế (ADR 0008)
- [x] (2026-11-15) Thanh toán đến sau khi giữ chỗ hết hạn: thử giữ lại, hết hàng thì tự hoàn tiền
- [x] (2026-11-17) Chốt 14 quy tắc nghiệp vụ: mô hình tiền (merchant riêng mỗi chuỗi), hồ sơ khách chung cơ bản, duyệt đơn tự động, giữ chỗ 15 phút, cọc thu cùng lúc, hoàn tiền 24 giờ, làm tròn, phí trễ, ngày lễ, gia hạn, đơn tại quầy, đóng chi nhánh, xác minh, giờ mở cửa (ADR 0009)
- [x] (2026-11-17) Duyệt `proposal-004` và sửa `001_init.sql` (49 bảng); phụ thu ngày lễ cộng trước giảm bậc; ngưỡng xác minh theo cọc của dòng
- [x] (2026-11-17) Chạy thử `001_init.sql` (49 bảng) và `db/tests/001_walkin_holidays_close_branch.sql` trên PostgreSQL 16.16: áp thành công, 19/19 ca đạt
- [x] (2026-11-17) Giới hạn 3 đơn `hold` chưa thanh toán mỗi người dùng toàn nền tảng
- [ ] Chọn dịch vụ bản đồ: spike P0, hướng API trả phí theo lượt có gói miễn phí (ứng viên Goong), không tự host OSRM
- [x] (2026-11-17) Công cụ migration: dbmate (đã áp `001_init.sql`, ADR 0004)
- [x] (2026-11-19) Kysely: spike RLS đạt 8/8 ca (ADR 0012)
- [x] (2026-11-21) Chọn lưu tệp, email, hosting: giả lập S3 khi dev là Garage, email Resend, VPS + Compose + Caddy (ADR 0014); R2 hay S3 khi chạy thật để P8
- [x] (2026-11-17) Duyệt tổng thể `project-plan`, `roadmap`, `tech-stack` (điểm 🟡 vẫn chờ spike)
- [x] (2026-11-17) MCP loại A: Postgres chỉ đọc (DB dev), GitHub, Figma; thêm đầu P0 sau khi có Postgres dev, mô tả để duyệt lần cuối trước khi thêm
- [ ] Cho phép thêm SDK MCP (loại B, sau MVP)
- [x] (2026-11-17) Tiêu chí spike: cổng thanh toán ưu tiên **chuỗi nhỏ tự đăng ký merchant dễ** (kèm sandbox, API hoàn tiền, webhook có chữ ký); bản đồ ưu tiên **API trả phí theo lượt có gói miễn phí** (ví dụ Goong), không tự host
- [x] (2026-11-17) Thiết kế giao diện: chủ dự án làm trên **Figma**; hệ thiết kế + màn đăng nhập, khung admin, quản lý nhân viên xong **trước P1**; web khách trước P3, mobile trước P6
- [ ] Tên miền, mạng xã hội, nhãn hiệu cho Rentwell (2026-11-17: kiểm tra tên miền trong P0, mua trước P8)
- [x] (2026-11-15) Duyệt hướng thiết kế lược đồ 002 (đánh giá, bộ phận, định tuyến) và các câu hỏi mở về đánh giá
- [x] (2026-11-15) Chốt quy tắc chi nhánh (kho riêng, chọn theo khoảng cách, đơn tại quầy, phí giao cấp chuỗi, chuyển hàng, trả đúng chi nhánh, đổi size tại chỗ)
- [x] (2026-11-15) Duyệt và sửa `001_init.sql` theo `proposal-003-branches.md` (47 bảng, đã chạy thử trên PostgreSQL 16)
- [ ] Chốt công nghệ chat thời gian thực (SSE hay WebSocket): Claude đề xuất chi tiết và hỏi lại ở đầu P7
- [ ] Rà soát pháp lý dữ liệu cá nhân (2026-11-17: Claude soạn danh sách dữ liệu và câu hỏi ở P7, chủ dự án hỏi luật sư trước P8; Claude không đưa ý kiến pháp lý)
- [x] (2026-11-15) URL công khai: một website chung, theo đường dẫn (ADR 0005)

## Ghi chú ngắn (mới nhất ở trên)

- 2026-11-21 (sau): khung `apps/web`, `apps/admin` (Next.js 16.4.6) và `apps/mobile` (Expo SDK 58, expo-router) build được; React ghim 19.3.0. Next cần `turbopack.root` và `outputFileTracingRoot` trỏ về gốc repo vì lockfile nằm ở `workspace/`. `eslint-config-next` báo peer chưa khai báo hỗ trợ ESLint 10 nhưng lint chạy đúng. Lint, typecheck, test đạt; `format:check` trên Windows báo các file cũ có CRLF (trong git vẫn LF, CI không ảnh hưởng).
- 2026-11-21: quy tắc commit theo đầy đủ Conventional Commits 1.0.0 (`../08-guides/git-workflow.md` mục 2). Rà soát tài liệu, sửa các dòng trạng thái cũ (CI đã xanh trên `main` từ 2026-11-18). Chủ dự án chốt: Garage làm giả lập S3, Resend, VPS + Compose + Caddy, duyệt Testcontainers và kysely-codegen (ADR 0014); làm khung Next.js và Expo ngay trong P0; làm cả spike tìm kiếm và spike bản đồ trong P0; thêm GitHub MCP (mô tả trước khi thêm); Claude tra tên miền; duyệt tài liệu "Nháp" theo đợt (đợt 1 trước P1); thiết kế Figma chưa bắt đầu.

- 2026-11-19: chủ dự án đã đẩy nhánh `feat/p0-foundation`, CI chạy xanh trên PR (đã gộp vào `main` bằng PR #1, `88d0a32`). ADR 0011 (GSAP cho web và admin) đã ghi từ 2026-11-18. Sửa các dòng trạng thái cũ trong tài liệu (dbmate đã chốt, bỏ OSRM tự host, bỏ MinIO, proposal-004 đã áp). Spike Kysely + RLS xong: `withTenant` (`apps/api/src/database/tenant-context.ts`), kiểm thử `apps/api/test/isolation/rls-isolation.spec.ts` 8/8 đạt trên Postgres dev bằng role ứng dụng, thêm bước chạy trong CI job `database`; ADR 0012. Còn chờ duyệt: Testcontainers, kysely-codegen. MCP loại A chờ mô tả chi tiết rồi duyệt. Sau đó: role `rentwell_readonly` (chỉ dev, BYPASSRLS, chỉ đọc) trong `infra/compose/postgres-init/02-readonly-dev.sql`, đã áp vào volume dev và kiểm tra (đọc được, ghi bị chặn); bản so sánh cổng thanh toán `../03-api/payment-gateways.md` (payOS không có API hoàn tiền), chủ dự án chọn MoMo (ADR 0013). MCP: chọn Postgres MCP Pro (crystaldba), thêm ở phạm vi local trên máy (không cần `.mcp.json` ở gốc repo).
- 2026-11-17 (P0 tuần 1): monorepo pnpm (Turborepo không chạy với `workspace/`, bỏ theo ADR 0010; TypeScript ghim 6.0 vì typescript-eslint chưa hỗ trợ 7); `packages/config`, `packages/shared`; Compose dev (Postgres 16, Redis, Mailpit; MinIO không còn image, chờ chọn thay thế); dbmate áp 001 bằng role migrator; seed; khung NestJS + health + Swagger + log JSON; lefthook + commitlint; CI viết xong (chưa chạy trên GitHub). Lint, typecheck, test (12 ca), kiểm thử SQL đều đạt trên máy. (Sau đó đã commit lên nhánh `feat/p0-foundation`.)
- 2026-11-17 (cuối): duyệt `project-plan`, `roadmap`, `tech-stack`; chọn MCP loại A (thêm đầu P0); thiết kế bằng Figma trước P1; chốt tiêu chí spike thanh toán và bản đồ; cập nhật skill `pricing-calculation`, `cases.md` và rule `pricing-money.md` theo ADR 0009. Chạy thử SQL: chờ chủ dự án bật Docker Desktop.
- 2026-11-17 (sau): duyệt proposal-004, đã sửa `001_init.sql` (thêm `holidays`, `holiday_surcharges`, khách vãng lai, `verification_min_deposit`, trigger đóng chi nhánh, CHECK `opening_hours`) và chép sang `docs/02-database/schema-001-init.sql`; viết `db/tests/001_walkin_holidays_close_branch.sql`. Đã chạy thử cùng ngày trên PostgreSQL 16.16 (container tạm): 49 bảng, 19/19 ca kiểm thử đạt.
- 2026-11-17: rà soát toàn bộ tài liệu trước P0. Chủ dự án chốt 14 quy tắc nghiệp vụ (ADR 0009). Viết `proposal-004` (chờ duyệt, chưa sửa `001_init.sql`). Phát hiện `users` và `user_addresses` đã nằm ngoài tenant nên hồ sơ khách chung gần như khớp lược đồ sẵn. Dọn mâu thuẫn: số bảng 47, trạng thái đầu file, tick việc đã xong. Giả định cần xác nhận: phụ thu ngày lễ cộng trước giảm bậc.

- 2026-11-15: chốt quy tắc giá và cọc (ADR 0008). Cổng thanh toán: so sánh ở spike P0.
- 2026-11-15: chốt 3 ngoại lệ phía khách: tiền về trễ (giữ lại nếu còn, hết thì hoàn); đổi size cả khi đang thuê (đã sửa `swap_booking_inventory` trong `001_init.sql`, chạy thử đúng); khách không đến nhận (hết ngày nhận thì hủy, hoàn cọc, giữ tiền thuê).
- 2026-11-15: chốt quyền theo chi nhánh: owner tạo/đóng chi nhánh, manager chuỗi sửa cài đặt chi nhánh; manager CN duyệt phiếu chuyển xuất từ chi nhánh mình, quản lý staff/warehouse/support của chi nhánh mình, chỉ xem giá. Đã sửa `roles-permissions.md`.
- 2026-11-15: chưa bắt đầu P0, chủ dự án còn chỉnh tài liệu. Máy đã có Node LTS, pnpm, Docker Desktop, Git. Giữ `.gitignore` trong `workspace/` (mỗi máy chạy `git config core.excludesFile workspace/.gitignore`). Đã cập nhật skill `inventory-reservation` và rule `database.md` theo lược đồ chi nhánh.
- 2026-11-15: thêm skill `clean-code` (đã duyệt). Bỏ đề xuất `review-code`.
- 2026-11-15: chủ dự án chọn làm máy chủ MCP loại B (sau MVP, 6 công cụ chỉ đọc, mở rộng được). Đã ghi ADR 0007 và roadmap; chưa thêm thư viện hay mã.
- 2026-11-15: đã sửa `001_init.sql` (chi nhánh, kho riêng, chuyển hàng, đổi size) và đồng bộ `docs/02-database/schema-001-init.sql`. Còn lại: cập nhật skill `inventory-reservation` và rule `database.md` (chờ duyệt vì nằm trong `.claude/`).
- 2026-11-15: chủ dự án chốt 8 điểm về chi nhánh. Đã viết lại `proposal-003` (quy tắc, luồng đặt, quy trình chuyển hàng, danh sách sửa `001_init.sql`); **chưa sửa file SQL, chờ duyệt**.
- 2026-11-15: chủ dự án làm rõ: tenant là chuỗi nhiều chi nhánh; đơn online gán chi nhánh gần khách nhất; thuê ở đâu trả ở đó (cả online và tại quầy). Đã viết ADR 0006 và đề xuất lược đồ 003, **chờ duyệt trước khi sửa `001_init.sql`**.
- 2026-11-15: chủ dự án duyệt: đánh giá công khai toàn nền tảng (người chưa đăng nhập cũng xem), cửa hàng được trả lời, bộ phận mặc định giữ nguyên, chat chốt công nghệ ở P7; một website chung cho mọi cửa hàng (ADR 0005).
- 2026-11-15: chủ dự án quyết định thêm đánh giá (P6), định tuyến theo bộ phận và chat trên nền phiếu (P7); lộ trình dài thêm khoảng 3 tuần (ước lượng). Đã viết đề xuất, chờ duyệt.
- 2026-11-15: hoàn tất thiết kế và khung thư mục; chưa có mã ứng dụng. Việc tiếp theo là P0, tuần 1.
