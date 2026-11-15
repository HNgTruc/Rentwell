---
name: clean-code
description: Làm sạch code trong một phạm vi người dùng chỉ định (file, thư mục hoặc phần vừa thay đổi) mà không đổi hành vi. Dùng khi người dùng gọi /clean-code hoặc nhờ "làm sạch code", "dọn code". Không tự chạy khi chưa được nhờ.
---

# Làm sạch code

Skill này **sửa code**, nên phải giữ quy tắc "làm đúng phần đề ra" trong `CLAUDE.md` và `docs/08-guides/working-agreement.md`. Quy ước đặt tên và cấu trúc: `docs/08-guides/conventions.md`, `docs/01-architecture/monorepo-structure.md`, `.claude/rules/`.

## Các bước

1. **Xác định phạm vi.** Chỉ làm trong phạm vi người dùng nêu: một file, một thư mục, hoặc phần chưa commit (`git diff`, file mới). Không nêu phạm vi thì hỏi lại. Không tự quét cả repo.
2. **Chạy kiểm tra trước** (từ `workspace/`): lint, typecheck, test của các gói liên quan. Ghi lại kết quả để so sau. Nếu đang hỏng sẵn, báo người dùng trước khi làm tiếp.
3. **Lập kế hoạch và chờ duyệt.** Liệt kê theo từng file: sẽ sửa gì, vì sao. Đánh dấu chỗ rủi ro. **Chưa sửa gì cho tới khi người dùng đồng ý.**
4. **Sửa** đúng danh sách đã duyệt, từng file một.
5. **Chạy kiểm tra sau.** Lint, typecheck hoặc test hỏng thì hoàn tác thay đổi gây hỏng và báo lại. Không "sửa test cho qua".
6. **Báo cáo** (mẫu ở cuối). **Không commit**: đưa lệnh `git add` / `git commit -m` để người dùng tự chạy.

## Được làm (không đổi hành vi)

- Xóa code chết, import và biến không dùng, `console.log` hay `debugger` sót lại, code bị comment bỏ.
- Đặt lại tên cục bộ cho rõ (biến, hàm nội bộ), tên tiếng Anh theo `conventions.md`.
- Tách hàm quá dài, gom đoạn lặp trong cùng phạm vi, giảm lồng `if` sâu bằng return sớm.
- Thay số hoặc chuỗi "ma thuật" bằng hằng số có tên.
- Gom kiểu hoặc schema trùng sang `packages/shared` khi đã dùng ở từ hai app trở lên (ghi rõ trong kế hoạch).
- Định dạng bằng Prettier (hook sẵn có).

## Không được làm

- Đổi hành vi, chữ ký hàm công khai, export của `index.ts` module, tên endpoint, mã lỗi, dạng dữ liệu trả về.
- Sửa migration đã áp dụng. Sửa SQL, RLS, trigger thì chỉ báo, không làm trong skill này.
- Đụng logic tiền, giá, cọc, tồn kho, giữ chỗ, webhook thanh toán khi **không có test bao phủ**; có test thì vẫn phải nêu riêng trong kế hoạch.
- Thêm, bỏ hay nâng cấp thư viện.
- Sửa ngoài phạm vi. Thấy vấn đề ở chỗ khác thì đưa vào mục "Ngoài phạm vi" của báo cáo.
- Đụng giao diện (`apps/web`, `apps/admin`, `apps/mobile`, `packages/ui`) khi cổng thiết kế trong `docs/00-overview/progress.md` còn trống ô tương ứng.
- Đổi cấu trúc thư mục hoặc chuyển file giữa module (đó là việc riêng, cần duyệt riêng).

## Mẫu báo cáo

```
Phạm vi: <file/thư mục/diff>
Kiểm tra trước: lint ✓/✗, typecheck ✓/✗, test ✓/✗
Đã sửa:
- <file>: <thay đổi> — <lý do>
Kiểm tra sau: lint ✓/✗, typecheck ✓/✗, test ✓/✗
Không đụng vì rủi ro: <danh sách, lý do>
Ngoài phạm vi (đề xuất làm sau): <danh sách>
Lệnh commit:
  git add <các file>
  git commit -m "refactor(<phạm vi>): clean up <tóm tắt>"
```

Nếu có sửa thêm, xóa file, cập nhật README của thư mục đó.
