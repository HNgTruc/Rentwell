# ADR-0004: Migration SQL thuần, truy vấn có kiểu bằng query builder

- **Trạng thái:** Đề xuất (xác nhận sau spike ở P0)
- **Ngày:** 2026-11-15

## Bối cảnh
Lược đồ có RLS, trigger cấm sửa, hàm giữ chỗ tồn kho, ràng buộc `CHECK`. Đây là logic mà ORM thường không biểu diễn được hoặc làm mờ đi.

## Các phương án
1. **Prisma:** tiện, nhưng RLS và `SET LOCAL` theo giao dịch cần bọc thủ công; schema DSL không biểu diễn trigger/hàm.
2. **Drizzle:** gần SQL hơn; vẫn cần SQL thuần cho trigger và RLS.
3. **SQL thuần cho migration + Kysely cho truy vấn có kiểu (kysely-codegen sinh kiểu từ DB).**

## Quyết định
Chọn phương án 3: **SQL là nguồn sự thật**, kiểu TypeScript sinh ngược từ CSDL. Công cụ chạy migration: dbmate hoặc node-pg-migrate (chốt sau spike).

## Hệ quả
- Không có ORM tự sinh migration; viết SQL tay (đã có `schema-001-init.sql`).
- Phải chạy lại codegen sau mỗi migration; CI kiểm tra kiểu sinh ra không lệch.
- Truy vấn phức tạp (giữ chỗ tồn kho) gọi hàm DB, không lặp logic ở tầng ứng dụng.
- Điều kiện bỏ phương án: nếu spike cho thấy RLS với Kysely không đặt biến tenant ổn định theo giao dịch.
