# Quy ước viết code

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15

## 1. Chung

- TypeScript `strict`, cấm `any` ngầm; ESLint + Prettier bắt buộc, chạy ở pre-commit và CI.
- Tên biến, hàm, file theo tiếng Anh; chú thích nghiệp vụ có thể tiếng Việt khi cần giải thích "vì sao".
- Mỗi hàm một việc; hàm thuần ưu tiên cho logic tiền và ngày.
- Không để bí mật, URL thật, dữ liệu cá nhân trong mã hoặc kiểm thử.

## 2. Đặt tên

| Loại | Quy ước | Ví dụ |
|---|---|---|
| File, thư mục | kebab-case | `booking-items.service.ts` |
| Lớp, kiểu | PascalCase | `BookingsService`, `QuoteResult` |
| Biến, hàm | camelCase | `calculateNights` |
| Hằng số | UPPER_SNAKE_CASE | `MAX_HOLD_MINUTES` |
| Bảng, cột SQL | snake_case, bảng số nhiều | `booking_items`, `start_date` |
| Endpoint | kebab-case, số nhiều | `/v1/item-types` |
| Biến môi trường | UPPER_SNAKE_CASE, có tiền tố nhóm | `PAYMENT_WEBHOOK_SECRET` |

## 3. Tiền và ngày

- **Tiền:** số nguyên đồng (`bigint` ở DB, `number` an toàn hoặc `bigint` ở TS). Không dùng số thực. Tên có hậu tố rõ: `amountVnd` khi cần.
- **Ngày thuê:** kiểu ngày `YYYY-MM-DD`, không có giờ; "đêm" = ngày địa phương. Thời điểm sự kiện: `timestamptz`, ISO 8601.
- Không dùng `new Date()` trực tiếp trong logic nghiệp vụ; nhận đồng hồ làm tham số hoặc qua dịch vụ có thể giả lập khi kiểm thử.

## 4. Backend

- Controller mỏng: kiểm tra đầu vào, gọi service, trả kết quả.
- Service chứa nghiệp vụ; repository là nơi **duy nhất** viết SQL.
- Mọi truy vấn trong giao dịch có `SET LOCAL app.tenant_id`; không mở kết nối "chay".
- Lỗi nghiệp vụ dùng lớp lỗi riêng có `code` ổn định; không ném chuỗi.
- Không bắt lỗi rồi bỏ qua; log có `request_id`.

## 5. Frontend và mobile

- Dữ liệu từ máy chủ qua TanStack Query; trạng thái giao diện cục bộ để trong component.
- Form dùng React Hook Form + Zod schema từ `packages/shared`.
- Thành phần dùng chung trong `packages/ui`; không sao chép.
- Truy cập: nhãn cho form, tương phản màu, điều hướng bàn phím, kích thước chạm tối thiểu trên mobile.
- Văn bản hiển thị đi qua i18n, không viết cứng nhiều nơi.

## 6. Kiểm thử

- Tên kiểm thử mô tả hành vi: "từ chối đơn giao khác tỉnh".
- Một kiểm thử, một ý chính; dùng bảng ca cho hàm thuần.
- Không phụ thuộc thứ tự chạy hay ngày giờ thật.

## 7. Tài liệu

- Quyết định kiến trúc mới → thêm ADR.
- Đổi hành vi API → cập nhật OpenAPI (sinh tự động) và `api-conventions.md` nếu đổi quy ước.
- Đổi lược đồ → migration mới + cập nhật `schema-overview.md` / `erd.md`.
