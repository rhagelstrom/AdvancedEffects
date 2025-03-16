--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals  advancedEffectsPiece onAttackAction onDamageAction
-- luacheck: globals onSingleAttackAction onFullAttackAction addAttackItems

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
