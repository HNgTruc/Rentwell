# Ca kiểm thử mẫu cho tính giá

Số liệu là **ví dụ minh họa** (không phải bảng giá thật). Quy tắc đã chốt: ADR 0008 (giảm bậc theo dòng, giá mùa từng đêm trước rồi giảm bậc, cọc % trên giá trị thay thế) và ADR 0009 (phụ thu ngày lễ trước giảm bậc, làm tròn half-up, km làm tròn lên, phí trễ theo ngày, gia hạn tính lại theo tổng đêm).

Thứ tự cho một dòng: giá từng đêm (giá mùa nếu có: `base × multiplier_percent / 100`) → cộng phụ thu ngày lễ của đêm đó → cộng các đêm → trừ % bậc cao nhất đạt tới → nhân số lượng → **làm tròn half-up một lần** về số nguyên đồng.

## Số đêm

| Ca | Nhận | Trả | Kỳ vọng |
|---|---|---|---|
| Cơ bản | 2026-12-10 | 2026-12-12 | 2 đêm |
| Một đêm | 2026-12-10 | 2026-12-11 | 1 đêm |
| Qua tháng | 2026-12-30 | 2027-01-02 | 3 đêm |
| Năm nhuận | 2028-02-28 | 2028-03-01 | 2 đêm |
| Cùng ngày | 2026-12-10 | 2026-12-10 | Lỗi: không hợp lệ |
| Trả trước nhận | 2026-12-12 | 2026-12-10 | Lỗi: không hợp lệ |

## Giá thuê

Giả định chung: giá cơ sở 100.000 đồng mỗi đêm; bậc giảm "từ 3 đêm giảm 10%" (nếu ca có dùng).

| Ca | Dữ liệu | Kỳ vọng |
|---|---|---|
| Một món hai đêm | 2 đêm, sl 1, không bậc | 200.000 |
| Ba món hai đêm | 2 đêm, sl 3 | 600.000 |
| Số lượng 0 | sl 0 | Lỗi |
| Dưới ngưỡng bậc một đêm | 2 đêm, bậc từ 3 đêm | 200.000 (không giảm) |
| Đúng ngưỡng bậc | 3 đêm, bậc 10% | 270.000 |
| Qua ranh giới mùa | 2 đêm, đêm thứ hai mùa 120% | 100.000 + 120.000 = 220.000 |
| Mùa và bậc | 3 đêm đều mùa 120%, bậc 10% | 360.000 × 90% = 324.000 |
| Ngày lễ phụ thu % | 3 đêm, đêm giữa là lễ +20%, bậc 10% | (100.000 + 120.000 + 100.000) × 90% = 288.000 |
| Ngày lễ phụ thu cố định | 2 đêm, đêm thứ hai lễ +50.000 | 250.000 |
| Lễ chồng mùa | 1 đêm mùa 120% và lễ +20% (của giá đêm) | 120.000 + 24.000 = 144.000 |
| Qua ranh giới ngày lễ | 3 đêm, chỉ đêm cuối là lễ | Chỉ đêm cuối bị phụ thu |
| Chuỗi không gán phụ thu cho ngày lễ đó | Đêm lễ, không có `holiday_surcharges` | Giá như ngày thường |
| Làm tròn xuống | Giá 33.333, 3 đêm, bậc 10%, sl 1 | 99.999 × 90% = 89.999,1 → 89.999 |
| Làm tròn half-up | Giá 33.335, 3 đêm, bậc 10%, sl 1 | 100.005 × 90% = 90.004,5 → 90.005 |
| Làm tròn sau khi nhân số lượng | Giá 33.335, 3 đêm, bậc 10%, sl 3 | 100.005 × 3 × 90% = 270.013,5 → 270.014 (không phải 90.005 × 3) |
| Giá mùa chồng lấn | Hai khoảng mùa trùng ngày | Ứng dụng từ chối ở bước nhập, không tính |

## Gia hạn (tính lại theo tổng đêm mới, thu phần chênh)

| Ca | Dữ liệu | Kỳ vọng |
|---|---|---|
| Gia hạn chạm bậc mới | Đã thu 2 đêm = 200.000; gia hạn thành 4 đêm, bậc từ 3 đêm 10% | Tổng mới 400.000 × 90% = 360.000; thu thêm 160.000 |
| Gia hạn qua ngày lễ | Đêm thêm là lễ +20% | Đêm đó phụ thu; tính lại cả dòng |
| Gia hạn không chạm bậc | 1 → 2 đêm, bậc từ 3 đêm | Thu thêm 100.000 |

## Cọc

| Ca | Dữ liệu | Kỳ vọng |
|---|---|---|
| Cọc cố định | `fixed` 500.000, sl 2 | 1.000.000 (theo mỗi món: cố định × số lượng, ADR 0009) |
| Cọc % giá trị thay thế | `percent` 30, `replacement_value` 2.000.000, sl 2 | 1.200.000 |
| Thiếu giá trị thay thế | `percent`, `replacement_value` = 0 | Lỗi, không báo giá |
| Cần xác minh danh tính | `requires_verification`, `verification_min_deposit` 1.000.000, cọc dòng 1.200.000 | Bắt xác minh |
| Dưới ngưỡng xác minh | Như trên, cọc dòng 800.000 | Không bắt |

## Phí giao

Km làm tròn **lên** số nguyên trước khi tính.

| Ca | Điều kiện | Kỳ vọng |
|---|---|---|
| Cùng tỉnh, trong bán kính | `flat_fee` đặt trước | Đúng `flat_fee` |
| `per_km` trong `base_km` đầu | Khoảng cách ≤ `base_km` | Đúng `base_fee` |
| `per_km` vượt `base_km` | `base_fee` 15.000 cho 3 km, `per_km_fee` 5.000, khoảng cách 5,2 km | 6 km → 15.000 + 3 × 5.000 = 30.000 |
| Km tròn sẵn | 5,0 km | Tính 5 km |
| `distance_tiers` | Khoảng cách (đã làm tròn lên) rơi vào một bậc | Mức phí của bậc |
| Khác tỉnh | `delivery_province_code` ≠ tỉnh chi nhánh | Từ chối `OUT_OF_DELIVERY_AREA` |
| Vượt bán kính | > `max_distance_km` | Từ chối |
| Dưới `min_order_amount` | Tổng đơn thấp | Từ chối giao tận nơi |
| Miễn phí | Tổng đơn ≥ `free_over_amount` | 0 |
| `applies_to` | `outbound`, `return`, `both` | Phí tính đúng số chiều |

## Phí trễ (theo ngày, ân hạn mặc định 2 giờ)

Giả định: `return_time` 18:00 ngày `end_date`; `grace_hours` 2; phí 100% giá một đêm (`price_per_night` đã lưu ở dòng đơn) mỗi ngày.

| Ca | Trả thực tế | Kỳ vọng |
|---|---|---|
| Đúng hạn | 17:30 ngày `end_date` | 0 |
| Trong ân hạn | 19:30 ngày `end_date` | 0 |
| Vừa quá ân hạn | 20:01 ngày `end_date` | 1 ngày |
| Trễ nửa ngày | 06:00 ngày `end_date + 1` (12 giờ) | 1 ngày |
| Trễ 1,5 ngày | 06:00 ngày `end_date + 2` (36 giờ) | 2 ngày |
| Có trần | Trễ 10 ngày, `max_nights_charged` 5 | 5 ngày |

## Hủy, hoàn tiền, hoàn cọc

| Ca | Kỳ vọng |
|---|---|
| Hủy trước mốc sớm nhất | Hoàn theo tỷ lệ mốc đó |
| Hủy sau mốc muộn nhất | Theo chính sách (có thể 0) |
| Khách không đến nhận | Hủy, hoàn cọc, giữ tiền thuê |
| Thanh toán đến sau khi hết hạn, hết hàng | Hoàn toàn bộ số đã thu |
| Hoàn cọc | Cọc − phí trễ − bồi thường − phí khác, không âm |
| Phí vượt cọc | Phần thiếu tạo khoản phải thu thêm |
| Tổng hoàn tiền | Không bao giờ vượt tổng đã thu |
