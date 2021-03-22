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
    DB.addHandler(DB.getPath(node, ".save_type"), "onUpdate", updateSaveEffects);
    DB.addHandler(DB.getPath(node, ".save"), "onUpdate", updateSaveEffects);
    DB.addHandler(DB.getPath(node, ".save_modifier"), "onUpdate", updateSaveEffects);
end

function onClose()
    local node = getDatabaseNode();
    DB.removeHandler(DB.getPath(node, ".save_type"), "onUpdate", updateSaveEffects);
    DB.removeHandler(DB.getPath(node, ".save"), "onUpdate", updateSaveEffects);
    DB.removeHandler(DB.getPath(node, ".save_modifier"), "onUpdate", updateSaveEffects);
end

function onVisibilityChanged()
	save_type.setVisible(isVisible());
	save.setVisible(isVisible());
	save_modifier.setVisible(isVisible());
end

function updateSaveEffects()
    if not Session.IsHost then
        return;
    end
    local nodeRecord = getDatabaseNode();
--Debug.console("advanced_effects_editor.lua","updatesaveEffects","nodeRecord",nodeRecord);
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"save_type","");
    local sSave = DB.getValue(nodeRecord,"save","");
    local nModifier = DB.getValue(nodeRecord,"save_modifier",0);
    local sTypeChar = "";
    
    if (sType == "modifier") or (sType == "") then
        sTypeChar = "";
    elseif (sType == "base") then 
        sTypeChar = "B";
    end
    
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","sType",sType);
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","sSave",sSave);
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","nModifier",nModifier);
    if (sSave ~= "") then
        sEffectString = sEffectString .. sTypeChar .. sSave:upper() .. ": " .. nModifier .. ";";
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end
