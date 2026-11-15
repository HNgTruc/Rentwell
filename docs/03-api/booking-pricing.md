# Tính giá, tồn kho và phí giao hàng

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15

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
3. Áp **giảm theo số đêm** (`price_tiers`): bậc theo tổng số đêm của đơn (ví dụ từ 3 đêm giảm 10%).
4. Thành tiền dòng = tổng giá các đêm sau giảm × số lượng.
5. Lưu `price_per_night` (đã gồm giảm bậc/mùa, giá trung bình làm tròn có kiểm soát) cùng snapshot `buffer_nights` vào `booking_items`.

> Quy tắc làm tròn: tính bằng số nguyên đồng; làm tròn một lần ở cuối dòng, hướng làm tròn ghi rõ trong code và kiểm thử. Không cộng dồn sai số.

> Cần chốt khi cài đặt (ghi thành ADR): giảm theo bậc áp cho **tổng đơn** hay **từng dòng**; thứ tự áp giá mùa và giảm bậc.

## 3. Phí giao hàng

Quy tắc ở `delivery_fee_rules` (một bộ cho mỗi cửa hàng), `delivery_fee_tiers` (bậc khoảng cách):

| `mode` | Cách tính |
|---|---|
| `flat` | Một mức phí `flat_fee` cho mọi khoảng cách trong bán kính |
| `per_km` | `base_fee` cho `base_km` đầu tiên; phần vượt cộng `per_km_fee` × km vượt (làm tròn km theo quy tắc ghi trong code) |
| `distance_tiers` | Tra `delivery_fee_tiers` theo khoảng cách → mức phí |

Điều kiện chung:
- `delivery_province_code` của đơn **phải trùng** tỉnh của cửa hàng; khác thì từ chối (422 `OUT_OF_DELIVERY_AREA`), DB cũng chặn bằng trigger.
- Vượt `max_distance_km` thì từ chối.
- Đơn dưới `min_order_amount` (nếu đặt) không được giao tận nơi.
- Miễn phí khi tổng đơn đạt `free_over_amount` (nếu bật).
- Áp cho chiều giao, chiều nhận hoặc cả hai (`applies_to`: `outbound`, `return`, `both`).
- Khoảng cách lấy từ dịch vụ bản đồ, **lưu lại vào đơn** (`delivery_distance_km`) để không tính lại.

## 4. Cọc

- Mức cọc theo cấu hình loại món: `deposit_type` (`fixed` số tiền cố định, hoặc `percent` tối đa 100) và `deposit_value`; cửa hàng đặt. Cơ sở tính phần trăm (giá thuê hay giá trị thay thế `replacement_value`) cần chốt khi cài đặt và ghi thành ADR.
- Cọc nằm trong bảng `deposits`, tách khỏi tiền thuê.
- Hoàn cọc = cọc − phí trễ − bồi thường hư hỏng − phí khác đã chốt; không âm. Phần thiếu (nếu có) tạo `fees` cần thu thêm.

## 5. Phí trễ

- Theo `late_fee_rules` của cửa hàng: đơn giá mỗi ngày trễ (hoặc theo phần trăm giá thuê ngày), có thể có ân hạn vài giờ và mức trần.
- Trễ tính theo thời điểm trả thực tế so với `return_time` của ngày hẹn.

## 6. Chính sách hủy

- `cancellation_policies` theo mốc thời gian trước ngày nhận (ví dụ trước 7 ngày hoàn 100%, 3 đến 7 ngày hoàn 50%, dưới 3 ngày không hoàn).
- Khi hủy: gọi `release_booking_inventory`, tạo hoàn tiền theo mốc.

## 7. Giữ chỗ và đồng thời

1. `POST /v1/bookings` (có `Idempotency-Key`): tính giá lại phía server (không tin giá client), tạo `bookings` trạng thái `hold` với `hold_expires_at`.
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

## Chi nhánh (đề xuất, chờ duyệt)

Đơn thuộc đúng một chi nhánh; phí giao tính từ chi nhánh đến địa chỉ khách; tồn kho giữ chỗ trong kho chi nhánh. Cách chọn chi nhánh gần nhất còn đủ hàng và các ràng buộc: `../02-database/proposal-003-branches.md` mục 3. Cập nhật mục 7 (giữ chỗ) và mục phí giao khi được duyệt.
