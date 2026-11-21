#!/usr/bin/env sh
# Khởi tạo Garage dev (ADR 0014): gán layout cho node đơn, nạp khóa truy cập cố định, tạo bucket, cấp quyền.
# Gọi qua `pnpm storage:init` (trong workspace/) sau `pnpm db:up`. Chạy lại nhiều lần không sao (idempotent).
# Khóa dưới đây là giá trị giả chỉ dùng ở dev/CI, khớp `.env.example`; không phải bí mật.
set -eu
root="$(cd "$(dirname "$0")/../.." && pwd)"
compose="$root/infra/compose/docker-compose.dev.yml"

BUCKET="rentwell-dev"
KEY_NAME="rentwell-dev"
KEY_ID="GKce36af4d41dcddb051e67991"
KEY_SECRET="68f0ed1f6905645a112fbbbcf307aced149a8f3d3256605ee59fef0dcdf251b7"

# MSYS_NO_PATHCONV: Git Bash trên Windows tự đổi `/garage` thành đường dẫn Windows; không ảnh hưởng Linux/macOS.
garage() {
  MSYS_NO_PATHCONV=1 docker compose -f "$compose" exec -T garage /garage "$@"
}

if garage status | grep -q "NO ROLE ASSIGNED"; then
  node_id="$(garage node id -q | cut -d@ -f1)"
  echo "== Gán layout cho node đơn"
  garage layout assign -z dc1 -c 1G "$node_id"
  garage layout apply --version 1
else
  echo "== Layout đã có"
fi

if garage key info "$KEY_ID" >/dev/null 2>&1; then
  echo "== Khóa $KEY_NAME đã có"
else
  echo "== Nạp khóa $KEY_NAME"
  garage key import --yes -n "$KEY_NAME" "$KEY_ID" "$KEY_SECRET"
fi

if garage bucket info "$BUCKET" >/dev/null 2>&1; then
  echo "== Bucket $BUCKET đã có"
else
  echo "== Tạo bucket $BUCKET"
  garage bucket create "$BUCKET"
fi

garage bucket allow --read --write --owner "$BUCKET" --key "$KEY_ID"
echo "OK: Garage sẵn sàng tại http://127.0.0.1:3900 (bucket $BUCKET, region garage, path-style)"
