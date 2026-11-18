# config/

Cấu hình dùng chung: ESLint, tsconfig, Prettier. Gói `@rentwell/config`, không có mã chạy.

## Bên trong

| Mục | Mô tả |
|---|---|
| `package.json` | Khai báo gói và các đường xuất (`./tsconfig.base.json`, `./eslint`, `./prettier`). |
| `tsconfig.base.json` | Tùy chọn TypeScript nghiêm ngặt chung; mỗi app tự đặt `module`, `outDir`, `lib`. |
| `eslint.config.js` | ESLint flat config + typescript-eslint; cấm `toFixed`, `parseFloat` (tiền là số nguyên). |
| `prettier.json` | Quy tắc định dạng (thay cho `.editorconfig` vì file đó ở `workspace/` không áp cho `apps/`). |

## Quy tắc

- TypeScript ghim `~6.0` ở `workspace/package.json`: typescript-eslint chưa hỗ trợ TypeScript 7 (bản viết lại bằng Go).

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
