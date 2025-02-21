--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose customApplyAttack

local applyAttack = nil;

function onInit()
    applyAttack = ActionAttack.applyAttack;
    ActionAttack.applyAttack = customApplyAttack;
end

function onClose()
    ActionAttack.applyAttack = applyAttack;
end

function customApplyAttack(rSource, rTarget, rRoll)
    if rSource and rRoll then
        rSource.itemPath = rRoll.itemPath;
        rSource.ammoPath = rRoll.ammoPath;
    end
    applyAttack(rSource, rTarget, rRoll);
end
