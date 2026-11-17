# tests/

Kiểm thử SQL: RLS, ràng buộc, trigger. Chạy trên PostgreSQL thật, bằng role không phải superuser/owner.

## Bên trong

| Mục | Mô tả |
|---|---|
| `001_walkin_holidays_close_branch.sql` | Khách vãng lai, bảng ngày lễ và phụ thu (RLS riêng), `opening_hours`, chặn đóng chi nhánh khi còn phiếu chuyển hàng mở. Đã chạy 2026-11-17 trên PostgreSQL 16.16, 20/20 ca đạt. Chưa phủ: đóng chi nhánh khi còn đơn mở hoặc tồn kho (cần seed ở P0). |

Cách chạy: xem phần đầu mỗi file. Mỗi file chạy trong một giao dịch và `ROLLBACK` ở cuối.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
