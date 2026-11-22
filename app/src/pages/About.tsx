import ContactLink from '@/components/contact-link'

export default function About() {
  return (
    <section className="max-w-2xl space-y-6">
      <h1 className="rise text-4xl font-semibold tracking-tight sm:text-5xl">About</h1>
      <p className="rise rise--delay-1 text-lg leading-relaxed text-muted-foreground">
        A place to try things out before they're finished. The site is built with React and
        hosted on AWS, with the infrastructure defined in Terraform.
      </p>
      <div className="rise rise--delay-2 pt-2">
        <ContactLink />
      </div>
    </section>
  )
}
