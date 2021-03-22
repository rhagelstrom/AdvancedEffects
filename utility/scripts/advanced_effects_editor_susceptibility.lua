--
--
--
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
    DB.addHandler(DB.getPath(node, ".susceptiblity_type"), "onUpdate", updateSusceptibleEffects);
    DB.addHandler(DB.getPath(node, ".susceptiblity"), "onUpdate", updateSusceptibleEffects);
    DB.addHandler(DB.getPath(node, ".susceptiblity_modifier"), "onUpdate", updateSusceptibleEffects);
    update();
end

function onClose()
    local node = getDatabaseNode();
    DB.removeHandler(DB.getPath(node, ".susceptiblity_type"), "onUpdate", updateSusceptibleEffects);
    DB.removeHandler(DB.getPath(node, ".susceptiblity"), "onUpdate", updateSusceptibleEffects);
    DB.removeHandler(DB.getPath(node, ".susceptiblity_modifier"), "onUpdate", updateSusceptibleEffects);
end

function updateSusceptibleEffects()
    if not Session.IsHost then
        return;
    end
    local nodeRecord = getDatabaseNode();
--Debug.console("advanced_effects_editor.lua","updateSusceptibleEffects","nodeRecord",nodeRecord);
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"susceptiblity_type","");
    local sSuscept = DB.getValue(nodeRecord,"susceptiblity","");
    local nModifier = DB.getValue(nodeRecord,"susceptiblity_modifier",0);
    local sTypeChar = "";
    
    if (sType == "") then
        sType = "immune";
    end
    if (sSuscept == "") then
        sSuscept = "acid";
    end
    
--Debug.console("advanced_effects_editor.lua","updateSusceptibleEffects","sType",sType);
--Debug.console("advanced_effects_editor.lua","updateSusceptibleEffects","sSuscept",sSuscept);
--Debug.console("advanced_effects_editor.lua","updateSusceptibleEffects","nModifier",nModifier);
    if (sSuscept ~= "") then
		if sType == "resist" then
			sEffectString = sEffectString .. sType:upper() .. ": " .. nModifier .. " " .. sSuscept .. ";";
		else
			sEffectString = sEffectString .. sType:upper() .. ": " .. sSuscept .. ";";
		end
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end

function update()
end