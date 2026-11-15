# storage/

Nơi lưu ảnh, video và tệp media trong repo: `uploads/` (dữ liệu dev, không vào git) và `assets/` (tài nguyên tĩnh được commit).

## Bên trong

| Mục | Mô tả |
|---|---|
| `.gitignore` | Chặn nội dung `uploads/` khỏi git (chỉ giữ README). |
| `assets/` | Tài nguyên tĩnh được commit: logo, ảnh mẫu cho seed, ảnh minh họa, video ngắn dùng trong sản phẩm. |
| `uploads/` | Dữ liệu tải lên khi phát triển (thư mục dữ liệu của MinIO dev, tệp thử). Nội dung không vào git. |

## Quy tắc

- Môi trường chạy thật KHÔNG dùng thư mục này: tệp người dùng tải lên đi vào S3/MinIO qua presigned URL.
- Không đặt dữ liệu thật của khách hàng, hợp đồng, giấy tờ vào đây.
- Tệp lớn: GitHub giới hạn 100 MB mỗi tệp; video nặng nên để ngoài git hoặc dùng Git LFS (cần bạn duyệt trước khi thêm).

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
