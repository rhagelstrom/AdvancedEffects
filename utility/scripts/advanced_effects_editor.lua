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
    DB.addHandler(DB.getPath(node, ".type"),"onUpdate", update);
    DB.addHandler(DB.getPath(node, ".save_type"), "onUpdate", updateSaveEffects);
    DB.addHandler(DB.getPath(node, ".save"), "onUpdate", updateSaveEffects);
    DB.addHandler(DB.getPath(node, ".save_modifier"), "onUpdate", updateSaveEffects);
	DB.addHandler(DB.getPath(node, ".save_bonus_type"), "onUpdate", updateSaveEffects);

    DB.addHandler(DB.getPath(node, ".ability_type"), "onUpdate", updateAbilityType);
    DB.addHandler(DB.getPath(node, ".ability"), "onUpdate", updateAbilityEffects);
    DB.addHandler(DB.getPath(node, ".ability_modifier"), "onUpdate", updateAbilityEffects);
	DB.addHandler(DB.getPath(node, ".ability_check"), "onUpdate", updateAbilityEffects);
	DB.addHandler(DB.getPath(node, ".ability_bonus_type"), "onUpdate", updateAbilityEffects);
	
    DB.addHandler(DB.getPath(node, ".susceptiblity_type"), "onUpdate", updateSusceptibleType);
    DB.addHandler(DB.getPath(node, ".susceptiblity"), "onUpdate", updateSusceptibleEffects);
    DB.addHandler(DB.getPath(node, ".susceptiblity_modifier"), "onUpdate", updateSusceptibleEffects);

    DB.addHandler(DB.getPath(node, ".misc_type"), "onUpdate", updateMiscType);
    DB.addHandler(DB.getPath(node, ".misc_modifier"), "onUpdate", updateMiscEffects);
	DB.addHandler(DB.getPath(node, ".misc_bonus_type"), "onUpdate", updateMiscEffects);
	
	DB.addHandler(DB.getPath(node, ".label_only"), "onUpdate", updateLabelOnlyEffects);
    update();
end

function onClose()
    local node = getDatabaseNode();
    DB.removeHandler(DB.getPath(node, ".type"),"onUpdate", update);
    DB.removeHandler(DB.getPath(node, ".save_type"), "onUpdate", updateSaveEffects);
    DB.removeHandler(DB.getPath(node, ".save"), "onUpdate", updateSaveEffects);
    DB.removeHandler(DB.getPath(node, ".save_modifier"), "onUpdate", updateSaveEffects);
	DB.removeHandler(DB.getPath(node, ".save_bonus_type"), "onUpdate", updateSaveEffects);

    DB.removeHandler(DB.getPath(node, ".ability_type"), "onUpdate", updateAbilityType);
    DB.removeHandler(DB.getPath(node, ".ability"), "onUpdate", updateAbilityEffects);
    DB.removeHandler(DB.getPath(node, ".ability_modifier"), "onUpdate", updateAbilityEffects);
    DB.removeHandler(DB.getPath(node, ".ability_check"), "onUpdate", updateAbilityEffects);
	DB.removeHandler(DB.getPath(node, ".ability_bonus_type"), "onUpdate", updateAbilityEffects);
	
    DB.removeHandler(DB.getPath(node, ".susceptiblity_type"), "onUpdate", updateSusceptibleType);
    DB.removeHandler(DB.getPath(node, ".susceptiblity"), "onUpdate", updateSusceptibleEffects);
    DB.removeHandler(DB.getPath(node, ".susceptiblity_modifier"), "onUpdate", updateSusceptibleEffects);

    DB.removeHandler(DB.getPath(node, ".misc_type"), "onUpdate", updateMiscType);
    DB.removeHandler(DB.getPath(node, ".misc_modifier"), "onUpdate", updateMiscEffects);
	DB.removeHandler(DB.getPath(node, ".misc_bonus_type"), "onUpdate", updateMiscEffects);
	
	DB.removeHandler(DB.getPath(node, ".label_only"), "onUpdate", updateLabelOnlyEffects);
end

function update()
    local node = getDatabaseNode();
    local sType = DB.getValue(node,"type","");

--  <values>save|ability|resist|immune|vulnerable</values>
    local bCustom = (sType == "");

    local bSave = (sType == "save");

    local bAbility = (sType == "ability");
	local bIsAbilityCheck = (DB.getValue(node, "ability_type", "modified") == "check");

    local bSusceptiblity = (sType == "susceptiblity");
	local bIsResist = (DB.getValue(node, "susceptiblity_type", "") == "resist");

    local bMisc = (sType == "misc");

    local bLabel = (sType == "label");
	
    local w = Interface.findWindow("advanced_effect_editor", "");
--Debug.console("advanced_effects_editor.lua","update","save",save);

	save_type.setVisible(bSave);
	save.setVisible(bSave);
	save_modifier.setVisible(bSave);
	save_bonus_type.setComboBoxVisible(bSave);
	if (bSave) then
		updateSaveEffects();
	end

	ability_type.setVisible(bAbility);
	ability.setVisible(bAbility and (not bIsAbilityCheck));
	ability_check.setVisible((bAbility and bIsAbilityCheck));
	ability_modifier.setVisible(bAbility);
	ability_bonus_type.setComboBoxVisible(bAbility);
	if (bAbility) then
		if bIsAbilityCheck then
			ability_modifier.setAnchor("left", "ability_check", "right", "relative", "10");
		else
			ability_modifier.setAnchor("left", "ability", "right", "relative", "10");
		end
		updateAbilityEffects();
	end

	susceptiblity_type.setVisible(bSusceptiblity);
	susceptiblity.setComboBoxVisible(bSusceptiblity);
	susceptiblity_modifier.setVisible(bSusceptiblity and bIsResist);
	if (bSusceptiblity) then
		updateSusceptibleEffects();
	end

	misc_type.setVisible(bMisc);
	misc_modifier.setVisible(bMisc);
	misc_bonus_type.setComboBoxVisible(bMisc);
	if (bMisc) then
		updateMiscEffects();
	end

	effect.setVisible(bCustom);

	label_only.setVisible(bLabel);
end

function updateSaveEffects()
    if not Session.IsHost then
        return;
    end
    local nodeRecord = getDatabaseNode();
--Debug.console("advanced_effects_editor.lua","updatesaveEffects","nodeRecord",nodeRecord);
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"save_type","modifier");
    local sSave = DB.getValue(nodeRecord,"save","fortitude");
    local nModifier = DB.getValue(nodeRecord,"save_modifier",0);
	local sBonusType = DB.getValue(nodeRecord, "save_bonus_type","");
	
    local sTypeChar = "";
    
    if (sType == "modifier") or (sType == "") then
        sTypeChar = "SAVE: ";
    elseif (sType == "base") then 
        sTypeChar = "B";
    end
    if (sSave == "") then
		sSave = "fortitude";
	end
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","sType",sType);
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","sSave",sSave);
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","nModifier",nModifier);
	if sBonusType ~= "" and sBonusType ~= "none" then
		sEffectString = sEffectString .. sTypeChar .. nModifier .. " " .. sBonusType .. ", " .. sSave:lower() .. ";";
	else
		sEffectString = sEffectString .. sTypeChar .. nModifier .. " " .. sSave:lower() .. ";";
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end

function updateAbilityType()
    local node = getDatabaseNode();

	local bIsAbilityCheck = (DB.getValue(node, "ability_type", "") == "check");

	ability.setVisible((not bIsAbilityCheck));
	ability_check.setVisible(bIsAbilityCheck);
	if bIsAbilityCheck then
		ability_modifier.setAnchor("left", "ability_check", "right", "relative", "10");
	else
		ability_modifier.setAnchor("left", "ability", "right", "relative", "10");
	end
	updateAbilityEffects();
end

function updateAbilityEffects()
    if not Session.IsHost then
        return;
    end
    
    local nodeRecord = getDatabaseNode();
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"ability_type","modified");
	local bIsCheck = (sType == "check");
	local sAbility = "";
	if bIsCheck then
		sAbility = DB.getValue(nodeRecord,"ability_check","strength");
		if (sAbility == "") then
			sAbility = "strength";
		end
	else
		sAbility = DB.getValue(nodeRecord,"ability","str");
		if (sAbility == "") then
			sAbility = "str";
		end
	end
    local nModifier = DB.getValue(nodeRecord,"ability_modifier",0);
	local sBonusType = DB.getValue(nodeRecord, "ability_bonus_type", "");
	
    local sTypeChar = "";
    
    if (sType == "modifier") or (sType == "") then
		sTypeChar = "";
	elseif (sType == "check") then
        sTypeChar = "ABIL: ";
    elseif (sType == "percent_modifier") then
        sTypeChar = "P";
    elseif (sType == "base") then 
        sTypeChar = "B";
    elseif (sType == "base_percent") then
        sTypeChar = "BP";
    end
	
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","sType",sType);
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","sAbility",sAbility);
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","nModifier",nModifier);
    
	if (sAbility ~= "") then
		if (bIsCheck) then
			if (sBonusType ~= "none") then
				sEffectString = sEffectString .. sTypeChar .. nModifier .. " " .. sBonusType .. ", " .. sAbility:lower() .. ";";
			else
				sEffectString = sEffectString .. sTypeChar .. nModifier .. " " .. sAbility:lower() .. ";";
			end
		else
			if (sBonusType ~= "none") then
				sEffectString = sEffectString .. sTypeChar .. sAbility:upper() .. ": " .. nModifier .. " " .. sBonusType .. ";";
			else
				sEffectString = sEffectString .. sTypeChar .. sAbility:upper() .. ": " .. nModifier .. ";";
			end
		end
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end

function updateSusceptibleType()
    local node = getDatabaseNode();
	local bIsResist = (DB.getValue(node, "susceptiblity_type", "") == "resist");
	susceptiblity_modifier.setVisible(bIsResist);
	updateSusceptibleEffects();
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
		DB.setValue(nodeRecord, "susceptiblity", "string", "acid");
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

function updateMiscType()
	local node = getDatabaseNode();
	local bIsNotHeal = (DB.getValue(node, "misc_type", "ac") ~= "heal");
	misc_bonus_type.setComboBoxVisible(bIsNotHeal);
	updateMiscEffects()
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
	local bIsNotHeal = (sType ~= "heal");
	local sBonusType = DB.getValue(nodeRecord, "misc_bonus_type", "");
	
    local sTypeChar = "";
    
    if (sType == "") then
        sType = "ac";
    end
    
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","sType",sType);
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","sSuscept",sSuscept);
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","nModifier",nModifier);
    if (nModifier ~= 0) then
		if bIsNotHeal and sBonusType ~= "" and sBonusType ~= "none" then
			sEffectString = sEffectString .. sType:upper() .. ": " .. nModifier .. " " .. sBonusType .. ";";
		else
			sEffectString = sEffectString .. sType:upper() .. ": " .. nModifier .. ";";
		end
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
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