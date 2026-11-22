export type Project = {
  name: string
  summary: string
  status: 'live' | 'in-progress' | 'idea'
  url?: string
  repo?: string
  tags: string[]
}

// Add tools and projects here. The Projects page renders this list.
export const projects: Project[] = [
  {
    name: 'nworb',
    summary: 'This site. React on S3 and CloudFront, with the infrastructure in Terraform.',
    status: 'in-progress',
    repo: 'https://github.com/oswren/nworb',
    tags: ['react', 'terraform', 'aws'],
  },
  {
    name: 'mm-rend',
    summary:
      'Browser extension that renders Mermaid diagrams from fenced code blocks on sites you allow. Runs locally, with no network requests.',
    status: 'live',
    repo: 'https://github.com/oswren/mm-rend',
    tags: ['browser extension', 'mermaid', 'azure devops'],
  },
]
