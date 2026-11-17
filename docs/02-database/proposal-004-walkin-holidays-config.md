# Đề xuất lược đồ 004: khách vãng lai, ngày lễ, cấu hình xác minh và giờ mở cửa

**Trạng thái:** ĐÃ DUYỆT (2026-11-17) và ĐÃ ÁP DỤNG vào `db/migrations/001_init.sql` (bản sao: `schema-001-init.sql`, nay 49 bảng). **Đã chạy thử 2026-11-17 trên PostgreSQL 16.16:** áp thành công (49 bảng), kiểm thử `../../db/tests/001_walkin_holidays_close_branch.sql` đạt 20/20 ca. Căn cứ: `../01-architecture/adr/0009-business-rules-batch-2026-11-17.md`.
Vì `001_init.sql` chưa áp ở đâu nên sửa thẳng file 001 (như proposal-003). Sau lần áp đầu thì chỉ dùng migration mới.

**Khác biệt so với đề xuất ban đầu (khi áp dụng):**
- `item_types.requires_verification` đã có sẵn; chỉ thêm `verification_min_deposit` (tên đổi từ `verification_min_value` cho rõ cơ sở so sánh là cọc).
- `late_fee_rules.grace_hours` đã có `DEFAULT 2`; không cần API điền.
- Đóng chi nhánh làm bằng trigger `forbid_closing_branch_in_use` (không phải hàm `close_branch`); tính cả đơn `returned` vào đơn mở. Lỗi 23514 với MESSAGE `BRANCH_HAS_OPEN_BOOKINGS`, `BRANCH_HAS_STOCK`, `BRANCH_HAS_OPEN_TRANSFERS`.
- `holidays` bật RLS riêng: mọi người đọc, chỉ `is_platform_admin()` ghi.
- `holiday_surcharges` không có `updated_at` và không có phụ thu theo loại món (backlog).

## 1. Hiện trạng liên quan (đã kiểm tra trong `001_init.sql`)

- `users` và `user_addresses` đã **ngoài tenant** (không `tenant_id`), đúng yêu cầu "hồ sơ khách chung thông tin cơ bản". Không cần bảng mới.
- `customer_profiles` có `tenant_id`, `user_id NOT NULL`, trạng thái xác minh, điểm tin cậy, danh sách đen, ghi chú: đúng yêu cầu "giấy tờ và đơn theo chuỗi".
- `branches.opening_hours jsonb` đã có, chưa có định dạng.
- Chưa có bảng ngày lễ, chưa có phụ thu ngày lễ, chưa có cờ xác minh theo loại món.

## 2. Thay đổi đề xuất

### 2.1 Khách vãng lai (đơn tại quầy)

| Bảng | Sửa |
|---|---|
| `customer_profiles` | `user_id` thành **NULL được**. Thêm `full_name text`, `phone text`, `linked_at timestamptz`. CHECK: `user_id IS NOT NULL OR (full_name IS NOT NULL AND phone IS NOT NULL)`. Giữ `UNIQUE (tenant_id, user_id)` (NULL không đụng nhau). Thêm chỉ mục `(tenant_id, phone)` để nhân viên tìm khách cũ |
| Liên kết sau này | Khi khách đăng ký tài khoản và xác nhận cùng số điện thoại, API gán `user_id` vào hồ sơ vãng lai (không tạo hồ sơ thứ hai). Nếu đã có hồ sơ cho `user_id` đó ở chuỗi: quy trình gộp **cần thiết kế riêng, để sau MVP**; MVP chỉ cho phép liên kết khi chưa có hồ sơ trùng |

Lưu ý: tên và sđt của hồ sơ vãng lai nằm trong tenant (nhạy cảm vừa phải); khi đã liên kết thì lấy tên/sđt từ `users`, cột trên giữ làm bản lưu của chuỗi.

### 2.2 Bảng ngày lễ dùng chung và phụ thu theo chuỗi

```sql
-- Lịch ngày lễ của nền tảng, KHÔNG có tenant_id. Chỉ super admin ghi; mọi vai trò đọc.
CREATE TABLE holidays (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code       text NOT NULL UNIQUE,            -- vd: tet-2027, quoc-khanh-2027
  name       text NOT NULL,
  start_date date NOT NULL,
  end_date   date NOT NULL,                   -- khoảng [start_date, end_date), cùng quy ước đêm
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_date > start_date)
);

-- Phụ thu ngày lễ do từng chuỗi gán
CREATE TABLE holiday_surcharges (
  tenant_id     uuid NOT NULL REFERENCES tenants (id),
  holiday_id    uuid NOT NULL REFERENCES holidays (id),
  mode          text NOT NULL CHECK (mode IN ('percent','fixed')),
  value         bigint NOT NULL CHECK (value > 0),         -- percent: tối đa 100 (CHECK dưới); fixed: đồng mỗi đêm
  is_active     boolean NOT NULL DEFAULT true,
  PRIMARY KEY (tenant_id, holiday_id),
  CHECK (mode <> 'percent' OR value <= 100)
);
```

- `holidays` là bảng nền tảng, tương tự `users`; cần chính sách RLS riêng (đọc: mọi vai trò; ghi: chỉ `is_platform_admin()`), kiểm thử rõ vì khác mẫu `tenant_isolation`.
- `holiday_surcharges` có `tenant_id` nên vòng lặp bật RLS hiện có áp tự động; thêm kiểm thử cô lập.
- **Phụ thu theo loại món** (ví dụ lễ chỉ tăng giá áo dài, không tăng phụ kiện) **chưa có**; MVP là một mức cho cả chuỗi. Ghi vào backlog.
- Hàm tính giá nhận danh sách ngày lễ và phụ thu như **tham số** (không đọc DB), giữ tính thuần.

### 2.3 Cờ xác minh theo loại món (P7)

| Bảng | Sửa |
|---|---|
| `item_types` | Thêm `verification_required boolean NOT NULL DEFAULT false` và `verification_min_value bigint` (NULL = luôn bắt khi cờ bật; có giá trị = chỉ bắt khi cọc hoặc giá trị thay thế của đơn đạt ngưỡng; cơ sở so sánh là **cọc của dòng**, để đơn giản) |

Câu hỏi nhỏ cần xác nhận: ngưỡng so với **cọc** hay **giá trị thay thế**? Đề xuất mặc định là **cọc của dòng** vì luôn có sẵn kể cả khi cọc cố định.

### 2.4 Chuẩn `opening_hours` và đóng chi nhánh

- `branches.opening_hours` có dạng:

```json
{ "mon": {"open":"08:00","close":"20:00"}, "tue": {"open":"08:00","close":"20:00"},
  "wed": null, "thu": {"open":"08:00","close":"20:00"}, "fri": {"open":"08:00","close":"20:00"},
  "sat": {"open":"09:00","close":"17:00"}, "sun": null }
```

  `null` là ngày nghỉ. Kiểm tra bằng Zod ở API (nguồn sự thật cho định dạng), thêm `CHECK (jsonb_typeof(opening_hours) = 'object')` ở DB. Thiếu thứ nào thì coi là nghỉ.
- **Đóng chi nhánh:** thêm trigger hoặc hàm `close_branch(p_tenant, p_branch)` chặn chuyển `status` sang `closed` nếu còn: đơn `hold`/`confirmed`/`handed_over` của chi nhánh, `branch_stock.quantity_usable > 0`, hoặc `stock_transfers` chưa ở `received`/`rejected`/`cancelled` liên quan chi nhánh. Lỗi trả mã riêng để API liệt kê việc còn lại.

### 2.5 Hạn giữ chỗ 15 phút

Không cần cột mới: `hold_expires_at` đã có. Hằng số 15 phút đặt ở cấu hình API (và một hằng trong hàm tạo đơn), không ở DB. Không có cài đặt theo chuỗi ở MVP.

### 2.6 Không đổi

- `users`, `user_addresses`, `delivery_fee_rules`, `late_fee_rules` (giá trị mặc định ân hạn 2 giờ do API điền khi chuỗi tạo quy tắc, không phải DEFAULT cứng ở DB).
- Gia hạn không cần bảng mới; `extensions` hiện có đủ, hàm giá tính lại tổng đêm.

## 3. Kiểm thử đi kèm (khi làm thật)

- `customer_profiles`: tạo vãng lai (có tên+sđt) thành công; thiếu cả `user_id` lẫn tên/sđt bị CHECK chặn; tenant B không đọc được hồ sơ vãng lai của tenant A.
- `holidays`: role ứng dụng đọc được; chỉ cờ platform admin ghi được; không có đường ghi cho role tenant thường.
- `holiday_surcharges`: cô lập tenant; `percent > 100` bị chặn.
- Đóng chi nhánh: bị chặn khi còn đơn mở, còn tồn, còn phiếu chuyển; thành công khi sạch.
- `opening_hours`: định dạng sai bị Zod từ chối; DB chặn khi không phải object.

## 4. Tác động

- `docs/03-api/booking-pricing.md` (phụ thu ngày lễ, gia hạn, làm tròn, phí trễ), `docs/04-product/booking-flow.md` (hạn giữ chỗ, đơn tại quầy, đóng chi nhánh): cập nhật cùng đợt với ADR 0009.
- Skill `pricing-calculation` và `cases.md` cần thêm ca ngày lễ, làm tròn, gia hạn; vì nằm trong `.claude/**` nên **hỏi trước khi sửa** (chưa làm).
- `docs/02-database/erd.md`, `schema-overview.md`: vẽ lại khi duyệt và sửa `001_init.sql`.
- Roadmap: P1 (hồ sơ khách), P2 (ngày lễ và phụ thu cùng bảng giá), P3 (hàm giá), P5 (đơn tại quầy, đóng chi nhánh), P7 (xác minh) đã tham chiếu.

## 5. Cần chủ dự án duyệt

- [x] (2026-11-17) Danh sách sửa ở mục 2.
- [x] (2026-11-17) Phụ thu ngày lễ cộng **trước** giảm bậc.
- [x] (2026-11-17) Ngưỡng xác minh so với **cọc của dòng** (mục 2.3).
- [x] (2026-11-17) Sửa thẳng `001_init.sql` trước lần áp đầu, thay vì migration 002.
- [x] (2026-11-17) Chạy thử `001_init.sql` và `db/tests/001_walkin_holidays_close_branch.sql` trên PostgreSQL 16.16: 20/20 ca đạt, không cần sửa.
- [ ] Bổ sung kiểm thử đóng chi nhánh khi còn đơn mở và còn tồn kho (cần seed).
