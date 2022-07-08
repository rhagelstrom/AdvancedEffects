--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onButtonPress onDragStart
function onButtonPress()
	local w = Interface.openWindow("advanced_effect_editor", window.getDatabaseNode());
	w.main.subwindow.name.setValue(DB.getValue(window.getDatabaseNode(), "...name", ""));
end
function onDragStart()
	local nodeAdvEffect = window.getDatabaseNode();

	local rEffect = {};
	rEffect.sSource = DB.getValue(nodeAdvEffect, 'name', '');
	rEffect.sUnits = DB.getValue(nodeAdvEffect, 'durunit');
	rEffect.sName = DB.getValue(nodeAdvEffect, 'effect', '');
	if DB.getValue(nodeAdvEffect, 'visibility') == 'hide' then
		rEffect.nGMOnly = 1
	end

	draginfo.setType('effect')
	draginfo.setNumberData(DB.getValue(nodeAdvEffect, 'durmod', 0));
	draginfo.setStringData(EffectManager.encodeEffectAsText(rEffect));
	draginfo.setDescription(draginfo.getStringData());

	return ActionEffect.performRoll(draginfo, nil, rEffect);
end
