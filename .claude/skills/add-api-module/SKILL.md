---
name: add-api-module
description: Tạo module NestJS mới trong apps/api đúng cấu trúc Rentwell (controller, service, repository, DTO, guard, kiểm thử). Dùng khi thêm một nhóm nghiệp vụ hoặc endpoint mới.
---

# Thêm module API

Dùng khi thêm module trong `apps/api/src/modules/<tên>/`. Quy ước đầy đủ: `docs/01-architecture/monorepo-structure.md`, `docs/03-api/api-conventions.md`, `.claude/rules/api.md`.

## Các bước

1. **Xác định ranh giới.** Module sở hữu bảng nào? Module khác chỉ gọi qua service công khai của nó, không đọc bảng của nó.
2. **Tạo cấu trúc:**
   ```
   modules/<tên>/
   ├── <tên>.module.ts
   ├── <tên>.controller.ts       # mỏng: kiểm tra đầu vào, gọi service
   ├── <tên>.service.ts          # nghiệp vụ
   ├── <tên>.repository.ts       # nơi DUY NHẤT viết SQL
   ├── dto/                      # Zod schema (dùng lại từ packages/shared nếu có)
   └── <tên>.service.spec.ts
   ```
3. **Đầu vào:** schema Zod đặt ở `packages/shared` nếu web/mobile cũng dùng.
4. **Phân quyền:** gắn guard theo `memberships`, đối chiếu `docs/04-product/roles-permissions.md`. Thêm kiểm tra quyền sở hữu nếu truy cập theo ID.
5. **Repository:** mọi truy vấn trong giao dịch đã `SET LOCAL app.tenant_id` (dùng helper giao dịch của `database/`). Truy vấn tham số hóa.
6. **Lỗi:** ném lỗi nghiệp vụ có `code` ổn định; ánh xạ `23514` sang `OUT_OF_STOCK` hoặc `OUT_OF_DELIVERY_AREA` khi liên quan.
7. **Ghi tiền/tồn kho:** bắt buộc `Idempotency-Key`.
8. **Nhạy cảm:** ghi `audit_logs` (đổi vai trò, hoàn tiền, điều chỉnh kho).
9. **OpenAPI:** gắn decorator mô tả để client sinh đúng.
10. **Kiểm thử:** đơn vị cho service; tích hợp cho endpoint (Postgres thật); ca cho phép và từ chối cho từng vai trò; ca tenant khác.
11. **Tài liệu:** cập nhật nhóm endpoint trong `api-conventions.md` nếu có nhóm mới.

## Kiểm tra trước khi xong

- [ ] Không có SQL ngoài repository
- [ ] Không đọc `tenant_id` từ body hoặc query
- [ ] Mỗi endpoint có guard và kiểm thử từ chối
- [ ] `pnpm lint && pnpm typecheck && pnpm test` xanh
- [ ] Nhờ agent `tenant-isolation-reviewer` rà soát
