# infra/

Hạ tầng và vận hành.

## Bên trong

| Mục | Mô tả |
|---|---|
| `.gitattributes` | Ép kết thúc dòng LF cho script shell và hook git. |
| `compose/` | docker-compose cho dev (và prod về sau). |
| `docker/` | Dockerfile của từng app. |
| `git-hooks/` | Hook git của repo (`core.hooksPath`), gọi lefthook với cấu hình `workspace/lefthook.yml`. |
| `scripts/` | Script thiết lập, kiểm tra CI, triển khai, sao lưu, khôi phục. |

## Quy tắc

- Không chứa bí mật. Mật khẩu trong file dev là giá trị giả, chỉ dùng ở máy dev và CI.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
