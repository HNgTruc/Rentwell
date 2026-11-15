---
description: Báo tiến độ so với lộ trình và tiêu chí hoàn thành của giai đoạn hiện tại
argument-hint: [P0..P8]
---

Báo tiến độ giai đoạn $ARGUMENTS (nếu để trống, suy ra giai đoạn hiện tại).

1. Đọc `docs/00-overview/progress.md` và `docs/06-roadmap/roadmap.md`, mục giai đoạn tương ứng; coi các mục đã `[x]` là xong, chỉ kiểm tra lại nếu nghi ngờ.
2. Đối chiếu từng công việc và từng tiêu chí hoàn thành (DoD) với mã nguồn, kiểm thử và tài liệu hiện có.
3. Trả về bảng: công việc, trạng thái (xong / đang làm / chưa), bằng chứng (file hoặc kiểm thử).
4. Nêu DoD nào chưa đạt và việc nhỏ nhất để đạt.
5. Nếu trễ so với ước lượng, nhắc quy tắc cắt phạm vi và đề xuất việc có thể cắt. Không tự cắt.
6. Nếu phát hiện việc đã xong nhưng chưa tick, đề xuất đánh `[x]` kèm ngày và hỏi người dùng trước khi sửa tài liệu.
