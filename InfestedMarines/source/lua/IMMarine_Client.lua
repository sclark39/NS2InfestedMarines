
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
    if self:GetWasRecentlyInfested() and not self.infestHintDisplayed then
        self.infestHintDisplayed = true
        GetKeybindDisplayManager():DisplayBinding("SecondaryAttack", IMStringGetRightClickTipMessage())
    end
    
    old_Marine_UpdateMisc(self, input)
    
end
