# Refonte du site coworking-bourg.fr — design

Date : 2026-10-20
Maquette validée : https://claude.ai/artifact/UfUdnGVTAyH3WjLYfZAexa (artboard « 2. Atelier chaleureux »)

## Objectif

Attirer de nouveaux coworkers. Le site doit donner envie, afficher des tarifs clairs et pousser vers une seule action :
réserver une visite par mail ou téléphone. Zéro service tiers, maintenance minimale.

## Décisions

| Sujet | Décision |
|---|---|
| Nom mis en avant | « Coworking Bourg-en-Bresse » ; Cowork'Ain apparaît comme association gestionnaire |
| Identité | Nouvelle, l'ancien logo « Le QG » disparaît |
| Direction visuelle | « Atelier chaleureux » : fond papier, Fraunces + Work Sans, accent brique |
| Photos | Les 5 photos existantes (500 px), en vignettes « tirages », pas de photo plein écran |
| Appel à l'action | `mailto:` pré-rempli + `tel:` cliquable |
| Actualités | Supprimées (billets 2019 et 2021 retirés) |
| Technique | Jekyll sur GitHub Pages, sans thème, design maison, données dans `_data/` |

## Contenu

### Infos pratiques (`_data/infos.yml`)

| Champ | Valeur | Statut |
|---|---|---|
| Adresse | 14 rue du Général Logerot, 01000 Bourg-en-Bresse | à vérifier (`about.md` disait 13) |
| Téléphone | 06 10 30 80 68 | à vérifier (qui répond ?) |
| Mail | qg.coworkain@gmail.com | à vérifier |
| Facebook | https://www.facebook.com/LeQGBourgenBresse/ | à vérifier |
| Surface | 130 m² | à vérifier |
| Temps à pied depuis la gare | inconnu | à fournir |
| Horaires / mode d'accès | inconnu | à fournir |
| Engagement minimum sur les formules au mois | inconnu | à fournir |

Tant qu'une valeur « à fournir » est vide, le gabarit n'affiche pas la phrase qui la contient (pas de `[X]` en
production).

### Tarifs (`_data/tarifs.yml`, tous TTC)

- À la carte : demi-journée 7 €, journée 14 €
- Au mois : poste en open space 117 €, bureau privatif 552 €
- Salle de réunion : demi-journée 42 €, journée 84 €

### Services inclus (`_data/services.yml`)

Fibre filaire et wifi, café, imprimante, cuisine, salle de repos, accès PMR. Le prêt de vidéoprojecteur est retiré.

### Page d'accueil, dans l'ordre

1. **En-tête** — logotype texte « Coworking *Bourg-en-Bresse* », menu Espaces · Tarifs · Accès, bouton « Réserver une visite ».
2. **Accroche** — surtitre « Un lieu de travail tenu par ceux qui y travaillent » ; H1 « Votre bureau en plein centre de
   Bourg-en-Bresse, à deux pas de la gare. » ; sous-titre « 130 m² partagés pour freelances, indépendants et
   télétravailleurs. À la journée, au mois, ou pour une réunion. » ; bouton mail + lien téléphone ; deux tirages
   photo inclinés (open space, tasse).
3. **Pourquoi ici** — trois blocs : Au cœur de la ville / À votre rythme / Entre collègues.
4. **Espaces** — open space, bureaux privatifs, salle de réunion, cuisine et salle de repos ; une vignette « tirage »
   et une phrase chacun.
5. **Tarifs** — liste façon carte de café (libellé, pointillés, prix), mention TTC et services inclus.
6. **Accès / contact** — bandeau sombre « Venez prendre un café avec nous. », adresse, horaires, lien
   OpenStreetMap (pas d'iframe de carte : évite un bandeau cookies), boutons mail et téléphone.
7. **Pied de page** — « Géré par Cowork'Ain, association loi 1901. », Facebook, mentions légales.

### Autres pages

- `mentions-legales.md` — éditeur (Cowork'Ain, association loi 1901, adresse), responsable de publication
  (à fournir), hébergeur (GitHub Inc., 88 Colin P. Kelly Jr. Street, San Francisco, CA 94107, USA), absence de
  cookies et de traceurs.
- `404.html` — en français, même style, lien vers l'accueil.

## Design

- Couleurs (variables CSS) : papier `#F3EDE3`, papier foncé `#E9E0D2`, encre `#2B2622`, texte secondaire `#4A423B`,
  brique `#9E3A26`, pointillés `#B8A992`. Contraste texte ≥ 4.5:1.
- Typo : Fraunces (titres, italique pour surtitres et légendes), Work Sans (texte), hébergées localement en woff2
  (sous-ensemble latin, licence OFL). Aucun appel à Google Fonts.
- Tirages photo : cadre blanc, légende en Fraunces italique, rotation de −4° à +4°. Sur mobile (< 640 px) les tirages
  de l'accroche s'empilent et la rotation est réduite.
- Menu : ligne qui passe à la ligne en mobile, pas de menu hamburger. Cibles tactiles ≥ 44 px.
- Aucun JavaScript.
- Favicon SVG : « C » Fraunces brique sur fond papier.

## Architecture

```
_config.yml              sans thème ; plugins : jekyll-seo-tag, jekyll-sitemap, jekyll-redirect-from ; exclude docs/, README.md, run_local.sh
Gemfile                  uniquement github-pages
_data/infos.yml
_data/tarifs.yml
_data/services.yml
_layouts/default.html    head (seo, preload polices, css), en-tête, pied de page
_includes/jsonld.html    LocalBusiness généré depuis _data
index.html               sections de l'accueil, boucles Liquid sur _data ; redirect_from des anciennes URL
mentions-legales.md
404.html
assets/css/main.css
assets/fonts/*.woff2
assets/favicon.svg
```

Redirections vers `/` : `/tarifs.html`, `/presta.html`, `/apropos/`, `/2019/09/06/inauguration.html`,
`/2021/09/06/menage.html`.

`_config.yml` : `email` corrigé, `twitter_username` supprimé, `description` réécrite, `lang: fr` conservé.

### Supprimé

`_posts/`, `_layouts/index.html`, `_layouts/post.html`, `about.md`, `presta.md`, `tarifs.md`, `acces.md`,
`contacts.md`, `photos.md`, `assets/Logo.jpg`, `assets/menage-ext-avant-apres.jpg`, `assets/css/style.scss`,
`action.yml`, `.github/workflows/jekyll-docker.yml`.

Prérequis : GitHub › Settings › Pages doit être en « Deploy from a branch » (`master`). Sinon, garder un workflow de
déploiement.

## SEO

- `<title>` : « Coworking Bourg-en-Bresse — bureaux partagés en centre-ville ».
- JSON-LD `LocalBusiness` : nom, adresse, téléphone, mail, URL, horaires (si renseignés), `priceRange`.
- `google-site-verification` existant conservé.
- Sitemap via `jekyll-sitemap`.

## Vérification

- `jekyll build` sans erreur ni avertissement.
- Liens internes et ancres valides ; anciennes URL qui redirigent bien.
- Rendu contrôlé à 390 px et 1280 px (captures).
- JSON-LD valide (validateur schema.org).
- Aucune requête réseau vers un domaine tiers au chargement de la page.

## Livraison

Branche `refonte`, PR GitHub, merge par Nicolas.

## Hors périmètre

Nouvelles photos, formulaire de contact, réservation en ligne, blog, mode sombre, version anglaise.
