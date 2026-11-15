# Rentwell

Nền tảng cho thuê đồ đa cửa hàng (multi-tenant). Monorepo: API NestJS, web và admin Next.js, mobile Expo, PostgreSQL có RLS.
Giai đoạn hiện tại: xem `docs/06-roadmap/roadmap.md` (làm theo thứ tự P0 đến P8).

## Đọc trước khi làm

- Kế hoạch tổng: `docs/00-overview/project-plan.md`
- Công nghệ và lý do: `docs/01-architecture/tech-stack.md`
- Lược đồ dữ liệu (nguồn sự thật): `db/migrations/` và `docs/02-database/`
- Tính giá, tồn kho: `docs/03-api/booking-pricing.md`
- Quy ước: `docs/08-guides/conventions.md`

## Bố cục repo

Gốc repo: `apps/`, `packages/`, `db/`, `infra/`, `docs/` (mã và tài liệu), `storage/` (ảnh, video, tệp media), `workspace/` (chỉ file cấu hình công cụ: `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `.gitignore`, `.editorconfig`, `.env.example`), cùng `.claude/`, `.github/`, `README.md`, `CLAUDE.md`. Lệnh `pnpm` và `turbo` chạy trong `workspace/`.

## Lệnh thường dùng

```
cd workspace
pnpm install
docker compose -f infra/compose/docker-compose.dev.yml up -d
pnpm db:migrate        # chạy migration
pnpm db:seed           # nạp dữ liệu mẫu
pnpm dev               # chạy tất cả app
pnpm lint && pnpm typecheck && pnpm test
```

## Quy tắc bắt buộc

1. **Tiền là số nguyên đồng**, không dùng số thực. Ngày thuê là `YYYY-MM-DD`; số đêm = `end_date - start_date`.
2. **Mọi truy vấn nghiệp vụ nằm trong giao dịch có `SET LOCAL app.tenant_id`.** Không bao giờ tin `tenant_id` từ client.
3. **SQL chỉ viết trong repository.** Controller mỏng, service chứa nghiệp vụ.
4. **Không sửa migration đã áp**; thay đổi lược đồ bằng migration mới, kèm kiểm thử SQL.
5. **Server tự tính lại giá**, không tin giá từ client. Logic tiền và ngày là hàm thuần, có bảng ca kiểm thử.
6. Thao tác ghi gây tác động tiền hoặc tồn kho cần `Idempotency-Key`.
7. Quyết định kiến trúc mới thì thêm ADR trong `docs/01-architecture/adr/`.
8. Không commit bí mật hay file `.env`; không dùng dữ liệu thật khi phát triển.
9. Role ứng dụng ở DB không phải superuser và không phải owner bảng (nếu không RLS vô hiệu).

## Quy tắc làm việc với Claude (bắt buộc)

1. **Không tự commit, không tự push.** Làm xong thì liệt kê file đã đổi và đưa sẵn lệnh để người dùng tự chạy (`git add ...`, `git commit -m "..."` theo Conventional Commits). Chỉ commit khi người dùng nói rõ "hãy commit".
2. **Thêm thành phần mới phải hỏi ý kiến trước.** Thư viện (`pnpm add`), agent, skill, rule, command, hook, dịch vụ ngoài: mô tả trước (là gì, vì sao cần, thay thế, chi phí, ảnh hưởng), chờ người dùng đồng ý rồi mới thêm.
3. **Làm đúng phần được giao.** Chỉ sửa file và dòng cần cho yêu cầu. Không refactor, đổi tên, định dạng lại, "tiện tay" sửa chỗ khác. Thấy vấn đề ngoài phạm vi thì báo lại, đừng tự sửa.
4. **Làm như chuyên gia lập trình SEO** cho mọi phần hiển thị công khai: xem `docs/07-quality/seo.md` và `.claude/rules/seo.md`.
5. **Cổng thiết kế: không làm giao diện khi chưa có thiết kế của người dùng.** Trước khi làm bất kỳ màn hình hay thành phần giao diện nào (`apps/web`, `apps/admin`, `apps/mobile`, `packages/ui`), dừng lại và hỏi người dùng về thiết kế; người dùng thiết kế trước, Claude chỉ làm theo bản đã duyệt. Không tự chọn phong cách, màu, phông, bố cục.

Chi tiết và ví dụ: `docs/08-guides/working-agreement.md`.

## Quy trình

- **Theo dõi tiến độ:** đọc `docs/00-overview/progress.md` và mục giai đoạn trong `docs/06-roadmap/roadmap.md` trước khi bắt đầu. Việc đã `[x]` thì không làm lại. Làm xong việc nào thì đánh `[x]` kèm ngày ngay trong cùng lần làm (cả `project-plan.md` mục 7 và 9 nếu có liên quan).
- **README thư mục:** thêm hoặc xóa mục trong thư mục nào thì cập nhật `README.md` của thư mục đó; thư mục mới phải có `README.md`.
- Nhánh `feat/...`, `fix/...`; commit theo Conventional Commits; gộp PR kiểu squash (`docs/08-guides/git-workflow.md`).
- Trước khi báo xong: chạy `/check` (lint, typecheck, test) và cập nhật tài liệu liên quan.
- Chưa chắc nghiệp vụ thì hỏi, không đoán; ghi chỗ chưa chốt vào tài liệu.

## Ngôn ngữ

Tài liệu và giao tiếp bằng tiếng Việt; tên code, commit, API bằng tiếng Anh.

## Cấu hình Claude Code

Bộ `.claude/` (rules, commands, agents, skills) sẽ lớn dần theo dự án. Khi thấy một việc lặp lại lần thứ hai, đề xuất thêm thành phần phù hợp bằng `/new-skill` (xem `.claude/README.md`, mục "Mở rộng theo dự án"). Không tự thêm hay sửa `.claude/settings.json` khi chưa hỏi.
