--
-- Effects on Abilities, apply to character in CT
--
---	This function removes existing effects and re-parses them.
--	First it finds any effects that have this ability as the source and removes those effects.
--	Then it calls updateAbilityEffects to re-parse the current/correct effects.
local function replaceAbilityEffects(nodeAbility)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(nodeAbility, '...')))
	if nodeCT then
		local bFound
		for _, nodeEffect in pairs(DB.getChildren(nodeCT, 'effects')) do
			local sEffSource = DB.getValue(nodeEffect, 'source_name', '')
			-- see if the node exists and if it's in an effectlist
			local nodeAbilitySource = DB.findNode(sEffSource)
			if nodeAbilitySource and string.match(sEffSource, 'effectlist') then
				if DB.getChild(nodeAbilitySource, '...') == nodeAbility then
					DB.deleteNode(nodeEffect) -- remove existing effect
					bFound = true
					AdvancedEffects.updateItemEffects(nodeAbility)
				end
			end
		end
		return bFound
	end
end

local function addAbilityEffect(node)
	local nodeAbility = DB.getParent(node)
	if nodeAbility then AdvancedEffects.updateItemEffects(nodeAbility) end
end

--	This function changes the associated effects when ability effect lists are changed.
local function updateAbilityEffectsForEdit(node)
	local nodeAbility = DB.getChild(node, '....')
	if nodeAbility and not replaceAbilityEffects(nodeAbility) then AdvancedEffects.updateItemEffects(nodeAbility) end
end

---	This function checks to see if an effect is missing its associated ability.
--	If an associated ability isn't found, it removes the effect as the ability has been removed
local function checkEffectsAfterDelete(nodeChar)
	local sUser = User.getUsername()
	for _, nodeEffect in pairs(DB.getChildren(nodeChar, 'effects')) do
		local sLabel = DB.getValue(nodeEffect, 'label', '')
		local sEffSource = DB.getValue(nodeEffect, 'source_name', '')
		-- see if the node exists and if it's in an effectlist
		local bDeleted = (not DB.findNode(sEffSource) and string.match(sEffSource, 'effectlist'))
		if bDeleted then
			local msg = { font = 'msgfont', icon = 'roll_effect' }
			msg.text = "Effect ['" .. sLabel .. "'] "
			msg.text = msg.text .. 'removed [from ' .. DB.getValue(nodeChar, 'name', '') .. ']'
			-- HANDLE APPLIED BY SETTING
			if sEffSource and sEffSource ~= '' then msg.text = msg.text .. ' [by Deletion]' end
			if EffectManager.isGMEffect(nodeChar, nodeEffect) then
				if sUser == '' then
					msg.secret = true
					Comm.addChatMessage(msg)
				elseif sUser ~= '' then
					Comm.addChatMessage(msg)
					Comm.deliverChatMessage(msg, sUser)
				end
			else
				Comm.deliverChatMessage(msg)
			end
			DB.deleteNode(nodeEffect)
		end
	end
end

---	This function checks to see if an effect is missing its associated ability.
--	If an associated ability isn't found, it removes the effect as the ability has been removed
local function updateFromDeletedAbility(node)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getParent(node)))
	if nodeCT then checkEffectsAfterDelete(nodeCT) end
end

---	Triggers after an effect on an ability is deleted, causing a recheck of the effects in the combat tracker
local function removeEffectOnAbilityEffectDelete(node)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(node, '....')))
	if nodeCT then checkEffectsAfterDelete(nodeCT) end
end

function onInit()
	local tNodes = { 'specialabilitylist', 'featlist', 'proficiencylist', 'traitlist' }
	if Session.IsHost then
		for _, sName in ipairs(tNodes) do
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist', 'onChildAdded', addAbilityEffect)
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit)
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit)
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit)
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit)
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit)
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit)
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit)
			DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete)
			DB.addHandler('charsheet.*.' .. sName .. '', 'onChildDeleted', updateFromDeletedAbility)
		end
	end
end
