--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose moddedGetEffectsByType moddedHasEffectCondition moddedHasEffect moddedCheckConditionalHelper
local checkConditionalHelper = nil;
local getEffectsByType = nil;
local hasEffect = nil;
local hasEffectCondition = nil;

function onInit()
    hasEffect = EffectManager5E.hasEffect;
    hasEffectCondition = EffectManager5E.hasEffectCondition;
    getEffectsByType = EffectManager5E.getEffectsByType;

    EffectManager5E.checkConditionalHelper = moddedCheckConditionalHelper;
    EffectManager5E.getEffectsByType = moddedGetEffectsByType;
    EffectManager5E.hasEffect = moddedHasEffect;
    EffectManager5E.hasEffectCondition = moddedHasEffectCondition;
end

function onClose()
    EffectManager5E.checkConditionalHelper = checkConditionalHelper;
    EffectManager5E.hasEffect = hasEffect;
    EffectManager5E.hasEffectCondition = hasEffectCondition;
    EffectManager5E.getEffectsByType = getEffectsByType;
end

-- luacheck: push ignore 561
function moddedGetEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
    if not rActor then
        return {};
    end
    local results = {};
    -- Set up filters
    local aRangeFilter = {};
    local aOtherFilter = {};
    if aFilter then
        for _, v in pairs(aFilter) do
            if type(v) ~= 'string' then
                table.insert(aOtherFilter, v);
            elseif StringManager.contains(DataCommon.rangetypes, v) then
                table.insert(aRangeFilter, v);
            else
                table.insert(aOtherFilter, v);
            end
        end
    end

    local aEffects;
    if TurboManager then
        aEffects = TurboManager.getMatchedEffects(rActor, sEffectType);
    else
        aEffects = DB.getChildList(ActorManager.getCTNode(rActor), 'effects');
    end
    -- Iterate through effects
    for _, v in ipairs(aEffects) do
        -- Check active
        local nActive = DB.getValue(v, 'isactive', 0);
        if (AdvancedEffects.isValidCheckEffect(rActor, v)) then
            local sLabel = DB.getValue(v, 'label', '');
            local sApply = DB.getValue(v, 'apply', '');

            -- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
            local bTargeted = EffectManager.isTargetedEffect(v);
            if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
                local aEffectComps = EffectManager.parseEffect(sLabel);

                -- Look for type/subtype match
                local nMatch = 0;
                for kEffectComp, sEffectComp in ipairs(aEffectComps) do
                    local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
                    -- Handle conditionals
                    if rEffectComp.type == 'IF' then
                        if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
                            break
                        end
                    elseif rEffectComp.type == 'IFT' then
                        if not rFilterActor then
                            break
                        end
                        if not EffectManager5E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
                            break
                        end
                        bTargeted = true;

                        -- Compare other attributes
                    else
                        -- Strip energy/bonus types for subtype comparison
                        local aEffectRangeFilter = {};
                        local aEffectOtherFilter = {};
                        local j = 1;
                        while rEffectComp.remainder[j] do
                            local s = rEffectComp.remainder[j];
                            if #s > 0 and ((s:sub(1, 1) == '!') or (s:sub(1, 1) == '~')) then
                                s = s:sub(2);
                            end
                            -- luacheck: push ignore 542
                            if StringManager.contains(DataCommon.dmgtypes, s) or s == 'all' or
                                StringManager.contains(DataCommon.bonustypes, s) or
                                StringManager.contains(DataCommon.conditions, s) or
                                StringManager.contains(DataCommon.connectors, s) then
                                -- SKIP
                            elseif StringManager.contains(DataCommon.rangetypes, s) then
                                table.insert(aEffectRangeFilter, s);
                            else
                                table.insert(aEffectOtherFilter, s);
                            end
                            -- luacheck: pop

                            j = j + 1;
                        end

                        -- Check for match
                        local comp_match = false;
                        if rEffectComp.type == sEffectType then

                            -- Check effect targeting
                            if bTargetedOnly and not bTargeted then
                                comp_match = false;
                            else
                                comp_match = true;
                            end

                            -- Check filters
                            if #aEffectRangeFilter > 0 then
                                local bRangeMatch = false;
                                for _, v2 in pairs(aRangeFilter) do
                                    if StringManager.contains(aEffectRangeFilter, v2) then
                                        bRangeMatch = true;
                                        break
                                    end
                                end
                                if not bRangeMatch then
                                    comp_match = false;
                                end
                            end
                            if #aEffectOtherFilter > 0 then
                                local bOtherMatch = false;
                                for _, v2 in pairs(aOtherFilter) do
                                    if type(v2) == 'table' then
                                        local bOtherTableMatch = true;
                                        for _, v3 in pairs(v2) do
                                            if not StringManager.contains(aEffectOtherFilter, v3) then
                                                bOtherTableMatch = false;
                                                break
                                            end
                                        end
                                        if bOtherTableMatch then
                                            bOtherMatch = true;
                                            break
                                        end
                                    elseif StringManager.contains(aEffectOtherFilter, v2) then
                                        bOtherMatch = true;
                                        break
                                    end
                                end
                                if not bOtherMatch then
                                    comp_match = false;
                                end
                            end
                        end

                        -- Match!
                        if comp_match then
                            nMatch = kEffectComp;
                            if nActive == 1 then
                                table.insert(results, rEffectComp);
                            end
                        end
                    end
                end -- END EFFECT COMPONENT LOOP

                -- Remove one shot effects
                if nMatch > 0 then
                    if nActive == 2 then
                        DB.setValue(v, 'isactive', 'number', 1);
                    else
                        if sApply == 'action' then
                            EffectManager.notifyExpire(v, 0);
                        elseif sApply == 'roll' then
                            EffectManager.notifyExpire(v, 0, true);
                        elseif sApply == 'single' then
                            EffectManager.notifyExpire(v, nMatch, true);
                        end
                    end
                end
            end -- END TARGET CHECK
        end -- END ACTIVE CHECK
    end -- END EFFECT LOOP

    -- RESULTS
    return results;
end
-- luacheck: pop

function moddedHasEffectCondition(rActor, sEffect)
    return EffectManager5E.hasEffect(rActor, sEffect, nil, false, true);
end

-- replace 5E EffectManager5E manager_effect_5E.lua hasEffect() with this
function moddedHasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
    if not sEffect or not rActor then
        return false;
    end
    local sLowerEffect = sEffect:lower();

    local aMatch = {};
    local aEffects;
    if TurboManager then
        aEffects = TurboManager.getMatchedEffects(rActor, sEffect);
    else
        aEffects = DB.getChildList(ActorManager.getCTNode(rActor), 'effects');
    end
    -- Iterate through effects
    for _, v in ipairs(aEffects) do
        local nActive = DB.getValue(v, 'isactive', 0);
        if (AdvancedEffects.isValidCheckEffect(rActor, v)) then
            -- Parse each effect label
            local sLabel = DB.getValue(v, 'label', '');
            local bTargeted = EffectManager.isTargetedEffect(v);
            local aEffectComps = EffectManager.parseEffect(sLabel);

            -- Iterate through each effect component looking for a type match
            local nMatch = 0;
            for kEffectComp, sEffectComp in ipairs(aEffectComps) do
                local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
                -- Handle conditionals
                if rEffectComp.type == 'IF' then
                    if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
                        break
                    end
                elseif rEffectComp.type == 'IFT' then
                    if not rTarget then
                        break
                    end
                    if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
                        break
                    end

                    -- Check for match
                elseif rEffectComp.original:lower() == sLowerEffect then
                    if bTargeted and not bIgnoreEffectTargets then
                        if EffectManager.isEffectTarget(v, rTarget) then
                            nMatch = kEffectComp;
                        end
                    elseif not bTargetedOnly then
                        nMatch = kEffectComp;
                    end
                end

            end

            -- If matched, then remove one-off effects
            if nMatch > 0 then
                if nActive == 2 then
                    DB.setValue(v, 'isactive', 'number', 1);
                else
                    table.insert(aMatch, v);
                    local sApply = DB.getValue(v, 'apply', '');
                    if sApply == 'action' then
                        EffectManager.notifyExpire(v, 0);
                    elseif sApply == 'roll' then
                        EffectManager.notifyExpire(v, 0, true);
                    elseif sApply == 'single' then
                        EffectManager.notifyExpire(v, nMatch, true);
                    end
                end
            end
        end
    end

    if #aMatch > 0 then
        return true;
    end
    return false;
end

-- replace 5E EffectManager5E manager_effect_5E.lua moddedCheckConditionalHelper() with this
function moddedCheckConditionalHelper(rActor, sEffect, rTarget, aIgnore)
    if not rActor then
        return false;
    end

    for _, v in ipairs(DB.getChildList(ActorManager.getCTNode(rActor), 'effects')) do
        if (AdvancedEffects.isValidCheckEffect(rActor, v) and not StringManager.contains(aIgnore, v.getNodeName())) then
            -- Parse each effect label
            local sLabel = DB.getValue(v, 'label', '');
            local aEffectComps = EffectManager.parseEffect(sLabel);

            -- Iterate through each effect component looking for a type match
            for _, sEffectComp in ipairs(aEffectComps) do
                local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);

                -- CHECK CONDITIONALS
                if rEffectComp.type == 'IF' then
                    if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
                        break
                    end
                elseif rEffectComp.type == 'IFT' then
                    if not rTarget then
                        break
                    end
                    if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
                        break
                    end

                    -- CHECK FOR AN ACTUAL EFFECT MATCH
                elseif rEffectComp.original:lower() == sEffect then
                    if EffectManager.isTargetedEffect(v) then
                        if EffectManager.isEffectTarget(v, rTarget) then
                            return true;
                        end
                    else
                        return true;
                    end
                end
            end
        end
    end

    return false;
end
