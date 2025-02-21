--
-- Effects on Items, apply to character in CT
--
--
-- luacheck: globals onInit
-- luacheck: globals inventoryUpdateItemEffects updateItemEffectsForEdit checkEffectsAfterEdit updateFromDeletedInventory
-- luacheck: globals checkEffectsAfterDelete updateItemEffects updateItemEffect updateCharEffects updateCharEffect onPCPostAdd
-- luacheck: globals customOnNPCPostAdd getUserFromNode sendEffectRemovedMessage sendEffectAddedMessage sendRawMessage isValidCheckEffect
-- luacheck: globals customDecodeActors getEffectsByType hasEffectCondition hasEffect checkConditionalHelper manager_action_damage_performRoll
-- luacheck: globals manager_action_attack_performRoll manager_power_performAction customHelperBuildAddStructure customAddClassFeature
-- luacheck: globals customAddFeat customAddSpeciesTrait addAbilityEffects CharSpeciesManager

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
        updateItemEffect(nodeItemEffect, sName, nodeChar, bEquipped, nIdentified);
    end -- for item's effects list
end

-- TODO: Good to go
-- update single effect for item
function updateItemEffect(nodeItemEffect, sName, nodeChar, bEquipped, nIdentified)
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
            local sVisibility = StringManager.capitalize(DB.getValue(nodeItemEffect, 'visibility', ''));
            if sVisibility == Interface.getString('item_label_effects_hide') then
                nDMOnly = 1;
            elseif sVisibility == Interface.getString('item_label_effects_show') then
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

--TODO Good to go
-- flip through all npc effects (generally do this in addNPC()/addPC()
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffects(nodeChar, nodeCT)
    for _, nodeCharEffect in ipairs(DB.getChildList(nodeChar, 'effectlist')) do
        updateCharEffect(nodeCharEffect, nodeCT);
    end -- for item's effects list
end

--TODO Good to go
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
    local sVisibility = StringManager.capitalize(DB.getValue(nodeCharEffect, 'visibility', ''));
    if sVisibility == Interface.getString('item_label_effects_show') then
        nDMOnly = 0;
    elseif sVisibility == Interface.getString('item_label_effects_hide') then
        nDMOnly = 1;
    end

    local rEffect = {};
    rEffect.nDuration = nRollDuration;
    -- rEffect.sName = sName .. ";" .. sLabel;
    rEffect.sName = sLabel;
    rEffect.sLabel = sLabel;
    rEffect.sUnits = DB.getValue(nodeCharEffect, 'durunit', '');
    rEffect.nInit = 0;
    rEffect.sSource = DB.getPath(nodeEntry);
    rEffect.nGMOnly = nDMOnly;
    rEffect.sApply = DB.getValue(nodeCharEffect, 'apply', '');
    rEffect.sChangeState = DB.getValue(nodeCharEffect, 'changestate', '');

	sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nDMOnly, User.getUsername())
    EffectManager.addEffect('', '', nodeEntry, rEffect, false);
end



----------------------------
-- CHAT MESSAGES
----------------------------
-- TODO Might not need

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

----------------------------
-- END CHAT MESSAGES
----------------------------


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

