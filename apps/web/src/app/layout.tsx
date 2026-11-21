import type { Metadata } from 'next';
import type { ReactNode } from 'react';

// Khung P0: chưa có giao diện (cổng thiết kế). Chặn lập chỉ mục cho tới khi có trang thật.
export const metadata: Metadata = {
  title: 'Rentwell',
  description: 'Nền tảng cho thuê đồ đa cửa hàng.',
  robots: { index: false, follow: false },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="vi">
      <body>{children}</body>
    </html>
  );
}
