# Bảng thuật ngữ

**Trạng thái:** Đã duyệt · **Cập nhật lần cuối:** 2026-11-15

Dùng thống nhất trong tài liệu, mã nguồn và giao diện.

| Thuật ngữ (VI) | Tên trong code | Giải nghĩa |
|---|---|---|
| Cửa hàng | `tenant` | Một đơn vị cho thuê độc lập trên nền tảng; ranh giới cô lập dữ liệu |
| Loại món | `item_type` | Mẫu sản phẩm cho thuê (ví dụ: áo dài lụa đỏ) |
| Biến thể / SKU | `item_variant` | Phiên bản cụ thể có tồn kho riêng (size, màu). Món không có size/màu vẫn có một biến thể "Mặc định" |
| Đêm | `night` | Đơn vị thuê. Nhận 10, trả 12 là 2 đêm |
| Số đêm đệm | `buffer_nights` | Số đêm chặn sau khi trả để giặt, kiểm tra trước khi cho thuê lại |
| Đơn thuê | `booking` | Một lần khách thuê một hoặc nhiều món trong một khoảng ngày |
| Giữ chỗ | `hold` | Trạng thái tạm giữ tồn kho có hạn (`hold_expires_at`) trong lúc chờ thanh toán |
| Tồn dùng được | `branch_stock.quantity_usable` | Số lượng sẵn sàng cho thuê của một biến thể tại một chi nhánh; chỉ đổi qua sổ cái |
| Phiếu chuyển hàng | `stock_transfers` | Chuyển hàng giữa hai chi nhánh của một chuỗi (nghiệp vụ Kho) |
| Đổi size | `booking_item_swaps` | Khách đến chi nhánh đã thuê đổi size; quần áo/thời trang không thu phí |
| Sổ cái kho | `inventory_movements` | Bảng chỉ thêm ghi mọi biến động tồn |
| Lịch tồn | `inventory_calendar` | Tồn theo từng đêm của từng biến thể tại từng chi nhánh, chặn đặt lố |
| Lô hàng | `inventory_lots` | Lô nhập: ngày/nơi sản xuất, nhà cung cấp, ngày mua |
| Bàn giao | `handover` | Biên bản giao đồ (`handover`) hoặc nhận lại đồ (`return`) |
| Cọc | `deposit` | Khoản tiền giữ để bảo đảm, hoàn lại sau khi trả đồ nếu không phát sinh |
| Phí trễ | `late_fee` | Phí khi trả sau ngày hẹn, theo `late_fee_rules` |
| Phí giao | `delivery_fee` | Phí giao/nhận tận nơi, theo quy tắc của cửa hàng |
| Bồi thường hư hỏng | `damage_claim` | Yêu cầu bồi thường khi đồ hỏng hoặc mất |
| Thành viên | `membership` | Liên kết người dùng với cửa hàng cùng vai trò |
| Nhân viên giao nhận | `staff` | Người giao và nhận đồ tại chỗ |
| Nhân viên kho | `warehouse` | Người soạn, kiểm tra, nhập xuất kho |
| Chăm sóc khách hàng | `support` | Người xử lý phiếu hỗ trợ |
| Super admin | `is_super_admin` | Quản trị viên toàn nền tảng (cờ trên người dùng) |
| RLS | Row Level Security | Chính sách PostgreSQL giới hạn dòng dữ liệu theo tenant |
| ADR | Architecture Decision Record | Biên bản một quyết định kiến trúc |
| DoD | Definition of Done | Tiêu chí hoàn thành của một giai đoạn |
| MVP | Minimum Viable Product | Bản tối thiểu dùng được |

- **Chuỗi / cửa hàng (tenant):** một thương hiệu cho thuê trên nền tảng, có dữ liệu riêng và có thể có nhiều chi nhánh. Mọi chuỗi dùng chung một website (ADR 0005).
- **Chi nhánh (branch):** một điểm nhận/trả cụ thể của chuỗi, có kho riêng. Đơn thuộc đúng một chi nhánh và trả đồ ở chi nhánh đó (ADR 0006).
