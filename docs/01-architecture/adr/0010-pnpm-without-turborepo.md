# ADR 0010: Giữ cấu hình trong `workspace/`, bỏ Turborepo, dùng `pnpm -r`

**Trạng thái:** Chấp nhận (2026-11-17) · thay thế một phần ADR 0002 (phần Turborepo) · **Người quyết:** chủ dự án

## Bối cảnh

`monorepo-structure.md` đặt file cấu hình công cụ trong `workspace/` để gốc repo gọn, và ghi ba rủi ro cần kiểm ở P0. Kết quả kiểm (2026-11-17):

1. **pnpm:** chạy tốt với `packages: ["../apps/*", "../packages/*"]`.
2. **Turborepo 2.11:** từ chối chạy: `Workspace package resolves outside repository root`. Turbo coi thư mục chứa `turbo.json` là gốc và không chấp nhận package ở ngoài.
3. **Node tìm module:** `workspace/node_modules` không phải thư mục cha của `apps/`, `packages/`, nên công cụ cài ở gốc workspace (vitest, typescript...) không import được từ package. Mỗi package phải tự khai báo công cụ nó dùng (cũng là cách pnpm khuyến nghị).
4. **`.gitignore`:** không tự áp cho `apps/`; giải quyết bằng `core.excludesFile` (script `infra/scripts/setup-git.sh`), đã kiểm `node_modules` trong `apps/` bị bỏ qua.

## Quyết định

- Giữ `workspace/` (gốc repo không đổi).
- **Bỏ Turborepo.** Script gốc dùng `pnpm -r` (chạy theo thứ tự phụ thuộc, `--parallel` cho `dev`).
- Mỗi package khai báo đủ phụ thuộc dev nó dùng (`typescript`, `vitest`, `eslint`...), cùng phiên bản.
- TypeScript ghim `~6.0`: typescript-eslint 8 chưa hỗ trợ TypeScript 7 (bản viết lại bằng Go); kiểm lại khi typescript-eslint hỗ trợ.

## Hệ quả

- Mất bộ nhớ đệm build và chạy "chỉ phần thay đổi" của Turbo. Với một người và vài package, thời gian build hiện tại vài giây; xem lại nếu CI chậm.
- `typecheck` và `test` ở gốc chạy `build` trước (để package dùng `dist/` của `@rentwell/shared`).
- Lệnh pnpm luôn chạy trong `workspace/` (chạy pnpm từ bên trong một package sẽ không thấy workspace).
- Hook git (lefthook) cũng tìm cấu hình ở gốc repo; dùng `infra/git-hooks/` + `core.hooksPath` để trỏ tới `workspace/lefthook.yml`.

## Phương án đã cân nhắc

- Đưa `package.json`, `pnpm-workspace.yaml`, `turbo.json` ra gốc repo, giữ Turbo: chuẩn hơn và có cache, nhưng đổi bố cục đã chốt và nhiều tài liệu; chủ dự án chọn giữ `workspace/`.
