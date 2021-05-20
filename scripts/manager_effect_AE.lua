--
-- Effects on Items, apply to character in CT
--

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
function checkEffectsAfterEdit(nodeItem)
	local nodeChar = nil
	local bIDUpdated = false;
	if nodeItem.getPath():match("%.effectlist%.") then
		nodeChar = DB.getChild(nodeItem, ".....");
	else
		nodeChar = DB.getChild(nodeItem, "...");
		bIDUpdated = true;
	end
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodeChar));
	if nodeCT then
		for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
			local sLabel = DB.getValue(nodeEffect, "label", "");
			local sEffSource = DB.getValue(nodeEffect, "source_name", "");
			-- see if the node exists and if it's in an inventory node
			local nodeEffectFound = DB.findNode(sEffSource);
			if (nodeEffectFound	and string.match(sEffSource,"inventorylist")) then
				local nodeEffectItem = nodeEffectFound.getChild("...");
				if nodeEffectFound == nodeItem then -- effect hide/show edit
					nodeEffect.delete();
					updateItemEffects(DB.getChild(nodeItem, "..."));
				elseif nodeEffectItem == nodeItem then -- id state was changed
					nodeEffect.delete();
					updateItemEffects(nodeEffectItem);
				end
			end
		end
	end
end

-- this checks to see if an effect is missing its associated item
-- if the item isn't found, it removes the effect as the item has been removed
function updateFromDeletedInventory(node)
--Debug.console("manager_effect_adnd.lua","updateFromDeletedInventory","node",node);
		local nodeChar = DB.getChild(node, "..");
		local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodeChar));
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
			nodeChar = ActorManager.getCTNode(ActorManager.resolveActor(nodeChar));
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
			local sVisibility = DB.getValue(nodeItemEffect, "visibility", "hide");
			if sVisibility == "hide" then
				nDMOnly = 1;
			elseif sVisibility == "show" then
				nDMOnly = 0;
			elseif nIdentified == 0 then
				nDMOnly = 1;
			elseif nIdentified > 0	then
				nDMOnly = 0;
			end

			if not ActorManager.isPC(nodeChar) then
				local bTokenVis = (DB.getValue(nodeChar,"tokenvis") == 1);
				if not bTokenVis then
					nDMOnly = 1; -- hide if token not visible
				end
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

local function getEffectsByType_new(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
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

local function getEffectsByType_kel(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly, rEffectSpell)
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
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);

		-- COMPATIBILITY FOR ADVANCED EFFECTS
		-- to add support for AE in other extensions, make this change
		-- Check effect is from used weapon.
		-- original line: if nActive ~= 0 then
		if ((not EffectManagerAE and nActive ~= 0) or (EffectManagerAE and isValidCheckEffect(rActor,v))) then
		-- END COMPATIBILITY FOR ADVANCED EFFECTS

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
					-- KEL adding TAG for SAVE
					if rEffectComp.type == "IF" then
						if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "NIF" then
						if EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "IFTAG" then
						if not rEffectSpell then
							break;
						elseif not EffectManager35E.checkTagConditional(rActor, v, rEffectComp.remainder, rEffectSpell) then
							break;
						end
					elseif rEffectComp.type == "NIFTAG" then
						if EffectManager35E.checkTagConditional(rActor, v, rEffectComp.remainder, rEffectSpell) then
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
					elseif rEffectComp.type == "NIFT" then
						if rActor.aTargets and not rFilterActor then
							-- if ( #rActor.aTargets[1] > 0 ) and not rFilterActor then
							break;
							-- end
						end
						if EffectManager35E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
							break;
						end
						if rFilterActor then
							bTargeted = true;
						end
					
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
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP

	return results;
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
	rEffect.sSource = nodeEntry.getPath();
	rEffect.nGMOnly = nDMOnly;
	rEffect.sApply = "";

	sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nDMOnly, sUser);
	EffectManager.addEffect("", "", nodeEntry, rEffect, false);
end

-- custom version of the one in CoreRPG to deal with adding new 
-- pcs to the combat tracker to deal with advanced effects. --celestian
local addPC_old
function addPC(nodeChar)
	-- Parameter validation
	if not nodeChar then
		return;
	end

	-- Call original function for better compatibility
	addPC_old(nodeChar)

	-- now flip through inventory and pass each to updateEffects()
	-- so that if they have a combat_effect it will be applied.
	for _,nodeItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		updateItemEffects(nodeItem,true);
	end
	-- end

	local rActor = ActorManager.resolveActor(nodeChar)
	local nodeCT = ActorManager.getCTNode(rActor)

	-- check to see if npc effects exists and if so apply --celestian
	updateCharEffects(nodeChar,nodeCT);

	-- make sure active users get ownership of their CT nodes
	-- otherwise effects applied by items/etc won't work.
	--AccessManagerADND.manageCTOwners(nodeEntry);
end

-- call the base addNPC from manager_combat2.lua from 5E ruleset for this and
-- then check for PC effects to add -- celestian
local addNPC_old
function addNPC(sClass, nodeCT, sName)
	-- Call original function
	local nodeEntry = addNPC_old(sClass, nodeCT, sName);

	updateCharEffects(nodeCT,nodeEntry);

	return nodeEntry;
end

-- build message to send that effect removed
function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly)
	local sUser = nodeChar.getOwner();
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
	local sUser = nodeCT.getOwner();
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
function isValidCheckEffect(rActor, nodeEffect)
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
		if DB.findNode(rActor.itemPath) and nodeItem then
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

	if nActive ~= 0 then
		if bActionOnly and bActionItemUsed then
			return true;
		elseif bActionOnly and not bActionItemUsed then
			return false;
		else
			return true;
		end
	end
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

	-- ADDITION FOR ADVANCED EFFECTS
	-- to add support for AE in other extensions, make this change
	-- itemPath data filled if itemPath if exists
	local sItemPath
	if EffectManagerAE then
		sItemPath = draginfo.getMetaData("itemPath");
		if (sItemPath and sItemPath ~= "") then
			rSource.itemPath = sItemPath;
		end
	end
	-- END ADDITION FOR ADVANCED EFFECTS

	return rSource, aTargets;
end

--	replace 3.5E EffectManager35E manager_effect_35E.lua hasEffect() with this
local function hasEffect_new(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = sEffect:lower();

	-- Iterate through each effect
	local aMatch = {};
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);

		-- COMPATIBILITY FOR ADVANCED EFFECTS
		-- to add support for AE in other extensions, make this change
		-- original line: if nActive ~= 0 then
		if ((not EffectManagerAE and nActive ~= 0) or (EffectManagerAE and isValidCheckEffect(rActor,v))) then
		-- END COMPATIBILITY FOR ADVANCED EFFECTS

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

local function hasEffect_kel(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets, rEffectSpell)
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = sEffect:lower();

	-- Iterate through each effect
	local aMatch = {};
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);

		-- COMPATIBILITY FOR ADVANCED EFFECTS
		-- to add support for AE in other extensions, make this change
		-- original line: if nActive ~= 0 then
		if ((not EffectManagerAE and nActive ~= 0) or (EffectManagerAE and isValidCheckEffect(rActor,v))) then
		-- END COMPATIBILITY FOR ADVANCED EFFECTS

			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			-- KEL making conditions work with IFT etc.
			local bIFT = false;
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);
				-- Check conditionals
				-- KEL Adding TAG for SIMMUNE
				if rEffectComp.type == "IF" then
					if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "NIF" then
					if EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not EffectManager35E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
						break;
					end
					bIFT = true;
				elseif rEffectComp.type == "NIFT" then
					if rActor.aTargets and not rTarget then
						-- if ( #rActor.aTargets[1] > 0 ) and not rTarget then
						break;
						-- end
					end
					if EffectManager35E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
						break;
					end
					if rTarget then
						bIFT = true;
					end
				elseif rEffectComp.type == "IFTAG" then
					if not rEffectSpell then
						break;
					elseif not EffectManager35E.checkTagConditional(rActor, v, rEffectComp.remainder, rEffectSpell) then
						break;
					end
				elseif rEffectComp.type == "NIFTAG" then
					if EffectManager35E.checkTagConditional(rActor, v, rEffectComp.remainder, rEffectSpell) then
						break;
					end

				-- Check for match
				elseif rEffectComp.original:lower() == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif bTargetedOnly and bIFT then
						nMatch = kEffectComp;
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
local function checkConditionalHelper_kel(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end

	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);

		-- COMPATIBILITY FOR ADVANCED EFFECTS
		-- to add support for AE in other extensions, make this change
		-- original line: if nActive ~= 0 and not StringManager.contains(aIgnore, v.getPath()) then
		if ((not EffectManagerAE and nActive ~= 0) or (EffectManagerAE and isValidCheckEffect(rActor,v))) and not StringManager.contains(aIgnore, v.getPath()) then
		-- END COMPATIBILITY FOR ADVANCED EFFECTS

			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			for _,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);
				--Check conditionals
				if rEffectComp.type == "IF" then
					if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "NIF" then
					if EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "IFTAG" then
					break;
				elseif rEffectComp.type == "NIFTAG" then
					break;
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not EffectManager35E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "NIFT" then
					if rActor.aTargets and not rTarget then
						-- if ( #rActor.aTargets[1] > 0 ) and not rTarget then
						break;
						-- end
					end
					if EffectManager35E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end

				-- Check for match
				-- KEL ignore effects which are on skip
				elseif rEffectComp.original:lower() == sEffect and nActive == 1 then
					if EffectManager.isTargetedEffect(v) then
						if EffectManager.isEffectTarget(v, rTarget) then
							-- if nActive == 1 then
							return true;
							-- end
						end
					else
						-- if nActive == 1 then
						return true;
						-- end
					end
				-- KEL Flatfooted improved
				elseif sEffect == "nodex" and nActive == 1 then
					local sLowerKel = rEffectComp.original:lower();
					if StringManager.contains(DataCommon2.tnodex, sLowerKel) then
						if EffectManager.isTargetedEffect(v) then
							if EffectManager.isEffectTarget(v, rTarget) then
								return true;
							end
						else
							return true;
						end
					end
				-- END
				end
			end
		end
	end
	-- KEL CA for nodex thing; FG really dislikes having another effect list check in an existing effect list
	-- Problem here: That creates a loop which will again check CA on the target etc., as in IF: bloodied stuff
	-- if sEffect == "nodex" then
		-- if hasEffect(rTarget, "CA", rActor, true) then
			-- return true;
		-- end
	-- end
	--END

	return false;
end

--	replace 3.5E EffectManager35E manager_effect_35E.lua checkConditionalHelper() with this
local function checkConditionalHelper_new(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end

	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);

		-- COMPATIBILITY FOR ADVANCED EFFECTS
		-- to add support for AE in other extensions, make this change
		-- original line: if nActive ~= 0 and not StringManager.contains(aIgnore, v.getPath()) then
		if ((not EffectManagerAE and nActive ~= 0) or (EffectManagerAE and isValidCheckEffect(rActor,v))) and not StringManager.contains(aIgnore, v.getPath()) then
		-- END COMPATIBILITY FOR ADVANCED EFFECTS

			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			for _,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);
				--Check conditionals
				if rEffectComp.type == "IF" then
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

local function usingKelrugemFOP()
	return (StringManager.contains(Extension.getExtensions(), "Full OverlayPackage") or
			StringManager.contains(Extension.getExtensions(), "Full OverlayPackage with alternative icons") or
			StringManager.contains(Extension.getExtensions(), "Full OverlayPackage with other icons"));
end

-- add the effect if the item is equipped and doesn't exist already
function onInit()
	if Session.IsHost then
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

	-- CoreRPG replacements
	ActionsManager.decodeActors = decodeActors;

	addPC_old = CombatManager.addPC;
	CombatManager.addPC = addPC;

	addNPC_old = CombatManager.addNPC;
	CombatManager.addNPC = addNPC;
	
	-- 3.5E replacements
	if usingKelrugemFOP() then
		EffectManager35E.checkConditionalHelper = EffectManager35E.checkConditionalHelper_kel;
		EffectManager35E.getEffectsByType = getEffectsByType_kel;
		EffectManager35E.hasEffect = hasEffect_kel;
	else
		EffectManager35E.checkConditionalHelper = EffectManager35E.checkConditionalHelper_new;
		EffectManager35E.getEffectsByType = getEffectsByType_new;
		EffectManager35E.hasEffect = hasEffect_new;
	end

	-- option in house rule section, enable/disable allow PCs to edit advanced effects.
	OptionsManager.registerOption2("ADND_AE_EDIT", false, "option_header_houserule", "option_label_ADND_AE_EDIT", "option_entry_cycler", 
			{ labels = "option_val_on" , values = "enabled", baselabel = "option_val_off", baseval = "disabled", default = "disabled" });		
end