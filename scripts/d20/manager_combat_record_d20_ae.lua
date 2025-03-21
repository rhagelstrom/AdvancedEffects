--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals AdvancedEffects onInit onClose customAddPC customAddNPC
local addPC = nil;
local addNPC = nil;

function onInit()
    addPC = CombatRecordManager.addPC;
    addNPC = CombatRecordManager.addNPC;
    CombatRecordManager.addPC = customAddPC;
    CombatRecordManager.addNPC = customAddNPC;
end

function onClose()
    CombatRecordManager.addPC = addPC;
    CombatRecordManager.addNPC = addNPC;
end

-- This function calls the original addPC function.
-- Then it looks through the character's inventory for carried items with attached effects.
-- While effects are checked for item carried status in the updateItemEffect function,
-- the items are first checked here to reduce excess calculations (since the check in updateItemEffect
-- is to facilitate deletion of effects that are no longer applicable).
-- Lastly it looks through the character's attached effects and adds those.
function customAddPC(tCustom, ...)
    addPC(tCustom, ...); -- Call original function

    -- check each inventory item for effects that need to be applied
    for _, nodeItem in ipairs(DB.getChildList(tCustom['nodeRecord'], 'inventorylist')) do
        if DB.getValue(nodeItem, 'carried') == 2 then
            AdvancedEffects.resolveActor(nodeItem);
        end
    end

    -- check each special ability for effects that need to be applied
    local tFields = {'specialabilitylist', 'featlist', 'proficiencylist', 'traitlist'};
    for _, fieldName in pairs(tFields) do
        for _, nodeAbility in ipairs(DB.getChildList(tCustom['nodeRecord'], fieldName)) do
            AdvancedEffects.resolveActor(nodeAbility);
        end
    end

    -- check for and apply character effects
    AdvancedEffects.updateCharEffects(tCustom['nodeRecord'], tCustom['nodeCT']);
end

function customAddNPC(tCustom, ...)
    addNPC(tCustom, ...); -- Call original function

    AdvancedEffects.updateCharEffects(tCustom['nodeRecord'], tCustom['nodeCT']);
end
