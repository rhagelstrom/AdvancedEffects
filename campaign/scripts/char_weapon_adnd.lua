--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onAttackAction onDamageAction
-- luacheck: globals advancedEffectsPiece
-- add itemPath to rActor so that when effects are checked we can
-- make compare against action only effects
function advancedEffectsPiece(nodeWeapon)
    local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '');
    return sRecord;
end

function onAttackAction(draginfo)
    local nodeWeapon = getDatabaseNode();
    local nodeChar = DB.getChild(nodeWeapon, '...')
    local rAction = CharWeaponManager.buildAttackAction(nodeChar, nodeWeapon);
    local rActor = ActorManager.resolveActor(nodeChar);

    if rAction.range == 'R' then
        CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);
    end

    rActor.itemPath = advancedEffectsPiece(nodeWeapon);
    if AmmunitionManager then
        local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);
        if nodeAmmo then
            rActor.ammoPath = DB.getPath(nodeAmmo);
        end
    end
    if not AmmunitionManager then
        ActionAttack.performRoll(draginfo, rActor, rAction);
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
                ActionAttack.performRoll(draginfo, rActor, rAction);
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
end

function onDamageAction(draginfo)
    local nodeWeapon = getDatabaseNode();
    local nodeChar = DB.getChild(nodeWeapon, '...')
    local rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon);
    local rActor = ActorManager.resolveActor(nodeChar);

    rActor.itemPath = advancedEffectsPiece(nodeWeapon);

    if AmmunitionManager then
        local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);
        if nodeAmmo then
            rActor.ammoPath = DB.getPath(nodeAmmo);
        end
    end

    ActionDamage.performRoll(draginfo, rActor, rAction);
    return true;
end
