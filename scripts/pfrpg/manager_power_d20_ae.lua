--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

-- local performPCPowerAction = nil;

-- function onInit()
--     performPCPowerAction = PowerManager.performPCPowerAction;
-- 	PowerManager.performPCPowerAction = customPerformPCPowerAction;
-- 	Debug.console("************* TEST ************")
-- end

-- function onClose()
--     PowerManager.performPCPowerAction = performPCPowerAction;
-- end

-- function customPerformPCPowerAction(draginfo, rActor, rAction, nodePower)
-- 	Debug.chat("Perform Action", rActor)

-- 	if not rActor or not rAction then
-- 		return false;
-- 	end
--  	-- add itemPath to rActor so that when effects are checked we can
--     -- make compare against action only effects
--     local nodeWeapon = DB.getChild(nodePower, '...');
--     local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '');
--     rActor.itemPath = sRecord;

--     -- bmos adding AmmunitionManager integration
--     if AmmunitionManager then
--         local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor)
--         if nodeAmmo then
--             rActor.ammoPath = DB.getPath(nodeAmmo)
--         end
--         if (draginfo and rActor.ammoPath and rActor.ammoPath ~= '') then
--             draginfo.setMetaData('ammoPath', rActor.ammoPath);
--         end
--     end

--     if (draginfo and rActor.itemPath and rActor.itemPath ~= '') then
--         draginfo.setMetaData('itemPath', rActor.itemPath);
--     end
-- 	return performAction(draginfo, rActor, rAction, nodePower);
-- end
