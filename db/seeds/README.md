# seeds/

Dữ liệu mẫu cho phát triển và kiểm thử.

## Bên trong

| Mục | Mô tả |
|---|---|
| `001_dev_seed.sql` | 2 chuỗi × 2 chi nhánh (TP.HCM, Hà Nội, Đà Nẵng), đủ vai trò, khách dùng chung và khách vãng lai, món có size, nhập kho theo chi nhánh, bậc giá, giá mùa, ngày lễ và phụ thu, phí giao, phí trễ. Chạy: `pnpm db:seed`; chạy lại thì tự bỏ qua. |

## Quy tắc

- Không dùng dữ liệu thật: email `@example.test`, số điện thoại, địa chỉ, mã phường đều giả.
- UUID cố định để kiểm thử tham chiếu được.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
