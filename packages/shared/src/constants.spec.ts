import { describe, expect, it } from 'vitest';
import { HOLD_MINUTES, MAX_ACTIVE_HOLDS_PER_USER, DEFAULT_LATE_GRACE_HOURS } from './index.js';

// Bảo vệ các giá trị đã chốt ở ADR 0009: đổi số phải sửa cả kiểm thử và ADR.
const cases: { name: string; actual: number; expected: number }[] = [
  { name: 'giữ chỗ 15 phút', actual: HOLD_MINUTES, expected: 15 },
  { name: 'tối đa 3 đơn hold mỗi người dùng', actual: MAX_ACTIVE_HOLDS_PER_USER, expected: 3 },
  { name: 'ân hạn trả trễ mặc định 2 giờ', actual: DEFAULT_LATE_GRACE_HOURS, expected: 2 },
];

describe('hằng số nghiệp vụ theo ADR 0009', () => {
  it.each(cases)('$name', ({ actual, expected }) => {
    expect(actual).toBe(expected);
  });
});
