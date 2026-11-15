---
description: Tạo skill, agent, rule hoặc command mới khi phát hiện việc lặp lại
argument-hint: <loại: skill|agent|rule|command> <tên> <mục đích ngắn>
---

Đề xuất thành phần cấu hình Claude Code mới cho Rentwell: $ARGUMENTS

**Bước 0 (bắt buộc):** mô tả cho người dùng trước (là gì, vì sao cần, nội dung chính, thay thế nếu không thêm) và CHỜ đồng ý. Chưa đồng ý thì không tạo file.

1. Đọc `.claude/README.md` mục "Mở rộng theo dự án" để chọn đúng loại và tránh trùng thành phần đã có.
2. Tạo file đúng chỗ:
   - skill: `.claude/skills/<tên>/SKILL.md` (frontmatter `name`, `description` nêu rõ khi nào dùng)
   - agent: `.claude/agents/<tên>.md` (mặc định chỉ đọc; cấp quyền ghi chỉ khi cần)
   - rule: `.claude/rules/<tên>.md` (frontmatter `paths` hẹp nhất có thể)
   - command: `.claude/commands/<tên>.md`
3. Nội dung dựa trên việc đã làm thật trong dự án, trỏ về docs thay vì chép lại.
4. Cập nhật cây thư mục và bảng trong `.claude/README.md`.
5. Báo lại: tên, lý do thêm, cách kích hoạt. Không commit; đưa lệnh commit cho người dùng tự chạy.
