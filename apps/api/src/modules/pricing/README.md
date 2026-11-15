# pricing/

Bảng giá, giá mùa, giảm theo bậc, phí giao hàng (hàm thuần).

## Bên trong

| Mục | Mô tả |
|---|---|
| `dto/` | Schema đầu vào và đầu ra (Zod) của module. |
| `events/` | Sự kiện miền module phát ra cho phần khác lắng nghe. |

## Quy tắc

- Khuôn module: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.repository.ts`, `*.policy.ts`, `dto/`, `events/`, `index.ts`.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
