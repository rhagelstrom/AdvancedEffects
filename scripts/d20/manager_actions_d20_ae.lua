--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onInit onClose customEncodeActionForDrag customDecodeActors
local decodeActors;
local encodeActionForDrag;

local itemPathKey = 'itemPath';
local ammoPathKey = 'ammoPath';

function onInit()
    decodeActors = ActionsManager.decodeActors;
    encodeActionForDrag = ActionsManager.encodeActionForDrag;
    ActionsManager.decodeActors = customDecodeActors;
    ActionsManager.encodeActionForDrag = customEncodeActionForDrag;
end

function onClose()
    ActionsManager.decodeActors = decodeActors;
    ActionsManager.encodeActionForDrag = encodeActionForDrag;
end

function customEncodeActionForDrag(draginfo, rSource, sType, rRolls, ...)
    encodeActionForDrag(draginfo, rSource, sType, rRolls, ...);

    if not rSource then
        return;
    end
    if rSource.itemPath and rSource.itemPath ~= '' then
        draginfo.setMetaData(itemPathKey, rSource.itemPath);
    end
    if AmmunitionManager and rSource.ammoPath and rSource.ammoPath ~= '' then
        draginfo.setMetaData(ammoPathKey, rSource.ammoPath);
    end
end

function customDecodeActors(draginfo, ...)
    local rSource, aTargets = decodeActors(draginfo, ...);

    local sitemPath = draginfo.getMetaData(itemPathKey);
    if sitemPath and sitemPath ~= '' then
        rSource.itemPath = sitemPath;
    end

    local sammoPath = draginfo.getMetaData(ammoPathKey)
    if AmmunitionManager and (sammoPath and sammoPath ~= '') then
        rSource.ammoPath = sammoPath;
    end

    return rSource, aTargets;
end
