--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals getWeaponDamageRollStructures_new
local getWeaponDamageRollStructures_old
function getWeaponDamageRollStructures_new(nodeWeapon, ...)
	local rActor, rDamage = getWeaponDamageRollStructures_old(nodeWeapon, ...);

	-- add nodeWeapon to rActor so that when effects are checked we can
	-- compare them against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '');
	rActor.nodeWeapon = sRecord;

	-- bmos adding AmmunitionManager integration
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
		if nodeAmmo then rActor.nodeAmmo = nodeAmmo.getPath() end
	end

	return rActor, rDamage;
end

-- luacheck: globals getWeaponAttackRollStructures_new
local getWeaponAttackRollStructures_old
function getWeaponAttackRollStructures_new(nodeWeapon, nAttack, ...)
	local rActor, rAttack = getWeaponAttackRollStructures_old(nodeWeapon, nAttack, ...);

	-- add nodeWeapon to rActor so that when effects are checked we can
	-- compare them against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '');
	rActor.nodeWeapon = sRecord;

	-- bmos adding AmmunitionManager integration
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
		if nodeAmmo then rActor.nodeAmmo = nodeAmmo.getPath() end
	end

	return rActor, rAttack;
end

function onInit()
	getWeaponDamageRollStructures_old = CharManager.getWeaponDamageRollStructures
	CharManager.getWeaponDamageRollStructures = getWeaponDamageRollStructures_new

	getWeaponAttackRollStructures_old = CharManager.getWeaponAttackRollStructures
	CharManager.getWeaponAttackRollStructures = getWeaponAttackRollStructures_new
end
