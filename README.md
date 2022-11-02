[![Build FG-Usable File](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Advanced-Effects/actions/workflows/create-ext.yml/badge.svg)](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Advanced-Effects/actions/workflows/create-ext.yml) [![Luacheck](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Advanced-Effects/actions/workflows/luacheck.yml/badge.svg)](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Advanced-Effects/actions/workflows/luacheck.yml)

# Advanced Effects
Original extension by [Celestian](https://www.fantasygrounds.com/forums/member.php?54726-celestian). Ported to PFRPG/3.5E by [rmilmine](https://www.fantasygrounds.com/forums/member.php?215591-rmilmine) and [bmos](https://www.fantasygrounds.com/forums/member.php?194283-bmos).

Attach effects to PCs, NPCs, class/race abilities, and items.

# Compatibility
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) 4.3.0 (2022-10-20).

# How does it work?
For items, effects (such as "IFT: ALIGN (evil); AC: 2") will be placed on the owner of the item when they equip the item (and are in the combat tracker) and will be removed when the item is unequipped.
If you use [Ammunition Manager](https://github.com/bmos/FG-Ammunition-Manager), effects attached to ammo used with a weapon will be included in the attack as well.

For NPCs and PCs, it automatically adds the effect when you drag/drop them into the combat tracker (this is great for permanent effects you don't want to lose if you clear the combat tracker).

PCs can have effects added either on the combat tab or within special ability details. Adding PC effects to special abilities allows them to be exported as part of a module to simplify player-character automation.

There is one campaign option which allows PCs to see and edit enabled item effects. The option is disabled by default.

Items

![Item sheets add effects](https://user-images.githubusercontent.com/1916835/175786580-f83bdf2f-4a26-4894-99f3-f8828bd45546.png)

The action "Action Only" effect (only used when THAT weapon/item is used for attack/damage).

![Action Only](https://i.imgur.com/QzwZaqx.png)

Special Abilities

![Special abilities add effects](https://user-images.githubusercontent.com/1916835/175786596-b181a9c1-6790-42d7-b314-339984c85181.png)


