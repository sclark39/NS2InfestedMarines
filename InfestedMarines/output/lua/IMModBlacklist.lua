-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMModBlacklist.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
--    Blocks incompatible mods from loading
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
do
	local blacklist = {
		"NS2Plus"
	}

	for _, modName in ipairs(blacklist) do
		local modEntry = ModLoader.GetModInfo(modName)
		if modEntry then
			if modEntry.FileHooks then
				ModLoader.SetupFileHook( modEntry.FileHooks, "IMModBlacklist.lua", "halt")
			end

			local client = decoda_name == "Client"
			local server = decoda_name == "Server"
			local predict = decoda_name == "Predict"
			local shared = client or server or predict

			if shared and modEntry.Shared then
				ModLoader.SetupFileHook( modEntry.Shared, "IMModBlacklist.lua", "halt")
			end

			if client and modEntry.Client then
				ModLoader.SetupFileHook( modEntry.Client, "IMModBlacklist.lua", "halt")
			elseif predict and modEntry.Predict then
				ModLoader.SetupFileHook( modEntry.Predict, "IMModBlacklist.lua", "halt")
			elseif server and modEntry.Server then
				ModLoader.SetupFileHook( modEntry.Server, "IMModBlacklist.lua", "halt")
			end
		end
	end
end