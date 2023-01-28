--
-- Effects on Items, apply to character in CT
--
---	This function removes existing effects and re-parses them.
--	First it finds any effects that have this item as the source and removes those effects.
--	Then it calls updateItemEffects to re-parse the current/correct effects.
local function replaceItemEffects(nodeItem)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(nodeItem, '...')))
	if not nodeCT or DB.getValue(nodeItem, 'carried') ~= 2 then return end
	for _, nodeEffect in ipairs(DB.getChildList(nodeCT, 'effects')) do
		local sEffSource = DB.getValue(nodeEffect, 'source_name', '')
		-- see if the node exists and if it's in an inventory node
		local nodeItemSource = DB.findNode(sEffSource)
		if nodeItemSource and string.match(sEffSource, 'inventorylist') then
			if DB.getChild(nodeItemSource, '...') == nodeItem then
				DB.deleteNode(nodeEffect) -- remove existing effect
				AdvancedEffects.updateItemEffects(nodeItem)
			end
		end
	end
end

local function inventoryUpdateItemEffects(node)
	local nodeItem = DB.getParent(node)
	if nodeItem then AdvancedEffects.updateItemEffects(nodeItem) end
end

--	This function changes the visibility of effects when items are identified.
local function updateItemEffectsForID(node)
	local nodeItem = DB.getParent(node)
	if nodeItem then replaceItemEffects(nodeItem) end
end

--	This function changes the associated effects when item effect lists are changed while item is equipped.
local function updateItemEffectsForEdit(node)
	local nodeItem = DB.getChild(node, '....')
	if nodeItem then replaceItemEffects(nodeItem) end
end

---	This function checks to see if an effect is missing its associated item.
--	If an associated item isn't found, it removes the effect as the item has been removed
local function checkEffectsAfterDelete(nodeChar)
	local sUser = User.getUsername()
	for _, nodeEffect in ipairs(DB.getChildList(nodeChar, 'effects')) do
		local sLabel = DB.getValue(nodeEffect, 'label', '')
		local sEffSource = DB.getValue(nodeEffect, 'source_name', '')
		-- see if the node exists and if it's in an inventory node
		local bDeleted = (not DB.findNode(sEffSource) and string.match(sEffSource, 'inventorylist'))
		if bDeleted then
			local msg = { font = 'msgfont', icon = 'roll_effect' }
			msg.text = "Effect ['" .. sLabel .. "'] "
			msg.text = msg.text .. 'removed [from ' .. DB.getValue(nodeChar, 'name', '') .. ']'
			-- HANDLE APPLIED BY SETTING
			if sEffSource and sEffSource ~= '' then msg.text = msg.text .. ' [by Deletion]' end
			if EffectManager.isGMEffect(nodeChar, nodeEffect) then
				if sUser == '' then
					msg.secret = true
					Comm.addChatMessage(msg)
				elseif sUser ~= '' then
					Comm.addChatMessage(msg)
					Comm.deliverChatMessage(msg, sUser)
				end
			else
				Comm.deliverChatMessage(msg)
			end
			DB.deleteNode(nodeEffect)
		end
	end
end

---	This function checks to see if an effect is missing its associated item.
--	If an associated item isn't found, it removes the effect as the item has been removed
local function updateFromDeletedInventory(node)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getParent(node)))
	if nodeCT then checkEffectsAfterDelete(nodeCT) end
end

---	Triggers after an effect on an item is deleted, causing a recheck of the effects in the combat tracker
local function removeEffectOnItemEffectDelete(node)
	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(DB.getChild(node, '....')))
	if nodeCT then checkEffectsAfterDelete(nodeCT) end
end

function onInit()
	if not Session.IsHost then return end
	-- watch the character/pc inventory list(s)
	for _, sItemListNodeName in pairs(ItemManager.getInventoryPaths('charsheet')) do
		local sItemList = 'charsheet.*.' .. sItemListNodeName
		DB.addHandler(sItemList .. '.*.carried', 'onUpdate', inventoryUpdateItemEffects)
		DB.addHandler(sItemList .. '.*.isidentified', 'onUpdate', updateItemEffectsForID)
		DB.addHandler(sItemList .. '.*.effectlist.*.effect', 'onUpdate', updateItemEffectsForEdit)
		DB.addHandler(sItemList .. '.*.effectlist.*.durdice', 'onUpdate', updateItemEffectsForEdit)
		DB.addHandler(sItemList .. '.*.effectlist.*.durmod', 'onUpdate', updateItemEffectsForEdit)
		DB.addHandler(sItemList .. '.*.effectlist.*.name', 'onUpdate', updateItemEffectsForEdit)
		DB.addHandler(sItemList .. '.*.effectlist.*.durunit', 'onUpdate', updateItemEffectsForEdit)
		DB.addHandler(sItemList .. '.*.effectlist.*.visibility', 'onUpdate', updateItemEffectsForEdit)
		DB.addHandler(sItemList .. '.*.effectlist.*.actiononly', 'onUpdate', updateItemEffectsForEdit)
		DB.addHandler(sItemList .. '.*.effectlist', 'onChildDeleted', removeEffectOnItemEffectDelete)
		DB.addHandler(sItemList .. '', 'onChildDeleted', updateFromDeletedInventory)
	end
end
