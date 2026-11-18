# Rentwell

Nền tảng cho thuê đồ nhiều cửa hàng (multi-tenant): web khách, trang quản trị, ứng dụng di động và API.

Trạng thái: P0 (khởi tạo). Có khung API, lược đồ CSDL, seed, CI; chưa có giao diện.

## Chạy trên máy

Cần Node 22+ (đã thử 24), pnpm 12, Docker Desktop.

```
cd workspace
pnpm install
sh ../infra/scripts/setup-git.sh
pnpm db:up && pnpm db:migrate && pnpm db:seed
pnpm lint && pnpm typecheck && pnpm test
```

`pnpm db:migrate` đọc `DATABASE_MIGRATION_URL` từ `workspace/.env` (tạo từ `.env.example`). API đọc biến theo `apps/api/.env.example`.

## Bắt đầu đọc từ đâu

- Kế hoạch tổng: `docs/00-overview/project-plan.md`
- Cấu trúc thư mục: `docs/01-architecture/monorepo-structure.md`
- Cấu trúc API: `docs/01-architecture/api-structure.md`
- Lộ trình: `docs/06-roadmap/roadmap.md`
- Cấu hình Claude Code: `.claude/README.md`

Mã nằm ở `apps/` và `packages/`, dữ liệu ở `db/`, hạ tầng ở `infra/`, tài liệu ở `docs/`, ảnh và video ở `storage/`. `workspace/` chỉ chứa file cấu hình công cụ (`package.json`, `pnpm-workspace.yaml`, `lefthook.yml`, `.gitignore`, `.editorconfig`...); lệnh `pnpm` chạy trong đó.
