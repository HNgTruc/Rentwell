import path from 'node:path';
import type { NextConfig } from 'next';

// Lockfile nằm ở workspace/ (ADR 0010), không phải thư mục cha của apps/, nên Next không tự tìm được gốc
// monorepo. Đặt gốc là thư mục repo để Turbopack và output tracing thấy được workspace/node_modules.
const repoRoot = path.join(import.meta.dirname, '../..');

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  turbopack: { root: repoRoot },
  outputFileTracingRoot: repoRoot,
};

export default nextConfig;
