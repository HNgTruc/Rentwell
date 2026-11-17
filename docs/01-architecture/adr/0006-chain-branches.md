# ADR 0006: Chuỗi cửa hàng nhiều chi nhánh, gán đơn theo vị trí khách

**Trạng thái:** Chấp nhận (2026-11-15); danh sách sửa lược đồ đã duyệt và áp dụng vào `001_init.sql` (`../../02-database/proposal-003-branches.md`)

## Bối cảnh

Tenant không phải một cửa hàng đơn lẻ mà là **một chuỗi** có nhiều **chi nhánh**. Tất cả dùng chung một website (ADR 0005). Chủ dự án nêu ba quy tắc:

1. Khách thuê trên website/app: hệ thống **định vị khách và chuyển đơn đến chi nhánh gần nhất** để giao hàng, nhằm giảm tiền ship.
2. Thuê ở chi nhánh nào thì **đổi trả ở chi nhánh đó**.
3. Hai quy tắc trên áp dụng chung cho **đơn tại quầy (offline)** và **đơn online**.

Điều này thay đổi hai quyết định trước đó ("mỗi cửa hàng đúng một điểm nhận/trả", tồn kho theo tenant).

## Quyết định

- **Tenant = chuỗi/thương hiệu. Chi nhánh (`branches`) = một điểm nhận/trả cụ thể** (địa chỉ, tọa độ, giờ mở cửa, tỉnh/thành riêng). Mỗi chi nhánh đúng một điểm nhận/trả.
- **Tồn kho theo chi nhánh** (mỗi chi nhánh có kho riêng của từng biến thể).
- **Mỗi đơn thuộc đúng một chi nhánh** (`branch_id`); nhận, giao và trả đều ở chi nhánh đó. Một đơn không tách giữa nhiều chi nhánh.
- **Chọn chi nhánh cho đơn online:** khách nhập địa chỉ trước; hệ thống liệt kê chi nhánh **từ gần đến xa**, chọn sẵn chi nhánh gần nhất còn đủ hàng cho cả đơn (và, nếu giao, cùng tỉnh/thành, trong bán kính). Khách chọn được chi nhánh khác trong danh sách hợp lệ.
- **Đơn tại quầy (offline):** nhân viên chi nhánh tạo đơn; chi nhánh là chi nhánh của nhân viên; thanh toán tại quầy ghi nhận được; cùng luồng trạng thái.
- **Trả đồ chỉ ở đúng chi nhánh của đơn**; hệ thống từ chối bàn giao/nhận lại ở chi nhánh khác.
- Phí giao hàng tính từ **chi nhánh** đến địa chỉ khách; quy tắc chỉ ở **cấp chuỗi**, chi nhánh không ghi đè.
- Nhân viên có thể gắn với một chi nhánh hoặc cả chuỗi.

## Lý do

- Giảm phí ship và thời gian giao cho khách; sát với cách chuỗi vận hành thật.
- Một nguồn tồn kho theo chi nhánh tránh hứa hàng ở nơi không có.
- Quy tắc "trả đúng chi nhánh" đơn giản cho vận hành và đối soát tồn kho.

## Hệ quả

- **Thay đổi lược đồ lớn** (xem proposal-003): `branches`, tồn kho, đơn, bàn giao, phí giao, quyền nhân viên. Vì `001_init.sql` chưa được áp ở đâu, nên đề xuất **sửa thẳng 001 trước khi áp lần đầu** thay vì chồng migration; cần chủ dự án duyệt.
- **Dịch vụ bản đồ và định vị trở thành lõi** (không còn là tùy chọn): tính khoảng cách, địa chỉ → tọa độ. Spike ở P0 phải kiểm cả tính năng này và chi phí.
- **Quyền riêng tư vị trí:** chỉ xin quyền khi cần, dùng vị trí để xếp hạng chi nhánh; không lưu vị trí chính xác ngoài địa chỉ giao của đơn.
- Hàm giữ chỗ tồn kho và kiểm thử đồng thời phải thêm chiều chi nhánh.
- Trang chi nhánh công khai có thể có SEO địa phương (`LocalBusiness` mỗi chi nhánh), xem `docs/07-quality/seo.md`.

## Chi tiết đã chốt (2026-11-15)

- Mỗi chi nhánh sở hữu một kho riêng; chi nhánh gần nhất hết hàng thì chuyển sang chi nhánh gần kế tiếp còn đủ.
- Khách nhập địa chỉ trước, rồi chọn chi nhánh trong danh sách sắp theo khoảng cách.
- Đơn tại quầy (offline) thuộc MVP.
- Phí giao chỉ cấp chuỗi.
- Có chuyển hàng giữa chi nhánh, thuộc nghiệp vụ Kho (quy trình trong `proposal-003-branches.md` mục 3).
- Trả đồ khi hết hạn thuê, ở đúng chi nhánh; trễ thì tính phí trễ. Đổi size do khách tự đến chi nhánh đã thuê, quần áo/thời trang không thu phí.
- Đã áp dụng vào `db/migrations/001_init.sql` (trước lần áp đầu tiên).

Danh sách sửa lược đồ và các điểm còn chờ duyệt: `../../02-database/proposal-003-branches.md` mục 4 và 6.
