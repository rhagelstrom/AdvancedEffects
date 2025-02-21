--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit moddedGetEffectsByType moddedHasEffect moddedHasEffectCondition
function onInit()
    if not CombatManagerKel then
        EffectManager35E.getEffectsByType = moddedGetEffectsByType;
        EffectManager35E.hasEffect = moddedHasEffect;
        EffectManager35E.hasEffectCondition = moddedHasEffectCondition;
    end
end

function moddedHasEffectCondition(rActor, sEffect)
    return EffectManager35E.hasEffect(rActor, sEffect, nil, false, true);
end

function moddedGetEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly) -- luacheck: ignore (cyclomatic complexity)
    local results = {};
    if not rActor then
        return results;
    end

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
        local nActive = DB.getValue(v, 'isactive', 0);
        -- Check effect is from used weapon.

        if AdvancedEffects.isValidCheckEffect(rActor, v) then
            -- Check targeting
            local bTargeted = EffectManager.isTargetedEffect(v);
            if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
                local sLabel = DB.getValue(v, 'label', '');
                local aEffectComps = EffectManager.parseEffect(sLabel);

                -- Look for type/subtype match
                local nMatch = 0;
                for kEffectComp, sEffectComp in ipairs(aEffectComps) do
                    local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);
                    -- Handle conditionals
                    if rEffectComp.type == 'IF' then
                        if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
                            break
                        end
                    elseif rEffectComp.type == 'IFT' then
                        if not rFilterActor then
                            break
                        end
                        if not EffectManager35E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
                            break
                        end
                        bTargeted = true;

                        -- Compare other attributes
                    else
                        -- Strip energy/bonus types for subtype comparison
                        local aEffectRangeFilter = {};
                        local aEffectOtherFilter = {};

                        local aComponents = {};
                        for _, vPhrase in ipairs(rEffectComp.remainder) do
                            local nTempIndexOR = 0;
                            local aPhraseOR = {};
                            repeat
                                local nStartOR, nEndOR = vPhrase:find('%s+or%s+', nTempIndexOR);
                                if nStartOR then
                                    table.insert(aPhraseOR, vPhrase:sub(nTempIndexOR, nStartOR - nTempIndexOR));
                                    nTempIndexOR = nEndOR;
                                else
                                    table.insert(aPhraseOR, vPhrase:sub(nTempIndexOR));
                                end
                            until nStartOR == nil;

                            for _, vPhraseOR in ipairs(aPhraseOR) do
                                local nTempIndexAND = 0;
                                repeat
                                    local nStartAND, nEndAND = vPhraseOR:find('%s+and%s+', nTempIndexAND);
                                    if nStartAND then
                                        local sInsert =
                                            StringManager.trim(vPhraseOR:sub(nTempIndexAND, nStartAND - nTempIndexAND));
                                        table.insert(aComponents, sInsert);
                                        nTempIndexAND = nEndAND;
                                    else
                                        local sInsert = StringManager.trim(vPhraseOR:sub(nTempIndexAND));
                                        table.insert(aComponents, sInsert);
                                    end
                                until nStartAND == nil;
                            end
                        end
                        local j = 1;
                        while aComponents[j] do
                            if StringManager.contains(DataCommon.dmgtypes, aComponents[j]) or
                                StringManager.contains(DataCommon.bonustypes, aComponents[j]) or aComponents[j] == 'all' then -- luacheck: ignore
                                -- Skip
                            elseif StringManager.contains(DataCommon.rangetypes, aComponents[j]) then
                                table.insert(aEffectRangeFilter, aComponents[j]);
                            else
                                table.insert(aEffectOtherFilter, aComponents[j]);
                            end

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
            end -- END TARGET CHECK
        end -- END ACTIVE CHECK
    end -- END EFFECT LOOP

    return results;
end

--	replace 3.5E EffectManager35E manager_effect_35E.lua hasEffect() with this
function moddedHasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
    if not sEffect or not rActor then
        return false;
    end
    local sLowerEffect = sEffect:lower();

    -- Iterate through each effect
    local aMatch = {};
    local aEffects;
    if TurboManager then
        aEffects = TurboManager.getMatchedEffects(rActor, sEffect);
    else
        aEffects = DB.getChildList(ActorManager.getCTNode(rActor), 'effects');
    end
    for _, v in ipairs(aEffects) do
        local nActive = DB.getValue(v, 'isactive', 0);

        -- COMPATIBILITY FOR ADVANCED EFFECTS
        -- to add support for AE in other extensions, make this change
        -- original line: if nActive ~= 0 then
        if (not AdvancedEffects and nActive ~= 0) or (AdvancedEffects and AdvancedEffects.isValidCheckEffect(rActor, v)) then
            -- END COMPATIBILITY FOR ADVANCED EFFECTS

            -- Parse each effect label
            local sLabel = DB.getValue(v, 'label', '');
            local bTargeted = EffectManager.isTargetedEffect(v);
            local aEffectComps = EffectManager.parseEffect(sLabel);

            -- Iterate through each effect component looking for a type match
            local nMatch = 0;
            for kEffectComp, sEffectComp in ipairs(aEffectComps) do
                local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);
                -- Check conditionals
                if rEffectComp.type == 'IF' then
                    if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
                        break
                    end
                elseif rEffectComp.type == 'IFT' then
                    if not rTarget then
                        break
                    end
                    if not EffectManager35E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
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
                    table.insert(aMatch, v)
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
