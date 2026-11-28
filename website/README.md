# AcadMind Website

Static, responsive bilingual (Arabic/English) landing page for AcadMind.

## Cloudflare Pages deployment

- Connect repository: `team0000-lang/AcadMind`
- Production branch: `fix/ai-library-pdf-ingestion` (change to `main` after merging the website)
- Framework preset: **None**
- Build command: leave empty
- Build output directory: `website`
- Root directory: leave as `/`

The site is plain HTML/CSS/JS and requires no build step. The download button checks GitHub Releases at runtime and links directly to the newest `.apk` asset when one is published. Until then, it links to the releases page.

## Domain

Suggested Pages project name: `acadmind` → `https://acadmind.pages.dev` (subject to availability in Cloudflare).

Update the canonical URL in `robots.txt` and `sitemap.xml` if a different domain is selected.
