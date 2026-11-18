# Kế hoạch dự án Rentwell

**Trạng thái:** Đã duyệt (2026-11-17) · **Cập nhật lần cuối:** 2026-11-17

Đây là file kế hoạch tổng. Chi tiết nằm ở các tài liệu được liên kết ở từng mục.

## 1. Mục tiêu

Xây **Rentwell**: nền tảng cho thuê đồ đa cửa hàng, gồm web khách hàng, trang quản trị cửa hàng, ứng dụng di động cho khách và nhân viên. Dự án cá nhân làm một mình, theo chuẩn doanh nghiệp (kiểm thử, bảo mật, CI/CD, tài liệu).

Mục tiêu cuối: **một đơn đi trọn vòng đời** (đặt → thanh toán → giao → nhận lại → tính phí → hoàn cọc) chạy ổn định, không đặt trùng, không rò dữ liệu giữa cửa hàng. Xem `vision.md`.

## 2. Phạm vi

- Trong MVP: đăng ký cửa hàng, phân quyền, danh mục và tồn kho, đặt thuê và tính giá, thanh toán và cọc, bàn giao, phí trễ và hư hỏng.
- Sau MVP: mobile, chăm sóc khách hàng, thông báo, báo cáo.
- Ngoài phạm vi: thuê theo giờ, giao liên tỉnh, mã giảm giá, bảo hiểm...
- Chat là lớp thời gian thực trên phiếu hỗ trợ, làm ở P7 (không phải hệ thống riêng).

Quyết định đã chốt (thuê theo đêm, theo số lượng, chuỗi nhiều chi nhánh mỗi chi nhánh một điểm nhận trả, giao cùng tỉnh, cửa hàng tự đặt phí giao): `scope-mvp.md`. Quy tắc nghiệp vụ bổ sung ngày 2026-11-17 (mô hình tiền, hồ sơ khách, giữ chỗ, cọc, hoàn tiền, làm tròn, phí trễ, ngày lễ...): ADR 0009.

## 3. Giả định

- Một người, 10 đến 15 giờ mỗi tuần, bắt đầu **2026-12-01**.
- Ước lượng là ước lượng, không phải cam kết; điều chỉnh sau mỗi giai đoạn.
- Quy tắc cắt phạm vi: trễ quá 30% ước lượng thì cắt tính năng, không kéo dài.

## 4. Công nghệ (tóm tắt)

TypeScript toàn hệ thống · NestJS (API) · Next.js (web, admin) · Expo (mobile) · PostgreSQL với RLS · Redis + BullMQ · Docker Compose · GitHub Actions. Chi tiết, lý do và các điểm cần kiểm chứng: `../01-architecture/tech-stack.md`.

## 5. Lộ trình theo giai đoạn

| GĐ | Tên | Thời lượng | Kết quả chính |
|---|---|---|---|
| P0 | Khởi tạo và hạ tầng | 2 tuần | Repo chạy, CI xanh, các spike kỹ thuật |
| P1 | Tenant, tài khoản, phân quyền | 4 tuần | Cô lập dữ liệu giữa cửa hàng, có kiểm thử chứng minh |
| P2 | Danh mục và tồn kho | 4 tuần | Đăng món, biến thể, nhập kho, bảng giá |
| P3 | Đặt thuê và tính giá | 5 tuần | Không đặt trùng, giá đúng |
| P4 | Thanh toán và cọc | 3 tuần | Nhận tiền (sandbox), giữ và hoàn cọc |
| P5 | Bàn giao, giao nhận, trả đồ | 4 tuần | **MVP web: một đơn đi trọn vòng** |
| P6 | Mobile | 5 tuần | App khách và nhân viên |
| P7 | CSKH, thông báo, báo cáo | 4 tuần | Vận hành hằng ngày có số liệu |
| P8 | Bảo mật, hiệu năng, ra mắt | 4 tuần | Bản chạy thật, beta kín |

Tổng khoảng 35 tuần; MVP web sau khoảng 21 tuần. Chi tiết công việc, tiêu chí hoàn thành, rủi ro từng giai đoạn: `../06-roadmap/roadmap.md`.

## 6. Mốc

| Mốc | Sau GĐ | Ý nghĩa |
|---|---|---|
| M1 | P0 | Môi trường dev tái lập được |
| M2 | P1 | An toàn dữ liệu đa cửa hàng |
| M3 | P3 | Đặt thuê đúng |
| **M4** | **P5** | **MVP web hoàn chỉnh** |
| M5 | P6 | Có app |
| M6 | P8 | Ra mắt beta |

## 7. Kế hoạch hai tuần đầu (P0, việc cụ thể)

**Tuần 1: nền móng**
- [x] (2026-11-17) Tạo monorepo pnpm theo `monorepo-structure.md` (bỏ Turborepo, ADR 0010).
- [x] (2026-11-17) Docker Compose: Postgres, Redis, Mailpit (MinIO ngừng phát hành image; chọn thay thế trước P2).
- [x] (2026-11-17) Áp `001_init.sql` làm migration đầu (dbmate); seed hai chuỗi mẫu.
- [x] (2026-11-17) Khung NestJS: cấu hình bằng Zod, log JSON, health check, Swagger.
- [ ] CI GitHub Actions: lint, typecheck, test, build (đã viết, chờ chạy xanh trên GitHub).

**Tuần 2: kiểm chứng rủi ro (spike)**
- [x] (2026-11-19) Kysely + RLS: mỗi request đặt `app.tenant_id` trong giao dịch, chứng minh không rò dữ liệu (ADR 0012; Testcontainers và kysely-codegen chờ duyệt).
- [x] (2026-11-19) Cổng thanh toán: so sánh xong, chọn MoMo (ADR 0013); chạy thử sandbox trước P4.
- [ ] Dịch vụ bản đồ: kiểm tra API trả phí theo lượt có gói miễn phí (ứng viên Goong) cho khoảng cách giao hàng; không tự host OSRM.
- [ ] Tìm kiếm tiếng Việt: thử `unaccent` + `pg_trgm`.
- [ ] Khung Next.js (`web`, `admin`) và Expo build được. Ghi mỗi spike thành một ADR.

**Xong P0 khi:** chạy `docker compose up` và `pnpm dev` trên máy sạch, CI xanh, ADR các spike đã ghi.

## 8. Rủi ro chính

| Rủi ro | Giảm thiểu |
|---|---|
| Làm một mình, thời gian không đều | Lát cắt nhỏ, mốc rõ, quy tắc cắt phạm vi |
| Rò dữ liệu giữa cửa hàng | RLS + kiểm thử tự động trong CI từ P1 |
| Đặt trùng, sai tồn kho | Ràng buộc DB, kiểm thử tải ở P3 |
| Sai tiền | Hàm thuần có bảng ca, sổ cái chỉ thêm |
| Cổng thanh toán không đăng ký được | Tìm hiểu từ P0, có phương án đối soát thủ công |
| Phạm vi phình to | Danh sách "ngoài phạm vi", duyệt trước khi thêm |

## 9. Việc cần quyết định sớm

| Xong | Việc | Cần trước |
|---|---|---|
| [x] | Chọn cổng thanh toán (2026-11-19: MoMo, ADR 0013; điều kiện: hộ kinh doanh đăng ký được; so sánh ở `../03-api/payment-gateways.md`) | P4, tìm hiểu ngay từ P0 |
| [x] | Giảm theo bậc áp cho tổng đơn hay từng dòng (2026-11-15: từng dòng, giá mùa trước rồi giảm bậc; ADR 0008) | P3 |
| [x] | Cơ sở tính cọc theo phần trăm (2026-11-15: giá trị thay thế; ADR 0008) | P3 |
| [x] | Thanh toán đến sau khi giữ chỗ hết hạn thì xử lý thế nào (2026-11-15: thử giữ lại, hết hàng tự hoàn tiền; `booking-flow.md` mục 5) | P4 |
| [ ] | Tên miền, tài khoản mạng xã hội cho Rentwell | Trước ra mắt |
| [ ] | Rà soát pháp lý dữ liệu cá nhân (Claude soạn danh sách câu hỏi ở P7, chủ dự án hỏi luật sư) | Trước P8 |
| [x] | URL công khai: một website chung, theo đường dẫn (ADR 0005, 2026-11-15) | P3 |
| [x] | 14 quy tắc nghiệp vụ: mô hình tiền, hồ sơ khách, duyệt đơn, giữ chỗ 15 phút, cọc, hoàn tiền, làm tròn, phí trễ, ngày lễ, gia hạn, đơn tại quầy, đóng chi nhánh, xác minh, giờ mở cửa (2026-11-17; ADR 0009) | P0 |
| [x] | Duyệt `proposal-004` (khách vãng lai, ngày lễ, cờ xác minh); phụ thu ngày lễ cộng trước giảm bậc (2026-11-17; đã sửa `001_init.sql`, đã chạy thử trên PostgreSQL 16, 19/19 ca đạt) | Trước áp `001_init.sql` |
| [ ] | Chọn dịch vụ bản đồ: spike P0, hướng API trả phí theo lượt có gói miễn phí (ứng viên Goong) | P3 |
| [x] | Duyệt tổng thể `project-plan`, `roadmap`, `tech-stack` (2026-11-17; điểm 🟡 vẫn chờ spike) | Trước P0 |

## 10. Cách theo dõi

Việc nào xong thì đánh `[x]` kèm ngày ngay trong tài liệu (mục 7, mục 9, `../06-roadmap/roadmap.md`); tổng hợp ở `progress.md`. Đọc trước khi làm để không lặp lại bước đã xong.

Bảng việc GitHub Projects (Backlog, Đang làm, Review, Xong; tối đa hai việc đang làm), ghi chú cuối tuần, kiểm tra tiêu chí hoàn thành cuối mỗi giai đoạn và cập nhật ước lượng. Xem `../08-guides/git-workflow.md`.
