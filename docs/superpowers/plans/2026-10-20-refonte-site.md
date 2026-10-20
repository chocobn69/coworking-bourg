# Refonte coworking-bourg.fr — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le site Jekyll/Cayman par un site « Atelier chaleureux » sur mesure, orienté conversion, conforme à
`docs/superpowers/specs/2026-10-20-refonte-site-design.md`.

**Architecture:** Jekyll 3.10 construit par GitHub Pages (gem `github-pages`), sans thème. Un layout unique, une page
d'accueil en sections, les données éditables dans `_data/*.yml`, une feuille CSS maison, polices auto-hébergées,
zéro JavaScript.

**Tech Stack:** Jekyll 3.10 / Liquid 4 (via `github-pages`), plugins `jekyll-seo-tag`, `jekyll-sitemap`,
`jekyll-redirect-from` ; CSS ; Docker (`ruby:3.3`) pour le build local ; Chrome headless pour les captures.

**Repo :** `/home/choco/projets_locaux/coworking-bourg`, branche `refonte` (déjà créée, contient la spec).

**Conventions pour l'exécutant :**
- Le shell a des alias destructifs : utiliser `command rm -f`, `command cp`, `command mv`, `command grep`, `command cat`.
- « Tests » = commandes de vérification sur `_site/` après build. Les sorties attendues sont données à chaque étape.
- Les fichiers temporaires (captures, etc.) vont dans `_scratch/` (ignoré par git et par Jekyll).
- Build : `./run_local.sh build` (créé en Task 1). Durée : ~1 min au premier lancement, quelques secondes ensuite.

---

## Fichiers

| Fichier | Rôle | Action |
|---|---|---|
| `Gemfile`, `Gemfile.lock` | Uniquement `github-pages` (versions = production) | Modifier |
| `run_local.sh` | Build/serve local via Docker | Réécrire |
| `.gitignore` | + `_scratch/` | Modifier |
| `_config.yml` | Sans thème, plugins réduits, SEO, exclusions | Réécrire |
| `_data/infos.yml` | Adresse, contact, horaires, gare | Créer |
| `_data/tarifs.yml` | Groupes de tarifs TTC | Créer |
| `_data/services.yml` | Services inclus | Créer |
| `assets/fonts/*.woff2`, `*-OFL.txt` | Fraunces (droit + italique), Work Sans, licences | Créer |
| `assets/css/main.css` | Toute la mise en forme | Créer |
| `assets/favicon.svg` | Favicon | Créer |
| `_layouts/default.html` | `<head>`, en-tête, pied de page | Réécrire |
| `_includes/jsonld.html` | JSON-LD `LocalBusiness` | Créer |
| `index.html` | Page d'accueil + redirections des anciennes URL | Créer (remplace `index.md`) |
| `mentions-legales.md` | Mentions légales | Créer |
| `404.html` | Page 404 en français | Réécrire |
| `README.md` | Comment modifier et lancer le site | Réécrire |
| `index.md`, `about.md`, `presta.md`, `tarifs.md`, `acces.md`, `contacts.md`, `photos.md`, `_posts/`, `_layouts/index.html`, `_layouts/post.html`, `assets/css/style.scss`, `assets/Logo.jpg`, `assets/menage-ext-avant-apres.jpg`, `action.yml`, `.github/workflows/jekyll-docker.yml` | Ancien site | Supprimer |

---

### Task 1 : Build local reproductible

**Files:**
- Modify: `Gemfile`, `Gemfile.lock` (régénéré), `.gitignore`
- Rewrite: `run_local.sh`

- [ ] **Step 1 : Remplacer `Gemfile`**

```ruby
source "https://rubygems.org"

gem "github-pages", group: :jekyll_plugins
```

- [ ] **Step 2 : Réécrire `run_local.sh`**

```bash
#!/usr/bin/env bash
#
# run_local.sh — build or serve the site locally with the same Jekyll as GitHub Pages
#
# Usage:
#   ./run_local.sh           serve on http://localhost:4000
#   ./run_local.sh build     build once into _site/
#
# Modes:
#   serve (default)  jekyll serve, rebuilds when a file changes
#   build            jekyll build, then exit
#
# Everything runs in a ruby container: Docker is the only host requirement.
# Gems are cached in ~/.cache/coworking-bourg-gems between runs.

set -euo pipefail

RUBY_IMAGE="ruby:3.3"
REPO_NWO="chocobn69/coworking-bourg"
GEM_CACHE="${HOME}/.cache/coworking-bourg-gems"
PORT="4000"
SITE_DIR="$(cd "$(dirname "$0")" && pwd)"

docker_options=(
    --rm
    # Run as the host user so _site/ and Gemfile.lock are not owned by root
    --user "$(id -u):$(id -g)"
    --env HOME=/tmp
    --env BUNDLE_PATH=/gems
    # github-pages needs the repository name to fill site.github outside of GitHub
    --env PAGES_REPO_NWO="${REPO_NWO}"
    --volume "${GEM_CACHE}:/gems"
    --volume "${SITE_DIR}:/srv"
    --workdir /srv
)

prepare_gem_cache() {
    mkdir -p "${GEM_CACHE}"
}

build_site() {
    docker run "${docker_options[@]}" \
        "${RUBY_IMAGE}" \
        sh -c "bundle install --quiet && bundle exec jekyll build"
}

serve_site() {
    docker run "${docker_options[@]}" \
        --interactive \
        --tty \
        --publish "${PORT}:${PORT}" \
        "${RUBY_IMAGE}" \
        sh -c "bundle install --quiet && bundle exec jekyll serve --host 0.0.0.0 --port ${PORT}"
}

main() {
    local mode="${1:-serve}"

    prepare_gem_cache

    case "${mode}" in
        build)
            build_site
            ;;
        serve)
            serve_site
            ;;
        *)
            echo "Usage: $0 [serve|build]" >&2
            exit 1
            ;;
    esac
}

main "$@"
```

Puis : `chmod +x run_local.sh`

- [ ] **Step 3 : Ajouter `_scratch/` à `.gitignore`**

`.gitignore` final :

```
_site
.sass-cache
.jekyll-metadata
.jekyll-cache
_scratch/
```

- [ ] **Step 4 : Régénérer le lock et builder le site actuel**

```bash
command rm -f Gemfile.lock
./run_local.sh build 2>&1 | tail -3
command ls _site/index.html _site/tarifs.html
```

Attendu : `done in … seconds.` puis les deux fichiers listés. Un avertissement « GitHub Metadata: No GitHub API
authentication » est normal.

- [ ] **Step 5 : Vérifier que le lock pointe sur github-pages / Jekyll 3.10**

```bash
command grep -E '^    (github-pages|jekyll) \(' Gemfile.lock
```

Attendu : une ligne `github-pages (…)` et une ligne `jekyll (3.10.…)`.

- [ ] **Step 6 : Commit**

```bash
git add Gemfile Gemfile.lock run_local.sh .gitignore
git commit -m "Build locally in Docker with the github-pages gem only"
```

---

### Task 2 : Configuration et données

**Files:**
- Rewrite: `_config.yml`
- Create: `_data/infos.yml`, `_data/tarifs.yml`, `_data/services.yml`
- Delete: `assets/css/style.scss` (importe le thème Cayman, qui disparaît)

- [ ] **Step 1 : Réécrire `_config.yml`**

```yaml
title: Coworking Bourg-en-Bresse
tagline: Bureaux partagés en centre-ville
description: >-
  Espace de coworking associatif en plein centre de Bourg-en-Bresse, à 5 minutes à pied de la gare.
  Open space, bureaux privatifs et salle de réunion, à la journée ou au mois.
email: qg.coworkain@gmail.com
url: "https://www.coworking-bourg.fr"
baseurl: ""
lang: fr
locale: fr_FR

webmaster_verifications:
  google: omjtwlAwENW3ic3Nw6-ZVjn3lwXdwK5TZl1S9A-g4Cs

markdown: kramdown
plugins:
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from

# Overrides Jekyll's default exclude list, so the defaults are repeated here
exclude:
  - docs/
  - README.md
  - LICENSE
  - run_local.sh
  - Gemfile
  - Gemfile.lock
  - vendor/
  - node_modules/
```

`jekyll-seo-tag` produit alors pour l'accueil le titre « Coworking Bourg-en-Bresse | Bureaux partagés en centre-ville »
(séparateur `|` imposé par le plugin).

- [ ] **Step 2 : Créer `_data/infos.yml`**

```yaml
nom: Coworking Bourg-en-Bresse
association: Cowork'Ain
responsable_publication: Nicolas Baccelli
adresse:
  rue: 14 rue du Général Logerot
  code_postal: "01000"
  ville: Bourg-en-Bresse
geo:
  latitude: 46.1996201
  longitude: 5.2205576
telephone: 06 10 30 80 68
telephone_international: "+33610308068"
mail: qg.coworkain@gmail.com
lien_visite: mailto:qg.coworkain@gmail.com?subject=Visite%20du%20coworking
facebook: https://www.facebook.com/LeQGBourgenBresse/
carte: https://www.openstreetmap.org/?mlat=46.19962&mlon=5.22056#map=18/46.19962/5.22056
surface: 130 m²
gare_a_pied: 5 minutes
horaires: Du lundi au vendredi, 8 h – 18 h
horaires_schema: Mo-Fr 08:00-18:00
```

- [ ] **Step 3 : Créer `_data/tarifs.yml`**

```yaml
# Prix TTC en euros
- groupe: À la carte
  lignes:
    - libelle: Demi-journée
      prix: 7
    - libelle: Journée
      prix: 14
- groupe: Au mois
  lignes:
    - libelle: Poste en open space
      prix: 117
    - libelle: Bureau privatif
      prix: 552
- groupe: Salle de réunion
  lignes:
    - libelle: Demi-journée
      prix: 42
    - libelle: Journée
      prix: 84
```

- [ ] **Step 4 : Créer `_data/services.yml`**

```yaml
- Fibre filaire et wifi
- Café
- Imprimante
- Cuisine
- Salle de repos
- Accès PMR
```

- [ ] **Step 5 : Supprimer l'ancienne feuille et builder**

```bash
command rm -f assets/css/style.scss
./run_local.sh build 2>&1 | tail -2
command ls _site/docs 2>&1 | head -1
```

Attendu : `done in …` ; `ls: cannot access '_site/docs': No such file or directory` (la spec n'est pas publiée).

- [ ] **Step 6 : Commit**

```bash
git add _config.yml _data
git rm -q assets/css/style.scss
git commit -m "Drop Cayman theme, add site data files"
```

---

### Task 3 : Polices, favicon, feuille de style

**Files:**
- Create: `assets/fonts/fraunces-latin-wght-normal.woff2`, `assets/fonts/fraunces-latin-wght-italic.woff2`,
  `assets/fonts/work-sans-latin-wght-normal.woff2`, `assets/fonts/Fraunces-OFL.txt`, `assets/fonts/WorkSans-OFL.txt`
- Create: `assets/favicon.svg`, `assets/css/main.css`

- [ ] **Step 1 : Télécharger les polices variables (sous-ensemble latin) et leurs licences**

```bash
mkdir -p assets/fonts
curl -fsSL -o assets/fonts/fraunces-latin-wght-normal.woff2 https://cdn.jsdelivr.net/fontsource/fonts/fraunces:vf@latest/latin-wght-normal.woff2
curl -fsSL -o assets/fonts/fraunces-latin-wght-italic.woff2 https://cdn.jsdelivr.net/fontsource/fonts/fraunces:vf@latest/latin-wght-italic.woff2
curl -fsSL -o assets/fonts/work-sans-latin-wght-normal.woff2 https://cdn.jsdelivr.net/fontsource/fonts/work-sans:vf@latest/latin-wght-normal.woff2
curl -fsSL -o assets/fonts/Fraunces-OFL.txt https://raw.githubusercontent.com/google/fonts/main/ofl/fraunces/OFL.txt
curl -fsSL -o assets/fonts/WorkSans-OFL.txt https://raw.githubusercontent.com/google/fonts/main/ofl/worksans/OFL.txt
file assets/fonts/*
```

Attendu : trois `Web Open Font Format (Version 2)` et deux fichiers texte.

- [ ] **Step 2 : Créer `assets/favicon.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="14" fill="#9E3A26"/><text x="32" y="46" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-size="42" font-weight="700" fill="#F3EDE3">C</text></svg>
```

(Un favicon ne peut pas charger de police web : le « C » s'affiche en Georgia.)

- [ ] **Step 3 : Créer `assets/css/main.css`**

```css
@font-face {
  font-family: "Fraunces";
  src: url("/assets/fonts/fraunces-latin-wght-normal.woff2") format("woff2");
  font-weight: 100 900;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "Fraunces";
  src: url("/assets/fonts/fraunces-latin-wght-italic.woff2") format("woff2");
  font-weight: 100 900;
  font-style: italic;
  font-display: swap;
}

@font-face {
  font-family: "Work Sans";
  src: url("/assets/fonts/work-sans-latin-wght-normal.woff2") format("woff2");
  font-weight: 100 900;
  font-style: normal;
  font-display: swap;
}

:root {
  --papier: #F3EDE3;
  --papier-fonce: #E9E0D2;
  --encre: #2B2622;
  --texte-doux: #4A423B;
  --texte-pied: #5E554C;
  --brique: #9E3A26;
  --pointilles: #B8A992;
  --bordure: #D9CEBD;
  --sur-encre: #E2D8C9;
  --lien-sur-encre: #F0B8A8;
  --contour-sur-encre: #8C7F70;
  --serif: "Fraunces", Georgia, serif;
  --sans: "Work Sans", system-ui, sans-serif;
  --largeur: 1120px;
}

*,
*::before,
*::after {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: var(--papier);
  color: var(--encre);
  font-family: var(--sans);
  font-size: 17px;
  line-height: 1.6;
}

img {
  display: block;
  max-width: 100%;
  height: auto;
}

a {
  color: var(--brique);
}

a:hover {
  color: var(--encre);
}

:focus-visible {
  outline: 3px solid var(--brique);
  outline-offset: 3px;
}

h1,
h2,
h3 {
  margin: 0;
  font-family: var(--serif);
  font-weight: 600;
  line-height: 1.1;
  letter-spacing: -0.02em;
}

p,
address {
  margin: 0;
}

address {
  font-style: normal;
}

.conteneur {
  max-width: var(--largeur);
  margin-inline: auto;
  padding-inline: 24px;
}

.evitement {
  position: absolute;
  left: 8px;
  top: -100px;
  padding: 8px 16px;
  background: var(--encre);
  color: var(--papier);
}

.evitement:focus {
  top: 8px;
}

.doux {
  color: var(--texte-doux);
}

.section {
  padding-block: 88px;
}

.titre-section {
  font-size: clamp(34px, 4.5vw, 48px);
}

.bande {
  background: var(--papier-fonce);
}

/* Boutons */

.bouton {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 44px;
  padding: 12px 22px;
  border: 1px solid transparent;
  border-radius: 999px;
  background: var(--brique);
  color: #FFFFFF;
  font-weight: 600;
  text-decoration: none;
}

.bouton:hover {
  background: var(--encre);
  color: #FFFFFF;
}

.bouton-grand {
  padding: 17px 30px;
  font-size: 18px;
}

.bouton-clair {
  background: var(--papier);
  color: var(--encre);
}

.bouton-clair:hover {
  background: #FFFFFF;
  color: var(--encre);
}

.bouton-contour {
  background: transparent;
  border-color: var(--contour-sur-encre);
  color: var(--papier);
}

.bouton-contour:hover {
  background: transparent;
  border-color: var(--papier);
  color: var(--papier);
}

/* En-tête */

.entete {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding-block: 28px;
  border-bottom: 1px solid var(--bordure);
}

.logotype {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  column-gap: 10px;
  color: var(--encre);
  font-family: var(--serif);
  text-decoration: none;
}

.logotype:hover {
  color: var(--encre);
}

.logotype-nom {
  font-size: 26px;
  font-weight: 700;
  letter-spacing: -0.01em;
}

.logotype-ville {
  color: var(--brique);
  font-size: 22px;
  font-style: italic;
}

.menu {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px 28px;
  font-weight: 500;
}

.menu a:not(.bouton) {
  color: var(--encre);
  text-decoration: none;
}

.menu a:not(.bouton):hover {
  color: var(--brique);
}

/* Tirages photo */

.tirage {
  --rotation: 0deg;
  margin: 0;
  padding: 12px 12px 40px;
  background: #FFFFFF;
  box-shadow: 0 2px 10px rgba(43, 38, 34, 0.12);
  transform: rotate(var(--rotation));
}

.tirage img {
  width: 100%;
  aspect-ratio: 3 / 2;
  object-fit: cover;
}

.tirage figcaption {
  margin-top: 10px;
  color: var(--texte-doux);
  font-family: var(--serif);
  font-size: 16px;
  font-style: italic;
}

.tirage-gauche {
  --rotation: -3deg;
}

.tirage-droite {
  --rotation: 3deg;
}

/* Accroche */

.accroche {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 56px;
  padding-block: 72px 88px;
}

.accroche-texte {
  flex: 999 1 500px;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 26px;
}

.surtitre {
  color: var(--brique);
  font-family: var(--serif);
  font-size: 20px;
  font-style: italic;
}

.accroche h1 {
  font-size: clamp(38px, 5.4vw, 64px);
  line-height: 1.06;
}

.accroche-intro {
  max-width: 540px;
  color: var(--texte-doux);
  font-size: 19px;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 14px;
}

.lien-tel {
  display: inline-flex;
  align-items: center;
  min-height: 44px;
  padding: 12px 4px;
  color: var(--encre);
  font-size: 18px;
  font-weight: 600;
}

.accroche-photos {
  position: relative;
  flex: 1 1 400px;
  min-width: 0;
  height: 440px;
}

.accroche-photo-1 {
  position: absolute;
  top: 0;
  left: 4%;
  width: 68%;
}

.accroche-photo-2 {
  position: absolute;
  right: 0;
  bottom: 0;
  width: 56%;
}

/* Pourquoi ici */

.arguments {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 40px;
  padding-block: 64px;
}

.arguments h2 {
  margin-bottom: 10px;
  font-size: 26px;
}

.arguments p {
  color: var(--texte-doux);
}

/* Espaces */

.espaces {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 56px;
}

.espaces-texte {
  flex: 999 1 520px;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.liste-espaces {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 28px 40px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.liste-espaces h3 {
  margin-bottom: 6px;
  font-size: 22px;
}

.liste-espaces p {
  color: var(--texte-doux);
}

.espaces-photos {
  flex: 1 1 320px;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 28px;
}

.espaces-photos .tirage {
  width: 85%;
}

.espaces-photos .tirage-gauche {
  align-self: flex-end;
}

/* Tarifs */

.tarifs {
  display: flex;
  flex-wrap: wrap;
  gap: 56px;
  border-top: 1px solid var(--bordure);
}

.tarifs-intro {
  flex: 1 1 300px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.services {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.services li {
  padding: 4px 14px;
  border: 1px solid var(--bordure);
  border-radius: 999px;
  font-size: 15px;
}

.tarifs-intro .tirage {
  width: 240px;
  margin-top: 8px;
}

.tarifs-liste {
  flex: 999 1 520px;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 36px;
}

.groupe-tarif h3 {
  margin-bottom: 14px;
  color: var(--brique);
  font-size: 22px;
  font-style: italic;
  font-weight: 400;
}

.groupe-tarif dl {
  margin: 0;
}

.ligne-tarif {
  display: flex;
  align-items: baseline;
  gap: 12px;
  font-size: 19px;
}

.ligne-tarif + .ligne-tarif {
  margin-top: 14px;
}

/* The dotted leader between label and price grows with the label */
.ligne-tarif dt {
  flex-grow: 1;
  display: flex;
  align-items: baseline;
  gap: 12px;
}

.ligne-tarif dt::after {
  content: "";
  flex-grow: 1;
  border-bottom: 2px dotted var(--pointilles);
}

.ligne-tarif dd {
  margin: 0;
  font-family: var(--serif);
  font-size: 26px;
  font-weight: 700;
  white-space: nowrap;
}

/* Accès */

.sombre {
  background: var(--encre);
  color: var(--papier);
}

.sombre a:not(.bouton) {
  color: var(--lien-sur-encre);
}

.sombre a:not(.bouton):hover {
  color: var(--papier);
}

.sombre :focus-visible {
  outline-color: var(--papier);
}

.acces {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 40px;
  padding-block: 80px;
}

.acces-texte {
  flex: 999 1 460px;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.acces-texte address,
.acces-texte p {
  color: var(--sur-encre);
  font-size: 19px;
}

.acces-contacts {
  flex: 1 1 280px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.acces-contacts .bouton {
  padding: 17px 24px;
  font-size: 18px;
}

/* Pied de page */

.pied {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 16px;
  padding-block: 32px;
  color: var(--texte-pied);
  font-size: 15px;
}

.pied nav {
  display: flex;
  gap: 20px;
}

/* Pages simples : mentions légales, 404 */

.page {
  max-width: 760px;
  padding-block: 64px 88px;
}

.page h1 {
  margin-bottom: 32px;
  font-size: clamp(34px, 4.5vw, 48px);
}

.page h2 {
  margin: 36px 0 8px;
  font-size: 24px;
}

.page p + p {
  margin-top: 12px;
}

.page .actions {
  margin-top: 32px;
}

/* Téléphone */

@media (max-width: 640px) {
  .accroche {
    gap: 40px;
    padding-block: 40px 56px;
  }

  .accroche-photos {
    height: auto;
    display: flex;
    flex-direction: column;
    gap: 20px;
  }

  .accroche-photo-1,
  .accroche-photo-2 {
    position: static;
    width: 88%;
  }

  .accroche-photo-2 {
    align-self: flex-end;
  }

  .tirage {
    transform: rotate(calc(var(--rotation) / 2));
  }

  .section {
    padding-block: 56px;
  }
}
```

- [ ] **Step 4 : Builder et vérifier la copie des ressources**

```bash
./run_local.sh build 2>&1 | tail -1
command ls _site/assets/css/main.css _site/assets/favicon.svg _site/assets/fonts/
```

Attendu : les fichiers listés, dont les trois `.woff2`.

- [ ] **Step 5 : Commit**

```bash
git add assets/fonts assets/favicon.svg assets/css/main.css
git commit -m "Add self-hosted fonts, favicon and stylesheet"
```

---

### Task 4 : Layout et JSON-LD

**Files:**
- Rewrite: `_layouts/default.html`
- Create: `_includes/jsonld.html`

- [ ] **Step 1 : Réécrire `_layouts/default.html`**

```html
<!DOCTYPE html>
<html lang="{{ site.lang }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#F3EDE3">
  {% seo %}
  <link rel="preload" href="{{ '/assets/fonts/fraunces-latin-wght-normal.woff2' | relative_url }}" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="{{ '/assets/fonts/work-sans-latin-wght-normal.woff2' | relative_url }}" as="font" type="font/woff2" crossorigin>
  <link rel="stylesheet" href="{{ '/assets/css/main.css' | relative_url }}">
  <link rel="icon" href="{{ '/assets/favicon.svg' | relative_url }}" type="image/svg+xml">
  {%- if page.url == "/" %}
  {% include jsonld.html %}
  {%- endif %}
</head>
<body>
  <a class="evitement" href="#contenu">Aller au contenu</a>
  <header class="conteneur entete">
    <a class="logotype" href="{{ '/' | relative_url }}">
      <span class="logotype-nom">Coworking</span>
      <span class="logotype-ville">Bourg-en-Bresse</span>
    </a>
    <nav class="menu" aria-label="Navigation principale">
      <a href="{{ '/#espaces' | relative_url }}">Espaces</a>
      <a href="{{ '/#tarifs' | relative_url }}">Tarifs</a>
      <a href="{{ '/#acces' | relative_url }}">Accès</a>
      <a class="bouton" href="{{ site.data.infos.lien_visite }}">Réserver une visite</a>
    </nav>
  </header>
  <main id="contenu">
    {{ content }}
  </main>
  <footer class="conteneur pied">
    <span>Géré par {{ site.data.infos.association }}, association loi 1901.</span>
    <nav aria-label="Liens secondaires">
      <a href="{{ site.data.infos.facebook }}">Facebook</a>
      <a href="{{ '/mentions-legales/' | relative_url }}">Mentions légales</a>
    </nav>
  </footer>
</body>
</html>
```

- [ ] **Step 2 : Créer `_includes/jsonld.html`**

```html
{%- assign infos = site.data.infos -%}
{%- assign prix = "" | split: "" -%}
{%- for groupe in site.data.tarifs -%}
  {%- assign prix_groupe = groupe.lignes | map: "prix" -%}
  {%- assign prix = prix | concat: prix_groupe -%}
{%- endfor -%}
{%- assign prix = prix | sort -%}
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": {{ infos.nom | jsonify }},
  "description": {{ site.description | jsonify }},
  "url": {{ site.url | jsonify }},
  "image": {{ "/assets/photo_openspace_1.jpg" | absolute_url | jsonify }},
  "telephone": {{ infos.telephone_international | jsonify }},
  "email": {{ infos.mail | jsonify }},
  "address": {
    "@type": "PostalAddress",
    "streetAddress": {{ infos.adresse.rue | jsonify }},
    "postalCode": {{ infos.adresse.code_postal | jsonify }},
    "addressLocality": {{ infos.adresse.ville | jsonify }},
    "addressCountry": "FR"
  },
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": {{ infos.geo.latitude }},
    "longitude": {{ infos.geo.longitude }}
  },
  "openingHours": {{ infos.horaires_schema | jsonify }},
  "priceRange": "{{ prix.first }} € – {{ prix.last }} €",
  "sameAs": [{{ infos.facebook | jsonify }}]
}
</script>
```

- [ ] **Step 3 : Builder**

```bash
./run_local.sh build 2>&1 | command grep -iE 'error|done'
```

Attendu : `done in …`, aucune ligne `Error`. (L'accueil est encore `index.md` : le JSON-LD n'est vérifié qu'en Task 5.)

- [ ] **Step 4 : Commit**

```bash
git add _layouts/default.html _includes/jsonld.html
git commit -m "New layout with header, footer and LocalBusiness JSON-LD"
```

---

### Task 5 : Page d'accueil, redirections, suppression de l'ancien site

**Files:**
- Create: `index.html`
- Delete: `index.md`, `about.md`, `presta.md`, `tarifs.md`, `acces.md`, `contacts.md`, `photos.md`, `_posts/`,
  `_layouts/index.html`, `_layouts/post.html`, `assets/Logo.jpg`, `assets/menage-ext-avant-apres.jpg`

- [ ] **Step 1 : Écrire la vérification (doit échouer)**

Créer `_scratch/check_home.sh` :

```bash
#!/usr/bin/env bash
# Scratch check of the built home page — not a permanent test.
set -u
site="_site"
fail=0

expect() {
    local file="$1"
    local pattern="$2"
    if ! command grep -q -- "${pattern}" "${site}/${file}"; then
        echo "MISSING in ${file}: ${pattern}"
        fail=1
    fi
}

expect index.html 'Votre bureau en plein centre de Bourg-en-Bresse'
expect index.html 'id="espaces"'
expect index.html 'id="tarifs"'
expect index.html 'id="acces"'
expect index.html '<dd>552&nbsp;€</dd>'
expect index.html '<dd>84&nbsp;€</dd>'
expect index.html 'Accès PMR'
expect index.html 'À 5 minutes à pied de la gare'
expect index.html 'Du lundi au vendredi, 8 h – 18 h'
expect index.html 'href="tel:+33610308068"'
expect index.html 'mailto:qg.coworkain@gmail.com?subject=Visite%20du%20coworking'
expect index.html '"@type": "LocalBusiness"'
expect index.html '<title>Coworking Bourg-en-Bresse | Bureaux partagés en centre-ville</title>'
for old in tarifs.html presta.html apropos/index.html acces.html contacts.html photos.html \
    2019/09/06/inauguration.html 2021/09/06/menage.html; do
    expect "${old}" 'url=https://www.coworking-bourg.fr/'
done
if command grep -qi 'vidéo' "${site}/index.html"; then
    echo "UNEXPECTED: vidéoprojecteur still listed"
    fail=1
fi
[ "${fail}" -eq 0 ] && echo "OK"
exit "${fail}"
```

```bash
mkdir -p _scratch && chmod +x _scratch/check_home.sh
./run_local.sh build >/dev/null 2>&1; _scratch/check_home.sh
```

Attendu : plusieurs lignes `MISSING …`, code de sortie 1.

- [ ] **Step 2 : Créer `index.html`**

```html
---
layout: default
image: /assets/photo_openspace_1.jpg
redirect_from:
  - /tarifs.html
  - /presta.html
  - /apropos/
  - /acces.html
  - /contacts.html
  - /photos.html
  - /2019/09/06/inauguration.html
  - /2021/09/06/menage.html
---
{%- assign infos = site.data.infos -%}
<section class="conteneur accroche">
  <div class="accroche-texte">
    <p class="surtitre">Un lieu de travail tenu par ceux qui y travaillent</p>
    <h1>Votre bureau en plein centre de Bourg-en-Bresse, à deux pas de la gare.</h1>
    <p class="accroche-intro">{{ infos.surface }} partagés pour freelances, indépendants et télétravailleurs. À la journée, au mois, ou pour une réunion.</p>
    <div class="actions">
      <a class="bouton bouton-grand" href="{{ infos.lien_visite }}">Réserver une visite</a>
      <a class="lien-tel" href="tel:{{ infos.telephone_international }}">ou appelez le {{ infos.telephone }}</a>
    </div>
  </div>
  <div class="accroche-photos">
    <figure class="tirage tirage-gauche accroche-photo-1">
      <img src="{{ '/assets/photo_openspace_1.jpg' | relative_url }}" alt="L'open space, son mur rouge et ses grandes tables" width="500" height="333">
      <figcaption>l'open space</figcaption>
    </figure>
    <figure class="tirage tirage-droite accroche-photo-2">
      <img src="{{ '/assets/photo_tasse.jpg' | relative_url }}" alt="Une tasse de café posée sur un bureau" width="500" height="333">
      <figcaption>le café est inclus</figcaption>
    </figure>
  </div>
</section>

<section class="bande" aria-label="Pourquoi venir ici">
  <div class="conteneur arguments">
    <div>
      <h2>Au cœur de la ville</h2>
      <p>À {{ infos.gare_a_pied }} à pied de la gare, entre les commerces et les cafés du centre.</p>
    </div>
    <div>
      <h2>À votre rythme</h2>
      <p>Une demi-journée pour essayer, un poste au mois, ou un bureau à vous.</p>
    </div>
    <div>
      <h2>Entre collègues</h2>
      <p>Une association gérée par ses coworkers : des prix justes et une vraie vie de bureau.</p>
    </div>
  </div>
</section>

<section id="espaces" class="conteneur section espaces">
  <div class="espaces-texte">
    <h2 class="titre-section">Les espaces</h2>
    <ul class="liste-espaces">
      <li>
        <h3>L'open space</h3>
        <p>Un poste parmi les autres coworkers, pour une demi-journée ou au mois.</p>
      </li>
      <li>
        <h3>Les bureaux privatifs</h3>
        <p>Une pièce fermée pour vous ou votre équipe, louée au mois.</p>
      </li>
      <li>
        <h3>La salle de réunion</h3>
        <p>Pour vos rendez-vous clients, formations et ateliers, à la demi-journée ou à la journée.</p>
      </li>
      <li>
        <h3>Cuisine et salle de repos</h3>
        <p>Pour déjeuner, faire une pause café et souffler entre deux rendez-vous.</p>
      </li>
    </ul>
  </div>
  <div class="espaces-photos">
    <figure class="tirage tirage-droite">
      <img src="{{ '/assets/photo_bureau_jaune.jpg' | relative_url }}" alt="Un coworker à son poste, près de la fenêtre" width="500" height="333" loading="lazy">
      <figcaption>un poste près de la fenêtre</figcaption>
    </figure>
    <figure class="tirage tirage-gauche">
      <img src="{{ '/assets/photo_bureau_orange.jpg' | relative_url }}" alt="Deux coworkers dans un bureau au mur orange" width="500" height="281" loading="lazy">
      <figcaption>un bureau à deux</figcaption>
    </figure>
  </div>
</section>

<section id="tarifs" class="conteneur section tarifs">
  <div class="tarifs-intro">
    <h2 class="titre-section">Tarifs</h2>
    <p class="doux">Tous les prix sont TTC. Inclus dans chaque formule :</p>
    <ul class="services">
      {%- for service in site.data.services %}
      <li>{{ service }}</li>
      {%- endfor %}
    </ul>
    <figure class="tirage tirage-gauche">
      <img src="{{ '/assets/photo_bureau_mauve.jpg' | relative_url }}" alt="Un bureau privatif au mur framboise" width="500" height="333" loading="lazy">
    </figure>
  </div>
  <div class="tarifs-liste">
    {%- for groupe in site.data.tarifs %}
    <div class="groupe-tarif">
      <h3>{{ groupe.groupe }}</h3>
      <dl>
        {%- for ligne in groupe.lignes %}
        <div class="ligne-tarif">
          <dt>{{ ligne.libelle }}</dt>
          <dd>{{ ligne.prix }}&nbsp;€</dd>
        </div>
        {%- endfor %}
      </dl>
    </div>
    {%- endfor %}
  </div>
</section>

<section id="acces" class="sombre">
  <div class="conteneur acces">
    <div class="acces-texte">
      <h2 class="titre-section">Venez prendre un café avec nous.</h2>
      <address>{{ infos.adresse.rue }}, {{ infos.adresse.code_postal }} {{ infos.adresse.ville }}</address>
      <p>{{ infos.horaires }}.<br>À {{ infos.gare_a_pied }} à pied de la gare. On vient aussi à vélo ou en voiture.</p>
      <p><a href="{{ infos.carte }}">Voir sur la carte</a></p>
    </div>
    <div class="acces-contacts">
      <a class="bouton bouton-clair" href="{{ infos.lien_visite }}">{{ infos.mail }}</a>
      <a class="bouton bouton-contour" href="tel:{{ infos.telephone_international }}">{{ infos.telephone }}</a>
    </div>
  </div>
</section>
```

- [ ] **Step 3 : Supprimer l'ancien contenu**

```bash
git rm -q index.md about.md presta.md tarifs.md acces.md contacts.md photos.md
git rm -q -r _posts
git rm -q _layouts/index.html _layouts/post.html assets/Logo.jpg assets/menage-ext-avant-apres.jpg
```

- [ ] **Step 4 : Builder et relancer la vérification (doit passer)**

```bash
./run_local.sh build 2>&1 | command grep -iE 'error|done'
_scratch/check_home.sh
```

Attendu : `done in …` puis `OK`. En cas de `MISSING` sur une redirection : vérifier le chemin exact généré avec
`command ls _site/2019/09/06/` (le chemin doit correspondre à l'ancienne URL).

- [ ] **Step 5 : Valider le JSON-LD**

```bash
python3 -I -c '
import json, re
html = open("_site/index.html", encoding="utf-8").read()
for block in re.findall(r"<script type=\"application/ld\+json\">(.*?)</script>", html, re.S):
    data = json.loads(block)
    print(data["@type"], data.get("priceRange", ""))
'
```

Attendu : une ligne produite par `jekyll-seo-tag` (`WebSite` ou `WebPage`) et `LocalBusiness 7 € – 552 €`.

- [ ] **Step 6 : Commit**

```bash
git add index.html
git commit -m "New single-page home with redirects from the old URLs"
```

---

### Task 6 : Mentions légales et 404

**Files:**
- Create: `mentions-legales.md`
- Rewrite: `404.html`

- [ ] **Step 1 : Créer `mentions-legales.md`**

```markdown
---
layout: default
title: Mentions légales
permalink: /mentions-legales/
---
{%- assign infos = site.data.infos -%}
<div class="conteneur page" markdown="1">

# Mentions légales

## Éditeur

Ce site est édité par {{ infos.association }}, association loi 1901,
{{ infos.adresse.rue }}, {{ infos.adresse.code_postal }} {{ infos.adresse.ville }}.

Contact : [{{ infos.mail }}](mailto:{{ infos.mail }}) · [{{ infos.telephone }}](tel:{{ infos.telephone_international }})

## Responsable de la publication

{{ infos.responsable_publication }}

## Hébergement

GitHub Inc., 88 Colin P. Kelly Jr. Street, San Francisco, CA 94107, États-Unis
([https://pages.github.com](https://pages.github.com)).

## Données personnelles et cookies

Ce site ne dépose aucun cookie et n'utilise aucun outil de mesure d'audience. Les polices de caractères sont
hébergées sur le site lui-même.

Comme tout hébergeur, GitHub peut conserver des journaux techniques, dont l'adresse IP des visiteurs : voir sa
[déclaration de confidentialité](https://docs.github.com/fr/site-policy/privacy-policies/github-general-privacy-statement).

Les informations que vous nous transmettez par mail ou par téléphone servent uniquement à répondre à votre demande.

## Crédits

Polices Fraunces et Work Sans, sous licence SIL Open Font License 1.1.

</div>
```

- [ ] **Step 2 : Réécrire `404.html`**

```html
---
layout: default
title: Page introuvable
permalink: /404.html
sitemap: false
---
<div class="conteneur page">
  <h1>Page introuvable</h1>
  <p class="doux">Cette page n'existe pas ou plus. Le coworking, lui, est toujours là.</p>
  <div class="actions">
    <a class="bouton" href="{{ '/' | relative_url }}">Retour à l'accueil</a>
  </div>
</div>
```

- [ ] **Step 3 : Builder et vérifier**

```bash
./run_local.sh build 2>&1 | command grep -iE 'error|done'
command grep -c -E 'Nicolas Baccelli|GitHub Inc\.' _site/mentions-legales/index.html
command grep -o '<h1[^>]*>[^<]*</h1>' _site/mentions-legales/index.html _site/404.html
command grep -c 'mentions-legales' _site/sitemap.xml
command grep -c '404' _site/sitemap.xml
```

Attendu : `done …` ; `2` ; `<h1 id="mentions-légales">Mentions légales</h1>` (l'`id` peut varier) et
`<h1>Page introuvable</h1>` ; `1` ; `0`.

- [ ] **Step 4 : Commit**

```bash
git add mentions-legales.md 404.html
git commit -m "Add legal notice and French 404 page"
```

---

### Task 7 : Nettoyage CI et README

**Files:**
- Delete: `action.yml`, `.github/workflows/jekyll-docker.yml`
- Rewrite: `README.md`

- [ ] **Step 1 : Vérifier le mode de déploiement GitHub Pages**

```bash
gh api repos/chocobn69/coworking-bourg/pages --jq '.build_type, .source.branch'
```

Attendu : `legacy` et `master` (= « Deploy from a branch » ; constaté le 2026-10-20). **Si la sortie est `workflow`, ne pas supprimer le
workflow : arrêter et signaler à Nicolas.**

- [ ] **Step 2 : Supprimer les fichiers CI inutiles**

```bash
git rm -q action.yml .github/workflows/jekyll-docker.yml
```

- [ ] **Step 3 : Réécrire `README.md`**

````markdown
# coworking-bourg

Site de l'espace de coworking de Bourg-en-Bresse : https://www.coworking-bourg.fr

Hébergé par GitHub Pages : chaque push sur `master` met le site en ligne.

## Modifier le contenu

| Quoi | Où |
|---|---|
| Tarifs | `_data/tarifs.yml` |
| Services inclus | `_data/services.yml` |
| Adresse, téléphone, mail, horaires | `_data/infos.yml` |
| Textes de la page d'accueil | `index.html` |
| Couleurs, typo, mise en page | `assets/css/main.css` |

Ces fichiers peuvent être modifiés directement depuis l'interface web de GitHub.

## Lancer le site en local

Seul Docker est nécessaire.

```sh
./run_local.sh          # http://localhost:4000
./run_local.sh build    # génère _site/
```
````

- [ ] **Step 4 : Commit**

```bash
git add README.md
git commit -m "Remove unused CI files, document how to edit the site"
```

---

### Task 8 : Vérification finale et PR

- [ ] **Step 1 : Build propre**

```bash
command rm -rf _site .jekyll-cache
./run_local.sh build 2>&1 | command grep -iE 'warn|error|done'
_scratch/check_home.sh
```

Attendu : `done …` (seul avertissement toléré : « GitHub Metadata: No GitHub API authentication ») puis `OK`.

- [ ] **Step 2 : Aucune ressource chargée depuis un domaine tiers**

```bash
command grep -hoE '(src|href)="https?://[^"]+"' _site/index.html _site/mentions-legales/index.html | sort -u
command grep -hoE '<link[^>]+>' _site/index.html | command grep -E 'href="https?://' | command grep -v canonical
```

Attendu, 1re commande : uniquement des liens de navigation (`facebook.com`, `openstreetmap.org`, `pages.github.com`,
`docs.github.com`) et l'URL canonique `https://www.coworking-bourg.fr/…` ; aucun `src="https://…"`. 2e commande : aucune sortie.

- [ ] **Step 3 : Liens internes valides**

```bash
python3 -I -c '
import pathlib, re
site = pathlib.Path("_site")
pages = [site / "index.html", site / "mentions-legales" / "index.html", site / "404.html"]
ids = set(re.findall(r"id=\"([^\"]+)\"", (site / "index.html").read_text(encoding="utf-8")))
bad = []
for page in pages:
    for href in re.findall(r"(?:href|src)=\"(/[^\"]*)\"", page.read_text(encoding="utf-8")):
        path, _, anchor = href.partition("#")
        target = site / path.lstrip("/")
        if target.is_dir():
            target = target / "index.html"
        if not target.exists():
            bad.append(f"{page}: {href}")
        if anchor and anchor not in ids:
            bad.append(f"{page}: #{anchor}")
print("\n".join(bad) or "OK")
'
```

Attendu : `OK`.

- [ ] **Step 4 : Captures mobile et bureau**

```bash
(cd _site && python3 -m http.server 4000 >/dev/null 2>&1 &)
google-chrome-stable --headless=new --disable-gpu --hide-scrollbars --window-size=390,4600 --screenshot="$PWD/_scratch/mobile.png" http://localhost:4000/ 2>/dev/null
google-chrome-stable --headless=new --disable-gpu --hide-scrollbars --window-size=1280,3000 --screenshot="$PWD/_scratch/bureau.png" http://localhost:4000/ 2>/dev/null
google-chrome-stable --headless=new --disable-gpu --hide-scrollbars --window-size=1280,1000 --screenshot="$PWD/_scratch/404.png" http://localhost:4000/404.html 2>/dev/null
pkill -f 'http.server 4000'
```

Lire les trois PNG (outil Read) et vérifier : pas de défilement horizontal ni de texte coupé à 390 px, tirages
empilés à 390 px, polices Fraunces/Work Sans chargées (titres à empattements, pas Georgia), pointillés des tarifs
visibles, bandeau sombre lisible. Corriger le CSS si besoin, rebuild, recommencer.

Puis montrer les captures à Nicolas :

```bash
(setsid xdg-open _scratch/mobile.png >/dev/null 2>&1 &)
(setsid xdg-open _scratch/bureau.png >/dev/null 2>&1 &)
```

et afficher leurs chemins absolus, chacun sur sa ligne.

- [ ] **Step 5 : Pousser la branche et ouvrir la PR (après accord de Nicolas)**

```bash
git push -u origin refonte
gh pr create --base master --head refonte --title "Refonte complète du site" --body "$(command cat <<'EOF'
Refonte du design et du contenu selon `docs/superpowers/specs/2026-10-20-refonte-site-design.md`.

- Design « Atelier chaleureux » sur mesure (plus de thème Cayman), sans JavaScript, polices auto-hébergées
- Contenu orienté prospects : accroche, espaces, tarifs TTC (salle de réunion de retour), accès, contact
- Données éditables dans `_data/` (tarifs, services, infos pratiques)
- Mentions légales, 404 en français, JSON-LD LocalBusiness
- Anciennes URL redirigées vers l'accueil ; billets 2019/2021 et pages vides supprimés
- Build local via Docker (`./run_local.sh`), CI Docker et `action.yml` supprimés

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Ne jamais fusionner : Nicolas fusionne lui-même.
