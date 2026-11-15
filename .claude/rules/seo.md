---
paths:
  - "apps/web/**"
  - "packages/ui/**"
---

# Quy tắc SEO (trang công khai)

Chi tiết và lý do: `docs/07-quality/seo.md`. Làm như chuyên gia lập trình SEO.

- Nội dung công khai phải có trong HTML từ máy chủ (SSR, SSG, ISR); không để nội dung chính chỉ hiện sau khi chạy JavaScript.
- Mỗi trang: `title` và `description` riêng sinh từ dữ liệu thật (`generateMetadata`), `canonical` tuyệt đối, đúng một `h1`, HTML ngữ nghĩa.
- Dữ liệu có cấu trúc JSON-LD (`Product`/`Offer`, `Organization`, `BreadcrumbList`, `LocalBusiness`) phải khớp nội dung hiển thị; không đánh dấu thứ không có trên trang.
- URL sạch, chữ thường, không dấu, theo `slug` từ máy chủ; đổi slug thì 301; món gỡ trả 410/404, không trả 200 trống.
- Ảnh dùng `next/image` với `alt`, `width`, `height`; tránh dịch chuyển bố cục (CLS).
- Trang riêng tư (đăng nhập, tài khoản, giỏ, thanh toán, admin) phải `noindex`.
- Không thêm thư viện nặng cho trang chỉ đọc; ưu tiên Server Components. Mục tiêu LCP ≤ 2,5 s, INP ≤ 200 ms, CLS ≤ 0,1.
- Chỉ làm đúng phần được giao: không sửa SEO ở trang khác khi chưa được yêu cầu; thấy thiếu thì báo lại.
