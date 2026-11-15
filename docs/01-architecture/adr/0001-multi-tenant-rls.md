# ADR-0001: Đa tenant bằng một CSDL dùng chung và Row Level Security

- **Trạng thái:** Đã chấp nhận
- **Ngày:** 2026-11-15

## Bối cảnh
Nhiều cửa hàng dùng chung nền tảng; dữ liệu cửa hàng này không được lộ cho cửa hàng khác. Dự án một người, cần chi phí vận hành thấp.

## Các phương án
1. **Mỗi tenant một CSDL:** cô lập mạnh nhất; vận hành, migration và kết nối nhân lên theo số cửa hàng. Quá nặng.
2. **Mỗi tenant một schema:** cô lập tốt; migration nhân lên, khó báo cáo chéo.
3. **Một schema chung, cột `tenant_id` + RLS:** vận hành đơn giản, một migration cho tất cả; cô lập dựa vào chính sách đúng và role không phải superuser.

## Quyết định
Chọn phương án 3. Mọi bảng nghiệp vụ có `tenant_id`, khóa ngoại ghép `(tenant_id, id)`, bật RLS. Mỗi request mở giao dịch và `SET LOCAL app.tenant_id`. Guard ở API là lớp thứ hai độc lập.

## Hệ quả
- Phải dùng role ứng dụng **không phải superuser và không phải owner bảng**.
- Phải có kiểm thử tự động chứng minh cô lập (chạy trong CI từ P1).
- Mọi truy vấn phải nằm trong giao dịch có đặt biến tenant; tác vụ nền cũng vậy.
- Báo cáo toàn nền tảng dùng `app.is_super_admin`.
