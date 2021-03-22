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
    DB.addHandler(DB.getPath(node, ".misc_type"), "onUpdate", updateMiscEffects);
    DB.addHandler(DB.getPath(node, ".misc_modifier"), "onUpdate", updateMiscEffects);
    update();
end

function onClose()
    local node = getDatabaseNode();

    DB.removeHandler(DB.getPath(node, ".misc_type"), "onUpdate", updateMiscEffects);
    DB.removeHandler(DB.getPath(node, ".misc_modifier"), "onUpdate", updateMiscEffects);
end


function updateMiscEffects()
    if not Session.IsHost then
        return;
    end
    local nodeRecord = getDatabaseNode();
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","nodeRecord",nodeRecord);
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"misc_type","");
    --local sSuscept = DB.getValue(nodeRecord,"susceptiblity","");
    local nModifier = DB.getValue(nodeRecord,"misc_modifier",0);
    local sTypeChar = "";
    
    if (sType == "") then
        sType = "ac";
    end
    
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","sType",sType);
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","sSuscept",sSuscept);
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","nModifier",nModifier);
    if (nModifier ~= 0) then
        sEffectString = sEffectString .. sType:upper() .. ": " .. nModifier .. ";";
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end

function update()
end