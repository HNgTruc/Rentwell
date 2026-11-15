---
description: Tạo migration SQL mới đúng quy ước (RLS, kiểm thử đi kèm)
argument-hint: <mô-tả-ngắn-bằng-tiếng-anh>
---

Tạo migration mới cho: $ARGUMENTS

1. Xem số thứ tự migration cuối trong `db/migrations/`, tạo file tiếp theo `NNN_<mô-tả>.sql`.
2. Tuân thủ `.claude/rules/database.md`: `tenant_id`, khóa ngoại ghép, RLS, tiền là `bigint`, sổ cái chỉ thêm.
3. Không sửa migration cũ.
4. Viết kiểm thử trong `db/tests/`: RLS (tenant khác không đọc/ghi được) và ràng buộc mới.
5. Nhắc chạy `pnpm db:migrate` (trong `workspace/`) và codegen kiểu.
6. Cập nhật `docs/02-database/schema-overview.md` (và `erd.md` nếu đổi quan hệ).
7. Liệt kê giới hạn hoặc việc ứng dụng phải kiểm tra thêm (nếu có).
