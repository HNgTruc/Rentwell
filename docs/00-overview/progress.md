# Tiến độ dự án

**Cập nhật lần cuối:** 2026-11-15

## Cách dùng (để không lặp lại bước đã làm)

1. **Trước khi làm một việc**, đọc file này và mục tương ứng trong `../06-roadmap/roadmap.md`. Việc đã `[x]` thì không làm lại; chỉ kiểm tra khi có lý do.
2. **Làm xong việc nào** thì đổi `[ ]` thành `[x]` kèm ngày: `- [x] (2026-12-03) Docker Compose ...`.
3. **Nơi tick chính:** `../06-roadmap/roadmap.md` (từng công việc và tiêu chí hoàn thành). Mục 7 và mục 9 của `project-plan.md` là bản tóm tắt P0 và các quyết định; tick ở đó luôn khi xong.
4. **Giai đoạn xong khi** mọi tiêu chí hoàn thành (DoD) của nó đã `[x]`; khi đó tick dòng giai đoạn ở dưới.
5. Việc bị bỏ hoặc đổi hướng: gạch bỏ bằng `~~...~~` và ghi lý do ngắn, không xóa, để người sau biết đã cân nhắc.

## Giai đoạn thiết kế (trước P0)

- [x] (2026-11-14) Chốt tên dự án: Rentwell (chưa kiểm tra tên miền, mạng xã hội, nhãn hiệu)
- [x] (2026-11-14) Lược đồ cơ sở dữ liệu: 42 bảng, RLS, hàm giữ chỗ tồn kho (`db/migrations/001_init.sql`)
- [x] (2026-11-15) Phạm vi MVP và tầm nhìn (`scope-mvp.md`, `vision.md`)
- [x] (2026-11-15) Kế hoạch tổng và lộ trình P0 đến P8 (`project-plan.md`, `../06-roadmap/roadmap.md`)
- [x] (2026-11-15) Công nghệ đề xuất và kiến trúc (`../01-architecture/`); các điểm 🟡 chờ spike
- [x] (2026-11-15) Quy tắc tính giá, đặt thuê, quyền (`../03-api/`, `../04-product/`)
- [x] (2026-11-15) Cấu hình Claude Code: rules, commands, agents, skills (`.claude/`)
- [x] (2026-11-15) Cấu trúc thư mục dự án và bộ khung thư mục
- [x] (2026-11-15) README mô tả cho mọi thư mục
- [x] (2026-11-15) Nạp skill `ui-ux-pro-max` vào `.claude/skills/` (chờ chỉnh bối cảnh và chốt thương hiệu)
- [x] (2026-11-15) Quy tắc làm việc với Claude (có cổng thiết kế): không tự commit, hỏi trước khi thêm thành phần, làm đúng phần giao, làm theo chuẩn SEO (`../08-guides/working-agreement.md`, `../07-quality/seo.md`)

## Cổng thiết kế (người dùng thiết kế xong, Claude mới làm giao diện)

- [ ] Thiết kế `apps/web` (khách) đã được người dùng duyệt
- [ ] Thiết kế `apps/admin` (quản trị) đã được người dùng duyệt
- [ ] Thiết kế `apps/mobile` (khách và nhân viên) đã được người dùng duyệt
- [ ] Hệ thiết kế chung (màu, phông, thành phần) đã được người dùng duyệt

## Tiến độ theo giai đoạn

| Xong | Giai đoạn | Thời lượng | Mốc |
|---|---|---|---|
| [ ] | P0 Khởi tạo và hạ tầng | 2 tuần | M1 Nền móng |
| [ ] | P1 Tenant, tài khoản, phân quyền | 4 tuần | M2 Cô lập tenant |
| [ ] | P2 Danh mục và tồn kho | 4 tuần | |
| [ ] | P3 Đặt thuê và tính giá | 5 tuần | M3 Đặt thuê đúng |
| [ ] | P4 Thanh toán và cọc | 3 tuần | |
| [ ] | P5 Bàn giao, giao nhận, trả đồ | 4 tuần | **M4 MVP web** |
| [ ] | P6 Mobile | 5 tuần | M5 Có app |
| [ ] | P7 CSKH, thông báo, báo cáo | 4 tuần | |
| [ ] | P8 Bảo mật, hiệu năng, ra mắt | 4 tuần | M6 Ra mắt beta |

## Việc cần quyết định (bản sao, tick tại `project-plan.md` mục 9)

- [ ] Chọn cổng thanh toán
- [ ] Giảm theo bậc áp cho tổng đơn hay từng dòng
- [ ] Cơ sở tính cọc theo phần trăm
- [ ] Thanh toán đến sau khi giữ chỗ hết hạn
- [ ] Tên miền, mạng xã hội, nhãn hiệu cho Rentwell
- [x] (2026-11-15) Duyệt hướng thiết kế lược đồ 002 (đánh giá, bộ phận, định tuyến) và các câu hỏi mở về đánh giá
- [x] (2026-11-15) Chốt quy tắc chi nhánh (kho riêng, chọn theo khoảng cách, đơn tại quầy, phí giao cấp chuỗi, chuyển hàng, trả đúng chi nhánh, đổi size tại chỗ)
- [x] (2026-11-15) Duyệt và sửa `001_init.sql` theo `proposal-003-branches.md` (47 bảng, đã chạy thử trên PostgreSQL 16)
- [ ] Chốt công nghệ chat thời gian thực (SSE hay WebSocket): Claude đề xuất chi tiết và hỏi lại ở đầu P7
- [ ] Rà soát pháp lý dữ liệu cá nhân
- [x] (2026-11-15) URL công khai: một website chung, theo đường dẫn (ADR 0005)

## Ghi chú ngắn (mới nhất ở trên)

- 2026-11-15: thêm skill `clean-code` (đã duyệt). Bỏ đề xuất `review-code`.
- 2026-11-15: chủ dự án chọn làm máy chủ MCP loại B (sau MVP, 6 công cụ chỉ đọc, mở rộng được). Đã ghi ADR 0007 và roadmap; chưa thêm thư viện hay mã.
- 2026-11-15: đã sửa `001_init.sql` (chi nhánh, kho riêng, chuyển hàng, đổi size) và đồng bộ `docs/02-database/schema-001-init.sql`. Còn lại: cập nhật skill `inventory-reservation` và rule `database.md` (chờ duyệt vì nằm trong `.claude/`).
- 2026-11-15: chủ dự án chốt 8 điểm về chi nhánh. Đã viết lại `proposal-003` (quy tắc, luồng đặt, quy trình chuyển hàng, danh sách sửa `001_init.sql`); **chưa sửa file SQL, chờ duyệt**.
- 2026-11-15: chủ dự án làm rõ: tenant là chuỗi nhiều chi nhánh; đơn online gán chi nhánh gần khách nhất; thuê ở đâu trả ở đó (cả online và tại quầy). Đã viết ADR 0006 và đề xuất lược đồ 003, **chờ duyệt trước khi sửa `001_init.sql`**.
- 2026-11-15: chủ dự án duyệt: đánh giá công khai toàn nền tảng (người chưa đăng nhập cũng xem), cửa hàng được trả lời, bộ phận mặc định giữ nguyên, chat chốt công nghệ ở P7; một website chung cho mọi cửa hàng (ADR 0005).
- 2026-11-15: chủ dự án quyết định thêm đánh giá (P6), định tuyến theo bộ phận và chat trên nền phiếu (P7); lộ trình dài thêm khoảng 3 tuần (ước lượng). Đã viết đề xuất, chờ duyệt.
- 2026-11-15: hoàn tất thiết kế và khung thư mục; chưa có mã ứng dụng. Việc tiếp theo là P0, tuần 1.
