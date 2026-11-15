---
description: Chạy lint, typecheck, test và báo kết quả ngắn gọn
allowed-tools: Bash(pnpm lint), Bash(pnpm typecheck), Bash(pnpm test:*), Bash(git diff:*), Bash(git status)
---

Kiểm tra chất lượng trước khi báo hoàn thành.

1. Vào `workspace/` rồi chạy `pnpm lint`, `pnpm typecheck`, `pnpm test` theo thứ tự.
2. Nếu thay đổi chạm `db/` thì kiểm tra thêm bộ kiểm thử SQL/RLS.
3. Nếu thay đổi chạm tiền, tồn kho hoặc phân quyền thì xác nhận kiểm thử liên quan đã được thêm hoặc cập nhật.
4. Báo kết quả: đạt/không đạt từng bước, lỗi đầu tiên cần sửa (nếu có). Không sửa lan sang việc ngoài yêu cầu.
5. Nhắc cập nhật tài liệu hoặc ADR nếu thay đổi làm đổi hành vi hay quyết định kiến trúc.

Ngữ cảnh thay đổi: !`git status --short`
