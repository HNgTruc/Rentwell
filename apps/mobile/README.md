# mobile/

Ứng dụng di động Expo (khách và nhân viên).

## Bên trong

| Mục | Mô tả |
|---|---|
| `.env.example` | Mẫu biến môi trường; chỉ biến công khai. |
| `app.json` | Cấu hình Expo (tên, slug, scheme, plugin expo-router). |
| `app/` | Định tuyến theo file (expo-router). |
| `assets/` | Ảnh, phông chữ, biểu tượng. |
| `eslint.config.mjs` | ESLint dùng cấu hình chung `@rentwell/config`. |
| `package.json` | Gói `@rentwell/mobile` (Expo SDK 58); `build` đóng gói JavaScript bằng `expo export` (không build native). |
| `src/` | Mã nguồn. |
| `tsconfig.json` | TypeScript, kế thừa cấu hình chung và `expo/tsconfig.base`. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
