# SEO (tối ưu tìm kiếm) cho trang công khai

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15
Phạm vi: `apps/web` (khách). `apps/admin`, API và các trang tài khoản không được lập chỉ mục.
Các con số và hành vi của Google dưới đây là hiểu biết hiện tại; **kiểm tra lại với tài liệu Google Search Central trước khi chốt ở P3 và P8**.

## 1. Nguyên tắc

1. **Nội dung công khai phải có trong HTML do máy chủ trả về** (SSR, SSG hoặc ISR), không chờ JavaScript phía trình duyệt mới có chữ.
2. **Mỗi trang một mục đích, một URL chuẩn (canonical), một `h1`.**
3. **Đo bằng số**, không cảm tính: Core Web Vitals, báo cáo lập chỉ mục, Lighthouse trong CI.
4. **Không đánh đổi người dùng lấy thứ hạng**: không nhồi từ khóa, không che nội dung.

## 2. Phân loại trang

| Loại trang | Lập chỉ mục | Cách render |
|---|---|---|
| Trang chủ, danh mục, trang cửa hàng, trang chi tiết món | **Có** | SSG/ISR (làm mới khi dữ liệu đổi) |
| Trang tìm kiếm, lọc nhiều tiêu chí | Chỉ các tổ hợp có giá trị; còn lại `noindex` | SSR |
| Đăng nhập, đăng ký, tài khoản, giỏ, thanh toán, đơn của tôi | **Không** (`noindex`) | CSR/SSR |
| `apps/admin`, API | **Không** (`X-Robots-Tag: noindex` + chặn trong robots) | Không áp dụng |
| Trang 404 / món đã gỡ | Không | Trả mã đúng (xem mục 6) |

## 3. Siêu dữ liệu từng trang

- `<title>` riêng, mô tả đúng nội dung, ngắn gọn; `meta description` riêng, có lời kêu gọi.
- `<link rel="canonical">` tuyệt đối; trang có tham số lọc trỏ về trang gốc.
- Open Graph và Twitter Card: tiêu đề, mô tả, ảnh (kích thước chuẩn chia sẻ).
- `<html lang="vi">`; nếu sau này có nhiều ngôn ngữ thì thêm `hreflang`.
- Dùng API metadata của Next.js (`generateMetadata`) tạo từ dữ liệu thật của trang, không viết tay từng trang.

## 4. Dữ liệu có cấu trúc (JSON-LD)

| Trang | Loại |
|---|---|
| Mọi trang | `Organization`/`WebSite`, `BreadcrumbList` |
| Chi tiết món | `Product` kèm `Offer` (giá, tình trạng) |
| Trang chuỗi | `Organization` |
| Trang chi nhánh (`/cua-hang/<chuoi>/chi-nhanh/<slug>`) | `LocalBusiness` (địa chỉ, tọa độ, giờ mở cửa) cho từng chi nhánh |

Quy tắc: dữ liệu trong JSON-LD phải **khớp nội dung hiển thị**; kiểm tra bằng công cụ Rich Results trước khi phát hành. Không đánh dấu thứ không có trên trang (đánh giá giả, giá không đúng).

## 5. URL

- Sạch, ngắn, dễ đọc, chữ thường, bỏ dấu tiếng Việt, nối bằng gạch ngang: `/cua-hang/<slug-cua-hang>/<slug-mon>`.
- Slug do máy chủ sinh từ tên, duy nhất, lưu trong CSDL. Dùng `unaccent` (đã có trong spike tìm kiếm tiếng Việt).
- **Đổi slug thì chuyển hướng 301** từ URL cũ; không để liên kết gãy.
- Cấu trúc **đã chốt** (ADR 0005): một website chung, theo đường dẫn `/cua-hang/<slug>`; slug cửa hàng duy nhất toàn nền tảng.
- Đánh giá công khai (toàn nền tảng) là nội dung thật hiển thị trên trang; có thể đưa số sao trung bình vào JSON-LD của trang món khi đánh giá đã hiển thị trên trang.

## 6. Mã trạng thái và lập chỉ mục

- Món/cửa hàng bị gỡ vĩnh viễn: `410`; tạm ẩn: `404`; đổi URL: `301`.
- Không để "soft 404" (trang trống trả 200).
- `robots.txt` và `sitemap.xml` sinh tự động từ dữ liệu; chỉ gồm URL canonical, đã công khai. Tách sitemap khi vượt giới hạn kích thước.
- Phân trang có liên kết thật (`<a href>`), mỗi trang có canonical riêng.

## 7. Hiệu năng (Core Web Vitals)

Mục tiêu trên trang công khai (kiểm tra lại ngưỡng hiện hành của Google): **LCP ≤ 2,5 s, INP ≤ 200 ms, CLS ≤ 0,1** ở phân vị 75, trên di động.

- Ảnh: `next/image`, định dạng hiện đại (WebP/AVIF), có `width`/`height`, `alt` mô tả, tải lười trừ ảnh đầu trang.
- Phông chữ: tự lưu, `font-display: swap`, ít biến thể.
- JavaScript: tách theo trang, ưu tiên Server Components, không tải thư viện nặng cho trang chỉ đọc.
- Cache: CDN cho trang tĩnh, `Cache-Control` đúng, ISR.
- Không dịch chuyển bố cục: dành chỗ cho ảnh, quảng cáo, biểu ngữ.

## 8. Nội dung và liên kết

- Một `h1`, thứ tự `h2`, `h3` hợp lý; HTML ngữ nghĩa (`nav`, `main`, `article`).
- Liên kết nội bộ: breadcrumb, món liên quan, danh mục; văn bản liên kết mô tả được đích.
- Mô tả món do cửa hàng viết: hướng dẫn nhập (độ dài tối thiểu, không sao chép nguyên văn nơi khác) để tránh trùng nội dung.
- Trang cửa hàng và món có nội dung riêng, không trùng nhau giữa các cửa hàng.

## 9. Kiểm thử và giám sát

- Lighthouse CI trong pipeline: chặn khi điểm SEO hoặc hiệu năng dưới ngưỡng đặt ra ở P3.
- Kiểm thử: mỗi loại trang có đúng `title`, `canonical`, `robots`, JSON-LD hợp lệ.
- Sau ra mắt: Google Search Console (độ phủ, Core Web Vitals, rich results), theo dõi hằng tuần.

## 10. Việc phải làm theo giai đoạn

- [ ] P2: sinh `slug` duy nhất cho cửa hàng, danh mục, loại món (lược đồ + API).
- [x] (2026-11-15) Chốt URL theo đường dẫn, một website chung (ADR 0005).
- [ ] P3: khung metadata, canonical, `robots`, `sitemap` cho `apps/web`.
- [ ] P3: JSON-LD cho `Product`, `Organization`, `BreadcrumbList`; kiểm tra Rich Results.
- [ ] P5: Lighthouse CI; đo Core Web Vitals trên dữ liệu thật; `noindex` cho trang riêng tư.
- [ ] P8: rà soát SEO toàn bộ, nộp sitemap lên Search Console, theo dõi lập chỉ mục.
