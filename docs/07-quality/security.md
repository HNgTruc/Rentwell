# Bảo mật

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15

Mô hình mối đe dọa rút gọn và các biện pháp. Chuẩn tham chiếu: OWASP Top 10 và OWASP ASVS (chọn cấp độ phù hợp ở P8).

## 1. Tài sản cần bảo vệ

| Tài sản | Mức nhạy cảm |
|---|---|
| Dữ liệu từng cửa hàng (đơn, khách, giá) | Cao: cô lập tenant |
| Thông tin cá nhân khách, giấy tờ xác minh | Rất cao |
| Dữ liệu tiền (thanh toán, cọc, hoàn tiền) | Cao: toàn vẹn |
| Mật khẩu, token, khóa bí mật | Rất cao |

## 2. Mối đe dọa và biện pháp

| Mối đe dọa | Biện pháp |
|---|---|
| Cửa hàng này đọc dữ liệu cửa hàng khác | RLS + guard + kiểm thử tự động; role ứng dụng không superuser; 404 cho tài nguyên tenant khác |
| Truy cập tài nguyên người khác bằng đổi ID (IDOR) | Kiểm tra quyền sở hữu mọi truy cập theo ID |
| Chiếm tài khoản | argon2, giới hạn thử, khóa tạm, xác minh email, refresh token xoay vòng và thu hồi được |
| Trộm token | Access token ngắn hạn; web dùng cookie `HttpOnly` + `Secure` + `SameSite`; mobile dùng `expo-secure-store` |
| Tiêm SQL | Truy vấn tham số hóa (Kysely), không nối chuỗi SQL |
| XSS / CSRF | Escape mặc định của React, CSP chặt, `SameSite`, token chống CSRF cho thao tác dùng cookie |
| Giả mạo webhook thanh toán | Kiểm tra chữ ký, idempotent, đối chiếu lại với cổng |
| Sửa giá phía client | Server tính lại giá, không tin giá từ client |
| Đặt trùng / gian lận tồn kho | Ràng buộc DB, giữ chỗ có hạn, giới hạn số đơn giữ chỗ chưa thanh toán mỗi khách |
| Tải tệp độc hại | Presigned URL giới hạn loại và dung lượng, quét/kiểm tra loại thực của tệp, không phục vụ tệp người dùng cùng tên miền với ứng dụng |
| Lộ giấy tờ khách | Bucket riêng tư, URL ký thời hạn ngắn, ghi log truy cập, thu thập tối thiểu, xóa theo chính sách lưu trữ |
| Lạm dụng API | Giới hạn tần suất theo IP và người dùng, kích thước body tối đa |
| Phụ thuộc có lỗ hổng | Quét phụ thuộc trong CI, cập nhật định kỳ |
| Lộ bí mật trong repo | Quét bí mật trong CI, `.env` ngoài git, xoay khóa khi nghi ngờ |
| Nhân viên lạm quyền | Phân quyền tối thiểu, `audit_logs` cho thao tác nhạy cảm |

## 3. Quyền riêng tư và pháp lý

- Chỉ thu thập dữ liệu cần thiết cho thuê đồ; giấy tờ xác minh chỉ khi món có giá trị cao.
- Cần chính sách quyền riêng tư, điều khoản sử dụng, và rà soát yêu cầu pháp luật Việt Nam về bảo vệ dữ liệu cá nhân **trước khi ra mắt** (nên có tư vấn pháp lý; tài liệu này không phải ý kiến pháp lý).
- Cho phép khách yêu cầu xem/xóa dữ liệu của mình trong giới hạn nghĩa vụ lưu giữ giao dịch.

## 4. Header và cấu hình

- HTTPS bắt buộc, HSTS.
- CSP, `X-Content-Type-Options`, `Referrer-Policy`, `frame-ancestors` giới hạn.
- CORS chỉ các nguồn đã biết.
- Thông báo lỗi ở production không lộ chi tiết nội bộ.

## 5. Ứng phó sự cố

- Có runbook: phát hiện, cô lập, xoay khóa, thông báo người dùng, khôi phục từ sao lưu.
- Log có `request_id` để truy vết; giữ log tối thiểu theo chính sách.
