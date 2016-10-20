-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMLOSMixin.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Make everything relevant.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kUnitMaxLOSDistance = kPlayerLOSDistance
local kUnitMinLOSDistance = kStructureLOSDistance

local kLOSTimeout = 1

local function UpdateLOS(self)
    
    self:SetExcludeRelevancyMask(0)
    
end

function LOSMixin:__initmixin()

    if Server then
    
        self.sighted = false
        self.lastTimeLookedForEnemies = 0
        self.updateLOS = true
        self.timeLastLOSUpdate = 0
        self.dirtyLOS = true
        self.timeLastLOSDirty = 0
        self.prevLOSorigin = Vector(0,0,0)
    
        self:SetIsSighted(false)
        UpdateLOS(self)
        self.oldSighted = true
        self.lastViewerId = Entity.invalidId
        
    end
    
end

if Server then

    function LOSMixin:OnTeamChange()
        
        UpdateLOS(self)
        self:SetIsSighted(false)
        
    end
    
    local function SharedUpdate(self)
    
        PROFILE("LOSMixin:SharedUpdate")
        
        -- Prevent entities from being sighted before the game starts.
        if not GetGamerules():GetGameStarted() then
            return
        end
        
        local now = Shared.GetTime()
        if self.dirtyLOS and self.timeLastLOSDirty + 0.2 < now then
        
            MarkNearbyDirty(self)
            self.dirtyLOS = false
            self.timeLastLOSDirty = now
            
        end
        
        if self.updateLOS and self.timeLastLOSUpdate + 0.2 < now then
        
            UpdateSelfSighted(self)
            LookForEnemies(self)
            
            self.updateLOS = false
            self.timeLastLOSUpdate = now
            
        end
        
        if self.oldSighted ~= self.sighted then
        
            if self.sighted then
            
                UpdateLOS(self)
                self.timeUpdateLOS = nil
                
            else
                self.timeUpdateLOS = Shared.GetTime() + kLOSTimeout
            end
            
            self.oldSighted = self.sighted
            
        end
        
        if self.timeUpdateLOS and self.timeUpdateLOS < Shared.GetTime() then
        
            UpdateLOS(self)
            self.timeUpdateLOS = nil
            
        end
        
    end
    
    function LOSMixin:OnUpdate(deltaTime)
        SharedUpdate(self, deltaTime)
    end
    
    function LOSMixin:OnProcessMove(input)
        SharedUpdate(self, input.time)
    end
    
end