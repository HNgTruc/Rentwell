---
name: rls-isolation-test
description: Viết kiểm thử chứng minh cô lập dữ liệu giữa các cửa hàng (RLS) cho bảng hoặc endpoint mới. Dùng sau khi thêm bảng, sửa chính sách RLS hoặc thêm endpoint truy cập dữ liệu tenant.
---

# Kiểm thử cô lập tenant (RLS)

Mục tiêu: **chứng minh được** cửa hàng B không đọc, ghi, xóa được dữ liệu cửa hàng A. Đây là bộ kiểm thử không thương lượng (xem `docs/07-quality/testing-strategy.md`).

## Cơ chế của dự án

- Chính sách dùng `current_setting('app.tenant_id', true)` và `app.is_super_admin`; mỗi request chạy `SET LOCAL app.tenant_id = '<uuid>'` trong giao dịch.
- **Phải kết nối bằng role ứng dụng** (không superuser, không owner bảng). Superuser và owner bỏ qua RLS, khiến kiểm thử xanh giả.

## Các ca bắt buộc cho mỗi bảng nghiệp vụ

1. **Đọc chéo:** đặt tenant B, `SELECT` bảng → không thấy dòng của A.
2. **Ghi chéo:** đặt tenant B, `UPDATE`/`DELETE` dòng của A → 0 dòng bị ảnh hưởng.
3. **Chèn sai tenant:** đặt tenant B, `INSERT` với `tenant_id = A` → bị từ chối.
4. **Không đặt tenant:** không `SET LOCAL` → thấy 0 dòng, không lỗi rò rỉ.
5. **Khóa ngoại chéo:** tham chiếu bản ghi của A từ bản ghi của B → bị khóa ngoại ghép chặn.
6. **Super admin:** `app.is_super_admin = 'true'` → đọc được theo thiết kế (nếu bảng cho phép).
7. **Biến không rò sang request sau:** hai giao dịch liên tiếp trên cùng kết nối, tenant khác nhau → giao dịch sau không thấy dữ liệu tenant trước (kiểm `SET LOCAL`, không phải `SET`).

## Ca bổ sung cho endpoint

- Đổi ID sang tài nguyên của tenant khác → 404 (không lộ sự tồn tại).
- Token của B gọi endpoint với dữ liệu của A → 403 hoặc 404.
- Gửi `tenant_id` trong body → bị bỏ qua, không ảnh hưởng.

## Mẫu (Vitest + Postgres thật)

```ts
describe('RLS: <bảng>', () => {
  it('tenant B không đọc được dòng của tenant A', async () => {
    const rowsB = await withTenant(db, tenantB, (tx) =>
      tx.selectFrom('<bảng>').selectAll().execute(),
    );
    expect(rowsB.find((r) => r.tenant_id === tenantA)).toBeUndefined();
  });

  it('không đặt tenant thì thấy 0 dòng', async () => {
    const rows = await withoutTenant(db, (tx) =>
      tx.selectFrom('<bảng>').selectAll().execute(),
    );
    expect(rows).toHaveLength(0);
  });
});
```

`withTenant`/`withoutTenant` là helper giao dịch kiểm thử (mở giao dịch, `SET LOCAL`, chạy, rollback). Tên có thể khác khi cài đặt.

## Kiểm tra trước khi xong

- [ ] Kết nối kiểm thử dùng role ứng dụng (xác nhận bằng `SELECT current_user, rolsuper`)
- [ ] Mỗi bảng mới có đủ ca 1 đến 5
- [ ] Kiểm thử chạy trong CI trên Postgres thật
- [ ] Cố ý làm hỏng chính sách một lần để chắc kiểm thử thật sự đỏ (kiểm thử không bắt được lỗi thì vô dụng)
