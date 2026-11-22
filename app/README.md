# nworb site

The personal sandbox at [nworb.cloud](https://nworb.cloud). A Vite, React and TypeScript app with Tailwind and shadcn/ui components.

## Develop

```bash
npm ci
npm run dev      # local dev server
npm run lint     # oxlint
npm run build    # type check and production build to dist/
```

## Content

- Projects: `src/data/projects.ts`
- Contact address: `src/config.ts`
- Pages: `src/pages/`

## Deploy

Pushes to `main` that touch `app/` are built and published to S3 by the `Deploy site` workflow, and CloudFront is invalidated. The infrastructure lives in `infra/`.
