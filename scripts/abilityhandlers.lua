--
-- Effects on Abilities, apply to character in CT
--
---	This function removes existing effects and re-parses them.
--	First it finds any effects that have this ability as the source and removes those effects.
--	Then it calls updateAbilityEffects to re-parse the current/correct effects.
local function replaceAbilityEffects(nodeAbility)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(nodeAbility, '...')));
	if nodeCT then
		local bFound
		for _, nodeEffect in pairs(DB.getChildren(nodeCT, 'effects')) do
			local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
			-- see if the node exists and if it's in an effectlist
			local nodeAbilitySource = DB.findNode(sEffSource);
			if nodeAbilitySource and string.match(sEffSource, 'effectlist') then
				if nodeAbilitySource.getChild('...') == nodeAbility then
					nodeEffect.delete(); -- remove existing effect
					bFound = true
					AdvancedEffects.updateItemEffects(nodeAbility);
				end
			end
		end
		return bFound
	end
end

local function addAbilityEffect(node)
	local nodeAbility = node.getParent();
	if nodeAbility then AdvancedEffects.updateItemEffects(nodeAbility); end
end

--	This function changes the associated effects when ability effect lists are changed.
local function updateAbilityEffectsForEdit(node)
	local nodeAbility = node.getChild('....');
	if nodeAbility and not replaceAbilityEffects(nodeAbility) then AdvancedEffects.updateItemEffects(nodeAbility); end
end

---	This function checks to see if an effect is missing its associated ability.
--	If an associated ability isn't found, it removes the effect as the ability has been removed
local function checkEffectsAfterDelete(nodeChar)
	local sUser = User.getUsername();
	for _, nodeEffect in pairs(DB.getChildren(nodeChar, 'effects')) do
		local sLabel = DB.getValue(nodeEffect, 'label', '');
		local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
		-- see if the node exists and if it's in an effectlist
		local bDeleted = (not DB.findNode(sEffSource) and string.match(sEffSource, 'effectlist'));
		if bDeleted then
			local msg = { font = 'msgfont', icon = 'roll_effect' };
			msg.text = 'Effect [\'' .. sLabel .. '\'] ';
			msg.text = msg.text .. 'removed [from ' .. DB.getValue(nodeChar, 'name', '') .. ']';
			-- HANDLE APPLIED BY SETTING
			if sEffSource and sEffSource ~= '' then msg.text = msg.text .. ' [by Deletion]'; end
			if EffectManager.isGMEffect(nodeChar, nodeEffect) then
				if sUser == '' then
					msg.secret = true;
					Comm.addChatMessage(msg);
				elseif sUser ~= '' then
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

---	This function checks to see if an effect is missing its associated ability.
--	If an associated ability isn't found, it removes the effect as the ability has been removed
local function updateFromDeletedAbility(node)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(node.getParent()));
	if nodeCT then checkEffectsAfterDelete(nodeCT); end
end

---	Triggers after an effect on an ability is deleted, causing a recheck of the effects in the combat tracker
local function removeEffectOnAbilityEffectDelete(node)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(node, '....')));
	if nodeCT then checkEffectsAfterDelete(nodeCT); end
end

function onInit()
	if Session.IsHost then
		-- watch the character/pc class lists
		DB.addHandler('charsheet.*.class.*.effectlist', 'onChildAdded', addAbilityEffect);
		DB.addHandler('charsheet.*.class.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.class.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.class.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.class.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.class.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.class.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.class.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.class.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
		DB.addHandler('charsheet.*.class', 'onChildDeleted', updateFromDeletedAbility);
		-- watch the character/pc class ability lists
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist', 'onChildAdded', addAbilityEffect);
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.specialabilitylist.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
		DB.addHandler('charsheet.*.specialabilitylist', 'onChildDeleted', updateFromDeletedAbility);
		-- watch the character/pc feats lists
		DB.addHandler('charsheet.*.featlist.*.effectlist', 'onChildAdded', addAbilityEffect);
		DB.addHandler('charsheet.*.featlist.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.featlist.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.featlist.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.featlist.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.featlist.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.featlist.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.featlist.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.featlist.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
		DB.addHandler('charsheet.*.featlist', 'onChildDeleted', updateFromDeletedAbility);
		-- watch the character/pc proficiencies lists
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist', 'onChildAdded', addAbilityEffect);
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.proficiencylist.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
		DB.addHandler('charsheet.*.proficiencylist', 'onChildDeleted', updateFromDeletedAbility);
		-- watch the character/pc racial traits lists
		DB.addHandler('charsheet.*.traitlist.*.effectlist', 'onChildAdded', addAbilityEffect);
		DB.addHandler('charsheet.*.traitlist.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.traitlist.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.traitlist.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.traitlist.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.traitlist.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.traitlist.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.traitlist.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
		DB.addHandler('charsheet.*.traitlist.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
		DB.addHandler('charsheet.*.traitlist', 'onChildDeleted', updateFromDeletedAbility);
	end
end
