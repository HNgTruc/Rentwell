# ADR 0008: Thứ tự tính giá, giảm theo số đêm và cơ sở cọc phần trăm

**Trạng thái:** Chấp nhận (2026-11-15)

## Bối cảnh

`docs/03-api/booking-pricing.md` để ngỏ ba điểm cần chốt trước khi viết hàm tính giá (P3): giảm theo số đêm áp cho tổng đơn hay từng dòng; thứ tự giữa giá mùa và giảm bậc; cọc theo phần trăm tính trên cơ sở nào.

## Quyết định

1. **Giảm theo số đêm áp cho từng dòng**, theo bậc của chính loại món đó (`price_tiers` gắn `item_type_id`). Số đêm dùng để chọn bậc là số đêm thuê của đơn (không tính đêm đệm).
2. **Thứ tự cho một dòng:**
   1. Mỗi đêm lấy giá của đêm đó: giá mùa nếu có `seasonal_prices` bao trùm, không thì `base_price_per_night`.
   2. Cộng giá các đêm.
   3. Trừ phần trăm của bậc cao nhất mà số đêm đạt tới (đêm mùa cũng được giảm).
   4. Nhân số lượng; làm tròn một lần ở cuối dòng (số nguyên đồng).
3. **Cọc phần trăm tính trên giá trị thay thế** (`item_variants.replacement_value`) × số lượng, snapshot vào `booking_items.replacement_value_snapshot`. Cọc cố định (`fixed`) giữ nguyên.
   - Loại món đặt `deposit_type = 'percent'` thì mọi biến thể phải có `replacement_value > 0`; API kiểm tra khi lưu loại món, biến thể và khi báo giá (CSDL không chặn được vì hai bảng khác nhau).

## Hệ quả

- Hàm tính giá là hàm thuần trong module `pricing`; ca kiểm thử bổ sung vào `.claude/skills/pricing-calculation/cases.md` khi làm P3 (đơn qua mùa và đủ bậc; cọc % với `replacement_value` lớn; thiếu `replacement_value`).
- Báo giá hiển thị từng dòng: giá theo đêm, phần giảm bậc, cọc.

## Phương án đã cân nhắc

- Giảm trên tổng đơn: đơn giản cho khách nhưng cửa hàng không đặt được mức giảm riêng từng món; không khớp `price_tiers` theo loại món.
- Không giảm đêm mùa: bảo vệ doanh thu cao điểm nhưng khó giải thích và phụ thuộc cách chia đêm.
- Cọc % trên tiền thuê: thuê ngắn món đắt thì cọc quá thấp so với rủi ro mất, hỏng.
