# So sánh cổng thanh toán (spike P0)

**Trạng thái:** Đã chọn MoMo (ADR 0013, 2026-11-19) · **Cập nhật lần cuối:** 2026-11-19
Căn cứ: ADR 0009 (mỗi chuỗi một merchant riêng, tiền về thẳng chuỗi; hoàn tiền về đúng kênh trong 24 giờ), tiêu chí spike trong `../06-roadmap/roadmap.md` P0.

> Bản này dựa trên tài liệu công khai đọc ngày 2026-11-19, **chưa** đăng ký thử sandbox hay hỏi bộ phận bán hàng. Phí và điều kiện đăng ký phải xác nhận trực tiếp với từng cổng trước khi chốt. Claude không đưa ý kiến pháp lý.

## 1. Tiêu chí (thứ tự ưu tiên)

1. Chuỗi nhỏ (cá nhân, hộ kinh doanh) **tự đăng ký merchant dễ**.
2. Có sandbox.
3. Có **API hoàn tiền** (ADR 0009: hoàn về đúng kênh, lệnh hoàn gửi trong 24 giờ).
4. Webhook/IPN có chữ ký; khóa và webhook lưu theo từng chuỗi.
5. Phí.

## 2. Bảng so sánh

| | payOS | VNPay (cổng thanh toán) | MoMo (Payment Gateway) |
|---|---|---|---|
| Cách trả | Chuyển khoản VietQR vào **tài khoản ngân hàng của chuỗi** | Thẻ nội địa, thẻ quốc tế, VNPAY-QR | Ví MoMo, thẻ |
| Ai đăng ký | Cá nhân, hộ kinh doanh, doanh nghiệp; xác thực bằng CCCD và chuyển khoản xác thực, tự động nếu khớp | Hộ kinh doanh cần giấy chứng nhận đăng ký hộ kinh doanh và ảnh cơ sở; qua bộ phận bán hàng | Đăng ký đối tác ở business.momo.vn; hồ sơ hộ kinh doanh chưa rõ |
| Độ dễ cho chuỗi nhỏ | **Cao** | Thấp đến trung bình | Trung bình (chưa xác nhận) |
| Sandbox | Có "môi trường test" (chưa xem chi tiết) | Có: tự đăng ký tại pay.vnpaytest.vn, nhận `TmnCode` và `HashSecret` qua email | Có: `test-payment.momo.vn` |
| API hoàn tiền | **Không có.** Chỉ có API chi hộ (`/v1/payouts`, có `x-idempotency-key`), tức chuyển khoản mới từ tài khoản chi hộ đã nạp tiền, không phải hoàn về giao dịch gốc | Có (`merchant_webapi/api/transaction`, tài liệu querydr/refund riêng) | Có (`POST /v2/gateway/api/refund`, hoàn toàn phần hoặc một phần) |
| Webhook và chữ ký | Webhook, chữ ký HMAC-SHA256 bằng checksum key của kênh | IPN gửi bằng GET, `vnp_SecureHash` HMAC-SHA512; gọi lại tối đa 10 lần, mỗi lần cách 5 phút | IPN gửi bằng POST tới `ipnUrl`, chữ ký HMAC-SHA256 |
| Khóa theo từng chuỗi | Mỗi chuỗi một kênh thanh toán (client id, api key, checksum key) | Mỗi chuỗi một `TmnCode` và `HashSecret` | Mỗi chuỗi một `partnerCode`, `accessKey`, `secretKey` |
| Phí (cần xác nhận) | Có gói miễn phí cho cá nhân, hộ kinh doanh từ 23/01/2026 (qua Kiên Long Bank, gói KLB–1000) | Phí đăng ký cổng từ 2.000.000 đ; thẻ nội địa khoảng 1,1% + 1.650 đ/giao dịch online (các nguồn không thống nhất) | Khoảng 1,1–2,2% tùy ngành (nguồn không chính thức) |

## 3. Điểm cần chú ý

- **payOS khớp tiêu chí 1 nhất nhưng vướng tiêu chí 3.** Hoàn tiền phải làm bằng chi hộ, nên chuỗi phải nạp sẵn tiền vào tài khoản chi hộ, và tiền hoàn đi bằng một giao dịch mới. Như vậy "hoàn về đúng kênh" chỉ đúng một nửa. Nếu chọn payOS cần sửa câu chữ của ADR 0009, mục hoàn tiền.
- **Tài khoản hộ kinh doanh:** theo các bài của VNPay về Thông tư 25/2025/TT-NHNN, từ 01/03/2026 giao dịch kinh doanh phải đi qua tài khoản đứng tên hộ kinh doanh. Điều này ảnh hưởng đến việc chuỗi đăng ký bằng tài khoản cá nhân ở mọi cổng. Cần chủ dự án hỏi luật sư hoặc ngân hàng; Claude không kết luận.
- **Ứng dụng không phụ thuộc cổng:** `apps/api/src/integrations/payment/` đặt sau một giao diện chung (tạo thanh toán, kiểm chữ ký webhook, hoàn tiền), nên sau MVP có thể thêm cổng thứ hai.

## 4. Đề xuất của Claude

Có hai hướng hợp lý, chủ dự án chọn:

- **A. payOS cho MVP.** Chuỗi nhỏ tự đăng ký được ngay, phí thấp. Hoàn tiền làm bằng API chi hộ, kèm phương án đối soát thủ công (đã có trong rủi ro của `project-plan.md` mục 8). Chấp nhận sửa ADR 0009, mục hoàn tiền.
- **B. MoMo cho MVP.** Có API hoàn tiền thật và sandbox công khai, khớp ADR 0009. Trước khi chọn cần xác nhận hộ kinh doanh đăng ký merchant được không, và mất bao lâu.

VNPay xếp sau: phí đăng ký cao và hồ sơ nặng với chuỗi nhỏ.

**Việc tiếp theo nếu chủ dự án đồng ý:** đăng ký sandbox của hướng được chọn, chạy thử tạo thanh toán, webhook và hoàn tiền (hoặc chi hộ), ghi kết quả thành ADR.

## Nguồn (đọc 2026-11-19)

- payOS API: https://payos.vn/docs/api/ · gói miễn phí 2026: https://payos.vn/cong-thanh-toan-mien-phi-payos-2026/ · xác thực: https://payos.vn/docs/huong-dan-su-dung/xac-thuc-to-chuc/
- VNPay sandbox: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html · tài khoản hộ kinh doanh 2026: https://vnpay.vn/tai-khoan-thanh-toan-ho-kinh-doanh-0xz1anvhceql · phí: https://vnpay.vn/vnpay-co-mat-phi-khong-0n1c8gu53a8
- MoMo hoàn tiền: https://developers.momo.vn/v3/docs/payment/api/payment-api/refund/ · IPN: https://developers.momo.vn/v3/docs/payment/api/result-handling/notification/ · chữ ký: https://developers.momo.vn/v3/docs/payment/api/other/signature/
