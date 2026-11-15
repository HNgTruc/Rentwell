# ADR-0002: Monorepo với pnpm workspaces và Turborepo

- **Trạng thái:** Đã chấp nhận
- **Ngày:** 2026-11-15

## Bối cảnh
Bốn ứng dụng (API, web, admin, mobile) dùng chung kiểu dữ liệu, schema validation và hàm tính giá. Một người phát triển.

## Các phương án
1. **Nhiều repo:** tách bạch; chia sẻ mã khó, đồng bộ phiên bản phiền.
2. **Monorepo:** một nơi, thay đổi liên ứng dụng trong một PR; cần công cụ build.

## Quyết định
Monorepo, pnpm workspaces + Turborepo (cache build, chạy song song).

## Hệ quả
- `packages/shared` là nguồn duy nhất cho Zod schema và hàm thuần (tính số đêm, giá).
- Cần quy tắc phụ thuộc (xem `monorepo-structure.md`) để tránh rối.
- CI chạy theo phần thay đổi (affected) khi repo lớn.
