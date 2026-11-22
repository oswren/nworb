import { ArrowUpRight } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { projects } from '@/data/projects'

const statusLabel: Record<string, string> = {
  live: 'Live',
  'in-progress': 'In progress',
  idea: 'Idea',
}

export default function Projects() {
  return (
    <section className="space-y-8">
      <h1 className="rise text-4xl font-semibold tracking-tight sm:text-5xl">
        <span className="gradient-text">Projects</span>
      </h1>
      <div className="grid gap-5 sm:grid-cols-2">
        {projects.map((project, i) => (
          <article
            key={project.name}
            className="glass rise group rounded-2xl p-6 transition hover:-translate-y-1"
            style={{ animationDelay: `${0.05 * i}s` }}
          >
            <div className="flex items-start justify-between gap-3">
              <h2 className="text-xl font-semibold">{project.name}</h2>
              <Badge variant="secondary">{statusLabel[project.status]}</Badge>
            </div>
            <p className="mt-3 leading-relaxed text-muted-foreground">{project.summary}</p>
            <div className="mt-5 flex flex-wrap gap-2 text-xs">
              {project.tags.map((tag) => (
                <span key={tag} className="rounded-full bg-muted px-2.5 py-1 text-muted-foreground">
                  {tag}
                </span>
              ))}
            </div>
            {(project.repo || project.url) && (
              <div className="mt-5 flex flex-wrap gap-4 text-sm">
                {project.repo && (
                  <a
                    href={project.repo}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-muted-foreground transition hover:text-foreground"
                  >
                    GitHub <ArrowUpRight className="size-3.5" />
                  </a>
                )}
                {project.url && (
                  <a
                    href={project.url}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-muted-foreground transition hover:text-foreground"
                  >
                    Visit <ArrowUpRight className="size-3.5" />
                  </a>
                )}
              </div>
            )}
          </article>
        ))}
      </div>
    </section>
  )
}
