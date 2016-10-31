-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMNetworkMessages.lua
--
--    Created by:   Sebastian Schuck (trevor@naturalselection2.com)
--
-- Allows scores to be negative
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kScoreUpdate =
{
	points = "integer",
	res = "integer (0 to " .. kMaxPersonalResources .. ")",
	wasKill = "boolean"
}
Shared.RegisterNetworkMessage("ScoreUpdate", kScoreUpdate)
