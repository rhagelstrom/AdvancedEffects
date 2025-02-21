--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose moddedHandleApplyDamage moddedNotifyApplyDamage
local handleApplyDamage = nil;
local notifyApplyDamage = nil;

function onInit()
    if not CombatManagerKel then
        handleApplyDamage = ActionDamage.handleApplyDamage;
        notifyApplyDamage = ActionDamage.notifyApplyDamage;

        ActionDamage.handleApplyDamage = moddedHandleApplyDamage;
        ActionDamage.notifyApplyDamage = moddedNotifyApplyDamage;

        OOBManager.registerOOBMsgHandler(ActionDamage.OOB_MSGTYPE_APPLYDMG, moddedHandleApplyDamage);
    end
end

function onClose()
    if not CombatManagerKel then
        ActionDamage.handleApplyDamage = handleApplyDamage;
        ActionDamage.notifyApplyDamage = notifyApplyDamage;
    end
end

function moddedHandleApplyDamage(msgOOB)
    local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
    local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
    if rTarget then
        rTarget.nOrder = msgOOB.nTargetOrder;
    end
    rSource.itemPath = msgOOB.itemPath;
    rSource.ammoPath = msgOOB.ammoPath;

    local nTotal = tonumber(msgOOB.nTotal) or 0;
    ActionDamage.applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sRollType, msgOOB.sDamage, nTotal);
end

function moddedNotifyApplyDamage(rSource, rTarget, bSecret, sRollType, sDesc, nTotal)
    if not rTarget then
        return;
    end

    local msgOOB = {};
    msgOOB.type = ActionDamage.OOB_MSGTYPE_APPLYDMG;

    if bSecret then
        msgOOB.nSecret = 1;
    else
        msgOOB.nSecret = 0;
    end
    msgOOB.sRollType = sRollType;
    msgOOB.nTotal = nTotal;
    msgOOB.sDamage = sDesc;
    if rSource then
        msgOOB.itemPath = rSource.itemPath;
        msgOOB.ammoPath = rSource.ammoPath;
    end

    msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
    msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
    msgOOB.nTargetOrder = rTarget.nOrder;

    Comm.deliverOOBMessage(msgOOB, '');
end
