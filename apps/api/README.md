# api/

Backend NestJS (REST API) và tiến trình nền. Gói `@rentwell/api`, CommonJS, nền HTTP Express.

## Bên trong

| Mục | Mô tả |
|---|---|
| `.env.example` | Mẫu biến môi trường của API (giá trị giả). |
| `eslint.config.mjs` | Dùng cấu hình chung `@rentwell/config/eslint`. |
| `nest-cli.json` | Cấu hình Nest CLI (`pnpm --filter @rentwell/api dev` chạy chế độ theo dõi). |
| `openapi/` | Hợp đồng OpenAPI sinh ra từ API, được commit để thay đổi hiện trong PR. |
| `package.json` | Phụ thuộc và script: `build`, `dev`, `start`, `typecheck`, `lint`, `test`. |
| `src/` | Mã nguồn của API. |
| `test/` | Kiểm thử tích hợp và e2e của API, chạy với Postgres thật. |
| `tsconfig.json`, `tsconfig.build.json` | TypeScript (decorator, metadata); bản build bỏ file `*.spec.ts`. |
| `vitest.config.mts` | Vitest dùng SWC để biên dịch decorator của NestJS. |

## Chạy

Từ `workspace/`: `pnpm db:up`, rồi `pnpm --filter @rentwell/api dev` với biến theo `.env.example`. Swagger ở `http://localhost:3000/docs` (tắt ở production), health ở `/v1/health`.

## Quy tắc

- SQL chỉ nằm trong `*.repository.ts`.
- Tenant lấy từ token, không từ body.
- Log JSON chỉ ghi method, đường dẫn, mã trạng thái, `request_id`; không ghi header, query, body.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
