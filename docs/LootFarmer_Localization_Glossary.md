# LootFarmer — Localization Glossary (Batches 01–02)

Game-specific terminology decisions for the runtime catalogs in `localization/`. The English catalog (`localization/en.po`) is the source of truth. Batch 01 (Change 38): es-419, es-ES, pt-BR, fr-FR, de-DE. Batch 02 (Change 39): it-IT, nl-NL, pl-PL, ru-RU, uk-UA. Batches 03–04 add their columns here.

## Not translated (brand and proper nouns)

| Text | Where | Rule |
|---|---|---|
| LootFarmer | everywhere | Product name, never translated or declined (ru «в LootFarmer», pl „w LootFarmer”). |
| `LootFarmer - Idle RPG`, `LOOTFARMER · IDLE RPG` | `APP_TITLE`, `GAME_TITLE` | Store title kept as the product name. |
| Google Play, itch.io | review buttons | Storefront names. |
| Pixel Plains, SnowHex, Kenney Fantasy UI Borders, CC0 | `CREDITS` | Credited works and licence. |

The exact entries that equal their English text are listed per locale and key in `tools/localization_allowlist.json` (brand, abbreviation, cognate or loanword). `tools/validate_localization.py` fails on any other copy-through. Batch 02 counts: it 12, nl 38, pl 10, ru 2, uk 2.

## Core terms

The **same game concept keeps the same word** across every screen of a language, and distinct mechanics keep distinct words: merge, evolve, upgrade and mastery never share a translation.

### Batch 01

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

### Batch 02

| English | it-IT | nl-NL | pl-PL | ru-RU | uk-UA |
|---|---|---|---|---|---|
| Coins / Gems | Monete / Gemme | Munten / Edelstenen | Monety / Klejnoty | Монеты / Самоцветы | Монети / Самоцвіти |
| Gear (equipment) | equipaggiamento | uitrusting | sprzęt | снаряжение | спорядження |
| Inventory | inventario | inventaris | ekwipunek | инвентарь | інвентар |
| Weapon / Outfit | arma / costume | wapen / outfit | broń / strój | оружие / костюм | зброя / вбрання |
| Supplies (consumables) | provviste | voorraad | zapasy | припасы | припаси |
| Slot | slot | vak (*slot* means "lock") | slot | ячейка | комірка |
| Merge (copy into item) | fondere · fusione | samenvoegen · samenvoeging | połączyć · łączenie | объединить · объединение | поєднати · поєднання |
| Evolve | far evolvere · evoluzione | evolueren · evolutie | przeprowadzić ewolucję · ewolucja | эволюция | еволюція |
| Upgrade (bought) | potenziamento | upgrade | ulepszenie | улучшение | покращення |
| Spare copy | copia extra | extra exemplaar | dodatkowa kopia | лишняя копия | зайва копія |
| Supply Mastery | Maestria delle provviste | Voorraadmeesterschap | Mistrzostwo zapasów | мастерство припасов | майстерність припасів |
| Map Mastery | Maestria delle mappe | Kaartmeesterschap | Mistrzostwo map | мастерство карт | майстерність мап |
| Prestige | Prestigio | Prestige | Prestiż | престиж | престиж |
| Opportunity / card | opportunità / carta | kans / kaart | okazja / karta | возможность / карточка | нагода / картка |
| Mission / Main objective | missione / obiettivo principale | missie / hoofddoel | misja / cel główny | задание / главная цель | місія / головна ціль |
| Claim | Riscuoti | Ophalen | Odbierz | Забрать | Отримати |
| Camp / respawn | campo / rinascere | kamp / respawnen | obóz / odrodzić się | лагерь / возрождение | табір / відродження |
| View Camp | Vedi campo | Kamp bekijken | Pokaż obóz | Осмотреть лагерь | Переглянути табір |
| Farm (verb) | farmare | farmen | farmić | фармить | фармити |
| Boss | boss | baas (pl. bazen) | boss (pl. bossowie) | босс | бос |
| Skill / cooldown | abilità / ricarica | vaardigheid / afkoeltijd | umiejętność / odnowienie | навык / перезарядка | навичка / перезарядка |
| Cast a skill | lanciare | gebruiken | rzucić | применить | застосувати |
| Loot / drop | bottino · drop | buit · drop | łup · drop | добыча · дроп | здобич · випадіння |
| Tier (item) | grado | rang | ranga | ранг | ранг |
| Stage (map) | zona | gebied | etap | этап | етап |
| Map | mappa | kaart | mapa | карта | мапа |
| Run (between Prestiges) | partita | run | rozgrywka | забег | забіг |
| HP / XP | PS / PE | HP / XP | PŻ / PD | ОЗ / опыт | ОЗ / досвід |
| Tap | Tocca | Tik | Dotknij | Нажми | Торкнись |
| Target (drag from the hero) | prendere di mira | als doelwit kiezen | wybrać jako cel | выбрать целью | обрати ціллю |
| Honest review | recensione sincera | eerlijke review | szczera recenzja | честный отзыв | чесний відгук |

## Register and regional variants

- **es-419:** tú; neutral Latin-American vocabulary; *toca*, *recolectar*, *Configuración*, preterite for recent events (*Derrotaste*), *costo*, *Lentes de Sol*, *Gorro de Santa*, *Gorro de Hongo*, decimal point, `1,000`. "coger" is never used.
- **es-ES:** tú; *pulsa*, *recoger*, *Ajustes*, present perfect for recent events (*Has derrotado*), *coste*, *Gafas de Sol*, *Gorro de Papá Noel*, *Gorro de Seta*, *¡Vale!*, *Valorar en Google Play*, decimal comma, `1000`. Derived from es-419 by reviewed rules plus 58 hand-written overrides; 185 of 1,941 entries differ.
- **pt-BR:** você; Brazilian gaming loanwords *farmar*, *drop*, *offline*; never European Portuguese forms (*ecrã*, *telemóvel*, *tu*).
- **fr-FR:** vous; narrow no-break space before `: ; ? !` and no-break space before `%`; *boss* and *farmer* as used by French players.
- **de-DE:** du; compounds for item names (*Blaukappen-Kostüm*, *Rotschal-Schwert*); *Upgrades*, *Boss*, *Drop*, *Respawn* as established German gaming terms.
- **it-IT:** tu; *Tocca*, *Sconfiggi*, *farmare*; *boss*, *drop*, *slot*, *build*, *feedback* as Italian players use them; decimal comma in written numbers (*+0,5 punti*), `1.000`. *Saetta*, not *Colpo di fulmine* (that idiom means love at first sight).
- **nl-NL:** je/jij; *Tik*, *Versla*; *upgrades*, *outfit*, *run*, *drop*, *kill* as Dutch gaming loanwords; *baas/bazen* and *eindbaas* rather than *boss*; *vak*, never *slot*; *IJ* capitalised as one letter (*IJsstoot*); `1.000`.
- **pl-PL:** ty; *Dotknij*, *Pokonaj*, *Załóż*; *boss/bossowie* (masculine personal, so *3 bossów*), *farmić*, *drop*; decimal comma; `1000`; quotes „…”.
- **ru-RU:** ты, as common in Russian casual games; *Нажми*, *Победи*, *Надень*; *босс*, *фармить*, *дроп*; «ёлочки» quotes; `1000`; *ё* written where it belongs (*ещё*, *Зелёный*).
- **uk-UA:** ти; written independently from Russian: *Торкнись* (not «Нажми»), *Переможи*, *Вдягни*; *мапа* for map and *картка* for card (Russian uses *карта* for both, so Russian card = *карточка*); *вбрання* for outfit (ru *костюм*); *поєднати* for merge (ru *объединить*); *нагода* for opportunity (ru *возможность*); *місії* (ru *задания*); apostrophe ’ (*здоров’я*, *п’ятьох*). Only 57 of 1,899 worded lines equal the Russian text (numbers, *Престиж*, *Пауза*, *Зима I*, abbreviations), checked by the Batch 02 probe.

## Counts and plurals (Batch 02)

The English source has no gettext plural forms. Italian and Dutch follow English (their two-form plural matches English closely). Polish, Russian and Ukrainian have three count forms (1 / 2–4 / 5+, with 12–14 and 22–24 exceptions), so a number written by code can never be followed by a count-dependent noun:

- **Label first, number last:** «Объединено копий: %d · предметов: %d», „Połączone kopie: %d”, «Ще не знайдено таборів: %d».
- **Currency amounts:** «монеты: %s», „monety: %s”, never «%s монет».
- **Units and abbreviations** are invariant: *с, мин, ч; s, min, godz.; с, хв, год; п.п., в.п., pkt; ОЗ, PŻ*.
- **Mass nouns in the genitive** are invariant with any number: *+5 урона / шкоди / obrony, %s / %s опыта / досвіду*. Polish *obrażenia* (plural only) is not, so it is moved before the number (*obrażenia +%s*).
- **Compact stat labels** glued by code (`"+%s %s"`, item comparison) use that genitive: ru *урона, вампиризма, скор. атаки*; uk *шкоди, крадіжки життя*; pl *obr., obrony, kradzieży życia*.
- **Fixed numbers in prose** are inflected correctly by hand: *10 раз / 72 часа / 3 босса*; *10 razy / 72 godziny / 3 bossów*; *10 разів / 72 години / 3 босів*.

`tools/validate_localization.py` enforces the rule: in pl/ru/uk a number placeholder may only be followed by a listed unit, abbreviation, preposition or invariant genitive.

## Names

Enemy, boss, stage, skill and item names are translated descriptively. Each item name is built from its enemy's name, so the two always match:

- **es:** *Atuendo de Gorra Azul*. **pt:** *Traje de Boné Azul*. **fr:** *Tenue de Casquette Bleue* (elided *d’* before a vowel). **de:** *Blaukappen-Kostüm*.
- **it:** *Costume da Berretto Blu* (*costume da* = dress-up costume of) and *Spada di Berretto Blu*; enemy names are treated as proper names without articles.
- **nl:** *Blauwe Pet-outfit*, *Blauwe Pet-zwaard*: Dutch hyphen after a multi-word name; long names are compounds (*Badmutszwemmer*, *Oranjeschermhelm*, *Lapjeskatcapuchon*).
- **pl, ru, uk:** the enemy name in the genitive, lower case after the first word: *Strój niebieskiej czapki / Miecz bałwana*, *Костюм синей кепки / Меч снеговика*, *Вбрання синього кашкета / Меч сніговика*.
- **"Plain" enemy:** an adjective on its gear (*Costume semplice*, *Gewoon zwaard*, *Zwyczajny strój*, *Простой меч*, *Просте вбрання*).
- **Grim Reaper:** *La Parca / Ceifador / La Faucheuse / Sensenmann / Tristo Mietitore / Magere Hein / Ponury Żniwiarz / Мрачный Жнец / Похмурий Жнець*.
- **Cyan vs Teal:** kept distinct in Slavic languages: ru *Голубой робот / Бирюзовый динозавр*; uk *Блакитний робот / Бірюзовий динозавр*; pl *Błękitny robot / Turkusowy dinozaur*.
- **Named enemies in dynamic goals:** names arrive in the nominative with their map ("Blue Cap (Winter I)"). pl, ru and uk therefore put a colon after the verb (*Pokonaj: %s*, *Победи: %s*, *Переможи: %s*) instead of declining a name the code cannot inflect.

## Formatting rules

- **Placeholder order:** placeholders keep the English order, because GDScript's `%` operator has no positional arguments. Count and type are checked by the validator. Order was reviewed by hand for all entries with repeated `%s`/`%d`: 106 in Batch 01, 105 per language in Batch 02.
- **Numbers:** compact numbers (`1.2K`, `3.4M`) and the merge level (`^25`) are the same in every language, as players read them in idle games. Decimals written inside sentences follow the locale (comma in it, nl, pl, ru, uk).
- **No-break spaces:** a number or numeric placeholder is glued to the word after it with a no-break space ("12 s", "5 Minuten", "37 с"), so units never start a line.
- **Durations** use the `DURATION_*` keys: `1 h 05 min`, `1 Std. 05 Min.`, `1 u 05 min`, `1 godz. 05 min`, `1 ч 05 мин`, `1 год 05 хв`.
- **Compass directions** carry their preposition in the `COMPASS_*` key: *A nord del campo 3*, *Ten noorden van kamp 3*, *Na północ od obozu 3*, *К северу от лагеря 3*, *На північ від табору 3*.
- **Language names** in Settings are shown in the current UI language, matching the English catalog. Autonyms (*Deutsch*, *日本語*) wait for the global gate, when the CJK, Thai and Devanagari font fallbacks exist; DejaVu Sans would draw those scripts as empty boxes. DejaVu Sans covers Latin, Polish and the full Russian and Ukrainian Cyrillic set.
