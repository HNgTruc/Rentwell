# Đề xuất lược đồ 002: đánh giá, bộ phận hỗ trợ, định tuyến phiếu

**Trạng thái:** Hướng thiết kế **đã được duyệt (2026-11-15)**; **chưa áp dụng**, chưa có file migration. Chưa có file migration; sau khi duyệt mới tạo `db/migrations/002_reviews_departments.sql` từ bản nháp dưới đây.
Liên quan: `../04-product/support-reviews-chat.md`. Nguyên tắc: không sửa `001_init.sql`; thay đổi bằng migration mới, kèm kiểm thử RLS.

## 1. Thay đổi

| Hạng mục | Thay đổi |
|---|---|
| `departments` | Bảng mới: bộ phận hỗ trợ của từng cửa hàng |
| `department_members` | Bảng mới: nhân viên thuộc bộ phận nào |
| `ticket_routing_rules` | Bảng mới: loại phiếu → bộ phận |
| `support_tickets` | Thêm `department_id`, `item_type_id`; thêm loại `feedback` vào `category` |
| `ticket_department_history` | Bảng mới: lịch sử chuyển bộ phận (chỉ thêm) |
| `reviews` | Bảng mới: đánh giá |
| `public_reviews` | View đọc công khai, chỉ cột an toàn |

Chat dùng lại `support_tickets` và `ticket_messages`, **không thêm bảng chat**.

## 2. Bản nháp SQL (chưa chạy, cần rà soát)

```sql
-- Bộ phận hỗ trợ của cửa hàng
CREATE TABLE departments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid NOT NULL REFERENCES tenants (id),
  code       text NOT NULL,                  -- vd: advice, delivery, damage, billing
  name       text NOT NULL,
  is_active  boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, code),
  UNIQUE (tenant_id, id)
);

CREATE TABLE department_members (
  tenant_id     uuid NOT NULL,
  department_id uuid NOT NULL,
  user_id       uuid NOT NULL REFERENCES users (id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (department_id, user_id),
  FOREIGN KEY (tenant_id, department_id) REFERENCES departments (tenant_id, id) ON DELETE CASCADE
);

-- Quy tắc loại phiếu -> bộ phận
CREATE TABLE ticket_routing_rules (
  tenant_id     uuid NOT NULL,
  category      text NOT NULL CHECK (category IN ('question','issue','damage','refund','delivery','feedback','other')),
  department_id uuid NOT NULL,
  PRIMARY KEY (tenant_id, category),
  FOREIGN KEY (tenant_id, department_id) REFERENCES departments (tenant_id, id)
);

-- Phiếu hỗ trợ: thêm bộ phận, món liên quan, loại 'feedback'
ALTER TABLE support_tickets
  ADD COLUMN department_id uuid,
  ADD COLUMN item_type_id  uuid,
  ADD FOREIGN KEY (tenant_id, department_id) REFERENCES departments (tenant_id, id),
  ADD FOREIGN KEY (tenant_id, item_type_id)  REFERENCES item_types (tenant_id, id);
-- Thay ràng buộc CHECK của category để thêm 'feedback' (tên ràng buộc lấy từ \d support_tickets khi viết migration thật)

CREATE INDEX support_tickets_dept_queue_idx
  ON support_tickets (tenant_id, department_id, status, priority, created_at);

CREATE TABLE ticket_department_history (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid NOT NULL,
  ticket_id  uuid NOT NULL,
  from_department_id uuid,
  to_department_id   uuid NOT NULL,
  changed_by uuid NOT NULL REFERENCES users (id),
  reason     text,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id, ticket_id) REFERENCES support_tickets (tenant_id, id) ON DELETE CASCADE
);

-- Đánh giá: mỗi dòng đơn một đánh giá, chỉ khi đơn đã hoàn tất (kiểm tra ở API và trigger)
CREATE TABLE reviews (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           uuid NOT NULL,
  booking_item_id     uuid NOT NULL,
  item_type_id        uuid NOT NULL,
  customer_profile_id uuid NOT NULL,
  rating              smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title               text,
  body                text,
  file_ids            uuid[] NOT NULL DEFAULT '{}',
  status              text NOT NULL DEFAULT 'published' CHECK (status IN ('published','hidden')),
  hidden_reason       text,
  hidden_by           uuid REFERENCES users (id),
  shop_reply          text,
  shop_replied_at     timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  UNIQUE (tenant_id, booking_item_id),
  FOREIGN KEY (tenant_id, booking_item_id)     REFERENCES booking_items (tenant_id, id),
  FOREIGN KEY (tenant_id, item_type_id)        REFERENCES item_types (tenant_id, id),
  FOREIGN KEY (tenant_id, customer_profile_id) REFERENCES customer_profiles (tenant_id, id)
);
CREATE INDEX reviews_item_idx ON reviews (tenant_id, item_type_id, status, created_at DESC);
```

## 3. RLS và đọc công khai (điểm cần cẩn thận)

- Các bảng mới đều bật RLS với chính sách `tenant_isolation` giống `001_init.sql` (vòng lặp bật RLS hiện có cần thêm tên bảng vào danh sách).
- **Đánh giá công khai cho người ngoài cửa hàng** mâu thuẫn với RLS theo tenant. Cách đề xuất: **không mở bảng `reviews`**; tạo view `public_reviews` chỉ gồm các cột an toàn (món, số sao, nhận xét, ảnh, tên hiển thị rút gọn, thời gian, phản hồi của cửa hàng) và chỉ dòng `status = 'published'`, rồi cấp quyền đọc view cho role ứng dụng. View chạy với quyền của chủ view nên bỏ qua RLS có kiểm soát; cần kiểm thử để chắc **không lộ cột nào khác** và **không lộ dòng đã ẩn**.
- Tên hiển thị rút gọn (ví dụ "Trúc N.") lấy từ hồ sơ khách; khách được chọn ẩn danh.
- Phạm vi xem đã chốt: **cả nền tảng và công khai, kể cả người chưa đăng nhập**. View `public_reviews` được cấp quyền đọc cho cả đường truy cập không đăng nhập; vì vậy danh sách cột phải tối thiểu và có kiểm thử chặn lộ cột.

## 4. Quy tắc nghiệp vụ ép ở cơ sở dữ liệu hoặc API

- Chỉ tạo `reviews` khi đơn chứa `booking_item_id` ở trạng thái `completed` và `customer_profile_id` đúng chủ đơn (trigger hoặc kiểm tra trong giao dịch tạo).
- Mỗi dòng đơn một đánh giá (`UNIQUE (tenant_id, booking_item_id)`).
- Ẩn đánh giá cần quyền manager trở lên và ghi `audit_logs`; không xóa.
- Đổi bộ phận của phiếu ghi một dòng vào `ticket_department_history`.
- Nhân viên chỉ thấy phiếu của bộ phận mình: kiểm tra ở API bằng `department_members` (RLS vẫn chỉ cô lập theo tenant).

## 5. Kiểm thử cần có khi làm thật

- Cô lập tenant cho từng bảng mới (skill `rls-isolation-test`).
- View `public_reviews`: không lộ cột ngoài danh sách, không lộ đánh giá ẩn, không lộ dữ liệu giữa tenant ngoài phạm vi cho phép.
- Chỉ đơn hoàn tất mới đánh giá được; một dòng đơn một đánh giá; khách khác không đánh giá thay.
- Định tuyến: loại phiếu vào đúng bộ phận; chuyển bộ phận ghi lịch sử; nhân viên bộ phận khác không thấy phiếu.

## 6. Đã duyệt và điều kiện khi làm thật

- [x] Hướng chung ở mục 1; chat dùng lại phiếu, không thêm bảng chat.
- [x] Đọc công khai bằng view `public_reviews`, **cho cả người chưa đăng nhập, trên toàn nền tảng** (mọi cửa hàng dùng chung một website).
- [x] Cửa hàng trả lời đánh giá công khai (cột `shop_reply`).
- [x] Bộ phận mặc định như `../04-product/support-reviews-chat.md` mục 3.
- [ ] Khi tới P6: viết `db/migrations/002_...sql` từ bản nháp, kiểm tra trên Postgres thật, kèm kiểm thử RLS và kiểm thử view; trình bạn xem trước khi áp.
- [ ] Vì xem công khai không cần đăng nhập: giới hạn tần suất cho điểm cuối đọc, phân trang theo con trỏ, chỉ trả cột trong view; cân nhắc bộ nhớ đệm.
