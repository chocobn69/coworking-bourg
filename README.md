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
| Questions fréquentes | `_includes/faq.html` |
| Pages open space, bureaux privatifs, salle de réunion | `open-space.html`, `bureaux-privatifs.html`, `salle-de-reunion.html` (en-tête du fichier) |
| Couleurs, typo, mise en page | `assets/css/main.css` |

Ces fichiers peuvent être modifiés directement depuis l'interface web de GitHub.

## Lancer le site en local

Seul Docker est nécessaire.

```sh
./run_local.sh          # http://localhost:4000
./run_local.sh build    # génère _site/
```
