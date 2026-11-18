# modules/

Các module nghiệp vụ; mỗi thư mục là một ranh giới.

## Bên trong

| Mục | Mô tả |
|---|---|
| `audit/` | Nhật ký thao tác nhạy cảm (chỉ thêm). |
| `auth/` | Đăng nhập, token, đổi và đặt lại mật khẩu. |
| `bookings/` | Đơn thuê, giữ chỗ, hợp đồng, gia hạn, hủy. |
| `catalog/` | Danh mục, loại món, biến thể (SKU), ảnh. |
| `files/` | Tệp: tạo presigned URL, quản lý metadata. |
| `handovers/` | Bàn giao và nhận lại, hư hỏng, phí trễ. |
| `inventory/` | Lô, sổ cái biến động tồn kho, lịch tồn kho theo đêm. |
| `memberships/` | Nhân viên, vai trò, lời mời vào cửa hàng. |
| `notifications/` | Email, đẩy, thông báo trong ứng dụng. |
| `payments/` | Thanh toán, cọc, hoàn tiền, webhook cổng thanh toán. |
| `pricing/` | Bảng giá, giá mùa, giảm theo bậc, phí giao hàng (hàm thuần). |
| `health/` | `GET /v1/health`: kiểm API và kết nối CSDL (200 hoặc 503). Không dùng ngữ cảnh tenant. |
| `reports/` | Báo cáo cho cửa hàng và quản trị. |
| `support/` | Phiếu hỗ trợ và khiếu nại. |
| `tenants/` | Cửa hàng (tenant), điểm nhận/trả, cấu hình cửa hàng. |

## Quy tắc

- Module khác chỉ gọi qua `index.ts` của module.
- Không đọc bảng của module khác.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
