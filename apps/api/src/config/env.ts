import { z } from 'zod';

// Nơi DUY NHẤT đọc biến môi trường. Thiếu hoặc sai thì API không khởi động.
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  // Role ỨNG DỤNG (không superuser, không chủ bảng). Role migration dùng biến khác, API không cần.
  DATABASE_URL: z
    .string()
    .url()
    .refine((v) => v.startsWith('postgres://') || v.startsWith('postgresql://'), 'Phải là URL PostgreSQL'),
  DATABASE_POOL_MAX: z.coerce.number().int().min(1).max(100).default(10),
});

export type AppConfig = z.infer<typeof envSchema>;

export class InvalidConfigError extends Error {}

/** Hàm thuần: nhận một bản đồ biến môi trường, trả cấu hình đã kiểm, hoặc ném lỗi liệt kê biến sai (không in giá trị). */
export function parseEnv(env: Record<string, string | undefined>): AppConfig {
  const result = envSchema.safeParse(env);
  if (!result.success) {
    const fields = result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
    throw new InvalidConfigError(`Cấu hình môi trường không hợp lệ: ${fields}`);
  }
  return result.data;
}

export const APP_CONFIG = Symbol('APP_CONFIG');
