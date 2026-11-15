# Rentwell

Nền tảng cho thuê đồ nhiều cửa hàng (multi-tenant): web khách, trang quản trị, ứng dụng di động và API.

Trạng thái: giai đoạn thiết kế (P0). Chưa có mã ứng dụng.

## Bắt đầu đọc từ đâu

- Kế hoạch tổng: `docs/00-overview/project-plan.md`
- Cấu trúc thư mục: `docs/01-architecture/monorepo-structure.md`
- Cấu trúc API: `docs/01-architecture/api-structure.md`
- Lộ trình: `docs/06-roadmap/roadmap.md`
- Cấu hình Claude Code: `.claude/README.md`

Mã nằm ở `apps/` và `packages/`, dữ liệu ở `db/`, hạ tầng ở `infra/`, tài liệu ở `docs/`, ảnh và video ở `storage/`. `workspace/` chỉ chứa file cấu hình công cụ (`package.json`, `pnpm-workspace.yaml`, `turbo.json`, `.gitignore`, `.editorconfig`); lệnh `pnpm` chạy trong đó.
