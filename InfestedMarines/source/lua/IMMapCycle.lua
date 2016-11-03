-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
--    lua\IMMapCycle.lua
--
--    Created by:   Sebastian Schuck
--
--    Overload some map functions to adept to the maploading pattern
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local oldGetMapName = Shared.GetMapName
local cachedMapName --cache the changed mapname to avoid extra string operations
local heighMapLoaded
function Shared.GetMapName(returnOld)
    local oldMapName = oldGetMapName()

    -- for minimap background
    if returnOld then
        return oldMapName
    end

    -- for heightmap
    if gHeightMap and not heighMapLoaded then
        heighMapLoaded = true
        return oldMapName
    end

    if cachedMapName then return cachedMapName end

    local mapName = string.gsub(oldMapName, "ns2_", "infest_")

    --Check for map in mapcycle if this is the server VM
    if Server then
        if not MapCycle_GetMapIsInCycle then
            -- mapcycle hasn't been loaded yet
            return mapName
        elseif not MapCycle_GetMapIsInCycle(mapName) then
            --could be the infect prefix has been used
            mapName = string.gsub(mapName, "infest_", "infect_")
            if not MapCycle_GetMapIsInCycle(mapName) then
                --also the mod could be loaded without the prefix method
                mapName = oldMapName
            end
        end
    end

    cachedMapName = mapName
    return mapName
end

