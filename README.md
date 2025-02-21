
# Advanced Effects

[![Build FG Extension](https://github.com/rhagelstrom/AdvancedEffects/actions/workflows/create-release.yml/badge.svg)](https://github.com/rhagelstrom/AdvancedEffects/actions/workflows/create-release.yml) [![Luacheckrc](https://github.com/rhagelstrom/AdvancedEffects/actions/workflows/luacheck.yml/badge.svg)](https://github.com/rhagelstrom/AdvancedEffects/actions/workflows/luacheck.yml) [![Markdownlint](https://github.com/rhagelstrom/AdvancedEffects/actions/workflows/markdownlint.yml/badge.svg)](https://github.com/rhagelstrom/AdvancedEffects/actions/workflows/markdownlint.yml)

**Current Version:** ~dev_version~
**Last Updated:** ~date~

## Description

The **Advanced Effects** extension allows the addition of effects directly to various game entities such as:

- Character Sheets
- Feats
- Features (5E)
- Items
- NPCs
- Proficiencies (PFRPG)
- Racial Traits
- Special Abilities (PFRPG)

These effects are automatically added or removed from the Combat Tracker whenever the associated record or effect is added, deleted, or edited. Most effects can be managed through the **Effects** tab located on the right side of the sheet.

## Locking / Hidden Effects

- **Locked Sheets:** Effects can only be edited by the GM or Player if the sheet is unlocked.
- **Hidden Effects:** Effects marked as "Hide" by the GM are invisible to players and cannot be edited or deleted by them.

## Item-Specific Features

Items have additional restrictions and features that influence how effects are applied.

### Locking Rules for Items

- **Identified Items:** Follow the standard locking rules.
- **Unidentified Items:** Follow the standard locking rules, but players cannot view or edit any effects on the item, regardless of whether they are marked to be shown or hidden by the GM.

### Action-Only Items

For items of type **Weapon** or **Ammunition**, there is an additional field called **Action Only**. When checked:

- The associated effect will only be applied when the **Attack** or **Damage** action is taken.

## Attribution

- Originally by Celestian.  Additional effort by: bmos, rmilmine, rhagelstrom, SoxMax, MeAndUnique
- Icon based on [Sparkles](https://game-icons.net/1x1/delapouite/sparkles.html) by Delapouite, modified by rhagelstrom with permission ([CC 3.0](https://creativecommons.org/licenses/by/3.0/)).

## Support and Discussion

For additional support and to participate in discussions, visit the **Fantasy Grounds Forums**:

[Fantasy Grounds Forum Thread](https://www.fantasygrounds.com/forums/showthread.php?40833-5E-Advanced-Effects-(items-npcs-characters))
