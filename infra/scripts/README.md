# scripts/

Script thiết lập máy dev, kiểm tra trong CI; về sau thêm triển khai, sao lưu, khôi phục.

## Bên trong

| Mục | Mô tả |
|---|---|
| `check-migrations-immutable.sh` | CI: chặn sửa/xóa migration đã đóng băng (đã có trên nhánh gốc với dấu `-- migrate:up`). |
| `check-root.sh` | CI: gốc repo chỉ có mục trong danh sách cho phép. |
| `garage-init.sh` | `pnpm storage:init`: khởi tạo Garage dev (layout node đơn, khóa truy cập cố định, bucket `rentwell-dev`); chạy lại không sao. |
| `db-test.sh` | `pnpm db:test`: chạy lần lượt `db/tests/*.sql` bằng psql trong container Postgres dev, dừng ở file lỗi đầu tiên; chạy được trên Linux (CI) và Windows (Git Bash). |
| `check-no-env.sh` | Hook pre-commit: chặn commit file `.env` thật, chỉ cho phép `.env.example`. |
| `setup-git.sh` | Chạy một lần mỗi máy: `core.excludesFile` (áp `workspace/.gitignore`) và `core.hooksPath` (`infra/git-hooks`). |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
