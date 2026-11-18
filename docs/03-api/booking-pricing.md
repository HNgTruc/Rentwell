# Tính giá, tồn kho và phí giao hàng

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-17

Đây là phần có rủi ro tiền bạc cao nhất. Mọi công thức là **hàm thuần** (không đọc DB, không đọc đồng hồ), đặt trong `packages/shared` hoặc `apps/api/src/modules/pricing`, có bảng ca kiểm thử.

## 1. Số đêm

- Khoảng thuê `[start_date, end_date)`, số đêm = `end_date − start_date`.
- Nhận 10, trả 12 → 2 đêm. Nhận 10, trả 10 → không hợp lệ.
- Đêm bị chiếm trong lịch tồn: từ `start_date` đến `end_date − 1`, cộng thêm `buffer_nights` sau đó.

Ca kiểm thử bắt buộc: qua tháng, qua năm, năm nhuận (29/2), 1 đêm, tối đa số đêm cho phép.

## 2. Giá thuê một dòng

Cho mỗi `booking_item` (biến thể, số lượng):

1. Giá một đêm cơ sở: `item_types.base_price_per_night`.
2. Nếu có **giá mùa** (`seasonal_prices`) bao trùm đêm đó thì dùng giá mùa cho đêm đó. Tính **từng đêm** vì một đơn có thể đi qua nhiều mùa.
2b. Nếu đêm đó thuộc một **ngày lễ** (`holidays`, bảng dùng chung) mà chuỗi đã gán **phụ thu** (`holiday_surcharges`: phần trăm hoặc số tiền cố định mỗi đêm) thì cộng phụ thu vào giá đêm (ADR 0009; lược đồ: `../02-database/proposal-004-walkin-holidays-config.md`, đã áp vào `001_init.sql`). Hàm tính giá nhận ngày lễ và phụ thu như tham số, không đọc DB.
3. Cộng giá các đêm, rồi áp **giảm theo số đêm** (`price_tiers` của **loại món của dòng này**): bậc cao nhất mà số đêm thuê đạt tới (ví dụ từ 3 đêm giảm 10%). Đêm mùa cũng được giảm.
4. Thành tiền dòng = (tổng giá các đêm − phần giảm bậc) × số lượng.
5. Lưu `price_per_night` (đã gồm giảm bậc/mùa, giá trung bình làm tròn có kiểm soát) cùng snapshot `buffer_nights` vào `booking_items`.

> Quy tắc làm tròn (đã chốt, ADR 0009): tính bằng số nguyên đồng; **làm tròn đến đồng gần nhất (half-up) một lần ở cuối dòng**, ghi rõ trong code và kiểm thử. Không cộng dồn sai số.

> Gia hạn (ADR 0009): tính lại cả dòng theo **tổng số đêm mới** (giá mùa, phụ thu ngày lễ từng đêm, bậc giảm theo tổng đêm), rồi **thu phần chênh** so với số đã thu cho dòng đó.

> Đã chốt (ADR 0008, 2026-11-15): giảm bậc **theo từng dòng**; **giá mùa từng đêm trước, giảm bậc sau** trên tổng của dòng.

## 3. Phí giao hàng

Quy tắc ở `delivery_fee_rules` (một bộ cho mỗi cửa hàng), `delivery_fee_tiers` (bậc khoảng cách):

| `mode` | Cách tính |
|---|---|
| `flat` | Một mức phí `flat_fee` cho mọi khoảng cách trong bán kính |
| `per_km` | `base_fee` cho `base_km` đầu tiên; phần vượt cộng `per_km_fee` × km vượt (km vượt **làm tròn lên** số nguyên km, ADR 0009) |
| `distance_tiers` | Tra `delivery_fee_tiers` theo khoảng cách → mức phí |

Điều kiện chung:
- `delivery_province_code` của đơn **phải trùng** tỉnh của cửa hàng; khác thì từ chối (422 `OUT_OF_DELIVERY_AREA`), DB cũng chặn bằng trigger.
- Vượt `max_distance_km` thì từ chối.
- Đơn dưới `min_order_amount` (nếu đặt) không được giao tận nơi.
- Miễn phí khi tổng đơn đạt `free_over_amount` (nếu bật).
- Áp cho chiều giao, chiều nhận hoặc cả hai (`applies_to`: `outbound`, `return`, `both`).
- Khoảng cách lấy từ dịch vụ bản đồ, **lưu lại vào đơn** (`delivery_distance_km`) để không tính lại.

## 4. Cọc

- Mức cọc theo cấu hình loại món: `deposit_type` (`fixed` số tiền cố định, hoặc `percent` tối đa 100) và `deposit_value`; cửa hàng đặt. Cọc phần trăm tính trên **giá trị thay thế** (`replacement_value` × số lượng; ADR 0008). Cọc cố định tính **theo mỗi món**: `deposit_value` × số lượng (chốt 2026-11-17, ADR 0009). Loại món cọc % thì mọi biến thể phải có `replacement_value > 0` (API kiểm tra).
- Cọc nằm trong bảng `deposits`, tách khỏi tiền thuê. **Cọc thu cùng lúc thanh toán đơn** (một lần trả: thuê + giao + cọc; ADR 0009).
- Hoàn cọc = cọc − phí trễ − bồi thường hư hỏng − phí khác đã chốt; không âm. Phần thiếu (nếu có) tạo `fees` cần thu thêm.

## 5. Phí trễ

- Theo `late_fee_rules` của cửa hàng: đơn giá mỗi ngày trễ (hoặc theo phần trăm giá thuê ngày), có thể có ân hạn vài giờ và mức trần.
- Trễ tính theo thời điểm trả thực tế so với `return_time` của ngày hẹn.
- Đã chốt (ADR 0009): tính **theo ngày**; **ân hạn mặc định 2 giờ** (chuỗi đổi được trong `late_fee_rules`; `grace_hours` mặc định 2 ở DB); quá ân hạn dù chỉ vài giờ tính **trọn 1 ngày**, trễ 1,5 ngày tính 2 ngày; áp mức trần nếu có.

## 6. Chính sách hủy

- `cancellation_policies` theo mốc thời gian trước ngày nhận (ví dụ trước 7 ngày hoàn 100%, 3 đến 7 ngày hoàn 50%, dưới 3 ngày không hoàn).
- Khi hủy: gọi `release_booking_inventory`, tạo hoàn tiền theo mốc.
- Hoàn tiền (ADR 0009): về **đúng kênh đã trả**, hệ thống gửi lệnh hoàn trong **24 giờ**; đơn tại quầy hoàn bằng đúng phương thức đã thu.

## 7. Giữ chỗ và đồng thời

1. `POST /v1/bookings` (có `Idempotency-Key`): tính giá lại phía server (không tin giá client), tạo `bookings` trạng thái `hold` với `hold_expires_at` = thời điểm tạo + **15 phút** (hằng số nền tảng, ADR 0009).
2. Gọi `reserve_booking_inventory`: tăng `reserved` trên từng đêm. Nếu vượt `capacity` → `23514` → 409 `OUT_OF_STOCK` và **giao dịch hoàn tác toàn bộ** (không giữ dở dang).
3. Giao dịch nên khóa theo thứ tự biến thể cố định để tránh khóa chết (deadlock) khi đơn có nhiều dòng.
4. Worker `expire_holds` chạy mỗi phút nhả các đơn hết hạn chưa thanh toán.

## 8. Bảng ca kiểm thử tối thiểu (cho P3)

| Ca | Kỳ vọng |
|---|---|
| 10→12, 1 món, giá cơ sở | 2 đêm × giá |
| Đơn qua ranh giới mùa | Mỗi đêm một giá |
| Đạt bậc giảm 3 đêm | Giảm đúng bậc, làm tròn đúng |
| Giao cùng tỉnh, 5 km, kiểu theo km | Phí đúng công thức |
| Giao khác tỉnh | 422, không tạo đơn |
| Vượt bán kính tối đa | 422 |
| Miễn phí giao khi đủ mức | Phí = 0 |
| Hủy sớm / muộn | Hoàn tiền đúng mốc |
| Trả trễ 1,5 ngày có ân hạn | Phí đúng quy tắc |
| 200 yêu cầu đồng thời, còn 5 | Đúng 5 thành công |
| Đêm thuộc ngày lễ có phụ thu % và phụ thu cố định | Phụ thu cộng vào giá đêm trước giảm bậc |
| Đơn qua ranh giới ngày lễ | Chỉ đêm lễ bị phụ thu |
| Gia hạn từ 2 lên 4 đêm đạt bậc giảm mới | Tính lại cả dòng theo 4 đêm, thu phần chênh |
| Làm tròn half-up (…,5 đồng) | Làm tròn lên đồng gần nhất, một lần cuối dòng |
| Km giao 5,2 km | Tính 6 km |
| Trả trễ 1,5 ngày, ân hạn 2 giờ | Tính 2 ngày (và trễ 1 giờ không tính phí) |

## Chi nhánh (đã chốt, ADR 0006)

Đơn thuộc đúng một chi nhánh; phí giao tính từ chi nhánh đến địa chỉ khách; tồn kho giữ chỗ trong kho chi nhánh (`reserve_booking_inventory` lấy `branch_id` từ đơn, khóa theo `(branch_id, variant_id)` thứ tự cố định). Cách chọn chi nhánh gần nhất còn đủ hàng và các ràng buộc: `../02-database/proposal-003-branches.md` mục 3.

Giới hạn số đơn `hold` chưa thanh toán tính **theo người dùng toàn nền tảng** (hồ sơ khách dùng chung, ADR 0009), không chỉ theo chuỗi. Giới hạn là **3 đơn `hold`** mỗi người dùng (ADR 0009); hằng số cấu hình ở API.
