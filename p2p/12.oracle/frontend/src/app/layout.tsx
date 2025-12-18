import type { Metadata } from "next";
import { Spline_Sans, Noto_Sans } from "next/font/google";
import "./globals.css";

const splineSans = Spline_Sans({
  variable: "--font-spline-sans",
  subsets: ["latin"],
});

const notoSans = Noto_Sans({
  variable: "--font-noto-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Real-time Crypto Price Tracker",
  description: "Track crypto prices in real-time",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=block" />
      </head>
      <body
        className={`${splineSans.variable} ${notoSans.variable} antialiased bg-background-light dark:bg-background-dark font-display text-slate-900 dark:text-white`}
      >
        {children}
      </body>
    </html>
  );
}
