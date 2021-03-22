-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    local node = getDatabaseNode();
    --DB.getValue(node,"save_type","modifier");
    -- if npc and no effect yet then we set the 
    -- visibility default to hidden
    if (node.getPath():match("^npc%.id%-%d+")) then
        local sVisibility = DB.getValue(node,"visibility");
        local sEffectString = DB.getValue(node,"effect");
        if (sVisibility == "" and sEffectString == "") then
            DB.setValue(node,"visibility","string","hide");
        end
    end
	DB.addHandler(DB.getPath(node, ".label_only"), "onUpdate", updateLabelOnlyEffects);
    update();
end

function onClose()
    local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, ".label_only"), "onUpdate", updateLabelOnlyEffects);
end

function updateLabelOnlyEffects()
	if not Session.IsHost then
		return;
	end
	local nodeRecord = getDatabaseNode();
	local sEffectString = "";
	local sLabelOnly = DB.getValue(nodeRecord, "label_only", "");
	DB.setValue(nodeRecord, "effect", "string", sLabelOnly);
end

function update()
end