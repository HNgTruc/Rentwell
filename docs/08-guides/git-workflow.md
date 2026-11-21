# Quy trình Git

**Trạng thái:** Nháp · **Cập nhật lần cuối:** 2026-11-21

## 1. Nhánh

- `main`: luôn triển khai được; được bảo vệ (chỉ gộp qua PR có CI xanh).
- Nhánh làm việc ngắn hạn (vài ngày), tách từ `main`:
  - `feat/<phạm-vi>-<mô-tả>`: `feat/bookings-quote-endpoint`
  - `fix/<...>`, `docs/<...>`, `chore/<...>`, `refactor/<...>`, `test/<...>`
- Làm một mình vẫn dùng PR: lưu vết quyết định, chạy CI, và là bản nháp kể chuyện cho portfolio.

## 2. Commit (Conventional Commits 1.0.0)

Theo đặc tả [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/). Hook `commit-msg` kiểm tra bằng commitlint (`@commitlint/config-conventional`, cấu hình ở `workspace/commitlint.config.mjs`).

### 2.1. Cấu trúc

```
<type>[(<scope>)][!]: <description>

[body]

[footer(s)]
```

- **Tiêu đề** (dòng đầu, bắt buộc): `type`, tùy chọn `(scope)`, tùy chọn `!`, rồi `: ` (dấu hai chấm và một dấu cách), rồi mô tả. Tối đa 100 ký tự.
- **Body** (tùy chọn): cách tiêu đề **một dòng trống**. Viết tự do, có thể nhiều đoạn; giải thích **vì sao** và bối cảnh, không kể lại diff.
- **Footer** (tùy chọn): cách body **một dòng trống**. Mỗi footer có dạng `Token: giá trị` hoặc `Token #giá trị`. Token dùng `-` thay dấu cách (`Reviewed-by`, `Co-Authored-By`), riêng `BREAKING CHANGE` được viết có dấu cách.
- Dòng trong body và footer tối đa 100 ký tự.

### 2.2. Type

| Type | Dùng khi | Ảnh hưởng SemVer |
|---|---|---|
| `feat` | Thêm tính năng mới | MINOR |
| `fix` | Sửa lỗi | PATCH |
| `docs` | Chỉ đổi tài liệu | không |
| `style` | Định dạng, khoảng trắng, dấu chấm phẩy; không đổi hành vi | không |
| `refactor` | Đổi cấu trúc mã, không thêm tính năng, không sửa lỗi | không |
| `perf` | Cải thiện hiệu năng | không |
| `test` | Thêm hoặc sửa kiểm thử | không |
| `build` | Hệ thống build, phụ thuộc (`pnpm`, Docker) | không |
| `ci` | Cấu hình CI (`.github/workflows`) | không |
| `chore` | Việc lặt vặt khác không đụng mã nguồn hay kiểm thử | không |
| `revert` | Hoàn tác commit trước | tùy commit bị hoàn tác |

Mọi type khi kèm thay đổi phá vỡ đều thành MAJOR (xem 2.4).

### 2.3. Scope

- Danh từ trong ngoặc, viết thường, mô tả phần mã bị ảnh hưởng: tên app (`api`, `web`, `admin`, `mobile`), gói (`ui`, `shared`), khu vực (`db`, `infra`, `claude`) hoặc module nghiệp vụ (`bookings`, `pricing`, `inventory`, `payments`).
- Không bắt buộc; bỏ khi thay đổi trải rộng nhiều nơi.

### 2.4. Thay đổi phá vỡ (breaking change)

Đánh dấu bằng một trong hai cách (hoặc cả hai):

- Thêm `!` ngay trước `:` ở tiêu đề: `feat(api)!: require Idempotency-Key on POST /bookings`.
- Thêm footer viết hoa `BREAKING CHANGE: <mô tả>` (`BREAKING-CHANGE` là từ đồng nghĩa).

Nếu dùng `!` mà không có footer thì mô tả ở tiêu đề phải nói rõ điều gì bị phá vỡ.

### 2.5. Quy ước riêng của dự án

- Viết bằng **tiếng Anh** (theo `CLAUDE.md`, mục Ngôn ngữ).
- `type` và `scope` viết thường. Mô tả bắt đầu bằng chữ thường, dùng thể mệnh lệnh, thì hiện tại (`add`, không `added`/`adds`), không chấm câu ở cuối.
- Một commit, một ý; commit nhỏ, dễ hoàn tác. Thay đổi gồm nhiều ý thì tách thành nhiều commit; nếu một commit khớp nhiều type thì nên tách.
- Hoàn tác: dùng type `revert` và footer `Refs:` trỏ tới SHA bị hoàn tác.
- Liên kết issue bằng footer: `Closes #12`, `Refs: #34`.
- Hook `pre-commit`: lint + typecheck phần thay đổi; `commit-msg`: kiểm tra định dạng.

### 2.6. Ví dụ

```
feat(bookings): reject delivery outside shop province
```

```
fix(pricing): round deposit to whole dong

Deposit was computed from a percentage and could produce fractional
amounts. Money must stay integer dong (CLAUDE.md rule 1).

Closes #42
```

```
feat(api)!: drop tenant_id from booking request body

BREAKING CHANGE: clients must stop sending tenant_id; the server now
derives it from the authenticated session.
```

```
revert: feat(bookings): reject delivery outside shop province

Refs: 676104e
```

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
