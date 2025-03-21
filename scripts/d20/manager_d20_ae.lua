--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
--
-- Effects on Items, apply to character in CT
--
-- luacheck: globals AdvancedEffects onInit sendRawMessage sendEffectRemovedMessage sendEffectAddedMessage isValidCheckEffect
-- luacheck: globals updateCharEffect updateCharEffects updateItemEffect resolveActor updateCharEffects updateItemEffects
local EffectManagerAE = nil;

-- add the effect if the item is equipped and doesn't exist already
function onInit()

    -- Set up the effect manager proxy functions for the detected ruleset
    if EffectManager35E then
        EffectManagerAE = EffectManager35E;
    elseif EffectManagerSFRPG then
        EffectManagerAE = EffectManagerSFRPG;
    elseif EffectManager5E then
        EffectManagerAE = EffectManager5E;
    end
end

function sendRawMessage(sUser, nGMOnly, msg)
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
    if nGMOnly == 1 then
        msg.secret = true;
        Comm.addChatMessage(msg);
    elseif nGMOnly ~= 1 then
        -- Comm.addChatMessage(msg);
        Comm.deliverChatMessage(msg);
    end
end

-- build message to send that effect removed
function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nGMOnly)
    local sUser = DB.getOwner(nodeChar);
    -- Build output message
    local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeChar), sUser);
    msg.text = 'Advanced Effect [\'' .. sLabel .. '\'] ';
    msg.text = msg.text .. 'removed [from ' .. DB.getValue(nodeChar, 'name', '') .. ']';
    -- HANDLE APPLIED BY SETTING
    local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
    if sEffSource and sEffSource ~= '' then
        msg.text = msg.text .. ' [by ' .. DB.getValue(sEffSource .. '.name', '') .. ']';
    end
    AdvancedEffects.sendRawMessage(sUser, nGMOnly, msg);
end

-- build message to send that effect added
function sendEffectAddedMessage(nodeCT, rNewEffect, _, nGMOnly)
    local sUser = DB.getOwner(nodeCT);
    -- Build output message
    local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeCT), sUser);
    msg.text = 'Advanced Effect [\'' .. rNewEffect.sName .. '\'] ';
    msg.text = msg.text .. '-> [to ' .. DB.getValue(nodeCT, 'name', '') .. ']';
    if rNewEffect.sSource and rNewEffect.sSource ~= '' then
        msg.text = msg.text .. ' [by ' .. DB.getValue(rNewEffect.sSource .. '.name', '') .. ']';
    end
    AdvancedEffects.sendRawMessage(sUser, nGMOnly, msg);
end

---	This function returns false if the effect is tied to an item and the item is not being used.
--	luacheck: globals isValidCheckEffect
function isValidCheckEffect(rActor, nodeEffect)
    if DB.getValue(nodeEffect, 'isactive', 0) == 0 then
        return;
    end
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
        -- if there is a nodeWeapon do some sanity checking
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
    end
    return true;
end

-- this will be used to manage PC/NPC effectslist objects
-- nodeCharEffect: node in effectlist on PC/NPC
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffect(nodeCharEffect, nodeEntry)
    local sLabel = DB.getValue(nodeCharEffect, 'effect', '');
    local nRollDuration;
    local dDurationDice = DB.getValue(nodeCharEffect, 'durdice');
    local nModDice = DB.getValue(nodeCharEffect, 'durmod', 0);
    if dDurationDice and dDurationDice ~= '' then
        nRollDuration = DiceManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
    local nGMOnly = 0;
    local sVisibility = StringManager.capitalize(DB.getValue(nodeCharEffect, 'visibility', ''));
    if sVisibility == Interface.getString('item_label_effects_hide') then
        nGMOnly = 1;
    end
    if not ActorManager.isPC(nodeEntry) then
        nGMOnly = 1; -- npcs effects always hidden from PCs/chat when we first drag/drop into CT
    end

    local rEffect = {};
    rEffect.nDuration = nRollDuration;
    -- rEffect.sName = sName .. ";" .. sLabel;
    rEffect.sName = sLabel;
    rEffect.sLabel = sLabel;
    rEffect.sUnits = DB.getValue(nodeCharEffect, 'durunit', '');
    rEffect.nInit = 0;
    rEffect.sSource = DB.getPath(nodeEntry);
    rEffect.nGMOnly = nGMOnly;
    rEffect.sApply = DB.getValue(nodeCharEffect, 'apply', '');
    rEffect.sChangeState = DB.getValue(nodeCharEffect, 'changestate', '');
    rEffect.sName = EffectManagerAE.evalEffect(nodeEntry, rEffect.sLabel); -- handle (N)PC Effects

    AdvancedEffects.sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nGMOnly, User.getUsername());
    EffectManager.addEffect('', '', nodeEntry, rEffect, false);
end

-- flip through all npc effects (generally do this in addNPC()/addPC())
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeCT: node in combat tracker for PC/NPC
function updateCharEffects(nodeChar, nodeCT)
    for _, nodeCharEffect in ipairs(DB.getChildList(nodeChar, 'effectlist')) do
        AdvancedEffects.updateCharEffect(nodeCharEffect, nodeCT);
    end -- for item's effects list
end

-- update single effect for item
function updateItemEffect(nodeItemEffect, sName, nodeChar, bEquipped, bIdentified)
    local sItemSource = DB.getPath(nodeItemEffect);
    local sLabel = DB.getValue(nodeItemEffect, 'effect', '');
    if not sLabel or sLabel == '' then
        return;
    end -- abort if we don't have effect string
    local bFound = false;
    for _, nodeEffect in ipairs(DB.getChildList(nodeChar, 'effects')) do
        local nActive = DB.getValue(nodeEffect, 'isactive', 0);
        local nGMOnly = DB.getValue(nodeEffect, 'isgmonly', 0);
        if nActive ~= 0 then
            local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
            if sEffSource == sItemSource then
                bFound = true;
                if not bEquipped then
                    sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nGMOnly);
                    DB.deleteNode(nodeEffect);
                    break
                end -- not equipped
            end -- effect source == item source
        end -- was active
    end -- nodeEffect for
    if bFound or not bEquipped then
        return;
    end
    local rEffect = {};
    local nRollDuration;
    local dDurationDice = DB.getValue(nodeItemEffect, 'durdice');
    local nModDice = DB.getValue(nodeItemEffect, 'durmod', 0);

    if dDurationDice and dDurationDice ~= '' then
        nRollDuration = DiceManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
    local nGMOnly = 0;
    if StringManager.capitalize(DB.getValue(nodeItemEffect, 'visibility', '')) == Interface.getString('item_label_effects_hide') then
        nGMOnly = 1;
    elseif not bIdentified then
        nGMOnly = 1;
    end

    if not ActorManager.isPC(nodeChar) then
        if DB.getValue(nodeChar, 'tokenvis') ~= 1 then
            nGMOnly = 1; -- hide if token not visible
        end
    end

    rEffect.nDuration = nRollDuration;
    if DB.getValue(nodeItemEffect, 'type', '') ~= 'label' then
        rEffect.sName = sName .. ';' .. sLabel;
    else
        rEffect.sName = sLabel;
    end
    rEffect.sLabel = sLabel;
    rEffect.sUnits = DB.getValue(nodeItemEffect, 'durunit', '');
    rEffect.nInit = 0;
    rEffect.sSource = sItemSource;
    rEffect.nGMOnly = nGMOnly;
    rEffect.sApply = DB.getValue(nodeItemEffect, 'apply', '');
    rEffect.sChangeState = DB.getValue(nodeItemEffect, 'changestate', '');
    rEffect.sName = EffectManagerAE.evalEffect(nodeChar, rEffect.sLabel); -- handle (N)PC Effects

    AdvancedEffects.sendEffectAddedMessage(nodeChar, rEffect, sLabel, nGMOnly);
    EffectManager.addEffect('', '', nodeChar, rEffect, false);
end

function resolveActor(nodeItem)
    local nodeChar = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(nodeItem, '...')));
    if nodeChar then
        -- not NPC not charsheet
        AdvancedEffects.updateItemEffects(nodeChar, nodeItem);
    else
        -- Effect on char sheet or CT npc sheet
        nodeChar = ActorManager.getCTNode(ActorManager.resolveActor((nodeItem)));
        if nodeChar then
            AdvancedEffects.updateItemEffects(nodeChar, nodeItem);
        end
    end
end

function updateItemEffects(nodeChar, nodeItem)

    local bEquipped = not DB.getPath(nodeItem):match('inventorylist') or DB.getValue(nodeItem, 'carried', 1) == 2;
    local bID = not DB.getPath(nodeItem):match('inventorylist') or DB.getValue(nodeItem, 'isidentified', 1) == 1;

    for _, nodeItemEffect in ipairs(DB.getChildList(nodeItem, 'effectlist')) do
        AdvancedEffects.updateItemEffect(nodeItemEffect, DB.getValue(nodeItem, 'name', ''), nodeChar, bEquipped, bID);
    end

    return true;
end
