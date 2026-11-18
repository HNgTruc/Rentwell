# ADR 0011: GSAP làm thư viện animation cho web và admin

**Trạng thái:** Chấp nhận (2026-11-17) · **Người quyết:** chủ dự án

## Bối cảnh

Chủ dự án muốn đưa bộ skill chính thức của GreenSock (`greensock/gsap-skills`, MIT) vào `.claude/skills/` để cả nhóm dùng chung. Các skill này hướng Claude dùng GSAP khi viết animation, nên việc thêm skill vào repo đồng nghĩa với việc chọn GSAP làm thư viện animation cho phần giao diện.

Ràng buộc:

- `apps/web` và `apps/admin` dùng Next.js (App Router), có SSR; trang công khai cần SEO và Core Web Vitals tốt (`docs/07-quality/seo.md`).
- `apps/mobile` dùng Expo (React Native). GSAP chạy trên DOM/SVG trình duyệt, **không dùng được cho React Native**.
- Cổng thiết kế (CLAUDE.md, quy tắc 5): chưa có thiết kế được duyệt thì chưa làm giao diện, kể cả animation.
- Từ khi Webflow mua GSAP, mọi plugin (SplitText, MorphSVG, ScrollSmoother...) đều miễn phí, cả cho mục đích thương mại, và nằm trong gói npm công khai `gsap`.

## Các phương án

1. **GSAP (`gsap` + `@gsap/react`)**
   - Ưu: dùng được với mọi framework, có timeline và ScrollTrigger, nhiều plugin; hook `useGSAP` tự dọn dẹp khi unmount; có bộ skill chính thức giúp Claude viết đúng cách (scope, cleanup, không chạy khi SSR, `prefers-reduced-motion`).
   - Nhược: là JS chạy phía client, làm tăng bundle (chưa đo, cần kiểm khi cài); không dùng cho mobile; API mang tính mệnh lệnh, không khai báo theo kiểu React.
2. **Motion (Framer Motion)**
   - Ưu: API khai báo, hợp với React; có animation layout và hiệu ứng khi thoát (exit).
   - Nhược: chỉ dùng cho React; khả năng sắp chuỗi theo timeline và cuộn kém GSAP; chưa có bộ skill tương đương trong repo.
3. **Chỉ dùng CSS (transition, `@keyframes`, tiện ích animation của Tailwind)**
   - Ưu: không tốn thêm JS, không cần chờ hydrate, tốt nhất cho SEO và hiệu năng.
   - Nhược: khó sắp chuỗi, khó điều khiển lúc chạy (dừng, đảo ngược) và khó làm animation theo cuộn.

## Quyết định

Chọn **GSAP** cho `apps/web` và `apps/admin` khi thiết kế được duyệt có animation vượt quá khả năng của CSS (chuỗi nhiều bước, theo cuộn, FLIP, SVG). Hiệu ứng đơn giản (hover, focus, mở/đóng) vẫn ưu tiên CSS và Tailwind.

Bộ skill `gsap-*` (8 skill) được đưa vào `.claude/skills/`, lấy từ upstream ở commit `aed9cfd` (2026-04-21) và giữ nguyên nội dung kèm `LICENSE` (MIT).

## Hệ quả

- Chưa cài gói. Khi có màn hình cần GSAP, chạy `pnpm add gsap @gsap/react` trong đúng app (cần hỏi trước theo quy tắc làm việc). Skill ghi lệnh `npm install`; trong repo này dùng `pnpm`.
- Trong React/Next.js: dùng `useGSAP` với `scope`, chỉ chạy phía client (`"use client"`), không gọi GSAP khi SSR.
- Mọi animation phải tôn trọng `prefers-reduced-motion` (`gsap.matchMedia()`).
- Trang công khai: animation không được che nội dung lúc tải lần đầu hoặc làm xấu LCP/CLS; nội dung phải có sẵn trong HTML khi SSR.
- Không dùng cho `apps/mobile`. Animation mobile sẽ quyết định riêng khi tới P7.
- Skill ghi đè tên trùng với skill GSAP đồng bộ ở máy cá nhân (`gsap-core`, `gsap-frameworks`); bản trong repo là bản dùng chung.
- Cập nhật skill: so với upstream, chép đè các thư mục `gsap-*` rồi ghi commit mới vào ADR này.
- Cổng thiết kế vẫn giữ nguyên: skill không cho phép Claude tự đặt ra animation khi chưa có thiết kế.
