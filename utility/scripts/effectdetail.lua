--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onButtonPress onDragStart
function onButtonPress()
	local w = Interface.openWindow("advanced_effect_editor", window.getDatabaseNode())
	w.main.subwindow.name.setValue(DB.getValue(window.getDatabaseNode(), "...name", ""))
end
function onDragStart(_, _, _, dragdata)
	local nodeAdvEffect = window.getDatabaseNode()

	local rEffect = {}
	rEffect.sSource = DB.getValue(nodeAdvEffect, "name", "")
	rEffect.sUnits = DB.getValue(nodeAdvEffect, "durunit")
	rEffect.sName = DB.getValue(nodeAdvEffect, "effect", "")
	if DB.getValue(nodeAdvEffect, "visibility") == "hide" then
		rEffect.nGMOnly = 1
	end

	dragdata.setType("effect")
	dragdata.setNumberData(DB.getValue(nodeAdvEffect, "durmod", 0))
	dragdata.setStringData(EffectManager.encodeEffectAsText(rEffect))
	dragdata.setDescription(dragdata.getStringData())

	return ActionEffect.performRoll(dragdata, nil, rEffect)
end
