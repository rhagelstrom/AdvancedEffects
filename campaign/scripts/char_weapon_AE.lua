--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onDamageChanged
function onDamageChanged()
	local nodeWeapon = getDatabaseNode()
	local nodeChar = nodeWeapon.getChild('...')
	local rActor = ActorManager.resolveActor(nodeChar)

	local aDamage = {}
	local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, 'damagelist'))
	for _, v in ipairs(aDamageNodes) do
		local aDice = DB.getValue(v, 'dice', {})
		local nMod = DB.getValue(v, 'bonus', 0)

		local sAbility = DB.getValue(v, 'stat', '')

		-- ADDITION FOR ADVANCED EFFECTS
		if sAbility == 'base' then
			sAbility = 'strength'
			if DB.getValue(nodeWeapon, 'type') == 1 then sAbility = 'dexterity' end
		end
		-- END ADDITION FOR ADVANCED EFFECTS

		if sAbility ~= '' then
			local nMult = DB.getValue(v, 'statmult', 1)
			local nMax = DB.getValue(v, 'statmax', 0)
			local nAbilityBonus = ActorManager35E.getAbilityBonus(rActor, sAbility)
			if nMax > 0 then nAbilityBonus = math.min(nAbilityBonus, nMax) end
			if nAbilityBonus > 0 and nMult ~= 1 then nAbilityBonus = math.floor(nMult * nAbilityBonus) end
			nMod = nMod + nAbilityBonus
		end

		if #aDice > 0 or nMod ~= 0 then
			local sDamage = StringManager.convertDiceToString(DB.getValue(v, 'dice', {}), nMod)
			local sType = DB.getValue(v, 'type', '')
			if sType ~= '' then sDamage = sDamage .. ' ' .. sType end
			table.insert(aDamage, sDamage)
		end
	end

	damageview.setValue(table.concat(aDamage, '\n+ '))
end
