# Chiến lược kiểm thử

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15

## 1. Nguyên tắc

1. **Kiểm thử nơi rủi ro nằm:** tiền, tồn kho, cô lập tenant, phân quyền. Không đuổi theo phần trăm độ phủ chung.
2. **Dùng Postgres thật** cho kiểm thử liên quan RLS, ràng buộc, trigger; không giả lập CSDL ở những phần này.
3. Hàm tính giá là **hàm thuần**, kiểm thử bằng bảng ca (table-driven), bao gồm ca biên.
4. Mỗi lỗi đã sửa kèm một kiểm thử tái hiện.

## 2. Tầng kiểm thử

| Tầng | Công cụ | Kiểm gì | Khi nào chạy |
|---|---|---|---|
| Đơn vị | Vitest | Tính số đêm, giá, phí giao, phí trễ, hoàn cọc | Mỗi PR |
| SQL / CSDL | pgTAP hoặc script SQL + Vitest | RLS, `CHECK`, trigger cấm sửa, hàm giữ chỗ | Mỗi PR |
| Tích hợp API | Vitest/Jest + Testcontainers | Endpoint, guard, giao dịch, idempotency, webhook | Mỗi PR |
| E2E web | Playwright | Đặt thuê, thanh toán sandbox, vòng đời đơn | Hằng đêm, trước phát hành |
| E2E mobile | Maestro | Luồng đặt thuê của khách, giao nhận của nhân viên | Trước phát hành |
| Tải | k6 | Đặt trùng đồng thời; webhook trùng | Trước phát hành, sau thay đổi tồn kho |
| Bảo mật | Quét phụ thuộc, quét bí mật, rà soát thủ công | Lỗ hổng đã biết, lộ khóa | Mỗi PR / trước phát hành |

## 3. Bộ kiểm thử "không thương lượng" (phải xanh mới gộp)

**Cô lập tenant**
- Tenant B không đọc/ghi/xóa được dữ liệu tenant A qua bất kỳ endpoint nào.
- Kết nối bằng role ứng dụng không đặt `app.tenant_id` thì thấy 0 dòng.
- Khóa ngoại chặn tham chiếu chéo tenant.

**Tồn kho**
- Không thể `reserved > capacity` dù đồng thời.
- `branch_stock.quantity_usable` = tổng `delta_usable` trong sổ cái, theo từng (chi nhánh, biến thể).
- Sổ cái không sửa/xóa được.
- Hủy và hết hạn nhả đúng số lượng.

**Tiền**
- Webhook trùng không tạo tác động kép.
- Tổng hoàn tiền không vượt tổng đã thu.
- Cùng `Idempotency-Key` trả cùng kết quả.

**Phân quyền**
- Mỗi ô ma trận trong `roles-permissions.md` có ca cho phép và ca từ chối.
- Đổi ID sang tài nguyên người khác nhận 403/404.

## 4. Dữ liệu kiểm thử

- Seed có sẵn: hai cửa hàng, mỗi cửa hàng đủ vai trò, vài món có biến thể, bảng giá và quy tắc giao.
- Mỗi kiểm thử tích hợp chạy trong giao dịch/lược đồ riêng hoặc dọn dẹp sau khi chạy, không phụ thuộc thứ tự.
- Thời gian dùng đồng hồ giả (không phụ thuộc ngày thật) cho ca biên ngày/mùa.

## 5. Mục tiêu độ phủ (tham khảo)

| Khu vực | Mục tiêu |
|---|---|
| Hàm tính giá, phí | gần 100% nhánh |
| Module `bookings`, `inventory`, `payments` | từ 85% dòng |
| Phần còn lại | không đặt cứng; ưu tiên kiểm thử luồng chính |
