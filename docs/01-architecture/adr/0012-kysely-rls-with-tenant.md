# ADR 0012: Kysely + RLS, ngữ cảnh tenant đặt bằng `withTenant`

**Trạng thái:** Chấp nhận (2026-11-19, spike P0) · **Người quyết:** chủ dự án (đồng ý làm spike), Claude đề xuất

## Bối cảnh

`tech-stack.md` để Kysely ở 🟡: cần chứng minh mỗi request chạy trong giao dịch có `app.tenant_id` và các chuỗi không thấy dữ liệu của nhau (CLAUDE.md quy tắc 2, ADR 0001). Rủi ro chính khi dùng pool kết nối là ngữ cảnh tenant của request trước **rò** sang request sau dùng lại cùng kết nối.

## Quyết định

1. Giữ **Kysely** làm lớp truy cập DB.
2. Mọi truy vấn nghiệp vụ đi qua `withTenant(db, tenantId, fn)` (`apps/api/src/database/tenant-context.ts`):
   - kiểm `tenantId` là UUID trước khi chạm CSDL;
   - mở giao dịch Kysely, chạy `select set_config('app.tenant_id', $1, true)`, rồi chạy `fn(trx)`.
3. Dùng `set_config(..., true)` thay `SET LOCAL`: cùng phạm vi giao dịch (tự mất khi COMMIT/ROLLBACK), nhưng nhận tham số nên không phải nối chuỗi SQL.
4. `tenantId` lấy từ token và membership ở phía server, không bao giờ từ client. Phần nối với guard/request làm ở P1.

## Kết quả spike (2026-11-19, PostgreSQL 16 dev, role `rentwell_app`)

`apps/api/test/rls-isolation.spec.ts`, 8/8 ca đạt:

- role ứng dụng không superuser, không BYPASSRLS;
- không có ngữ cảnh tenant: 0 dòng;
- có ngữ cảnh: chỉ thấy dòng của đúng tenant;
- **không rò** sang giao dịch sau trên cùng kết nối (pool 1 kết nối), kể cả khi giao dịch lỗi và rollback;
- 20 giao dịch song song xen kẽ hai tenant không lẫn dữ liệu;
- chèn dòng của tenant khác bị chặn (`42501`, WITH CHECK); sửa dòng tenant khác bị lọc (0 dòng).

## Hệ quả

- Kiểm thử chạy khi có biến `RLS_TEST_DATABASE_URL`, không có thì bỏ qua. CI job `database` chạy nó sau migrate và seed.
- **Còn mở:**
  - `testing.md` yêu cầu Testcontainers. Spike dùng Postgres của Docker Compose dev và CI. Thêm Testcontainers là thêm thư viện, cần chủ dự án duyệt (trước P1).
  - Kiểu sinh tự động (`kysely-codegen`) chưa thêm, `Database` vẫn là `Kysely<any>`. Cần duyệt trước P1.
  - Ngữ cảnh super admin (`app.is_super_admin`) chưa có hàm riêng, làm ở P1 cùng phân quyền.

## Phương án đã cân nhắc

- `SET LOCAL app.tenant_id = '...'` nối chuỗi: không tham số hóa được, dễ lỗi chèn SQL.
- `SET` cấp phiên rồi `RESET` khi trả kết nối: rò nếu quên reset hoặc lỗi giữa chừng.
- Drizzle, Prisma: khó kiểm soát giao dịch và `SET LOCAL` hơn (xem `tech-stack.md`).
