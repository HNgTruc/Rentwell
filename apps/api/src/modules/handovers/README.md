# handovers/

Bàn giao và nhận lại, hư hỏng, phí trễ.

## Bên trong

| Mục | Mô tả |
|---|---|
| `dto/` | Schema đầu vào và đầu ra (Zod) của module. |
| `events/` | Sự kiện miền module phát ra cho phần khác lắng nghe. |

## Quy tắc

- Khuôn module: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.repository.ts`, `*.policy.ts`, `dto/`, `events/`, `index.ts`.

> Khi thêm hoặc xóa mục trong thư mục này, cập nhật bảng trên.
