--
-- Effects on Items, apply to character in CT
--
--
-- luacheck: globals onInit
-- luacheck: globals inventoryUpdateItemEffects updateItemEffectsForEdit checkEffectsAfterEdit updateFromDeletedInventory
-- luacheck: globals checkEffectsAfterDelete updateItemEffects updateItemEffect updateCharEffects updateCharEffect onPCPostAdd
-- luacheck: globals onNPCPostAdd getUserFromNode sendEffectRemovedMessage sendEffectAddedMessage sendRawMessage isValidCheckEffect
-- luacheck: globals decodeActors getEffectsByType hasEffectCondition hasEffect checkConditionalHelper manager_action_damage_performRoll
-- luacheck: globals manager_action_attack_performRoll manager_power_performAction helperBuildAddStructure addClassFeature
-- luacheck: globals addFeat addSpeciesTrait addAbilityEffects CharSpeciesManager
local addClassFeature_old;
local addFeat_old;
local addSpeciesTrait_old;
local decodeActors_old;
local helperBuildAddStructure_old;
local onNPCPostAdd_old;

-- add the effect if the item is equipped and doesn't exist already
function onInit()
    if Session.IsHost then
        -- watch the combatracker/npc inventory list
        DB.addHandler('combattracker.list.*.inventorylist.*.carried', 'onUpdate', inventoryUpdateItemEffects);
        DB.addHandler('combattracker.list.*.inventorylist.*.effectlist.*.effect', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('combattracker.list.*.inventorylist.*.effectlist.*.durdice', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('combattracker.list.*.inventorylist.*.effectlist.*.durmod', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('combattracker.list.*.inventorylist.*.effectlist.*.name', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('combattracker.list.*.inventorylist.*.effectlist.*.durunit', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('combattracker.list.*.inventorylist.*.effectlist.*.visibility', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('combattracker.list.*.inventorylist.*.effectlist.*.actiononly', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('combattracker.list.*.inventorylist.*.isidentified', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('combattracker.list.*.inventorylist', 'onChildDeleted', updateFromDeletedInventory);

        -- watch the character/pc inventory list
        DB.addHandler('charsheet.*.inventorylist.*.carried', 'onUpdate', inventoryUpdateItemEffects);
        DB.addHandler('charsheet.*.inventorylist.*.effectlist.*.effect', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('charsheet.*.inventorylist.*.effectlist.*.durdice', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('charsheet.*.inventorylist.*.effectlist.*.durmod', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('charsheet.*.inventorylist.*.effectlist.*.name', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('charsheet.*.inventorylist.*.effectlist.*.durunit', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('charsheet.*.inventorylist.*.effectlist.*.visibility', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('charsheet.*.inventorylist.*.effectlist.*.actiononly', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('charsheet.*.inventorylist.*.isidentified', 'onUpdate', updateItemEffectsForEdit);
        DB.addHandler('charsheet.*.inventorylist', 'onChildDeleted', updateFromDeletedInventory);
    end

    onNPCPostAdd_old = CombatRecordManager.getRecordTypePostAddCallback('npc');
    CombatRecordManager.setRecordTypePostAddCallback('npc', onNPCPostAdd);
    CombatRecordManager.setRecordTypePostAddCallback('charsheet', onPCPostAdd);

    -- CoreRPG replacements
    decodeActors_old = ActionsManager.decodeActors;
    ActionsManager.decodeActors = decodeActors;

    -- 5E effects replacements
    EffectManager5E.checkConditionalHelper = checkConditionalHelper;
    EffectManager5E.getEffectsByType = getEffectsByType;
    EffectManager5E.hasEffect = hasEffect;
    EffectManager5E.hasEffectCondition = hasEffectCondition;

    -- used for 5E extension ONLY
    ActionAttack.performRoll = manager_action_attack_performRoll;
    ActionDamage.performRoll = manager_action_damage_performRoll;
    addClassFeature_old = CharClassManager.addClassFeature;
    CharClassManager.addClassFeature = addClassFeature;
    addFeat_old = CharFeatManager.addFeat;
    CharFeatManager.addFeat = addFeat;
    addSpeciesTrait_old = CharSpeciesManager.addSpeciesTrait;
    CharSpeciesManager.addSpeciesTrait = addSpeciesTrait;
    helperBuildAddStructure_old = CharManager.helperBuildAddStructure;
    CharManager.helperBuildAddStructure = helperBuildAddStructure;
    PowerManager.performAction = manager_power_performAction;

    -- option in house rule section, enable/disable allow PCs to edit advanced effects.
    OptionsManager.registerOption2('ADND_AE_EDIT', false, 'option_header_houserule', 'option_label_ADND_AE_EDIT',
                                   'option_entry_cycler', {
        labels = 'option_label_ADND_AE_enabled',
        values = 'enabled',
        baselabel = 'option_label_ADND_AE_disabled',
        baseval = 'disabled',
        default = 'disabled'
    });

    if PowerUp then
        PowerUp.registerExtension('Advanced Effects', '~dev_version~');
    end

end

-- run from addHandler for updated item effect options
function inventoryUpdateItemEffects(nodeField)
    updateItemEffects(DB.getChild(nodeField, '..'));
end

-- update single item from edit for *.effect handler
function updateItemEffectsForEdit(nodeField)
    checkEffectsAfterEdit(DB.getChild(nodeField, '..'));
end

-- find the effect for this source and delete and re-build
function checkEffectsAfterEdit(itemNode)
    local nodeChar;
    if DB.getPath(itemNode):match('%.effectlist%.') then
        nodeChar = DB.getChild(itemNode, '.....');
    else
        nodeChar = DB.getChild(itemNode, '...');
    end
    local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodeChar));
    if nodeCT then
        for _, nodeEffect in ipairs(DB.getChildList(nodeCT, 'effects')) do
            local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
            -- see if the node exists and if it's in an inventory node
            local nodeEffectFound = DB.findNode(sEffSource);
            if (nodeEffectFound and string.match(sEffSource, 'inventorylist')) then
                local nodeEffectItem = DB.getChild(nodeEffectFound, '...');
                if nodeEffectFound == itemNode then -- effect hide/show edit
                    DB.deleteNode(nodeEffect);
                    updateItemEffects(DB.getChild(itemNode, '...'));
                elseif nodeEffectItem == itemNode then -- id state was changed
                    DB.deleteNode(nodeEffect);
                    updateItemEffects(nodeEffectItem);
                end
            end
        end
    end
end

-- this checks to see if an effect is missing a associated item that applied the effect
-- when items are deleted and then clears that effect if it's missing.
function updateFromDeletedInventory(node)
    local nodeChar = DB.getChild(node, '..');
    local bisNPC = (not ActorManager.isPC(nodeChar));
    local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodeChar));
    -- if we're already in a combattracker situation (npcs)
    if bisNPC and string.match(DB.getPath(nodeChar), '^combattracker') then
        nodeCT = nodeChar;
    end
    if nodeCT then
        -- check that we still have the combat effect source item
        -- otherwise remove it
        checkEffectsAfterDelete(nodeCT);
    end
    -- onEncumbranceChanged();
end

-- this checks to see if an effect is missing a associated item that applied the effect
-- when items are deleted and then clears that effect if it's missing.
function checkEffectsAfterDelete(nodeChar)
    local sUser = User.getUsername();
    for _, nodeEffect in ipairs(DB.getChildList(nodeChar, 'effects')) do
        local sLabel = DB.getValue(nodeEffect, 'label', '');
        local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
        -- see if the node exists and if it's in an inventory node
        local nodeFound = DB.findNode(sEffSource);
        local bDeleted = ((nodeFound == nil) and string.match(sEffSource, 'inventorylist'));
        if (bDeleted) then
            local msg = {font = 'msgfont', icon = 'roll_effect'};
            msg.text = 'Effect [\'' .. sLabel .. '\'] ';
            msg.text = msg.text .. 'removed [from ' .. DB.getValue(nodeChar, 'name', '') .. ']';
            -- HANDLE APPLIED BY SETTING
            if sEffSource and sEffSource ~= '' then
                msg.text = msg.text .. ' [by Deletion]';
            end
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
            DB.deleteNode(nodeEffect);
        end

    end
end

function updateItemEffects(nodeItem)
    local nodeChar = DB.getChild(nodeItem, '...');
    if not nodeChar then
        return;
    end
    local sName = DB.getValue(nodeItem, 'name', '');
    -- we swap the node to the combat tracker node
    -- so the "effect" is written to the right node
    if not string.match(DB.getPath(nodeChar), '^combattracker') then
        nodeChar = ActorManager.getCTNode(ActorManager.resolveActor(nodeChar));
    end
    -- if not in the combat tracker bail
    if not nodeChar then
        return;
    end

    local nCarried = DB.getValue(nodeItem, 'carried', 0);
    local bEquipped = (nCarried == 2);
    local nIdentified = DB.getValue(nodeItem, 'isidentified', 1);
    -- local bOptionID = OptionsManager.isOption("MIID", "on");
    -- if not bOptionID then
    -- nIdentified = 1;
    -- end

    for _, nodeItemEffect in ipairs(DB.getChildList(nodeItem, 'effectlist')) do
        updateItemEffect(nodeItemEffect, sName, nodeChar, nil, bEquipped, nIdentified);
    end -- for item's effects list
end

-- update single effect for item
function updateItemEffect(nodeItemEffect, sName, nodeChar, _, bEquipped, nIdentified)
    local sItemSource = DB.getPath(nodeItemEffect);
    local sLabel = DB.getValue(nodeItemEffect, 'effect', '');
    if sLabel and sLabel ~= '' then -- if we have effect string
        local bFound = false;
        for _, nodeEffect in ipairs(DB.getChildList(nodeChar, 'effects')) do
            local nActive = DB.getValue(nodeEffect, 'isactive', 0);
            local nDMOnly = DB.getValue(nodeEffect, 'isgmonly', 0);
            if (nActive ~= 0) then
                local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
                if (sEffSource == sItemSource) then
                    bFound = true;
                    if (not bEquipped) then
                        sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly);
                        DB.deleteNode(nodeEffect);
                        break
                    end -- not equipped
                end -- effect source == item source
            end -- was active
        end -- nodeEffect for

        if (not bFound and bEquipped) then
            local rEffect = {};
            local nRollDuration;
            local dDurationDice = DB.getValue(nodeItemEffect, 'durdice');
            local nModDice = DB.getValue(nodeItemEffect, 'durmod', 0);
            if (dDurationDice and dDurationDice ~= '') then
                nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
            else
                nRollDuration = nModDice;
            end
            local nDMOnly = 0;
            local sVisibility = DB.getValue(nodeItemEffect, 'visibility', '');
            if sVisibility == 'hide' then
                nDMOnly = 1;
            elseif sVisibility == 'show' then
                nDMOnly = 0;
            elseif nIdentified == 0 then
                nDMOnly = 1;
            elseif nIdentified > 0 then
                nDMOnly = 0;
            end

            if not ActorManager.isPC(nodeChar) then
                local bTokenVis = (DB.getValue(nodeChar, 'tokenvis', 1) == 1);
                if not bTokenVis then
                    nDMOnly = 1; -- hide if token not visible
                end
            end

            rEffect.nDuration = nRollDuration;
            rEffect.sName = sName .. ';' .. sLabel;
            rEffect.sLabel = sLabel;
            rEffect.sUnits = DB.getValue(nodeItemEffect, 'durunit', '');
            rEffect.nInit = 0;
            rEffect.sSource = sItemSource;
            rEffect.nGMOnly = nDMOnly;
            rEffect.sApply = DB.getValue(nodeItemEffect, 'apply', '');
            rEffect.sChangeState = DB.getValue(nodeItemEffect, 'changestate', '');

            sendEffectAddedMessage(nodeChar, rEffect, sLabel, nDMOnly)
            EffectManager.addEffect('', '', nodeChar, rEffect, false);
        end
    end
end

-- flip through all npc effects (generally do this in addNPC()/addPC()
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffects(nodeChar, nodeEntry)
    for _, nodeCharEffect in ipairs(DB.getChildList(nodeChar, 'effectlist')) do
        updateCharEffect(nodeCharEffect, nodeEntry);
    end -- for item's effects list
end

-- this will be used to manage PC/NPC effectslist objects
-- nodeCharEffect: node in effectlist on PC/NPC
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffect(nodeCharEffect, nodeEntry)
    local sLabel = DB.getValue(nodeCharEffect, 'effect', '');
    local nRollDuration;
    local dDurationDice = DB.getValue(nodeCharEffect, 'durdice');
    local nModDice = DB.getValue(nodeCharEffect, 'durmod', 0);
    if (dDurationDice and dDurationDice ~= '') then
        nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
    local nDMOnly = 0;
    local sVisibility = DB.getValue(nodeCharEffect, 'visibility', '');
    if sVisibility == 'show' then
        nDMOnly = 0;
    elseif sVisibility == 'hide' then
        nDMOnly = 1;
    end

    local rEffect = {};
    rEffect.nDuration = nRollDuration;
    -- rEffect.sName = sName .. ";" .. sLabel;
    rEffect.sName = sLabel;
    rEffect.sLabel = sLabel;
    rEffect.sUnits = DB.getValue(nodeCharEffect, 'durunit', '');
    rEffect.nInit = 0;
    -- rEffect.sSource = DB.getPath(nodeEntry);
    rEffect.nGMOnly = nDMOnly;
    rEffect.sApply = DB.getValue(nodeCharEffect, 'apply', '');
    rEffect.sChangeState = DB.getValue(nodeCharEffect, 'changestate', '');

    sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nDMOnly);
    EffectManager.addEffect('', '', nodeEntry, rEffect, false);
end

-- custom version of the one in CoreRPG to deal with adding new
-- pcs to the combat tracker to deal with advanced effects. --celestian
function onPCPostAdd(tCustom)
    -- add this to make the npc show up first time for Situational Awareness
    DB.setValue(tCustom.nodeCT, 'ct.visible', 'number', 1);
    --

    -- now flip through inventory and pass each to updateEffects()
    -- so that if they have a combat_effect it will be applied.
    for _, nodeItem in ipairs(DB.getChildList(tCustom.nodeRecord, 'inventorylist')) do
        updateItemEffects(nodeItem);
    end
    -- check to see if pc effects exists and if so apply --celestian
    updateCharEffects(tCustom.nodeRecord, tCustom.nodeCT);
end

-- I call the 5e version of CombatManager2.addNPC directly and then touch up what I need now
-- added the bit that checks for PC effects to add -- celestian
function onNPCPostAdd(tCustom)
    onNPCPostAdd_old(tCustom);

    -- add this to make the npc show up first time for Situational Awareness
    DB.setValue(tCustom.nodeCT, 'ct.visible', 'number', 1);

    -- check to see if npc effects exists and if so apply --celestian
    updateCharEffects(tCustom.nodeRecord, tCustom.nodeCT);
end

-- get the Connected Player's name that has this identity
function getUserFromNode(node)
    local _, sRecord = DB.getValue(node, 'link', '', '');
    local sUser = nil;
    for _, vUser in ipairs(User.getActiveUsers()) do
        for _, vIdentity in ipairs(User.getActiveIdentities(vUser)) do
            if (sRecord == ('charsheet.' .. vIdentity)) then
                sUser = vUser;
                break
            end
        end
    end
    return sUser;
end

-- build message to send that effect removed
function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly)
    local sUser = getUserFromNode(nodeChar);
    local sCharacterName = DB.getValue(nodeChar, 'name', '');
    -- Build output message
    local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeChar), sUser);
    msg.text = 'Advanced Effect [\'' .. sLabel .. '\'] ';
    msg.text = msg.text .. 'removed [from ' .. sCharacterName .. ']';
    -- HANDLE APPLIED BY SETTING
    local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
    if sEffSource and sEffSource ~= '' then
        msg.text = msg.text .. ' [by ' .. DB.getValue(DB.findNode(sEffSource), 'name', '') .. ']';
    end
    sendRawMessage(sUser, nDMOnly, msg);
end

-- build message to send that effect added
function sendEffectAddedMessage(nodeCT, rNewEffect, _, nDMOnly)
    local sUser = getUserFromNode(nodeCT);
    -- Build output message
    local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeCT), sUser);
    msg.text = 'Advanced Effect [\'' .. rNewEffect.sName .. '\'] ';
    msg.text = msg.text .. '-> [to ' .. DB.getValue(nodeCT, 'name', '') .. ']';
    if rNewEffect.sSource and rNewEffect.sSource ~= '' then
        msg.text = msg.text .. ' [by ' .. DB.getValue(DB.findNode(rNewEffect.sSource), 'name', '') .. ']';
    end
    sendRawMessage(sUser, nDMOnly, msg);
end

-- send message
function sendRawMessage(sUser, nDMOnly, msg)
    local sIdentity = nil;
    if sUser and sUser ~= '' then
        sIdentity = User.getCurrentIdentity(sUser) or nil;
    end
    if sIdentity then
        msg.icon = 'portrait_' .. User.getCurrentIdentity(sUser) .. '_chat';
    else
        msg.font = 'msgfont';
        msg.icon = 'roll_effect';
    end
    if nDMOnly == 1 then
        msg.secret = true;
        Comm.addChatMessage(msg);
    elseif nDMOnly ~= 1 then
        Comm.deliverChatMessage(msg);
    end
end

---	This function returns false if the effect is tied to an item and the item is not being used.
function isValidCheckEffect(rActor, nodeEffect)
    if DB.getValue(nodeEffect, 'isactive', 0) ~= 0 then
        local bActionItemUsed, bActionOnly = false, false;
        local sItemPath = '';

        local sSource = DB.getValue(nodeEffect, 'source_name', '');
        -- if source is a valid node and we can find "actiononly"
        -- setting then we set it.
        local node = DB.findNode(sSource);
        if node then
            local nodeItem = DB.getChild(node, '...');
            if nodeItem then
                sItemPath = DB.getPath(nodeItem);
                bActionOnly = (DB.getValue(node, 'actiononly', 0) ~= 0);
            end
        end

        if sItemPath and sItemPath ~= '' then
            -- if there is an itemPath do some sanity checking
            if rActor.itemPath then
                -- here is where we get the node path of the item, not the
                -- effectslist entry
                if bActionOnly and (sItemPath == rActor.itemPath) then
                    bActionItemUsed = true;
                end
            end

            -- if there is a ammoPath do some sanity checking
            if AmmunitionManager and rActor.ammoPath then
                -- here is where we get the node path of the item, not the
                -- effectslist entry
                if bActionOnly and (sItemPath == rActor.ammoPath) then
                    bActionItemUsed = true;
                end
            end
        end

        if bActionOnly and not bActionItemUsed then
            return false;
        else
            return true;
        end
    end
end

--
--          REPLACEMENT FUNCTIONS
--

--	replace CoreRPG ActionsManager manager_actions.lua decodeActors() with this
function decodeActors(draginfo, ...)
    local rSource, aTargets = decodeActors_old(draginfo, ...);

    local sItemPath = draginfo.getMetaData('itemPath');
    if (sItemPath and sItemPath ~= '') then
        rSource.itemPath = sItemPath;
    end

    local sAmmoPath = draginfo.getMetaData('ammoPath')
    if AmmunitionManager and (sAmmoPath and sAmmoPath ~= '') then
        rSource.ammoPath = sAmmoPath;
    end

    return rSource, aTargets;
end

-- luacheck: push ignore 561
-- replace 5E EffectManager5E manager_effect_5E.lua getEffectsByType() with this
function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
    if not rActor then
        return {};
    end
    local results = {};

    -- Set up filters
    local aRangeFilter = {};
    local aOtherFilter = {};
    if aFilter then
        for _, v in pairs(aFilter) do
            if type(v) ~= 'string' then
                table.insert(aOtherFilter, v);
            elseif StringManager.contains(DataCommon.rangetypes, v) then
                table.insert(aRangeFilter, v);
            else
                table.insert(aOtherFilter, v);
            end
        end
    end

    local aEffects;
    if TurboManager then
        aEffects = TurboManager.getMatchedEffects(rActor, sEffectType);
    else
        aEffects = DB.getChildList(ActorManager.getCTNode(rActor), 'effects');
    end
    -- Iterate through effects
    for _, v in ipairs(aEffects) do
        -- Check active
        local nActive = DB.getValue(v, 'isactive', 0);
        if (EffectManagerADND.isValidCheckEffect(rActor, v)) then
            local sLabel = DB.getValue(v, 'label', '');
            local sApply = DB.getValue(v, 'apply', '');

            -- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
            local bTargeted = EffectManager.isTargetedEffect(v);
            if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
                local aEffectComps = EffectManager.parseEffect(sLabel);

                -- Look for type/subtype match
                local nMatch = 0;
                for kEffectComp, sEffectComp in ipairs(aEffectComps) do
                    local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
                    -- Handle conditionals
                    if rEffectComp.type == 'IF' then
                        if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
                            break
                        end
                    elseif rEffectComp.type == 'IFT' then
                        if not rFilterActor then
                            break
                        end
                        if not EffectManager5E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
                            break
                        end
                        bTargeted = true;

                        -- Compare other attributes
                    else
                        -- Strip energy/bonus types for subtype comparison
                        local aEffectRangeFilter = {};
                        local aEffectOtherFilter = {};
                        local j = 1;
                        while rEffectComp.remainder[j] do
                            local s = rEffectComp.remainder[j];
                            if #s > 0 and ((s:sub(1, 1) == '!') or (s:sub(1, 1) == '~')) then
                                s = s:sub(2);
                            end
                            -- luacheck: push ignore 542
                            if StringManager.contains(DataCommon.dmgtypes, s) or s == 'all' or
                                StringManager.contains(DataCommon.bonustypes, s) or
                                StringManager.contains(DataCommon.conditions, s) or
                                StringManager.contains(DataCommon.connectors, s) then
                                -- SKIP
                            elseif StringManager.contains(DataCommon.rangetypes, s) then
                                table.insert(aEffectRangeFilter, s);
                            else
                                table.insert(aEffectOtherFilter, s);
                            end
                            -- luacheck: pop

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
                                for _, v2 in pairs(aRangeFilter) do
                                    if StringManager.contains(aEffectRangeFilter, v2) then
                                        bRangeMatch = true;
                                        break
                                    end
                                end
                                if not bRangeMatch then
                                    comp_match = false;
                                end
                            end
                            if #aEffectOtherFilter > 0 then
                                local bOtherMatch = false;
                                for _, v2 in pairs(aOtherFilter) do
                                    if type(v2) == 'table' then
                                        local bOtherTableMatch = true;
                                        for _, v3 in pairs(v2) do
                                            if not StringManager.contains(aEffectOtherFilter, v3) then
                                                bOtherTableMatch = false;
                                                break
                                            end
                                        end
                                        if bOtherTableMatch then
                                            bOtherMatch = true;
                                            break
                                        end
                                    elseif StringManager.contains(aEffectOtherFilter, v2) then
                                        bOtherMatch = true;
                                        break
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
                        DB.setValue(v, 'isactive', 'number', 1);
                    else
                        if sApply == 'action' then
                            EffectManager.notifyExpire(v, 0);
                        elseif sApply == 'roll' then
                            EffectManager.notifyExpire(v, 0, true);
                        elseif sApply == 'single' then
                            EffectManager.notifyExpire(v, nMatch, true);
                        end
                    end
                end
            end -- END TARGET CHECK
        end -- END ACTIVE CHECK
    end -- END EFFECT LOOP

    -- RESULTS
    return results;
end
-- luacheck: pop

function hasEffectCondition(rActor, sEffect)
    return EffectManager5E.hasEffect(rActor, sEffect, nil, false, true);
end

-- replace 5E EffectManager5E manager_effect_5E.lua hasEffect() with this
function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
    if not sEffect or not rActor then
        return false;
    end
    local sLowerEffect = sEffect:lower();

    local aMatch = {};
    local aEffects;
    if TurboManager then
        aEffects = TurboManager.getMatchedEffects(rActor, sEffect);
    else
        aEffects = DB.getChildList(ActorManager.getCTNode(rActor), 'effects');
    end
    -- Iterate through effects
    for _, v in ipairs(aEffects) do
        local nActive = DB.getValue(v, 'isactive', 0);
        if (EffectManagerADND.isValidCheckEffect(rActor, v)) then
            -- Parse each effect label
            local sLabel = DB.getValue(v, 'label', '');
            local bTargeted = EffectManager.isTargetedEffect(v);
            local aEffectComps = EffectManager.parseEffect(sLabel);

            -- Iterate through each effect component looking for a type match
            local nMatch = 0;
            for kEffectComp, sEffectComp in ipairs(aEffectComps) do
                local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
                -- Handle conditionals
                if rEffectComp.type == 'IF' then
                    if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
                        break
                    end
                elseif rEffectComp.type == 'IFT' then
                    if not rTarget then
                        break
                    end
                    if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
                        break
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
                    DB.setValue(v, 'isactive', 'number', 1);
                else
                    table.insert(aMatch, v);
                    local sApply = DB.getValue(v, 'apply', '');
                    if sApply == 'action' then
                        EffectManager.notifyExpire(v, 0);
                    elseif sApply == 'roll' then
                        EffectManager.notifyExpire(v, 0, true);
                    elseif sApply == 'single' then
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

-- replace 5E EffectManager5E manager_effect_5E.lua checkConditionalHelper() with this
function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
    if not rActor then
        return false;
    end

    for _, v in ipairs(DB.getChildList(ActorManager.getCTNode(rActor), 'effects')) do
        if (EffectManagerADND.isValidCheckEffect(rActor, v) and not StringManager.contains(aIgnore, v.getNodeName())) then
            -- Parse each effect label
            local sLabel = DB.getValue(v, 'label', '');
            local aEffectComps = EffectManager.parseEffect(sLabel);

            -- Iterate through each effect component looking for a type match
            for _, sEffectComp in ipairs(aEffectComps) do
                local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);

                -- CHECK CONDITIONALS
                if rEffectComp.type == 'IF' then
                    if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
                        break
                    end
                elseif rEffectComp.type == 'IFT' then
                    if not rTarget then
                        break
                    end
                    if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
                        break
                    end

                    -- CHECK FOR AN ACTUAL EFFECT MATCH
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

-- replace 5E ActionDamage manager_action_damage.lua performRoll() with this
-- extension only
function manager_action_damage_performRoll(draginfo, rActor, rAction)
    local rRoll = ActionDamage.getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= '') then
        draginfo.setMetaData('itemPath', rActor.itemPath);
    end
    if AmmunitionManager and (draginfo and rActor.ammoPath and rActor.ammoPath ~= '') then
        draginfo.setMetaData('ammoPath', rActor.ammoPath);
    end

    ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- replace 5E ActionAttack manager_action_attack.lua performRoll() with this
-- extension only
function manager_action_attack_performRoll(draginfo, rActor, rAction)
    local rRoll = ActionAttack.getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= '') then
        draginfo.setMetaData('itemPath', rActor.itemPath);
    end
    if AmmunitionManager and (draginfo and rActor.ammoPath and rActor.ammoPath ~= '') then
        draginfo.setMetaData('ammoPath', rActor.ammoPath);
    end

    ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- replace 5E PowerManager manager_power.lua performAction() with this
-- extension only
function manager_power_performAction(draginfo, rActor, rAction, nodePower)
    if not rActor or not rAction then
        return false;
    end

    -- add itemPath to rActor so that when effects are checked we can
    -- make compare against action only effects
    local nodeWeapon = DB.getChild(nodePower, '...');
    local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '');
    rActor.itemPath = sRecord;

    -- bmos adding AmmunitionManager integration
    if AmmunitionManager then
        local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor)
        if nodeAmmo then
            rActor.ammoPath = DB.getPath(nodeAmmo)
        end
        if (draginfo and rActor.ammoPath and rActor.ammoPath ~= '') then
            draginfo.setMetaData('ammoPath', rActor.ammoPath);
        end
    end

    if (draginfo and rActor.itemPath and rActor.itemPath ~= '') then
        draginfo.setMetaData('itemPath', rActor.itemPath);
    end
    --

    PowerManager.evalAction(rActor, nodePower, rAction);

    local rRolls = {};
    if rAction.type == 'cast' then
        rAction.subtype = (rAction.subtype or '');
        if rAction.subtype == '' then
            table.insert(rRolls, ActionPower.getPowerCastRoll(rActor, rAction));
        end
        if ((rAction.subtype == '') or (rAction.subtype == 'atk')) and rAction.range then
            table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
        end
        if ((rAction.subtype == '') or (rAction.subtype == 'save')) and ((rAction.save or '') ~= '') then
            table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));
        end

    elseif rAction.type == 'attack' then
        table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));

    elseif rAction.type == 'powersave' then
        table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));

    elseif rAction.type == 'damage' then
        table.insert(rRolls, ActionDamage.getRoll(rActor, rAction));

    elseif rAction.type == 'heal' then
        table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));

    elseif rAction.type == 'effect' then
        local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
        if rRoll then
            table.insert(rRolls, rRoll);
        end
    end

    if #rRolls > 0 then
        ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
    end
    return true;
end

local rAdd;
-- replace 5E CharManager manager_char.lua helperBuildAddStructure() with this
function helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard)
    rAdd = helperBuildAddStructure_old(nodeChar, sClass, sRecord, bWizard);
    return rAdd;
end

-- replace 5E CharClassManager manager_char_class.lua addClassFeature() with this
function addClassFeature(nodeChar, sClass, sRecord, nodeClass, bWizard)
    addClassFeature_old(nodeChar, sClass, sRecord, nodeClass, bWizard);
    if rAdd then
        addAbilityEffects(nodeChar);
    end
end

-- replace 5E CharFeatManager manager_char_feat.lua addFeat() with this
function addFeat(nodeChar, sClass, sRecord, bWizard)
    addFeat_old(nodeChar, sClass, sRecord, bWizard);
    if rAdd then
        addAbilityEffects(nodeChar);
    end
end

-- replace 5E CharSpeciesManager manager_char.lua addSpeciesTrait() with this
function addSpeciesTrait(nodeChar, sClass, sRecord, bWizard)
    addSpeciesTrait_old(nodeChar, sClass, sRecord, bWizard);
    if rAdd then
        addAbilityEffects(nodeChar);
    end
end

-- Common logic for adding effects from abilities to the character upon gaining the ability.
function addAbilityEffects(nodeChar)
    local nodeSource = rAdd.nodeSource;
    if not nodeSource then
        return;
    end

    local nodeList = nodeChar.createChild('effectlist');
    if not nodeList then
        return;
    end

    local nodeEntry = ActorManager.getCTNode(nodeChar);
    for _, nodeSourceEffect in ipairs(DB.getChildList(nodeSource, 'effectlist')) do
        local nodeCharEffect = nodeList.createChild();
        DB.copyNode(nodeSourceEffect, nodeCharEffect);
        if nodeEntry then
            updateCharEffect(nodeCharEffect, nodeEntry);
        end
    end
end
