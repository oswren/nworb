import { CONTACT_EMAIL } from '@/config'
import { Mail } from 'lucide-react'

type Props = { className?: string }

export default function ContactLink({ className }: Props) {
  return (
    <a
      href={`mailto:${CONTACT_EMAIL}`}
      className={
        'group inline-flex items-center gap-2 rounded-full border border-border px-4 py-2 text-sm font-medium transition hover:border-foreground/40 hover:bg-foreground/5 ' +
        (className ?? '')
      }
    >
      <Mail className="size-4 text-muted-foreground transition group-hover:text-foreground" />
      <span>{CONTACT_EMAIL}</span>
    </a>
  )
}
