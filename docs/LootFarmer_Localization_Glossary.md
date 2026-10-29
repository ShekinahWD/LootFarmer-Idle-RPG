# LootFarmer — Localization Glossary (Batch 01: es-419, es-ES, pt-BR, fr-FR, de-DE)

Game-specific terminology decisions for the runtime catalogs in `localization/`. The English catalog (`localization/en.po`) is the source of truth. Batches 02–04 add their columns here.

## Not translated (brand and proper nouns)

| Text | Where | Rule |
|---|---|---|
| LootFarmer | everywhere | Product name, never translated or declined. |
| `LootFarmer - Idle RPG`, `LOOTFARMER · IDLE RPG` | `APP_TITLE`, `GAME_TITLE` | Store title kept as the product name. |
| Google Play, itch.io | review buttons | Storefront names. |
| Pixel Plains, SnowHex, Kenney Fantasy UI Borders, CC0 | `CREDITS` | Credited works and licence. |

The exact entries that equal their English text are listed per locale and key in `tools/localization_allowlist.json` (brand, abbreviation, cognate or loanword). `tools/validate_localization.py` fails on any other copy-through.

## Core terms

The **same game concept keeps the same word** across every screen of a language, and distinct mechanics keep distinct words: merge, evolve, upgrade and mastery never share a translation.

| English | es-419 | es-ES | pt-BR | fr-FR | de-DE |
|---|---|---|---|---|---|
| Coins / Gems | Monedas / Gemas | Monedas / Gemas | Moedas / Gemas | Pièces / Gemmes | Münzen / Edelsteine |
| Gear (equipment) | equipo | equipo | equipamento | équipement | Ausrüstung |
| Weapon / Outfit | arma / atuendo | arma / atuendo | arma / traje | arme / tenue | Waffe / Kostüm |
| Supplies (consumables) | suministros | suministros | suprimentos | consommables | Vorräte |
| Merge (copy into item) | fusionar · fusión | fusionar · fusión | fundir · fusão | fusionner · fusion | verschmelzen · Verschmelzung |
| Evolve (^100 + 101 copies → next tier) | evolucionar | evolucionar | evoluir | faire évoluer | weiterentwickeln |
| Upgrade (bought) | mejora | mejora | melhoria | amélioration | Upgrade |
| Supply Mastery (uses) | Maestría de suministros | Maestría de suministros | Maestria de Suprimentos | Maîtrise des consommables | Vorratsmeisterschaft |
| Map Mastery | Maestría del mapa | Maestría del mapa | Maestria do Mapa | Maîtrise des cartes | Kartenmeisterschaft |
| Prestige | Prestigio | Prestigio | Prestígio | Prestige | Prestige |
| Opportunity / card | oportunidad / carta | oportunidad / carta | oportunidade / carta | opportunité / carte | Gelegenheit / Karte |
| Mission / Main objective | misión / objetivo principal | misión / objetivo principal | missão / objetivo principal | mission / objectif principal | Mission / Hauptziel |
| Claim | Reclamar | Reclamar | Resgatar | Récupérer | Abholen |
| Camp / respawn | campamento / reaparecer | campamento / reaparecer | acampamento / renascer | camp / réapparaître | Lager / respawnen |
| Farm (verb) | farmear | farmear | farmar | farmer | farmen |
| Boss | jefe | jefe | chefe | boss | Boss |
| Skill / cooldown | habilidad / enfriamiento | habilidad / enfriamiento | habilidade / recarga | compétence / recharge | Fähigkeit / Abklingzeit |
| Loot / drop | botín | botín | saque · drop | butin | Beute · Drop |
| Tier (item) | nivel | nivel | nível | rang | Rang |
| Stage (map) | etapa | etapa | fase | zone | Gebiet |
| Run (between Prestiges) | partida | partida | partida | partie | Durchlauf |
| HP / XP | PV / EXP | PV / EXP | PV / XP | PV / XP | LP / EP |
| Target (drag from the hero) | apuntar · fijar como objetivo | apuntar · fijar como objetivo | mirar · marcar como alvo | cibler | anvisieren |
| Honest review | reseña honesta | reseña sincera | avaliação sincera | avis sincère | ehrliche Bewertung |

## Register and regional variants

- **es-419:** tú; neutral Latin-American vocabulary; *toca*, *recolectar*, *Configuración*, preterite for recent events (*Derrotaste*), *costo*, *Lentes de Sol*, *Gorro de Santa*, *Gorro de Hongo*, decimal point, `1,000`. "coger" is never used.
- **es-ES:** tú; *pulsa*, *recoger*, *Ajustes*, present perfect for recent events (*Has derrotado*), *coste*, *Gafas de Sol*, *Gorro de Papá Noel*, *Gorro de Seta*, *¡Vale!*, *Valorar en Google Play*, decimal comma, `1000`. Derived from es-419 by reviewed rules plus 58 hand-written overrides; 185 of 1,941 entries differ.
- **pt-BR:** você; Brazilian gaming loanwords *farmar*, *drop*, *offline*; never European Portuguese forms (*ecrã*, *telemóvel*, *tu*).
- **fr-FR:** vous; narrow no-break space before `: ; ? !` and no-break space before `%`; *boss* and *farmer* as used by French players.
- **de-DE:** du; compounds for item names (*Blaukappen-Kostüm*, *Rotschal-Schwert*); *Upgrades*, *Boss*, *Drop*, *Respawn* as established German gaming terms.

## Names

Enemy, boss, stage, skill and item names are translated descriptively. Each item name is built from its enemy's name, so the two always match: es *Atuendo de Gorra Azul*, pt *Traje de Boné Azul*, fr *Tenue de Casquette Bleue* (elided *d’* before a vowel), de *Blaukappen-Kostüm*. The "Plain" enemy's gear uses an adjective (*Espada sencilla*, *Épée sobre*, *Schlichtes Schwert*). The Grim Reaper is *La Parca* / *Ceifador* / *La Faucheuse* / *Sensenmann*.

## Formatting rules

- Placeholders keep the English **order**: GDScript's `%` operator has no positional arguments. Count and type are checked by the validator. Order was reviewed by hand for the 106 entries with repeated `%s`/`%d`.
- Compact numbers (`1.2K`, `3.4M`) and the merge level (`^25`) are the same in every language, as players read them in idle games; decimals inside sentences follow the locale.
- A number or numeric placeholder is glued to the word after it with a no-break space ("12 s", "5 Minuten"), so units never start a line.
- Durations use `DURATION_*` keys (`1 h 05 min`, `1 Std. 05 Min.`).
- Plural forms: the English source has none. Translations use count-neutral wording or `(s)` the same way the source does.
- Language names in Settings are shown in the current UI language, matching the English catalog. Autonyms (*Deutsch*, *日本語*) wait for the global gate, when the CJK, Thai and Devanagari font fallbacks exist; DejaVu Sans would draw those scripts as empty boxes.
