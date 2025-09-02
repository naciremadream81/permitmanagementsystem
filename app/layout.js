import './globals.css'

export const metadata = {
  title: 'PermitPro',
  description: 'Permit Management System',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
