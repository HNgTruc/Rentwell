---
description: Chạy một spike kỹ thuật (kiểm chứng rủi ro) và ghi kết quả thành ADR
argument-hint: <tên-spike, ví dụ kysely-rls>
---

Thực hiện spike: $ARGUMENTS

1. Tìm spike trong `docs/01-architecture/tech-stack.md` mục 9; nếu không có thì hỏi lại phạm vi.
2. Nêu giả thuyết cần kiểm chứng và tiêu chí đạt/không đạt **trước khi** viết code.
3. Viết mã thử nhỏ nhất trong thư mục `spikes/<tên>/`, không đụng vào mã sản phẩm.
4. Chạy và ghi kết quả thật (kể cả khi thất bại). Không tuyên bố đạt nếu chưa chạy.
5. Viết ADR (xem `/new-adr`) với kết luận và phương án thay thế nếu không đạt.
6. Cập nhật trạng thái 🟡 thành ✅ hoặc đổi lựa chọn trong `tech-stack.md`.
