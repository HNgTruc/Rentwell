# Hỗ trợ khách, đánh giá và chat

**Trạng thái:** Đề xuất theo quyết định của chủ dự án (2026-11-15) · chờ duyệt chi tiết
Liên quan: `roles-permissions.md`, `booking-flow.md`, `../02-database/proposal-002-reviews-routing-chat.md`, `../00-overview/scope-mvp.md`.

## 1. Quyết định đã nhận

1. **Đánh giá và feedback sản phẩm:** khách thuê xong thì được đánh giá; đánh giá hiện trong app của khách; **mọi khách xem được đánh giá của người khác**.
2. **Định tuyến theo bộ phận support:** phiếu hỗ trợ đi vào hàng đợi của đúng bộ phận.
3. **Chat:** đưa vào quy trình làm việc, theo hướng hợp với dự án (mục 4).

## 2. Đánh giá sản phẩm và feedback

**Ai được đánh giá:** chỉ khách có đơn **đã hoàn tất** chứa món đó (`completed`), mỗi dòng đơn một đánh giá. Đây là cách ngăn đánh giá giả, và cũng làm đánh giá đáng tin để hiển thị công khai.

**Nội dung:** số sao (1 đến 5), nhận xét, ảnh (tùy chọn). Cửa hàng được trả lời công khai.

**Ai xem được:**
- Mọi khách (kể cả chưa mua) xem đánh giá đã đăng của một món hoặc cửa hàng, trong app mobile và trên web.
- Chỉ hiện **tên hiển thị rút gọn** của người đánh giá, không lộ email hay thông tin cá nhân.
- Cửa hàng xem tất cả đánh giá của mình; manager có thể **ẩn** đánh giá vi phạm (có lý do, ghi nhật ký), không được xóa hay sửa nội dung.

**Feedback riêng tư:** góp ý không muốn công khai (ví dụ về dịch vụ giao hàng) đi qua phiếu hỗ trợ loại `feedback`, chỉ cửa hàng thấy.

**SEO:** số sao trung bình và số đánh giá có thể đưa vào dữ liệu có cấu trúc của trang món, nhưng **chỉ khi là đánh giá thật hiển thị trên trang** (xem `../07-quality/seo.md`). Không đánh dấu thứ không có.

## 3. Phiếu hỗ trợ và định tuyến theo bộ phận

**Bộ phận (department)** do mỗi cửa hàng cấu hình, ví dụ: Tư vấn, Giao nhận, Kho và hư hỏng, Thanh toán và hoàn tiền. Mỗi bộ phận gồm một hoặc nhiều nhân viên có vai trò `support` (hoặc vai trò khác do cửa hàng gán).

**Định tuyến:** quy tắc "loại phiếu → bộ phận" do cửa hàng đặt, có giá trị mặc định:

| Loại phiếu (khách chọn) | Bộ phận mặc định |
|---|---|
| `question` (hỏi, tư vấn cách dùng) | Tư vấn |
| `delivery` (giao nhận) | Giao nhận |
| `damage`, `issue` (hư hỏng, sự cố) | Kho và hư hỏng |
| `refund` (hoàn tiền, thanh toán) | Thanh toán và hoàn tiền |
| `feedback` (góp ý riêng) | Tư vấn |
| `other` | Tư vấn |

**Luồng:**
1. Khách tạo phiếu (gắn với đơn nếu liên quan) → hệ thống chọn bộ phận theo quy tắc, đặt hạn xử lý (SLA).
2. Phiếu vào hàng đợi của bộ phận; một nhân viên nhận hoặc được giao.
3. Nhân viên trả lời, ghi chú nội bộ (khách không thấy); cần bộ phận khác thì **chuyển bộ phận** (ghi lại lịch sử).
4. Khách trả lời → phiếu trở lại hàng đợi; chờ khách quá lâu thì tự đóng sau thời hạn cửa hàng đặt.
5. Đóng phiếu; khách có thể được mời đánh giá trải nghiệm hỗ trợ (để sau).

**Phân quyền:** nhân viên chỉ thấy phiếu của bộ phận mình; manager và owner thấy tất cả. Nhân viên không thuộc bộ phận nào thì không thấy hàng đợi.

## 4. Chat: đặt ở đâu cho hợp dự án

Đề xuất: **chat là lớp thời gian thực đặt lên cùng hệ phiếu hỗ trợ**, không phải một hệ thống thứ hai.

- Mỗi cuộc trò chuyện là một phiếu (`support_tickets`) và tin nhắn dùng lại `ticket_messages`. Nhờ đó có sẵn: gắn với đơn, định tuyến theo bộ phận, giao việc, lịch sử, ghi chú nội bộ, kiểm tra quyền, không phải làm lại.
- Hai điểm vào cho khách:
  - **Tư vấn trước khi thuê:** nút "Hỏi cửa hàng" trên trang món, tạo phiếu loại `question` gắn với món đó (`item_type_id`).
  - **Hỗ trợ trong lúc thuê:** nút "Cần hỗ trợ" trong chi tiết đơn, tạo phiếu gắn với đơn.
- **Thời gian thực** chỉ là cách phân phối tin nhắn mới (đẩy xuống app thay vì tải lại). Nếu mất kết nối, tin nhắn vẫn nằm trong phiếu và thông báo đẩy/email báo có tin mới (P7 đã có `notifications`).
- Giới hạn có chủ đích: không chat nhóm, không trạng thái "đang gõ", không gọi thoại/video ở giai đoạn đầu.

**Công nghệ truyền tin thời gian thực: chưa chốt, cần bạn duyệt** (chưa thêm gì). Hai hướng để cân nhắc, mình sẽ nêu chi tiết khi tới P7:

| Hướng | Ưu | Nhược |
|---|---|---|
| SSE (máy chủ đẩy một chiều) + gửi tin bằng REST | Đơn giản, dùng được qua HTTP thường, ít thư viện | Chỉ một chiều, tinh chỉnh khi nhiều máy chủ |
| WebSocket (qua NestJS gateway) | Hai chiều, quen thuộc cho chat | Phức tạp hơn khi mở rộng, cần Redis để chia sẻ giữa các máy chủ |

## 5. Vị trí trong lộ trình

| Giai đoạn | Việc |
|---|---|
| P6 (Mobile) | Đánh giá: viết và xem trong app khách và trên web |
| P7 (CSKH) | Bộ phận, định tuyến, hàng đợi theo bộ phận; chat thời gian thực trên nền phiếu; phiếu loại `feedback` |

Ước lượng thêm: khoảng 1 tuần cho đánh giá (P6) và 2 tuần cho định tuyến và chat (P7), tức tổng lộ trình dài thêm khoảng 3 tuần. Số này là ước lượng, cập nhật lại khi vào giai đoạn.

## 6. Quyết định đã xác nhận (2026-11-15)

- [x] Đánh giá **công khai**, người chưa đăng nhập cũng xem được.
- [x] Khách xem đánh giá **của cả nền tảng**. Tất cả cửa hàng (chi nhánh) dùng chung **một website**, nên đánh giá hiển thị theo món và theo cửa hàng trên cùng một trang web (xem ADR 0005).
- [x] Cửa hàng được **trả lời** đánh giá công khai.
- [x] Danh sách bộ phận mặc định ở mục 3 được dùng.
- [ ] Hướng thời gian thực (SSE hay WebSocket): **để P7; Claude sẽ đề xuất chi tiết rồi hỏi lại** trước khi thêm bất kỳ thư viện nào.
- [x] Đề xuất lược đồ, gồm view `public_reviews` đọc công khai: được duyệt hướng thiết kế. Migration thật vẫn chỉ tạo khi tới P6 và qua rà soát.
