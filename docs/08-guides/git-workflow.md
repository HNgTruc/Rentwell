# Quy trình Git

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-15

## 1. Nhánh

- `main`: luôn triển khai được; được bảo vệ (chỉ gộp qua PR có CI xanh).
- Nhánh làm việc ngắn hạn (vài ngày), tách từ `main`:
  - `feat/<phạm-vi>-<mô-tả>`: `feat/bookings-quote-endpoint`
  - `fix/<...>`, `docs/<...>`, `chore/<...>`, `refactor/<...>`, `test/<...>`
- Làm một mình vẫn dùng PR: lưu vết quyết định, chạy CI, và là bản nháp kể chuyện cho portfolio.

## 2. Commit (Conventional Commits)

```
<loại>(<phạm vi>): <mô tả ngắn, thì hiện tại>

<nội dung giải thích "vì sao", nếu cần>
```

Loại: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`.
Ví dụ: `feat(bookings): reject delivery outside shop province`.

- Một commit, một ý; commit nhỏ, dễ hoàn tác.
- Thay đổi phá vỡ: thêm `!` hoặc đoạn `BREAKING CHANGE:`.
- Hook `pre-commit`: lint + typecheck phần thay đổi; `commit-msg`: kiểm tra định dạng.

## 3. Pull request

- Tiêu đề theo Conventional Commits; mô tả: **vì sao**, thay đổi gì, cách kiểm tra, ảnh chụp nếu có giao diện.
- Danh sách tự kiểm tra:
  - [ ] Kiểm thử mới/cập nhật
  - [ ] Tài liệu/ADR cập nhật
  - [ ] Migration tương thích ngược
  - [ ] Không lộ bí mật, không dữ liệu thật
  - [ ] Đã thử luồng liên quan
- Gộp bằng **squash** để lịch sử `main` gọn, mỗi PR một commit.

## 4. Phiên bản và thẻ

- SemVer: `MAJOR.MINOR.PATCH`. Thẻ `vX.Y.Z` trên `main` khi phát hành.
- `CHANGELOG.md` sinh từ commit hoặc viết tay theo từng phát hành.

## 5. Bảng việc

- GitHub Projects: *Backlog → Đang làm → Review → Xong*; tối đa hai việc đang làm.
- Mỗi issue gắn nhãn giai đoạn (`P0` đến `P8`) và loại (`feature`, `bug`, `chore`, `docs`).
- Mỗi PR liên kết issue (`Closes #n`).

> Claude không tự commit hay push; xem `working-agreement.md`.
