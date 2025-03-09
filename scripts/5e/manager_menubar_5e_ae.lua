--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals MenubarManager5EAE onInit onMenuVersionInit performVersionSwitch
function onInit()

    ToolbarManager.registerButton('version', {
        sType = 'action',
        sIcon = 'button_toolbar_version_legacy',
        sTooltipRes = 'record_tooltip_legacy',
        fnOnInit = MenubarManager5EAE.onMenuVersionInit,
        fnActivate = MenubarManager5EAE.performVersionSwitch
    });

    local tRecords = {
        'background',
        'class',
        'class_specialization',
        'feat',
        'npc',
        'item',
        'itemtemplate',
        'race',
        'race_subrace',
        'skill',
        'spell',
        'vehicle'
    };

    for _, sRecord in ipairs(tRecords) do
        if not LibraryData5E.aRecordOverrides[sRecord].aCustom then
            LibraryData5E.aRecordOverrides[sRecord].aCustom = {};
        end
        if not LibraryData5E.aRecordOverrides[sRecord].aCustom.tWindowMenu then
            LibraryData5E.aRecordOverrides[sRecord].aCustom.tWindowMenu = {};
        end
        if not LibraryData5E.aRecordOverrides[sRecord].aCustom.tWindowMenu['right'] then
            LibraryData5E.aRecordOverrides[sRecord].aCustom.tWindowMenu['right'] = {};
        end
        if sRecord == 'npc' and  not LibraryData5E.aRecordOverrides[sRecord].aCustom.tWindowMenu['left'] then
            LibraryData5E.aRecordOverrides[sRecord].aCustom.tWindowMenu['left']  = {'chat_speak'};
        end
        table.insert(LibraryData5E.aRecordOverrides[sRecord].aCustom.tWindowMenu['right'], 1, 'version');
    end
    LibraryData.overrideRecordTypes(LibraryData5E.aRecordOverrides);
end

function onMenuVersionInit(c)
    local node = WindowManager.getOuterWindowDatabaseNode(c.window);
    local sVersion = DB.getValue(node, 'version', 'Legacy');
    if sVersion == '2024' then
        c.setFrame('windowmenubar_button', 2, 2, 2, 2);
        c.setTooltipText(Interface.getString('record_tooltip_2024'));
    else
        c.setFrame('windowmenubar_button_down', 2, 2, 2, 2);
        c.setTooltipText(Interface.getString('record_tooltip_legacy'));
    end
end

function performVersionSwitch(c)
    local node = WindowManager.getOuterWindowDatabaseNode(c.window);
    local sVersion = DB.getValue(node, 'version', 'Legacy');
    if sVersion == '2024' then
        DB.setValue(node, 'version', 'string', 'Legacy')
        c.setFrame('windowmenubar_button_down', 2, 2, 2, 2);
        c.setTooltipText(Interface.getString('record_tooltip_legacy'));
    else
        DB.setValue(node, 'version', 'string', '2024')
        c.setFrame('windowmenubar_button', 2, 2, 2, 2);
        c.setTooltipText(Interface.getString('record_tooltip_2024'));
    end
end
