---
paths:
  - "apps/web/**"
  - "apps/admin/**"
  - "apps/mobile/**"
  - "packages/ui/**"
---

# Quy tắc giao diện (web, admin, mobile)

- **Cổng thiết kế:** chưa có thiết kế do người dùng duyệt thì KHÔNG làm giao diện; dừng và hỏi (xem `docs/08-guides/working-agreement.md` mục 5). Không tự chọn phong cách, màu, phông, bố cục.
- Dữ liệu từ máy chủ qua TanStack Query; client API sinh từ OpenAPI (`packages/api-client`).
- Form dùng React Hook Form và Zod schema từ `packages/shared`. Không viết lại luật kiểm tra ở nhiều nơi.
- Thành phần dùng chung đặt ở `packages/ui`, không sao chép giữa web và admin.
- Ẩn nút theo vai trò chỉ để tiện dùng, không phải bảo mật; quyền thật nằm ở API.
- Truy cập: nhãn cho mọi ô nhập, tương phản đủ, dùng được bằng bàn phím, vùng chạm tối thiểu trên mobile.
- Văn bản hiển thị đi qua i18n (mặc định tiếng Việt).
- Mobile: token lưu bằng `expo-secure-store`; thao tác ghi thử lại an toàn nhờ `Idempotency-Key`.
- Tiền hiển thị định dạng VND từ số nguyên đồng; không tính tiền ở client để gửi lên.
