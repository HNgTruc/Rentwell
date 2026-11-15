# mcp/

Máy chủ MCP của Rentwell (loại B), chỉ đọc; CHƯA LÀM, dự kiến sau MVP (ADR 0007).

## Bên trong

| Mục | Mô tả |
|---|---|
| `src/` | Mã nguồn máy chủ MCP (dự kiến: `server.ts`, `apiClient.ts`, `auth.ts`, `audit.ts`). |
| `test/` | Kiểm thử: khóa chỉ thấy đúng chuỗi/chi nhánh, giới hạn tốc độ, không lộ dữ liệu thừa. |

## Quy tắc

- Không truy cập cơ sở dữ liệu; chỉ gọi API Rentwell bằng khóa API.
- Mỗi công cụ ứng một endpoint và một scope.
- Cài thư viện (SDK MCP) phải được chủ dự án duyệt trước.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
