--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit hideNpcEffects

-- if npc and no effect yet then we set the
-- visibility default to hidden
local function hideNpcEffects(nodeAdvEffect)
	if DB.getPath(nodeAdvEffect):match('npc%.id%-%d+') then
		return;
	end -- not for reference npcs
end

function onInit()
	local nodeAdvEffect = getDatabaseNode();

    name.setValue(DB.getValue(nodeAdvEffect, 'name', ''));
	hideNpcEffects(nodeAdvEffect)
end
