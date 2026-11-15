---
paths:
  - "apps/api/**"
---

# Quy tắc API (NestJS)

- Controller mỏng: kiểm tra đầu vào (Zod), gọi service, trả kết quả. Nghiệp vụ nằm trong service.
- Phân quyền bằng guard theo `memberships`; kiểm tra thêm quyền sở hữu tài nguyên (khách chỉ thấy đơn của mình). Ma trận ở `docs/04-product/roles-permissions.md`.
- Tenant lấy từ token và membership, không đọc từ body.
- Lỗi theo RFC 9457 (`type`, `title`, `status`, `code`, `detail`, `request_id`). Ánh xạ `23514` thành 409 `OUT_OF_STOCK` hoặc 422 `OUT_OF_DELIVERY_AREA`.
- Thao tác ghi liên quan tiền hoặc tồn kho bắt buộc header `Idempotency-Key`.
- Webhook thanh toán: kiểm tra chữ ký, lưu `payment_webhook_events` theo mã sự kiện duy nhất.
- Module chỉ gọi nhau qua service công khai, không đọc bảng của module khác.
- Thao tác nhạy cảm (đổi vai trò, hoàn tiền, điều chỉnh kho) ghi `audit_logs`.
- Không log dữ liệu cá nhân hay token; log có `request_id`, `tenant_id`.
