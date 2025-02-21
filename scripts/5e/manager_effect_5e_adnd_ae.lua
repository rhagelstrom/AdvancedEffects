--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals isValidCheckEffect
-- Support for Legacy calls DEPRECATED
function isValidCheckEffect(rActor, v)
    return AdvancedEffects.isValidCheckEffect(rActor, v);
end