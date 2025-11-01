import "./globals.css";
import { AuthProvider } from "../context/AuthContext";

export const metadata = {
  title: "Smart Gram Admin",
  description: "Next.js + Firebase Auth",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
