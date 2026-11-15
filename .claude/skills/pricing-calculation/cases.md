# Ca kiểm thử mẫu cho tính giá

Số liệu dưới đây là **ví dụ minh họa** để định dạng ca kiểm thử, không phải bảng giá thật. Giá trị kỳ vọng ở các ca có giảm bậc hoặc giá mùa phụ thuộc quy tắc chưa chốt (xem ADR); điền sau khi chốt.

## Số đêm

| Ca | Nhận | Trả | Kỳ vọng |
|---|---|---|---|
| Cơ bản | 2026-12-10 | 2026-12-12 | 2 đêm |
| Một đêm | 2026-12-10 | 2026-12-11 | 1 đêm |
| Qua tháng | 2026-12-30 | 2027-01-02 | 3 đêm |
| Năm nhuận | 2028-02-28 | 2028-03-01 | 2 đêm |
| Cùng ngày | 2026-12-10 | 2026-12-10 | Lỗi: không hợp lệ |
| Trả trước nhận | 2026-12-12 | 2026-12-10 | Lỗi: không hợp lệ |

## Giá thuê (giá cơ sở 100.000 đồng mỗi đêm, không giảm, không giá mùa)

| Ca | Số đêm | Số lượng | Kỳ vọng |
|---|---|---|---|
| Một món hai đêm | 2 | 1 | 200.000 |
| Ba món hai đêm | 2 | 3 | 600.000 |
| Số lượng 0 | 2 | 0 | Lỗi |

## Cần ca khi quy tắc đã chốt

- Đơn đi qua ranh giới hai mùa: mỗi đêm một giá.
- Đạt bậc giảm đúng ngưỡng (ví dụ đúng 3 đêm) và dưới ngưỡng một đêm.
- Làm tròn: giá sau giảm không chia hết, kiểm hướng làm tròn.
- Giá mùa chồng lấn: ứng dụng phải từ chối ở bước nhập, không tính.

## Phí giao

| Ca | Điều kiện | Kỳ vọng |
|---|---|---|
| Cùng tỉnh, trong bán kính | `flat_fee` đặt trước | Đúng `flat_fee` |
| `per_km` trong `base_km` đầu | Khoảng cách ≤ `base_km` | Đúng `base_fee` |
| `per_km` vượt `base_km` | Khoảng cách > `base_km` | `base_fee` + `per_km_fee` × km vượt |
| `distance_tiers` | Khoảng cách rơi vào một bậc | Mức phí của bậc |
| Khác tỉnh | `delivery_province_code` ≠ tỉnh cửa hàng | Từ chối `OUT_OF_DELIVERY_AREA` |
| Vượt bán kính | > `max_distance_km` | Từ chối |
| Dưới `min_order_amount` | Tổng đơn thấp | Từ chối giao tận nơi |
| Miễn phí | Tổng đơn ≥ `free_over_amount` | 0 |
| `applies_to` | `outbound`, `return`, `both` | Phí tính đúng số chiều |

## Hủy, phí trễ, hoàn cọc

| Ca | Kỳ vọng |
|---|---|
| Hủy trước mốc sớm nhất | Hoàn theo tỷ lệ mốc đó |
| Hủy sau mốc muộn nhất | Theo chính sách (có thể 0) |
| Trả trễ trong ân hạn | Phí 0 |
| Trả trễ ngoài ân hạn | Phí theo `late_fee_rules`, có mức trần nếu đặt |
| Hoàn cọc | Cọc − phí trễ − bồi thường − phí khác, không âm |
| Phí vượt cọc | Phần thiếu tạo khoản phải thu thêm |
| Tổng hoàn tiền | Không bao giờ vượt tổng đã thu |
