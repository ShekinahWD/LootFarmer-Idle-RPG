# LootFarmer — Localization Glossary (Batches 01–04, all 20 languages)

Game-specific terminology decisions for the runtime catalogs in `localization/`. The English catalog (`localization/en.po`) is the source of truth. Batch 01 (Change 38): es-419, es-ES, pt-BR, fr-FR, de-DE. Batch 02 (Change 39): it-IT, nl-NL, pl-PL, ru-RU, uk-UA. Batch 03 (Change 42): tr-TR, id-ID, vi-VN, th-TH, hi-IN. Batch 04 (Change 43): ja-JP, ko-KR, zh-CN, zh-TW.

## Not translated (brand and proper nouns)

| Text | Where | Rule |
|---|---|---|
| LootFarmer | everywhere | Product name, never translated or declined (ru «в LootFarmer», pl „w LootFarmer”). |
| `LootFarmer - Idle RPG`, `LOOTFARMER · IDLE RPG` | `APP_TITLE`, `GAME_TITLE` | Store title kept as the product name. |
| Google Play, itch.io | review buttons | Storefront names. |
| Pixel Plains, SnowHex, Kenney Fantasy UI Borders, CC0 | `CREDITS` | Credited works and licence. |
| Discord | `DISCORD` (Settings button, Change 41) | Service name, identical in every catalog (allowlisted as a brand). |

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
- **Language names** in the Settings dropdown are autonyms, the same in every UI language (Change 40); since Change 42 the dropdown draws with the Thai and Devanagari fallbacks so *ไทย* and *हिन्दी* render everywhere. DejaVu Sans covers Latin (incl. Turkish and Vietnamese), Polish and the full Russian and Ukrainian Cyrillic set.

## Change 41 additions (29 October 2026)

| English | es-419 / es-ES | pt-BR | fr-FR | de-DE | it-IT | nl-NL | pl-PL | ru-RU | uk-UA |
|---|---|---|---|---|---|---|---|---|---|
| Joystick position | Posición del joystick | Posição do joystick | Position du joystick | Joystick-Position | Posizione del joystick | Joystickpositie | Pozycja joysticka | Положение джойстика | Положення джойстика |
| Left / Center / Right | Izquierda / Centro / Derecha | Esquerda / Centro / Direita | Gauche / Centre / Droite | Links / Mitte / Rechts | Sinistra / Centro / Destra | Links / Midden / Rechts | Z lewej / Na środku / Z prawej | Слева / По центру / Справа | Ліворуч / По центру / Праворуч |
| Guided / Basic / None (mode names) | Guiada / Básica / Ninguna | Guiado / Básico / Nenhum | Guidé / Simple / Aucun | Geführt / Einfach / Keine | Guidata / Base / Nessuna | Begeleid / Basis / Geen | Z przewodnikiem / Podstawowy / Bez podpowiedzi | С обучением / Базовый / Без подсказок | З навчанням / Базовий / Без підказок |

- The mode names are the first part of the earlier "Name · description" strings, unchanged; each description is now its own key (`GUIDE_MODE_*_DETAIL`).
- Collection contracts state both numbers: the count to collect (21 / 31 / 41) and the count handed in (20 / 30 / 40), with "you keep one". pl/ru/uk use the literal numbers with the correct case (pl „po 21 strojów”, ru «по 21 костюму», uk «по 21 вбранню»); no number placeholder is involved.
- `PROGRESS_COLLECTION` is "Progress: %s" (was "Found this run"), because the kept copy can be an older one.

## Batch 03 (Change 42): tr-TR, id-ID, vi-VN, th-TH, hi-IN

Written from scratch against the 1,951-key English catalog; the drafts were reference only. Reviewed by Claude, not by native speakers.

| English | tr-TR | id-ID | vi-VN | th-TH | hi-IN |
|---|---|---|---|---|---|
| Coins / Gems | Altın / Mücevher | Koin / Permata | Xu / Ngọc | เหรียญ / อัญมณี | सिक्के / रत्न |
| Gear (equipment) | ekipman | perlengkapan | trang bị | อุปกรณ์ | गियर (उपकरण in "equipment slot") |
| Inventory | envanter | inventaris | túi đồ | กระเป๋า | इन्वेंटरी |
| Weapon / Outfit | silah / kıyafet | senjata / kostum | vũ khí / trang phục | อาวุธ / ชุด | हथियार / पोशाक (f.) |
| Supplies (consumables) | malzemeler | perbekalan | đồ tiêu hao | เสบียง | रसद |
| Slot | yuva | slot | ô | ช่อง | स्लॉट |
| Merge | birleştir · birleştirme | gabungkan · penggabungan | ghép | ผสาน · การผสาน | मर्ज करें · मर्ज |
| Evolve | evrimleştir · evrim | evolusikan · evolusi | tiến hóa | วิวัฒนาการ | इवॉल्व करें · इवॉल्यूशन |
| Upgrade (bought) | geliştirme | peningkatan | nâng cấp | อัปเกรด | अपग्रेड |
| Spare copy | yedek kopya | salinan cadangan | bản sao dư | ชิ้นสำรอง | अतिरिक्त प्रति |
| Supply Mastery | Malzeme Ustalığı | Penguasaan Perbekalan | Thành thạo đồ tiêu hao | ความชำนาญเสบียง | रसद महारत |
| Map Mastery | Harita Ustalığı | Penguasaan Peta | Thành thạo bản đồ | ความชำนาญแผนที่ | नक्शा महारत |
| Prestige | Prestij | Prestise | Chuyển sinh | เพรสทีจ | प्रेस्टीज |
| Opportunity / card | fırsat / kart | peluang / kartu | cơ hội / thẻ | โอกาส / การ์ด | अवसर / कार्ड |
| Mission / Main objective | görev / ana hedef | misi / tujuan utama | nhiệm vụ / mục tiêu chính | ภารกิจ / เป้าหมายหลัก | मिशन / मुख्य उद्देश्य |
| Claim / pick up | Al / topla | Klaim / ambil | Nhận / nhặt | รับ / เก็บ | प्राप्त करें / उठाएँ |
| Camp / respawn | kamp / yeniden doğma | kemah / bangkit | trại / hồi sinh | ค่าย / เกิดใหม่ | कैंप / पुनर्जीवन |
| View Camp | Kampı Gör | Lihat Kemah | Xem trại | ดูค่าย | कैंप देखें |
| Farm (verb) | farm yap · farmla | farming | cày | ฟาร์ม | फ़ार्म करें |
| Boss | boss (boss'u, boss'lar) | bos | Boss | บอส | बॉस |
| Skill / cooldown | yetenek / bekleme süresi | skill / jeda | kỹ năng / hồi chiêu | สกิล / คูลดาวน์ | स्किल / कूलडाउन |
| Cast a skill | kullan | rapal | thi triển | ร่าย | चलाएँ |
| Loot / drop | ganimet / düşen | jarahan / drop | chiến lợi phẩm / rơi | ของดรอป / ดรอป | लूट / ड्रॉप |
| Trophy | kupa | trofi | chiến tích | ถ้วยรางวัล | ट्रॉफ़ी |
| Tier / level | kademe / seviye | tingkat / level | bậc / cấp | ขั้น / เลเวล | टियर / लेवल |
| Stage (map) / map | bölge / harita | tahap / peta | màn / bản đồ | ด่าน / แผนที่ | स्टेज / नक्शा |
| Run (between Prestiges) | tur | putaran | lượt chơi | รอบ | दौर |
| HP / XP | Can / TP | HP / EXP | HP / EXP | HP / EXP | HP / XP |
| Tap | Dokun | Ketuk | Chạm | แตะ | टैप करें |
| Target (drag from the hero) | hedef al | jadikan target | chọn làm mục tiêu | เลือกเป็นเป้าหมาย | निशाना बनाएँ |
| Defeat | yen | kalahkan | đánh bại | กำจัด (บอส: ปราบ) | हराएँ |
| Equip / Unequip | Kuşan / Çıkar | Pakai / Lepas | Trang bị / Tháo | สวมใส่ / ถอด | लैस करें / हटाएँ |
| Elite | Seçkin | Elit | Tinh anh | อีลิท | एलीट |
| Honest review | dürüst değerlendirme | ulasan jujur | đánh giá chân thật | รีวิวตามจริง | ईमानदार समीक्षा |
| Joystick position: Left / Center / Right | Joystick konumu: Sol / Orta / Sağ | Posisi joystick: Kiri / Tengah / Kanan | Vị trí cần điều khiển: Trái / Giữa / Phải | ตำแหน่งจอยสติ๊ก: ซ้าย / กลาง / ขวา | जॉयस्टिक स्थिति: बाएँ / बीच में / दाएँ |
| Guided / Basic / None | Rehberli / Temel / Yok | Terpandu / Dasar / Tanpa | Có hướng dẫn / Cơ bản / Không | แนะนำทีละขั้น / พื้นฐาน / ไม่มี | निर्देशित / बुनियादी / कोई नहीं |
| Stages (Winter I …) | Kış, Yaz, Sonbahar, İlkbahar | Musim Dingin, Panas, Gugur, Semi | Mùa Đông, Hè, Thu, Xuân | ฤดูหนาว, ร้อน, ใบไม้ร่วง, ใบไม้ผลิ | सर्दी, गर्मी, पतझड़, वसंत |
| Grim Reaper / Death (legacy) | Tırpanlı Ölüm / Ölüm | Malaikat Maut / Sang Maut | Thần Chết / Tử Thần | ยมทูต / มัจจุราช | यमदूत / मृत्यु |

### Register and language rules (Batch 03)

- **tr-TR:** sen; imperatives *Dokun, Yen, Kuşan*. Turkish suffixes follow the vowel of the word they attach to, which code cannot know for a name or number, so **no suffix is ever attached to a placeholder**: *Yen: %s* / *%s yen*, *Seç: Kamp %d*, *Can (seviye %d)*, *canın %%%s kadarı*. Fixed names and numerals take their correct suffix by hand (*Kardan Adam'ı*, *Kış II'yi*, *Yaz I'e*, *^100'e*, *21 tane*). Percent sign first: *%12*, written `%%%s` (the validator accepts a moved `%%`). All-caps headers use İ/I correctly (*SEVİYE, KUŞANILI, AÇIK*); the UI never uppercases text itself. Singular after numerals (*5 düşman*). *Boss* kept (patron means employer); trophy *kupa*, distinct from loot *ganimet*.
- **id-ID:** kamu, plain imperatives; KBBI/gaming loanwords *level, item, reset, offline, damage, farming, skill, slot, drop*; *tingkat* only for item tier; *jeda* for cooldown; no plural after numbers. 22 allowlisted English-identical lines (all loanwords or HP).
- **vi-VN:** bạn; NFC precomposed diacritics throughout (checked); *Chuyển sinh* for Prestige (the Vietnamese idle/MMO reset term), deliberately distinct from respawn *hồi sinh*; *cày* for farming, *ghép* for merge; Cyan *xanh lơ* vs Teal *xanh mòng két*.
- **th-TH:** no pronoun where natural, คุณ otherwise; no spaces inside a phrase, a space between clauses, no final full stop. **ค่าย for camp** (not the loanword แคมป์, which Godot's ICU dictionary split as แคม|ป์ when wrapping). **ๆ attached** (ใกล้ๆ), so no line can start with ๆ. Cyan *ฟ้า* vs Teal *เขียวหัวเป็ด*. Roman numerals kept in stage names.
- **hi-IN:** आप with *-ें/-एँ* imperatives; danda । ends sentences; Western digits. Hindi -ā nouns and feminine plurals change with the count (1 सिक्का / 2 सिक्के), so count lines put the label first: *सिक्के: %s*, *मर्ज हुई प्रतियाँ: %d* — enforced by the validator (`COUNT_FOLLOWERS['hi_IN']`). Verbs never agree with a name placeholder (*हराएँ: %s*). Item names *<enemy> की पोशाक / की तलवार* (both feminine, so *की* always agrees). Abbreviated units *से., मि., घं.*.
- **Item names** are generated from the enemy names: tr *<ad> Kıyafeti / Kılıcı*, id *Kostum / Pedang <nama>*, vi *Trang phục / Kiếm <tên>*, th *ชุด / ดาบ<ชื่อ>*, hi *<नाम> की पोशाक / तलवार*; the Plain enemy gets an adjective (*Sade Kıyafet, Trang phục Thường, ชุดธรรมดา, सादी पोशाक*).
- **Compass:** tr *%s yönü · Kamp %d çevresi*, id *Sebelah utara Kemah %d*, vi *Phía bắc trại %d*, th *ทางเหนือของค่าย %d*, hi *उत्तर दिशा · कैंप %d से*.
- **Fonts:** Thai and Hindi draw with the theme font plus Noto Sans Thai / Noto Sans Devanagari (OFL); every other locale keeps plain DejaVu Sans (Turkish and Vietnamese are fully covered by it). The language dropdown always carries both fallbacks so ไทย and हिन्दी render in every locale.

## Batch 04 (Change 43): ja-JP, ko-KR, zh-CN, zh-TW

Written from scratch against the 1,951-key English catalog (unique English texts translated once, item names generated from the enemy names); the drafts were reference only. Reviewed by Claude, **not by native speakers**. Simplified and Traditional Chinese were written separately with regional vocabulary, not converted: 118 of 1,272 distinct English texts have the same Chinese wording in both (short shared words such as 技能, 武器, 精通/熟練度 differ; 傳送/传送 are only glyph variants).

| English | ja-JP | ko-KR | zh-CN | zh-TW |
|---|---|---|---|---|
| Coins / Gems | コイン / ジェム | 코인 / 보석 | 金币 / 宝石 | 金幣 / 寶石 |
| Gear (equipment) | 装備 | 장비 | 装备 | 裝備 |
| Inventory | 持ち物 | 인벤토리 | 背包 | 背包 |
| Item | アイテム | 아이템 | 物品 | 道具 |
| Weapon / Outfit | 武器 / 衣装 | 무기 / 의상 | 武器 / 服装 | 武器 / 服裝 |
| Supplies (consumables) | 消耗品 | 소모품 | 补给品 | 補給品 |
| Slot | スロット | 슬롯 | 格子 (inventory) · 栏位 (skill/mission) | 欄位 |
| Merge | 合成 | 합성 | 合成 | 合成 |
| Evolve | 進化 | 진화 | 进化 | 進化 |
| Upgrade (bought) | 強化 | 강화 | 强化 | 強化 |
| Spare copy | 予備 | 여분 | 重复品 | 重複品 |
| Supply Mastery | 消耗品熟練度 | 소모품 숙련도 | 补给精通 | 補給熟練度 |
| Map Mastery | マップ熟練度 | 지도 숙련도 | 地图精通 | 地圖熟練度 |
| Prestige | 転生 | 환생 | 转生 | 轉生 |
| Respawn | 復活 | 부활 | 复活 | 復活 |
| Opportunity / card | チャンス / カード | 기회 / 카드 | 机遇 / 卡牌 | 機會 / 卡片 |
| Mission / Main objective | ミッション / メイン目標 | 미션 / 메인 목표 | 任务 / 主要目标 | 任務 / 主要目標 |
| Claim / pick up | 受け取る / 拾う | 받기·수령 / 줍기 | 领取 / 拾取 | 領取 / 撿取 |
| Camp / View Camp | キャンプ / キャンプを見る | 캠프 / 캠프 보기 | 营地 / 查看营地 | 營地 / 查看營地 |
| Farm (verb) · Focus Farming | 狩る · 集中狩り | 파밍 · 집중 파밍 | 刷怪 · 专注刷怪 | 刷怪 · 專注刷怪 |
| Boss | ボス | 보스 | 首领 | 頭目 |
| Elite | エリート | 정예 | 精英 | 菁英 |
| Skill / cooldown | スキル / クールダウン | 스킬 / 쿨타임 | 技能 / 冷却 | 技能 / 冷卻 |
| Cast | 発動 / 使う | 시전 | 施放 | 施放 |
| Loot / drop | 戦利品 / ドロップ | 전리품 / 드롭 | 战利品 / 掉落 | 戰利品 / 掉落 |
| Trophy | トロフィー | 트로피 | 奖杯 | 獎盃 |
| Tier / level | ランク / レベル | 등급 / 레벨 | 阶 / 等级 | 階 / 等級 |
| Stage (map) / map | ステージ / マップ | 스테이지 / 지도 | 关卡 / 地图 | 關卡 / 地圖 |
| Run (between Prestiges) | 周回 | 회차 | 轮 | 輪 |
| HP / XP | HP / EXP·経験値 | 체력 (HP in the HUD) / 경험치 | 生命值 (HP in the HUD) / 经验 | 生命值 (HP in the HUD) / 經驗 |
| Critical / lifesteal | クリティカル / HP吸収 | 치명타 / 흡혈 | 暴击 / 吸血 | 爆擊 / 吸血 |
| Defense | 防御 | 방어 | 防御 | 防禦 |
| Tap | タップ | 터치 | 点击 | 輕觸 |
| Target (drag from the hero) | ターゲットにする | 대상으로 지정 | 锁定 | 鎖定 |
| Equip / Unequip | 装備する / 外す | 장착 / 해제 | 装备 / 卸下 | 裝備 / 卸下 |
| Settings / Save | 設定 / セーブ | 설정 / 저장 | 设置 / 保存 | 設定 / 儲存 |
| Reset (Hard Reset) | リセット (完全リセット) | 초기화 (완전 초기화) | 重置 (彻底重置) | 重設 (完全重設) |
| Honest review | 率直なレビュー | 솔직한 리뷰 | 真实的评价 | 真實的評價 |
| Joystick position: Left / Center / Right | ジョイスティックの位置: 左 / 中央 / 右 | 조이스틱 위치: 왼쪽 / 가운데 / 오른쪽 | 摇杆位置: 左侧 / 居中 / 右侧 | 搖桿位置: 左側 / 置中 / 右側 |
| Guided / Basic / None | ガイド付き / 基本 / なし | 단계별 안내 / 기본 / 없음 | 全程引导 / 基础 / 无 | 完整引導 / 基本 / 無 |
| Stages (Winter I …) | 冬 I, 夏, 秋, 春 | 겨울 I, 여름, 가을, 봄 | 冬季 I, 夏季, 秋季, 春季 | 冬季 I, 夏季, 秋季, 春季 |
| Grim Reaper | 死神 | 사신 | 死神 | 死神 |
| Skills (Heal, Frost Burst, Fire Burst, Lightning Strike, Arcane Focus, Arcane Strike) | ヒール, フロストバースト, ファイアバースト, ライトニング, 秘術集中, 秘術の一撃 | 치유, 서리 폭발, 화염 폭발, 번개 강타, 비전 집중, 비전 일격 | 治疗术, 冰霜爆发, 烈焰爆发, 雷击, 奥术专注, 奥术打击 | 治癒術, 冰霜爆破, 烈焰爆破, 雷擊, 秘法專注, 秘法打擊 |

### Register and language rules (Batch 04)

- **ja-JP:** friendly direct register for guidance and goals (〜しよう, plain verb goals such as 雪だるまを倒す), です/ます for system messages, confirmations and errors; buttons are nouns or short verbs (装備する, 合成, 受け取る). Full-width punctuation and brackets around Japanese text (「」, （）, ：, 、。); a half-width space only around Latin words and Roman stage numerals (冬 II). No space between a number and its counter or unit (5体, 2.5秒, 1時間05分). Prestige is 転生, the established idle-game term, and stays distinct from respawning (復活). Farming is 狩り, Upgrades 強化 (never used for merging), Tier ランク. MAX is kept as Japanese game UI writes it (allowlisted).
- **ko-KR:** -하세요 for guidance, -습니다 for system messages, nouns for buttons (장착, 해제, 합성). Spaces between words and before units written as words (1시간 05분, 3초 후); counters attach (3개, 5마리). **No particle whose form depends on the preceding syllable (을/를, 이/가, 은/는, 와/과, (으)로) is ever attached to a placeholder**: a placeholder hides that syllable, so lines use a colon, a noun or an invariant particle instead (선택: %s, %s 처치, %s의, %s에서) — enforced by the validator. Fixed names take their correct particle (눈사람을, 겨울 II가). Prestige is 환생 (distinct from 부활), cooldown 쿨타임, tap 터치. **Word wrapping:** Korean lines break between words; the catalog carries U+2060 WORD JOINERs inside every Korean word (tools/korean_keep_all.py, checked by the validator), because Godot otherwise breaks between any two Hangul syllables.
- **zh-CN:** Mainland vocabulary and punctuation: “”, full-width ，。：！？（）, 设置, 保存, 默认, 点击, 首领, 暴击, 防御, 物品, 卡牌, 背包格子, 内存, 网络, 应用, 界面, 恢复, 兼容, 标签页. A space separates Chinese from Latin text and numbers inside sentences (击败 5 个普通敌人); units attach (2.5秒). Prestige 转生, Mastery 精通.
- **zh-TW:** Taiwan vocabulary and punctuation, written independently: 「」, 設定, 儲存, 預設, 輕觸, 頭目, 爆擊, 防禦, 道具, 卡片, 欄位, 記憶體, 網路, 應用程式, 介面, 復原/重設, 相容, 分頁, 菁英, 繳交, 撿取, 品質, 略過, 小貓熊, 太陽眼鏡, 棒球帽, 置中. Arcane is 秘法 (zh-CN 奥术), mastery 熟練度 (zh-CN 精通).
- **Character sets:** every Japanese CJK character is in CP932, every Simplified Chinese one in GB2312 and every Traditional one in Big5 (validator rule), so no Traditional glyph slips into zh-CN and no Simplified one into zh-TW or Japanese.
- **"Cap" enemies in Chinese:** 鸭舌帽 (zh-CN) / 棒球帽 (zh-TW) rather than 帽 alone, because 绿帽 (green hat) is an insult in Chinese.
- **Item names** generated from the enemy names: ja *<名>の衣装 / <名>の剣*, ko *<이름> 의상 / <이름> 검*, zh-CN *<名>服装 / <名>之剑*, zh-TW *<名>服裝 / <名>之劍*; the Plain enemy gets an adjective (プレーンな衣装, 기본 의상, 普通服装, 平凡服裝).
- **Compass:** the direction word carries no preposition and FARMING_LOCATION supplies the reference: ja *北（キャンプ3から） · 近い*, ko *북쪽 (캠프 3 기준) · 가까움*, zh-CN *北方（相对营地 3） · 很近*, zh-TW *北方（相對營地 3） · 很近*.
- **Intentional English** (allowlisted per key): all four keep `APP_TITLE`, `GAME_TITLE`, `DISCORD` (brands) and `PLAYER_STATUS`, `HUD_HP` (HP in the HUD); Japanese also `STATS_SHORT_HP`, `SKILL_AMOUNT_HP` (HP) and `UPGRADE_MAX`, `VALUE_MAX` (MAX).
- **Fonts:** each of the four draws with its own regional Noto Sans subset first (JP, KR, SC, TC; OFL) and DejaVu Sans second, so kana, Hangul, Han and full-width punctuation take the region's forms and Latin letters and digits keep DejaVu's. The language dropdown carries four endonym fonts so 日本語, 한국어, 简体中文 and 繁體中文 keep their own regional forms in every UI language.

