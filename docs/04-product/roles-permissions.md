# Vai trò và phân quyền (RBAC)

**Trạng thái:** Nháp (phạm vi chi nhánh đã chốt 2026-11-15) · **Cập nhật lần cuối:** 2026-11-15

## Cách phân quyền

- Quyền gắn với **membership** (người dùng × cửa hàng × vai trò), không gắn trực tiếp với người dùng. Một người có thể là khách ở cửa hàng A và nhân viên ở cửa hàng B.
- `super_admin` là cờ riêng trên người dùng, chỉ dùng cho quản trị nền tảng.
- **Kiểm tra ở hai lớp:** guard trong API (vai trò + quyền sở hữu tài nguyên) và RLS ở CSDL (cô lập tenant). Ẩn nút trên giao diện **không phải** biện pháp bảo mật.
- Khách chỉ thấy đơn của chính mình (kiểm tra sở hữu, không chỉ kiểm tra vai trò).

## Phạm vi theo chi nhánh

Tenant là chuỗi nhiều chi nhánh (ADR 0006). Membership có thể gắn với **một chi nhánh** (`branch_id`) hoặc **cả chuỗi** (`branch_id` rỗng). `owner` và manager cấp chuỗi thấy mọi chi nhánh; manager cấp chi nhánh, `staff`, `warehouse`, `support` gắn chi nhánh chỉ thấy đơn, kho, phiếu, nhân viên của chi nhánh mình. Bàn giao và nhận lại chỉ làm ở chi nhánh của đơn. Lược đồ: `../02-database/proposal-003-branches.md` (đã áp dụng).

Giới hạn chi nhánh được kiểm tra ở API (policy của từng module); RLS ở CSDL chỉ cô lập giữa các chuỗi.

## Ma trận quyền

Ký hiệu: **X** toàn quyền · **R** chỉ xem · **C** tạo/sửa trong phạm vi việc của mình · **B** chỉ trong chi nhánh của mình · **–** không có.
"Manager chuỗi" = manager không gắn chi nhánh; "manager CN" = manager gắn một chi nhánh.

| Chức năng | owner | manager chuỗi | manager CN | staff (giao nhận) | warehouse | support | customer |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Thông tin chuỗi (tên, liên hệ, gói) | X | R | R | – | – | – | – |
| Tạo, đóng chi nhánh | X | – | – | – | – | – | – |
| Cài đặt chi nhánh (địa chỉ, giờ mở cửa, giao hàng, nhận đơn online) | X | X | R (B) | – | – | – | R (công khai) |
| Nhân viên và vai trò | X | C (không đổi owner) | B (staff, warehouse, support; không tạo manager) | – | – | – | – |
| Danh mục, giá, chính sách | X | X | R | – | R | R | R (công khai) |
| Quy tắc phí giao, phí trễ (cấp chuỗi) | X | X | R | – | – | – | – |
| Nhập/xuất/điều chỉnh kho | X | X | B | – | B | – | – |
| Yêu cầu chuyển hàng | X | X | B | – | B | – | – |
| Duyệt phiếu chuyển hàng | X | X (mọi phiếu) | B (phiếu xuất **từ** chi nhánh mình) | – | – | – | – |
| Xuất, nhận hàng chuyển | X | X | B | – | B | – | – |
| Tạo đơn tại quầy, đổi size cho khách | X | X | B | B | B | – | – |
| Xem đơn thuê | X | X | B | R (đơn được giao, B) | R (đơn cần soạn, B) | R (B nếu gắn CN) | R (đơn của mình) |
| Duyệt, hủy, đổi đơn | X | X | B | – | – | C (đề xuất) | C (hủy đơn của mình) |
| Bàn giao khi giao/nhận | X | X | B | B | B | – | – |
| Ghi hư hỏng, bồi thường | X | X | B | C (ghi nhận, B) | C (ghi nhận, B) | R | R (đơn của mình) |
| Thanh toán, hoàn cọc | X | X | B | – | – | R | C (thanh toán đơn mình) |
| Phiếu hỗ trợ | X | X | B | – | – | X (phiếu của bộ phận mình) | C (của mình) |
| Bộ phận hỗ trợ, quy tắc định tuyến | X | X | – | – | – | – | – |
| Đánh giá sản phẩm | X (xem, trả lời) | X (xem, trả lời, ẩn) | R | – | – | R | C (viết cho đơn đã hoàn tất; xem công khai) |
| Báo cáo doanh thu | X | R | R (B) | – | – | – | – |
| Nhật ký thao tác (audit) | X | R | R (B) | – | – | – | – |

Quy tắc bổ sung:
- Hoàn cọc và hủy đơn sau khi đã giao cần quyền manager trở lên (manager CN chỉ với đơn của chi nhánh mình).
- Manager CN không tự nâng quyền: không tạo manager, không gán người vào chi nhánh khác, không đổi phạm vi của chính mình.
- Giá, danh mục, chính sách, phí giao, phí trễ chỉ đặt ở cấp chuỗi, dùng chung mọi chi nhánh.
- Chỉ owner đổi chủ sở hữu hoặc xóa cửa hàng.
- Thao tác nhạy cảm (đổi vai trò, hoàn tiền, điều chỉnh kho thủ công) **bắt buộc ghi `audit_logs`**.

## Quyền super admin

- Xem danh sách cửa hàng, khóa/mở khóa, số liệu hệ thống.
- **Không** mặc định xem nội dung nghiệp vụ của cửa hàng; truy cập hỗ trợ phải có lý do và được ghi nhật ký.

## Kiểm thử bắt buộc

Mỗi ô trong ma trận có kiểm thử tự động cho cả hướng cho phép lẫn từ chối. Thêm ca: người dùng đổi `id` tài nguyên sang tài nguyên của người/tenant khác phải nhận 404 hoặc 403.
