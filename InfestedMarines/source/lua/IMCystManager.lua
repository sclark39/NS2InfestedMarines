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

IMCystManager.kCystConnectionRadius = 7
IMCystManager.kCystConnectionRadiusSq = IMCystManager.kCystConnectionRadius * IMCystManager.kCystConnectionRadius

function IMCystManager:OnCreate()
    
    -- manage cyst connectivity by setting up tables for the number of connected cysts each one
    -- has.
    self.cysts = {}
    self.cysts.numLevels = 0
    
end

local function GetRandomCystIndexFromList(list)
    
    local weight = 0
    local pick = 0
    for i=1, #list do
        local ent = Shared.GetEntity(list[i])
        if ent then
            weight = weight + 1
            if math.random() * weight <= 1 then
                pick = i
            end
        end
    end
    
    return pick
    
end

local function RankExtractorsByDistance(x, pos)
    
    local weights = {}
    
    for i=1, #x do -- get length squared would lead to too much bias, I think...
        table.insert((x:GetOrigin() - pos):GetLength())
    end
    
    return weights
    
end

local function RankPointsByDistance(pts, pos)
    
    local weights = {}
    for i=1, #pts do
        table.insert(weights, (pts[i]-pos):GetLength())
    end
    
    return weights
    
end

local function FindNewCystPlacementFromPosition(pos)
    
    -- bias to try to move towards the furthest extractor.
    local extractors = IMGetUndamagedExtractors()
    local weights = RankExtractorsByDistance(pos)
    local pick = extractors[IWGetRandomWeightedIndex(weights)]
    
    local points = IMGetRandomPointsAroundPosition(pos)
    if #points == 0 then
        return nil
    end
    local weights = RankPointsByDistance(points, pick:GetOrigin())
    
    local index = IWGetRandomWeightedIndex(weights)
    
    return points[index]
    
end

local function FindNewCystLocation(self)
    
    local success = false
    for i=1, self.cysts.numLevels do
        local list = self.cysts[i]
        while #list > 0 do
            local index = GetRandomCystIndexFromList(list)
            local ent = Shared.GetEntity(list[index])
            if ent then
                local newPosition = FindNewCystPlacementFromPosition(ent:GetOrigin())
                if newPosition then
                    Log("returning position from FindNewCystLocation")
                    return newPosition
                end
            end
            -- eliminate this choice, try again
            table.remove(list, index)
        end
    end
    
    Log("returning nil from FindNewCystLocation")
    return nil
    
end

function IMCystManager:CreateCyst(position)
    
    local connectedCysts = GetEntitiesWithinRange("Cyst", position, IMCystManager.kCystConnectionRadius)
    local newCyst = CreateEntity( Cyst.kMapName, position, kAlienTeamType )
    
    Log("Created new cyst!")
    
    -- connect cysts
    for i=1, #connectedCysts do
        if connectedCysts[i] then
            newCyst:AddCystConnection(connectedCysts[i])
        end
    end
    
end

function IMCystManager:AddNewCyst()
    
    local newCystLocation = FindNewCystLocation(self)
    if not newCystLocation then
        Log("Warning!  Could not find suitable cyst location!")
        return false
    end
    
    self:CreateCyst(newCystLocation)
    
    return true
    
end



