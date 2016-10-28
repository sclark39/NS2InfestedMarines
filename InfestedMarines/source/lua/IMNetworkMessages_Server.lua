-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMNetworkMessages_Server.lua
--
--    Created by:   Sebastian Schuck (trevor@naturalselection2.com)
--
--    Override the chat interface to stop dead players chating with alive players
--    Also makes team chat functional again as infested can use it to chat with each other.
--
--    To be compatible with the shine mod this needs to be loaded before the shine startup.lua
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--Todo Begin: make those non local functions in vanilla
local kChatsPerSecondAdded = 1
local kMaxChatsInBucket = 5
local function CheckChatAllowed(client)

	client.chatTokenBucket = client.chatTokenBucket or CreateTokenBucket(kChatsPerSecondAdded, kMaxChatsInBucket)
	-- Returns true if there was a token to remove.
	return client.chatTokenBucket:RemoveTokens(1)

end

local function GetChatPlayerData(client)

	local playerName = "Admin"
	local playerLocationId = -1
	local playerTeamNumber = kTeamReadyRoom
	local playerTeamType = kNeutralTeamType
	local player

	if client then

		player = client:GetControllingPlayer()
		if not player then
			return
		end
		playerName = player:GetName()
		playerLocationId = player.locationId
		playerTeamNumber = player:GetTeamNumber()
		playerTeamType = player:GetTeamType()

	end

	return playerName, playerLocationId, playerTeamNumber, playerTeamType, player

end
--Todo end

local function OnChatReceived(client, message)

	if not CheckChatAllowed(client) then
		return
	end

	local chatMessage = string.UTF8Sub(message.message, 1, kMaxChatLength)
	if chatMessage and string.len(chatMessage) > 0 then

		local playerName, playerLocationId, playerTeamNumber, playerTeamType, author = GetChatPlayerData(client)

		if playerName then
			local authorIsInfected = author.GetIsInfected and author:GetIsInfected()
			local authorIsDead = not author.GetIsAlive or not author:GetIsAlive()

			local players = message.teamOnly and GetEntitiesForTeam("Player", playerTeamNumber) or EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
			for _, player in ipairs(players) do
				local playerIsInfected = player.GetIsInfected and player:GetIsInfected()

				local send = true

				--Mark Dead and stop them from chatting with the living
				if authorIsDead then
					if player.GetIsAlive and player:GetIsAlive() and player:GetTeamNumber() == kMarineTeamType then
						send = false
					else
						playerName = string.format("(Dead) %s", playerName) --Todo: Localize
					end
				end

				--Mark Infested players for the other infested players
				if authorIsInfected and playerIsInfected then
					playerName = string.format("(Infested) %s", playerName) --Todo: Localize
				end

				if send then
					Server.SendNetworkMessage(player, "Chat", BuildChatMessage(message.teamOnly, playerName, playerLocationId, playerTeamNumber, playerTeamType, chatMessage), true)
				end
			end

			Shared.Message("Chat " .. (message.teamOnly and "Team - " or "All - ") .. playerName .. ": " .. chatMessage)

			-- We save a history of chat messages received on the Server.
			Server.AddChatToHistory(chatMessage, playerName, client:GetUserId(), playerTeamNumber, message.teamOnly)

		end

	end

end

Server.HookNetworkMessage("ChatClient", OnChatReceived)