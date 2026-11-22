import { Link } from 'react-router'

export default function NotFound() {
  return (
    <section className="space-y-3">
      <h1 className="rise text-4xl font-semibold tracking-tight">Page not found</h1>
      <Link to="/" className="text-muted-foreground underline">
        Back to home
      </Link>
    </section>
  )
}
