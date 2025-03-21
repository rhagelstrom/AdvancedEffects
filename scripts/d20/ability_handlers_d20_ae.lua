--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
--
-- Effects on Abilities, apply to character in CT
--
---	This function removes existing effects and re-parses them.
--	First it finds any effects that have this ability as the source and removes those effects.
--	Then it calls updateAbilityEffects to re-parse the current/correct effects.
--
-- luacheck: globals AdvancedEffects replaceAbilityEffects addAbilityEffect updateAbilityEffectsForEdit checkEffectsAfterDelete
-- luacheck: globals updateFromDeletedAbility removeEffectOnAbilityEffectDelete onInit onClose
function onInit()
    if not Session.IsHost then
        return;
    end
    local tNodes = {'specialabilitylist', 'featlist', 'featurelist', 'proficiencylist', 'traitlist'};
    for _, sName in ipairs(tNodes) do
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist', 'onChildAdded', addAbilityEffect);
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler('charsheet.*.' .. sName .. '.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
        DB.addHandler('charsheet.*.' .. sName .. '', 'onChildDeleted', updateFromDeletedAbility);
    end
    tNodes = {'charsheet', 'combattracker.list'};
    for _, sName in ipairs(tNodes) do
        DB.addHandler(sName .. '.*.effectlist', 'onChildAdded', addAbilityEffect);
        DB.addHandler(sName .. '.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler(sName .. '.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler(sName .. '.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler(sName .. '.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler(sName .. '.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler(sName .. '.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler(sName .. '.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
        DB.addHandler(sName .. '.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
    end
end

function onClose()
    if not Session.IsHost then
        return;
    end
    local tNodes = {'specialabilitylist', 'featlist', 'featurelist', 'proficiencylist', 'traitlist'};
    for _, sName in ipairs(tNodes) do
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist', 'onChildAdded', addAbilityEffect);
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler('charsheet.*.' .. sName .. '.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
        DB.removeHandler('charsheet.*.' .. sName .. '', 'onChildDeleted', updateFromDeletedAbility);
    end
    tNodes = {'charsheet', 'combattracker.list'};
    for _, sName in ipairs(tNodes) do
        DB.removeHandler(sName .. '.*.effectlist', 'onChildAdded', addAbilityEffect);
        DB.removeHandler(sName .. '.*.effectlist.*.effect', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler(sName .. '.*.effectlist.*.durdice', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler(sName .. '.*.effectlist.*.durmod', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler(sName .. '.*.effectlist.*.name', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler(sName .. '.*.effectlist.*.durunit', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler(sName .. '.*.effectlist.*.visibility', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler(sName .. '.*.effectlist.*.actiononly', 'onUpdate', updateAbilityEffectsForEdit);
        DB.removeHandler(sName .. '.*.effectlist', 'onChildDeleted', removeEffectOnAbilityEffectDelete);
    end
end

function replaceAbilityEffects(nodeAbility)
    local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(nodeAbility, '...')));
    if not nodeCT then
        nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodeAbility));
        if not nodeCT then
            return;
        end
    end
    local bFound;
    for _, nodeEffect in ipairs(DB.getChildList(nodeCT, 'effects')) do
        local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
        -- see if the node exists and if it's in an effectlist
        local nodeAbilitySource = DB.findNode(sEffSource);
        if nodeAbilitySource and string.match(sEffSource, 'effectlist') then
            if DB.getChild(nodeAbilitySource, '...') == nodeAbility then
                DB.deleteNode(nodeEffect); -- remove existing effect
                bFound = true;
                AdvancedEffects.resolveActor(nodeAbility);
            end
        end
    end
    return bFound;
end

function addAbilityEffect(node)
    local nodeAbility = DB.getParent(node);
    if nodeAbility then
        AdvancedEffects.resolveActor(nodeAbility);
    end
end

--	This function changes the associated effects when ability effect lists are changed.
function updateAbilityEffectsForEdit(node)
    local nodeAbility = DB.getChild(node, '....');
    if nodeAbility and not replaceAbilityEffects(nodeAbility) then
        AdvancedEffects.resolveActor(nodeAbility);
    end
end

---	This function checks to see if an effect is missing its associated ability.
--	If an associated ability isn't found, it removes the effect as the ability has been removed
function checkEffectsAfterDelete(nodeChar)
    local sUser = User.getUsername();
    for _, nodeEffect in ipairs(DB.getChildList(nodeChar, 'effects')) do
        local sLabel = DB.getValue(nodeEffect, 'label', '');
        local sEffSource = DB.getValue(nodeEffect, 'source_name', '');
        -- see if the node exists and if it's in an effectlist
        local bDeleted = (not DB.findNode(sEffSource) and string.match(sEffSource, 'effectlist'));
        if bDeleted then
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

---	This function checks to see if an effect is missing its associated ability.
--	If an associated ability isn't found, it removes the effect as the ability has been removed
function updateFromDeletedAbility(node)
    local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getParent(node)));
    if nodeCT then
        checkEffectsAfterDelete(nodeCT);
    end
end

---	Triggers after an effect on an ability is deleted, causing a recheck of the effects in the combat tracker
function removeEffectOnAbilityEffectDelete(node)
    local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(node, '....')));
    if not nodeCT then
        nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(node, '..')));
    end
    if nodeCT then
        checkEffectsAfterDelete(nodeCT);
    end
end
