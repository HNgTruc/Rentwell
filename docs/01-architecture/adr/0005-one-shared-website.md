# ADR 0005: Một website chung cho mọi cửa hàng, URL theo đường dẫn

**Trạng thái:** Chấp nhận (2026-11-15) · **Người quyết:** chủ dự án

## Bối cảnh

Nhiều chuỗi cửa hàng (mỗi chuỗi là một tenant, có thể có nhiều chi nhánh, xem ADR 0006) bán trên nền tảng. Chủ dự án quyết định: **tất cả dùng chung một website** (`apps/web`), khách xem đánh giá và danh mục của cả nền tảng. Câu hỏi mở trước đó trong `docs/07-quality/seo.md`: mỗi cửa hàng một tên miền con hay chung một tên miền theo đường dẫn.

## Quyết định

- Một tên miền cho `apps/web`; trang cửa hàng ở `/cua-hang/<slug-cua-hang>`, trang món ở `/cua-hang/<slug-cua-hang>/<slug-mon>`.
- Trang tổng hợp theo danh mục và tìm kiếm chéo cửa hàng nằm trên cùng tên miền.
- `apps/admin` ở tên miền con riêng, không lập chỉ mục.

## Lý do

- Gom uy tín tìm kiếm về một tên miền; đúng hướng SEO của dự án.
- Khớp quyết định dùng chung một website và đánh giá công khai toàn nền tảng.
- Không cần cấu hình tên miền và chứng chỉ cho từng cửa hàng.

## Hệ quả

- Cần `slug` duy nhất toàn nền tảng cho cửa hàng; slug món duy nhất trong cửa hàng.
- Tìm kiếm chéo cửa hàng cơ bản phải có sớm hơn dự kiến (trước đây nằm ở "sàn giao dịch nâng cao" ngoài MVP); chỉ phần cơ bản (duyệt, lọc, tìm theo tên) thuộc phạm vi, phần nâng cao vẫn để sau.
- Truy cập công khai dữ liệu nhiều cửa hàng cần đường đọc riêng (view hoặc truy vấn dùng ngữ cảnh nền tảng), kiểm thử kỹ để không lộ dữ liệu riêng của cửa hàng.
- Nếu sau này cửa hàng lớn muốn tên miền riêng: làm như tính năng bổ sung (ADR mới).

## Phương án đã cân nhắc

- Tên miền con cho từng cửa hàng: tốt cho thương hiệu riêng nhưng chia nhỏ uy tín SEO và tốn cấu hình; không hợp mô hình dùng chung một website.
