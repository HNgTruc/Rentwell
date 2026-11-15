# ADR 0007: Máy chủ MCP của Rentwell (loại B), làm sau MVP

**Trạng thái:** Chấp nhận (2026-11-15). Việc thêm thư viện vẫn chờ duyệt lúc bắt đầu làm.

## Bối cảnh

Chủ dự án muốn Rentwell có **máy chủ MCP riêng** để trợ lý AI (Claude, ChatGPT) của chủ cửa hàng tra cứu nghiệp vụ bằng tiếng tự nhiên: tồn từng chi nhánh, đơn cần giao hôm nay, phiếu chuyển hàng đang mở. Chi tiết thiết kế: `../mcp-design.md`.

## Quyết định

- Làm máy chủ MCP **loại B** (do dự án viết và chạy), đặt ở `apps/mcp/`, **sau MVP**.
- Máy chủ **không truy cập cơ sở dữ liệu**; chỉ gọi API Rentwell bằng khóa API, nên RLS, quyền, phạm vi chi nhánh và nhật ký kiểm toán vẫn do API bảo đảm.
- Bản đầu gồm **6 công cụ chỉ đọc** (tồn kho, đơn trong ngày, chi tiết đơn, phiếu chuyển hàng, doanh thu, đánh giá mới) và **được mở rộng thêm** sau. Công cụ ghi chỉ thêm khi có scope riêng và bước xác nhận của người.
- Khóa API gắn với một chuỗi, có thể giới hạn một chi nhánh, lưu băm, có hạn, thu hồi được.
- Tham khảo ý tưởng từ `fdhhhdjd/MCP-STARTER-KIT`, không sao chép mã.

## Hệ quả

- Cần bảng `api_keys` (migration riêng) và client API sinh từ OpenAPI (`packages/api-client`) dùng lại.
- Cần thêm SDK MCP chính thức cho TypeScript: **phải mô tả và được duyệt** trước khi cài.
- Công cụ trả dữ liệu tối thiểu, không trả giấy tờ xác minh hay thông tin cá nhân thừa; văn bản do khách nhập được gắn nhãn là dữ liệu.

## Phương án đã cân nhắc

- Cho MCP đọc thẳng cơ sở dữ liệu: nhanh nhưng vòng qua toàn bộ kiểm tra của API, bị loại.
- Làm ngay từ P0: chưa có dữ liệu và API thật để tra, bị loại.
