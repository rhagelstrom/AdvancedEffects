--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
local function updateSusceptibleEffects(nodeRecord)
	if not Session.IsHost then return; end
	local sEffectString;
	local sType = DB.getValue(nodeRecord, 'susceptiblity_type', '');
	local sSuscept = DB.getValue(nodeRecord, 'susceptiblity', '');
	local nModifier = DB.getValue(nodeRecord, 'susceptiblity_modifier', 0);

	if (sType == '') then sType = 'immune'; end
	if (sSuscept == '') then sSuscept = 'acid'; end

	if sSuscept ~= '' then
		if sType == 'resist' then
			sEffectString = sType:upper() .. ': ' .. nModifier .. ' ' .. sSuscept .. ';';
		else
			sEffectString = sType:upper() .. ': ' .. sSuscept .. ';';
		end
	end

	DB.setValue(nodeRecord, 'effect', 'string', sEffectString);
end

-- luacheck: globals update
function update() end

function onInit()
	if Session.IsHost then
		local node = getDatabaseNode();
		-- if npc and no effect yet then we set the
		-- visibility default to hidden
		if (node.getPath():match('^npc%.id%-%d+')) then
			local sVisibility = DB.getValue(node, 'visibility');
			local sEffectString = DB.getValue(node, 'effect');
			if (sVisibility == '' and sEffectString == '') then DB.setValue(node, 'visibility', 'string', 'hide'); end
		end

		DB.addHandler(DB.getPath(node, '.susceptiblity_type'), 'onUpdate', updateSusceptibleEffects);
		DB.addHandler(DB.getPath(node, '.susceptiblity'), 'onUpdate', updateSusceptibleEffects);
		DB.addHandler(DB.getPath(node, '.susceptiblity_modifier'), 'onUpdate', updateSusceptibleEffects);
	end
end

function onClose()
	if Session.IsHost then
		local node = getDatabaseNode();
		DB.removeHandler(DB.getPath(node, '.susceptiblity_type'), 'onUpdate', updateSusceptibleEffects);
		DB.removeHandler(DB.getPath(node, '.susceptiblity'), 'onUpdate', updateSusceptibleEffects);
		DB.removeHandler(DB.getPath(node, '.susceptiblity_modifier'), 'onUpdate', updateSusceptibleEffects);
	end
end
