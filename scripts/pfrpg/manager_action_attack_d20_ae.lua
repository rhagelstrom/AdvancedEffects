--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- local performRoll = nil;
-- luacheck: globals onInit onClose moddedPerformRoll
function onInit()
    -- performRoll = ActionAttack.performRoll
    -- ActionAttack.performRoll = moddedPerformRoll;
end

function onClose()
    -- ActionAttack.performRoll = performRoll;
end

function moddedPerformRoll(draginfo, rActor, rAction)
    local rRoll = ActionAttack.getRoll(rActor, rAction);

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
