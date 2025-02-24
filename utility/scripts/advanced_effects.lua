--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals update effect_description name

-- update display string
function update()
	local node = getDatabaseNode()
	-- display dice/mods for duration --celestian
	local sDuration = ''
	local dDurationDice = DB.getValue(node, 'durdice')
	local nDurationMod = DB.getValue(node, 'durmod', 0)
	local sDurDice = DiceManager.convertDiceToString(dDurationDice)
	if sDurDice ~= '' then
		sDuration = sDuration .. sDurDice
	end
	if nDurationMod ~= 0 and sDurDice ~= '' then
		local sSign = '+'
		if nDurationMod < 0 then
			sSign = ''
		end
		sDuration = sDuration .. sSign .. nDurationMod
	elseif nDurationMod ~= 0 then
		sDuration = sDuration .. nDurationMod
	end

	local sUnits = DB.getValue(node, 'durunit', '')
	if sDuration ~= '' then
		-- local nDuration = tonumber(sDuration);
		local bMultiple = (sDurDice ~= '') or (nDurationMod > 1)
		if sUnits == 'minute' then
			sDuration = sDuration .. ' minute' -- 5e uses minutes, not turns!
		elseif sUnits == 'hour' then
			sDuration = sDuration .. ' hour'
		elseif sUnits == 'day' then
			sDuration = sDuration .. ' day'
		else
			sDuration = sDuration .. ' rnd'
		end
		if bMultiple then
			sDuration = sDuration .. 's'
		end
	end
	local sActionOnly = '[ActionOnly]'
	local bActionOnly = (DB.getValue(node, 'actiononly', 0) ~= 0)
	if not bActionOnly then
		sActionOnly = ''
	end
	local sEffect = DB.getValue(node, 'effect', '')
	local sVis = DB.getValue(node, 'visibility', '')
	if sVis ~= '' then
		sVis = ' visibility [' .. sVis .. ']'
	end
	if sDuration ~= '' then
		sDuration = ' for [' .. sDuration .. ']'
	end
	local sFinal = '[' .. sEffect .. ']' .. sDuration .. sVis .. sActionOnly
	effect_description.setValue(sFinal)
end

function onInit()
	local nodeAdvEffect = getDatabaseNode()

	-- watch these variables and update display string if they change
	DB.addHandler(DB.getPath(nodeAdvEffect, 'effect'), 'onUpdate', update)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'durdice'), 'onUpdate', update)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'durmod'), 'onUpdate', update)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'durunit'), 'onUpdate', update)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'visibility'), 'onUpdate', update)
	DB.addHandler(DB.getPath(nodeAdvEffect, 'actiononly'), 'onUpdate', update)

	-- set name of effect to name of item so that, when effect
	-- is applied to someone, it shows where it came from properly
	local nodeAdvEffectSource = DB.getChild(nodeAdvEffect, '...')
	name.setValue(DB.getValue(nodeAdvEffectSource, 'name', ''))

	update()
end

function onClose()
	local nodeAdvEffect = getDatabaseNode()

	DB.removeHandler(DB.getPath(nodeAdvEffect, 'effect'), 'onUpdate', update)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'durdice'), 'onUpdate', update)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'durmod'), 'onUpdate', update)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'durunit'), 'onUpdate', update)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'visibility'), 'onUpdate', update)
	DB.removeHandler(DB.getPath(nodeAdvEffect, 'actiononly'), 'onUpdate', update)
end
