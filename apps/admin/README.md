# admin/

Trang quản trị cửa hàng và super admin (Next.js).

## Bên trong

| Mục | Mô tả |
|---|---|
| `.env.example` | Mẫu biến môi trường; chỉ biến công khai, không bí mật. |
| `eslint.config.mjs` | ESLint: `eslint-config-next` (core web vitals) + cấu hình chung `@rentwell/config`. |
| `next.config.ts` | Cấu hình Next.js; đặt gốc monorepo là thư mục repo vì lockfile nằm ở `workspace/`. |
| `package.json` | Gói `@rentwell/admin`; `dev` chạy ở cổng 3002. |
| `public/` | Tài nguyên tĩnh công khai. |
| `src/` | Mã nguồn. |
| `tsconfig.json` | TypeScript, kế thừa `@rentwell/config/tsconfig.base.json`. |

## Quy tắc

- `src/app/` chỉ định tuyến; logic nằm trong `src/features/`.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
