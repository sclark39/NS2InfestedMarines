-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
--    lua\IMGUIMarineHUD.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
--    Removes some unneeded marine HUD elements
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local originalHUDUpdate
originalHUDUpdate = Class_ReplaceMethod( "GUIMarineHUD", "Update", function(self)
    originalHUDUpdate(self)
    
    self.commanderName:SetIsVisible(false)
    self.resourceDisplay.teamText:SetIsVisible(false)
    self.resourceDisplay.background:SetIsVisible(false)
    if self.minimapBackground then
        self.minimapBackground:SetIsVisible(false)
    end
    
    --if self.gameTime then
        --self.gameTime:SetIsVisible(false)
    --end
end)
