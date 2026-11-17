---
name: pricing-calculation
description: Viết hoặc sửa hàm tính giá thuê, phí giao, cọc, phí trễ, hoàn tiền kèm bảng ca kiểm thử. Dùng khi chạm logic tiền hoặc số đêm.
---

# Tính giá (hàm thuần)

Quy tắc nghiệp vụ: `docs/03-api/booking-pricing.md`. Quy tắc code: `.claude/rules/pricing-money.md`. Ca kiểm thử mẫu: `cases.md` cùng thư mục.

## Nguyên tắc

- **Hàm thuần:** đầu vào là dữ liệu (ngày, số lượng, bảng giá, quy tắc), đầu ra là số tiền; không đọc DB, không `new Date()`.
- **Tiền là số nguyên đồng**; làm tròn **half-up** (đến đồng gần nhất) **một lần ở cuối dòng**, sau khi nhân số lượng (ADR 0009).
- **Số đêm** = `end_date − start_date`, khoảng `[start, end)`.
- **Thứ tự một dòng** (ADR 0008, 0009): giá từng đêm (giá mùa nếu có) → cộng phụ thu ngày lễ của đêm đó → cộng các đêm → trừ % bậc cao nhất theo số đêm thuê → nhân số lượng → làm tròn.
- Ngày lễ và phụ thu là **tham số đầu vào** (lấy từ `holidays`, `holiday_surcharges` ở tầng service), hàm giá không đọc DB.
- **Km giao làm tròn lên** số nguyên trước khi tính phí.
- **Phí trễ theo ngày**: quá `return_time + grace_hours` dù vài giờ tính trọn 1 ngày.
- **Gia hạn**: tính lại cả dòng theo tổng đêm mới, kết quả là phần chênh phải thu.
- **Cọc %** trên `replacement_value` × số lượng; cọc của dòng cũng là cơ sở so ngưỡng xác minh (`verification_min_deposit`).
- Server tính lại khi tạo đơn; không tin giá từ client.

## Quy trình

1. **Chốt quy tắc trước khi code.** Các điểm đã chốt ở ADR 0008 và 0009. Nếu gặp điểm mới chưa có trong ADR, **dừng và hỏi người dùng**, rồi ghi ADR. Không tự chọn.
2. **Viết bảng ca kiểm thử trước** (xem `cases.md`), gồm ca biên.
3. **Cài hàm thuần** trong `packages/shared` (nếu web/mobile cần báo giá) hoặc `modules/pricing`.
4. **Chạy kiểm thử** cho đến khi xanh.
5. **Tích hợp** vào `POST /v1/quotes` và `POST /v1/bookings` (cùng một hàm, không nhân đôi logic).
6. **Nhờ agent `pricing-reviewer`** rà soát.

## Mẫu bảng ca (table-driven)

```ts
const cases = [
  { name: '10→12, 1 món', start: '2026-12-10', end: '2026-12-12', qty: 1, base: 100_000, expected: 200_000 },
  // ... xem cases.md
];
it.each(cases)('$name', ({ start, end, qty, base, expected }) => {
  expect(calcRental({ start, end, qty, base /* ... */ }).total).toBe(expected);
});
```

## Kiểm tra trước khi xong

- [ ] Không có số thực trong đường tính tiền
- [ ] Mọi quy tắc có ca kiểm thử, gồm ca biên
- [ ] Không phụ thuộc đồng hồ hệ thống
- [ ] Điểm chưa chốt đã được hỏi và ghi ADR
