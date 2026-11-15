---
paths:
  - "**/*.spec.ts"
  - "**/*.test.ts"
  - "db/tests/**"
  - "apps/api/test/**"
---

# Quy tắc kiểm thử

- Kiểm thử RLS, ràng buộc, trigger dùng **Postgres thật** (Testcontainers), không giả lập CSDL.
- Tên kiểm thử mô tả hành vi: "từ chối đơn giao khác tỉnh".
- Hàm thuần dùng bảng ca (table-driven), có ca biên.
- Không phụ thuộc thứ tự chạy hay ngày giờ thật; dùng đồng hồ giả.
- Bộ kiểm thử bắt buộc: cô lập tenant, tồn kho không bị đặt lố khi đồng thời, webhook trùng không tác động kép, ma trận phân quyền (cả cho phép lẫn từ chối).
- Mỗi lỗi đã sửa kèm một kiểm thử tái hiện.
- Xem `docs/07-quality/testing-strategy.md`.
