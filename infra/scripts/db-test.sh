#!/usr/bin/env sh
# Chạy lần lượt mọi file db/tests/*.sql bằng psql trong container Postgres dev; dừng ở file lỗi đầu tiên.
# Gọi qua `pnpm db:test` (trong workspace/), chạy được trên Linux, macOS và Windows (Git Bash).
# Vòng lặp nằm trong script thay vì package.json: shell của pnpm trên Linux tự thay `$f` trước khi
# chuyển cho container (thành chuỗi rỗng), còn cmd trên Windows thì không, nên một dòng lệnh không chạy đúng cả hai.
set -eu
root="$(cd "$(dirname "$0")/../.." && pwd)"
compose="$root/infra/compose/docker-compose.dev.yml"
found=0
for f in "$root"/db/tests/*.sql; do
  [ -e "$f" ] || continue
  found=1
  name="$(basename "$f")"
  echo "== $name"
  # MSYS_NO_PATHCONV: Git Bash trên Windows tự đổi `/db/...` thành đường dẫn Windows; biến này không ảnh hưởng Linux/macOS.
  MSYS_NO_PATHCONV=1 docker compose -f "$compose" exec -T postgres \
    psql -U postgres -d rentwell -v ON_ERROR_STOP=1 -q -f "/db/tests/$name"
done
[ "$found" = 1 ] || { echo "Không có file db/tests/*.sql"; exit 1; }
