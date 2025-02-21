--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose updateVis onLockModeChanged onDrop
function onInit()
    if super and super.onInit then
        super.onInit();
    end
    local nodePath = DB.getPath(getDatabaseNode());
    DB.addHandler(nodePath .. '.locked', 'onUpdate', onLockModeChanged);
    if not Session.IsHost then
        DB.addHandler(nodePath .. '.isidentified', 'onUpdate', updateVis);
    end
    onLockModeChanged();
end

function onClose()
    if super and super.onClose then
        super.ononCloseInit();
    end
    local nodePath = DB.getPath(getDatabaseNode());
    DB.removeHandler(nodePath ..'.locked', 'onUpdate', onLockModeChanged);
    if not Session.IsHost then
        DB.removeHandler(nodePath .. '.isidentified', 'onUpdate', updateVis);
    end
end

function updateVis()
    local node = getDatabaseNode();
    local nID = DB.getValue(node, 'isidentified', 1);

    local bReadOnly = WindowManager.getReadOnlyState(node);
    if not bReadOnly then
        if nID == 1 then
            WindowManager.callSafeControlsSetLockMode(self, {'effects_list_iadd'}, false);
        else
            WindowManager.callSafeControlsSetLockMode(self, {'effects_list_iadd'}, true);
        end
    end
    self.effects_list.updateVis()

end

function onLockModeChanged()
    local nodeRecord = getDatabaseNode();
    local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
    WindowManager.callSafeControlsSetLockMode(self, {'effects_list_iadd'}, bReadOnly);
    self.effects_list.onLockModeChanged(bReadOnly);
end

function onDrop(_, _, draginfo)
    if not effects_list_iadd.getLockMode() and draginfo.getType() == 'effect' then
        local nodeAdvEffect = DB.createChild(DB.getChild(getDatabaseNode(), 'effectlist'));
        local rEffect = EffectManager.decodeEffectFromText(draginfo.getStringData(), draginfo.getSecret());
        DB.setValue(nodeAdvEffect, 'effect', 'string', rEffect.sName);
        DB.setValue(nodeAdvEffect, 'durmod', 'number', draginfo.getNumberData());
        if rEffect.sUnits then
            DB.setValue(nodeAdvEffect, 'durunit', 'string', rEffect.sUnits);
        end
        if rEffect.nGMOnly == 1 then
            DB.setValue(nodeAdvEffect, 'visibility', 'string', Interface.getString('item_label_effects_hide'));
        end
        if rEffect.sChangeState then
            DB.setValue(nodeAdvEffect, 'changestate', 'string' ,rEffect.sChangeState);
        end
    end
end
