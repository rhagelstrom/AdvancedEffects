--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

--
-- Effects on Items, apply to character in CT
--

-- luacheck: globals CombatManagerKel hasEffectCondition_new notifyApplyDamage TurboManager

local function sendRawMessage(sUser, nGMOnly, msg)
	local sIdentity = nil
	if sUser and sUser ~= '' then sIdentity = User.getCurrentIdentity(sUser) or nil end
	if sIdentity then
		msg.icon = 'portrait_' .. User.getCurrentIdentity(sUser) .. '_chat'
	else
		msg.font = 'msgfont'
		msg.icon = 'roll_effect'
	end
	if nGMOnly == 1 then
		msg.secret = true
		Comm.addChatMessage(msg)
	elseif nGMOnly ~= 1 then
		-- Comm.addChatMessage(msg);
		Comm.deliverChatMessage(msg)
	end
end

-- build message to send that effect removed
local function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nGMOnly)
	local sUser = DB.getOwner(nodeChar)
	-- Build output message
	local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeChar), sUser)
	msg.text = "Advanced Effect ['" .. sLabel .. "'] "
	msg.text = msg.text .. 'removed [from ' .. DB.getValue(nodeChar, 'name', '') .. ']'
	-- HANDLE APPLIED BY SETTING
	local sEffSource = DB.getValue(nodeEffect, 'source_name', '')
	if sEffSource and sEffSource ~= '' then msg.text = msg.text .. ' [by ' .. DB.getValue(sEffSource .. '.name', '') .. ']' end
	sendRawMessage(sUser, nGMOnly, msg)
end

-- build message to send that effect added
local function sendEffectAddedMessage(nodeCT, rNewEffect, _, nGMOnly)
	local sUser = DB.getOwner(nodeCT)
	-- Build output message
	local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeCT), sUser)
	msg.text = "Advanced Effect ['" .. rNewEffect.sName .. "'] "
	msg.text = msg.text .. '-> [to ' .. DB.getValue(nodeCT, 'name', '') .. ']'
	if rNewEffect.sSource and rNewEffect.sSource ~= '' then
		msg.text = msg.text .. ' [by ' .. DB.getValue(rNewEffect.sSource .. '.name', '') .. ']'
	end
	sendRawMessage(sUser, nGMOnly, msg)
end

---	This function returns false if the effect is tied to an item and the item is not being used.
--	luacheck: globals isValidCheckEffect
function isValidCheckEffect(rActor, nodeEffect)
	if DB.getValue(nodeEffect, 'isactive', 0) == 0 then return end
	local bActionItemUsed, bActionOnly = false, false
	local sItemPath = ''

	local sSource = DB.getValue(nodeEffect, 'source_name', '')
	-- if source is a valid node and we can find "actiononly"
	-- setting then we set it.
	local node = DB.findNode(sSource)
	if node then
		local nodeItem = DB.getChild(node, '...')
		if nodeItem then
			sItemPath = DB.getPath(nodeItem)
			bActionOnly = (DB.getValue(node, 'actiononly', 0) ~= 0)
		end
	end

	if sItemPath and sItemPath ~= '' then
		-- if there is a nodeWeapon do some sanity checking
		if rActor.nodeItem then
			-- here is where we get the node path of the item, not the
			-- effectslist entry
			if bActionOnly and (sItemPath == rActor.nodeItem) then bActionItemUsed = true end
		end

		-- if there is a nodeAmmo do some sanity checking
		if AmmunitionManager and rActor.nodeAmmo then
			-- here is where we get the node path of the item, not the
			-- effectslist entry
			if bActionOnly and (sItemPath == rActor.nodeAmmo) then bActionItemUsed = true end
		end
	end

	if bActionOnly and not bActionItemUsed then return false end
	return true
end

local function getEffectsByType_new(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly) -- luacheck: ignore (cyclomatic complexity)
	local results = {}
	if not rActor then return results end

	-- Set up filters
	local aRangeFilter = {}
	local aOtherFilter = {}
	if aFilter then
		for _, v in pairs(aFilter) do
			if type(v) ~= 'string' then
				table.insert(aOtherFilter, v)
			elseif StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v)
			else
				table.insert(aOtherFilter, v)
			end
		end
	end
	local aEffects
	if TurboManager then
		aEffects = TurboManager.getMatchedEffects(rActor, sEffectType)
	else
		aEffects = DB.getChildList(ActorManager.getCTNode(rActor), 'effects')
	end
	-- Iterate through effects
	for _, v in ipairs(aEffects) do
		local nActive = DB.getValue(v, 'isactive', 0)
		-- Check effect is from used weapon.
		if isValidCheckEffect(rActor, v) then
			-- Check targeting
			local bTargeted = EffectManager.isTargetedEffect(v)
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local sLabel = DB.getValue(v, 'label', '')
				local aEffectComps = EffectManager.parseEffect(sLabel)

				-- Look for type/subtype match
				local nMatch = 0
				for kEffectComp, sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp)
					-- Handle conditionals
					if rEffectComp.type == 'IF' then
						if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then break end
					elseif rEffectComp.type == 'IFT' then
						if not rFilterActor then break end
						if not EffectManager35E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then break end
						bTargeted = true

						-- Compare other attributes
					else
						-- Strip energy/bonus types for subtype comparison
						local aEffectRangeFilter = {}
						local aEffectOtherFilter = {}

						local aComponents = {}
						for _, vPhrase in ipairs(rEffectComp.remainder) do
							local nTempIndexOR = 0
							local aPhraseOR = {}
							repeat
								local nStartOR, nEndOR = vPhrase:find('%s+or%s+', nTempIndexOR)
								if nStartOR then
									table.insert(aPhraseOR, vPhrase:sub(nTempIndexOR, nStartOR - nTempIndexOR))
									nTempIndexOR = nEndOR
								else
									table.insert(aPhraseOR, vPhrase:sub(nTempIndexOR))
								end
							until nStartOR == nil

							for _, vPhraseOR in ipairs(aPhraseOR) do
								local nTempIndexAND = 0
								repeat
									local nStartAND, nEndAND = vPhraseOR:find('%s+and%s+', nTempIndexAND)
									if nStartAND then
										local sInsert = StringManager.trim(vPhraseOR:sub(nTempIndexAND, nStartAND - nTempIndexAND))
										table.insert(aComponents, sInsert)
										nTempIndexAND = nEndAND
									else
										local sInsert = StringManager.trim(vPhraseOR:sub(nTempIndexAND))
										table.insert(aComponents, sInsert)
									end
								until nStartAND == nil
							end
						end
						local j = 1
						while aComponents[j] do
							if
								StringManager.contains(DataCommon.dmgtypes, aComponents[j])
								or StringManager.contains(DataCommon.bonustypes, aComponents[j])
								or aComponents[j] == 'all'
							then -- luacheck: ignore
								-- Skip
							elseif StringManager.contains(DataCommon.rangetypes, aComponents[j]) then
								table.insert(aEffectRangeFilter, aComponents[j])
							else
								table.insert(aEffectOtherFilter, aComponents[j])
							end

							j = j + 1
						end

						-- Check for match
						local comp_match = false
						if rEffectComp.type == sEffectType then
							-- Check effect targeting
							if bTargetedOnly and not bTargeted then
								comp_match = false
							else
								comp_match = true
							end

							-- Check filters
							if #aEffectRangeFilter > 0 then
								local bRangeMatch = false
								for _, v2 in pairs(aRangeFilter) do
									if StringManager.contains(aEffectRangeFilter, v2) then
										bRangeMatch = true
										break
									end
								end
								if not bRangeMatch then comp_match = false end
							end
							if #aEffectOtherFilter > 0 then
								local bOtherMatch = false
								for _, v2 in pairs(aOtherFilter) do
									if type(v2) == 'table' then
										local bOtherTableMatch = true
										for _, v3 in pairs(v2) do
											if not StringManager.contains(aEffectOtherFilter, v3) then
												bOtherTableMatch = false
												break
											end
										end
										if bOtherTableMatch then
											bOtherMatch = true
											break
										end
									elseif StringManager.contains(aEffectOtherFilter, v2) then
										bOtherMatch = true
										break
									end
								end
								if not bOtherMatch then comp_match = false end
							end
						end

						-- Match!
						if comp_match then
							nMatch = kEffectComp
							if nActive == 1 then table.insert(results, rEffectComp) end
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, 'isactive', 'number', 1)
					else
						local sApply = DB.getValue(v, 'apply', '')
						if sApply == 'action' then
							EffectManager.notifyExpire(v, 0)
						elseif sApply == 'roll' then
							EffectManager.notifyExpire(v, 0, true)
						elseif sApply == 'single' then
							EffectManager.notifyExpire(v, nMatch, true)
						end
					end
				end
			end -- END TARGET CHECK
		end -- END ACTIVE CHECK
	end -- END EFFECT LOOP

	return results
end

-- this will be used to manage PC/NPC effectslist objects
-- nodeCharEffect: node in effectlist on PC/NPC
-- nodeEntry: node in combat tracker for PC/NPC
local function updateCharEffect(nodeCharEffect, nodeEntry)
	local sLabel = DB.getValue(nodeCharEffect, 'effect', '')
	local nRollDuration
	local dDurationDice = DB.getValue(nodeCharEffect, 'durdice')
	local nModDice = DB.getValue(nodeCharEffect, 'durmod', 0)
	if dDurationDice and dDurationDice ~= '' then
		nRollDuration = DiceManager.evalDice(dDurationDice, nModDice)
	else
		nRollDuration = nModDice
	end
	local nGMOnly = 0
	local sVisibility = DB.getValue(nodeCharEffect, 'visibility')
	if sVisibility == 'show' then
		nGMOnly = 0
	elseif sVisibility == 'hide' then
		nGMOnly = 1
	end
	if not ActorManager.isPC(nodeEntry) then
		nGMOnly = 1 -- npcs effects always hidden from PCs/chat when we first drag/drop into CT
	end

	local rEffect = {}
	rEffect.nDuration = nRollDuration
	-- rEffect.sName = sName .. ";" .. sLabel;
	rEffect.sName = sLabel
	rEffect.sLabel = sLabel
	rEffect.sUnits = DB.getValue(nodeCharEffect, 'durunit', '')
	rEffect.nInit = 0
	rEffect.sSource = DB.getPath(nodeEntry)
	rEffect.nGMOnly = nGMOnly
	rEffect.sApply = DB.getValue(nodeCharEffect, 'apply', '');
	rEffect.sChangeState = DB.getValue(nodeCharEffect, 'changestate', '');
	rEffect.sName = EffectManager35E.evalEffect(nodeEntry, rEffect.sLabel) -- handle (N)PC Effects

	sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nGMOnly, User.getUsername())
	EffectManager.addEffect('', '', nodeEntry, rEffect, false)
end

-- flip through all npc effects (generally do this in addNPC()/addPC())
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeCT: node in combat tracker for PC/NPC
local function updateCharEffects(nodeChar, nodeCT)
	for _, nodeCharEffect in ipairs(DB.getChildList(nodeChar, 'effectlist')) do
		updateCharEffect(nodeCharEffect, nodeCT)
	end -- for item's effects list
end

--
--	REPLACEMENT FUNCTIONS
--

local weaponPathKey = 'nodeWeapon'
local ammoPathKey = 'nodeAmmo'

--	replace CoreRPG ActionsManager manager_actions.lua encodeActionForDrag() with this
local encodeActionForDrag_old
local function encodeActionForDrag_new(draginfo, rSource, sType, rRolls, ...)
	encodeActionForDrag_old(draginfo, rSource, sType, rRolls, ...)

	if not rSource then return end
	if rSource.nodeItem and rSource.nodeItem ~= '' then draginfo.setMetaData(weaponPathKey, rSource.nodeItem) end
	if AmmunitionManager and rSource.nodeAmmo and rSource.nodeAmmo ~= '' then draginfo.setMetaData(ammoPathKey, rSource.nodeAmmo) end
end

--	replace CoreRPG ActionsManager manager_actions.lua decodeActors() with this
local decodeActors_old
local function decodeActors_new(draginfo, ...)
	local rSource, aTargets = decodeActors_old(draginfo, ...)

	local sNodeWeapon = draginfo.getMetaData(weaponPathKey)
	if sNodeWeapon and sNodeWeapon ~= '' then rSource.nodeItem = sNodeWeapon end

	local sNodeAmmo = draginfo.getMetaData(ammoPathKey)
	if AmmunitionManager and (sNodeAmmo and sNodeAmmo ~= '') then rSource.nodeAmmo = sNodeAmmo end

	return rSource, aTargets
end

-- update single effect for item
local function updateItemEffect(nodeItemEffect, sName, nodeChar, bEquipped, bIdentified)
	local sItemSource = DB.getPath(nodeItemEffect)
	local sLabel = DB.getValue(nodeItemEffect, 'effect', '')
	if not sLabel or sLabel == '' then return end -- abort if we don't have effect string
	local bFound = false
	for _, nodeEffect in ipairs(DB.getChildList(nodeChar, 'effects')) do
		local nActive = DB.getValue(nodeEffect, 'isactive', 0)
		local nGMOnly = DB.getValue(nodeEffect, 'isgmonly', 0)
		if nActive ~= 0 then
			local sEffSource = DB.getValue(nodeEffect, 'source_name', '')
			if sEffSource == sItemSource then
				bFound = true
				if not bEquipped then
					sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nGMOnly)
					DB.deleteNode(nodeEffect)
					break
				end -- not equipped
			end -- effect source == item source
		end -- was active
	end -- nodeEffect for
	if bFound or not bEquipped then return end
	local rEffect = {}
	local nRollDuration
	local dDurationDice = DB.getValue(nodeItemEffect, 'durdice')
	local nModDice = DB.getValue(nodeItemEffect, 'durmod', 0)

	if dDurationDice and dDurationDice ~= '' then
		nRollDuration = DiceManager.evalDice(dDurationDice, nModDice)
	else
		nRollDuration = nModDice
	end
	local nGMOnly = 0
	if DB.getValue(nodeItemEffect, 'visibility') == 'hide' then
		nGMOnly = 1
	elseif not bIdentified then
		nGMOnly = 1
	end

	if not ActorManager.isPC(nodeChar) then
		if DB.getValue(nodeChar, 'tokenvis') ~= 1 then
			nGMOnly = 1 -- hide if token not visible
		end
	end

	rEffect.nDuration = nRollDuration
	if DB.getValue(nodeItemEffect, 'type', '') ~= 'label' then
		rEffect.sName = sName .. ';' .. sLabel
	else
		rEffect.sName = sLabel
	end
	rEffect.sLabel = sLabel
	rEffect.sUnits = DB.getValue(nodeItemEffect, 'durunit', '')
	rEffect.nInit = 0
	rEffect.sSource = sItemSource
	rEffect.nGMOnly = nGMOnly
	rEffect.sApply = DB.getValue(nodeItemEffect, 'apply', '');
	rEffect.sChangeState = DB.getValue(nodeItemEffect, 'changestate', '');
	rEffect.sName = EffectManager35E.evalEffect(nodeChar, rEffect.sLabel) -- handle (N)PC Effects

	sendEffectAddedMessage(nodeChar, rEffect, sLabel, nGMOnly)
	EffectManager.addEffect('', '', nodeChar, rEffect, false)
end

-- luacheck: globals updateItemEffects
function updateItemEffects(nodeItem)
	local nodeChar = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(nodeItem, '...')))
	if not nodeChar then return end

	local bEquipped = not DB.getPath(nodeItem):match('inventorylist') or DB.getValue(nodeItem, 'carried', 1) == 2
	local bID = not DB.getPath(nodeItem):match('inventorylist') or DB.getValue(nodeItem, 'isidentified', 1) == 1
	-- local bOptionID = OptionsManager.isOption("MIID", "on");
	-- if not bOptionID then
	-- bID = true;
	-- end

	for _, nodeItemEffect in ipairs(DB.getChildList(nodeItem, 'effectlist')) do
		updateItemEffect(nodeItemEffect, DB.getValue(nodeItem, 'name', ''), nodeChar, bEquipped, bID)
	end

	return true
end

-- This function calls the original addPC function.
-- Then it looks through the character's inventory for carried items with attached effects.
-- While effects are checked for item carried status in the updateItemEffect function,
-- the items are first checked here to reduce excess calculations (since the check in updateItemEffect
-- is to facilitate deletion of effects that are no longer applicable).
-- Lastly it looks through the character's attached effects and adds those.
local addPC_old
local function addPC_new(tCustom, ...)
	addPC_old(tCustom, ...) -- Call original function

	-- check each inventory item for effects that need to be applied
	for _, nodeItem in ipairs(DB.getChildList(tCustom['nodeRecord'], 'inventorylist')) do
		if DB.getValue(nodeItem, 'carried') == 2 then updateItemEffects(nodeItem) end
	end

	-- check each special ability for effects that need to be applied
	local tFields = { 'specialabilitylist', 'featlist', 'proficiencylist', 'traitlist' }
	for _, fieldName in pairs(tFields) do
		for _, nodeAbility in ipairs(DB.getChildList(tCustom['nodeRecord'], fieldName)) do
			updateItemEffects(nodeAbility)
		end
	end

	-- check for and apply character effects
	updateCharEffects(tCustom['nodeRecord'], tCustom['nodeCT'])
end

local addNPC_old
local function addNPC_new(tCustom, ...)
	addNPC_old(tCustom, ...) -- Call original function

	updateCharEffects(tCustom['nodeRecord'], tCustom['nodeCT'])
end

function hasEffectCondition_new(rActor, sEffect) return EffectManager35E.hasEffect(rActor, sEffect, nil, false, true) end

--	replace 3.5E EffectManager35E manager_effect_35E.lua hasEffect() with this
local function hasEffect_new(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	if not sEffect or not rActor then return false end
	local sLowerEffect = sEffect:lower()

	-- Iterate through each effect
	local aMatch = {}
	local aEffects
	if TurboManager then
		aEffects = TurboManager.getMatchedEffects(rActor, sEffect)
	else
		aEffects = DB.getChildList(ActorManager.getCTNode(rActor), 'effects')
	end
	for _, v in ipairs(aEffects) do
		local nActive = DB.getValue(v, 'isactive', 0)

		-- COMPATIBILITY FOR ADVANCED EFFECTS
		-- to add support for AE in other extensions, make this change
		-- original line: if nActive ~= 0 then
		if (not AdvancedEffects and nActive ~= 0) or (AdvancedEffects and AdvancedEffects.isValidCheckEffect(rActor, v)) then
			-- END COMPATIBILITY FOR ADVANCED EFFECTS

			-- Parse each effect label
			local sLabel = DB.getValue(v, 'label', '')
			local bTargeted = EffectManager.isTargetedEffect(v)
			local aEffectComps = EffectManager.parseEffect(sLabel)

			-- Iterate through each effect component looking for a type match
			local nMatch = 0
			for kEffectComp, sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp)
				-- Check conditionals
				if rEffectComp.type == 'IF' then
					if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then break end
				elseif rEffectComp.type == 'IFT' then
					if not rTarget then break end
					if not EffectManager35E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then break end

					-- Check for match
				elseif rEffectComp.original:lower() == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then nMatch = kEffectComp end
					elseif not bTargetedOnly then
						nMatch = kEffectComp
					end
				end
			end

			-- If matched, then remove one-off effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, 'isactive', 'number', 1)
				else
					table.insert(aMatch, v)
					local sApply = DB.getValue(v, 'apply', '')
					if sApply == 'action' then
						EffectManager.notifyExpire(v, 0)
					elseif sApply == 'roll' then
						EffectManager.notifyExpire(v, 0, true)
					elseif sApply == 'single' then
						EffectManager.notifyExpire(v, nMatch, true)
					end
				end
			end
		end
	end

	if #aMatch > 0 then return true end
	return false
end

function handleApplyDamage(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode)
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode)
	if rTarget then rTarget.nOrder = msgOOB.nTargetOrder end

	if rSource then
		rSource.nodeItem = msgOOB.nodeItem
		rSource.nodeAmmo = msgOOB.nodeAmmo
		rSource.nodeWeapon = msgOOB.nodeWeapon
	end

	local nTotal = tonumber(msgOOB.nTotal) or 0
	ActionDamage.applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sRollType, msgOOB.sDamage, nTotal)
end

function notifyApplyDamage(rSource, rTarget, bSecret, sRollType, sDesc, nTotal)
	if not rTarget then return end

	local msgOOB = {}
	msgOOB.type = ActionDamage.OOB_MSGTYPE_APPLYDMG

	if bSecret then
		msgOOB.nSecret = 1
	else
		msgOOB.nSecret = 0
	end
	msgOOB.sRollType = sRollType
	msgOOB.nTotal = nTotal
	msgOOB.sDamage = sDesc

	if rSource then
		msgOOB.nodeItem = rSource.nodeItem
		msgOOB.nodeAmmo = rSource.nodeAmmo
		msgOOB.nodeWeapon = rSource.nodeWeapon
	end

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource)
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget)
	msgOOB.nTargetOrder = rTarget.nOrder

	Comm.deliverOOBMessage(msgOOB, '')
end

-- add the effect if the item is equipped and doesn't exist already
function onInit()
	-- CoreRPG replacements
	encodeActionForDrag_old = ActionsManager.encodeActionForDrag
	ActionsManager.encodeActionForDrag = encodeActionForDrag_new

	decodeActors_old = ActionsManager.decodeActors
	ActionsManager.decodeActors = decodeActors_new

	addPC_old = CombatRecordManager.addPC
	CombatRecordManager.addPC = addPC_new

	addNPC_old = CombatRecordManager.addNPC
	CombatRecordManager.addNPC = addNPC_new

	-- 3.5E replacements
	if not CombatManagerKel then
		EffectManager35E.getEffectsByType = getEffectsByType_new
		EffectManager35E.hasEffect = hasEffect_new
		EffectManager35E.hasEffectCondition = hasEffectCondition_new
		ActionDamage.notifyApplyDamage = notifyApplyDamage
		ActionDamage.handleApplyDamage = handleApplyDamage
		OOBManager.registerOOBMsgHandler(ActionDamage.OOB_MSGTYPE_APPLYDMG, handleApplyDamage)
	end

	-- option in house rule section, enable/disable allow PCs to edit advanced effects.
	OptionsManager.registerOption2('ADND_AE_EDIT', false, 'option_header_houserule', 'option_label_ADND_AE_EDIT', 'option_entry_cycler', {
		labels = 'option_val_on',
		values = 'enabled',
		baselabel = 'option_val_off',
		baseval = 'disabled',
		default = 'disabled',
	})
end
