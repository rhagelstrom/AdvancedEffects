--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
local function updateMiscEffects(nodeRecord)
	local sEffectString = '';
	local sType = DB.getValue(nodeRecord, 'misc_type', '');
	-- local sSuscept = DB.getValue(nodeRecord,"susceptiblity","");
	local nModifier = DB.getValue(nodeRecord, 'misc_modifier', 0);

	if (sType == '') then sType = 'ac'; end

	if (nModifier ~= 0) then sEffectString = sEffectString .. sType:upper() .. ': ' .. nModifier .. ';'; end

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

		DB.addHandler(DB.getPath(node, '.misc_type'), 'onUpdate', updateMiscEffects);
		DB.addHandler(DB.getPath(node, '.misc_modifier'), 'onUpdate', updateMiscEffects);
	end
end

function onClose()
	if Session.IsHost then
		local node = getDatabaseNode();

		DB.removeHandler(DB.getPath(node, '.misc_type'), 'onUpdate', updateMiscEffects);
		DB.removeHandler(DB.getPath(node, '.misc_modifier'), 'onUpdate', updateMiscEffects);
	end
end
