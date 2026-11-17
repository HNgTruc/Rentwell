# Phạm vi MVP

**Trạng thái:** Đã duyệt · **Cập nhật lần cuối:** 2026-11-15

## Quyết định đã chốt

| # | Quyết định |
|---|---|
| 1 | Thuê theo **đêm**: nhận ngày 10, trả ngày 12 = 2 đêm; khoảng `[nhận, trả)` |
| 2 | **Mọi món theo số lượng**; giày hoặc bông tai tính là 1 món; tồn kho theo **biến thể (SKU)** |
| 3 | *(đã sửa 2026-11-15, ADR 0006)* Tenant là **chuỗi** có nhiều **chi nhánh**; mỗi chi nhánh có **đúng một điểm nhận/trả**; tồn kho theo chi nhánh |
| 4 | Giao tận nơi **chỉ trong cùng tỉnh/thành** của chi nhánh giao, không liên tỉnh |
| 5 | **Cửa hàng tự đặt phí giao**: cố định, theo km, hoặc theo bậc khoảng cách; có bán kính tối đa, miễn phí từ mức đơn; áp cho chiều giao, chiều nhận, hoặc cả hai |
| 6 | **Đa tenant**: `tenant_id` mọi bảng, RLS ở PostgreSQL |
| 7 | Vai trò: owner, manager, staff (giao nhận), warehouse, support, customer; super admin là cờ riêng |
| 8 | Mobile phục vụ **cả khách hàng và nhân viên** |
| 9 | Đơn vị hành chính hai cấp: tỉnh/thành và phường/xã |
| 10 | **Đánh giá sản phẩm** (sau MVP, P6): khách thuê xong được đánh giá; **công khai, người chưa đăng nhập cũng xem được, toàn nền tảng**; cửa hàng được trả lời |
| 11 | **Phiếu hỗ trợ định tuyến theo bộ phận** (P7): mỗi cửa hàng cấu hình bộ phận và quy tắc loại phiếu → bộ phận |
| 12 | **Chat** (P7): lớp thời gian thực đặt lên phiếu hỗ trợ, không phải hệ thống riêng. Chi tiết: `../04-product/support-reviews-chat.md` |
| 13 | **Một website chung** cho mọi cửa hàng (chi nhánh), URL theo đường dẫn; khách xem danh mục và đánh giá của cả nền tảng (ADR 0005) |
| 14 | **Chọn chi nhánh theo khoảng cách:** khách nhập địa chỉ, thấy chi nhánh từ gần đến xa; gần nhất hết hàng thì xuống chi nhánh kế tiếp; **thuê ở chi nhánh nào trả ở chi nhánh đó**; áp dụng cả đơn tại quầy và online (ADR 0006) |
| 15 | Mỗi chi nhánh **kho riêng**; **chuyển hàng giữa chi nhánh** thuộc nghiệp vụ Kho; **phí giao chỉ cấp chuỗi**; **đổi size** do khách tự đến chi nhánh đã thuê (quần áo/thời trang không thu phí đổi); trả trễ hạn thì tính phí trễ |
| 16 | *(2026-11-17, ADR 0009)* Mỗi chuỗi có **merchant riêng**, nền tảng không giữ tiền; hồ sơ khách chung thông tin cơ bản, giấy tờ và đơn theo chuỗi; đơn online tự xác nhận khi thanh toán, giữ chỗ 15 phút; có **phụ thu ngày lễ** (bảng ngày lễ dùng chung); khách vãng lai tại quầy chỉ cần tên và sđt |

## Trong phạm vi MVP (đến M4: web chạy trọn một đơn)

- Đăng ký chuỗi và chi nhánh, nhân viên (theo chi nhánh), phân quyền.
- Danh mục món, biến thể, ảnh, lô hàng (ngày/nơi sản xuất, nhà cung cấp, ngày mua).
- Giá cơ bản, giảm theo số đêm, giá theo mùa; chính sách hủy, phí trễ.
- Đặt thuê, giữ chỗ có hạn, hợp đồng thuê, gia hạn.
- Thanh toán và cọc qua một cổng; hoàn cọc.
- Bàn giao hai chiều có ảnh; hư hỏng; phí trễ.
- Phí giao hàng theo quy tắc của chuỗi (chi nhánh có thể ghi đè), tính từ chi nhánh giao.
- Tồn kho theo chi nhánh; đơn online tự gán chi nhánh gần nhất còn hàng; trả đồ đúng chi nhánh; đơn tại quầy (đã chốt thuộc MVP); chuyển hàng giữa chi nhánh; đổi size tại chi nhánh.

## Sau MVP (mobile, CSKH, báo cáo: P6 đến P8)

- App khách và app nhân viên; push; phiếu hỗ trợ; báo cáo; xác minh danh tính.
- Đánh giá sản phẩm (P6); bộ phận hỗ trợ, định tuyến phiếu và chat (P7). Hướng thiết kế đã duyệt: `../02-database/proposal-002-reviews-routing-chat.md`.

## Ngoài phạm vi (backlog)

Thuê theo giờ · giao liên tỉnh · nhiều điểm nhận trả · mã giảm giá và điểm thưởng · thuê dài hạn/định kỳ · bảo hiểm · thanh toán quốc tế · nhận diện hư hỏng bằng AI.

## Tiêu chí chấp nhận MVP

Một đơn đi trọn vòng: khách đặt → thanh toán → giữ chỗ → giao → nhận lại → tính phí → hoàn cọc, trên web, với kiểm thử E2E và kiểm thử tải chống đặt trùng đạt (xem `../06-roadmap/roadmap.md`, M4).
