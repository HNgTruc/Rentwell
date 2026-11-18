# ADR 0013: MoMo là cổng thanh toán cho MVP

**Trạng thái:** Chấp nhận có điều kiện (2026-11-19) · **Người quyết:** chủ dự án

## Bối cảnh

ADR 0009: mỗi chuỗi có merchant riêng, tiền về thẳng chuỗi; hoàn tiền về đúng kênh đã trả, lệnh hoàn gửi trong 24 giờ. Bản so sánh `../../03-api/payment-gateways.md` (2026-11-19) xét payOS, VNPay, MoMo:

- payOS dễ đăng ký nhất nhưng **không có API hoàn tiền**, chỉ có chi hộ (giao dịch mới, phải nạp sẵn tiền).
- VNPay có phí đăng ký cổng từ 2.000.000 đ và hồ sơ nặng với chuỗi nhỏ.
- MoMo có API hoàn tiền (toàn phần và một phần), sandbox công khai, IPN có chữ ký HMAC-SHA256.

## Quyết định

Dùng **MoMo Payment Gateway** cho MVP. Mỗi chuỗi một bộ `partnerCode`, `accessKey`, `secretKey`, lưu theo tenant (mã hóa); IPN nhận theo từng chuỗi và kiểm chữ ký bằng khóa của chuỗi đó.

**Điều kiện:** chủ dự án xác nhận với MoMo rằng hộ kinh doanh đăng ký merchant được, kèm thời gian và phí. Nếu không được, quay lại bản so sánh: phương án dự phòng là payOS với hoàn tiền bằng chi hộ (phải sửa ADR 0009, mục hoàn tiền).

## Hệ quả

- `apps/api/src/integrations/payment/` đặt sau một giao diện chung (tạo thanh toán, kiểm chữ ký IPN, hoàn tiền), để sau MVP thêm cổng khác được.
- Gọi API hoàn tiền của MoMo phải chờ phản hồi ít nhất 30 giây (theo tài liệu MoMo); lệnh hoàn chạy bằng tác vụ nền (BullMQ), thử lại có idempotency.
- MoMo không dựa vào phản hồi IPN của mình để tự hoàn tiền, nên việc đối soát nằm phía Rentwell.
- Việc tiếp theo (trước P4): chạy thử trên sandbox `test-payment.momo.vn` gồm tạo thanh toán, IPN, hoàn toàn phần và một phần; ghi kết quả vào ADR này.
