-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDamageChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")
	local rActor = ActorManager.resolveActor(nodeChar);

	-- ADDITION FOR ADVANCED EFFECTS
	local sBaseAbility = "strength";
	if type.getValue() == 1 then
		sBaseAbility = "dexterity";
	end
	-- END ADDITION FOR ADVANCED EFFECTS
	
	local aDamage = {};
	local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "damagelist"));
	for _,v in ipairs(aDamageNodes) do
		local aDice = DB.getValue(v, "dice", {});
		local nMod = DB.getValue(v, "bonus", 0);
		local sAbility = DB.getValue(v, "stat", "");

		-- ADDITION FOR ADVANCED EFFECTS
		if sAbility == "base" then
			sAbility = sBaseAbility;
		end
		-- END ADDITION FOR ADVANCED EFFECTS

		if sAbility ~= "" then
			local nAbilityBonus = ActorManager35E.getAbilityBonus(rActor, sAbility);
			local nMult = DB.getValue(v, "statmult", 1);
			if nAbilityBonus > 0 and nMult ~= 1 then
				nAbilityBonus = math.floor(nMult * nAbilityBonus);
			end
			nMod = nMod + nAbilityBonus;
		end
		
		if #aDice > 0 or nMod ~= 0 then
			local sDamage = DiceManager.convertDiceToString(DB.getValue(v, "dice", {}), nMod);
			local sType = DB.getValue(v, "type", "");
			if sType ~= "" then
				sDamage = sDamage .. " " .. sType;
			end
			table.insert(aDamage, sDamage);
		end
	end

	damageview.setValue(table.concat(aDamage, "\n+ "));
end