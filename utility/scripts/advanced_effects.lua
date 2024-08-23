--
-- handles advanced effects
--
--
-- luacheck: globals onInit onClose update effectdetail
-- luacheck: globals node effect_description
function onInit()
    if super and super.onInit then
        super.onInit();
    end
    local node = getDatabaseNode();
    local nodeItem = DB.getChild(node, '...');
    -- set name of effect to name of item so when effect
    -- is applied to someone it shows where it came from properly
    local sName = DB.getValue(nodeItem, 'name', '');
    name.setValue(sName);

    -- DB.addHandler(DB.getPath(node),"onChildUpdate", update);
    -- watch these variables and update display string if they change
    DB.addHandler(DB.getPath(node, 'effect'), 'onUpdate', update);
    DB.addHandler(DB.getPath(node, 'durdice'), 'onUpdate', update);
    DB.addHandler(DB.getPath(node, 'durmod'), 'onUpdate', update);
    DB.addHandler(DB.getPath(node, 'durunit'), 'onUpdate', update);
    DB.addHandler(DB.getPath(node, 'visibility'), 'onUpdate', update);
    DB.addHandler(DB.getPath(node, 'actiononly'), 'onUpdate', update);
    DB.addHandler(DB.getPath(nodeItem, 'locked'), 'onUpdate', update);
    update();
end

function onClose()
    local node = getDatabaseNode();
    local nodeItem = DB.getChild(node, '...');
    -- DB.removeHandler(DB.getPath(node),"onChildUpdate", update);
    DB.removeHandler(DB.getPath(node, 'effect'), 'onUpdate', update);
    DB.removeHandler(DB.getPath(node, 'durdice'), 'onUpdate', update);
    DB.removeHandler(DB.getPath(node, 'durmod'), 'onUpdate', update);
    DB.removeHandler(DB.getPath(node, 'durunit'), 'onUpdate', update);
    DB.removeHandler(DB.getPath(node, 'visibility'), 'onUpdate', update);
    DB.removeHandler(DB.getPath(node, 'actiononly'), 'onUpdate', update);
    DB.removeHandler(DB.getPath(nodeItem, 'locked'), 'onUpdate', update);
end

-- update display string
function update()

    if super and super.update then
        super.update();
    end
    local node = getDatabaseNode();
    local nodeItem = DB.getChild(node, '...');
    local bReadOnly = DB.getValue(nodeItem, 'locked', 0);

    -- display dice/mods for duration --celestian
    local sDuration = '';
    local dDurationDice = DB.getValue(node, 'durdice');
    local nDurationMod = DB.getValue(node, 'durmod', 0);
    local sDurDice = StringManager.convertDiceToString(dDurationDice);
    if (sDurDice ~= '') then
        sDuration = sDuration .. sDurDice;
    end
    if (nDurationMod ~= 0 and sDurDice ~= '') then
        local sSign = '+';
        if (nDurationMod < 0) then
            sSign = '';
        end
        sDuration = sDuration .. sSign .. nDurationMod;
    elseif (nDurationMod ~= 0) then
        sDuration = sDuration .. nDurationMod;
    end

    local sUnits = DB.getValue(node, 'durunit', '');
    if sDuration ~= '' then
        local bMultiple = (sDurDice ~= '') or (nDurationMod > 1);
        if sUnits == 'minute' then
            sDuration = sDuration .. ' minute'; -- 5e uses minutes, not turns!
        elseif sUnits == 'hour' then
            sDuration = sDuration .. ' hour';
        elseif sUnits == 'day' then
            sDuration = sDuration .. ' day';
        else
            sDuration = sDuration .. ' rnd';
        end
        if (bMultiple) then
            sDuration = sDuration .. 's';
        end
    end
    local sActionOnly = '[ActionOnly]';
    local bActionOnly = (DB.getValue(node, 'actiononly', 0) ~= 0);
    if (not bActionOnly) then
        sActionOnly = '';
    end
    local sEffect = DB.getValue(node, 'effect', '');
    local sVis = DB.getValue(node, 'visibility', '');
    local sVisible = sVis;
    if (sVis ~= '') then
        sVis = ' visibility [' .. sVis .. ']';
    end
    if (sDuration ~= '') then
        sDuration = ' for [' .. sDuration .. ']';
    end
    local sFinal = '[' .. sEffect .. ']' .. sDuration .. sVis .. sActionOnly;
    effect_description.setValue(sFinal);

    if not Session.IsHost then
        if sVisible == 'hide' then
            effect_description.setVisible(false);
            effectdetail.setVisible(false);
        elseif sVisible == 'show' then
            effect_description.setVisible(true);
            effectdetail.update();
        elseif sVisible == '' and bReadOnly == 1 then
            effect_description.setVisible(false);
            effectdetail.setVisible(false);
        else
            effect_description.setVisible(true);
            effectdetail.update();
        end
    end

end
