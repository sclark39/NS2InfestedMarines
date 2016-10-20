-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMPlayer_Server.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Prevents kill message from appearing in console.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- local function declared in Player_Server, and used in Player:OnKill
local function DestroyViewModel(self)

    assert(self.viewModelId ~= Entity.invalidId)
    
    DestroyEntity(self:GetViewModelEntity())
    self.viewModelId = Entity.invalidId
    
end

-- override to comment out the logs and prevent respawn.
function Player:OnKill(killer, doer, point, direction)

    local isSuicide = not doer and not killer -- xenocide is not a suicide
    local killedByDeathTrigger = doer and doer:isa("DeathTrigger") or killer and killer:isa("DeathTrigger")
    
    if not Shared.GetCheatsEnabled() and ( isSuicide or killedByDeathTrigger ) then
        self.spawnBlockTime = Shared.GetTime() + kSuicideDelay + kFadeToBlackTime
    end
    
    -- Determine the killer's player name.
    local killerName
    if killer then
        -- search for a player being/owning the killer
        local realKiller = killer
        while realKiller and not realKiller:isa("Player") and realKiller.GetOwner do
            realKiller = realKiller:GetOwner()
        end
        if realKiller and realKiller:isa("Player") then
            self.killedBy = killer:GetId()
            killerName = realKiller:GetName()
            --Log("%s: killed by %s", self, self.killedBy)
        end
    end

    -- Save death to server log unless it's part of the concede sequence
    if not self.concedeSequenceActive then
        if isSuicide or killedByDeathTrigger then
            --PrintToLog("%s committed suicide", self:GetName())
        elseif killerName ~= nil then
            --PrintToLog("%s was killed by %s", self:GetName(), killerName)
        else
            --PrintToLog("%s died", self:GetName())
        end
    end

    -- Go to third person so we can see ragdoll and avoid HUD effects (but keep short so it's personal)
    if not self:GetAnimateDeathCamera() then
        self:SetIsThirdPerson(4)
    end
    
    local angles = self:GetAngles()
    angles.roll = 0
    self:SetAngles(angles)
    
    -- This is a hack, CameraHolderMixin should be doing this.
    self.baseYaw = 0
    
    self:AddDeaths()
    
    -- Fade out screen.
    self.timeOfDeath = Shared.GetTime()
    
    DestroyViewModel(self)
    
    -- Save position of last death only if we didn't die to a DeathTrigger
    if not killedByDeathTrigger then
        self.lastDeathPos = self:GetOrigin()
    end
    
    self.lastClass = self:GetMapName()
    
end