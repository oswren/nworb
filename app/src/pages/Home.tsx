import { Link } from 'react-router'
import { ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import ContactLink from '@/components/contact-link'

export default function Home() {
  return (
    <section className="space-y-10">
      <div className="space-y-6">
        <p className="rise inline-flex rounded-full border border-border px-3 py-1 text-xs text-muted-foreground">
          Sandbox · tools, infrastructure and experiments
        </p>
        <h1 className="rise rise--delay-1 text-5xl font-semibold tracking-tight sm:text-7xl">
          Building things, <span className="gradient-text">in the open.</span>
        </h1>
        <p className="rise rise--delay-2 max-w-2xl text-lg leading-relaxed text-muted-foreground">
          Small tools, cloud experiments and the odd side project. Everything here runs on AWS,
          provisioned with Terraform and shipped from React.
        </p>
        <div className="rise rise--delay-2 flex flex-wrap gap-3">
          <Button asChild size="lg" className="rounded-full">
            <Link to="/projects">
              See projects <ArrowRight />
            </Link>
          </Button>
          <ContactLink />
        </div>
      </div>
    </section>
  )
}
