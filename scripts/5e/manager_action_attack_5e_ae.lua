--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose customOnAttack
local onAttack = nil;

function onInit()
    onAttack = ActionAttack.onAttack;
    ActionAttack.onAttack = customOnAttack;
    ActionsManager.registerResultHandler('attack', customOnAttack);
end

function onClose()
    ActionAttack.onAttack = onAttack;
end

function customOnAttack(rSource, rTarget, rRoll)
    if rSource and rRoll then
        rSource.itemPath = rRoll.itemPath;
        rSource.ammoPath = rRoll.ammoPath;
    end
    onAttack(rSource, rTarget, rRoll);
end
