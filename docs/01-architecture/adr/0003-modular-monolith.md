# ADR-0003: Modular monolith thay vì microservices

- **Trạng thái:** Đã chấp nhận
- **Ngày:** 2026-11-15

## Bối cảnh
Một miền nghiệp vụ, một người phát triển, giao dịch nghiệp vụ gắn chặt (đặt thuê, tồn kho, thanh toán cần nhất quán).

## Các phương án
1. **Microservices:** mở rộng độc lập; chi phí vận hành, giao dịch phân tán, gỡ lỗi phức tạp.
2. **Monolith không ranh giới:** nhanh lúc đầu, rối về sau.
3. **Modular monolith:** một tiến trình, module có ranh giới rõ, giao dịch DB đơn giản.

## Quyết định
Modular monolith với NestJS. Module chỉ gọi nhau qua service công khai; chỉ repository của module sở hữu mới viết SQL cho bảng của nó. Worker là tiến trình riêng cùng mã nguồn.

## Hệ quả
- Giao dịch đặt thuê + giữ chỗ nằm trong một giao dịch DB duy nhất.
- Có thể tách `payments` hoặc `notifications` thành dịch vụ sau nếu cần, nhờ ranh giới module.
- Phải kỷ luật về phụ thuộc giữa module (kiểm bằng lint rule hoặc `dependency-cruiser`).
