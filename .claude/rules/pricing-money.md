---
paths:
  - "packages/shared/**"
  - "apps/api/src/modules/pricing/**"
  - "apps/api/src/modules/bookings/**"
  - "apps/api/src/modules/payments/**"
---

# Quy tắc tiền và ngày

- Tiền là số nguyên đồng. Làm tròn **half-up** (đến đồng gần nhất) **một lần** ở cuối dòng, sau khi nhân số lượng (ADR 0009); có kiểm thử.
- Tính giá là **hàm thuần**: không đọc DB, không dùng `new Date()` trực tiếp (nhận đồng hồ qua tham số).
- Số đêm = `end_date - start_date`; nhận 10 trả 12 là 2 đêm; trả cùng ngày nhận không hợp lệ.
- Giá mùa tính **từng đêm**; giảm theo bậc áp theo quy tắc đã chốt trong ADR.
- Phí giao: kiểm tra cùng tỉnh, bán kính tối đa, `min_order_amount`, `free_over_amount`, `applies_to`.
- Mỗi thay đổi công thức phải có bảng ca kiểm thử, gồm ca biên (qua tháng, năm nhuận, qua ranh giới mùa, 1 đêm).
- Server tính lại giá khi tạo đơn; không tin giá từ client.
- Chỗ chưa chốt (cơ sở tính cọc phần trăm, thứ tự áp giảm bậc): hỏi người dùng, ghi ADR, không tự quyết.
