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

Contact&nbsp;: [{{ infos.mail }}](mailto:{{ infos.mail }}) · [{{ infos.telephone }}](tel:{{ infos.telephone_international }})

## Responsable de la publication

{{ infos.responsable_publication }}

## Hébergement

GitHub Inc., 88 Colin P. Kelly Jr. Street, San Francisco, CA 94107, États-Unis
Tél.&nbsp;: +1 877 448 4820 ([https://pages.github.com](https://pages.github.com)).

## Données personnelles et cookies

Ce site ne dépose aucun cookie et n'utilise aucun outil de mesure d'audience. Les polices de caractères sont
hébergées sur le site lui-même.

Comme tout hébergeur, GitHub peut conserver des journaux techniques, dont l'adresse IP des visiteurs&nbsp;: voir sa
[déclaration de confidentialité](https://docs.github.com/fr/site-policy/privacy-policies/github-general-privacy-statement).

Les informations que vous nous transmettez par mail ou par téléphone servent uniquement à répondre à votre demande.
Vous pouvez demander à les consulter ou à les supprimer en écrivant à [{{ infos.mail }}](mailto:{{ infos.mail }}),
et adresser une réclamation à la CNIL ([https://www.cnil.fr](https://www.cnil.fr)).

## Crédits

Polices Fraunces et Work Sans, sous licence SIL Open Font License 1.1.

</div>
