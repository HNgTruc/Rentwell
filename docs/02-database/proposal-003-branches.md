# Đề xuất lược đồ 003: chuỗi nhiều chi nhánh

**Trạng thái:** ĐÃ DUYỆT và ĐÃ ÁP DỤNG vào `001_init.sql` (2026-11-15). Đã chạy thử trên PostgreSQL 16 (47 bảng), kiểm tra: tồn theo chi nhánh, không bán lố, giao khác tỉnh, trả sai chi nhánh, chuyển kho nhiều bước, đổi size, cô lập giữa các chuỗi bằng RLS.
Căn cứ: `../01-architecture/adr/0006-chain-branches.md`.
Phát hiện quan trọng: `001_init.sql` **chưa được áp dụng ở đâu** (P0 chưa bắt đầu), nên đề xuất **sửa thẳng file 001 trước lần áp đầu tiên** thay vì chồng nhiều migration ALTER. Quy tắc "không sửa migration đã áp" chỉ có hiệu lực từ lúc áp lần đầu.
`proposal-002` (đánh giá, bộ phận) được viết trên nền chưa có chi nhánh; sẽ điều chỉnh theo bản này khi làm P6 và P7.

## 1. Quy tắc đã chốt

| # | Quy tắc |
|---|---|
| 1 | **Mỗi chi nhánh sở hữu một kho riêng** (tồn kho theo chi nhánh) |
| 2 | Chi nhánh gần nhất hết hàng thì **chuyển sang chi nhánh gần kế tiếp còn đủ hàng** |
| 3 | **Khách chọn chi nhánh:** nhập địa chỉ trước; hệ thống hiển thị danh sách chi nhánh **sắp theo khoảng cách từ gần đến xa** để khách chọn |
| 4 | **Đơn tại quầy (offline) thuộc MVP** |
| 5 | **Phí giao chỉ cấp chuỗi** (không ghi đè theo chi nhánh); khoảng cách tính từ chi nhánh giao |
| 6 | **Có chuyển hàng giữa chi nhánh**, theo quy trình ở mục 3 |
| 7 | **Trả đồ khi hết hạn thuê, tại đúng chi nhánh đã thuê.** Món có size: khách **tự đến đổi size tại chi nhánh đã thuê** (không đổi online) |
| 8 | Một đơn thuộc đúng một chi nhánh; không tách đơn giữa nhiều chi nhánh |

## 2. Luồng khách đặt thuê online

1. Khách chọn món và ngày.
2. Khách **nhập địa chỉ** (hoặc cho phép định vị). Nếu chọn giao tận nơi, địa chỉ này là địa chỉ giao.
3. Hệ thống tính khoảng cách tới từng chi nhánh và hiển thị danh sách **từ gần đến xa**. Mỗi dòng cho khách thấy: tên chi nhánh, địa chỉ, **khoảng cách**, **còn hàng hay không** cho cả đơn trong mọi đêm, **phí giao** (nếu giao) và giờ nhận/trả.
4. Chi nhánh gần nhất **còn đủ hàng** được chọn sẵn; chi nhánh hết hàng hiện mờ kèm lý do (hoặc xuống cuối) nên khách thấy ngay "gần kế tiếp" nào còn.
5. Với giao tận nơi, chỉ các chi nhánh **cùng tỉnh/thành** với địa chỉ giao và trong bán kính giao mới chọn được. Nhận tại chi nhánh thì mọi chi nhánh còn hàng đều chọn được.
6. Khách xác nhận chi nhánh → server **tính lại** khoảng cách, phí, tồn kho rồi giữ chỗ trong kho chi nhánh đó.
7. Trả đồ: ở đúng chi nhánh đó.

Khoảng cách: lọc thô bằng đường chim bay, rồi tính **khoảng cách đường đi** cho vài chi nhánh đầu danh sách để hạn chế gọi dịch vụ bản đồ (có bộ nhớ đệm). Dịch vụ bản đồ chọn ở spike P0.

## 3. Chuyển hàng giữa chi nhánh (quy trình và bộ phận phụ trách)

**Thuộc bộ phận: Kho (vai trò `warehouse`)**, là nghiệp vụ tồn kho, không phải hỗ trợ khách (`support`). Người duyệt là `manager` (cấp chuỗi, hoặc cấp chi nhánh nguồn); chủ chuỗi xem được tất cả.

**Trạng thái phiếu chuyển:** `requested` → `approved` → `in_transit` → `received` (hoặc `rejected`, `cancelled`).

| Bước | Ai | Việc | Tác động kho |
|---|---|---|---|
| 1. Yêu cầu | Kho hoặc manager chi nhánh nhận | Tạo phiếu: chi nhánh nguồn, chi nhánh đích, biến thể, số lượng, lý do | Chưa đổi |
| 2. Duyệt | Manager (nguồn hoặc chuỗi) | Duyệt hoặc từ chối | Chưa đổi |
| 3. Xuất | Kho chi nhánh nguồn | Đếm, đóng gói, xác nhận xuất | Ghi `transfer_out` ở nguồn: **trừ kho nguồn ngay** |
| 4. Vận chuyển | Kho hoặc người giao | Đang trên đường | Hàng **không dùng được ở đâu** cho đến khi nhận |
| 5. Nhận | Kho chi nhánh đích | Đếm, đối chiếu số lượng, xác nhận nhận | Ghi `transfer_in` ở đích: **cộng kho đích** |
| 6. Chênh lệch | Kho đích + manager | Nhận thiếu, hỏng khi vận chuyển: ghi nhận điều chỉnh có lý do | `lost` hoặc `damaged` có liên kết phiếu |

Quy tắc: không xuất quá số **có thể rút** (kho nguồn phải còn đủ cho các đơn đã giữ chỗ các đêm tương lai; ràng buộc `reserved <= capacity` sẵn có sẽ chặn, API trả lỗi dễ hiểu); mọi biến động đi qua sổ cái chỉ-thêm; phiếu và bước chuyển ghi `audit_logs`; lịch sử chuyển bất biến. Gợi ý (để sau MVP): tự đề xuất chuyển hàng khi một chi nhánh hay hết hàng còn chi nhánh khác dư.

## 4. Danh sách sửa trong `db/migrations/001_init.sql` (chờ duyệt, chưa sửa)

### 4.1 Bảng mới

| Bảng | Nội dung |
|---|---|
| `branches` | `id`, `tenant_id`, `name`, `slug` (duy nhất trong chuỗi), `phone`, `address_line`, `ward_code`, `province_code`, `latitude`, `longitude`, `pickup_time`, `return_time`, `opening_hours`, `delivery_enabled`, `accepts_online`, `status` (`active`/`closed`), thời gian tạo/sửa. Khóa duy nhất `(tenant_id, id)` và `(tenant_id, slug)` |
| `branch_stock` | `tenant_id`, `branch_id`, `variant_id`, `quantity_usable` (CHECK >= 0); khóa chính `(branch_id, variant_id)`. **Nơi duy nhất giữ số lượng dùng được**, chỉ đổi qua sổ cái |
| `stock_transfers` | Phiếu chuyển: `code`, `from_branch_id`, `to_branch_id`, `status`, người yêu cầu/duyệt/xuất/nhận, thời gian, lý do (CHECK nguồn khác đích) |
| `stock_transfer_lines` | Dòng phiếu: `transfer_id`, `variant_id`, `quantity_requested`, `quantity_sent`, `quantity_received` |
| `booking_item_swaps` | Lịch sử **đổi size tại chi nhánh** (chỉ thêm): đơn, dòng đơn, biến thể cũ → mới, số lượng, chênh lệch tiền, người thực hiện, thời gian |

### 4.2 Bảng hiện có

| Bảng | Sửa |
|---|---|
| `tenants` | Giữ thông tin chuỗi (tên, slug, email, tiền tệ, gói, cài đặt, trạng thái). **Bỏ** `address_line`, `ward_code`, `province_code`, `latitude`, `longitude`, `pickup_time`, `return_time`, `opening_hours`, `delivery_enabled` (chuyển sang `branches`). Giữ `phone` làm liên hệ chuỗi |
| `memberships` | Thêm `branch_id` (NULL = cả chuỗi); khóa duy nhất mới `(tenant_id, user_id, role, branch_id)` xử lý NULL; khóa ngoại ghép tới `branches` |
| `item_variants` | **Bỏ** `quantity_usable` (chuyển sang `branch_stock`) |
| `inventory_lots` | Thêm `branch_id` (lô nhập về chi nhánh nào) |
| `inventory_movements` | Thêm `branch_id`; mở rộng `movement_type` thêm `transfer_out` (trừ) và `transfer_in` (cộng); cập nhật biểu thức `delta_usable`; thêm `transfer_id` tùy chọn |
| `inventory_calendar` | Thêm `branch_id`; khóa chính thành `(branch_id, variant_id, night)`; giữ `inventory_not_oversold`; thêm khóa ngoại tới `branch_stock` |
| `delivery_fee_rules` | **Giữ cấp chuỗi** (đã khóa duy nhất theo tenant); không thêm `branch_id`. Khoảng cách tính từ chi nhánh giao |
| `bookings` | Thêm `branch_id NOT NULL` (khóa ngoại ghép), `channel` (`online`/`offline`), `delivery_distance_km` tính từ chi nhánh |
| `handovers` | Thêm `branch_id NOT NULL`; **ràng buộc bằng `bookings.branch_id`** (khóa ngoại ghép `(tenant_id, booking_id, branch_id)` hoặc trigger) cho cả giao và trả |
| `support_tickets` | Thêm `branch_id` tùy chọn (theo đơn), phục vụ định tuyến |
| `payments` | Kiểm tra cột phương thức thanh toán; cần ghi nhận **tiền mặt/chuyển khoản tại quầy** (thêm giá trị nếu thiếu) |

### 4.3 Hàm và trigger

| Hàm / trigger | Sửa |
|---|---|
| `apply_inventory_movement` | Cập nhật `branch_stock` theo `(branch_id, variant_id)` (tạo dòng nếu chưa có) thay vì `item_variants` |
| `sync_calendar_capacity` | Gắn vào `branch_stock`; chỉ đồng bộ capacity của đúng chi nhánh và biến thể |
| `reserve_inventory`, `release_inventory` | Thêm tham số `p_branch`; đọc `branch_stock`; khóa `(branch_id, variant_id, night)` |
| `reserve_booking_inventory`, `release_booking_inventory` | Lấy `branch_id` từ đơn; khóa theo `(branch_id, variant_id)` theo thứ tự cố định |
| `expire_holds` | Không đổi logic; các hàm nó gọi đã theo chi nhánh |
| `validate_booking_delivery` | Đọc `branches` của đơn thay vì `tenants`: chi nhánh bật giao, **cùng tỉnh với địa chỉ giao**, đơn `online` hoặc `offline` đều hợp lệ |
| Mới: kiểm tra trả đúng chi nhánh | Chặn `handovers` có `branch_id` khác chi nhánh của đơn |
| Mới: kiểm tra chuyển kho | Nguồn khác đích; xuất `transfer_out` chỉ khi phiếu `approved`; nhận `transfer_in` chỉ khi `in_transit` |
| Mới: đổi size | Giải phóng và giữ chỗ **trong một giao dịch** (chỉ các đêm còn lại), cùng chi nhánh; ghi `booking_item_swaps` |

### 4.4 RLS và chỉ mục

- RLS: vòng lặp hiện có tự bật `tenant_isolation` cho mọi bảng có cột `tenant_id`, nên các bảng mới (có `tenant_id`) được bảo vệ tự động; chỉ cần kiểm thử.
- Giới hạn theo chi nhánh cho nhân viên làm ở tầng API (chính sách), không ở RLS.
- Chỉ mục mới: `branches (tenant_id, province_code)`, `bookings (tenant_id, branch_id, status)`, `branch_stock (tenant_id, variant_id)`, `stock_transfers (tenant_id, status)`, và chỉ mục khoảng cách ban đầu bằng tọa độ (có thể cân nhắc PostGIS; **thêm tiện ích mở rộng cần bạn duyệt riêng**, mặc định dùng công thức đường chim bay trong ứng dụng).

### 4.5 Seed và kiểm thử đi kèm

- Seed hai chuỗi, mỗi chuỗi ít nhất hai chi nhánh ở các tỉnh khác nhau, kho khác nhau.
- Kiểm thử: cô lập tenant cho bảng mới; không bán quá tồn theo chi nhánh; chọn chi nhánh gần nhất còn hàng và chuyển sang chi nhánh kế tiếp; chặn giao khác tỉnh; chặn trả sai chi nhánh; luồng chuyển kho nhiều bước kể cả nhận thiếu; đổi size giữ nguyên bất biến kho; nhân viên chi nhánh A không thao tác kho/đơn chi nhánh B.

## 5. Tác động lên phần còn lại

- Skill `inventory-reservation`, `rls-isolation-test`, `payment-webhook`: cần cập nhật khi sửa lược đồ (thêm chiều chi nhánh). Sẽ trình bạn trước vì `.claude/**` ở chế độ hỏi trước.
- `docs/02-database/erd.md` và `schema-overview.md`: vẽ lại sau khi sửa.
- `docs/03-api/booking-pricing.md` mục 7 (giữ chỗ) và mục phí giao.
- Kế hoạch: việc P0 "duyệt và sửa 001 trước khi áp" đã thêm vào roadmap.

## 5b. Khác biệt so với đề xuất ban đầu (đã làm)

- Thêm `item_types.free_size_exchange` (quần áo, thời trang = `true`: đổi size không thu phí).
- Đổi size qua hàm `swap_booking_inventory`, giữa hai biến thể **cùng một mẫu**, khi đơn `confirmed` hoặc **đang thuê** (`handed_over`, chốt 2026-11-15: món cũ giữ thêm đêm đệm rồi nhả, món mới giữ từ hôm nay).
- Thêm chính sách `branches_public_read` để trang web chung đọc chi nhánh đang hoạt động công khai.
- Thêm trigger chặn đổi chi nhánh của đơn đã tạo; trả đồ đúng chi nhánh bảo đảm bằng khóa ngoại ghép `(tenant_id, booking_id, branch_id)`.
- Trả trễ: dùng `late_fee_rules` cấp chuỗi và `fees.fee_type = 'late'` có sẵn; hạn trả theo `branches.return_time`.

## 6. Việc đã duyệt

- [x] Danh sách sửa `001_init.sql` ở mục 4 (đặc biệt: bỏ `item_variants.quantity_usable`, thêm `branch_stock`; bỏ cột địa chỉ khỏi `tenants`).
- [x] Sửa thẳng `001_init.sql` trước lần áp đầu (đề xuất) thay vì migration mới.
- [x] Quy trình chuyển hàng ở mục 3, trong đó thuộc bộ phận Kho, `manager` duyệt.
- [x] Quy tắc 7 (trả khi hết hạn thuê; trễ thì tính phí thêm): **"trả hàng khi hết hạn thuê"** (bạn viết "khi hết hàng", mình hiểu là hết hạn thuê). Đổi size chỉ làm tại chi nhánh đã thuê.
- [x] Đổi size: quần áo, thời trang không thu phí; món khác: chênh lệch giá (nếu hai size khác giá) thu hoặc hoàn tại quầy, ghi như khoản phí; được không?
