#!/usr/bin/env sh
# Chặn commit file biến môi trường thật (.env, .env.local, .env.production...). Chỉ cho phép .env.example.
# Dùng: check-no-env.sh <file>...   (lefthook truyền danh sách file staged)
bad=""
for f in "$@"; do
  name="$(basename "$f")"
  case "$name" in
    .env.example) ;;
    .env|.env.*) bad="$bad $f" ;;
  esac
done
if [ -n "$bad" ]; then
  echo "Khong duoc commit file .env that:$bad (chi cho phep .env.example)" >&2
  exit 1
fi
exit 0
