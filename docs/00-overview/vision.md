# Tầm nhìn sản phẩm

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15

## Bài toán

Cửa hàng cho thuê đồ (trang phục, phụ kiện, thiết bị sự kiện) thường quản lý bằng sổ tay, Excel và nhắn tin. Hậu quả: đặt trùng, mất đồ không rõ ai giữ, tính phí trễ và hư hỏng tranh cãi, không biết món nào đang ở đâu. Khách thì khó biết món còn trống ngày nào và tổng chi phí là bao nhiêu.

## Giải pháp

**Rentwell** là nền tảng cho thuê đồ đa cửa hàng: mỗi cửa hàng có không gian quản trị riêng (tenant), khách đặt thuê trên web và ứng dụng di động, hệ thống tự lo tồn kho, giá, giao nhận, cọc và phí phát sinh.

## Người dùng

| Vai trò | Mục tiêu chính |
|---|---|
| Khách hàng | Tìm món, biết còn trống không, thấy giá rõ ràng, đặt và theo dõi đơn |
| Chủ cửa hàng (owner) | Quản lý món, giá, nhân viên, doanh thu |
| Quản lý (manager) | Duyệt đơn, điều phối vận hành hằng ngày |
| Nhân viên giao nhận (staff) | Giao và nhận đồ, chụp ảnh bàn giao |
| Nhân viên kho (warehouse) | Soạn đồ, nhận lại, kiểm tra tình trạng, nhập xuất kho |
| Chăm sóc khách hàng (support) | Xử lý phiếu hỗ trợ, khiếu nại |
| Super admin | Quản trị toàn nền tảng, khóa/mở cửa hàng |

## Giá trị cốt lõi

1. **Không bao giờ đặt trùng.** Tồn kho là nguồn sự thật, ràng buộc ở cơ sở dữ liệu.
2. **Giá minh bạch.** Khách thấy từng khoản (thuê, giao, cọc) trước khi trả tiền.
3. **Dấu vết đầy đủ.** Ảnh và biên bản bàn giao giải quyết tranh cãi.
4. **Cô lập dữ liệu giữa cửa hàng.** Cửa hàng này không thấy dữ liệu cửa hàng khác.
5. **Vận hành được bằng điện thoại.** Nhân viên làm việc ngay tại chỗ.

## Nguyên tắc sản phẩm

- Chính xác trước, đẹp sau.
- Mặc định an toàn: từ chối khi không chắc (hết hàng, ngoài vùng giao).
- Mỗi cửa hàng tự quyết giá, chính sách hủy, phí giao trong khuôn khổ nền tảng.

## Chỉ số thành công (sau khi ra mắt beta)

| Chỉ số | Mục tiêu tham khảo |
|---|---|
| Đơn bị đặt trùng | 0 |
| Đơn có biên bản bàn giao đủ ảnh | từ 95% |
| Thời gian tạo đơn của khách | dưới 3 phút |
| Cửa hàng dùng thử còn hoạt động sau 1 tháng | từ 60% |

(Con số là điểm khởi đầu để đo, sẽ điều chỉnh theo dữ liệu thật.)
