function onInit()
    if super and super.onInit() then
        super.onInit();
    end
    local sPath = DB.getPath(getDatabaseNode());
    DB.addHandler(sPath .. '.locked', 'onUpdate', update);

    header_effects.setVisible(true);
    effects_iedit.setVisible(true);
    effects_list_iadd.setVisible(true);
    effects_list.setVisible(true);
    update()
end

function update()
    if super and super.update() then
        super.update();
    end
    local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

    if bReadOnly then
        effects_iedit.setVisible(false);
        effects_list_iadd.setVisible(false);
        effects_list.update(bReadOnly);

    else
        effects_iedit.setVisible(true);
        effects_list_iadd.setVisible(true);
        effects_list.update(bReadOnly);
    end
end
