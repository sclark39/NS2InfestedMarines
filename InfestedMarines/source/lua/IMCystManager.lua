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
IMCystManager.kCystNumWallTraces = 10
IMCystManager.kAreaOfDenialDuration = 5 -- seconds that an area must be cyst free after cyst dies.
IMCystManager.kDenialAreaRadius = 7
IMCystManager.kDenialAreaRadiusSq = IMCystManager.kDenialAreaRadius * IMCystManager.kDenialAreaRadius

function IMCystManager:OnCreate()
    
    self.denialAreas = {}
    
end

local function GetRandomCystNearLocation(location)
    
    local cystsInRange = GetEntitiesWithinRange("Cyst", location, IMCystManager.kCystInitialSearchRadius)
    while(#cystsInRange > 0) do
        local index = math.random(#cystsInRange)
        if cystsInRange[index] and cystsInRange[index].GetIsAlive and cystsInRange[index]:GetIsAlive() then
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
        if not cysts[index] or not cysts[index].GetIsAlive or not cysts[index]:GetIsAlive() then
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
        if cystsInRange[index] and cystsInRange[index].GetIsAlive and cystsInRange[index]:GetIsAlive() then
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
            if cysts[j] and cysts[j].GetIsAlive and cysts[j]:GetIsAlive() then
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

local function ArePointsAboutEqual(p1, p2)
    
    local diff = p1 - p2
    if math.abs(diff.x) < 0.0001 and math.abs(diff.y) < 0.0001 and math.abs(diff.z) < 0.0001 then
        return true
    end
    
    return false
    
end

local function GetIsOnPathingMesh(self, point, thresholdDistSq)
    
    -- requires a bit of a workaround because there is no engine function to get if a point is
    -- on the pathing mesh.  Instead, we get the closest point on the pathing mesh, and compare
    -- them.  Unfortunately, if the point is so far off the mesh a good "closest" point cannot
    -- be found... the engine, in its infinite wisdom, will return the original point... so we
    -- need to detect when this occurs.  We'll give it the passed in point with a slight +y
    -- offset, so if it's the exact same point... it *should* in all likelihood be a reliable
    -- indicator that the point was invalid.
    
    local adjustedPoint = point + Vector(0, 0.5, 0)
    local newPoint = Pathing.GetClosestPoint(adjustedPoint)
    
    if ArePointsAboutEqual(newPoint, adjustedPoint) then
        -- these should NOT be equal, ever.  It's slid off the pathing mesh, return false.
        return false
    end
    
    local diff = (point - newPoint)
    diff.y = diff.y * 0.25 -- we don't care as much about vertical displacement.
    local distSq = diff:GetLengthSquared()
    if distSq > thresholdDistSq then
        -- too far away from original point.  Likely what's happening is this point is off the
        -- map in the void somewhere, but close enough to "snap" back to the pathing mesh.  We
        -- don't want this.
        return false
    end
    
    return true
    
end

local function CheapTraceCystLocation(self, startPoint, endPoint)
    
    local diff = (endPoint - startPoint) / IMCystManager.kCystNumWallTraces
    local threshold = diff:GetLength() * 1.1 -- allow about 10% more distance.
    local thresholdSq = threshold * threshold
    for i=1, IMCystManager.kCystNumWallTraces do
        local pt = startPoint + (diff * i)
        if not GetIsOnPathingMesh(self, pt, thresholdSq) then
            return false
        end
    end
    
    return true
    
end

local function GetRandomNonWallCyst(self, startPoint, pointTable)
    
    while (#pointTable > 0) do
        local index = math.random(#pointTable)
        
        -- check to ensure cyst is pretty much on pathing mesh for several points along the trace.
        if pointTable[index] and CheapTraceCystLocation(self, startPoint, pointTable[index]) then
            return pointTable[index]
        else
            table.remove(pointTable, index)
        end
    end
    
    return nil
    
end

local function GetIsPointInDenialArea(self, point)
    
    local now = Shared.GetTime()
    
    for i=#self.denialAreas, 1, -1 do
        -- ensure denial area is still active
        if self.denialAreas[i].tEnd < now then
            table.remove(self.denialAreas, i)
        else
            if (point - self.denialAreas[i].pt):GetLengthSquared() <= IMCystManager.kDenialAreaRadiusSq then
                return true
            end
        end
    end
    
    return false
    
end

local function EliminatePointsNearDenialAreas(self, points)
    
    for i=#points, 1, -1 do
        if GetIsPointInDenialArea(self, points[i]) then
            table.remove(points, i)
        end
    end
    
    return points
    
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
    EliminatePointsNearDenialAreas(self, pts)
    
    if #pts == 0 then
        return false
    end
    
    -- return a random point from this list, ensuring it doesn't pass through a wall.
    return GetRandomNonWallCyst(self, currentCyst:GetOrigin(), pts)
    
end

function IMCystManager:CreateAreaOfDenial(point)
    
    table.insert(self.denialAreas, { pt = point, tEnd = Shared.GetTime() + IMCystManager.kAreaOfDenialDuration } )
    
end

local function DoGroundTraceForCyst(position, redo)
    
    local groundTrace = Shared.TraceBox(Cyst.kBoxTraceExtents, position + Vector(0, 1.5, 0), position + Vector(0, -5, 0),  CollisionRep.Default, PhysicsMask.CystBuild, EntityFilterAllButIsa("TechPoint"))
    if groundTrace.fraction == 1 then
        return nil
    end
    
    if not redo and math.abs(groundTrace.normal.y) <= 0.5 and groundTrace.fraction < 0.01 then
        -- we didn't go very far, and the normal implies that we are sticking in a wall.
        -- attempt to push out of the wall, then check to ensure we're still over the pathing mesh.
        local newPos = position + groundTrace.normal * 0.25
        
        local adjustedPoint = newPos + Vector(0, 0.5, 0)
        local newPoint = Pathing.GetClosestPoint(adjustedPoint)
        
        if ArePointsAboutEqual(newPoint, adjustedPoint) then
            -- these should NOT be equal, ever.  It's slid off the pathing mesh, fail.
            return nil
        end
        
        return DoGroundTraceForCyst(newPoint, true)
    end
    
    return groundTrace
    
end

function IMCystManager:CreateCyst(position)
    
    local groundTrace = DoGroundTraceForCyst(position)
    if not groundTrace then
        return false
    end
    
    local coords = AlignCyst(Coords.GetTranslation(groundTrace.endPoint), groundTrace.normal)
    coords.origin = groundTrace.endPoint - (Cyst.kBoxTraceExtents.y * coords.yAxis * 10)
    local newCyst = CreateEntity( Cyst.kMapName, coords.origin, kAlienTeamType )
    newCyst:SetCoords(coords)
    
    return true
    
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
    
    return self:CreateCyst(newCystLocation)
    
end



