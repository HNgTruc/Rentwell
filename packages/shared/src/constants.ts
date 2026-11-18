// Hằng số nghiệp vụ đã chốt (ADR 0009). Đổi giá trị ở đây phải kèm ADR mới.

/** Tiền tệ mặc định; tiền luôn là số nguyên đồng. */
export const CURRENCY = 'VND' as const;

/** Thời hạn giữ chỗ chưa thanh toán (phút). */
export const HOLD_MINUTES = 15;

/** Số đơn `hold` chưa thanh toán tối đa của một người dùng trên toàn nền tảng. */
export const MAX_ACTIVE_HOLDS_PER_USER = 3;

/** Ân hạn trả trễ mặc định (giờ); chuỗi đổi được trong `late_fee_rules.grace_hours`. */
export const DEFAULT_LATE_GRACE_HOURS = 2;

/** Hạn gửi lệnh hoàn tiền (giờ). */
export const REFUND_DISPATCH_HOURS = 24;
