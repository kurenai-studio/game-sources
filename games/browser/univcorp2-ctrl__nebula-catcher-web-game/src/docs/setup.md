# Setup and deployment guide

This project is wired for local development, CI, GitHub Pages deployment, and Cloudflare Pages deployment.

## Local development

```bash
npm install
npm run dev
```

## Quality checks

```bash
npm run check
```

This runs lint, unit tests, and a production build.

## GitHub Pages publication

1. Open the repository on GitHub.
2. Go to **Settings > Pages**.
3. Set **Build and deployment > Source** to **GitHub Actions**.
4. Run **Actions > Deploy GitHub Pages > Run workflow** if the first push did not deploy automatically.

Expected public URL pattern:

```text
https://<github-owner>.github.io/nebula-catcher-web-game/
```

## Cloudflare Pages publication

The workflow `.github/workflows/cloudflare-pages.yml` uses Wrangler Direct Upload to deploy the prebuilt `dist/` directory.

### Required GitHub Actions Secrets

| Secret | Purpose |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account identifier used by Wrangler |
| `CLOUDFLARE_API_TOKEN` | Token allowed to deploy Cloudflare Pages projects |

### Required GitHub Actions Variable

| Variable | Recommended value |
| --- | --- |
| `CLOUDFLARE_PROJECT_NAME` | `nebula-catcher-web-game` |

### Run deployment

1. Open GitHub repository **Settings > Secrets and variables > Actions**.
2. Add the two Secrets and one Variable above.
3. Open **Actions > Deploy Cloudflare Pages**.
4. Click **Run workflow**.
5. The workflow creates the Pages project if it does not exist and deploys `dist/`.

Expected Cloudflare Pages URL pattern:

```text
https://nebula-catcher-web-game.pages.dev
```

## Attach your Cloudflare custom domain

After the Cloudflare Pages project exists:

1. Open Cloudflare Dashboard.
2. Go to **Workers & Pages**.
3. Select the `nebula-catcher-web-game` Pages project.
4. Open **Custom domains**.
5. Choose **Set up a custom domain**.
6. Enter the domain or subdomain you already own in Cloudflare.
7. Continue and activate the domain.

Do not commit domain secrets or API tokens to the repository.
