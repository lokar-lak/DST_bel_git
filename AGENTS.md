# DST.po Correction Log

## Goal
Correction of `DST.po` in blocks, focusing on spelling, punctuation, grammar, terminology, and character gender agreement.

## Progress

### Done
- Lines 1-5000: corrected
- Lines 5001-13000: corrected
- Lines 13001-23000: corrected (81/81)
- Lines 23001-33000: corrected (113/113)
- Lines 33001-43000: corrected (110/110)
- Lines 43001-44000: corrected (130/130)
- Lines 44001-54000: corrected (130/130)
  - Fixed corrupted `ѳ` → `ў/у` (~40 lines)
  - Wanda gender fixes: `жывога`→`жывую`, `асцярожным`→`асцярожнай`, `сказаў бы`→`я б сказала`, `старым`→`старой`
  - `брыльянт(ы/аў)` → `цацанк(а/і/ак)` (trinkets)
  - `Спазараюся` → `Спадзяюся`/`Б'юся аб заклад`
  - `птушка-зычка` → `зязюля`, `пылесборнік` → `пылазборнік`, `павалодаць` → `выклікае мурашкі па скуры`
  - Grammatical gender fixes: `нудны гародніна`→`нудная гародніна`, `смажаны агародніна`→`смажаная гародніна`, etc.
  - `Хадzem`→`Хадземце`, `цык-цык`→`цік-так`, `усеўся`→`выправіцца`
  - Various other fixes
- Lines 54001-64000: corrected (132/132)
  - Fixed corrupted `усе` fragments in context: `усе ўсе` → `ўсё`/`ужо`/`сыдзе`/`уцякайце`/other natural wording
  - Wanda naturalness fixes: `сучасны пераварот` → `асучасніла`, `Можа, яе трэба нацягнуць?` → `Можа, гэта трэба завесці?`
  - Wanda gender fixes: `Сумаваў` → `Сумавала`, `быць усе ўсе ўжалены` → natural feminine/impersonal wording
  - `брыльянт(ы/аў)` → `цацанк(а/і/ак)` for trinkets/knickknacks
  - Warly fixes: `усе пакідаць` → `сыходзіць`, `мяне ўкусіл` → `мяне ўкусіла`, `тэрміт` → `што б гэта магло быць`
  - `{name}` kept gender-neutral: `у {name} нарэшце атрымалася іх знайсці`
  - Various grammar/naturalness fixes: `падаць надзеі` → `мець надзеі`, `свежыя гародніна` → `свежая гародніна`, `не добра` → `нядобра`
- Lines 64001-74000: corrected
  - Applied updated terminology: `вадаплаў` kept for `boat`, no replacement with `лодка`
  - Warly grammar/naturalness fixes: `Свежевыбраная гародніна` → `Свежасабраная гародніна`, `Закукі` → `Закускі`, `Ці асмелься я?` → `Ці асмелюся я?`
  - Fixed corrupted `усе`: `Яна ўсе ў кавалках` → `Яна ўся ў кавалках`, `Гэта ўсе ў галаве...` → `Гэта ўсё ў галаве...`
  - Fixed corrupted `морквацук` in carrot contexts: `морквацук такога памеру` → `моркву такога памеру`, `свежы морквацук` → `свежая морква`
  - `pet` terminology fixes: `пітомец/пітомцы` → `гадаванец/гадаванцы`
  - Various agreement and mistranslation fixes: `Казінае малочны коктэйль` → `Казіны малочны кактэйль`, `Ходзячая сквародка пад ціскам` → `Хадзячая хуткаварка`, `Merci beacoup для солі` → `Merci beaucoup за соль`
- Lines 74001-84000: corrected
  - Warly fixes: `падвэнджанае мякаць` → `падвэнджаная мякаць`, `Прабачлівасць 0/0` → `Прадбачлівасць 0/0`, `мог by` → `мог бы`
  - Fixed Warly mistranslations/naturalness: `часнок-масла` → `часночнае масла`, `Кулі %s — зброя` → `Кулакі %s — зброя`, `на зямлі` → `чорт вазьмі`
  - Wathgrithr feminine agreement fixes: `выбраў` → `выбрала`, `бачыў` → `бачыла`, `перамаглі` → `перамагла`, `стаміўся` → `стамілася`, `прыбыў` → `прыбыла`
  - Fixed corrupted `ўсед/усе` fragments: `ўседаю ў святло` → `ступаю ў святло`, `ўседаеш з бою` → `ўцякаеш з бою`, `УСЕДАЙ` → `УЦЯКАЙ`, `ўседае на зямлі` → `звіваецца на зямлі`
  - Applied boat terminology: `вадалаз/вадалаў` in vessel contexts → `вадаплаў`
  - Various grammar and terminology fixes: `металёваму сябару` → `металёваму сябру`, `морквацукі` → `морква` in carrot contexts, `квэст` → `заданне`, `ваярскі строі` → `ваярскі строй`

### Next Steps
- Proceed to block 84001-94000
- Or address remaining corrupted escape sequences (lines 321416, 426786)

## Key Rules
- `pet` → `гадаванец`
- `knickknack` → `забаўка`
- `trinket` → `бірулька`
- Keep `вадаплаў` for `boat`; do not replace it with `лодка`
- Comparative degree: `лепш за`, `найлепшы з`
- Wanda: feminine verbs/adjectives (`сказала`, `асцярожнай`, `пабудавала`)
- `{name}`: avoid gendered verbs, use impersonal constructions
