# ADR 0009: Quy tắc nghiệp vụ chốt trước P0 (tiền, tài khoản khách, giữ chỗ, phí, ngày lễ)

**Trạng thái:** Chấp nhận (2026-11-17) · **Người quyết:** chủ dự án

## Bối cảnh

Rà soát toàn bộ tài liệu trước P0 cho thấy nhiều quy tắc nghiệp vụ chưa văn bản nào nêu rõ. Chủ dự án đã trả lời từng câu hỏi ngày 2026-11-17; ADR này gom lại để làm nguồn tham chiếu. Chi tiết lược đồ đi kèm: `../../02-database/proposal-004-walkin-holidays-config.md`.

## Quyết định

| # | Chủ đề | Quyết định |
|---|---|---|
| 1 | Mô hình tiền | Mỗi chuỗi có **merchant riêng** ở cổng thanh toán; tiền về thẳng chuỗi. Nền tảng không giữ tiền, không chia tiền, không thu hoa hồng ở MVP |
| 2 | Hồ sơ khách | `users` và `user_addresses` **dùng chung toàn nền tảng** (tên, sđt, email, địa chỉ giao). Giấy tờ xác minh, điểm tin cậy, danh sách đen, đơn, phiếu hỗ trợ **vẫn theo từng chuỗi** (`customer_profiles` và các bảng có `tenant_id`). Chuỗi không thấy dữ liệu của khách ở chuỗi khác |
| 3 | Duyệt đơn | Đơn online **tự `confirmed`** khi webhook báo thanh toán thành công; cửa hàng không duyệt tay. Cửa hàng chỉ hủy hoặc đổi khi có sự cố |
| 4 | Hạn giữ chỗ | **15 phút** (`hold_expires_at = tạo + 15 phút`). Giá trị này là hằng số nền tảng ở MVP, chưa có cài đặt theo chuỗi |
| 5 | Cọc | Thu **cùng lúc thanh toán đơn** (thuê + giao + cọc, một lần trả). Hoàn cọc là một khoản hoàn tiền riêng sau khi trả đồ |
| 6 | Hoàn tiền | Hoàn **về đúng kênh đã trả**, hệ thống gửi lệnh hoàn trong **24 giờ**; thời gian tiền về tùy ngân hàng. Đơn tại quầy: cửa hàng ghi nhận hoàn bằng đúng phương thức đã thu |
| 7 | Làm tròn | Tiền: làm tròn **đến đồng gần nhất** (half-up), một lần ở cuối dòng. Km tính phí giao: **làm tròn lên** số nguyên km |
| 8 | Phí trễ | Theo **ngày**; **ân hạn mặc định 2 giờ** sau `return_time`; quá ân hạn dù chỉ vài giờ tính **trọn 1 ngày**. Ân hạn, mức phí, trần vẫn do chuỗi đặt trong `late_fee_rules`; 2 giờ là `DEFAULT` sẵn có của `grace_hours` ở DB |
| 9 | Ngày lễ | Có **bảng ngày lễ dùng chung** (nền tảng quản lý, không thuộc tenant) làm lịch tham chiếu. **Chuỗi gán phụ thu** cho từng ngày lễ. Thứ tự tính giá: xem mục "Thứ tự tính giá cập nhật" |
| 10 | Gia hạn | Tính lại theo **tổng số đêm mới** của dòng đơn (giá mùa và phụ thu từng đêm, bậc giảm theo tổng đêm), **thu phần chênh** so với đã thu |
| 11 | Đơn tại quầy | Khách vãng lai **chỉ cần tên và số điện thoại**, không bắt tài khoản. Tạo hồ sơ khách theo chuỗi không gắn `user`; sau này liên kết được với tài khoản. Không qua `hold`: tạo thẳng `confirmed` khi đã ghi nhận thu tiền tại quầy |
| 12 | Đóng chi nhánh | **Chặn đóng** khi còn đơn mở (`hold`, `confirmed`, `handed_over`, `returned`) hoặc còn tồn kho, hoặc phiếu chuyển hàng chưa xong (`requested`, `approved`, `in_transit`) tại chi nhánh đó. Trigger ở DB chặn (mã `BRANCH_HAS_OPEN_BOOKINGS`, `BRANCH_HAS_STOCK`, `BRANCH_HAS_OPEN_TRANSFERS`); API liệt kê việc còn lại |
| 13 | Xác minh danh tính | Chuỗi **bật theo từng loại món** và đặt **ngưỡng** (cọc hoặc giá trị thay thế); nền tảng không đặt ngưỡng cứng. Làm ở P7 |
| 14 | Giờ mở cửa | `branches.opening_hours` có định dạng cố định: mỗi thứ trong tuần một khung giờ hoặc nghỉ. Không hỗ trợ nghỉ trưa hay ngày lễ riêng ở MVP. "Hết ngày nhận" tính theo giờ đóng cửa của ngày đó |

### Thứ tự tính giá cập nhật (bổ sung ADR 0008)

ADR 0008 giữ nguyên, thêm một bước cho phụ thu ngày lễ. Cho mỗi đêm của một dòng:

1. Giá đêm = giá mùa nếu có, không thì `base_price_per_night` (như ADR 0008).
2. Nếu đêm đó là ngày lễ mà chuỗi đã gán phụ thu cho ngày lễ đó: cộng phụ thu vào giá đêm (phụ thu theo **phần trăm** của giá đêm, hoặc **số tiền cố định**; chọn một khi cấu hình).
3. Cộng giá các đêm, trừ giảm bậc theo số đêm, nhân số lượng, làm tròn một lần (như ADR 0008). **Phụ thu ngày lễ nằm trong tổng trước khi giảm bậc**, nên đêm lễ cũng được giảm bậc (nhất quán với đêm mùa).

Đã được chủ dự án xác nhận ngày 2026-11-17 (phụ thu cộng trước giảm bậc).

## Hệ quả

- `proposal-004` thêm: hồ sơ khách vãng lai, bảng ngày lễ và phụ thu theo chuỗi, cờ xác minh trên loại món, chuẩn `opening_hours`, ràng buộc đóng chi nhánh.
- `booking-pricing.md` và `booking-flow.md` cập nhật theo bảng trên; ca kiểm thử giá thêm ca ngày lễ và gia hạn.
- Spike cổng thanh toán (P0) phải kiểm: mỗi chuỗi tự đăng ký merchant được không (hay cổng cho nhiều merchant dưới một ứng dụng), hoàn tiền qua API, và cách nhận webhook theo từng chuỗi (khóa và chữ ký lưu theo tenant).
- Không có bảng chia tiền, công nợ, hoa hồng. Nếu sau này nền tảng muốn thu hộ thì cần ADR mới và xem xét điều kiện pháp lý.
- Khách có tài khoản chung nên **giới hạn số đơn `hold` chưa thanh toán tính theo người dùng toàn nền tảng**, không chỉ theo chuỗi.

## Bổ sung ngày 2026-11-17 (sau khi duyệt proposal-004)

- Ngưỡng xác minh so với **cọc của dòng** (cột `item_types.verification_min_deposit`; cờ `requires_verification` đã có sẵn).
- Giới hạn **3 đơn `hold`** chưa thanh toán mỗi người dùng trên toàn nền tảng.
- **Cọc cố định tính theo mỗi món**: `deposit_value` × số lượng (giống cọc % cũng nhân số lượng).
- `001_init.sql` đã sửa theo proposal-004 (49 bảng); đã chạy thử trên PostgreSQL 16.16, 19/19 ca kiểm thử đạt.

## Điểm còn mở

- Dịch vụ bản đồ và cổng thanh toán cụ thể: spike P0.

## Phương án đã cân nhắc

- Nền tảng thu hộ rồi chia: cần bảng công nợ và giấy phép trung gian thanh toán, quá nặng cho MVP; bị loại.
- Hồ sơ khách chung cả giấy tờ xác minh: dữ liệu nhạy cảm bị chia sẻ chéo chuỗi, cần đồng ý và rà pháp lý; bị loại.
- Ngày lễ dùng thuần giá mùa (không có bảng ngày lễ): đơn giản hơn nhưng chuỗi phải tự nhập lại ngày lễ hằng năm; chủ dự án chọn có lịch chung.
- Hạn giữ chỗ 30 phút hoặc cài đặt theo chuỗi: để sau nếu có nhu cầu thật.
