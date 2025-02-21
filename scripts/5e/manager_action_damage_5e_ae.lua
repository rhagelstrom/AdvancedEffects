--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose customApplyDamage
local applyDamage = nil;
function onInit()
    applyDamage = ActionDamage.applyDamage;
    ActionDamage.applyDamage = customApplyDamage;
end

function onClose()
    ActionDamage.applyDamage = applyDamage;
end

function customApplyDamage(rSource, rTarget, rRoll)
    if rSource and rRoll then
        rSource.itemPath = rRoll.itemPath;
        rSource.ammoPath = rRoll.ammoPath;
    end
    applyDamage(rSource, rTarget, rRoll);
end
