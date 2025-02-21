--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose customApplyDamage applyDamage
local applyDamageOriginal = nil;

function onInit()
    applyDamageOriginal = ActionDamage.applyDamage;
    ActionDamage.applyDamage = customApplyDamage;
end

function onClose()
    ActionDamage.applyDamage = applyDamageOriginal;
end

function customApplyDamage(rSource, rTarget, bSecret, sRollType, sDamage, nTotal, ...)
    local rRoll = {};
    rRoll.sType = sRollType;
    rRoll.sDesc = sDamage;
    rRoll.nTotal = nTotal;
    rRoll.bSecret = bSecret;
    ActionDamageDnDBCE.applyDamageBCE(rSource, rTarget, rRoll, ...);
end

function applyDamage(rSource, rTarget, rRoll, ...)
    applyDamageOriginal(rSource, rTarget, rRoll.bSecret, rRoll.sType, rRoll.sDesc, rRoll.nTotal, ...);
end