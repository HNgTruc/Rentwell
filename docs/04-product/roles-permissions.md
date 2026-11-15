# Vai trò và phân quyền (RBAC)

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15

## Cách phân quyền

- Quyền gắn với **membership** (người dùng × cửa hàng × vai trò), không gắn trực tiếp với người dùng. Một người có thể là khách ở cửa hàng A và nhân viên ở cửa hàng B.
- `super_admin` là cờ riêng trên người dùng, chỉ dùng cho quản trị nền tảng.
- **Kiểm tra ở hai lớp:** guard trong API (vai trò + quyền sở hữu tài nguyên) và RLS ở CSDL (cô lập tenant). Ẩn nút trên giao diện **không phải** biện pháp bảo mật.
- Khách chỉ thấy đơn của chính mình (kiểm tra sở hữu, không chỉ kiểm tra vai trò).

## Phạm vi theo chi nhánh

Tenant là chuỗi nhiều chi nhánh (ADR 0006). Membership có thể gắn với **một chi nhánh** hoặc **cả chuỗi**. `owner` và manager cấp chuỗi thấy mọi chi nhánh; manager cấp chi nhánh, `staff`, `warehouse`, `support` gắn chi nhánh chỉ thấy đơn, kho, phiếu của chi nhánh mình. Bàn giao và nhận lại chỉ làm ở chi nhánh của đơn. Chi tiết chờ duyệt: `../02-database/proposal-003-branches.md`.

## Ma trận quyền

Ký hiệu: **X** toàn quyền · **R** chỉ xem · **C** tạo/sửa trong phạm vi việc của mình · **–** không có.

| Chức năng | owner | manager | staff (giao nhận) | warehouse | support | customer |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Thông tin cửa hàng, điểm nhận/trả | X | R | – | – | – | – |
| Nhân viên và vai trò | X | C (không đổi owner) | – | – | – | – |
| Danh mục, giá, chính sách | X | X | – | R | R | R (công khai) |
| Quy tắc phí giao, phí trễ | X | X | – | – | – | – |
| Nhập/xuất/điều chỉnh kho | X | X | – | X | – | – |
| Chuyển hàng giữa chi nhánh (yêu cầu, xuất, nhận) | X | X (duyệt) | – | C (yêu cầu, xuất, nhận) | – | – |
| Tạo đơn tại quầy, đổi size cho khách | X | X | C | C | – | – |
| Xem đơn thuê | X | X | R (đơn được giao) | R (đơn cần soạn) | R | R (đơn của mình) |
| Duyệt, hủy, đổi đơn | X | X | – | – | C (đề xuất) | C (hủy đơn của mình) |
| Bàn giao khi giao/nhận | X | X | C | C | – | – |
| Ghi hư hỏng, bồi thường | X | X | C (ghi nhận) | C (ghi nhận) | R | R (đơn của mình) |
| Thanh toán, hoàn cọc | X | X | – | – | R | C (thanh toán đơn mình) |
| Phiếu hỗ trợ | X | X | – | – | X (phiếu của bộ phận mình) | C (của mình) |
| Bộ phận hỗ trợ, quy tắc định tuyến | X | X | – | – | – | – |
| Đánh giá sản phẩm | X (xem, trả lời) | X (xem, trả lời, ẩn) | – | – | R | C (viết cho đơn đã hoàn tất; xem công khai) |
| Báo cáo doanh thu | X | R | – | – | – | – |
| Nhật ký thao tác (audit) | X | R | – | – | – | – |

Quy tắc bổ sung:
- Hoàn cọc và hủy đơn sau khi đã giao cần quyền manager trở lên.
- Chỉ owner đổi chủ sở hữu hoặc xóa cửa hàng.
- Thao tác nhạy cảm (đổi vai trò, hoàn tiền, điều chỉnh kho thủ công) **bắt buộc ghi `audit_logs`**.

## Quyền super admin

- Xem danh sách cửa hàng, khóa/mở khóa, số liệu hệ thống.
- **Không** mặc định xem nội dung nghiệp vụ của cửa hàng; truy cập hỗ trợ phải có lý do và được ghi nhật ký.

## Kiểm thử bắt buộc

Mỗi ô trong ma trận có kiểm thử tự động cho cả hướng cho phép lẫn từ chối. Thêm ca: người dùng đổi `id` tài nguyên sang tài nguyên của người/tenant khác phải nhận 404 hoặc 403.
