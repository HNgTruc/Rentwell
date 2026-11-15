# Quy ước API

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15

## 1. Nguyên tắc chung

- REST, JSON, tài liệu OpenAPI sinh từ code (Swagger) tại `/docs`.
- Tiền tố phiên bản: `/v1/...`. Thay đổi phá vỡ thì tăng phiên bản.
- Tên tài nguyên số nhiều, kebab-case: `/v1/bookings`, `/v1/item-types`.
- Thời gian ISO 8601 có múi giờ; ngày thuê dùng `YYYY-MM-DD` (không giờ).
- **Tiền là số nguyên đơn vị đồng**, kèm trường `currency` khi cần (`VND`).
- ID là UUID.

## 2. Xác thực và ngữ cảnh tenant

- Header `Authorization: Bearer <access_token>`.
- Cửa hàng hiện tại lấy từ **token và membership**, không tin `tenant_id` do client gửi trong body.
- Web khách duyệt cửa hàng công khai qua đường dẫn công khai `/v1/public/shops/:slug/...` (không cần đăng nhập, chỉ đọc).

## 3. Định dạng phản hồi

Thành công:

```json
{ "data": { "id": "..." } }
```

Danh sách (phân trang theo con trỏ):

```json
{ "data": [ ... ], "page": { "next_cursor": "abc", "has_more": true } }
```

Lỗi (theo RFC 9457 Problem Details):

```json
{
  "type": "https://rentwell.dev/errors/out-of-stock",
  "title": "Hết hàng",
  "status": 409,
  "code": "OUT_OF_STOCK",
  "detail": "Biến thể M không còn đủ cho 12/12 đến 14/12.",
  "request_id": "req_01H...",
  "errors": [{ "field": "items[0].quantity", "message": "..." }]
}
```

## 4. Mã trạng thái

| Mã | Dùng khi |
|---|---|
| 200/201/204 | Thành công, tạo mới, không nội dung |
| 400 | Sai định dạng |
| 401 | Chưa đăng nhập / token hết hạn |
| 403 | Không đủ quyền |
| 404 | Không thấy (cũng dùng khi tài nguyên thuộc tenant khác, để không lộ sự tồn tại) |
| 409 | Xung đột nghiệp vụ: hết hàng, trạng thái không cho phép |
| 422 | Sai quy tắc nghiệp vụ: ngoài vùng giao |
| 429 | Vượt giới hạn tần suất |

Ánh xạ lỗi CSDL: `23514` (`inventory_not_oversold`) → 409 `OUT_OF_STOCK`; `23514` do khác tỉnh → 422 `OUT_OF_DELIVERY_AREA`.

## 5. Idempotency

- Các thao tác ghi gây tác động tiền hoặc tồn kho (`POST /bookings`, thanh toán, hoàn tiền) **bắt buộc** header `Idempotency-Key` (UUID do client sinh).
- Cùng khóa, cùng nội dung: trả lại kết quả cũ. Cùng khóa, khác nội dung: 422.
- Lưu khóa kèm kết quả trong thời gian tối thiểu 24 giờ.
- Webhook từ cổng thanh toán: chống trùng bằng mã sự kiện duy nhất trong `payment_webhook_events`.

## 6. Phân trang, lọc, sắp xếp

- Phân trang con trỏ: `?limit=20&cursor=...` (mặc định 20, tối đa 100).
- Lọc: `?status=confirmed&from=2026-12-01&to=2026-12-31`.
- Sắp xếp: `?sort=-created_at`.

## 7. Giới hạn tần suất

- Theo IP và theo người dùng, lưu ở Redis.
- Đường nhạy cảm (đăng nhập, quên mật khẩu) giới hạn chặt hơn; trả `429` kèm `Retry-After`.

## 8. Nhóm endpoint chính (dự kiến)

| Nhóm | Ví dụ |
|---|---|
| Auth | `POST /v1/auth/login`, `/refresh`, `/logout`, `/forgot-password` |
| Cửa hàng | `GET/PATCH /v1/tenant`, `/v1/tenant/members` |
| Danh mục | `/v1/item-types`, `/v1/item-types/:id/variants`, `/v1/categories` |
| Tồn kho | `/v1/inventory/movements`, `/v1/inventory/availability?variant=&from=&to=` |
| Báo giá | `POST /v1/quotes` (tính giá, không giữ chỗ) |
| Đơn thuê | `POST /v1/bookings`, `GET /v1/bookings/:id`, `POST /v1/bookings/:id/cancel`, `/extend` |
| Thanh toán | `POST /v1/bookings/:id/payments`, `POST /v1/webhooks/payments/:provider` |
| Bàn giao | `POST /v1/bookings/:id/handovers`, `/handovers/:id/photos` |
| Hỗ trợ | `/v1/tickets`, `/v1/tickets/:id/messages` |
| Tệp | `POST /v1/files/presign` |

## 9. Bảo mật API

- Kiểm tra mọi đầu vào bằng Zod/class-validator; từ chối trường lạ.
- CORS chỉ cho phép các nguồn đã biết.
- Không trả dữ liệu nội bộ trong lỗi ở môi trường thật; chi tiết nằm trong log theo `request_id`.
