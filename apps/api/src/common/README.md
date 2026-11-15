# common/

Thành phần dùng chung, không chứa nghiệp vụ.

## Bên trong

| Mục | Mô tả |
|---|---|
| `decorators/` | Decorator dùng chung (`@CurrentUser`, `@CurrentTenant`, `@Roles`). |
| `errors/` | Lớp lỗi nghiệp vụ và bảng mã lỗi ổn định (`OUT_OF_STOCK`, ...). |
| `filters/` | Bộ lọc lỗi, chuyển lỗi thành RFC 9457 kèm mã lỗi ổn định. |
| `guards/` | Guard xác thực và phân quyền (JWT, vai trò, tenant). |
| `idempotency/` | Xử lý header `Idempotency-Key` cho thao tác ghi tiền và tồn kho. |
| `interceptors/` | Interceptor: gán `request_id`, ghi nhật ký, giới hạn thời gian. |
| `pagination/` | Phân trang kiểu con trỏ. |

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
