import type { Metadata } from 'next'
import '@/app/globals.scss'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'local-work-qa',
  description: 'AI-assisted knowledge base for problem-solving logs',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja">
      <body>
        <nav className="nav">
          <Link href="/" className="nav__logo">
            <span className="nav__logo-icon">📚</span>
            <span className="nav__logo-title">local-work-qa</span>
            <span className="nav__logo-version">v0.1</span>
          </Link>
          <div className="nav__spacer" />
          <span className="nav__meta">問題解決ナレッジベース</span>
        </nav>
        {children}
      </body>
    </html>
  )
}
