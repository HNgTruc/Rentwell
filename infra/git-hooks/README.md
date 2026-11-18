# git-hooks/

Hook git của repo. `infra/scripts/setup-git.sh` đặt `core.hooksPath` tới thư mục này. Mỗi hook chỉ đặt `LEFTHOOK_CONFIG=workspace/lefthook.yml` rồi gọi lefthook, vì lefthook mặc định tìm cấu hình ở gốc repo (ADR 0010).

## Bên trong

| Mục | Mô tả |
|---|---|
| `commit-msg` | Kiểm commit message (commitlint, Conventional Commits). |
| `pre-commit` | Prettier và ESLint cho file staged, chặn commit file `.env` thật. |

Bỏ qua tạm thời (ví dụ khi sửa gấp): `LEFTHOOK=0 git commit ...`. CI vẫn kiểm lại.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
