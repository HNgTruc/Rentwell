# apps/

Các ứng dụng chạy được, mỗi cái build và triển khai riêng.

## Bên trong

| Mục | Mô tả |
|---|---|
| `admin/` | Trang quản trị cửa hàng và super admin (Next.js). |
| `api/` | Backend NestJS (REST API) và tiến trình nền. |
| `mcp/` | Máy chủ MCP của Rentwell (loại B), chỉ đọc; CHƯA LÀM, dự kiến sau MVP (ADR 0007). |
| `mobile/` | Ứng dụng di động Expo (khách và nhân viên). |
| `web/` | Web khách hàng (Next.js). |

## Quy tắc

- Không import chéo giữa các app.
- Mã dùng chung đặt ở `packages/`.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
