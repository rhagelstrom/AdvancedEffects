--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

local function insertNodes(rActor, nodeWeapon)
	-- add nodeWeapon and nodeItem to rActor so that when effects are
	-- checked we can compare them against action only effects
	local _, nodeItem = DB.getValue(nodeWeapon, 'shortcut', '', '')
	rActor.nodeItem = nodeItem
	rActor.nodeWeapon = DB.getPath(nodeWeapon)

	-- bmos adding AmmunitionManager integration
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
		if nodeAmmo then rActor.nodeAmmo = DB.getPath(nodeAmmo) end
	end
end

local getWeaponDamageRollStructures_old
local function getWeaponDamageRollStructures_new(nodeWeapon, ...)
	local rActor, rDamage = getWeaponDamageRollStructures_old(nodeWeapon, ...)

	insertNodes(rActor, nodeWeapon)

	return rActor, rDamage
end

local getWeaponAttackRollStructures_old
local function getWeaponAttackRollStructures_new(nodeWeapon, nAttack, ...)
	local rActor, rAttack = getWeaponAttackRollStructures_old(nodeWeapon, nAttack, ...)

	insertNodes(rActor, nodeWeapon)

	return rActor, rAttack
end

function onInit()
	getWeaponDamageRollStructures_old = CharManager.getWeaponDamageRollStructures
	CharManager.getWeaponDamageRollStructures = getWeaponDamageRollStructures_new

	getWeaponAttackRollStructures_old = CharManager.getWeaponAttackRollStructures
	CharManager.getWeaponAttackRollStructures = getWeaponAttackRollStructures_new
end
