# ERD: Rentwell

**Trạng thái:** Đã duyệt (P1) · **Cập nhật lần cuối:** 2026-11-15

SQL đi kèm: `schema-001-init.sql` (PostgreSQL 15+, đã chạy thử trên 16: 49 bảng, 2026-11-17). Sơ đồ Mermaid chỉ hiển thị cột chính.

## Quyết định đã chốt
1. **Mọi món đều theo số lượng.** Không theo dõi từng chiếc. Giày hay bông tai là 1 món. Tồn kho tính theo **biến thể (SKU)**; món không có size/màu vẫn có 1 biến thể "Mặc định".
2. **Tính theo đêm.** Nhận 10, trả 12 = 2 đêm. Khoảng thuê là `[ngày nhận, ngày trả)`.
3. **Giao hàng:** mỗi cửa hàng tự đặt cách tính phí (cố định, theo km, hoặc theo bậc khoảng cách) và bán kính tối đa. Chỉ giao trong cùng tỉnh/thành của cửa hàng.

## Sơ đồ 1: cửa hàng, tài khoản, danh mục, tồn kho

```mermaid
erDiagram
  tenants ||--o{ memberships : "nhân sự và khách"
  users ||--o{ memberships : ""
  tenants ||--o{ customer_profiles : ""
  users ||--o{ customer_profiles : ""
  customer_profiles ||--o{ verification_documents : ""
  tenants ||--o| delivery_fee_rules : "phí giao do cửa hàng đặt"
  tenants ||--o{ delivery_fee_tiers : ""
  tenants ||--o| late_fee_rules : ""
  tenants ||--o{ cancellation_policies : ""

  tenants ||--o{ categories : ""
  categories ||--o{ item_types : ""
  brands ||--o{ item_types : ""
  item_types ||--o{ item_variants : "SKU: size, màu"
  item_types ||--o{ price_tiers : "giảm theo số đêm"
  item_types ||--o{ seasonal_prices : "giá mùa"
  item_types ||--o{ item_type_images : ""

  item_variants ||--o{ inventory_lots : "nguồn gốc lô"
  suppliers ||--o{ inventory_lots : ""
  item_variants ||--o{ inventory_movements : "sổ cái kho"
  item_variants ||--o{ inventory_calendar : "tồn theo đêm"
  tenants ||--o{ branches : "chi nhánh"
  branches ||--o{ branch_stock : "kho riêng"
  item_variants ||--o{ branch_stock : ""
  branches ||--o{ bookings : "đơn thuộc 1 chi nhánh"
  branches ||--o{ stock_transfers : "chuyển hàng"
  bookings ||--o{ booking_item_swaps : "đổi size"

  tenants {
    uuid id PK
    text slug "chuỗi cửa hàng"
  }
  branches {
    uuid id PK
    text slug
    text province_code "phạm vi giao hàng"
    time return_time
    bool delivery_enabled
    bool accepts_online
  }
  branch_stock {
    uuid branch_id PK
    uuid variant_id PK
    int quantity_usable "chỉ đổi qua sổ cái"
  }
  item_types {
    uuid id PK
    text name
    text country_of_origin "nơi sản xuất"
    bigint base_price_per_night
    int buffer_nights
  }
  item_variants {
    uuid id PK
    text sku
    text name
    bigint replacement_value
  }
  inventory_lots {
    uuid id PK
    date manufacture_date "ngày sản xuất"
    text manufacture_place "nơi sản xuất"
    date purchase_date
    int quantity_received
  }
  inventory_calendar {
    uuid variant_id PK
    date night PK
    int capacity
    int reserved "CHECK reserved <= capacity"
  }
  inventory_movements {
    uuid id PK
    text movement_type
    int quantity
    int delta_usable
  }
```

## Sơ đồ 2: đơn thuê, tiền, chăm sóc khách hàng

```mermaid
erDiagram
  customer_profiles ||--o{ bookings : ""
  bookings ||--|{ booking_items : ""
  item_variants ||--o{ booking_items : ""
  bookings ||--o{ booking_status_history : "chỉ ghi thêm"
  bookings ||--o| rental_contracts : ""
  bookings ||--o{ handovers : "giao và trả"
  handovers ||--o{ handover_lines : ""
  booking_items ||--o{ handover_lines : ""
  handovers ||--o{ handover_photos : ""
  bookings ||--o{ extensions : "gia hạn"
  bookings ||--o{ fees : "trễ, hư, mất, giao"
  bookings ||--o{ payments : ""
  bookings ||--o| deposits : ""
  payments ||--o{ refunds : ""
  bookings ||--o{ support_tickets : ""
  support_tickets ||--o{ ticket_messages : ""
  bookings ||--o{ damage_claims : ""
  booking_items ||--o{ damage_claims : ""
  bookings ||--o{ inventory_movements : "hư/mất phát sinh từ đơn"

  bookings {
    uuid id PK
    text code
    text status
    date start_date "ngày nhận"
    date end_date "ngày trả"
    int nights "end_date - start_date"
    text fulfillment "pickup | delivery"
    text delivery_province_code "phải trùng tỉnh cửa hàng"
    numeric delivery_distance_km
    bigint delivery_fee
    timestamptz hold_expires_at
  }
  booking_items {
    uuid id PK
    int quantity
    bigint price_per_night "đã gồm giảm bậc/mùa"
    int buffer_nights "snapshot"
  }
  handover_lines {
    uuid id PK
    int quantity_ok
    int quantity_damaged
    int quantity_missing
  }
  payments {
    uuid id PK
    text kind "rental | deposit | fee"
    bigint amount
    text idempotency_key
  }
```

## Luồng chính ở mức SQL
1. Tạo `bookings` (status = hold, có `hold_expires_at`) và `booking_items`.
2. Gọi `reserve_booking_inventory(tenant, booking)`: giữ chỗ các đêm `[start, end + đêm đệm)`. Hết hàng thì DB báo lỗi **23514** (ràng buộc `inventory_not_oversold`); app đổi thành "hết hàng ngày này".
3. Thanh toán cọc thành công thì `confirmed`. Không kịp thì job gọi `expire_holds()` mỗi phút để nhả tồn.
4. Hủy đơn: `release_booking_inventory(tenant, booking)`.
5. Giao đồ: `handovers(kind='handover')`. Trả đồ: `handovers(kind='return')` với `handover_lines` ghi số lượng tốt, hư, mất.
6. Nhân viên kho ghi hư/mất vào `inventory_movements`; `branch_stock.quantity_usable` và lịch tồn của chi nhánh tự cập nhật. Giảm xuống thấp hơn số đã đặt ở các đêm tương lai thì DB chặn, buộc xử lý các đơn bị ảnh hưởng trước.
7. Giao tận nơi: app tính khoảng cách và phí theo `delivery_fee_rules`; DB chặn nếu khác tỉnh hoặc cửa hàng chưa bật giao hàng (lỗi 23514).

## Đã kiểm thử trên PostgreSQL 16
- Nhập kho cộng đúng; thuê 10→12 ra 2 đêm.
- Đặt vượt số lượng bị từ chối; đặt vừa đủ được chấp nhận.
- Hai phiên đặt cùng lúc 2/3 đôi cho cùng đêm: phiên sau chờ, rồi bị từ chối, không đặt lố.
- `expire_holds()` nhả đúng tồn.
- Giảm số lượng dưới số đã đặt bị chặn.
- Giao khác tỉnh bị chặn; cùng tỉnh được.
- Sổ cái kho không sửa/xóa được.
- Cửa hàng B không đọc/ghi được dữ liệu cửa hàng A (RLS); tham chiếu chéo bị khóa ngoại chặn.

## Giới hạn cần biết
- Role kết nối của app phải là role thường (không superuser, không owner), mỗi request phải `SET LOCAL app.tenant_id`.
- Khoảng giá mùa chồng nhau cho cùng món chưa bị DB chặn: app kiểm tra (hoặc thêm `btree_gist` sau).
- Tổng `quantity_ok + damaged + missing` khi trả phải bằng số đã thuê: app kiểm tra.
- Mỗi loại món phải có ít nhất một biến thể: app tạo "Mặc định" khi tạo loại món.
- Lịch tồn dùng `current_date`: đặt timezone DB là `Asia/Ho_Chi_Minh`.
- `price_per_night` lưu đã gồm giảm bậc/mùa; công thức tính giá nằm ở tầng app và cần test riêng.
