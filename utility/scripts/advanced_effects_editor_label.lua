--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
local function updateLabelOnlyEffects(nodeRecord)
	local sLabelOnly = DB.getValue(nodeRecord, 'label_only', '');
	DB.setValue(nodeRecord, 'effect', 'string', sLabelOnly);
end

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

		DB.addHandler(DB.getPath(node, '.label_only'), 'onUpdate', updateLabelOnlyEffects);
	end
end

function onClose()
	if Session.IsHost then DB.removeHandler(DB.getPath(getDatabaseNode(), '.label_only'), 'onUpdate', updateLabelOnlyEffects); end
end
