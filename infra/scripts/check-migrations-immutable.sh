#!/usr/bin/env sh
# Chặn sửa hoặc xóa migration đã "đóng băng" (quy tắc 4: không sửa migration đã áp).
# Đóng băng = file đã có trên nhánh gốc VÀ bản trên nhánh gốc đã có dấu dbmate "-- migrate:up"
# (tức đã qua công cụ migration). Nhờ vậy lần đầu thêm dấu dbmate vào 001 không bị chặn.
# Dùng: check-migrations-immutable.sh <base-ref>   (vd origin/main)
set -eu
base="${1:-origin/main}"
root="$(git rev-parse --show-toplevel)"
cd "$root"
status=0
for f in $(git diff --name-only --diff-filter=MDR "$base"...HEAD -- db/migrations/ | grep '\.sql$' || true); do
  if git show "$base:$f" 2>/dev/null | grep -q -- '-- migrate:up'; then
    echo "LỖI: migration đã đóng băng bị sửa/xóa: $f (thêm migration mới thay vì sửa)"
    status=1
  fi
done
[ "$status" -eq 0 ] && echo "OK: không sửa migration đã đóng băng"
exit "$status"
