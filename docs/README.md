# Rentwell: Tài liệu dự án

Nền tảng cho thuê đồ đa cửa hàng (multi-tenant). Mỗi cửa hàng là một tenant, có web quản trị riêng, khách hàng đặt thuê qua web và mobile.

> Trạng thái: **giai đoạn lập kế hoạch, chưa có code.** Tài liệu là nguồn sự thật duy nhất (single source of truth) cho mọi quyết định.

## Cách đọc tài liệu

Đọc theo thứ tự thư mục. Mỗi thư mục trả lời một câu hỏi:

| Thư mục | Câu hỏi | File chính |
|---|---|---|
| `00-overview/` | Làm cái gì, cho ai, đến đâu? | `project-plan.md` (kế hoạch tổng), `progress.md` (tiến độ, đánh dấu việc đã xong), `vision.md`, `scope-mvp.md`, `glossary.md` |
| `01-architecture/` | Xây bằng gì, ghép thế nào? | `tech-stack.md`, `system-architecture.md`, `monorepo-structure.md`, `api-structure.md`, `mcp-design.md` (đề xuất), `adr/` |
| `02-database/` | Dữ liệu lưu thế nào? | `schema-overview.md` (kèm `schema-001-init.sql`, ERD), `proposal-002-reviews-routing-chat.md`, `proposal-003-branches.md` (đã áp dụng) |
| `03-api/` | Giao tiếp giữa các phần ra sao? | `api-conventions.md`, `booking-pricing.md` |
| `04-product/` | Nghiệp vụ chạy thế nào? | `roles-permissions.md`, `booking-flow.md`, `support-reviews-chat.md` |
| `05-devops/` | Chạy và triển khai ở đâu? | `environments.md`, `ci-cd.md` |
| `06-roadmap/` | Làm theo thứ tự nào? | `roadmap.md` |
| `07-quality/` | Đảm bảo chất lượng thế nào? | `testing-strategy.md`, `security.md`, `seo.md` |
| `08-guides/` | Viết code theo quy ước nào? | `conventions.md`, `git-workflow.md`, `working-agreement.md` |

## Cấu trúc thư mục

```
docs/
├── README.md
├── 00-overview/
│   ├── progress.md            # Tiến độ, đánh dấu việc đã xong
│   ├── project-plan.md        # KẾ HOẠCH TỔNG: mục tiêu, lộ trình, việc 2 tuần đầu, rủi ro
│   ├── vision.md              # Tầm nhìn, người dùng, giá trị cốt lõi
│   ├── scope-mvp.md           # Trong/ngoài phạm vi MVP, quyết định đã chốt
│   └── glossary.md            # Thuật ngữ nghiệp vụ dùng thống nhất
├── 01-architecture/
│   ├── tech-stack.md          # Công nghệ + lý do chọn + phương án thay thế
│   ├── system-architecture.md # Kiến trúc tổng thể, luồng dữ liệu
│   ├── monorepo-structure.md  # Cấu trúc mã nguồn
│   ├── api-structure.md       # Cấu trúc phần API (backend)
│   └── adr/                   # Architecture Decision Records
│       ├── 0000-template.md
│       ├── 0001-multi-tenant-rls.md
│       ├── 0002-monorepo.md
│       ├── 0003-modular-monolith.md
│       ├── 0004-sql-first-migrations.md
│       ├── 0005-one-shared-website.md
│       ├── 0006-chain-branches.md
│       ├── 0007-mcp-server.md
│       ├── 0008-pricing-tiers-deposit.md
│       ├── 0009-business-rules-batch-2026-11-17.md
│       └── 0010-pnpm-without-turborepo.md
├── 02-database/
│   ├── schema-overview.md     # Nhóm bảng, quy tắc, giới hạn đã biết
│   ├── schema-001-init.sql    # Migration khởi tạo (49 bảng)
│   ├── erd.md                 # Sơ đồ ERD (Mermaid)
│   ├── proposal-002-reviews-routing-chat.md  # Đề xuất lược đồ (đã duyệt hướng)
│   ├── proposal-003-branches.md  # Chuỗi nhiều chi nhánh (đã duyệt, đã áp dụng)
│   └── proposal-004-walkin-holidays-config.md  # Khách vãng lai, ngày lễ, cờ xác minh (chờ duyệt)
├── 03-api/
│   ├── api-conventions.md     # REST, lỗi, phân trang, idempotency, versioning
│   └── booking-pricing.md     # Thuật toán giá, tồn kho, phí giao hàng
├── 04-product/
│   ├── roles-permissions.md   # Ma trận phân quyền RBAC
│   ├── booking-flow.md        # Vòng đời đơn thuê
│   └── support-reviews-chat.md  # Hỗ trợ, đánh giá, định tuyến, chat (đã duyệt hướng)
├── 05-devops/
│   ├── environments.md        # local / staging / production
│   └── ci-cd.md               # Pipeline, release, rollback
├── 06-roadmap/
│   └── roadmap.md             # Lộ trình theo giai đoạn, milestone, DoD
├── 07-quality/
│   ├── testing-strategy.md
│   ├── security.md
│   └── seo.md                 # SEO trang công khai
└── 08-guides/
    ├── conventions.md         # Quy ước đặt tên, code style
    ├── git-workflow.md        # Nhánh, commit, PR
    └── working-agreement.md   # Quy tắc làm việc với Claude
```

## Quy ước tài liệu

- Viết bằng tiếng Việt, thuật ngữ kỹ thuật giữ tiếng Anh.
- Mỗi quyết định kiến trúc quan trọng có một ADR trong `01-architecture/adr/`. Không sửa ADR đã chấp nhận; tạo ADR mới thay thế.
- Mọi file có đầu mục **Trạng thái** (Nháp / Đã duyệt / Lỗi thời) và **Cập nhật lần cuối**.
- Sơ đồ dùng Mermaid để diff được bằng git.
- Ký hiệu: ✅ đã chốt, 🟡 đề xuất (chưa kiểm chứng), ⬜ chưa làm.
