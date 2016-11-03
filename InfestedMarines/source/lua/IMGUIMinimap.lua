-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
--    lua\IMMinimap.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
--    Sets the proper minimap background
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local oldInitialize = GUIMinimap.Initialize
function GUIMinimap:Initialize()
    oldInitialize(self)

    self.minimap:SetTexture("maps/overviews/" .. Shared.GetMapName(true) .. ".tga")
end