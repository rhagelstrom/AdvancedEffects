--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onLockModeChanged updateVis  addEntry
function onLockModeChanged(bReadOnly)
    for _, w in ipairs(getWindows()) do
        w.onLockModeChanged(bReadOnly);
    end
    if not Session.IsHost then
        updateVis();
    end
end

function updateVis()
    local listNode = getDatabaseNode()
    local parentNode = DB.getParent(listNode);
    local nID = DB.getValue(parentNode, 'isidentified', 1);
    local bReadOnly = WindowManager.getReadOnlyState(parentNode);
    for _, w in ipairs(getWindows()) do
        local node = w.getDatabaseNode()
        local sVis = StringManager.capitalize(DB.getValue(node, 'visibility', ''));
        if nID == 0 or sVis == Interface.getString('item_label_effects_hide') then
            w.effect_description.setVisible(false);
            w.effectdetail.setVisible(false);
            w.idelete.setVisible(false);
        else
            w.effect_description.setVisible(true);
            w.effectdetail.setVisible(not bReadOnly);
            w.idelete.setVisible(not bReadOnly);
        end
    end
end

function addEntry()
    local w = createWindow();
    w.idelete.setVisible(true);
    return w;
end
