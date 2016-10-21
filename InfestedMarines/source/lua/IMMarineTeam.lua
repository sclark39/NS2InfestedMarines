-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMMarineTeam.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Changes marine starting structures.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local function GetUnoccupiedTechPoint(self, techPointsOccupied)
    local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
    while #techPoints > 0 do
        local index = math.random(1,#techPoints)
        if techPoints[index] and not techPointsOccupied[techPoints[index]] then
            techPointsOccupied[techPoints[index]] = true
            return techPoints[index]
        end
        table.remove(techPoints, index)
    end
    return nil
end

local function SpawnPowerGenerator(self, techPointsOccupied)
    local techPoint = GetUnoccupiedTechPoint(self, techPointsOccupied)
    
    local power = CreateEntityForTeam(kTechId.ArmsLab, techPoint:GetOrigin(), kMarineTeamType)
    power:SetCoords(techPoint:GetCoords())
end

function MarineTeam:SpawnInitialStructures(techPoint)
    
    self.startTechPoint = techPoint
    
    local powerNodes = EntityListToTable(Shared.GetEntitiesWithClassname("PowerPoint"))
    local rezNodes = EntityListToTable(Shared.GetEntitiesWithClassname("ResourcePoint"))
    gAirFilters = {}
    for i=1, #rezNodes do
        if rezNodes[i] then
            local newExtractor = CreateEntityForTeam(kTechId.Extractor, rezNodes[i]:GetOrigin(), kMarineTeamType)
            newExtractor:SetConstructionComplete()
            table.insert(gAirFilters, newExtractor)
        end
    end
    
end

-- local used in Update()
local function GetArmorLevel(self)

    local armorLevels = 0
    
    local techTree = self:GetTechTree() 
    if techTree then
    
        if techTree:GetHasTech(kTechId.Armor3) then
            armorLevels = 3
        elseif techTree:GetHasTech(kTechId.Armor2) then
            armorLevels = 2
        elseif techTree:GetHasTech(kTechId.Armor1) then
            armorLevels = 1
        end
    
    end
    
    return armorLevels

end

-- remove no-ip check
function MarineTeam:Update(timePassed)

    PROFILE("MarineTeam:Update")

    PlayingTeam.Update(self, timePassed)
    
    -- Update distress beacon mask
    self:UpdateGameMasks(timePassed)    
    
    local armorLevel = GetArmorLevel(self)
    for index, player in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
        player:UpdateArmorAmount(armorLevel)
    end
    
end

