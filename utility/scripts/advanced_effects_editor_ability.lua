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
    DB.addHandler(DB.getPath(node, ".ability_type"), "onUpdate", updateAbilityEffects);
    DB.addHandler(DB.getPath(node, ".ability"), "onUpdate", updateAbilityEffects);
    DB.addHandler(DB.getPath(node, ".ability_modifier"), "onUpdate", updateAbilityEffects);
    update();
end

function onClose()
    local node = getDatabaseNode();
    DB.removeHandler(DB.getPath(node, ".ability_type"), "onUpdate", updateAbilityEffects);
    DB.removeHandler(DB.getPath(node, ".ability"), "onUpdate", updateAbilityEffects);
    DB.removeHandler(DB.getPath(node, ".ability_modifier"), "onUpdate", updateAbilityEffects);
end

function updateAbilityEffects()
    if not Session.IsHost then
        return;
    end
    
    local nodeRecord = getDatabaseNode();
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"ability_type","");
    local sAbility = DB.getValue(nodeRecord,"ability","str");
    local nModifier = DB.getValue(nodeRecord,"ability_modifier",0);
	local sBonusType = DB.getValue(nodeRecord, "ability_bonus_type", "");
	
    local sTypeChar = "";
    
    if (sType == "modifier") or (sType == "") then
        sTypeChar = "";
    elseif (sType == "percent_modifier") then
        sTypeChar = "P";
    elseif (sType == "base") then 
        sTypeChar = "B";
    elseif (sType == "base_percent") then
        sTypeChar = "BP";
    end
	
    if (sAbility == "") then 
        sAbility = "str";
    end
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","sType",sType);
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","sAbility",sAbility);
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","nModifier",nModifier);
    
    if (sAbility ~= "") then
		if (sBonusType ~= "-") then
			sEffectString = sEffectString .. sTypeChar .. sAbility .. " " .. nModifier .. ";";
		else
			sEffectString = sEffectString .. sTypeChar .. sAbility .. " " .. nModifier .. ", " .. sBonusType .. ";";
		end
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end

function update()
end