import type { Metadata, Viewport } from "next";

import "./globals.css";

export const metadata: Metadata = {
  title: "用英语学音乐",
  description:
    "面向初中生的“用英语学音乐素养”闯关课程 PWA（内部试用版；本地部署，局域网访问）",
  applicationName: "用英语学音乐",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className="antialiased">{children}</body>
    </html>
  );
}