--
-- Effects on Items, apply to character in CT
--
--
-- add the effect if the item is equipped and doesn't exist already
function onInit()
	if Session.IsHost then
		-- watch the combatracker/npc inventory list
		DB.addHandler("combattracker.list.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
		DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("combattracker.list.*.inventorylist.*.isidentified", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("combattracker.list.*.inventorylist", "onChildDeleted", updateFromDeletedInventory);

		-- watch the character/pc inventory list
		DB.addHandler("charsheet.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
		DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", updateItemEffectsForEdit);
		DB.addHandler("charsheet.*.inventorylist", "onChildDeleted", updateFromDeletedInventory);
	end
	CombatManager.setCustomAddPC(addPC);
	CombatManager.setCustomAddNPC(addNPC);

	-- CoreRPG replacements
	ActionsManager.decodeActors = decodeActors;
	
	EffectManager35E.checkConditionalHelper = checkConditionalHelper;
	EffectManager35E.getEffectsByType = getEffectsByType;
	EffectManager35E.hasEffect = hasEffect;

	-- option in house rule section, enable/disable allow PCs to edit advanced effects.
	OptionsManager.registerOption2("ADND_AE_EDIT", false, "option_header_houserule", "option_label_ADND_AE_EDIT", "option_entry_cycler", 
			{ labels = "option_val_on" , values = "enabled", baselabel = "option_val_off", baseval = "disabled", default = "disabled" });		
end

-- run from addHandler for updated item effect options
function inventoryUpdateItemEffects(nodeField)
	nodeItem = DB.getChild(nodeField, "..");

	updateItemEffects(DB.getChild(nodeField, ".."));
end
-- update single item from edit for *.effect handler
function updateItemEffectsForEdit(nodeField)
	checkEffectsAfterEdit(nodeField.getChild(".."));
end
-- find the effect for this source and delete and re-build
function checkEffectsAfterEdit(itemNode)
	local nodeChar = nil
	local bIDUpdated = false;
	if itemNode.getPath():match("%.effectlist%.") then
		nodeChar = DB.getChild(itemNode, ".....");
	else
		nodeChar = DB.getChild(itemNode, "...");
		bIDUpdated = true;
	end
	local nodeCT = getCTNodeByNodeChar(nodeChar);
	if nodeCT then
		for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
			local sLabel = DB.getValue(nodeEffect, "label", "");
			local sEffSource = DB.getValue(nodeEffect, "source_name", "");
			-- see if the node exists and if it's in an inventory node
			local nodeEffectFound = DB.findNode(sEffSource);
			if (nodeEffectFound	and string.match(sEffSource,"inventorylist")) then
				local nodeEffectItem = nodeEffectFound.getChild("...");
				if nodeEffectFound == itemNode then -- effect hide/show edit
					nodeEffect.delete();
					updateItemEffects(DB.getChild(itemNode, "..."));
				elseif nodeEffectItem == itemNode then -- id state was changed
					nodeEffect.delete();
					updateItemEffects(nodeEffectItem);
				end
			end
		end
	end
end
-- this checks to see if an effect is missing a associated item that applied the effect 
-- when items are deleted and then clears that effect if it's missing.
function updateFromDeletedInventory(node)
--Debug.console("manager_effect_adnd.lua","updateFromDeletedInventory","node",node);
		local nodeChar = DB.getChild(node, "..");
		local nodeCT = getCTNodeByNodeChar(nodeChar);
		-- if we're already in a combattracker situation (npcs)
		if not ActorManager.isPC(nodeChar) and string.match(nodeChar.getPath(),"^combattracker") then
				nodeCT = nodeChar;
		end
		if nodeCT then
				-- check that we still have the combat effect source item
				-- otherwise remove it
				checkEffectsAfterDelete(nodeCT);
		end
	--onEncumbranceChanged();
end

-- this checks to see if an effect is missing a associated item that applied the effect 
-- when items are deleted and then clears that effect if it's missing.
function checkEffectsAfterDelete(nodeChar)
		local sUser = User.getUsername();
		for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
				local sLabel = DB.getValue(nodeEffect, "label", "");
				local sEffSource = DB.getValue(nodeEffect, "source_name", "");
				-- see if the node exists and if it's in an inventory node
				local nodeFound = DB.findNode(sEffSource);
				local bDeleted = ((nodeFound == nil) and string.match(sEffSource,"inventorylist"));
				if (bDeleted) then
						local msg = {font = "msgfont", icon = "roll_effect"};
						msg.text = "Effect ['" .. sLabel .. "'] ";
						msg.text = msg.text .. "removed [from " .. DB.getValue(nodeChar, "name", "") .. "]";
						-- HANDLE APPLIED BY SETTING
						if sEffSource and sEffSource ~= "" then
								msg.text = msg.text .. " [by Deletion]";
						end
						if EffectManager.isGMEffect(nodeChar, nodeEffect) then
								if sUser == "" then
										msg.secret = true;
										Comm.addChatMessage(msg);
								elseif sUser ~= "" then
										Comm.addChatMessage(msg);
										Comm.deliverChatMessage(msg, sUser);
								end
						else
								Comm.deliverChatMessage(msg);
						end
						nodeEffect.delete();
				end
		end
end

function updateItemEffects(nodeItem)
	local nodeChar = DB.getChild(nodeItem, "...");
		if not nodeChar then
				return;
		end
		local sUser = User.getUsername();
		local sName = DB.getValue(nodeItem, "name", "");
		-- we swap the node to the combat tracker node
		-- so the "effect" is written to the right node
		if not string.match(nodeChar.getPath(),"^combattracker") then
				nodeChar = getCTNodeByNodeChar(nodeChar);
		end
		-- if not in the combat tracker bail
		if not nodeChar then
				return;
		end

		local nCarried = DB.getValue(nodeItem, "carried", 0);
		local bEquipped = (nCarried == 2);
		local nIdentified = DB.getValue(nodeItem, "isidentified", 1);
		-- local bOptionID = OptionsManager.isOption("MIID", "on");
		-- if not bOptionID then 
				-- nIdentified = 1;
		-- end

		for _,nodeItemEffect in pairs(DB.getChildren(nodeItem, "effectlist")) do
				updateItemEffect(nodeItemEffect, sName, nodeChar, nil, bEquipped, nIdentified);
		end -- for item's effects list
end

-- update single effect for item
function updateItemEffect(nodeItemEffect, sName, nodeChar, sUser, bEquipped, nIdentified)
	local sCharacterName = DB.getValue(nodeChar, "name", "");
	local sItemSource = nodeItemEffect.getPath();
	local sLabel = DB.getValue(nodeItemEffect, "effect", "");
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","bEquipped",bEquipped);		
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","nodeItemEffect",nodeItemEffect);	
	if sLabel and sLabel ~= "" then -- if we have effect string
		local bFound = false;
		for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			local nDMOnly = DB.getValue(nodeEffect, "isgmonly", 0);
			if (nActive ~= 0) then
				local sEffSource = DB.getValue(nodeEffect, "source_name", "");
				if (sEffSource == sItemSource) then
					bFound = true;
					if (not bEquipped) then
						sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly, sUser)
						nodeEffect.delete();
						break;
					end -- not equipped
				end -- effect source == item source
			end -- was active
		end -- nodeEffect for
		if (not bFound and bEquipped) then
			local rEffect = {};
			local nRollDuration = 0;
			local dDurationDice = DB.getValue(nodeItemEffect, "durdice");
			local nModDice = DB.getValue(nodeItemEffect, "durmod", 0);
			local bLabelOnly = (DB.getValue(nodeItemEffect, "type", "") == "label");

			if (dDurationDice and dDurationDice ~= "") then
				nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
			else
				nRollDuration = nModDice;
			end
			local nDMOnly = 0;
			local sVisibility = DB.getValue(nodeItemEffect, "visibility", "");
			if sVisibility == "hide" then
				nDMOnly = 1;
			elseif sVisibility == "show"	then
				nDMOnly = 0;
			elseif nIdentified == 0 then
				nDMOnly = 1;
			elseif nIdentified > 0	then
				nDMOnly = 0;
			end

			local bTokenVis = (DB.getValue(nodeChar,"tokenvis",1) == 1);
			if not bTokenVis then
				nDMOnly = 1; -- hide if token not visible
			end

			rEffect.nDuration = nRollDuration;
			if not bLabelOnly then
				rEffect.sName = sName .. ";" .. sLabel;
			else
				rEffect.sName = sLabel;
			end
			rEffect.sLabel = sLabel; 
			rEffect.sUnits = DB.getValue(nodeItemEffect, "durunit", "");
			rEffect.nInit = 0;
			rEffect.sSource = sItemSource;
			rEffect.nGMOnly = nDMOnly;
			rEffect.sApply = "";
		
			sendEffectAddedMessage(nodeChar, rEffect, sLabel, nDMOnly, sUser)
			EffectManager.addEffect("", "", nodeChar, rEffect, false);
		end
	end
end

function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	local results = {};
	
	-- Set up filters
	local aRangeFilter = {};
	local aOtherFilter = {};
	if aFilter then
		for _,v in pairs(aFilter) do
			if type(v) ~= "string" then
				table.insert(aOtherFilter, v);
			elseif StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v);
			else
				table.insert(aOtherFilter, v);
			end
		end
	end
	
	-- Determine effect type targeting
	local bTargetSupport = StringManager.isWord(sEffectType, DataCommon.targetableeffectcomps);
	
	-- Iterate through effects
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		-- Check effect is from used weapon.
		if isValidCheckEffect(rActor,v) then
			-- Check targeting
			local bTargeted = EffectManager.isTargetedEffect(v);
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local sLabel = DB.getValue(v, "label", "");
				local aEffectComps = EffectManager.parseEffect(sLabel);
				
				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp, sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);
					-- Handle conditionals
					if rEffectComp.type == "IF" then
						if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "IFT" then
						if not rFilterActor then
							break;
						end
						if not EffectManager35E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
							break;
						end
						bTargeted = true;
					
					-- Compare other attributes
					else
						-- Strip energy/bonus types for subtype comparison
						local aEffectRangeFilter = {};
						local aEffectOtherFilter = {};
						
						local aComponents = {};
						for _,vPhrase in ipairs(rEffectComp.remainder) do
							local nTempIndexOR = 0;
							local aPhraseOR = {};
							repeat
								local nStartOR, nEndOR = vPhrase:find("%s+or%s+", nTempIndexOR);
								if nStartOR then
									table.insert(aPhraseOR, vPhrase:sub(nTempIndexOR, nStartOR - nTempIndexOR));
									nTempIndexOR = nEndOR;
								else
									table.insert(aPhraseOR, vPhrase:sub(nTempIndexOR));
								end
							until nStartOR == nil;
							
							for _,vPhraseOR in ipairs(aPhraseOR) do
								local nTempIndexAND = 0;
								repeat
									local nStartAND, nEndAND = vPhraseOR:find("%s+and%s+", nTempIndexAND);
									if nStartAND then
										local sInsert = StringManager.trim(vPhraseOR:sub(nTempIndexAND, nStartAND - nTempIndexAND));
										table.insert(aComponents, sInsert);
										nTempIndexAND = nEndAND;
									else
										local sInsert = StringManager.trim(vPhraseOR:sub(nTempIndexAND));
										table.insert(aComponents, sInsert);
									end
								until nStartAND == nil;
							end
						end
						local j = 1;
						while aComponents[j] do
							if StringManager.contains(DataCommon.dmgtypes, aComponents[j]) or 
									StringManager.contains(DataCommon.bonustypes, aComponents[j]) or
									aComponents[j] == "all" then
								-- Skip
							elseif StringManager.contains(DataCommon.rangetypes, aComponents[j]) then
								table.insert(aEffectRangeFilter, aComponents[j]);
							else
								table.insert(aEffectOtherFilter, aComponents[j]);
							end
							
							j = j + 1;
						end
					
						-- Check for match
						local comp_match = false;
						if rEffectComp.type == sEffectType then

							-- Check effect targeting
							if bTargetedOnly and not bTargeted then
								comp_match = false;
							else
								comp_match = true;
							end
						
							-- Check filters
							if #aEffectRangeFilter > 0 then
								local bRangeMatch = false;
								for _,v2 in pairs(aRangeFilter) do
									if StringManager.contains(aEffectRangeFilter, v2) then
										bRangeMatch = true;
										break;
									end
								end
								if not bRangeMatch then
									comp_match = false;
								end
							end
							if #aEffectOtherFilter > 0 then
								local bOtherMatch = false;
								for _,v2 in pairs(aOtherFilter) do
									if type(v2) == "table" then
										local bOtherTableMatch = true;
										for k3, v3 in pairs(v2) do
											if not StringManager.contains(aEffectOtherFilter, v3) then
												bOtherTableMatch = false;
												break;
											end
										end
										if bOtherTableMatch then
											bOtherMatch = true;
											break;
										end
									elseif StringManager.contains(aEffectOtherFilter, v2) then
										bOtherMatch = true;
										break;
									end
								end
								if not bOtherMatch then
									comp_match = false;
								end
							end
						end

						-- Match!
						if comp_match then
							nMatch = kEffectComp;
							if nActive == 1 then
								table.insert(results, rEffectComp);
							end
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						local sApply = DB.getValue(v, "apply", "");
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end -- END VALID CHECK
	end	-- END EFFECT LOOP
	
	return results;
end

-- return the CTnode by using character sheet node 
function getCTNodeByNodeChar(nodeChar)
		local nodeCT = nil;
	for _,node in pairs(DB.getChildren("combattracker.list")) do
				local _, sRecord = DB.getValue(node, "link", "", "");
				if sRecord ~= "" and sRecord == nodeChar.getPath() then
						nodeCT = node;
						break;
				end
		end
		return nodeCT;
end

-- flip through all npc effects (generally do this in addNPC()/addPC()
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffects(nodeChar,nodeEntry)
		for _,nodeCharEffect in pairs(DB.getChildren(nodeChar, "effectlist")) do
				updateCharEffect(nodeCharEffect,nodeEntry);
		end -- for item's effects list 
end
-- this will be used to manage PC/NPC effectslist objects
-- nodeCharEffect: node in effectlist on PC/NPC
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffect(nodeCharEffect,nodeEntry)
	local sUser = User.getUsername();
	local sName = DB.getValue(nodeEntry, "name", "");
	local sLabel = DB.getValue(nodeCharEffect, "effect", "");
	local nRollDuration = 0;
	local dDurationDice = DB.getValue(nodeCharEffect, "durdice");
	local nModDice = DB.getValue(nodeCharEffect, "durmod", 0);
	if (dDurationDice and dDurationDice ~= "") then
			nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
	else
			nRollDuration = nModDice;
	end
	local nDMOnly = 0;
	local sVisibility = DB.getValue(nodeCharEffect, "visibility", "");
	if sVisibility == "show" then
			nDMOnly = 0;
	elseif sVisibility == "hide" then
			nDMOnly = 1;
	end
	if not ActorManager.isPC(nodeEntry) then
		nDMOnly = 1; -- npcs effects always hidden from PCs/chat when we first drag/drop into CT
	end
	
	local rEffect = {};
	rEffect.nDuration = nRollDuration;
	--rEffect.sName = sName .. ";" .. sLabel;
	rEffect.sName = sLabel;
	rEffect.sLabel = sLabel; 
	rEffect.sUnits = DB.getValue(nodeCharEffect, "durunit", "");
	rEffect.nInit = 0;
	--rEffect.sSource = nodeEntry.getPath();
	rEffect.nGMOnly = nDMOnly;
	rEffect.sApply = "";

	sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nDMOnly, sUser);
	EffectManager.addEffect("", "", nodeEntry, rEffect, false);
end

-- custom version of the one in CoreRPG to deal with adding new 
-- pcs to the combat tracker to deal with advanced effects. --celestian
function addPC(nodePC)
	-- Parameter validation
	if not nodePC then
		return;
	end

	-- Create a new combat tracker window
	local nodeEntry = DB.createChild("combattracker.list");
	if not nodeEntry then
		return;
	end
	
	-- Set up the CT specific information
	DB.setValue(nodeEntry, "link", "windowreference", "charsheet", nodePC.getNodeName());
	DB.setValue(nodeEntry, "friendfoe", "string", "friend");

	local sToken = DB.getValue(nodePC, "token", nil);
	if not sToken or sToken == "" then
		sToken = "portrait_" .. nodePC.getName() .. "_token"
	end
	DB.setValue(nodeEntry, "token", "token", sToken);

		-- now flip through inventory and pass each to updateEffects()
		-- so that if they have a combat_effect it will be applied.
		for _,nodeItem in pairs(DB.getChildren(nodePC, "inventorylist")) do
				updateItemEffects(nodeItem,true);
		end
		-- end
		-- check to see if npc effects exists and if so apply --celestian
		updateCharEffects(nodePC,nodeEntry);

		-- make sure active users get ownership of their CT nodes
		-- otherwise effects applied by items/etc won't work.
		--AccessManagerADND.manageCTOwners(nodeEntry);
end

-- copied the base addNPC from manager_combat2.lua from 5E ruleset for this and
-- added the bit that checks for PC effects to add -- celestian
function addNPC(sClass, nodeNPC, sName)
	local nodeEntry, nodeLastMatch = CombatManager.addNPCHelper(nodeNPC, sName);
	
	local bPFMode = DataCommon.isPFRPG();

	-- HP
	local sOptHRNH = OptionsManager.getOption("HRNH");
	local nHP = DB.getValue(nodeNPC, "hp", 0);
	local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
	if sOptHRNH == "max" and sHD ~= "" then
		nHP = StringManager.evalDiceString(sHD, true, true);
	elseif sOptHRNH == "random" and sHD ~= "" then
		nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
	end
	DB.setValue(nodeEntry, "hp", "number", nHP);

	-- Defensive properties
	local sAC = DB.getValue(nodeNPC, "ac", "10");
	DB.setValue(nodeEntry, "ac_final", "number", tonumber(string.match(sAC, "^(%d+)")) or 10);
	DB.setValue(nodeEntry, "ac_touch", "number", tonumber(string.match(sAC, "touch (%d+)")) or 10);
	local sFlatFooted = string.match(sAC, "flat[%-–]footed (%d+)");
	if not sFlatFooted then
		sFlatFooted = string.match(sAC, "flatfooted (%d+)");
	end
	DB.setValue(nodeEntry, "ac_flatfooted", "number", tonumber(sFlatFooted) or 10);
	
	-- Handle BAB / Grapple / CM Field
	local sBABGrp = DB.getValue(nodeNPC, "babgrp", "");
	local aSplitBABGrp = StringManager.split(sBABGrp, "/", true);
	
	local sMatch = string.match(sBABGrp, "CMB ([+-]%d+)");
	if sMatch then
		DB.setValue(nodeEntry, "grapple", "number", tonumber(sMatch) or 0);
	else
		if aSplitBABGrp[2] then
			DB.setValue(nodeEntry, "grapple", "number", tonumber(aSplitBABGrp[2]) or 0);
		end
	end

	sMatch = string.match(sBABGrp, "CMD ([+-]?%d+)");
	if sMatch then
		DB.setValue(nodeEntry, "cmd", "number", tonumber(sMatch) or 0);
	else
		if aSplitBABGrp[3] then
			DB.setValue(nodeEntry, "cmd", "number", tonumber(aSplitBABGrp[3]) or 0);
		end
	end

	-- Offensive properties
	local nodeAttacks = nodeEntry.createChild("attacks");
	if nodeAttacks then
		for _,v in pairs(nodeAttacks.getChildren()) do
			v.delete();
		end
		
		local nAttacks = 0;
		
		local sAttack = DB.getValue(nodeNPC, "atk", "");
		if sAttack ~= "" then
			local nodeValue = nodeAttacks.createChild();
			if nodeValue then
				DB.setValue(nodeValue, "value", "string", sAttack);
				nAttacks = nAttacks + 1;
			end
		end
		
		local sFullAttack = DB.getValue(nodeNPC, "fullatk", "");
		if sFullAttack ~= "" then
			nodeValue = nodeAttacks.createChild();
			if nodeValue then
				DB.setValue(nodeValue, "value", "string", sFullAttack);
				nAttacks = nAttacks + 1;
			end
		end
		
		if nAttacks == 0 then
			nodeAttacks.createChild();
		end
	end

	-- Track additional damage types and intrinsic effects
	local aEffects = {};
	local aAddDamageTypes = {};
	
	-- Decode monster type qualities
	local sType = string.lower(DB.getValue(nodeNPC, "type", ""));
	local sCreatureType, sSubTypes = string.match(sType, "([^(]+) %(([^)]+)%)");
	if not sCreatureType then
		sCreatureType = sType;
	end
	local aTypes = StringManager.split(sCreatureType, " ", true);
	local aSubTypes = {};
	if sSubTypes then
		aSubTypes = StringManager.split(sSubTypes, ",", true);
	end

	if StringManager.contains(aSubTypes, "lawful") then
		table.insert(aAddDamageTypes, "lawful");
	end
	if StringManager.contains(aSubTypes, "chaotic") then
		table.insert(aAddDamageTypes, "chaotic");
	end
	if StringManager.contains(aSubTypes, "good") then
		table.insert(aAddDamageTypes, "good");
	end
	if StringManager.contains(aSubTypes, "evil") then
		table.insert(aAddDamageTypes, "evil");
	end
	
	local bImmuneNonlethal = false;
	local bImmuneCritical = false;
	local bImmunePrecision = false;
	if bPFMode then
		local bElemental = false;
		if StringManager.contains(aTypes, "construct") then
			table.insert(aEffects, "Construct traits");
			bImmuneNonlethal = true;
		elseif StringManager.contains(aTypes, "elemental") then
			bElemental = true;
		elseif StringManager.contains(aTypes, "ooze") then
			table.insert(aEffects, "Ooze traits");
			bImmuneCritical = true;
			bImmunePrecision = true;
		elseif StringManager.contains(aTypes, "undead") then
			table.insert(aEffects, "Undead traits");
			bImmuneNonlethal = true;
		end
		
		if StringManager.contains(aSubTypes, "aeon") then
			table.insert(aEffects, "Aeon traits");
			bImmuneCritical = true;
		end
		if StringManager.contains(aSubTypes, "elemental") then
			bElemental = true;
		end
		if StringManager.contains(aSubTypes, "incorporeal") then
			bImmunePrecision = true;
		end
		if StringManager.contains(aSubTypes, "swarm") then
			table.insert(aEffects, "Swarm traits");
			bImmuneCritical = true;
		end
		
		if bElemental then
			table.insert(aEffects, "Elemental traits");
			bImmuneCritical = true;
			bImmunePrecision = true;
		end
	else
		if StringManager.contains(aTypes, "construct") then
			table.insert(aEffects, "Construct traits");
			bImmuneNonlethal = true;
			bImmuneCritical = true;
		elseif StringManager.contains(aTypes, "elemental") then
			table.insert(aEffects, "Elemental traits");
			bImmuneCritical = true;
		elseif StringManager.contains(aTypes, "ooze") then
			table.insert(aEffects, "Ooze traits");
			bImmuneCritical = true;
		elseif StringManager.contains(aTypes, "plant") then
			table.insert(aEffects, "Plant traits");
			bImmuneCritical = true;
		elseif StringManager.contains(aTypes, "undead") then
			table.insert(aEffects, "Undead traits");
			bImmuneNonlethal = true;
			bImmuneCritical = true;
		end
		if StringManager.contains(aSubTypes, "swarm") then
			table.insert(aEffects, "Swarm traits");
			bImmuneCritical = true;
		end
	end
	if bImmuneNonlethal then
		table.insert(aEffects, "IMMUNE: nonlethal");
	end
	if bImmuneCritical then
		table.insert(aEffects, "IMMUNE: critical");
	end
	if bImmunePrecision then
		table.insert(aEffects, "IMMUNE: precision");
	end

	-- DECODE SPECIAL QUALITIES
	local sSpecialQualities = string.lower(DB.getValue(nodeNPC, "specialqualities", ""));
	
	local aSQWords = StringManager.parseWords(sSpecialQualities);
	local i = 1;
	while aSQWords[i] do
		-- HARDNESS
		if StringManager.isWord(aSQWords[i], "hardness") and StringManager.isNumberString(aSQWords[i+1]) then
			i = i + 1;
			local sHardnessAmount = aSQWords[i];
			if (tonumber(aSQWords[i+1]) or 0) <= 20 then
				table.insert(aEffects, "DR: " .. sHardnessAmount .. " adamantine; RESIST: " .. sHardnessAmount .. " " .. table.concat(DataCommon.energytypes, "; RESIST: " .. sHardnessAmount .. " "));
			else
				table.insert(aEffects, "DR: " .. sHardnessAmount .. " all; RESIST: " .. sHardnessAmount .. " " .. table.concat(DataCommon.energytypes, "; RESIST: " .. sHardnessAmount .. " "));
			end

		-- DAMAGE REDUCTION
		elseif StringManager.isWord(aSQWords[i], "dr") or (StringManager.isWord(aSQWords[i], "damage") and StringManager.isWord(aSQWords[i+1], "reduction")) then
			if aSQWords[i] ~= "dr" then
				i = i + 1;
			end
			
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				local sDRAmount = aSQWords[i];
				local aDRTypes = {};
				
				while aSQWords[i+1] do
					if StringManager.isWord(aSQWords[i+1], { "and", "or" }) then
						table.insert(aDRTypes, aSQWords[i+1]);
					elseif StringManager.isWord(aSQWords[i+1], { "epic", "magic" }) then
						table.insert(aDRTypes, aSQWords[i+1]);
						table.insert(aAddDamageTypes, aSQWords[i+1]);
					elseif StringManager.isWord(aSQWords[i+1], "cold") and StringManager.isWord(aSQWords[i+2], "iron") then
						table.insert(aDRTypes, "cold iron");
						i = i + 1;
					elseif StringManager.isWord(aSQWords[i+1], DataCommon.dmgtypes) then
						table.insert(aDRTypes, aSQWords[i+1]);
					else
						break;
					end

					i = i + 1;
				end
				
				local sDREffect = "DR: " .. sDRAmount;
				if #aDRTypes > 0 then
					sDREffect = sDREffect .. " " .. table.concat(aDRTypes, " ");
				end
				table.insert(aEffects, sDREffect);
			end

		-- SPELL RESISTANCE
		elseif StringManager.isWord(aSQWords[i], "sr") or (StringManager.isWord(aSQWords[i], "spell") and StringManager.isWord(aSQWords[i+1], "resistance")) then
			if aSQWords[i] ~= "sr" then
				i = i + 1;
			end
			
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				DB.setValue(nodeEntry, "sr", "number", tonumber(aSQWords[i]) or 0);
			end
		
		-- FAST HEALING
		elseif StringManager.isWord(aSQWords[i], "fast") and StringManager.isWord(aSQWords[i+1], { "healing", "heal" }) then
			i = i + 1;
			
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				table.insert(aEffects, "FHEAL: " .. aSQWords[i]);
			end
		
		-- REGENERATION
		elseif StringManager.isWord(aSQWords[i], "regeneration") then
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				local sRegenAmount = aSQWords[i];
				local aRegenTypes = {};
				
				while aSQWords[i+1] do
					if StringManager.isWord(aSQWords[i+1], { "and", "or" }) then
						table.insert(aRegenTypes, aSQWords[i+1]);
					elseif StringManager.isWord(aSQWords[i+1], "cold") and StringManager.isWord(aSQWords[i+2], "iron") then
						table.insert(aRegenTypes, "cold iron");
						i = i + 1;
					elseif StringManager.isWord(aSQWords[i+1], DataCommon.dmgtypes) then
						table.insert(aRegenTypes, aSQWords[i+1]);
					else
						break;
					end

					i = i + 1;
				end
				i = i - 1;
				
				local sRegenEffect = "REGEN: " .. sRegenAmount;
				if #aRegenTypes > 0 then
					sRegenEffect = sRegenEffect .. " " .. table.concat(aRegenTypes, " ");
					EffectManager.addEffect("", "", nodeEntry, { sName = sRegenEffect, nDuration = 0, nGMOnly = 1 }, false);
				else
					table.insert(aEffects, sRegenEffect);
				end
			end
			
		-- RESISTANCE
		elseif StringManager.isWord(aSQWords[i], "resistance") and StringManager.isWord(aSQWords[i+1], "to") then
			i = i + 1;
		
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], "and") then
					-- SKIP
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.energytypes) and StringManager.isNumberString(aSQWords[i+2]) then
					i = i + 1;
					table.insert(aEffects, "RESIST: " .. aSQWords[i+1] .. " " .. aSQWords[i]);
				else
					break;
				end

				i = i + 1;
			end

		elseif StringManager.isWord(aSQWords[i], "resist") then
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], DataCommon.energytypes) and StringManager.isNumberString(aSQWords[i+2]) then
					i = i + 1;
					table.insert(aEffects, "RESIST: " .. aSQWords[i+1] .. " " .. aSQWords[i]);
				elseif not StringManager.isWord(aSQWords[i+1], "and") then
					break;
				end
				
				i = i + 1;
			end
			
		-- VULNERABILITY
		elseif StringManager.isWord(aSQWords[i], {"vulnerability", "vulnerable"}) and StringManager.isWord(aSQWords[i+1], "to") then
			i = i + 1;
		
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], "and") then
					-- SKIP
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.energytypes) then
					table.insert(aEffects, "VULN: " .. aSQWords[i+1]);
				else
					break;
				end

				i = i + 1;
			end
			
		-- IMMUNITY
		elseif StringManager.isWord(aSQWords[i], "immunity") and StringManager.isWord(aSQWords[i+1], "to") then
			i = i + 1;
		
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], "and") then
					-- SKIP
				elseif StringManager.isWord(aSQWords[i+2], "traits") then
					-- SKIP+
					i = i + 1;
				-- Add exception for "magic immunity", which is also a damage type
				elseif StringManager.isWord(aSQWords[i+1], "magic") then
					table.insert(aEffects, "IMMUNE: spell");
				elseif StringManager.isWord(aSQWords[i+1], "critical") and StringManager.isWord(aSQWords[i+2], "hits") then
					table.insert(aEffects, "IMMUNE: critical");
					i = i + 1;
				elseif StringManager.isWord(aSQWords[i+1], "precision") and StringManager.isWord(aSQWords[i+2], "damage") then
					table.insert(aEffects, "IMMUNE: precision");
					i = i + 1;
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.immunetypes) then
					table.insert(aEffects, "IMMUNE: " .. aSQWords[i+1]);
					if StringManager.isWord(aSQWords[i+2], "effects") then
						i = i + 1;
					end
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.dmgtypes) and not StringManager.isWord(aSQWords[i+1], DataCommon.specialdmgtypes) then
					table.insert(aEffects, "IMMUNE: " .. aSQWords[i+1]);
				else
					break;
				end

				i = i + 1;
			end
		elseif StringManager.isWord(aSQWords[i], "immune") then
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], "and") then
					--SKIP
				elseif StringManager.isWord(aSQWords[i+2], "traits") then
					-- SKIP+
					i = i + 1;
				-- Add exception for "magic immunity", which is also a damage type
				elseif StringManager.isWord(aSQWords[i+1], "magic") then
					table.insert(aEffects, "IMMUNE: spell");
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.immunetypes) then
					table.insert(aEffects, "IMMUNE: " .. aSQWords[i+1]);
					if StringManager.isWord(aSQWords[i+2], "effects") then
						i = i + 1;
					end
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.dmgtypes) then
					table.insert(aEffects, "IMMUNE: " .. aSQWords[i+1]);
				else
					break;
				end

				i = i + 1;
			end
			
		-- SPECIAL DEFENSES
		elseif StringManager.isWord(aSQWords[i], "uncanny") and StringManager.isWord(aSQWords[i+1], "dodge") then
			if StringManager.isWord(aSQWords[i-1], "improved") then
				table.insert(aEffects, "Improved Uncanny Dodge");
			else
				table.insert(aEffects, "Uncanny Dodge");
			end
			i = i + 1;
		
		elseif StringManager.isWord(aSQWords[i], "evasion") then
			if StringManager.isWord(aSQWords[i-1], "improved") then
				table.insert(aEffects, "Improved Evasion");
			else
				table.insert(aEffects, "Evasion");
			end
		
		-- TRAITS
		elseif StringManager.isWord(aSQWords[i], "incorporeal") then
			table.insert(aEffects, "Incorporeal");
		elseif StringManager.isWord(aSQWords[i], "blur") then
			table.insert(aEffects, "CONC");
		elseif StringManager.isWord(aSQWords[i], "natural") and StringManager.isWord(aSQWords[i+1], "invisibility") then
			table.insert(aEffects, "Invisible");
		end
	
		-- ITERATE SPECIAL QUALITIES DECODE
		i = i + 1;
	end

	-- FINISH ADDING EXTRA DAMAGE TYPES
	if #aAddDamageTypes > 0 then
		table.insert(aEffects, "DMGTYPE: " .. table.concat(aAddDamageTypes, ","));
	end
	
	-- ADD DECODED EFFECTS
	if #aEffects > 0 then
		EffectManager.addEffect("", "", nodeEntry, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

		updateCharEffects(nodeNPC,nodeEntry);

	-- Roll initiative and sort
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT == "group" then
		if nodeLastMatch then
			local nLastInit = DB.getValue(nodeLastMatch, "initresult", 0);
			DB.setValue(nodeEntry, "initresult", "number", nLastInit);
		else
			DB.setValue(nodeEntry, "initresult", "number", math.random(20) + DB.getValue(nodeEntry, "init", 0));
		end
	elseif sOptINIT == "on" then
		DB.setValue(nodeEntry, "initresult", "number", math.random(20) + DB.getValue(nodeEntry, "init", 0));
	end

	return nodeEntry;
end

-- get the Connected Player's name that has this identity
function getUserFromNode(node)
	local sNodePath = node.getPath();
	local _, sRecord = DB.getValue(node, "link", "", "");
	local sUser = nil;
	for _,vUser in ipairs(User.getActiveUsers()) do
		for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
			if (sRecord == ("charsheet." .. vIdentity)) then
				sUser = vUser;
				break;
			end
		end
	end
	return sUser;
end

-- build message to send that effect removed
function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly)
	local sUser = getUserFromNode(nodeChar);
--Debug.console("manager_effect_adnd.lua","sendEffectRemovedMessage","sUser",sUser);	
	local sCharacterName = DB.getValue(nodeChar, "name", "");
	-- Build output message
	local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeChar),sUser);
	msg.text = "Advanced Effect ['" .. sLabel .. "'] ";
	msg.text = msg.text .. "removed [from " .. sCharacterName .. "]";
	-- HANDLE APPLIED BY SETTING
	local sEffSource = DB.getValue(nodeEffect, "source_name", "");		
	if sEffSource and sEffSource ~= "" then
		msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(sEffSource), "name", "") .. "]";
	end
	sendRawMessage(sUser,nDMOnly,msg);
end
-- build message to send that effect added
function sendEffectAddedMessage(nodeCT, rNewEffect, sLabel, nDMOnly)
	local sUser = getUserFromNode(nodeCT);
--Debug.console("manager_effect_adnd.lua","sendEffectAddedMessage","sUser",sUser);	
	-- Build output message
	local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeCT),sUser);
	msg.text = "Advanced Effect ['" .. rNewEffect.sName .. "'] ";
	msg.text = msg.text .. "-> [to " .. DB.getValue(nodeCT, "name", "") .. "]";
	if rNewEffect.sSource and rNewEffect.sSource ~= "" then
		msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
	end
		sendRawMessage(sUser,nDMOnly,msg);
end

-- send message
function sendRawMessage(sUser, nDMOnly, msg)
	local sIdentity = nil;
	if sUser and sUser ~= "" then 
		sIdentity = User.getCurrentIdentity(sUser) or nil;
	end
	if sIdentity then
		msg.icon = "portrait_" .. User.getCurrentIdentity(sUser) .. "_chat";
	else
		msg.font = "msgfont";
		msg.icon = "roll_effect";
	end
	if nDMOnly == 1 then
		msg.secret = true;
		Comm.addChatMessage(msg);
	elseif nDMOnly ~= 1 then 
		--Comm.addChatMessage(msg);
		Comm.deliverChatMessage(msg);
	end
end

--	pass effect to here to see if the effect is being triggered
--	by an item and if so if it's valid
function isValidCheckEffect(rActor,nodeEffect)
	local bResult = false;
	local nActive = DB.getValue(nodeEffect, "isactive", 0);
	local bItem = false;
	local bActionItemUsed = false;
	local bActionOnly = false;
	local nodeItem = nil;

	local sSource = DB.getValue(nodeEffect,"source_name","");
	-- if source is a valid node and we can find "actiononly"
	-- setting then we set it.
	local node = DB.findNode(sSource);
	if (node and node ~= nil) then
		nodeItem = node.getChild("...");
		if nodeItem and nodeItem ~= nil then
			bActionOnly = (DB.getValue(node,"actiononly",0) ~= 0);
		end
	end

	-- if there is a itemPath do some sanity checking
	if (rActor.itemPath and rActor.itemPath ~= "") then 
		-- here is where we get the node path of the item, not the
		-- effectslist entry
		if ((DB.findNode(rActor.itemPath) ~= nil)) then
			if (node and node ~= nil and nodeItem and nodeItem ) then
				local sNodePath = nodeItem.getPath();
				if bActionOnly and sNodePath ~= "" and (sNodePath == rActor.itemPath) then
					bActionItemUsed = true;
					bItem = true;
				else
					bActionItemUsed = false;
					bItem = true; -- is item but doesn't match source path for this effect
				end
			end
		end
	end

	if nActive ~= 0 and bActionOnly and bActionItemUsed then
		bResult = true;
	elseif nActive ~= 0 and not bActionOnly and bActionItemUsed then
		bResult = true;
	elseif nActive ~= 0 and bActionOnly and not bActionItemUsed then
		bResult = false;
	elseif nActive ~= 0 then
		bResult = true;
	end
	return bResult;
end

--
--	REPLACEMENT FUNCTIONS
--

--	replace CoreRPG ActionsManager manager_actions.lua decodeActors() with this
function decodeActors(draginfo)
	local rSource = nil;
	local aTargets = {};
	
	for k,v in ipairs(draginfo.getShortcutList()) do
		if k == 1 then
			rSource = ActorManager.resolveActor(v.recordname);
		else
			local rTarget = ActorManager.resolveActor(v.recordname);
			if rTarget then
				table.insert(aTargets, rTarget);
			end
		end
	end

	-- itemPath data filled if itemPath if exists
	local sItemPath = draginfo.getMetaData("itemPath");
	if (sItemPath and sItemPath ~= "") then
		rSource.itemPath = sItemPath;
	end
	--

	return rSource, aTargets;
end

--	replace 3.5E EffectManager35E manager_effect_35E.lua hasEffect() with this
function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = sEffect:lower();
	
	-- Iterate through each effect
	local aMatch = {};
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		
		-- CHANGE FOR ADVANCED EFFECTS
		-- original line: if nActive ~= 0 then
		if isValidCheckEffect(rActor,v) then
		-- END CHANGE FOR ADVANCED EFFECTS
		
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);
				-- Check conditionals
				if rEffectComp.type == "IF" then
					if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not EffectManager35E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
						break;
					end
				
				-- Check for match
				elseif rEffectComp.original:lower() == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				end
				
			end
			
			-- If matched, then remove one-off effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);
				else
					table.insert(aMatch, v);
					local sApply = DB.getValue(v, "apply", "");
					if sApply == "action" then
						EffectManager.notifyExpire(v, 0);
					elseif sApply == "roll" then
						EffectManager.notifyExpire(v, 0, true);
					elseif sApply == "single" then
						EffectManager.notifyExpire(v, nMatch, true);
					end
				end
			end
		end
	end
	
	if #aMatch > 0 then
		return true;
	end
	return false;
end

--	replace 3.5E EffectManager35E manager_effect_35E.lua checkConditionalHelper() with this
function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end
	
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);

		-- CHANGE FOR ADVANCED EFFECTS
		-- original line: if nActive ~= 0 and not StringManager.contains(aIgnore, v.getPath()) then
		if isValidCheckEffect(rActor,v) and not StringManager.contains(aIgnore, v.getPath()) then
		-- END CHANGE FOR ADVANCED EFFECTS

			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			for _,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);

				-- ADDITION FOR ADVANCED EFFECTS
				-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
				if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
					break;
				-- END ADDITION FOR ADVANCED EFFECTS
				
				--Check conditionals
				elseif rEffectComp.type == "IF" then
					if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not EffectManager35E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end
				
				-- Check for match
				elseif rEffectComp.original:lower() == sEffect then
					if EffectManager.isTargetedEffect(v) then
						if EffectManager.isEffectTarget(v, rTarget) then
							return true;
						end
					else
						return true;
					end
				end
			end
		end
	end
	
	return false;
end