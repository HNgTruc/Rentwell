---
name: payment-webhook
description: Xử lý webhook thanh toán, cọc và hoàn tiền đúng cách (chữ ký, idempotent, đối soát). Dùng khi tích hợp hoặc sửa cổng thanh toán.
---

# Webhook thanh toán

Giai đoạn P4. Cổng thanh toán chưa chốt (PayOS, VNPay hoặc MoMo; xem spike trong `docs/01-architecture/tech-stack.md`). Skill này mô tả khuôn xử lý chung, không phụ thuộc cổng; chi tiết chữ ký và định dạng lấy từ **tài liệu chính thức của cổng đã chọn**, không đoán.

## Bảng liên quan

- `payment_webhook_events`: `provider`, `event_id`, `tenant_id`, `payload`, `received_at`, `processed_at`, **`UNIQUE (provider, event_id)`**.
- `payments` (`kind`: `rental`, `deposit`, `fee`; `idempotency_key`), `deposits` (`pending`, `held`, `released`, `partially_deducted`, `forfeited`), `refunds`.

## Khuôn xử lý

1. **Nhận thô:** endpoint công khai `POST /v1/webhooks/payments/:provider`, đọc **body thô** để kiểm tra chữ ký (parse JSON trước có thể làm sai chữ ký).
2. **Kiểm tra chữ ký** bằng khóa bí mật của cổng; sai thì 401 và không ghi nhận tác động.
3. **Chống trùng:** chèn vào `payment_webhook_events`; vi phạm `UNIQUE (provider, event_id)` nghĩa là đã nhận, trả 200 và dừng (không xử lý lần hai).
4. **Đối chiếu với cổng** (gọi API truy vấn giao dịch) nếu cổng hỗ trợ; không tin hoàn toàn vào nội dung webhook.
5. **Xác định tenant và đơn** từ dữ liệu giao dịch, rồi mở giao dịch với `SET LOCAL app.tenant_id` tương ứng.
6. **Kiểm tra trạng thái hiện tại** của đơn trước khi chuyển (webhook có thể đến trễ hoặc đảo thứ tự).
7. **Ghi tác động trong một giao dịch:** cập nhật `payments`, chuyển đơn `hold → confirmed`, ghi `booking_status_history`, cập nhật `deposits` nếu có.
8. Đánh dấu `processed_at`; luôn trả 200 nhanh khi đã nhận hợp lệ để cổng không gửi lại vô ích.
9. Lỗi xử lý tạm thời: để hàng đợi thử lại (BullMQ); không mất sự kiện (đã lưu ở bước 3).

## Ca đặc biệt cần quyết định (hỏi người dùng, ghi ADR)

- Thanh toán đến sau khi giữ chỗ **đã hết hạn**: tồn đã nhả. Hoàn tiền tự động hay cấp lại nếu còn trống?
- Thanh toán thiếu hoặc thừa so với đơn.
- Cổng gửi sự kiện thất bại/hủy sau khi đã thành công.

## Hoàn tiền và cọc

- Tổng hoàn tiền **không bao giờ vượt** tổng đã thu.
- Hoàn cọc = cọc − phí trễ − bồi thường − phí khác đã chốt, không âm; phần thiếu tạo khoản phải thu thêm.
- Mọi biến động tiền có bản ghi truy vết được đến đơn; thao tác hoàn tiền ghi `audit_logs` và cần quyền manager trở lên.

## Đối soát

Worker chạy cuối ngày: so `payments` với báo cáo của cổng, cảnh báo khi lệch. Không tự sửa số liệu; chỉ báo.

## Kiểm thử bắt buộc

- Gửi cùng một webhook 10 lần → đúng một tác động.
- Chữ ký sai → từ chối, không ghi tác động.
- Webhook đảo thứ tự hoặc đến trễ không làm sai trạng thái đơn.
- Hoàn tiền vượt tổng đã thu bị chặn.
- Dùng sandbox của cổng ở môi trường dev và staging; không dùng khóa thật.
