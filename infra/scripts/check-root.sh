#!/usr/bin/env sh
# Gốc repo chỉ được có các mục trong danh sách cho phép (docs/01-architecture/monorepo-structure.md, "Giữ gốc sạch").
# Chỉ xét mục được git theo dõi, nên thư mục cục bộ bị bỏ qua (node_modules...) không làm hỏng kiểm tra.
set -eu
root="$(git rev-parse --show-toplevel)"
allowed=" apps packages db infra docs storage workspace .claude .github README.md CLAUDE.md "
bad=""
for entry in $(git -C "$root" ls-files | cut -d/ -f1 | sort -u); do
  case "$allowed" in
    *" $entry "*) ;;
    *) bad="$bad $entry" ;;
  esac
done
if [ -n "$bad" ]; then
  echo "Mục không được phép ở gốc repo:$bad"
  exit 1
fi
echo "OK: gốc repo sạch"
