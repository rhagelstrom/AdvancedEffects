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
function onFilter(w)
    if not Session.IsHost then
        local node = w.getDatabaseNode();
        local parentNode = DB.getChild(node, '...');
        local nID = DB.getValue(parentNode, 'isidentified', 1);
        return not (nID == 0 or StringManager.capitalize(DB.getValue(node, 'visibility', '')) ==  Interface.getString('item_label_effects_hide'));
    else
        return true;
    end
end

function updateVis()
    applyFilter(true);
end

function addEntry()
    local w = createWindow();
    w.idelete.setVisible(true);
    return w;
end
