--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose insertNodes customGetWeaponDamageRollStructures customGetWeaponAttackRollStructures
local getWeaponDamageRollStructures = nil;
local getWeaponAttackRollStructures = nil;

function onInit()
    getWeaponDamageRollStructures = CharManager.getWeaponDamageRollStructures;
    getWeaponAttackRollStructures = CharManager.getWeaponAttackRollStructures;
    CharManager.getWeaponDamageRollStructures = customGetWeaponDamageRollStructures;
    CharManager.getWeaponAttackRollStructures = customGetWeaponAttackRollStructures;
end

function onClose()
    CharManager.getWeaponDamageRollStructures = getWeaponDamageRollStructures;
    CharManager.getWeaponAttackRollStructures = getWeaponAttackRollStructures;
end

function insertNodes(rActor, nodeWeapon)
    -- add nodeWeapon and nodeItem to rActor so that when effects are
    -- checked we can compare them against action only effects
    local _, nodeItem = DB.getValue(nodeWeapon, 'shortcut', '', '');
    rActor.itemPath = nodeItem;
    rActor.weaponPath = DB.getPath(nodeWeapon);

    -- bmos adding AmmunitionManager integration
    if not AmmunitionManager then
        return
    end
    local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon);
    if nodeAmmo then
        rActor.ammoPath = DB.getPath(nodeAmmo);
    end
end

function customGetWeaponDamageRollStructures(nodeWeapon, ...)
    local rActor, rDamage = getWeaponDamageRollStructures(nodeWeapon, ...);
    insertNodes(rActor, nodeWeapon);

    return rActor, rDamage;
end

function customGetWeaponAttackRollStructures(nodeWeapon, nAttack, ...)
    local rActor, rAttack = getWeaponAttackRollStructures(nodeWeapon, nAttack, ...);
    insertNodes(rActor, nodeWeapon);

    return rActor, rAttack;
end
