# Thư mục `.claude/`

Cấu hình Claude Code cho dự án Rentwell. Mọi thứ ở đây được commit, trừ `settings.local.json`.

```
.claude/
├── README.md                          # File này
├── settings.json                      # Quyền, hook (dùng chung cả nhóm)
├── settings.local.json                # Cá nhân, KHÔNG commit (đã ignore)
├── rules/                             # Quy tắc theo vùng mã, nạp khi chạm file khớp `paths`
│   ├── database.md                    #   db/**, repository
│   ├── api.md                         #   apps/api/**
│   ├── pricing-money.md               #   packages/shared, pricing, bookings, payments
│   ├── frontend.md                    #   web, admin, mobile, ui
│   ├── seo.md                         #   SEO trang công khai (apps/web)
│   └── testing.md                     #   *.spec.ts, db/tests, apps/api/test
├── commands/                          # Lệnh gạch chéo tự tạo
│   ├── check.md                       #   /check: lint + typecheck + test
│   ├── new-migration.md               #   /new-migration <mô tả>
│   ├── new-adr.md                     #   /new-adr <tiêu đề>
│   ├── phase-status.md                #   /phase-status [P0..P8]
│   ├── spike.md                       #   /spike <tên>
│   └── new-skill.md                   #   /new-skill <loại> <tên> <mục đích>
├── agents/                            # Subagent chuyên trách (chỉ đọc, trừ docs-keeper)
│   ├── tenant-isolation-reviewer.md   #   Rà RLS, phân quyền, IDOR
│   ├── pricing-reviewer.md            #   Rà tiền, giá, tồn kho, idempotency
│   └── docs-keeper.md                 #   Giữ docs khớp với mã
└── skills/                            # Kỹ năng: quy trình chi tiết, nạp khi đúng ngữ cảnh
    ├── add-api-module/SKILL.md        #   Thêm module NestJS đúng cấu trúc
    ├── rls-isolation-test/SKILL.md    #   Viết kiểm thử cô lập tenant (RLS)
    ├── pricing-calculation/
    │   ├── SKILL.md                   #   Hàm tính giá, phí, cọc
    │   └── cases.md                   #   Bảng ca kiểm thử mẫu
    ├── inventory-reservation/SKILL.md #   Giữ chỗ, nhả chỗ, sổ cái tồn kho
    ├── payment-webhook/SKILL.md       #   Webhook thanh toán idempotent, hoàn tiền
    ├── clean-code/SKILL.md            #   Làm sạch code trong phạm vi chỉ định, không đổi hành vi
    └── ui-ux-pro-max/                 #   Kho tra cứu UI/UX (phong cách, màu, phông, UX); có bối cảnh Rentwell
```

Ngoài thư mục này, ở gốc repo còn `CLAUDE.md` (bối cảnh và quy tắc chung, luôn được nạp).

## Cách phân chia

| Nơi | Chứa gì | Khi nào nạp |
|---|---|---|
| `CLAUDE.md` | Tổng quan, lệnh, quy tắc bắt buộc, con trỏ tới docs | Luôn luôn |
| `rules/*.md` | Quy tắc riêng từng vùng mã | Khi làm việc với file khớp `paths` |
| `commands/` | Quy trình lặp lại, gọi bằng `/tên` | Khi bạn gọi |
| `agents/` | Người rà soát có ngữ cảnh riêng | Khi được giao hoặc tự chọn theo mô tả |
| `skills/` | Quy trình làm một loại việc, có thể kèm file phụ | Khi nhiệm vụ khớp phần `description` của skill |
| `settings.json` | Quyền được phép/cấm, hook tự định dạng | Luôn luôn |

Nguyên tắc: `CLAUDE.md` ngắn, chỉ giữ thứ phải đúng ở mọi nơi; chi tiết đẩy xuống `rules/` và `docs/` để không tốn ngữ cảnh.

## Cách dùng khuyến nghị

- Trước khi báo xong một việc: `/check`.
- Sau khi sửa migration, repository, guard: nhờ agent `tenant-isolation-reviewer`.
- Sau khi sửa tính giá, thanh toán, tồn kho: nhờ agent `pricing-reviewer`.
- Cuối giai đoạn: `/phase-status` rồi nhờ `docs-keeper`.
- Việc 🟡 trong tech-stack: `/spike <tên>`.

## Bảo mật cấu hình

- `deny` chặn đọc `.env`, `secrets/`, và các lệnh phá hủy (`rm -rf`, force push, `reset --hard`, `psql` tới production).
- `allow` chỉ gồm lệnh phát triển thường dùng; lệnh khác sẽ hỏi trước khi chạy.
- Hook `PostToolUse` tự chạy Prettier trên file vừa sửa (lỗi hook không chặn công việc).
- Không đặt bí mật vào `settings.json`; dùng `settings.local.json` hoặc biến môi trường.

## Việc cần làm khi khởi tạo repo (P0)

- [ ] Thêm vào `.gitignore`: `.claude/settings.local.json`
- [ ] Cài `jq` (hook dùng), `prettier` trong repo
- [ ] Kiểm tra tên script `pnpm db:migrate`, `pnpm db:seed`, `pnpm lint`, `pnpm typecheck`, `pnpm test` khớp `package.json`
- [ ] Điều chỉnh `allow` theo lệnh thực tế
- [ ] Rà `rules/*.md` khi cấu trúc thư mục thay đổi

> Ghi chú: cú pháp `settings.json`, `rules/` (frontmatter `paths`), `commands/`, `agents/` theo hiểu biết hiện tại về Claude Code; nên kiểm tra lại với tài liệu chính thức của phiên bản đang dùng vì các tính năng này thay đổi theo thời gian.

## Mở rộng theo dự án

`.claude/` được phép và nên lớn dần theo dự án. Bộ hiện tại chỉ là khởi đầu cho giai đoạn P0 đến P4; các giai đoạn sau sẽ cần thêm.

### Khi nào thêm gì

| Dấu hiệu | Thêm | Ví dụ có thể cần |
|---|---|---|
| Phải nhắc Claude cùng một quy trình nhiều lần | **skill** | `delivery-distance` (P5), `notifications` (P6), `new-web-screen`, `mobile-screen` |
| Một khu vực code hay bị sai cùng kiểu lỗi | **rule** (có `paths` hẹp) | `rules/queue-workers.md`, `rules/i18n.md` |
| Cần người rà soát độc lập, ngữ cảnh riêng | **agent** (mặc định chỉ đọc) | `security-reviewer`, `migration-reviewer` |
| Lệnh dài hoặc lặp lại hằng ngày | **command** | `/seed-demo`, `/release` |
| Việc lặp mà luôn chạy y hệt, không cần Claude phán đoán | **hook** trong `settings.json` | chạy typecheck sau khi sửa file |
| Quy tắc phải đúng ở mọi nơi, ngắn gọn | dòng trong **CLAUDE.md** | quy tắc mới cho cả dự án |

### Quy tắc giữ cho gọn

1. **Thêm khi có nhu cầu thật**, thường là lần thứ hai hoặc thứ ba gặp cùng một việc. Không viết sẵn cho giai đoạn chưa tới.
2. **Dựa trên việc đã làm.** Skill tốt đúc kết từ một lần làm xong và chạy đúng, không phải từ phỏng đoán.
3. **Trỏ về docs, không chép.** Quy tắc nghiệp vụ nằm ở `docs/`; skill chỉ nói cách làm và liên kết tới đó.
4. **Mô tả (`description`) quyết định khi nào được nạp.** Viết rõ "dùng khi...", đừng viết chung chung.
5. **Mỗi thành phần một việc.** Quá dài hoặc quá rộng thì tách ra.
6. **Rà định kỳ.** Cuối mỗi giai đoạn: xóa cái không dùng, sửa cái đã lệch với code. `docs-keeper` có thể hỗ trợ.
7. **Đi qua git.** Thay đổi `.claude/` cũng là commit có lý do, để cả đội (hoặc bạn sau này) biết vì sao.
8. **Kiểm tra quyền.** Agent mới mặc định chỉ đọc; không nới `permissions` trong `settings.json` nếu chưa cân nhắc.

Dùng `/new-skill <loại> <tên> <mục đích>` để Claude tạo đúng khuôn.

### Dự kiến sẽ cần theo giai đoạn (chỉ là gợi ý, chưa làm)

- P2 đến P3: `new-web-screen` (khung trang Next.js), `i18n`
- P5: `delivery-distance` (khoảng cách, bán kính, phí giao)
- P6: `notifications` (email, đẩy, mẫu thông báo)
- P7: `new-mobile-screen` (Expo)
- P8: `release` (checklist phát hành), `load-test`

## Quy tắc cưỡng chế trong settings.json

- **Chặn:** `git commit`, `git push`, `git tag` (Claude đưa lệnh, bạn tự chạy).
- **Hỏi trước:** `pnpm add/remove/up`, `npm install`, mọi sửa trong `.claude/**`.
- Lý do và chi tiết: `docs/08-guides/working-agreement.md`.
