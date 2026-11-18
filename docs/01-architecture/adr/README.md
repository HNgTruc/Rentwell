# adr/

Architecture Decision Records: mỗi quyết định kiến trúc một file.

## Bên trong

| Mục | Mô tả |
|---|---|
| `0000-template.md` | Mẫu ADR. |
| `0001-multi-tenant-rls.md` | Đa tenant bằng RLS. |
| `0002-monorepo.md` | Chọn monorepo. |
| `0003-modular-monolith.md` | Modular monolith. |
| `0004-sql-first-migrations.md` | Migration SQL-first, công cụ dbmate (đã chốt); Kysely + RLS chờ spike. |
| `0005-one-shared-website.md` | Một website chung cho mọi cửa hàng, URL theo đường dẫn. |
| `0006-chain-branches.md` | Chuỗi nhiều chi nhánh; gán đơn theo vị trí khách; trả đúng chi nhánh. |
| `0007-mcp-server.md` | Máy chủ MCP riêng của Rentwell (loại B), chỉ đọc, làm sau MVP. |
| `0008-pricing-tiers-deposit.md` | Giảm bậc theo dòng, giá mùa trước giảm bậc, cọc % trên giá trị thay thế. |
| `0009-business-rules-batch-2026-11-17.md` | 14 quy tắc nghiệp vụ chốt trước P0: mô hình tiền, hồ sơ khách, hạn giữ chỗ, cọc, hoàn tiền, làm tròn, phí trễ, ngày lễ, gia hạn, đơn tại quầy, đóng chi nhánh, xác minh, giờ mở cửa. |
| `0010-pnpm-without-turborepo.md` | Giữ cấu hình trong `workspace/`, bỏ Turborepo, dùng `pnpm -r`; mỗi package tự khai báo công cụ; TypeScript ghim 6.0. |
| `0011-gsap-animation.md` | GSAP làm thư viện animation cho web và admin, kèm bộ skill `gsap-*`; không dùng cho mobile. |
| `0012-kysely-rls-with-tenant.md` | Kysely giữ nguyên; truy vấn nghiệp vụ qua `withTenant` (`set_config` cấp giao dịch); spike chứng minh không rò tenant qua pool. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
