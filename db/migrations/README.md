# migrations/

Migration SQL thuần, đánh số tăng dần (`001_init.sql`, `002_...`).

## Bên trong

| Mục | Mô tả |
|---|---|
| `001_init.sql` | Lược đồ khởi tạo: 42 bảng, RLS, hàm giữ chỗ tồn kho. |

## Quy tắc

- Không sửa migration đã áp; thay đổi bằng migration mới.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
