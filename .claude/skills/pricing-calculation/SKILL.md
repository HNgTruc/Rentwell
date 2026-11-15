---
name: pricing-calculation
description: Viết hoặc sửa hàm tính giá thuê, phí giao, cọc, phí trễ, hoàn tiền kèm bảng ca kiểm thử. Dùng khi chạm logic tiền hoặc số đêm.
---

# Tính giá (hàm thuần)

Quy tắc nghiệp vụ: `docs/03-api/booking-pricing.md`. Quy tắc code: `.claude/rules/pricing-money.md`. Ca kiểm thử mẫu: `cases.md` cùng thư mục.

## Nguyên tắc

- **Hàm thuần:** đầu vào là dữ liệu (ngày, số lượng, bảng giá, quy tắc), đầu ra là số tiền; không đọc DB, không `new Date()`.
- **Tiền là số nguyên đồng**; làm tròn một lần ở cuối dòng, hướng làm tròn ghi trong code và có kiểm thử.
- **Số đêm** = `end_date − start_date`, khoảng `[start, end)`.
- **Giá mùa tính từng đêm**, rồi áp giảm theo bậc theo quy tắc đã chốt.
- Server tính lại khi tạo đơn; không tin giá từ client.

## Quy trình

1. **Chốt quy tắc trước khi code.** Nếu gặp điểm chưa chốt (giảm bậc áp cho tổng đơn hay từng dòng; cơ sở tính cọc phần trăm; thứ tự giá mùa và giảm bậc), **dừng và hỏi người dùng**, rồi ghi ADR. Không tự chọn.
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
