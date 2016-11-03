-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMMarine_Client.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Handles client-only functionality for the marine, including targeting for infested, and the keybind display.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local old_Marine_UpdateMisc = Marine.UpdateMisc
function Marine:UpdateMisc(input)
    
    -- clear last update's infection target
    if self.currentInfectionTarget then
        local oldTarget = Shared.GetEntity(self.currentInfectionTarget)
        if oldTarget then
            oldTarget.targetedForInfection = nil
        end
        self.currentInfectionTarget = nil
    end
    
    -- update the infection target every frame.  Using the crosshair target was too slow/unresponsive.
    if self:GetIsInfected() then
        local target = self:GetCrosshairTargetForInfection()
        if target then
            -- check if target is valid
            if self:GetCanInfectTarget(target) then
                self.currentInfectionTarget = target:GetId()
                target.targetedForInfection = true
            end
        end
    end
    
    -- update the keybind displayed on the marine's screen.
    if self:GetWasRecentlyInfested() and not self.secondaryKeybindShown then
        self.secondaryKeybindShown = true
    end
    
    old_Marine_UpdateMisc(self, input)
    
end