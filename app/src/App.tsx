import { NavLink, Outlet } from 'react-router'
import AmbientBackground from '@/components/ambient-background'
import ContactLink from '@/components/contact-link'

const year = new Date().getFullYear()

const links = [
  { to: '/', label: 'Home', end: true },
  { to: '/projects', label: 'Projects' },
  { to: '/about', label: 'About' },
]

export default function App() {
  return (
    <div className="relative flex min-h-screen flex-col text-foreground">
      <AmbientBackground />

      <header className="sticky top-4 z-10 mx-auto mt-4 w-[min(92%,56rem)]">
        <nav className="glass flex items-center justify-between rounded-full px-5 py-3">
          <NavLink to="/" className="font-semibold tracking-tight">
            nworb<span className="gradient-text">.</span>
          </NavLink>
          <ul className="flex gap-5 text-sm">
            {links.map((link) => (
              <li key={link.to}>
                <NavLink
                  to={link.to}
                  end={link.end}
                  className={({ isActive }) =>
                    isActive
                      ? 'text-foreground'
                      : 'text-muted-foreground transition hover:text-foreground'
                  }
                >
                  {link.label}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
      </header>

      <main className="mx-auto w-[min(92%,56rem)] flex-1 py-16 sm:py-24">
        <Outlet />
      </main>

      <footer className="mx-auto mt-auto flex w-[min(92%,56rem)] flex-col items-center gap-4 border-t border-border py-10 text-sm text-muted-foreground sm:flex-row sm:justify-between">
        <span>© {year} nworb</span>
        <ContactLink />
      </footer>
    </div>
  )
}
