--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onButtonPress onDragStart setLockMode getLockMode onEditModeChanged
function onButtonPress()
    if self.isVisible() then
        Interface.openWindow('advanced_effect_editor', window.getDatabaseNode());
    end
    self.onEditModeChanged();
end

function onDragStart(_, _, _, dragdata)

    local nodeAdvEffect = window.getDatabaseNode();

    local rEffect = {}
    rEffect.sSource = DB.getValue(nodeAdvEffect, 'name', '');
    rEffect.sUnits = DB.getValue(nodeAdvEffect, 'durunit');
    rEffect.sName = DB.getValue(nodeAdvEffect, 'effect', '');
    if StringManager.capitalize(DB.getValue(nodeAdvEffect, 'visibility', '')) == Interface.getString('item_label_effects_hide') then
        rEffect.nGMOnly = 1;
    end

    dragdata.setType('effect');
    dragdata.setNumberData(DB.getValue(nodeAdvEffect, 'durmod', 0));
    dragdata.setStringData(EffectManager.encodeEffectAsText(rEffect));
    dragdata.setDescription(dragdata.getStringData());

    return ActionEffect.performRoll(dragdata, nil, rEffect);

end

function setLockMode(bReadOnly)
    setVisible(not bReadOnly);
    if not Session.IsHost then
        local sVis = StringManager.capitalize(DB.getValue(window.getDatabaseNode(), 'visibility', ''));
        if sVis == Interface.getString('item_label_effects_hide') then
            setVisible(false);
        end
    end
end

function getLockMode()
    return not isVisible();
end

function onEditModeChanged()
    if self.editmode then
        setVisible(WindowManager.getEditMode(window, self.editmode[1]));
    end
end
