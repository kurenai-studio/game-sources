# GitHub Pages deployment

- Repository: https://github.com/hendrasaputra/petal-mines
- Workflow: https://github.com/hendrasaputra/petal-mines/actions/workflows/pages.yml
- Pages settings: https://github.com/hendrasaputra/petal-mines/settings/pages
- Selected custom domain: `mines.hensap.id`

## DNS record

In the DNS zone for `hensap.id`, add:

| Type | Name / Host | Target / Value | TTL |
| --- | --- | --- | --- |
| CNAME | `mines` | `hendrasaputra.github.io` | Default |

Use the hostname only: no `https://`, trailing path, or `/petal-mines`. If the provider expects a full record name, use `mines.hensap.id` instead of `mines`. Do not add conflicting A/AAAA records for that same hostname. No changes to the root domain or its nameservers are needed.

The custom domain is configured in this repository's Pages settings. GitHub Actions publishes `dist/`; a repository CNAME file is not used. **Live status, 3 November 2026:** public DNS validates, GitHub has issued the certificate for `mines.hensap.id`, and **Enforce HTTPS** is enabled. The game HTML, JavaScript and CSS return HTTP 200 over trusted HTTPS at https://mines.hensap.id/.

DNS reference: [GitHub's custom-subdomain guide](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-a-subdomain).

## Delivery

Pushes to `main` run `npm ci`, all unit tests, the TypeScript/Vite production build, then deploy the artifact. Pull requests run checks without publishing. The Actions workflow uses Node.js 24 and pinned official action commits.

Vite's relative asset paths support both a project subpath and the custom domain root. Progress is stored locally by browser origin, so the localhost test save will not appear automatically on `mines.hensap.id`.

The account's existing Pages domain points to a separate website. This repository uses its own custom domain; the account-wide domain configuration was left unchanged.
