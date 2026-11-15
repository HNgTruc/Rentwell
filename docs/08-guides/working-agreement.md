# Quy tắc làm việc với Claude

**Cập nhật lần cuối:** 2026-11-15
Áp dụng cho mọi phiên làm việc. Bản ngắn nằm trong `CLAUDE.md`; một phần được cưỡng chế bằng `.claude/settings.json`.

## 1. Không tự commit, không tự push

- Claude không chạy `git commit`, `git push`, `git tag` (bị chặn trong `settings.json`).
- Làm xong, Claude trả về: danh sách file đã đổi, tóm tắt thay đổi, và **lệnh sẵn để bạn chạy**:

```bash
git status
git add <các file đã liệt kê>
git commit -m "feat(bookings): thêm kiểm tra tồn kho khi giữ chỗ"
```

- Thông điệp theo Conventional Commits (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`), xem `git-workflow.md`.
- Một commit một việc; nếu thay đổi gồm nhiều việc, Claude chia thành nhiều cặp lệnh.
- Chỉ commit khi bạn nói rõ "hãy commit".

## 2. Thêm thành phần mới: mô tả và chờ ý kiến

Áp dụng cho: thư viện, agent, skill, rule, command, hook, dịch vụ hoặc công cụ ngoài.

Claude phải nêu trước, ngắn gọn:

| Mục | Nội dung |
|---|---|
| Là gì | Tên, mục đích |
| Vì sao cần | Việc nào đang bị vướng nếu không có |
| Thay thế | Cách không cần thêm, hoặc lựa chọn khác |
| Chi phí | Kích thước, bảo trì, giấy phép, bảo mật, tiền (nếu có) |
| Ảnh hưởng | File nào đổi, phần nào bị tác động |

Rồi **chờ bạn đồng ý**. Cưỡng chế: `pnpm add/remove/up` và sửa `.claude/**` đều ở chế độ "hỏi trước" trong `settings.json`.

Thư viện phải kiểm tra: còn được bảo trì, giấy phép phù hợp, không có lỗ hổng đã biết (`pnpm audit`), phiên bản chốt cụ thể.

## 3. Làm đúng phần được giao

- Chỉ sửa file và dòng cần cho yêu cầu.
- Không: refactor, đổi tên, sắp xếp lại import, định dạng lại cả file, nâng phiên bản phụ thuộc, sửa chỗ khác "tiện tay".
- Thấy lỗi hoặc điểm đáng cải thiện ngoài phạm vi: **báo lại** ở cuối, không tự sửa.
- Yêu cầu mơ hồ hoặc mâu thuẫn tài liệu: hỏi, không đoán.
- Diff nhỏ nhất đủ làm xong việc. Trước khi báo xong, Claude tự rà diff xem có dòng nào không liên quan.
- Lưu ý: hook Prettier tự định dạng file vừa sửa. Khi repo đã sạch Prettier thì không sinh diff thừa; nếu thấy diff định dạng ngoài ý muốn, báo lại.

## 4. Làm theo chuyên gia lập trình SEO

Mọi trang công khai (`apps/web`) làm theo `../07-quality/seo.md` và `.claude/rules/seo.md`: render phía máy chủ, siêu dữ liệu đúng từng trang, dữ liệu có cấu trúc, tốc độ, URL sạch, chặn lập chỉ mục phần riêng tư.

## 5. Cổng thiết kế: người dùng thiết kế trước

Áp dụng cho mọi giao diện: màn hình, trang, thành phần, hệ thiết kế ở `apps/web`, `apps/admin`, `apps/mobile`, `packages/ui`.

- **Trước khi làm giao diện**, Claude dừng và hỏi bạn: đã có thiết kế chưa (Figma, ảnh, phác thảo, mô tả), muốn bố cục, phong cách, màu, phông ra sao, màn hình nào làm trước.
- Bạn thiết kế xong và duyệt thì Claude mới làm, **bám đúng bản đã duyệt**. Chỗ thiết kế chưa nói tới thì hỏi, không tự bịa.
- Claude **không tự chọn** phong cách, màu, phông, bố cục. Skill `ui-ux-pro-max` chỉ dùng để tra cứu theo yêu cầu của bạn (ví dụ kiểm tra độ tương phản, gợi ý khi bạn nhờ), kết quả là đề xuất chờ bạn duyệt.
- Phần không phải giao diện (API, cơ sở dữ liệu, logic) không bị chặn bởi cổng này.
- Phần kỹ thuật không có hình dạng (khung dự án Next.js, cấu hình Tailwind, route rỗng) vẫn làm được, nhưng không thêm giao diện hay kiểu dáng.
- Tick `[x]` ở mục "Cổng thiết kế" trong `../00-overview/progress.md` khi bạn xác nhận thiết kế của từng app, để Claude biết đã được phép làm.

## Tóm tắt một dòng

Làm đúng việc được giao, đưa lệnh commit cho tôi, hỏi trước khi thêm cái mới, chờ thiết kế của tôi trước khi làm giao diện.
