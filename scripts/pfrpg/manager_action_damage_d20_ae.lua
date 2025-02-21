--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose moddedPerformRoll
-- local performRoll = nil;
-- local notifyApplyDamage = nil;
-- local handleApplyDamage = nil;

function onInit()
    -- performRoll = ActionDamage.performRoll;
    -- notifyApplyDamage = ActionDamage.notifyApplyDamage;
    -- handleApplyDamage = ActionDamage.handleApplyDamage;
    -- ActionDamage.performRoll = moddedPerformRoll;

    -- if not CombatManagerKel then
    --     ActionDamage.notifyApplyDamage = moddedNotifyApplyDamage
    --     ActionDamage.handleApplyDamage = moddedHandleApplyDamage
    --     OOBManager.registerOOBMsgHandler(ActionDamage.OOB_MSGTYPE_APPLYDMG, moddedHandleApplyDamage)
    -- end
end

function onClose()
    -- ActionDamage.performRoll = performRoll;
    -- ActionDamage.notifyApplyDamage = notifyApplyDamage;
    -- ActionDamage.handleApplyDamage = handleApplyDamage;

end

function moddedPerformRoll(draginfo, rActor, rAction)
    local rRoll = ActionDamage.getRoll(rActor, rAction);

    if rActor.itemPath and rActor.itemPath ~= '' then
        rRoll.itemPath = rActor.itemPath
        if draginfo then
            draginfo.setMetaData('itemPath', rActor.itemPath);
        end
    end
    if AmmunitionManager and rActor.ammoPath and rActor.ammoPath ~= '' then
        rRoll.ammoPath = rActor.ammoPath
        if draginfo then
            draginfo.setMetaData('ammoPath', rActor.ammoPath);
        end
    end

    ActionsManager.performAction(draginfo, rActor, rRoll);
end
