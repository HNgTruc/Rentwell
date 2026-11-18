-- =====================================================================
-- Kiểm thử SQL cho phần thêm vào 001_init.sql theo proposal-004 / ADR 0009:
--   khách vãng lai, bảng ngày lễ + phụ thu, đóng chi nhánh, opening_hours
-- Cách chạy (cần PostgreSQL 15+ có 001_init.sql đã áp, kết nối bằng role có quyền tạo role):
--   psql "$DATABASE_MIGRATION_URL" -v ON_ERROR_STOP=1 -f db/tests/001_walkin_holidays_close_branch.sql
-- Toàn bộ chạy trong một giao dịch và ROLLBACK ở cuối, không để lại dữ liệu.
-- Kiểm thử RLS dùng role không phải superuser/owner (quy tắc 9 của dự án).
-- TRẠNG THÁI: chạy lần đầu 2026-11-17 trên PostgreSQL 16.16, 19/19 ca đạt.
-- Chưa phủ: chặn đóng chi nhánh khi còn đơn mở hoặc còn tồn kho (cần seed món, biến thể, đơn;
-- thêm khi có seed ở P0).
-- =====================================================================
BEGIN;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rentwell_test_app') THEN
    CREATE ROLE rentwell_test_app NOLOGIN;
  END IF;
END $$;
GRANT USAGE ON SCHEMA public TO rentwell_test_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rentwell_test_app;

-- Hàm hỗ trợ (tạo trong giao dịch, bị ROLLBACK cùng)
CREATE FUNCTION public.test_expect_fail(p_sql text, p_state text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = p_state THEN
      RAISE NOTICE 'OK   %', p_label;
      RETURN;
    END IF;
    RAISE EXCEPTION 'FAIL %: mong đợi SQLSTATE %, nhận % (%)', p_label, p_state, SQLSTATE, SQLERRM;
  END;
  RAISE EXCEPTION 'FAIL %: mong đợi lỗi % nhưng câu lệnh thành công', p_label, p_state;
END $$;

CREATE FUNCTION public.test_expect_count(p_sql text, p_expected int, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE n int;
BEGIN
  EXECUTE p_sql INTO n;
  IF n IS DISTINCT FROM p_expected THEN
    RAISE EXCEPTION 'FAIL %: mong đợi %, nhận %', p_label, p_expected, n;
  END IF;
  RAISE NOTICE 'OK   %', p_label;
END $$;
GRANT EXECUTE ON FUNCTION public.test_expect_fail(text, text, text) TO rentwell_test_app;
GRANT EXECUTE ON FUNCTION public.test_expect_count(text, int, text) TO rentwell_test_app;

-- Dữ liệu nền (chạy bằng quyền hiện tại, bỏ qua RLS)
INSERT INTO tenants (id, name, slug) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Chuoi A', 'chuoi-a'),
  ('bbbbbbbb-0000-0000-0000-000000000001', 'Chuoi B', 'chuoi-b');

INSERT INTO branches (id, tenant_id, name, slug, address_line, ward_code, province_code) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'A1', 'a1', '1 Le Loi', '00001', '79'),
  ('aaaaaaaa-1111-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001', 'A2', 'a2', '2 Le Loi', '00002', '79');

-- ---------------------------------------------------------------------
-- 1. Khách vãng lai (customer_profiles)
-- ---------------------------------------------------------------------
SET LOCAL ROLE rentwell_test_app;
SELECT set_config('app.tenant_id', 'aaaaaaaa-0000-0000-0000-000000000001', true);

INSERT INTO customer_profiles (tenant_id, full_name, phone)
VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'Khach Vang Lai', '0900000001');
SELECT public.test_expect_count(
  $q$SELECT count(*)::int FROM customer_profiles WHERE phone = '0900000001'$q$, 1,
  'tạo hồ sơ vãng lai chỉ với tên và sđt');

SELECT public.test_expect_fail(
  $q$INSERT INTO customer_profiles (tenant_id) VALUES ('aaaaaaaa-0000-0000-0000-000000000001')$q$,
  '23514', 'thiếu cả user_id lẫn tên/sđt bị CHECK chặn');
SELECT public.test_expect_fail(
  $q$INSERT INTO customer_profiles (tenant_id, full_name) VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'Chi co ten')$q$,
  '23514', 'có tên nhưng thiếu sđt bị chặn');

-- Chuỗi B không thấy hồ sơ của chuỗi A
SELECT set_config('app.tenant_id', 'bbbbbbbb-0000-0000-0000-000000000001', true);
SELECT public.test_expect_count(
  $q$SELECT count(*)::int FROM customer_profiles$q$, 0,
  'tenant B không đọc được hồ sơ vãng lai của tenant A');
SELECT public.test_expect_fail(
  $q$INSERT INTO customer_profiles (tenant_id, full_name, phone)
     VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'Gia mao', '0900000002')$q$,
  '42501', 'tenant B không ghi được hồ sơ vào tenant A');

-- ---------------------------------------------------------------------
-- 2. Ngày lễ dùng chung + phụ thu theo chuỗi
-- ---------------------------------------------------------------------
-- Role tenant thường không ghi được holidays
SELECT public.test_expect_fail(
  $q$INSERT INTO holidays (code, name, start_date, end_date) VALUES ('tet-test', 'Tet', '2027-02-05', '2027-02-12')$q$,
  '42501', 'role tenant thường không ghi được holidays');

-- Super admin ghi được
SELECT set_config('app.is_super_admin', 'true', true);
INSERT INTO holidays (id, code, name, start_date, end_date)
VALUES ('cccccccc-0000-0000-0000-000000000001', 'tet-test', 'Tet', '2027-02-05', '2027-02-12');
SELECT set_config('app.is_super_admin', '', true);

SELECT public.test_expect_count(
  $q$SELECT count(*)::int FROM holidays WHERE code = 'tet-test'$q$, 1,
  'mọi tenant đọc được holidays');
SELECT public.test_expect_fail(
  $q$INSERT INTO holidays (code, name, start_date, end_date) VALUES ('bad', 'Bad', '2027-03-01', '2027-03-01')$q$,
  '42501', 'ghi holidays không phải admin bị chặn (kiểm tra RLS đứng trước CHECK)');

SELECT set_config('app.tenant_id', 'aaaaaaaa-0000-0000-0000-000000000001', true);
INSERT INTO holiday_surcharges (tenant_id, holiday_id, mode, value)
VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'cccccccc-0000-0000-0000-000000000001', 'percent', 20);
SELECT public.test_expect_count($q$SELECT count(*)::int FROM holiday_surcharges$q$, 1,
  'chuỗi A gán được phụ thu ngày lễ');
SELECT public.test_expect_fail(
  $q$UPDATE holiday_surcharges SET value = 150 WHERE mode = 'percent'$q$,
  '23514', 'phụ thu percent trên 100 bị chặn');
SELECT public.test_expect_fail(
  $q$UPDATE holiday_surcharges SET value = 0$q$,
  '23514', 'phụ thu bằng 0 bị chặn');

SELECT set_config('app.tenant_id', 'bbbbbbbb-0000-0000-0000-000000000001', true);
SELECT public.test_expect_count($q$SELECT count(*)::int FROM holiday_surcharges$q$, 0,
  'tenant B không thấy phụ thu của tenant A');

-- Super admin được bỏ ràng buộc khoảng ngày sai? Không: CHECK vẫn áp cho mọi role
SELECT set_config('app.is_super_admin', 'true', true);
SELECT public.test_expect_fail(
  $q$INSERT INTO holidays (code, name, start_date, end_date) VALUES ('bad2', 'Bad', '2027-03-01', '2027-03-01')$q$,
  '23514', 'end_date phải sau start_date, kể cả super admin');
SELECT set_config('app.is_super_admin', '', true);

-- ---------------------------------------------------------------------
-- 3. opening_hours phải là object
-- ---------------------------------------------------------------------
SELECT set_config('app.tenant_id', 'aaaaaaaa-0000-0000-0000-000000000001', true);
SELECT public.test_expect_fail(
  $q$UPDATE branches SET opening_hours = '[]'::jsonb WHERE slug = 'a1'$q$,
  '23514', 'opening_hours dạng mảng bị chặn');
UPDATE branches SET opening_hours = '{"mon":{"open":"08:00","close":"20:00"},"sun":null}'::jsonb WHERE slug = 'a1';
SELECT public.test_expect_count(
  $q$SELECT count(*)::int FROM branches WHERE slug = 'a1' AND opening_hours -> 'sun' = 'null'::jsonb$q$, 1,
  'opening_hours đúng định dạng được lưu, ngày nghỉ là null');

-- ---------------------------------------------------------------------
-- 4. Đóng chi nhánh
-- ---------------------------------------------------------------------
-- Chi nhánh sạch đóng được
UPDATE branches SET status = 'closed' WHERE slug = 'a2';
SELECT public.test_expect_count(
  $q$SELECT count(*)::int FROM branches WHERE slug = 'a2' AND status = 'closed'$q$, 1,
  'chi nhánh không còn việc dang dở đóng được');

-- Chi nhánh có phiếu chuyển hàng đang mở bị chặn
INSERT INTO branches (id, tenant_id, name, slug, address_line, ward_code, province_code)
VALUES ('aaaaaaaa-1111-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0000-000000000001', 'A3', 'a3', '3 Le Loi', '00003', '79');
INSERT INTO stock_transfers (id, tenant_id, code, from_branch_id, to_branch_id, status)
VALUES ('dddddddd-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'TR-1',
        'aaaaaaaa-1111-0000-0000-000000000003', 'aaaaaaaa-1111-0000-0000-000000000001', 'requested');
SELECT public.test_expect_fail(
  $q$UPDATE branches SET status = 'closed' WHERE slug = 'a3'$q$,
  '23514', 'còn phiếu chuyển hàng mở thì không đóng được chi nhánh nguồn');
SELECT public.test_expect_fail(
  $q$UPDATE branches SET status = 'closed' WHERE slug = 'a1'$q$,
  '23514', 'còn phiếu chuyển hàng mở thì không đóng được chi nhánh đích');

UPDATE stock_transfers SET status = 'cancelled' WHERE code = 'TR-1';
UPDATE branches SET status = 'closed' WHERE slug = 'a3';
SELECT public.test_expect_count(
  $q$SELECT count(*)::int FROM branches WHERE slug = 'a3' AND status = 'closed'$q$, 1,
  'hủy phiếu xong thì đóng được chi nhánh');

RESET ROLE;
ROLLBACK;
