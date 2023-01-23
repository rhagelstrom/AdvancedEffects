--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals save_bonus_type ability_check ability_bonus_type susceptiblity_type susceptiblity susceptiblity_modifier
-- luacheck: globals misc_bonus_type misc_attack_type label_only
local function updateAbilityEffects()
	local nodeRecord = getDatabaseNode()
	local sEffectString = ''
	local sType = DB.getValue(nodeRecord, 'ability_type', 'modified')
	local bIsCheck = (sType == 'check')
	local sAbility
	if bIsCheck then
		sAbility = DB.getValue(nodeRecord, 'ability_check', 'strength')
		if sAbility == '' then sAbility = 'strength' end
	else
		sAbility = DB.getValue(nodeRecord, 'ability', 'str')
		if sAbility == '' then sAbility = 'str' end
	end
	local nModifier = DB.getValue(nodeRecord, 'ability_modifier', 0)
	local sBonusType = DB.getValue(nodeRecord, 'ability_bonus_type', '')

	local sTypeChar = ''

	if (sType == 'modifier') or (sType == '') then
		sTypeChar = ''
	elseif sType == 'check' then
		sTypeChar = 'ABIL: '
	elseif sType == 'percent_modifier' then
		sTypeChar = 'P'
	elseif sType == 'base' then
		sTypeChar = 'B'
	elseif sType == 'base_percent' then
		sTypeChar = 'BP'
	end

	if sAbility ~= '' then
		if bIsCheck then
			if sBonusType ~= 'none' then
				sEffectString = sEffectString .. sTypeChar .. nModifier .. ' ' .. sBonusType .. ', ' .. sAbility:lower() .. ';'
			else
				sEffectString = sEffectString .. sTypeChar .. nModifier .. ' ' .. sAbility:lower() .. ';'
			end
		else
			if sBonusType ~= 'none' then
				sEffectString = sEffectString .. sTypeChar .. sAbility:upper() .. ': ' .. nModifier .. ' ' .. sBonusType .. ';'
			else
				sEffectString = sEffectString .. sTypeChar .. sAbility:upper() .. ': ' .. nModifier .. ';'
			end
		end
	end

	DB.setValue(nodeRecord, 'effect', 'string', sEffectString)
end

local function updateSaveEffects()
	local nodeRecord = getDatabaseNode()
	local sEffectString = ''
	local sType = DB.getValue(nodeRecord, 'save_type', 'modifier')
	local sSave = DB.getValue(nodeRecord, 'save', 'fortitude')
	local nModifier = DB.getValue(nodeRecord, 'save_modifier', 0)
	local sBonusType = DB.getValue(nodeRecord, 'save_bonus_type', '')

	local sTypeChar = ''

	if (sType == 'modifier') or (sType == '') then
		sTypeChar = 'SAVE: '
	elseif sType == 'base' then
		sTypeChar = 'B'
	end
	if sSave == '' then sSave = 'fortitude' end

	if sBonusType ~= '' and sBonusType ~= 'none' then
		sEffectString = sEffectString .. sTypeChar .. nModifier .. ' ' .. sBonusType .. ', ' .. sSave:lower() .. ';'
	else
		sEffectString = sEffectString .. sTypeChar .. nModifier .. ' ' .. sSave:lower() .. ';'
	end

	DB.setValue(nodeRecord, 'effect', 'string', sEffectString)
end

local function updateMiscEffects()
	local nodeRecord = getDatabaseNode()
	local sEffectString = ''
	local sType = DB.getValue(nodeRecord, 'misc_type', '')
	local nModifier = DB.getValue(nodeRecord, 'misc_modifier', 0)
	local sBonusType = DB.getValue(nodeRecord, 'misc_bonus_type', 'none')
	local sAttackType = DB.getValue(nodeRecord, 'misc_attack_type', 'none')

	if sType == '' then sType = 'ac' end

	if nModifier ~= 0 then
		if sType == 'atk' and sAttackType ~= 'none' then
			if sBonusType ~= 'none' then
				sEffectString = sEffectString .. sType:upper() .. ': ' .. nModifier .. ' ' .. sBonusType .. ', ' .. sAttackType .. ';'
			else
				sEffectString = sEffectString .. sType:upper() .. ': ' .. nModifier .. ' ' .. ',' .. sAttackType .. ';'
			end
		elseif sType ~= 'heal' and sBonusType ~= 'none' then
			sEffectString = sEffectString .. sType:upper() .. ': ' .. nModifier .. ' ' .. sBonusType .. ';'
		else
			sEffectString = sEffectString .. sType:upper() .. ': ' .. nModifier .. ';'
		end
	end

	DB.setValue(nodeRecord, 'effect', 'string', sEffectString)
end

local function updateSusceptibleEffects()
	local nodeRecord = getDatabaseNode()
	local sEffectString = ''
	local sType = DB.getValue(nodeRecord, 'susceptiblity_type', '')
	local sSuscept = DB.getValue(nodeRecord, 'susceptiblity', '')
	local nModifier = DB.getValue(nodeRecord, 'susceptiblity_modifier', 0)

	if sType == '' then sType = 'immune' end
	if sSuscept == '' then
		sSuscept = 'acid'
		DB.setValue(nodeRecord, 'susceptiblity', 'string', 'acid')
	end

	if sType == 'resist' then
		sEffectString = sEffectString .. sType:upper() .. ': ' .. nModifier .. ' ' .. sSuscept .. ';'
	else
		sEffectString = sEffectString .. sType:upper() .. ': ' .. sSuscept .. ';'
	end

	DB.setValue(nodeRecord, 'effect', 'string', sEffectString)
end

-- luacheck: globals update
function update()
	local node = getDatabaseNode()
	local sType = DB.getValue(node, 'type', '')

	-- <values>save|ability|resist|immune|vulnerable</values>
	local bCustom = (sType == '')

	local bSave = (sType == 'save')

	local bAbility = (sType == 'ability')
	local bIsAbilityCheck = (DB.getValue(node, 'ability_type', 'modified') == 'check')

	local bSusceptiblity = (sType == 'susceptiblity')

	local bMisc = (sType == 'misc_ae')

	local bLabel = (sType == 'label')

	save_type.setVisible(bSave)
	save.setVisible(bSave)
	save_modifier.setVisible(bSave)
	save_bonus_type.setComboBoxVisible(bSave)
	if bSave and Session.IsHost then updateSaveEffects() end

	ability_type.setVisible(bAbility)
	ability.setVisible(bAbility and not bIsAbilityCheck)
	ability_check.setVisible((bAbility and bIsAbilityCheck))
	ability_modifier.setVisible(bAbility)
	ability_bonus_type.setComboBoxVisible(bAbility)
	if bAbility then
		if bIsAbilityCheck then
			ability_modifier.setAnchor('left', 'ability_check', 'right', 'relative', '10')
		else
			ability_modifier.setAnchor('left', 'ability', 'right', 'relative', '10')
		end

		if Session.IsHost then updateAbilityEffects() end
	end

	susceptiblity_type.setVisible(bSusceptiblity)
	susceptiblity.setComboBoxVisible(bSusceptiblity)
	susceptiblity_modifier.setVisible(bSusceptiblity and DB.getValue(node, 'susceptiblity_type', '') == 'resist')
	if bSusceptiblity and Session.IsHost then updateSusceptibleEffects() end

	misc_type.setVisible(bMisc)
	misc_modifier.setVisible(bMisc)
	misc_bonus_type.setComboBoxVisible(bMisc)
	misc_attack_type.setComboBoxVisible(bMisc and DB.getValue(node, 'misc_attack_type', '') == 'atk')
	if bMisc and Session.IsHost then updateMiscEffects() end

	effect.setVisible(bCustom)

	label_only.setVisible(bLabel)
end

local function updateAbilityType(node)
	local bIsAbilityCheck = DB.getValue(node) == 'check'

	ability.setVisible(not bIsAbilityCheck)
	ability_check.setVisible(bIsAbilityCheck)

	if bIsAbilityCheck then
		ability_modifier.setAnchor('left', 'ability_check', 'right', 'relative', '10')
	else
		ability_modifier.setAnchor('left', 'ability', 'right', 'relative', '10')
	end

	updateAbilityEffects()
end

local function updateMiscType(node)
	local sVal = DB.getValue(node)
	misc_bonus_type.setComboBoxVisible(sVal ~= 'heal')
	misc_attack_type.setComboBoxVisible(sVal == 'atk')

	updateMiscEffects()
end

local function updateLabelOnlyEffects(node) DB.setValue(DB.getParent(node), 'effect', 'string', DB.getValue(node) or '') end

local function updateSusceptibleType(node)
	susceptiblity_modifier.setVisible(DB.getValue(node) == 'resist')

	updateSusceptibleEffects()
end

-- if npc and no effect yet then we set the
-- visibility default to hidden
local function hideNpcEffects(nodeAdvEffect)
	if DB.getPath(nodeAdvEffect):match('npc%.id%-%d+') then return; end -- not for reference npcs

	local sVisibility = DB.getValue(nodeAdvEffect, 'visibility', '')
	local sEffectString = DB.getValue(nodeAdvEffect, 'effect', '')
	if sVisibility == '' and sEffectString == '' then DB.setValue(nodeAdvEffect, 'visibility', 'string', 'hide') end
end

function onInit()
	local nodeAdvEffect = getDatabaseNode()

	hideNpcEffects(nodeAdvEffect)
	update()

	if not Session.IsHost then
		return -- abort if code is running on client
	end

	DB.addHandler(DB.getPath(nodeAdvEffect, 'type'), 'onUpdate', update)

	DB.addHandler(DB.getPath(nodeAdvEffect, 'save_type'), 'onUpdate', updateSaveEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'save'), 'onUpdate', updateSaveEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'save_modifier'), 'onUpdate', updateSaveEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'save_bonus_type'), 'onUpdate', updateSaveEffects)

	DB.addHandler(DB.getPath(nodeAdvEffect, 'ability_type'), 'onUpdate', updateAbilityType)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'ability'), 'onUpdate', updateAbilityEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'ability_modifier'), 'onUpdate', updateAbilityEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'ability_check'), 'onUpdate', updateAbilityEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'ability_type'), 'onUpdate', updateAbilityEffects)

	DB.addHandler(DB.getPath(nodeAdvEffect, 'susceptiblity_type'), 'onUpdate', updateSusceptibleType)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'susceptiblity'), 'onUpdate', updateSusceptibleEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'susceptiblity_modifier'), 'onUpdate', updateSusceptibleEffects)

	DB.addHandler(DB.getPath(nodeAdvEffect, 'misc_type'), 'onUpdate', updateMiscType)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'misc_attack_type'), 'onUpdate', updateMiscEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'misc_bonus_type'), 'onUpdate', updateMiscEffects)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'misc_modifier'), 'onUpdate', updateMiscEffects)

	DB.addHandler(DB.getPath(nodeAdvEffect, 'label_only'), 'onUpdate', updateLabelOnlyEffects)
end

function onClose()
	if not Session.IsHost then
		return -- abort if code is running on client
	end

	local nodeAdvEffect = getDatabaseNode()

	DB.removeHandler(DB.getPath(nodeAdvEffect, 'type'), 'onUpdate', update)

	DB.removeHandler(DB.getPath(nodeAdvEffect, 'save_type'), 'onUpdate', updateSaveEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'save'), 'onUpdate', updateSaveEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'save_modifier'), 'onUpdate', updateSaveEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'save_bonus_type'), 'onUpdate', updateSaveEffects)

	DB.removeHandler(DB.getPath(nodeAdvEffect, 'ability_type'), 'onUpdate', updateAbilityType)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'ability'), 'onUpdate', updateAbilityEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'ability_modifier'), 'onUpdate', updateAbilityEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'ability_check'), 'onUpdate', updateAbilityEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'ability_type'), 'onUpdate', updateAbilityEffects)

	DB.removeHandler(DB.getPath(nodeAdvEffect, 'susceptiblity_type'), 'onUpdate', updateSusceptibleType)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'susceptiblity'), 'onUpdate', updateSusceptibleEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'susceptiblity_modifier'), 'onUpdate', updateSusceptibleEffects)

	DB.removeHandler(DB.getPath(nodeAdvEffect, 'misc_type'), 'onUpdate', updateMiscType)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'misc_attack_type'), 'onUpdate', updateMiscEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'misc_bonus_type'), 'onUpdate', updateMiscEffects)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'misc_modifier'), 'onUpdate', updateMiscEffects)

	DB.removeHandler(DB.getPath(nodeAdvEffect, 'label_only'), 'onUpdate', updateLabelOnlyEffects)
end
