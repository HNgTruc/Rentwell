# workspace/

Chỉ file cấu hình công cụ của monorepo. Lệnh `pnpm` và `turbo` chạy trong thư mục này.

## Bên trong

| Mục | Mô tả |
|---|---|
| `.editorconfig` | Quy tắc định dạng của trình soạn thảo. |
| `.env.example` | Mẫu biến môi trường dùng chung (giá trị giả). |
| `.gitignore` | Danh sách bỏ qua của git (xem ghi chú rủi ro trong `docs/01-architecture/monorepo-structure.md`). |
| `package.json` | Script gốc và phiên bản Node. |
| `pnpm-workspace.yaml` | Khai báo workspace (trỏ `../apps/*`, `../packages/*`). |
| `turbo.json` | Cấu hình Turborepo. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
