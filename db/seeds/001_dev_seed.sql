-- =====================================================================
-- 001_dev_seed.sql | Dữ liệu mẫu cho DEV/TEST. Toàn bộ là dữ liệu GIẢ (tên, email @example.test, sđt, địa chỉ).
-- Chạy: (từ workspace/) pnpm db:seed   — bằng superuser trong container dev, sau pnpm db:migrate.
-- Chạy lại an toàn: đã có dữ liệu mẫu thì bỏ qua.
-- Nội dung: 2 chuỗi, mỗi chuỗi 2 chi nhánh ở 2 tỉnh khác nhau, đủ vai trò nhân viên (chuỗi và chi nhánh),
-- 2 khách có tài khoản dùng chung toàn nền tảng + 1 khách vãng lai, danh mục có biến thể, nhập kho theo chi nhánh,
-- bậc giá, giá mùa, ngày lễ + phụ thu, chính sách hủy, phí trễ, phí giao (per_km và distance_tiers).
-- Mã tỉnh: 79 = TP.HCM, 01 = Hà Nội, 48 = Đà Nẵng. Mã phường là giá trị giả.
-- Quy ước UUID: nhóm đầu cho biết loại (a = chuỗi A, b = chuỗi B, c = người dùng, d = ngày lễ).
-- =====================================================================
SELECT EXISTS (SELECT 1 FROM tenants WHERE slug = 'ao-dai-xinh') AS seeded \gset
\if :seeded
  \echo 'Seed đã có, bỏ qua.'
  \quit
\endif

BEGIN;

-- ---------- Người dùng (toàn nền tảng, không thuộc chuỗi) ----------
INSERT INTO users (id, email, phone, full_name) VALUES
  ('c0000000-0000-4000-8000-000000000001', 'owner.a@example.test',     '0900000101', 'Chủ Chuỗi A'),
  ('c0000000-0000-4000-8000-000000000002', 'manager.a@example.test',   '0900000102', 'Quản Lý Chuỗi A'),
  ('c0000000-0000-4000-8000-000000000003', 'manager.a1@example.test',  '0900000103', 'Quản Lý CN A1'),
  ('c0000000-0000-4000-8000-000000000004', 'staff.a1@example.test',    '0900000104', 'Giao Nhận A1'),
  ('c0000000-0000-4000-8000-000000000005', 'kho.a1@example.test',      '0900000105', 'Kho A1'),
  ('c0000000-0000-4000-8000-000000000006', 'support.a@example.test',   '0900000106', 'CSKH A'),
  ('c0000000-0000-4000-8000-000000000011', 'owner.b@example.test',     '0900000111', 'Chủ Chuỗi B'),
  ('c0000000-0000-4000-8000-000000000012', 'manager.b1@example.test',  '0900000112', 'Quản Lý CN B1'),
  ('c0000000-0000-4000-8000-000000000013', 'kho.b1@example.test',      '0900000113', 'Kho B1'),
  ('c0000000-0000-4000-8000-000000000021', 'khach.lan@example.test',   '0900000121', 'Khách Lan'),
  ('c0000000-0000-4000-8000-000000000022', 'khach.minh@example.test',  '0900000122', 'Khách Minh'),
  ('c0000000-0000-4000-8000-000000000099', 'admin@example.test',       NULL,         'Quản Trị Nền Tảng');
UPDATE users SET is_super_admin = true WHERE id = 'c0000000-0000-4000-8000-000000000099';

INSERT INTO user_addresses (user_id, receiver_name, phone, address_line, ward_code, province_code, latitude, longitude, is_default) VALUES
  ('c0000000-0000-4000-8000-000000000021', 'Khách Lan',  '0900000121', '10 Đường Mẫu, Phường Mẫu', '79001', '79', 10.776900, 106.700900, true),
  ('c0000000-0000-4000-8000-000000000022', 'Khách Minh', '0900000122', '20 Phố Mẫu, Phường Mẫu',   '01001', '01', 21.028500, 105.854200, true);

-- ---------- Chuỗi và chi nhánh ----------
INSERT INTO tenants (id, name, slug, phone, email) VALUES
  ('a0000000-0000-4000-8000-000000000000', 'Áo Dài Xinh', 'ao-dai-xinh', '0280000001', 'lienhe@ao-dai-xinh.example.test'),
  ('b0000000-0000-4000-8000-000000000000', 'Sự Kiện Pro', 'su-kien-pro', '0236000001', 'lienhe@su-kien-pro.example.test');

INSERT INTO branches (id, tenant_id, name, slug, address_line, ward_code, province_code, latitude, longitude, opening_hours, delivery_enabled) VALUES
  ('a0000000-0000-4000-8000-0000000000b1', 'a0000000-0000-4000-8000-000000000000', 'Áo Dài Xinh Quận 1', 'quan-1',
   '1 Đường Mẫu A', '79002', '79', 10.775600, 106.701800,
   '{"mon":{"open":"08:00","close":"20:00"},"tue":{"open":"08:00","close":"20:00"},"wed":{"open":"08:00","close":"20:00"},"thu":{"open":"08:00","close":"20:00"},"fri":{"open":"08:00","close":"20:00"},"sat":{"open":"09:00","close":"18:00"},"sun":null}', true),
  ('a0000000-0000-4000-8000-0000000000b2', 'a0000000-0000-4000-8000-000000000000', 'Áo Dài Xinh Hoàn Kiếm', 'hoan-kiem',
   '2 Phố Mẫu A', '01002', '01', 21.028800, 105.852000,
   '{"mon":{"open":"08:30","close":"19:30"},"tue":{"open":"08:30","close":"19:30"},"wed":{"open":"08:30","close":"19:30"},"thu":{"open":"08:30","close":"19:30"},"fri":{"open":"08:30","close":"19:30"},"sat":{"open":"08:30","close":"19:30"},"sun":{"open":"09:00","close":"17:00"}}', true),
  ('b0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', 'Sự Kiện Pro Hải Châu', 'hai-chau',
   '3 Đường Mẫu B', '48001', '48', 16.067800, 108.220800,
   '{"mon":{"open":"08:00","close":"18:00"},"tue":{"open":"08:00","close":"18:00"},"wed":{"open":"08:00","close":"18:00"},"thu":{"open":"08:00","close":"18:00"},"fri":{"open":"08:00","close":"18:00"},"sat":null,"sun":null}', true),
  ('b0000000-0000-4000-8000-0000000000b2', 'b0000000-0000-4000-8000-000000000000', 'Sự Kiện Pro Thủ Đức', 'thu-duc',
   '4 Đường Mẫu B', '79003', '79', 10.850000, 106.770000,
   '{"mon":{"open":"08:00","close":"18:00"},"tue":{"open":"08:00","close":"18:00"},"wed":{"open":"08:00","close":"18:00"},"thu":{"open":"08:00","close":"18:00"},"fri":{"open":"08:00","close":"18:00"},"sat":{"open":"08:00","close":"12:00"},"sun":null}', false);

-- ---------- Nhân viên (NULL branch_id = cả chuỗi) và khách ----------
INSERT INTO memberships (tenant_id, user_id, role, branch_id) VALUES
  ('a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000001', 'owner',     NULL),
  ('a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000002', 'manager',   NULL),
  ('a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000003', 'manager',   'a0000000-0000-4000-8000-0000000000b1'),
  ('a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000004', 'staff',     'a0000000-0000-4000-8000-0000000000b1'),
  ('a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000005', 'warehouse', 'a0000000-0000-4000-8000-0000000000b1'),
  ('a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000006', 'support',   NULL),
  ('a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000021', 'customer',  NULL),
  ('a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000022', 'customer',  NULL),
  ('b0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000011', 'owner',     NULL),
  ('b0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000012', 'manager',   'b0000000-0000-4000-8000-0000000000b1'),
  ('b0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000013', 'warehouse', 'b0000000-0000-4000-8000-0000000000b1'),
  ('b0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000021', 'customer',  NULL);

-- Hồ sơ khách theo chuỗi: khách Lan thuê ở cả hai chuỗi (một tài khoản, hai hồ sơ); một khách vãng lai ở chuỗi A
INSERT INTO customer_profiles (id, tenant_id, user_id, full_name, phone) VALUES
  ('a0000000-0000-4000-8000-0000000000c1', 'a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000021', NULL, NULL),
  ('a0000000-0000-4000-8000-0000000000c2', 'a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000022', NULL, NULL),
  ('a0000000-0000-4000-8000-0000000000c3', 'a0000000-0000-4000-8000-000000000000', NULL, 'Khách Vãng Lai', '0900000199'),
  ('b0000000-0000-4000-8000-0000000000c1', 'b0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-000000000021', NULL, NULL);

-- ---------- Danh mục ----------
INSERT INTO categories (id, tenant_id, name, slug) VALUES
  ('a0000000-0000-4000-8000-0000000000d1', 'a0000000-0000-4000-8000-000000000000', 'Áo dài',   'ao-dai'),
  ('a0000000-0000-4000-8000-0000000000d2', 'a0000000-0000-4000-8000-000000000000', 'Phụ kiện', 'phu-kien'),
  ('b0000000-0000-4000-8000-0000000000d1', 'b0000000-0000-4000-8000-000000000000', 'Âm thanh', 'am-thanh');

INSERT INTO brands (id, tenant_id, name, country) VALUES
  ('a0000000-0000-4000-8000-0000000000e1', 'a0000000-0000-4000-8000-000000000000', 'Nhà May Mẫu', 'Việt Nam'),
  ('b0000000-0000-4000-8000-0000000000e1', 'b0000000-0000-4000-8000-000000000000', 'Hãng Loa Mẫu', 'Nhật Bản');

INSERT INTO suppliers (id, tenant_id, name, phone) VALUES
  ('a0000000-0000-4000-8000-0000000000f1', 'a0000000-0000-4000-8000-000000000000', 'Xưởng May Mẫu', '0280000099'),
  ('b0000000-0000-4000-8000-0000000000f1', 'b0000000-0000-4000-8000-000000000000', 'Đại Lý Thiết Bị Mẫu', '0236000099');

-- Loại món: áo dài (có size, cọc 30% giá trị thay thế, đổi size miễn phí, đêm đệm 1 để giặt);
-- khăn (biến thể mặc định, cọc cố định); loa (cọc %, bắt xác minh khi cọc dòng từ 2.000.000)
INSERT INTO item_types (id, tenant_id, category_id, brand_id, name, slug, base_price_per_night, deposit_type, deposit_value,
                        buffer_nights, free_size_exchange, requires_verification, verification_min_deposit) VALUES
  ('a0000000-0000-4000-8000-000000000101', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000d1',
   'a0000000-0000-4000-8000-0000000000e1', 'Áo dài lụa trơn', 'ao-dai-lua-tron', 150000, 'percent', 30, 1, true, false, NULL),
  ('a0000000-0000-4000-8000-000000000102', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000d2',
   NULL, 'Khăn vấn', 'khan-van', 30000, 'fixed', 50000, 0, false, false, NULL),
  ('b0000000-0000-4000-8000-000000000101', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000d1',
   'b0000000-0000-4000-8000-0000000000e1', 'Loa sự kiện 500W', 'loa-su-kien-500w', 400000, 'percent', 20, 0, false, true, 2000000);

INSERT INTO item_variants (id, tenant_id, item_type_id, sku, name, attributes, replacement_value) VALUES
  ('a0000000-0000-4000-8000-000000000111', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-000000000101', 'ADL-S', 'Size S', '{"size":"S"}', 2000000),
  ('a0000000-0000-4000-8000-000000000112', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-000000000101', 'ADL-M', 'Size M', '{"size":"M"}', 2000000),
  ('a0000000-0000-4000-8000-000000000113', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-000000000101', 'ADL-L', 'Size L', '{"size":"L"}', 2000000),
  ('a0000000-0000-4000-8000-000000000121', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-000000000102', 'KV-1',  'Mặc định', '{}', 200000),
  ('b0000000-0000-4000-8000-000000000111', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-000000000101', 'LOA-500', 'Mặc định', '{}', 15000000);

-- ---------- Giá và chính sách (cấp chuỗi) ----------
INSERT INTO price_tiers (tenant_id, item_type_id, min_nights, discount_percent) VALUES
  ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-000000000101', 3, 10),
  ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-000000000101', 7, 20),
  ('b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-000000000101', 2, 5);

INSERT INTO seasonal_prices (tenant_id, item_type_id, label, start_date, end_date, multiplier_percent) VALUES
  ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-000000000101', 'Mùa cưới cuối năm', '2026-11-15', '2027-01-15', 120);

INSERT INTO cancellation_policies (tenant_id, name, rules, is_default) VALUES
  ('a0000000-0000-4000-8000-000000000000', 'Mặc định',
   '[{"hours_before_start":168,"refund_percent":100},{"hours_before_start":72,"refund_percent":50},{"hours_before_start":0,"refund_percent":0}]', true),
  ('b0000000-0000-4000-8000-000000000000', 'Mặc định',
   '[{"hours_before_start":48,"refund_percent":100},{"hours_before_start":0,"refund_percent":0}]', true);

INSERT INTO late_fee_rules (tenant_id, grace_hours, fee_mode, fee_value, max_nights_charged) VALUES
  ('a0000000-0000-4000-8000-000000000000', 2, 'percent_of_nightly', 100, 5),
  ('b0000000-0000-4000-8000-000000000000', 2, 'fixed_per_night', 300000, NULL);

INSERT INTO delivery_fee_rules (tenant_id, mode, base_fee, base_km, per_km_fee, max_distance_km, free_over_amount, applies_to) VALUES
  ('a0000000-0000-4000-8000-000000000000', 'per_km', 15000, 3, 5000, 20, 1000000, 'both');
INSERT INTO delivery_fee_rules (tenant_id, mode, max_distance_km, min_order_amount, applies_to) VALUES
  ('b0000000-0000-4000-8000-000000000000', 'distance_tiers', 30, 500000, 'outbound');
INSERT INTO delivery_fee_tiers (tenant_id, from_km, to_km, fee) VALUES
  ('b0000000-0000-4000-8000-000000000000', 0, 10, 50000),
  ('b0000000-0000-4000-8000-000000000000', 10, 30, 120000);

-- ---------- Ngày lễ (nền tảng) và phụ thu (chuỗi A) ----------
INSERT INTO holidays (id, code, name, start_date, end_date) VALUES
  ('d0000000-0000-4000-8000-000000000001', 'tet-2027',         'Tết Nguyên Đán 2027', '2027-02-05', '2027-02-12'),
  ('d0000000-0000-4000-8000-000000000002', 'quoc-khanh-2027',  'Quốc khánh 2027',     '2027-09-01', '2027-09-03');
INSERT INTO holiday_surcharges (tenant_id, holiday_id, mode, value) VALUES
  ('a0000000-0000-4000-8000-000000000000', 'd0000000-0000-4000-8000-000000000001', 'percent', 20),
  ('b0000000-0000-4000-8000-000000000000', 'd0000000-0000-4000-8000-000000000002', 'fixed', 100000);

-- ---------- Nhập kho theo chi nhánh (lô + sổ cái; branch_stock do trigger cập nhật) ----------
INSERT INTO inventory_lots (id, tenant_id, branch_id, variant_id, lot_code, manufacture_place, supplier_id, purchase_date, purchase_price, quantity_received) VALUES
  ('a0000000-0000-4000-8000-000000000201', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000b1', 'a0000000-0000-4000-8000-000000000112', 'L-A1-M', 'TP.HCM', 'a0000000-0000-4000-8000-0000000000f1', '2026-10-01', 900000, 3),
  ('a0000000-0000-4000-8000-000000000202', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000b1', 'a0000000-0000-4000-8000-000000000111', 'L-A1-S', 'TP.HCM', 'a0000000-0000-4000-8000-0000000000f1', '2026-10-01', 900000, 2),
  ('a0000000-0000-4000-8000-000000000203', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000b2', 'a0000000-0000-4000-8000-000000000112', 'L-A2-M', 'TP.HCM', 'a0000000-0000-4000-8000-0000000000f1', '2026-10-05', 900000, 1),
  ('a0000000-0000-4000-8000-000000000204', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000b1', 'a0000000-0000-4000-8000-000000000121', 'L-A1-KV', NULL, NULL, '2026-10-01', 80000, 10),
  ('b0000000-0000-4000-8000-000000000201', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000111', 'L-B1-LOA', 'Nhật Bản', 'b0000000-0000-4000-8000-0000000000f1', '2026-09-20', 9000000, 2);

INSERT INTO inventory_movements (tenant_id, branch_id, variant_id, lot_id, movement_type, quantity, reason, created_by)
SELECT tenant_id, branch_id, variant_id, id, 'receive', quantity_received, 'Nhập kho dữ liệu mẫu',
       CASE WHEN tenant_id = 'a0000000-0000-4000-8000-000000000000'
            THEN 'c0000000-0000-4000-8000-000000000005'::uuid ELSE 'c0000000-0000-4000-8000-000000000013'::uuid END
  FROM inventory_lots;

COMMIT;

\echo 'Seed xong: 2 chuỗi, 4 chi nhánh, 12 người dùng, 5 biến thể, tồn kho theo chi nhánh.'
