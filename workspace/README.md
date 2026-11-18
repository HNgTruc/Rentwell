# workspace/

Chỉ file cấu hình công cụ của monorepo. Lệnh `pnpm` chạy trong thư mục này (không dùng Turborepo, ADR 0010).

## Bên trong

| Mục | Mô tả |
|---|---|
| `.editorconfig` | Quy tắc định dạng của trình soạn thảo (không tự áp cho `apps/`; Prettier ở `packages/config` lo phần đó). |
| `.env.example` | Mẫu biến môi trường dùng chung (giá trị giả). `pnpm db:migrate` cần `DATABASE_MIGRATION_URL` trong `workspace/.env`. |
| `.gitignore` | Danh sách bỏ qua của git; áp cho cả repo qua `core.excludesFile` (`infra/scripts/setup-git.sh`). |
| `commitlint.config.mjs` | Kiểm commit message theo Conventional Commits. |
| `lefthook.yml` | Hook git: pre-commit (Prettier, ESLint, chặn file `.env`), commit-msg (commitlint). Gọi qua `infra/git-hooks/`. |
| `package.json` | Script gốc (`pnpm -r`), công cụ dùng chung, phiên bản pnpm và Node. |
| `pnpm-lock.yaml` | Khóa phiên bản phụ thuộc (commit; CI cài bằng `--frozen-lockfile`). |
| `pnpm-workspace.yaml` | Khai báo workspace (trỏ `../apps/*`, `../packages/*`) và danh sách gói được chạy script cài đặt. |

## Quy tắc

- Mỗi package tự khai báo công cụ nó dùng (`typescript`, `vitest`, `eslint`), vì `workspace/node_modules` không phải thư mục cha của `apps/`, `packages/`.
- Không chạy `pnpm` từ bên trong một package; dùng `pnpm --filter <tên> ...` từ đây.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
