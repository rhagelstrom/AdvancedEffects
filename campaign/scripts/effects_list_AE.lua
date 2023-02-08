--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onDrop
function onDrop(x, y, draginfo, ...)
	if super and super.onDrop then super.onDrop(x, y, draginfo, ...) end
	if draginfo.getType() == 'effect' then
		local nodeAdvEffect = DB.createChild(DB.getChild(window.getDatabaseNode(), 'effectlist'))
		local rEffect = EffectManager.decodeEffectFromText(draginfo.getStringData(), draginfo.getSecret())
		DB.setValue(nodeAdvEffect, 'effect', 'string', rEffect.sName)
		DB.setValue(nodeAdvEffect, 'durmod', 'number', draginfo.getNumberData())
		if rEffect.sUnits then DB.setValue(nodeAdvEffect, 'durunit', 'string', rEffect.sUnits) end
		if rEffect.nGMOnly == 1 then DB.setValue(nodeAdvEffect, 'visibility', 'string', 'hide') end
	end
end
