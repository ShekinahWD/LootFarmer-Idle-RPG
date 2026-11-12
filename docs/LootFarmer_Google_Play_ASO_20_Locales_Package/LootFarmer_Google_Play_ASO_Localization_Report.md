# LootFarmer: Google Play ASO localization review

**Prepared:** 2026-10-28  
**Scope:** Approved `en-US` source + 19 market-adapted store listings (20 total).  
**Status:** Complete *draft package*, passes mechanical validation. **No Play Console import or native-speaker sign-off has been performed.**

## Reference and positioning

The approved English listing is preserved as supplied, with Markdown bold markers around headings omitted because the store listing is plain text:

- Name: `LootFarmer: Idle RPG`
- Short description: `Defeat enemies, steal their gear, and wear their look in this idle RPG.`
- Full description: the user-approved **Option A: Equipment First**. Its meaning, wording and section order have not been rewritten.

Each of the other 19 descriptions was **rewritten for its market** from the approved *feature claims*, rather than translated phrase by phrase. Locale-dependent emphasis includes genre convention (`放置RPG`, `방치형 RPG`, `RPG idle`, `Idle-RPG`), local terminology for loot and equipment, merge/combine, automation, boss fights, and outfit-based appearance changes. The name **LootFarmer** remains unchanged; some market-facing subtitles localize the genre descriptor.

The primary hook remains taking equipment carried by defeated enemies and visibly changing the hero by equipping that loot. Supporting features are item merging and weapon evolution, automatic attacks after stopping movement, targeted farming upgrades, 8 seasonal stages, bosses and summons, upgrades, missions, Map Mastery, permanent Prestige card bonuses, and offline rewards. Descriptions **do not claim** guaranteed every-kill drops, continuous combat with the app closed, online multiplayer, unlimited stages, or no-cost downloads.

## Delivery format and import workflow

- `LootFarmer_Google_Play_ASO_20_Locales.json`: the installed **Godot Marketing Capture Toolkit 1.0.2** `play_store_listing.py` handoff structure (`source_locale`, 20 `localizations`, each with `locale`, `language`, `title`, `short_description`, and `full_description`, plus the field limits). This is an **AI-assisted Play Console transport/handoff file**, not evidence that Play Console imports this JSON directly or accepts its locale codes without checking.
- `LootFarmer_Google_Play_ASO_20_Locales_Review.csv`: Excel-compatible UTF-8 BOM CSV with one row per locale, source runtime ID, Play-facing ID, English-readable language, all approved/draft text, length checks and review status.
- `LootFarmer_Google_Play_Runtime_to_Play_Locale_Map.json`: explicit runtime-to-Play mapping. As validated in the reusable workflow, `uk-UA → uk`, `id-ID → id`, `vi-VN → vi`, and `th-TH → th`. The remaining IDs follow the baseline toolkit map. Confirm the **actual** Console language list after import.

The CSV is for review and editing. Importing the CSV as a Google Play localization package is not guaranteed; follow the Play Console's actual current AI-assisted import path and verify accepted languages.

## Review of all 20 descriptions

The columns below report Python Unicode code-point counts. Google Play's visible field counter is authoritative if it differs.

| Runtime | Play tag | Title | Short | Full | Short description |
|---|---|---:|---:|---:|---|
| `en-US` | `en-US` | 20/30 | 71/80 | 2113/4000 | Defeat enemies, steal their gear, and wear their look in this idle RPG. |
| `es-419` | `es-419` | 20/30 | 80/80 | 1887/4000 | Derrota enemigos, roba su equipo y cambia de aspecto al usar sus armas y trajes. |
| `es-ES` | `es-ES` | 20/30 | 80/80 | 1806/4000 | Consigue las armas y atuendos de tus enemigos y cambia de aspecto al equiparlos. |
| `pt-BR` | `pt-BR` | 20/30 | 74/80 | 1840/4000 | Derrote monstros, pegue suas armas e trajes e mude o visual ao equipá-los. |
| `fr-FR` | `fr-FR` | 21/30 | 74/80 | 1970/4000 | Récupérez les armes et tenues ennemies et changez de look en les équipant. |
| `de-DE` | `de-DE` | 20/30 | 75/80 | 1874/4000 | Erbeute Waffen und Outfits deiner Gegner und verändere damit deinen Helden. |
| `it-IT` | `it-IT` | 20/30 | 66/80 | 1784/4000 | Prendi armi e abiti dei nemici: equipaggiali per cambiare aspetto. |
| `nl-NL` | `nl-NL` | 20/30 | 73/80 | 1787/4000 | Pak wapens en outfits van vijanden en verander je uiterlijk met hun buit. |
| `pl-PL` | `pl-PL` | 20/30 | 70/80 | 1659/4000 | Zdobywaj broń i stroje wrogów, zakładaj je i zmieniaj wygląd bohatera. |
| `ru-RU` | `ru-RU` | 20/30 | 67/80 | 1640/4000 | Забирай оружие и наряды врагов и меняй облик героя, надевая добычу. |
| `uk-UA` | `uk` | 20/30 | 67/80 | 1607/4000 | Забирай зброю й одяг ворогів, одягай трофеї та змінюй вигляд героя. |
| `tr-TR` | `tr-TR` | 20/30 | 71/80 | 1750/4000 | Düşmanın silahını ve kıyafetini ele geçir, kuşanıp görünümünü değiştir. |
| `id-ID` | `id` | 20/30 | 72/80 | 1794/4000 | Rebut senjata dan kostum musuh, lalu pakai untuk mengubah tampilan hero. |
| `vi-VN` | `vi` | 20/30 | 69/80 | 1661/4000 | Hạ quái, lấy vũ khí và trang phục của chúng để đổi diện mạo nhân vật. |
| `th-TH` | `th` | 20/30 | 64/80 | 1407/4000 | ปราบศัตรู ชิงอาวุธและชุดที่พวกมันใช้มาใส่ เปลี่ยนลุคฮีโร่ได้จริง |
| `hi-IN` | `hi-IN` | 20/30 | 59/80 | 1599/4000 | दुश्मनों के हथियार और पोशाक लूटें, पहनकर हीरो का रूप बदलें। |
| `ja-JP` | `ja-JP` | 17/30 | 33/80 | 731/4000 | 敵が落とす武器や衣装を集め、装備して見た目も変えられる放置RPG。 |
| `ko-KR` | `ko-KR` | 19/30 | 37/80 | 896/4000 | 적의 무기와 의상을 전리품으로 얻고 장착해 캐릭터 외형을 바꾸세요. |
| `zh-CN` | `zh-CN` | 16/30 | 25/80 | 559/4000 | 击败敌人夺取武器和服装，穿戴战利品，改变角色外观。 |
| `zh-TW` | `zh-TW` | 16/30 | 28/80 | 553/4000 | 打倒敵人取得武器與服裝，裝備戰利品，讓角色外觀隨之改變。 |

## Validation performed

- `play_store_listing.py validate` from the installed 1.0.2 package **PASS**: exactly 20 unique mapped Play locales.
- All titles are ≤30 characters, short descriptions ≤80, and full descriptions ≤4,000; every row has title, short and full copy.
- All 19 localized long descriptions have multiple substantive sections, and none repeats its short description verbatim.
- The approved English text is intact as plain-text paragraphs. No generated image or runtime `.po` translation was created or modified.
- No `--` punctuation, placeholder text, Markdown heading markers or unverifiable ranking/volume assertions in the exported descriptions.

## Market research and terminology evidence

This is **ASO-oriented writing, not verified keyword-volume optimization**. Search terms and genre vocabulary were spot-checked against publicly available Google Play listings and guidance. Examples include:

| Market | Supported vocabulary / writing direction | Example source |
|---|---|---|
| General metadata | Emphasize useful, accurate info early; avoid keyword stuffing, claims and repeated short description | https://support.google.com/googleplay/android-developer/answer/13393723?hl=en |
| Latin American Spanish | *RPG incremental*, *botín*, *equipo*, *equipar* | https://play.google.com/store/apps/details?hl=es_AR&id=net.gameduo.cd |
| Brazilian Portuguese | *RPG idle*, *equipamentos*, *fundir*, *combine* | https://play.google.com/store/apps/details?hl=pt_BR&id=mobi.blackbears.idle.shelter |
| German | *Idle-RPG*, *Beute*, *Ausrüstung*, *Offline-Belohnungen* | https://play.google.com/store/apps/details?hl=de&id=com.leidd.games.ascendHeroClicker |
| Italian | *RPG idle*, *bottino*, *equipaggiamento* | https://play.google.com/store/apps/details?hl=it&id=com.dungeon.blade |
| Dutch | *idle RPG*, *buit*, *uitrusting*, *pixelart* | https://play.google.com/store/apps/details?hl=nl&id=com.demonfork.lootfall |
| Indonesian | *RPG idle*, *perlengkapan*, *loot*, *gabungkan* | https://play.google.com/store/apps/details?hl=id&id=idler.axes.masters.sword.attack.merge |
| Japanese | *放置RPG*, *装備*, *ドロップ*, *合成*, *ハクスラ* | https://play.google.com/store/apps/details?hl=ja&id=jp.pluszero.dungeon |
| Korean | *방치형 RPG*, *장비 파밍*, *합성*, *자동 전투* | https://play.google.com/store/apps/details?hl=ko&id=com.nodebrothers.gangwha |
| Simplified Chinese | *放置RPG*, *装备*, *自动战斗*, *合成* | https://play.google.com/store/apps/details?hl=zh_CN&id=com.droidhang.ad |

Other markets' drafts use natural-language genre conventions and adapted syntax, but were **not independently validated with native market researchers**. No reliable per-country keyword search volume, conversion, or ranking data was available, and none is asserted.

## Before publication

1. Review each listing in context with a proficient native editor, especially Thai, Hindi, Japanese, Korean and Chinese where regional nuance matters. Treat machine-written localization as a draft until reviewed.
2. Re-check Google Play's current metadata policy and character counters and examine how each title/short description wraps on real devices. Consider refinements based on real Play Console recommendations if available.
3. Import through Play Console's supported localization workflow and compare the **actual detected language names** to this 20-entry plan. If a tag is rejected, correct the reviewed locale map rather than dropping that language.
4. Preserve the English source as the reference for meaning and factual gameplay claims; reflect only approved gameplay changes in later revisions. These are *store listing translations*, not the game's 19 runtime `.po` catalogs.

## Source documents

- `docs/Reusable_Game_Development_Playbook.md` §§134.1–134.3: approved English first, language-specific market adaptation, locale mappings and 20-language QA.
- `docs/LootFarmer_GDD.md`: equipment carried/dropped by enemies, visual outfits, gear merges, automatic attacks, 8 stages, Prestige, and offline rewards.
- Approved English listing from this conversation: `LootFarmer: Idle RPG`, approved short description Option A and full description Option A (Equipment First).

**Next gate:** Human review and Play Console import verification. The package is complete and mechanically valid; it is not already published or guaranteed ASO-optimal.
