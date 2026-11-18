#!/usr/bin/env sh
# Thiết lập git cục bộ cho repo (chạy một lần mỗi máy, sau `pnpm install`, từ bất kỳ đâu trong repo).
#  1. core.excludesFile: .gitignore nằm trong workspace/ nên không tự áp cho apps/, packages/
#     (xem docs/01-architecture/monorepo-structure.md).
#  2. core.hooksPath: hook pre-commit, commit-msg ở infra/git-hooks/ (gọi lefthook với cấu hình workspace/lefthook.yml).
set -eu
root="$(git rev-parse --show-toplevel)"
git config core.excludesFile "$root/workspace/.gitignore"
git config core.hooksPath infra/git-hooks
chmod +x "$root/infra/git-hooks/"* 2>/dev/null || true
echo "OK: core.excludesFile = $root/workspace/.gitignore"
echo "OK: core.hooksPath = infra/git-hooks"
