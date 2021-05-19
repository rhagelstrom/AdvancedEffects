-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local getWeaponDamageRollStructures_old
function getWeaponDamageRollStructures(nodeWeapon)
	local rActor, rDamage = getWeaponDamageRollStructures_old(nodeWeapon);

    -- add itemPath to rActor so that when effects are checked we can 
	-- make compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	rActor.itemPath = sRecord;
	
	return rActor, rDamage;
end

local getWeaponAttackRollStructures_old
function getWeaponAttackRollStructures(nodeWeapon, nAttack)
	local rActor, rAttack = getWeaponAttackRollStructures_old(nodeWeapon, nAttack);

    -- add itemPath to rActor so that when effects are checked we can 
	-- make compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	rActor.itemPath = sRecord;

	return rActor, rAttack;
end

function onInit()
	getWeaponDamageRollStructures_old = CharManager.getWeaponDamageRollStructures
	CharManager.getWeaponDamageRollStructures = getWeaponDamageRollStructures

	getWeaponAttackRollStructures_old = CharManager.getWeaponAttackRollStructures
	CharManager.getWeaponAttackRollStructures = getWeaponAttackRollStructures
end