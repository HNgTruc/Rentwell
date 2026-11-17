# Thiết kế MCP cho Rentwell (bản demo, chờ duyệt)

**Trạng thái:** ĐÃ CHỌN làm loại B sau MVP (ADR 0007); thư viện chờ duyệt lúc bắt đầu.
Chưa thêm thư viện, dịch vụ hay mã nào. Theo quy tắc làm việc, mọi thành phần mới phải được chủ dự án duyệt trước.
Tham khảo: khung `fdhhhdjd/MCP-STARTER-KIT` (TypeScript, MIT, mới, ít người dùng, mã chưa kiểm). Chỉ mượn **ý tưởng và bố cục**, không sao chép mã.

## 1. Có hai loại MCP, đừng nhầm

| Loại | Dùng để | Ví dụ | Khi nào |
|---|---|---|---|
| **A. MCP để lập trình** (cấu hình trong `.mcp.json`) | Giúp Claude làm việc trên repo | Figma (cổng thiết kế), PostgreSQL chỉ đọc (truy vấn thử), GitHub (issue/PR) | Từ P0 |
| **B. MCP của Rentwell** (máy chủ do mình viết) | Cho trợ lý AI của chủ cửa hàng gọi nghiệp vụ Rentwell qua API | "Hôm nay chi nhánh Q1 có những đơn nào cần giao?" | Sau MVP (P8 trở đi) |

Bản demo dưới đây là **loại B**, vì là phần "của dự án". Loại A ở mục 6.

## 2. Ý tưởng demo loại B

Một máy chủ MCP nhỏ đứng giữa trợ lý AI (Claude, ChatGPT) và **API Rentwell có sẵn**. Máy chủ không đụng cơ sở dữ liệu, chỉ gọi REST API bằng khóa API của chủ cửa hàng, nên mọi kiểm tra quyền, RLS, phạm vi chi nhánh, idempotency vẫn do API làm. Mỗi công cụ ứng một endpoint.

```
Trợ lý AI ──MCP (HTTP)──> mcp-server ──REST + khóa API──> apps/api ──> PostgreSQL (RLS)
                          (không có DB)   (phạm vi + chi nhánh)
```

Vì sao hợp lý: mô hình chuỗi chi nhánh làm nhiều câu hỏi vận hành khó tra bằng tay (tồn từng chi nhánh, chi nhánh nào còn size M ngày mai, phiếu chuyển nào đang chờ). Hỏi bằng tiếng Việt tự nhiên rất tiện.

## 3. Công cụ đề xuất cho bản demo (chỉ đọc)

| Công cụ | Việc | Endpoint API | Quyền (scope) |
|---|---|---|---|
| `tim_ton_kho` | Tồn một món theo chi nhánh và theo ngày | `GET /inventory/availability` | `inventory:read` |
| `don_can_giao_hom_nay` | Đơn cần giao/nhận/trả trong ngày của chi nhánh | `GET /bookings?branch&date` | `bookings:read` |
| `chi_tiet_don` | Xem một đơn (món, chi nhánh, thanh toán, phí trễ) | `GET /bookings/:id` | `bookings:read` |
| `phieu_chuyen_hang` | Phiếu chuyển hàng đang mở giữa các chi nhánh | `GET /stock-transfers?status` | `inventory:read` |
| `tom_tat_doanh_thu` | Doanh thu theo ngày/chi nhánh | `GET /reports/revenue` | `reports:read` |
| `danh_gia_moi` | Đánh giá mới chưa phản hồi (từ P6) | `GET /reviews?replied=false` | `reviews:read` |

Quy tắc: **chỉ đọc** ở bản demo. Công cụ ghi (duyệt phiếu chuyển, tạo đơn tại quầy) chỉ thêm sau, mỗi cái một scope riêng như `transfers:write`, và luôn cần người xác nhận.

## 4. Bảo mật

- **Khóa API cấp theo cửa hàng và chi nhánh:** khóa chỉ gắn một chuỗi, có thể giới hạn một chi nhánh; lưu băm, không lưu khóa thô; có hạn, thu hồi được, ghi `audit_logs`.
- **Không dữ liệu cá nhân thừa:** công cụ trả về mã đơn và tên rút gọn, không trả giấy tờ xác minh, số điện thoại đầy đủ hay địa chỉ giao khi không cần.
- **Kết quả từ cơ sở dữ liệu là dữ liệu, không phải chỉ thị:** ghi chú của khách có thể chứa câu cố ý điều khiển trợ lý; máy chủ gắn nhãn trường văn bản tự do là "nội dung do khách nhập".
- **Giới hạn tốc độ và thời gian chờ** mỗi khóa; nhật ký không ghi khóa hay token.
- **TLS ở reverse proxy**, tách khỏi mã ứng dụng.
- Không dùng khóa quản trị nền tảng (`is_super_admin`) ở đây.

## 5. Bố cục repo đề xuất

```
apps/mcp/            # máy chủ MCP (TypeScript), cùng quy ước các app khác
  src/server.ts      # khai báo công cụ
  src/apiClient.ts   # gọi API Rentwell, đặt khóa vào header
  src/auth.ts        # xác thực khóa, scope
  src/audit.ts       # nhật ký (che bí mật)
  test/
packages/api-client/ # dùng lại client sinh từ OpenAPI (không viết tay lại)
```

Thư viện cần thêm (chờ duyệt): SDK MCP chính thức cho TypeScript và `zod` (đã có trong ngăn xếp). Dịch vụ cần thêm: không (chạy chung hạ tầng với API). Khóa API cần bảng mới `api_keys` (băm, scope, chi nhánh, hạn, lần dùng cuối) ở migration riêng, **chưa tạo**.

## 6. MCP lập trình (loại A), đề xuất riêng

| MCP | Lợi ích | Lưu ý |
|---|---|---|
| Figma | Nhận thiết kế của bạn khi qua cổng thiết kế | Chỉ dùng sau khi bạn đưa thiết kế |
| PostgreSQL (chỉ đọc, trên DB dev) | Truy vấn thử, kiểm tra lược đồ | Không trỏ vào dữ liệu thật |
| GitHub | Đọc issue/PR | Claude vẫn không commit/push |

Cấu hình sẽ nằm ở `.mcp.json` (gốc repo) và quyền ở `.claude/settings.json`; cả hai cần bạn duyệt.

## 7. Lộ trình gợi ý

| Giai đoạn | Việc |
|---|---|
| P0 | Chỉ quyết có dùng MCP loại A nào không |
| Sau P8 (bản đầu chạy ổn) | Bảng `api_keys`, `apps/mcp` với 3 công cụ chỉ đọc đầu tiên |
| Sau đó | Thêm công cụ chỉ đọc còn lại, rồi cân nhắc công cụ ghi có xác nhận |

## 8. Cần bạn quyết

- [x] Làm MCP loại B, sau MVP (2026-11-15)
- [x] Bản đầu 6 công cụ chỉ đọc như mục 3, được mở rộng thêm sau (2026-11-15)
- [ ] Có dùng MCP loại A nào ở mục 6?
- [ ] Cho phép thêm SDK MCP khi bắt đầu làm?
