-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMCystManager.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Handles the cyst related functionality for InfestedMarines gamemode.  Contains utilities for
--    adding new cysts in the right places.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local cystManager = nil

function GetCystManager()
    
    if not cystManager then
        cystManager = CreateCystManager()
    end
    
    return cystManager
    
end

function CreateCystManager()
    
    local newCM = IMCystManager()
    newCM:OnCreate()
    return newCM
    
end

function DestroyCystManager()
    
    cystManager = nil
    
end

function ResetCystManager()
    
    DestroyCystManager()
    GetCystManager()
    
end

class 'IMCystManager'

IMCystManager.kCystInitialSearchRadius = 14
IMCystManager.kCystConnectionRadius = 7
IMCystManager.kCystSearchRadius = 6
IMCystManager.kCystMinDistance = 5

function IMCystManager:OnCreate()
    
end

local function GetRandomCystNearLocation(location)
    
    local cystsInRange = GetEntitiesWithinRange("Cyst", location, IMCystManager.kCystInitialSearchRadius)
    while(#cystsInRange > 0) do
        local index = math.random(#cystsInRange)
        if cystsInRange[index] then
            return cystsInRange[index]
        else
            table.remove(cystsInRange, index)
        end
    end
    return nil
    
end

local function GetRandomCystNoLocation()
    
    local cysts = EntityListToTable(Shared.GetEntitiesWithClassname("Cyst"))
    while #cysts > 0 do
        local index = math.random(#cysts)
        if not cysts[index] then
            table.remove(cysts, index)
        else
            return cysts[index]
        end
    end
    
    return nil
    
end

-- random cyst map-wide, or if location is specified, random cyst within a generous radius
local function GetRandomCyst(optional_location)
    
    if optional_location then
        return GetRandomCystNearLocation(optional_location)
    end
    
    return GetRandomCystNoLocation()
    
end

-- attempts to find another cyst within kCystMinDistance of the position offsetVec offset from the
-- origin of cyst.  If it finds one, it returns the entity (or a random entity if it found many).
-- otherwise, it returns nil.
local function Jump(cyst, offsetVec)
    local pos = cyst:GetOrigin() + offsetVec
    local cystsInRange = GetEntitiesWithinRange("Cyst", pos, IMCystManager.kCystMinDistance )
    while (#cystsInRange > 0) do
        local index = math.random(#cystsInRange)
        if cystsInRange[index] then
            return cystsInRange[index]
        else
            table.remove(cystsInRange, index)
        end
    end
    return nil
end

local function EliminatePointsNearCysts(pts)
    
    local vettedPoints = {}
    for i=1, #pts do
        local cysts = GetEntitiesWithinRange("Cyst", pts[i], IMCystManager.kCystMinDistance)
        local foundCyst = false
        for j=1, #cysts do
            if cysts[j] then
                foundCyst = true
                break
            end
        end
        if not foundCyst then
            table.insert(vettedPoints, pts[i])
        end
    end
    
    return vettedPoints
    
end

local function FindNewCystLocation(self, optional_start_location)
    
    local startingCyst = GetRandomCyst(optional_start_location)
    if not startingCyst then
        return false
    end
    local angle = math.random() * math.pi * 2
    local ca = math.cos(angle)
    local sa = math.sin(angle)
    local offset = IMCystManager.kCystSearchRadius
    local offsetVec = Vector(-sa * offset, 0, ca * offset)
    
    local currentCyst = startingCyst
    while true do
        local nextCyst = Jump(currentCyst, offsetVec)
        if not nextCyst then
            break
        end
        currentCyst = nextCyst
    end
    
    -- now we know we're at the sort of "perimeter" of the blob of cysts -- there aren't any more
    -- cysts nearby.  Now we make a new cyst at some random point near this.
    local pts = IMGetRandomPointsAroundPosition(currentCyst:GetOrigin())
    pts = EliminatePointsNearCysts(pts)
    if #pts == 0 then
        return false
    end
    
    -- return random one for now... maybe we can rank them later for better results?
    return pts[math.random(#pts)]
    
end

function IMCystManager:CreateCyst(position)
    
    local newCyst = CreateEntity( Cyst.kMapName, position, kAlienTeamType )
    
end

function IMCystManager:AddNewCyst(optional_start_location)
    
    local attempts = 5
    local newCystLocation = nil
    while not newCystLocation and attempts > 0 do
        attempts = attempts - 1
        newCystLocation = FindNewCystLocation(self, optional_start_location)
    end
    
    if not newCystLocation then
        return false
    end
    
    self:CreateCyst(newCystLocation)
    
    return true
    
end



