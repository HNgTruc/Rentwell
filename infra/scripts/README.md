# scripts/

Script thiết lập máy dev, kiểm tra trong CI; về sau thêm triển khai, sao lưu, khôi phục.

## Bên trong

| Mục | Mô tả |
|---|---|
| `check-migrations-immutable.sh` | CI: chặn sửa/xóa migration đã đóng băng (đã có trên nhánh gốc với dấu `-- migrate:up`). |
| `check-root.sh` | CI: gốc repo chỉ có mục trong danh sách cho phép. |
| `check-no-env.sh` | Hook pre-commit: chặn commit file `.env` thật, chỉ cho phép `.env.example`. |
| `setup-git.sh` | Chạy một lần mỗi máy: `core.excludesFile` (áp `workspace/.gitignore`) và `core.hooksPath` (`infra/git-hooks`). |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
