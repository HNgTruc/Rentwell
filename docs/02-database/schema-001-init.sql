-- migrate:up transaction:false
-- (dấu cho dbmate; transaction:false vì file tự có BEGIN/COMMIT. Không có phần down: lùi bằng migration mới.)
-- =====================================================================
-- 001_init.sql  |  Nền tảng cho thuê đồ (multi-tenant)  |  PostgreSQL 15+
-- Phạm vi: P1 (MVP)
--   * Thuê theo ĐÊM: nhận ngày 10, trả ngày 12 = 2 đêm  -> [start_date, end_date)
--   * Tồn kho theo SỐ LƯỢNG trên từng BIẾN THỂ (SKU: size/màu). Giày/bông tai = 1 món
--   * tenant = một CHUỖI cửa hàng; chuỗi có nhiều CHI NHÁNH (bảng branches), mỗi chi nhánh
--     có kho riêng (branch_stock) và điểm nhận/trả riêng. Đơn thuộc đúng 1 chi nhánh,
--     trả đồ tại đúng chi nhánh đã thuê (ADR 0006)
--   * Giao tận nơi: chỉ cùng tỉnh/thành của chi nhánh giao; phí do chuỗi đặt (cấp chuỗi)
--   * Mọi bảng nghiệp vụ có tenant_id + Row Level Security
-- Quy ước:
--   * Tiền: bigint, đơn vị nhỏ nhất của tiền tệ (VND không có số lẻ)
--   * Khóa ngoại giữa các bảng theo cửa hàng dùng cặp (tenant_id, id)
--     để không thể tham chiếu chéo cửa hàng
--   * App phải kết nối bằng role KHÔNG phải superuser/owner, và đặt mỗi request:
--       SET LOCAL app.tenant_id = '<uuid>';      -- cửa hàng đang thao tác
--       SET LOCAL app.is_super_admin = 'true';   -- chỉ cho quản trị nền tảng/job nền
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 0. Hàm dùng chung
-- ---------------------------------------------------------------------
CREATE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE FUNCTION forbid_modification() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ được ghi thêm, không sửa/xóa', TG_TABLE_NAME
    USING ERRCODE = '42501';
END $$;

CREATE FUNCTION current_tenant_id() RETURNS uuid
LANGUAGE sql STABLE AS
$$ SELECT nullif(current_setting('app.tenant_id', true), '')::uuid $$;

CREATE FUNCTION is_platform_admin() RETURNS boolean
LANGUAGE sql STABLE AS
$$ SELECT coalesce(current_setting('app.is_super_admin', true), '') = 'true' $$;

-- ---------------------------------------------------------------------
-- 1. Cửa hàng, tài khoản, phân quyền
-- ---------------------------------------------------------------------
CREATE TABLE tenants (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name              text NOT NULL,
  slug              text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  phone             text,
  email             text,
  -- Địa chỉ, tọa độ, giờ nhận/trả, giao hàng nằm ở bảng branches (mỗi chi nhánh một điểm)
  timezone          text NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  currency          char(3) NOT NULL DEFAULT 'VND',
  plan              text NOT NULL DEFAULT 'free',
  settings          jsonb NOT NULL DEFAULT '{}',     -- vd: {"support_refund_limit": 500000}
  status            text NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended','closed')),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- Chi nhánh: một điểm nhận/trả + một kho. Phí giao và phí trễ do CHUỖI đặt (không ghi đè theo chi nhánh).
CREATE TABLE branches (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         uuid NOT NULL REFERENCES tenants (id),
  name              text NOT NULL,
  slug              text NOT NULL CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  phone             text,
  address_line      text NOT NULL,
  ward_code         text NOT NULL,          -- mã xã/phường theo danh mục hành chính hiện hành
  province_code     text NOT NULL,          -- mã tỉnh/thành: ràng buộc phạm vi giao hàng
  latitude          numeric(9,6),
  longitude         numeric(9,6),
  pickup_time       time NOT NULL DEFAULT '08:00',   -- giờ bắt đầu nhận đồ trong ngày nhận
  return_time       time NOT NULL DEFAULT '18:00',   -- hạn trả đồ trong ngày trả (quá giờ tính phí trễ)
  -- Giờ mở cửa: {"mon":{"open":"08:00","close":"20:00"},"sun":null,...}; null hoặc thiếu = nghỉ. Zod ở API kiểm định dạng chi tiết (ADR 0009).
  opening_hours     jsonb NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(opening_hours) = 'object'),
  delivery_enabled  boolean NOT NULL DEFAULT false,
  accepts_online    boolean NOT NULL DEFAULT true,   -- false = chỉ nhận đơn tại quầy
  status            text NOT NULL DEFAULT 'active' CHECK (status IN ('active','closed')),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, slug),
  UNIQUE (tenant_id, id)
);
CREATE INDEX branches_province_idx ON branches (tenant_id, province_code) WHERE status = 'active';

CREATE TABLE users (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email          text NOT NULL,
  phone          text,
  password_hash  text,                                -- NULL nếu đăng nhập qua bên thứ ba
  full_name      text NOT NULL,
  is_super_admin boolean NOT NULL DEFAULT false,
  status         text NOT NULL DEFAULT 'active' CHECK (status IN ('active','locked','deleted')),
  last_login_at  timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX users_email_key ON users (lower(email));
CREATE UNIQUE INDEX users_phone_key ON users (phone) WHERE phone IS NOT NULL;

CREATE TABLE memberships (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid NOT NULL REFERENCES tenants (id),
  user_id    uuid NOT NULL REFERENCES users (id),
  role       text NOT NULL CHECK (role IN ('owner','manager','staff','warehouse','support','customer')),
  branch_id  uuid,                                   -- NULL = làm cho cả chuỗi; có giá trị = chỉ chi nhánh đó
  status     text NOT NULL DEFAULT 'active' CHECK (status IN ('active','invited','disabled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, branch_id) REFERENCES branches (tenant_id, id)
);
-- Một người có thể giữ nhiều vai trò/chi nhánh, nhưng không trùng; NULL được coi như một giá trị
CREATE UNIQUE INDEX memberships_unique_scope ON memberships
  (tenant_id, user_id, role, coalesce(branch_id, '00000000-0000-0000-0000-000000000000'::uuid));
CREATE INDEX memberships_user_idx ON memberships (user_id);

CREATE TABLE files (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES tenants (id),
  storage_key text NOT NULL UNIQUE,
  mime_type   text NOT NULL,
  size_bytes  bigint NOT NULL CHECK (size_bytes >= 0),
  sha256      text,
  is_private  boolean NOT NULL DEFAULT true,
  uploaded_by uuid REFERENCES users (id),
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id)
);

-- Hồ sơ khách THEO CHUỖI (xác minh, điểm tin cậy, danh sách đen). Tên, sđt, email, địa chỉ giao dùng chung nằm ở users/user_addresses.
-- Khách vãng lai ở đơn tại quầy: user_id NULL, chỉ cần full_name và phone; sau này gán user_id khi khách có tài khoản (ADR 0009).
CREATE TABLE customer_profiles (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           uuid NOT NULL REFERENCES tenants (id),
  user_id             uuid REFERENCES users (id),
  full_name           text,
  phone               text,
  linked_at           timestamptz,                 -- thời điểm gán tài khoản cho hồ sơ vãng lai
  CONSTRAINT customer_profiles_identity CHECK (user_id IS NOT NULL OR (full_name IS NOT NULL AND phone IS NOT NULL)),
  verification_status text NOT NULL DEFAULT 'unverified'
                      CHECK (verification_status IN ('unverified','pending','verified','rejected')),
  trust_score         int NOT NULL DEFAULT 0,
  is_blacklisted      boolean NOT NULL DEFAULT false,
  internal_note       text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, user_id),
  UNIQUE (tenant_id, id)
);
CREATE INDEX customer_profiles_phone_idx ON customer_profiles (tenant_id, phone) WHERE phone IS NOT NULL;

CREATE TABLE verification_documents (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           uuid NOT NULL,
  customer_profile_id uuid NOT NULL,
  doc_type            text NOT NULL CHECK (doc_type IN ('national_id','driver_license','passport','student_card','other')),
  file_id             uuid NOT NULL,
  status              text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  reviewed_by         uuid REFERENCES users (id),
  reviewed_at         timestamptz,
  expires_at          date,
  created_at          timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id, customer_profile_id) REFERENCES customer_profiles (tenant_id, id),
  FOREIGN KEY (tenant_id, file_id)             REFERENCES files (tenant_id, id)
);

-- Sổ địa chỉ của người dùng (dùng chung mọi cửa hàng, không có tenant_id).
-- Đơn hàng sao chép địa chỉ vào chính nó (snapshot), không tham chiếu bảng này.
CREATE TABLE user_addresses (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  label         text,
  receiver_name text NOT NULL,
  phone         text NOT NULL,
  address_line  text NOT NULL,
  ward_code     text,
  province_code text NOT NULL,
  latitude      numeric(9,6),
  longitude     numeric(9,6),
  is_default    boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX user_addresses_one_default ON user_addresses (user_id) WHERE is_default;

-- ---------------------------------------------------------------------
-- 2. Danh mục, mẫu sản phẩm, biến thể (SKU)
-- ---------------------------------------------------------------------
CREATE TABLE brands (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  name      text NOT NULL,
  country   text,
  logo_file_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, name),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, logo_file_id) REFERENCES files (tenant_id, id)
);

CREATE TABLE suppliers (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  name      text NOT NULL,
  phone     text,
  email     text,
  address   text,
  tax_code  text,
  note      text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id)
);

CREATE TABLE categories (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid NOT NULL REFERENCES tenants (id),
  parent_id  uuid,
  name       text NOT NULL,
  slug       text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, slug),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, parent_id) REFERENCES categories (tenant_id, id)
);

-- Thuộc tính động theo danh mục (xuất xứ riêng, chất liệu, size...)
CREATE TABLE attribute_definitions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     uuid NOT NULL,
  category_id   uuid NOT NULL,
  key           text NOT NULL CHECK (key ~ '^[a-z][a-z0-9_]*$'),
  label         text NOT NULL,
  data_type     text NOT NULL CHECK (data_type IN ('text','number','date','boolean','select')),
  options       jsonb,
  level         text NOT NULL CHECK (level IN ('item_type','variant')),
  is_required   boolean NOT NULL DEFAULT false,
  is_filterable boolean NOT NULL DEFAULT false,
  sort_order    int NOT NULL DEFAULT 0,
  UNIQUE (tenant_id, category_id, level, key),
  FOREIGN KEY (tenant_id, category_id) REFERENCES categories (tenant_id, id)
);

-- Mẫu sản phẩm: thông tin chung (ví dụ "Giày Nike Air Force 1")
CREATE TABLE item_types (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             uuid NOT NULL REFERENCES tenants (id),
  category_id           uuid NOT NULL,
  brand_id              uuid,
  name                  text NOT NULL,
  model_code            text,
  slug                  text NOT NULL,
  description           text,
  country_of_origin     text,                 -- nơi sản xuất / xuất xứ của mẫu
  manufacturer          text,
  release_year          smallint CHECK (release_year BETWEEN 1900 AND 2100),
  attributes            jsonb NOT NULL DEFAULT '{}',
  base_price_per_night  bigint NOT NULL CHECK (base_price_per_night >= 0),
  deposit_type          text NOT NULL DEFAULT 'fixed' CHECK (deposit_type IN ('fixed','percent')),
  deposit_value         bigint NOT NULL DEFAULT 0 CHECK (deposit_value >= 0),
  min_nights            int NOT NULL DEFAULT 1 CHECK (min_nights >= 1),
  max_nights            int,
  advance_notice_days   int NOT NULL DEFAULT 0 CHECK (advance_notice_days >= 0),
  buffer_nights         int NOT NULL DEFAULT 0 CHECK (buffer_nights >= 0),  -- đêm đệm để vệ sinh sau khi trả
  free_size_exchange    boolean NOT NULL DEFAULT false,  -- true (quần áo, thời trang): đổi size tại quầy không thu phí
  requires_verification boolean NOT NULL DEFAULT false,
  verification_min_deposit bigint CHECK (verification_min_deposit IS NULL OR verification_min_deposit >= 0),  -- NULL = luôn bắt khi cờ bật; có giá trị = chỉ bắt khi cọc của dòng đạt ngưỡng (ADR 0009)
  min_customer_age      smallint,
  usage_guide           text,
  safety_notes          text,
  tags                  text[] NOT NULL DEFAULT '{}',
  is_active             boolean NOT NULL DEFAULT true,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, slug),
  UNIQUE (tenant_id, id),
  CHECK (max_nights IS NULL OR max_nights >= min_nights),
  CHECK (deposit_type <> 'percent' OR deposit_value <= 100),
  FOREIGN KEY (tenant_id, category_id) REFERENCES categories (tenant_id, id),
  FOREIGN KEY (tenant_id, brand_id)    REFERENCES brands (tenant_id, id)
);
CREATE INDEX item_types_category_idx ON item_types (tenant_id, category_id) WHERE is_active;
CREATE INDEX item_types_tags_idx ON item_types USING gin (tags);

CREATE TABLE item_type_images (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL,
  item_type_id uuid NOT NULL,
  file_id      uuid NOT NULL,
  sort_order   int NOT NULL DEFAULT 0,
  FOREIGN KEY (tenant_id, item_type_id) REFERENCES item_types (tenant_id, id) ON DELETE CASCADE,
  FOREIGN KEY (tenant_id, file_id)      REFERENCES files (tenant_id, id)
);

-- Biến thể (SKU): đơn vị tồn kho thực sự. Mẫu không có size/màu vẫn có 1 biến thể "Mặc định".
CREATE TABLE item_variants (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id               uuid NOT NULL,
  item_type_id            uuid NOT NULL,
  sku                     text NOT NULL,
  name                    text NOT NULL,                 -- "Size 39 / Đen"
  attributes              jsonb NOT NULL DEFAULT '{}',
  price_override_per_night bigint CHECK (price_override_per_night >= 0),
  replacement_value       bigint NOT NULL DEFAULT 0 CHECK (replacement_value >= 0),
  -- Số lượng tồn nằm ở branch_stock (theo từng chi nhánh), chỉ đổi qua inventory_movements
  is_active               boolean NOT NULL DEFAULT true,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, sku),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, item_type_id) REFERENCES item_types (tenant_id, id)
);
CREATE INDEX item_variants_type_idx ON item_variants (tenant_id, item_type_id);

-- ---------------------------------------------------------------------
-- 3. Giá, chính sách (mỗi cửa hàng tự đặt)
-- ---------------------------------------------------------------------
-- Giảm giá khi thuê nhiều đêm (vd từ 3 đêm giảm 10%)
CREATE TABLE price_tiers (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL,
  item_type_id     uuid NOT NULL,
  min_nights       int NOT NULL CHECK (min_nights >= 2),
  discount_percent numeric(5,2) NOT NULL CHECK (discount_percent > 0 AND discount_percent <= 100),
  UNIQUE (item_type_id, min_nights),
  FOREIGN KEY (tenant_id, item_type_id) REFERENCES item_types (tenant_id, id) ON DELETE CASCADE
);

-- Giá theo mùa/dịp lễ (120 = tăng 20%). Việc không cho khoảng ngày chồng nhau do app kiểm tra.
CREATE TABLE seasonal_prices (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id          uuid NOT NULL,
  item_type_id       uuid NOT NULL,
  label              text NOT NULL,
  start_date         date NOT NULL,
  end_date           date NOT NULL,
  multiplier_percent int NOT NULL CHECK (multiplier_percent BETWEEN 1 AND 1000),
  CHECK (end_date >= start_date),
  FOREIGN KEY (tenant_id, item_type_id) REFERENCES item_types (tenant_id, id) ON DELETE CASCADE
);

-- Lịch ngày lễ DÙNG CHUNG toàn nền tảng, không có tenant_id (RLS riêng ở mục 10: mọi người đọc, chỉ super admin ghi).
-- Khoảng [start_date, end_date) cùng quy ước đêm. Phụ thu do từng chuỗi gán ở holiday_surcharges (ADR 0009).
CREATE TABLE holidays (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code       text NOT NULL UNIQUE,                 -- vd: tet-2027
  name       text NOT NULL,
  start_date date NOT NULL,
  end_date   date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_date > start_date)
);

-- Phụ thu ngày lễ theo chuỗi: percent (1 đến 100, của giá đêm) hoặc fixed (đồng mỗi đêm). Cộng vào giá đêm TRƯỚC giảm bậc.
-- Chưa có phụ thu theo loại món (backlog).
CREATE TABLE holiday_surcharges (
  tenant_id  uuid NOT NULL REFERENCES tenants (id),
  holiday_id uuid NOT NULL REFERENCES holidays (id),
  mode       text NOT NULL CHECK (mode IN ('percent','fixed')),
  value      bigint NOT NULL CHECK (value > 0),
  is_active  boolean NOT NULL DEFAULT true,
  PRIMARY KEY (tenant_id, holiday_id),
  CHECK (mode <> 'percent' OR value <= 100)
);

-- rules: [{"hours_before_start": 48, "refund_percent": 100}, {"hours_before_start": 0, "refund_percent": 0}]
CREATE TABLE cancellation_policies (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid NOT NULL REFERENCES tenants (id),
  name       text NOT NULL,
  rules      jsonb NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id)
);
CREATE UNIQUE INDEX cancellation_policies_one_default ON cancellation_policies (tenant_id) WHERE is_default;

-- Phí trả trễ: mỗi cửa hàng một bộ quy tắc
CREATE TABLE late_fee_rules (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL UNIQUE REFERENCES tenants (id),
  grace_hours  int NOT NULL DEFAULT 2 CHECK (grace_hours >= 0),
  fee_mode     text NOT NULL DEFAULT 'percent_of_nightly'
               CHECK (fee_mode IN ('percent_of_nightly','fixed_per_night')),
  fee_value    numeric(12,2) NOT NULL CHECK (fee_value >= 0),
  max_nights_charged int,
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- Phí giao hàng: mỗi cửa hàng tự quyết định cách tính cho hợp lý với khu vực của mình.
--   flat           : một mức phí cố định
--   per_km         : base_fee cho base_km đầu, sau đó per_km_fee cho mỗi km thêm
--   distance_tiers : tra bảng delivery_fee_tiers theo khoảng cách
-- Khoảng cách (km) do app tính (đường chim bay hoặc API bản đồ) TỪ CHI NHÁNH GIAO rồi lưu vào đơn.
-- Quy tắc ở cấp chuỗi: mọi chi nhánh dùng chung, không ghi đè theo chi nhánh.
CREATE TABLE delivery_fee_rules (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         uuid NOT NULL UNIQUE REFERENCES tenants (id),
  mode              text NOT NULL CHECK (mode IN ('flat','per_km','distance_tiers')),
  flat_fee          bigint CHECK (flat_fee >= 0),
  base_fee          bigint CHECK (base_fee >= 0),
  base_km           numeric(6,2) CHECK (base_km >= 0),
  per_km_fee        bigint CHECK (per_km_fee >= 0),
  max_distance_km   numeric(6,2) NOT NULL CHECK (max_distance_km > 0),
  free_over_amount  bigint CHECK (free_over_amount >= 0),    -- miễn phí khi đơn từ mức này
  min_order_amount  bigint CHECK (min_order_amount >= 0),
  applies_to        text NOT NULL DEFAULT 'both' CHECK (applies_to IN ('outbound','return','both')),
  is_active         boolean NOT NULL DEFAULT true,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  CHECK (mode <> 'flat'   OR flat_fee IS NOT NULL),
  CHECK (mode <> 'per_km' OR (base_fee IS NOT NULL AND base_km IS NOT NULL AND per_km_fee IS NOT NULL))
);

CREATE TABLE delivery_fee_tiers (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  from_km   numeric(6,2) NOT NULL CHECK (from_km >= 0),
  to_km     numeric(6,2) NOT NULL,
  fee       bigint NOT NULL CHECK (fee >= 0),
  CHECK (to_km > from_km),
  UNIQUE (tenant_id, from_km)
);

-- ---------------------------------------------------------------------
-- 4. Đơn thuê
-- ---------------------------------------------------------------------
CREATE TABLE bookings (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id            uuid NOT NULL REFERENCES tenants (id),
  code                 text NOT NULL,                       -- mã đơn dễ đọc, app tạo
  branch_id            uuid NOT NULL,                       -- chi nhánh giữ hàng, giao/nhận và NHẬN LẠI đồ trả
  channel              text NOT NULL DEFAULT 'online' CHECK (channel IN ('online','offline')),  -- offline = tại quầy
  customer_profile_id  uuid NOT NULL,
  status               text NOT NULL DEFAULT 'hold'
                       CHECK (status IN ('hold','confirmed','handed_over','returned','completed','cancelled','expired')),
  start_date           date NOT NULL,                        -- ngày nhận
  end_date             date NOT NULL,                        -- ngày trả
  nights               int GENERATED ALWAYS AS (end_date - start_date) STORED,
  fulfillment          text NOT NULL DEFAULT 'pickup' CHECK (fulfillment IN ('pickup','delivery')),
  -- Địa chỉ giao (snapshot tại thời điểm đặt)
  delivery_receiver      text,
  delivery_phone         text,
  delivery_address_line  text,
  delivery_ward_code     text,
  delivery_province_code text,
  delivery_latitude      numeric(9,6),
  delivery_longitude     numeric(9,6),
  delivery_distance_km   numeric(6,2),                       -- tính từ chi nhánh của đơn
  delivery_fee           bigint NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
  subtotal             bigint NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  discount             bigint NOT NULL DEFAULT 0 CHECK (discount >= 0),
  deposit_total        bigint NOT NULL DEFAULT 0 CHECK (deposit_total >= 0),
  total                bigint NOT NULL DEFAULT 0 CHECK (total >= 0),
  cancellation_policy_snapshot jsonb,
  late_fee_snapshot    jsonb,
  hold_expires_at      timestamptz,
  note                 text,
  created_by           uuid REFERENCES users (id),
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, code),
  UNIQUE (tenant_id, id),
  UNIQUE (tenant_id, id, branch_id),                         -- để bàn giao/đổi hàng buộc đúng chi nhánh của đơn
  CHECK (end_date > start_date),
  CONSTRAINT bookings_delivery_fields CHECK (
    fulfillment = 'pickup'
    OR (delivery_receiver IS NOT NULL AND delivery_phone IS NOT NULL
        AND delivery_address_line IS NOT NULL AND delivery_province_code IS NOT NULL)
  ),
  CONSTRAINT bookings_hold_has_expiry CHECK (status <> 'hold' OR hold_expires_at IS NOT NULL),
  FOREIGN KEY (tenant_id, branch_id)           REFERENCES branches (tenant_id, id),
  FOREIGN KEY (tenant_id, customer_profile_id) REFERENCES customer_profiles (tenant_id, id)
);
CREATE INDEX bookings_branch_idx ON bookings (tenant_id, branch_id, status, start_date);
CREATE INDEX bookings_customer_idx ON bookings (tenant_id, customer_profile_id, created_at DESC);
CREATE INDEX bookings_status_dates_idx ON bookings (tenant_id, status, start_date);
CREATE INDEX bookings_hold_expiry_idx ON bookings (hold_expires_at) WHERE status = 'hold';

CREATE TABLE booking_items (
  id                         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id                  uuid NOT NULL,
  booking_id                 uuid NOT NULL,
  variant_id                 uuid NOT NULL,
  quantity                   int NOT NULL CHECK (quantity > 0),
  price_per_night            bigint NOT NULL CHECK (price_per_night >= 0),  -- đã gồm giảm theo bậc/mùa
  line_total                 bigint NOT NULL CHECK (line_total >= 0),
  deposit_amount             bigint NOT NULL DEFAULT 0 CHECK (deposit_amount >= 0),
  replacement_value_snapshot bigint NOT NULL DEFAULT 0,
  buffer_nights              int NOT NULL DEFAULT 0 CHECK (buffer_nights >= 0), -- snapshot để nhả đúng số đêm đã giữ
  UNIQUE (booking_id, variant_id),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, booking_id) REFERENCES bookings (tenant_id, id) ON DELETE CASCADE,
  FOREIGN KEY (tenant_id, variant_id) REFERENCES item_variants (tenant_id, id)
);
CREATE INDEX booking_items_variant_idx ON booking_items (tenant_id, variant_id);

CREATE TABLE booking_status_history (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL,
  booking_id  uuid NOT NULL,
  from_status text,
  to_status   text NOT NULL,
  changed_by  uuid REFERENCES users (id),
  reason      text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id, booking_id) REFERENCES bookings (tenant_id, id) ON DELETE CASCADE
);
CREATE INDEX booking_status_history_idx ON booking_status_history (booking_id, created_at);

CREATE TABLE rental_contracts (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         uuid NOT NULL,
  booking_id        uuid NOT NULL UNIQUE,
  terms_version     text NOT NULL,
  accepted_at       timestamptz NOT NULL,
  accepted_ip       inet,
  signature_file_id uuid,
  pdf_file_id       uuid,
  FOREIGN KEY (tenant_id, booking_id)        REFERENCES bookings (tenant_id, id),
  FOREIGN KEY (tenant_id, signature_file_id) REFERENCES files (tenant_id, id),
  FOREIGN KEY (tenant_id, pdf_file_id)       REFERENCES files (tenant_id, id)
);

-- Bàn giao (giao đồ cho khách) và trả đồ: mỗi đơn tối đa 1 lần mỗi loại
CREATE TABLE handovers (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             uuid NOT NULL,
  booking_id            uuid NOT NULL,
  branch_id             uuid NOT NULL,                -- phải trùng chi nhánh của đơn (giao và trả đúng nơi)
  kind                  text NOT NULL CHECK (kind IN ('handover','return')),
  performed_by          uuid NOT NULL REFERENCES users (id),
  customer_confirmed_at timestamptz,
  note                  text,
  created_at            timestamptz NOT NULL DEFAULT now(),
  UNIQUE (booking_id, kind),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, booking_id, branch_id) REFERENCES bookings (tenant_id, id, branch_id)
);

-- Khi trả: quantity_ok + quantity_damaged + quantity_missing = số lượng đã thuê (app kiểm tra)
CREATE TABLE handover_lines (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         uuid NOT NULL,
  handover_id       uuid NOT NULL,
  booking_item_id   uuid NOT NULL,
  quantity_ok       int NOT NULL DEFAULT 0 CHECK (quantity_ok >= 0),
  quantity_damaged  int NOT NULL DEFAULT 0 CHECK (quantity_damaged >= 0),
  quantity_missing  int NOT NULL DEFAULT 0 CHECK (quantity_missing >= 0),
  note              text,
  UNIQUE (handover_id, booking_item_id),
  FOREIGN KEY (tenant_id, handover_id)     REFERENCES handovers (tenant_id, id) ON DELETE CASCADE,
  FOREIGN KEY (tenant_id, booking_item_id) REFERENCES booking_items (tenant_id, id)
);

CREATE TABLE handover_photos (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       uuid NOT NULL,
  handover_id     uuid NOT NULL,
  booking_item_id uuid,
  file_id         uuid NOT NULL,
  label           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id, handover_id)     REFERENCES handovers (tenant_id, id) ON DELETE CASCADE,
  FOREIGN KEY (tenant_id, booking_item_id) REFERENCES booking_items (tenant_id, id),
  FOREIGN KEY (tenant_id, file_id)         REFERENCES files (tenant_id, id)
);

CREATE TABLE extensions (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id          uuid NOT NULL,
  booking_id         uuid NOT NULL,
  previous_end_date  date NOT NULL,
  requested_end_date date NOT NULL,
  extra_amount       bigint NOT NULL DEFAULT 0 CHECK (extra_amount >= 0),
  status             text NOT NULL DEFAULT 'requested' CHECK (status IN ('requested','approved','rejected')),
  requested_by       uuid REFERENCES users (id),
  decided_by         uuid REFERENCES users (id),
  decided_at         timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  CHECK (requested_end_date > previous_end_date),
  FOREIGN KEY (tenant_id, booking_id) REFERENCES bookings (tenant_id, id)
);

CREATE TABLE fees (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL,
  booking_id  uuid NOT NULL,
  fee_type    text NOT NULL CHECK (fee_type IN ('late','damage','missing','cleaning','delivery','other')),
  amount      bigint NOT NULL CHECK (amount >= 0),
  reason      text,
  status      text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','charged','waived')),
  created_by  uuid REFERENCES users (id),
  created_at  timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id, booking_id) REFERENCES bookings (tenant_id, id)
);

-- ---------------------------------------------------------------------
-- 5. Tồn kho
-- ---------------------------------------------------------------------
-- Lô hàng: giữ nguồn gốc (ngày/nơi sản xuất, nhà cung cấp...) khi không theo dõi từng chiếc
CREATE TABLE inventory_lots (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id          uuid NOT NULL,
  branch_id          uuid NOT NULL,             -- lô nhập về chi nhánh nào
  variant_id         uuid NOT NULL,
  lot_code           text,
  manufacture_date   date,                  -- ngày sản xuất
  manufacture_place  text,                  -- nơi sản xuất của lô này
  supplier_id        uuid,
  purchase_date      date,
  purchase_price     bigint CHECK (purchase_price >= 0),  -- giá mua / 1 đơn vị
  quantity_received  int NOT NULL CHECK (quantity_received > 0),
  condition_grade    text NOT NULL DEFAULT 'A' CHECK (condition_grade IN ('A','B','C')),
  warranty_expiry    date,
  note               text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  CHECK (manufacture_date IS NULL OR purchase_date IS NULL OR manufacture_date <= purchase_date),
  FOREIGN KEY (tenant_id, branch_id)   REFERENCES branches (tenant_id, id),
  FOREIGN KEY (tenant_id, variant_id)  REFERENCES item_variants (tenant_id, id),
  FOREIGN KEY (tenant_id, supplier_id) REFERENCES suppliers (tenant_id, id)
);

-- Tồn kho theo chi nhánh: nơi DUY NHẤT giữ số lượng dùng được. Chỉ đổi qua inventory_movements (trigger).
CREATE TABLE branch_stock (
  tenant_id       uuid NOT NULL,
  branch_id       uuid NOT NULL,
  variant_id      uuid NOT NULL,
  quantity_usable int NOT NULL DEFAULT 0 CHECK (quantity_usable >= 0),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (branch_id, variant_id),
  UNIQUE (tenant_id, branch_id, variant_id),
  FOREIGN KEY (tenant_id, branch_id)  REFERENCES branches (tenant_id, id),
  FOREIGN KEY (tenant_id, variant_id) REFERENCES item_variants (tenant_id, id)
);
CREATE INDEX branch_stock_variant_idx ON branch_stock (tenant_id, variant_id);

-- Phiếu chuyển hàng giữa chi nhánh (nghiệp vụ Kho). Quy trình:
--   requested -> approved -> in_transit -> received   (hoặc rejected / cancelled)
-- Xuất ghi transfer_out ở nguồn (trừ ngay); nhận ghi transfer_in ở đích (cộng). Hàng đang chuyển không dùng được ở đâu.
CREATE TABLE stock_transfers (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       uuid NOT NULL REFERENCES tenants (id),
  code            text NOT NULL,
  from_branch_id  uuid NOT NULL,
  to_branch_id    uuid NOT NULL,
  status          text NOT NULL DEFAULT 'requested'
                  CHECK (status IN ('requested','approved','in_transit','received','rejected','cancelled')),
  reason          text,
  requested_by    uuid REFERENCES users (id),
  approved_by     uuid REFERENCES users (id),
  approved_at     timestamptz,
  shipped_by      uuid REFERENCES users (id),
  shipped_at      timestamptz,
  received_by     uuid REFERENCES users (id),
  received_at     timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, code),
  UNIQUE (tenant_id, id),
  CHECK (from_branch_id <> to_branch_id),
  FOREIGN KEY (tenant_id, from_branch_id) REFERENCES branches (tenant_id, id),
  FOREIGN KEY (tenant_id, to_branch_id)   REFERENCES branches (tenant_id, id)
);
CREATE INDEX stock_transfers_status_idx ON stock_transfers (tenant_id, status, created_at DESC);

CREATE TABLE stock_transfer_lines (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           uuid NOT NULL,
  transfer_id         uuid NOT NULL,
  variant_id          uuid NOT NULL,
  quantity_requested  int NOT NULL CHECK (quantity_requested > 0),
  quantity_sent       int CHECK (quantity_sent >= 0),        -- điền khi xuất
  quantity_received   int CHECK (quantity_received >= 0),    -- điền khi nhận; chênh lệch ghi lost/damaged có transfer_id
  UNIQUE (transfer_id, variant_id),
  CHECK (quantity_sent IS NULL OR quantity_sent <= quantity_requested),
  CHECK (quantity_received IS NULL OR quantity_received <= coalesce(quantity_sent, 0)),
  FOREIGN KEY (tenant_id, transfer_id) REFERENCES stock_transfers (tenant_id, id) ON DELETE CASCADE,
  FOREIGN KEY (tenant_id, variant_id)  REFERENCES item_variants (tenant_id, id)
);

-- Sổ cái biến động tồn kho (chỉ ghi thêm). delta_usable tự suy ra từ loại.
-- Đặt thuê/trả KHÔNG ghi ở đây: việc giữ chỗ nằm ở inventory_calendar.
CREATE TABLE inventory_movements (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      uuid NOT NULL,
  branch_id      uuid NOT NULL,
  variant_id     uuid NOT NULL,
  lot_id         uuid,
  movement_type  text NOT NULL CHECK (movement_type IN
                   ('receive','damaged','lost','scrap','repair_out','repair_in','adjust_up','adjust_down',
                    'transfer_out','transfer_in')),
  quantity       int NOT NULL CHECK (quantity > 0),
  delta_usable   int GENERATED ALWAYS AS (
                   CASE WHEN movement_type IN ('receive','repair_in','adjust_up','transfer_in') THEN quantity ELSE -quantity END
                 ) STORED,
  reason         text,
  booking_id     uuid,                      -- hư/mất phát sinh từ đơn nào
  transfer_id    uuid,                      -- bắt buộc với transfer_out/transfer_in; có thể gắn cho lost/damaged khi vận chuyển
  created_by     uuid REFERENCES users (id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  CHECK (movement_type NOT IN ('transfer_out','transfer_in') OR transfer_id IS NOT NULL),
  FOREIGN KEY (tenant_id, branch_id)   REFERENCES branches (tenant_id, id),
  FOREIGN KEY (tenant_id, variant_id)  REFERENCES item_variants (tenant_id, id),
  FOREIGN KEY (tenant_id, lot_id)      REFERENCES inventory_lots (tenant_id, id),
  FOREIGN KEY (tenant_id, booking_id)  REFERENCES bookings (tenant_id, id),
  FOREIGN KEY (tenant_id, transfer_id) REFERENCES stock_transfers (tenant_id, id)
);
CREATE INDEX inventory_movements_variant_idx ON inventory_movements (tenant_id, branch_id, variant_id, created_at DESC);

-- Lịch tồn theo đêm: mỗi dòng = 1 chi nhánh x 1 biến thể x 1 đêm.
-- CHECK (reserved <= capacity) là chốt chặn cuối: hai khách đặt cùng lúc thì
-- người đến sau bị database từ chối (SQLSTATE 23514), không cần khóa thủ công.
CREATE TABLE inventory_calendar (
  tenant_id  uuid NOT NULL,
  branch_id  uuid NOT NULL,
  variant_id uuid NOT NULL,
  night      date NOT NULL,
  capacity   int NOT NULL CHECK (capacity >= 0),
  reserved   int NOT NULL DEFAULT 0 CHECK (reserved >= 0),
  PRIMARY KEY (branch_id, variant_id, night),
  CONSTRAINT inventory_not_oversold CHECK (reserved <= capacity),
  FOREIGN KEY (tenant_id, branch_id, variant_id) REFERENCES branch_stock (tenant_id, branch_id, variant_id) ON DELETE CASCADE
);
CREATE INDEX inventory_calendar_night_idx ON inventory_calendar (tenant_id, night);

-- Kiểm tra phiếu chuyển trước khi ghi sổ: đúng trạng thái, đúng chi nhánh, đúng món trong phiếu.
CREATE FUNCTION validate_transfer_movement() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_tr stock_transfers%ROWTYPE;
BEGIN
  IF NEW.transfer_id IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT * INTO v_tr FROM stock_transfers WHERE tenant_id = NEW.tenant_id AND id = NEW.transfer_id;
  IF NEW.movement_type = 'transfer_out' THEN
    IF v_tr.status <> 'approved' OR NEW.branch_id <> v_tr.from_branch_id THEN
      RAISE EXCEPTION 'Chỉ xuất kho cho phiếu đã duyệt, tại chi nhánh nguồn' USING ERRCODE = '23514';
    END IF;
  ELSIF NEW.movement_type = 'transfer_in' THEN
    IF v_tr.status <> 'in_transit' OR NEW.branch_id <> v_tr.to_branch_id THEN
      RAISE EXCEPTION 'Chỉ nhận kho cho phiếu đang vận chuyển, tại chi nhánh đích' USING ERRCODE = '23514';
    END IF;
  ELSIF NEW.movement_type NOT IN ('lost','damaged') THEN
    RAISE EXCEPTION 'Chỉ transfer_out, transfer_in, lost, damaged được gắn phiếu chuyển' USING ERRCODE = '23514';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM stock_transfer_lines
                  WHERE tenant_id = NEW.tenant_id AND transfer_id = NEW.transfer_id AND variant_id = NEW.variant_id) THEN
    RAISE EXCEPTION 'Món không thuộc phiếu chuyển' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_inventory_movements_transfer_check
BEFORE INSERT ON inventory_movements
FOR EACH ROW EXECUTE FUNCTION validate_transfer_movement();

-- Cập nhật branch_stock.quantity_usable theo sổ cái.
-- UPDATE trước, chỉ INSERT khi chưa có dòng: để delta âm với dòng chưa tồn tại vẫn bị CHECK >= 0 chặn.
CREATE FUNCTION apply_inventory_movement() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE branch_stock
     SET quantity_usable = quantity_usable + NEW.delta_usable, updated_at = now()
   WHERE branch_id = NEW.branch_id AND variant_id = NEW.variant_id AND tenant_id = NEW.tenant_id;
  IF NOT FOUND THEN
    INSERT INTO branch_stock (tenant_id, branch_id, variant_id, quantity_usable)
    VALUES (NEW.tenant_id, NEW.branch_id, NEW.variant_id, NEW.delta_usable)
    ON CONFLICT (branch_id, variant_id)
    DO UPDATE SET quantity_usable = branch_stock.quantity_usable + EXCLUDED.quantity_usable, updated_at = now();
  END IF;
  RETURN NULL;
END $$;

CREATE TRIGGER trg_inventory_movements_apply
AFTER INSERT ON inventory_movements
FOR EACH ROW EXECUTE FUNCTION apply_inventory_movement();

-- Khi số lượng dùng được của một chi nhánh đổi, đồng bộ capacity các đêm từ hôm nay của CHÍNH chi nhánh đó.
-- Nếu giảm xuống thấp hơn số đã đặt (kể cả khi xuất kho chuyển đi), CHECK trên inventory_calendar sẽ chặn
-- => buộc xử lý các đơn bị ảnh hưởng trước.
CREATE FUNCTION sync_calendar_capacity() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE inventory_calendar
     SET capacity = NEW.quantity_usable
   WHERE branch_id = NEW.branch_id AND variant_id = NEW.variant_id AND night >= current_date;
  RETURN NULL;
END $$;

CREATE TRIGGER trg_branch_stock_sync_capacity
AFTER UPDATE OF quantity_usable ON branch_stock
FOR EACH ROW WHEN (OLD.quantity_usable IS DISTINCT FROM NEW.quantity_usable)
EXECUTE FUNCTION sync_calendar_capacity();

-- Giữ chỗ các đêm [p_start, p_end) cho p_qty món TRONG KHO CỦA p_branch. Vượt tồn => lỗi 23514.
CREATE FUNCTION reserve_inventory(p_tenant uuid, p_branch uuid, p_variant uuid, p_start date, p_end date, p_qty int)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_usable int;
BEGIN
  IF p_qty <= 0 OR p_end <= p_start THEN
    RAISE EXCEPTION 'Yêu cầu giữ chỗ không hợp lệ' USING ERRCODE = '22023';
  END IF;

  SELECT bs.quantity_usable INTO v_usable
    FROM branch_stock bs
    JOIN item_variants v ON v.tenant_id = bs.tenant_id AND v.id = bs.variant_id
    JOIN branches br     ON br.tenant_id = bs.tenant_id AND br.id = bs.branch_id
   WHERE bs.tenant_id = p_tenant AND bs.branch_id = p_branch AND bs.variant_id = p_variant
     AND v.is_active AND br.status = 'active'
     FOR SHARE OF bs;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Chi nhánh không có món này, đã ngừng cho thuê hoặc đã đóng cửa' USING ERRCODE = '22023';
  END IF;

  INSERT INTO inventory_calendar (tenant_id, branch_id, variant_id, night, capacity, reserved)
  SELECT p_tenant, p_branch, p_variant, d::date, v_usable, p_qty
    FROM generate_series(p_start::timestamp, (p_end - 1)::timestamp, interval '1 day') AS d
  ON CONFLICT (branch_id, variant_id, night)
  DO UPDATE SET reserved = inventory_calendar.reserved + EXCLUDED.reserved;
END $$;

CREATE FUNCTION release_inventory(p_tenant uuid, p_branch uuid, p_variant uuid, p_start date, p_end date, p_qty int)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE inventory_calendar
     SET reserved = reserved - p_qty
   WHERE tenant_id = p_tenant AND branch_id = p_branch AND variant_id = p_variant
     AND night >= p_start AND night < p_end;
END $$;

-- Giữ/nhả toàn bộ hàng của một đơn trong kho của chi nhánh đơn (đã tính đêm đệm).
-- Khóa theo thứ tự variant để tránh deadlock.
CREATE FUNCTION reserve_booking_inventory(p_tenant uuid, p_booking uuid)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT b.branch_id, bi.variant_id, bi.quantity, bi.buffer_nights, b.start_date, b.end_date
      FROM booking_items bi
      JOIN bookings b ON b.tenant_id = bi.tenant_id AND b.id = bi.booking_id
     WHERE bi.tenant_id = p_tenant AND bi.booking_id = p_booking
     ORDER BY bi.variant_id
  LOOP
    PERFORM reserve_inventory(p_tenant, r.branch_id, r.variant_id, r.start_date, r.end_date + r.buffer_nights, r.quantity);
  END LOOP;
END $$;

CREATE FUNCTION release_booking_inventory(p_tenant uuid, p_booking uuid)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT b.branch_id, bi.variant_id, bi.quantity, bi.buffer_nights, b.start_date, b.end_date
      FROM booking_items bi
      JOIN bookings b ON b.tenant_id = bi.tenant_id AND b.id = bi.booking_id
     WHERE bi.tenant_id = p_tenant AND bi.booking_id = p_booking
     ORDER BY bi.variant_id
  LOOP
    PERFORM release_inventory(p_tenant, r.branch_id, r.variant_id, r.start_date, r.end_date + r.buffer_nights, r.quantity);
  END LOOP;
END $$;

-- Job nền (chạy mỗi phút bằng quyền quản trị nền tảng): đơn giữ chỗ quá hạn -> expired, nhả tồn.
CREATE FUNCTION expire_holds() RETURNS int
LANGUAGE plpgsql AS $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN
    SELECT id, tenant_id FROM bookings
     WHERE status = 'hold' AND hold_expires_at < now()
     ORDER BY hold_expires_at
     FOR UPDATE SKIP LOCKED
  LOOP
    PERFORM release_booking_inventory(r.tenant_id, r.id);
    UPDATE bookings SET status = 'expired' WHERE id = r.id;
    INSERT INTO booking_status_history (tenant_id, booking_id, from_status, to_status, reason)
    VALUES (r.tenant_id, r.id, 'hold', 'expired', 'Hết hạn giữ chỗ');
    n := n + 1;
  END LOOP;
  RETURN n;
END $$;

-- Đổi size tại chi nhánh của đơn, trong một giao dịch, CÙNG kho, CÙNG đơn, giữa hai biến thể CÙNG mẫu.
--   * Đơn 'confirmed' (chưa nhận đồ): nhả món cũ và giữ món mới cho toàn kỳ thuê (kể cả đêm đệm).
--   * Đơn 'handed_over' (đang thuê): khách mang món cũ trả lại hôm nay. Món cũ vẫn bị chiếm thêm số đêm đệm
--     (giặt, kiểm tra) rồi mới nhả các đêm còn lại; món mới được giữ từ hôm nay tới hết kỳ (kể cả đêm đệm).
--     Chỉ đổi khi còn ít nhất một đêm thuê. Tình trạng món cũ do nhân viên kiểm tra; hư hỏng ghi theo luồng thường.
-- Gọi hàm này TRƯỚC khi app cập nhật booking_items, rồi app ghi booking_item_swaps trong cùng giao dịch.
-- Hết hàng size mới => lỗi 23514, toàn bộ giao dịch hoàn tác.
CREATE FUNCTION swap_booking_inventory(p_tenant uuid, p_booking uuid, p_from_variant uuid, p_to_variant uuid, p_qty int)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  b bookings%ROWTYPE; v_buffer int; v_have int; v_type_from uuid; v_type_to uuid;
  v_release_from date; v_reserve_from date;
BEGIN
  IF p_qty <= 0 OR p_from_variant = p_to_variant THEN
    RAISE EXCEPTION 'Yêu cầu đổi size không hợp lệ' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO b FROM bookings WHERE tenant_id = p_tenant AND id = p_booking FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Đơn không tồn tại' USING ERRCODE = '22023';
  END IF;
  IF b.status NOT IN ('confirmed','handed_over') THEN
    RAISE EXCEPTION 'Chỉ đổi size khi đơn đã xác nhận hoặc đang thuê' USING ERRCODE = '23514';
  END IF;

  SELECT quantity, buffer_nights INTO v_have, v_buffer
    FROM booking_items
   WHERE tenant_id = p_tenant AND booking_id = p_booking AND variant_id = p_from_variant;
  IF NOT FOUND OR v_have < p_qty THEN
    RAISE EXCEPTION 'Đơn không có đủ số lượng món cần đổi' USING ERRCODE = '22023';
  END IF;

  SELECT item_type_id INTO v_type_from FROM item_variants WHERE tenant_id = p_tenant AND id = p_from_variant;
  SELECT item_type_id INTO v_type_to   FROM item_variants WHERE tenant_id = p_tenant AND id = p_to_variant;
  IF v_type_from IS DISTINCT FROM v_type_to THEN
    RAISE EXCEPTION 'Chỉ đổi giữa các size/màu của cùng một mẫu' USING ERRCODE = '23514';
  END IF;

  IF b.status = 'confirmed' THEN
    v_release_from := b.start_date;
    v_reserve_from := b.start_date;
  ELSE
    IF current_date >= b.end_date THEN
      RAISE EXCEPTION 'Đã hết kỳ thuê, không còn đêm để đổi' USING ERRCODE = '23514';
    END IF;
    v_release_from := greatest(b.start_date, current_date + v_buffer);
    v_reserve_from := greatest(b.start_date, current_date);
  END IF;

  -- Khóa theo thứ tự variant để tránh deadlock với các giao dịch khác
  IF p_from_variant < p_to_variant THEN
    PERFORM release_inventory(p_tenant, b.branch_id, p_from_variant, v_release_from, b.end_date + v_buffer, p_qty);
    PERFORM reserve_inventory(p_tenant, b.branch_id, p_to_variant,   v_reserve_from, b.end_date + v_buffer, p_qty);
  ELSE
    PERFORM reserve_inventory(p_tenant, b.branch_id, p_to_variant,   v_reserve_from, b.end_date + v_buffer, p_qty);
    PERFORM release_inventory(p_tenant, b.branch_id, p_from_variant, v_release_from, b.end_date + v_buffer, p_qty);
  END IF;
END $$;

-- Lịch sử đổi size (chỉ ghi thêm). price_difference = 0 với món có free_size_exchange (quần áo, thời trang);
-- món khác: app tính chênh lệch giá, thu/hoàn tại quầy.
CREATE TABLE booking_item_swaps (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         uuid NOT NULL,
  booking_id        uuid NOT NULL,
  branch_id         uuid NOT NULL,
  from_variant_id   uuid NOT NULL,
  to_variant_id     uuid NOT NULL,
  quantity          int NOT NULL CHECK (quantity > 0),
  price_difference  bigint NOT NULL DEFAULT 0,            -- dương: khách trả thêm; âm: hoàn khách
  reason            text,
  performed_by      uuid NOT NULL REFERENCES users (id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  CHECK (from_variant_id <> to_variant_id),
  FOREIGN KEY (tenant_id, booking_id, branch_id) REFERENCES bookings (tenant_id, id, branch_id),
  FOREIGN KEY (tenant_id, from_variant_id)       REFERENCES item_variants (tenant_id, id),
  FOREIGN KEY (tenant_id, to_variant_id)         REFERENCES item_variants (tenant_id, id)
);
CREATE INDEX booking_item_swaps_booking_idx ON booking_item_swaps (tenant_id, booking_id, created_at);

-- Kiểm tra chi nhánh của đơn: giao tận nơi chỉ khi chi nhánh bật giao và cùng tỉnh/thành với địa chỉ giao;
-- đơn mới phải vào chi nhánh đang hoạt động, và đơn online chỉ vào chi nhánh nhận đơn online.
CREATE FUNCTION validate_booking_delivery() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_branch branches%ROWTYPE;
BEGIN
  SELECT * INTO v_branch FROM branches WHERE tenant_id = NEW.tenant_id AND id = NEW.branch_id;
  IF TG_OP = 'INSERT' THEN
    IF v_branch.status <> 'active' THEN
      RAISE EXCEPTION 'Chi nhánh đã đóng cửa' USING ERRCODE = '23514';
    END IF;
    IF NEW.channel = 'online' AND NOT v_branch.accepts_online THEN
      RAISE EXCEPTION 'Chi nhánh không nhận đơn online' USING ERRCODE = '23514';
    END IF;
  END IF;
  IF NEW.fulfillment = 'delivery' THEN
    IF NOT v_branch.delivery_enabled THEN
      RAISE EXCEPTION 'Chi nhánh không bật giao tận nơi' USING ERRCODE = '23514';
    END IF;
    IF NEW.delivery_province_code IS DISTINCT FROM v_branch.province_code THEN
      RAISE EXCEPTION 'Chỉ giao trong cùng tỉnh/thành phố với chi nhánh' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_bookings_delivery
BEFORE INSERT OR UPDATE OF fulfillment, delivery_province_code, branch_id ON bookings
FOR EACH ROW EXECUTE FUNCTION validate_booking_delivery();

-- Đơn đã giữ chỗ trong kho một chi nhánh thì không được đổi chi nhánh
CREATE FUNCTION forbid_booking_branch_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.branch_id IS DISTINCT FROM OLD.branch_id THEN
    RAISE EXCEPTION 'Không đổi chi nhánh của đơn đã tạo; hủy và đặt lại' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_bookings_branch_immutable
BEFORE UPDATE OF branch_id ON bookings
FOR EACH ROW EXECUTE FUNCTION forbid_booking_branch_change();

-- ---------------------------------------------------------------------
-- 6. Tiền
-- ---------------------------------------------------------------------
CREATE TABLE payments (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL,
  booking_id       uuid NOT NULL,
  kind             text NOT NULL CHECK (kind IN ('rental','deposit','fee')),
  method           text NOT NULL CHECK (method IN ('cash','bank_transfer','card','ewallet')),
  amount           bigint NOT NULL CHECK (amount > 0),
  status           text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','succeeded','failed','cancelled')),
  provider         text,
  provider_txn_id  text,
  idempotency_key  text NOT NULL,
  paid_at          timestamptz,
  created_by       uuid REFERENCES users (id),
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, idempotency_key),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, booking_id) REFERENCES bookings (tenant_id, id)
);
CREATE UNIQUE INDEX payments_provider_txn_key ON payments (provider, provider_txn_id)
  WHERE provider_txn_id IS NOT NULL;

CREATE TABLE deposits (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL,
  booking_id       uuid NOT NULL UNIQUE,
  amount           bigint NOT NULL CHECK (amount >= 0),
  status           text NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','held','released','partially_deducted','forfeited')),
  deducted_amount  bigint NOT NULL DEFAULT 0 CHECK (deducted_amount >= 0),
  decided_by       uuid REFERENCES users (id),
  decided_at       timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CHECK (deducted_amount <= amount),
  FOREIGN KEY (tenant_id, booking_id) REFERENCES bookings (tenant_id, id)
);

CREATE TABLE refunds (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL,
  booking_id   uuid NOT NULL,
  payment_id   uuid,
  amount       bigint NOT NULL CHECK (amount > 0),
  reason       text,
  status       text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','processed','rejected')),
  requested_by uuid REFERENCES users (id),
  approved_by  uuid REFERENCES users (id),
  processed_at timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id, booking_id) REFERENCES bookings (tenant_id, id),
  FOREIGN KEY (tenant_id, payment_id) REFERENCES payments (tenant_id, id)
);

-- Webhook của cổng thanh toán: lưu mọi sự kiện, event_id duy nhất để không xử lý lặp
CREATE TABLE payment_webhook_events (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider     text NOT NULL,
  event_id     text NOT NULL,
  tenant_id    uuid,
  payload      jsonb NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  UNIQUE (provider, event_id)
);

-- ---------------------------------------------------------------------
-- 7. Chăm sóc khách hàng
-- ---------------------------------------------------------------------
CREATE TABLE support_tickets (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           uuid NOT NULL,
  code                text NOT NULL,
  customer_profile_id uuid NOT NULL,
  booking_id          uuid,
  branch_id           uuid,                          -- chi nhánh liên quan (thường lấy từ đơn); NULL = cấp chuỗi
  category            text NOT NULL CHECK (category IN ('question','issue','damage','refund','delivery','other')),
  priority            text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low','normal','high','urgent')),
  status              text NOT NULL DEFAULT 'open' CHECK (status IN ('open','pending_customer','in_progress','resolved','closed')),
  subject             text NOT NULL,
  assigned_to         uuid REFERENCES users (id),
  sla_due_at          timestamptz,
  closed_at           timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, code),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, customer_profile_id) REFERENCES customer_profiles (tenant_id, id),
  FOREIGN KEY (tenant_id, booking_id)          REFERENCES bookings (tenant_id, id),
  FOREIGN KEY (tenant_id, branch_id)           REFERENCES branches (tenant_id, id)
);
CREATE INDEX support_tickets_queue_idx ON support_tickets (tenant_id, status, priority, created_at);

CREATE TABLE ticket_messages (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL,
  ticket_id   uuid NOT NULL,
  sender_id   uuid NOT NULL REFERENCES users (id),
  body        text NOT NULL,
  is_internal boolean NOT NULL DEFAULT false,   -- ghi chú nội bộ: khách không thấy
  file_ids    uuid[] NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id, ticket_id) REFERENCES support_tickets (tenant_id, id) ON DELETE CASCADE
);
CREATE INDEX ticket_messages_idx ON ticket_messages (ticket_id, created_at);

CREATE TABLE damage_claims (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL,
  booking_id       uuid NOT NULL,
  booking_item_id  uuid NOT NULL,
  quantity         int NOT NULL CHECK (quantity > 0),
  description      text NOT NULL,
  claimed_amount   bigint NOT NULL CHECK (claimed_amount >= 0),
  status           text NOT NULL DEFAULT 'open' CHECK (status IN ('open','accepted','disputed','resolved','waived')),
  resolved_amount  bigint CHECK (resolved_amount >= 0),
  resolved_by      uuid REFERENCES users (id),
  resolved_at      timestamptz,
  created_by       uuid REFERENCES users (id),
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id, booking_id)      REFERENCES bookings (tenant_id, id),
  FOREIGN KEY (tenant_id, booking_item_id) REFERENCES booking_items (tenant_id, id)
);

-- ---------------------------------------------------------------------
-- 8. Hệ thống
-- ---------------------------------------------------------------------
CREATE TABLE notifications (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid NOT NULL REFERENCES tenants (id),
  user_id    uuid NOT NULL REFERENCES users (id),
  type       text NOT NULL,
  title      text NOT NULL,
  body       text,
  data       jsonb NOT NULL DEFAULT '{}',
  read_at    timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user_idx ON notifications (user_id, created_at DESC);

CREATE TABLE device_tokens (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  platform   text NOT NULL CHECK (platform IN ('ios','android','web')),
  token      text NOT NULL UNIQUE,
  last_seen_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id   uuid,
  actor_id    uuid,
  action      text NOT NULL,
  entity_type text NOT NULL,
  entity_id   uuid,
  before      jsonb,
  after       jsonb,
  ip          inet,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_logs_entity_idx ON audit_logs (tenant_id, entity_type, entity_id, created_at DESC);

-- Bảng chỉ ghi thêm
CREATE TRIGGER trg_booking_status_history_append_only
  BEFORE UPDATE OR DELETE ON booking_status_history
  FOR EACH ROW EXECUTE FUNCTION forbid_modification();
CREATE TRIGGER trg_inventory_movements_append_only
  BEFORE UPDATE OR DELETE ON inventory_movements
  FOR EACH ROW EXECUTE FUNCTION forbid_modification();
CREATE TRIGGER trg_booking_item_swaps_append_only
  BEFORE UPDATE OR DELETE ON booking_item_swaps
  FOR EACH ROW EXECUTE FUNCTION forbid_modification();
CREATE TRIGGER trg_audit_logs_append_only
  BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION forbid_modification();

-- ---------------------------------------------------------------------
-- 9. Tự gắn trigger updated_at cho mọi bảng có cột updated_at
-- ---------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOR t IN
    SELECT c.table_name
      FROM information_schema.columns c
      JOIN information_schema.tables tb
        ON tb.table_schema = c.table_schema AND tb.table_name = c.table_name AND tb.table_type = 'BASE TABLE'
     WHERE c.table_schema = 'public' AND c.column_name = 'updated_at'
  LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%1$s_updated_at BEFORE UPDATE ON %1$I FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t);
  END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 9b. Đóng chi nhánh: chặn khi còn việc dang dở (ADR 0009)
-- Lỗi 23514, MESSAGE là mã để API ánh xạ và liệt kê việc còn lại.
-- ---------------------------------------------------------------------
CREATE FUNCTION forbid_closing_branch_in_use() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'closed' AND OLD.status <> 'closed' THEN
    IF EXISTS (SELECT 1 FROM bookings
                WHERE tenant_id = NEW.tenant_id AND branch_id = NEW.id
                  AND status IN ('hold','confirmed','handed_over','returned')) THEN
      RAISE EXCEPTION 'BRANCH_HAS_OPEN_BOOKINGS' USING ERRCODE = '23514';
    END IF;
    IF EXISTS (SELECT 1 FROM branch_stock
                WHERE tenant_id = NEW.tenant_id AND branch_id = NEW.id AND quantity_usable > 0) THEN
      RAISE EXCEPTION 'BRANCH_HAS_STOCK' USING ERRCODE = '23514';
    END IF;
    IF EXISTS (SELECT 1 FROM stock_transfers
                WHERE tenant_id = NEW.tenant_id
                  AND (from_branch_id = NEW.id OR to_branch_id = NEW.id)
                  AND status IN ('requested','approved','in_transit')) THEN
      RAISE EXCEPTION 'BRANCH_HAS_OPEN_TRANSFERS' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_branches_forbid_close_in_use
  BEFORE UPDATE OF status ON branches
  FOR EACH ROW EXECUTE FUNCTION forbid_closing_branch_in_use();

-- ---------------------------------------------------------------------
-- 10. Row Level Security: mỗi cửa hàng chỉ thấy dữ liệu của mình
-- ---------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOR t IN
    SELECT c.table_name
      FROM information_schema.columns c
      JOIN information_schema.tables tb
        ON tb.table_schema = c.table_schema AND tb.table_name = c.table_name AND tb.table_type = 'BASE TABLE'
     WHERE c.table_schema = 'public' AND c.column_name = 'tenant_id'
       AND c.table_name NOT IN ('payment_webhook_events')
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON %I
         USING (is_platform_admin() OR tenant_id = current_tenant_id())
         WITH CHECK (is_platform_admin() OR tenant_id = current_tenant_id())', t);
  END LOOP;
END $$;

-- tenants: ai cũng đọc được cửa hàng đang hoạt động (trang công khai), chỉ ghi được cửa hàng của mình
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants FORCE ROW LEVEL SECURITY;
CREATE POLICY tenants_read ON tenants FOR SELECT
  USING (status = 'active' OR is_platform_admin() OR id = current_tenant_id());
CREATE POLICY tenants_write ON tenants FOR ALL
  USING (is_platform_admin() OR id = current_tenant_id())
  WITH CHECK (is_platform_admin() OR id = current_tenant_id());

-- branches: chi nhánh đang hoạt động hiển thị công khai (địa chỉ, giờ mở cửa) cho trang web chung.
-- Chính sách tenant_isolation (tạo ở vòng lặp trên) vẫn lo phần ghi và đọc chi nhánh đã đóng.
CREATE POLICY branches_public_read ON branches FOR SELECT
  USING (status = 'active');

-- holidays: bảng dùng chung, không có tenant_id nên vòng lặp trên không áp. Mọi người đọc, chỉ super admin ghi.
ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE holidays FORCE ROW LEVEL SECURITY;
CREATE POLICY holidays_read ON holidays FOR SELECT USING (true);
CREATE POLICY holidays_write ON holidays FOR ALL
  USING (is_platform_admin()) WITH CHECK (is_platform_admin());

COMMIT;

-- migrate:down
-- Không lùi migration: thay đổi bằng migration mới (quy tắc 4).
