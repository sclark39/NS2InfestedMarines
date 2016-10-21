-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMCyst_Server.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function Cyst:GetIsActuallyConnected()
    return true
end

function Cyst:GetSurroundingCystsCount()
    return self.nearCysts.num
end

function Cyst:GetSurroundingCysts()
    
    self.cystEnts = {}
    local missing = {}
    for id, _ in pairs(self.nearCysts) do
        if id ~= "num" then
            local ent = Shared.GetEntity(id)
            if ent then
                table.insert(self.cystEnts, ent)
            else
                table.insert(missing, id)
            end
        end
    end
    
    self.nearCysts.num = self.nearCysts.num - #missing
    for i=1, #missing do
        self.nearCysts[missing[i]] = nil
    end
    return self.cystEnts
    
end

function Cyst:OnEntityChange(entityId, newEntityId)
end

function Cyst:AddCystConnection(cyst)
    
    local oldLevel = self.nearCysts.num
    local id = cyst:GetId()
    if self.nearCysts[id] == nil then
        self.nearCysts[id] = true
        self.nearCysts.num = self.nearCysts.num + 1
    end
    local newLevel = self.nearCysts.num
    
    GetCystManager():UpdateCystConnectionLevel(self, oldLevel, newLevel)
    
    -- ensure it is mutual
    oldLevel = cyst.nearCysts.num
    local thisId = self:GetId()
    if cyst.nearCysts[thisId] == nil then
        cyst.nearCysts[thisId] = true
        cyst.nearCysts.num = cyst.nearCysts.num + 1
    end
    newLevel = cyst.nearCysts.num
    
    GetCystManager():UpdateCystConnectionLevel(cyst, oldLevel, newLevel)
    
    
end

function Cyst:RemoveCystFromSurrounding(cyst)
    local entId = cyst:GetId()
    if self.nearCysts[entId] then
        self.nearCysts[entId] = nil
        self.nearCysts.num = self.nearCysts.num - 1
    end
end

function Cyst:PreOnKill(attacker, doer, point, direction)
    local ents = self:GetSurroundingCysts()
    for i=1, #ents do
        ents[i]:RemoveCystFromSurrounding(self)
    end
end



