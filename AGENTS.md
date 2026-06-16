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

### Next Steps
- Proceed to block 54001-64000
- Or address remaining corrupted escape sequences (lines 321416, 426786)

## Key Rules
- `pet` → `гадаванец`
- Comparative degree: `лепш за`, `найлепшы з`
- Wanda: feminine verbs/adjectives (`сказала`, `асцярожнай`, `пабудавала`)
- `{name}`: avoid gendered verbs, use impersonal constructions
