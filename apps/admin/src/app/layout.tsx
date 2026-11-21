import type { Metadata } from 'next';
import type { ReactNode } from 'react';

// Trang quản trị là trang riêng tư: luôn noindex (docs/07-quality/seo.md). Chưa có giao diện (cổng thiết kế).
export const metadata: Metadata = {
  title: 'Rentwell Admin',
  robots: { index: false, follow: false },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="vi">
      <body>{children}</body>
    </html>
  );
}
