# shared/

Zod schema, kiểu, hằng số, hàm thuần (số đêm, giá); không phụ thuộc framework. Gói `@rentwell/shared` (ESM, build ra `dist/`).

## Bên trong

| Mục | Mô tả |
|---|---|
| `eslint.config.js` | Dùng cấu hình chung. |
| `package.json` | Script `build`, `typecheck`, `lint`, `test`. |
| `src/` | Mã nguồn. Hiện có `constants.ts`: hằng số đã chốt ở ADR 0009 (giữ chỗ 15 phút, tối đa 3 đơn hold...), kèm kiểm thử. |
| `tsconfig.json`, `tsconfig.build.json` | TypeScript; bản build bỏ file `*.spec.ts`. |

## Quy tắc

- Đổi hằng số nghiệp vụ phải kèm ADR và sửa kiểm thử.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
