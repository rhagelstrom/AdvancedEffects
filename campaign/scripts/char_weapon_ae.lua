--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals ActorManagerAE advancedEffectsPiece onAttackAction onDamageAction onDamageChanged
-- luacheck: globals onSingleAttackAction onFullAttackAction addAttackItems
function onInit()
    -- Set up the effect manager proxy functions for the detected ruleset
    if ActorManager35E then
        ActorManagerAE = ActorManager35E;
    elseif ActorManagerSFRPG then
        ActorManagerAE = ActorManagerSFRPG;
    elseif ActorManager5E then
        ActorManagerAE = ActorManager5E;
    end

    if super and super.onInit then
        super.onInit();
    end
end

function advancedEffectsPiece(nodeWeapon)
    local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '');
    return sRecord;
end

function addAttackItems(rActor, nodeWeapon, draginfo)
    rActor.itemPath = advancedEffectsPiece(nodeWeapon);
    if (draginfo and rActor.itemPath and rActor.itemPath ~= '') then
        draginfo.setMetaData('itemPath', rActor.itemPath);
    end

    if AmmunitionManager then
        local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);
        if nodeAmmo then
            rActor.ammoPath = DB.getPath(nodeAmmo);
        end
        if (draginfo and rActor.ammoPath and rActor.ammoPath ~= '') then
            draginfo.setMetaData('ammoPath', rActor.ammoPath);
        end
    end

    if not AmmunitionManager then
        return true;
    else
        local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon,
                                                                        AmmunitionManager.getAmmoNode(nodeWeapon));
        local messagedata = {text = '', sender = rActor.sName, font = 'emotefont'};

        local nodeAmmoManager = DB.getChild(nodeWeapon, 'ammunitionmanager');
        local bLoading = AmmunitionManager.hasLoadAction(nodeWeapon);
        local bIsLoaded = DB.getValue(nodeAmmoManager, 'isloaded') == 1;
        if not bLoading or bIsLoaded then
            if bInfiniteAmmo or nAmmo > 0 then
                if bLoading then
                    DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0);
                end
                return true;
            end
            messagedata.text = Interface.getString('char_message_atkwithnoammo');
            Comm.deliverChatMessage(messagedata);
            if bLoading then
                DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0);
            end
        else
            local sWeaponName = DB.getValue(nodeWeapon, 'name', 'weapon');
            messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName, true, rActor);
            Comm.deliverChatMessage(messagedata);
        end
    end
    return false;
end

-- PFRPG
function onFullAttackAction(draginfo)
    local nodeWeapon = getDatabaseNode();
    local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);

    local rRolls = {};
    for i = 1, DB.getValue(nodeWeapon, 'attacks', 1) do
        rAttack.modifier = self.calcAttackBonus(i);
        rAttack.order = i;
        table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack));
    end
    if not OptionsManager.isOption('RMMT', 'off') and (#rRolls > 1) then
        for _, v in ipairs(rRolls) do
            v.sDesc = v.sDesc .. ' [FULL]';
        end
    end

    if addAttackItems(rActor, nodeWeapon, draginfo) then
        ActionsManager.performMultiAction(draginfo, rActor, 'attack', rRolls);
        return true;
    else
        return false;
    end
end

-- PFRPG
function onSingleAttackAction(n, draginfo)
    local nodeWeapon = getDatabaseNode();
    local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);
    rAttack.order = n or 1;
    rAttack.modifier = self.calcAttackBonus(n or 1);

    if addAttackItems(rActor, nodeWeapon, draginfo) then
        ActionAttack.performRoll(draginfo, rActor, rAttack);
        return true;
    else
        return false;
    end
end

-- 5E
function onAttackAction(draginfo)
    local nodeWeapon = getDatabaseNode();
    local nodeChar = DB.getChild(nodeWeapon, '...')
    local rAction = CharWeaponManager.buildAttackAction(nodeChar, nodeWeapon);
    local rActor = ActorManager.resolveActor(nodeChar);

    Debug.chat("OnAttackAction")
    if rAction.range == 'R' then
        CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);
    end
    if addAttackItems(rActor, nodeWeapon, draginfo) then
        ActionAttack.performRoll(draginfo, rActor, rAction);
        return true;
    else
        return false;
    end

end

function onDamageAction(draginfo)
    local nodeWeapon = getDatabaseNode();
    local rAction;
    local rActor;
    if User.getRulesetName() == '5E' then
        local nodeChar = DB.getChild(nodeWeapon, '...');
        rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon);
        rActor = ActorManager.resolveActor(nodeChar);
    else
        rActor, rAction = CharManager.getWeaponDamageRollStructures(nodeWeapon);
    end

    rActor.itemPath = advancedEffectsPiece(nodeWeapon);
    if (draginfo and rActor.itemPath and rActor.itemPath ~= '') then
        draginfo.setMetaData('itemPath', rActor.itemPath);
    end

    if AmmunitionManager then
        local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);
        if nodeAmmo then
            rActor.ammoPath = DB.getPath(nodeAmmo);
        end
        if (draginfo and rActor.ammoPath and rActor.ammoPath ~= '') then
            draginfo.setMetaData('ammoPath', rActor.ammoPath);
        end
    end

    ActionDamage.performRoll(draginfo, rActor, rAction);
    return true;
end

function onDamageChanged()
    local nodeWeapon = getDatabaseNode();
    local nodeChar = DB.getChild(nodeWeapon, '...');
    local rActor = ActorManager.resolveActor(nodeChar);

    local aDamage = {};
    local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, 'damagelist'));
    for _, v in ipairs(aDamageNodes) do
        local aDice = DB.getValue(v, 'dice', {});
        local nMod = DB.getValue(v, 'bonus', 0);

        local sAbility = DB.getValue(v, 'stat', '');

        -- ADDITION FOR ADVANCED EFFECTS
        if sAbility == 'base' then
            sAbility = 'strength';
            if DB.getValue(nodeWeapon, 'type') == 1 then
                sAbility = 'dexterity';
            end
        end
        -- END ADDITION FOR ADVANCED EFFECTS

        if sAbility ~= '' then
            local nMult = DB.getValue(v, 'statmult', 1);
            local nMax = DB.getValue(v, 'statmax', 0);
            local nAbilityBonus = ActorManagerAE.getAbilityBonus(rActor, sAbility);
            if nMax > 0 then
                nAbilityBonus = math.min(nAbilityBonus, nMax);
            end
            if nAbilityBonus > 0 and nMult ~= 1 then
                nAbilityBonus = math.floor(nMult * nAbilityBonus);
            end
            nMod = nMod + nAbilityBonus;
        end

        if #aDice > 0 or nMod ~= 0 then
            local sDamage = StringManager.convertDiceToString(DB.getValue(v, 'dice', {}), nMod)
            local sType = DB.getValue(v, 'type', '');
            if sType ~= '' then
                sDamage = sDamage .. ' ' .. sType;
            end
            table.insert(aDamage, sDamage);
        end
    end

    damageview.setValue(table.concat(aDamage, '\n+ '));
end
