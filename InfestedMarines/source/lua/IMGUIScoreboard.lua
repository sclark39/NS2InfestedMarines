-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIScoreboard.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Only show player death status to other dead players, or if they are infested, or to
--    spectators.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kPlayerItemLeftMargin = 10
local kPlayerNumberWidth = 20
local kPlayerVoiceChatIconSize = 20
local kPlayerBadgeIconSize = 20
local kPlayerBadgeRightPadding = 4

local kMinTruncatedNameLength = 8
local kDeadColor = Color(1,0,0,1)
local kInfestedColor = Color(0,1,0,1)

local function GetIsVisibleTeam(teamNumber)
    local isVisibleTeam = false
    local localPlayer = Client.GetLocalPlayer()
    if localPlayer then
    
        if localPlayer.GetIsInfected and localPlayer:GetIsInfected() then
            isVisibleTeam = true
        elseif localPlayer.GetIsAlive and not localPlayer:GetIsAlive() then
            isVisibleTeam = true
        elseif localPlayer:GetTeamNumber() == kSpectatorIndex then
            isVisibleTeam = true
        end
        
    end
    
    return isVisibleTeam
end

local function SetPlayerItemBadges( item, badgeTextures )

    assert( #badgeTextures <= #item.BadgeItems )

    local offset = 0

    for i = 1, #item.BadgeItems do

        if badgeTextures[i] ~= nil then
            item.BadgeItems[i]:SetTexture( badgeTextures[i] )
            item.BadgeItems[i]:SetIsVisible( true )
        else
            item.BadgeItems[i]:SetIsVisible( false )
        end

    end

    -- now adjust the position of the player name
    local numBadgesShown = math.min( #badgeTextures, #item.BadgeItems )
    
    offset = numBadgesShown*(kPlayerBadgeIconSize + kPlayerBadgeRightPadding) * GUIScoreboard.kScalingFactor
                
    return offset            

end

function GUIScoreboard:UpdateTeam(updateTeam)
    
    local teamGUIItem = updateTeam["GUIs"]["Background"]
    local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
    local teamInfoGUIItem = updateTeam["GUIs"]["TeamInfo"]
    local teamNameText = Locale.ResolveString( string.format("NAME_TEAM_%s", updateTeam["TeamNumber"]))
    local teamColor = updateTeam["Color"]
    local localPlayerHighlightColor = updateTeam["HighlightColor"]
    local playerList = updateTeam["PlayerList"]
    local teamScores = updateTeam["GetScores"]()
    local teamNumber = updateTeam["TeamNumber"]
    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    -- Determines if the local player can see secret information
    -- for this team.
    local isVisibleTeam = GetIsVisibleTeam(teamNumber)
    
    
    -- How many items per player.
    local numPlayers = table.count(teamScores)
    
    -- Update the team name text.
    local playersOnTeamText = string.format("%d %s", numPlayers, numPlayers == 1 and Locale.ResolveString("SB_PLAYER") or Locale.ResolveString("SB_PLAYERS") )
    local teamHeaderText = nil
    
    if teamNumber == kTeamReadyRoom then
        -- Add number of players connecting
        local numPlayersConnecting = PlayerUI_GetNumConnectingPlayers()
        if numPlayersConnecting > 0 then
            -- It will show RR team if players are connecting even if no players are in the RR
            if numPlayers > 0 then
                teamHeaderText = string.format("%s (%s, %d %s)", teamNameText, playersOnTeamText, numPlayersConnecting, Locale.ResolveString("SB_CONNECTING") )
            else
                teamHeaderText = string.format("%s (%d %s)", teamNameText, numPlayersConnecting, Locale.ResolveString("SB_CONNECTING") )
            end
        end
    end
    
    if not teamHeaderText then
        teamHeaderText = string.format("%s (%s)", teamNameText, playersOnTeamText)
    end
    
    teamNameGUIItem:SetText( teamHeaderText )
    
    -- Update team resource display
    local teamResourcesString = ConditionalValue(isVisibleTeam, string.format(Locale.ResolveString("SB_TEAM_RES"), ScoreboardUI_GetTeamResources(teamNumber)), "")
    teamInfoGUIItem:SetText(string.format("%s", teamResourcesString))
    
    -- Make sure there is enough room for all players on this team GUI.
    teamGUIItem:SetSize(Vector(self:GetTeamItemWidth(), (GUIScoreboard.kTeamItemHeight) + ((GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * numPlayers), 0) * GUIScoreboard.kScalingFactor)
    
    -- Resize the player list if it doesn't match.
    if table.count(playerList) ~= numPlayers then
        self:ResizePlayerList(playerList, numPlayers, teamGUIItem)
    end
    
    local currentY = (GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize + 10) * GUIScoreboard.kScalingFactor
    local currentPlayerIndex = 1
    local deadString = Locale.ResolveString("STATUS_DEAD")
    local infestedString = Locale.ResolveString("STATUS_INFESTED") or "Infested"
    
    for index, player in ipairs(playerList) do
    
        local playerRecord = teamScores[currentPlayerIndex]
        local playerName = playerRecord.Name
        local clientIndex = playerRecord.ClientIndex
        local steamId = GetSteamIdForClientIndex(clientIndex)
        local score = playerRecord.Score
        local kills = playerRecord.Kills
        local assists = playerRecord.Assists
        local deaths = playerRecord.Deaths
        local isCommander = playerRecord.IsCommander and isVisibleTeam == true
        local isRookie = playerRecord.IsRookie
        local resourcesStr = ConditionalValue(isVisibleTeam, tostring(math.floor(playerRecord.Resources * 10) / 10), "-")
        local ping = playerRecord.Ping
        local pingStr = tostring(ping)
        local currentPosition = Vector(player["Background"]:GetPosition())
        local playerStatus = isVisibleTeam and playerRecord.Status or "-"
        local isSpectator = playerRecord.IsSpectator
        local isDead = isVisibleTeam and playerRecord.Status == deadString
        local isInfested = isVisibleTeam and not isDead and playerRecord.Status == infestedString
        local isSteamFriend = playerRecord.IsSteamFriend
        local playerSkill = playerRecord.Skill
        local commanderColor = GUIScoreboard.kCommanderFontColor
        
        if isVisibleTeam and teamNumber == kTeam1Index then
            local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)
            if table.contains(currentTech, kTechId.Jetpack) then
                if playerStatus ~= "" and playerStatus ~= " " then
                    playerStatus = string.format("%s/%s", playerStatus, Locale.ResolveString("STATUS_JETPACK") )
                else
                    playerStatus = Locale.ResolveString("STATUS_JETPACK")
                end
            end
        end
        
        if isCommander then
            score = "*"
        end
        
        currentPosition.y = currentY
        player["Background"]:SetPosition(currentPosition)
        player["Background"]:SetColor(ConditionalValue(isCommander, commanderColor, teamColor))
        
        -- Handle local player highlight
        if ScoreboardUI_IsPlayerLocal(playerName) then
            if self.playerHighlightItem:GetParent() ~= player["Background"] then
                if self.playerHighlightItem:GetParent() ~= nil then
                    self.playerHighlightItem:GetParent():RemoveChild(self.playerHighlightItem)
                end
                player["Background"]:AddChild(self.playerHighlightItem)
                self.playerHighlightItem:SetIsVisible(true)
                self.playerHighlightItem:SetColor(localPlayerHighlightColor)
            end
        end
        
        player["Number"]:SetText(index..".")
        player["Name"]:SetText(playerName)
        
        -- Needed to determine who to (un)mute when voice icon is clicked.
        player["ClientIndex"] = clientIndex
        
        -- Voice icon.
        local playerVoiceColor = GUIScoreboard.kVoiceDefaultColor
        local voiceChannel = clientIndex and ChatUI_GetVoiceChannelForClient(clientIndex) or VoiceChannel.Invalid
        if ChatUI_GetClientMuted(clientIndex) then
            playerVoiceColor = GUIScoreboard.kVoiceMuteColor
        elseif voiceChannel ~= VoiceChannel.Invalid then
            playerVoiceColor = teamColor
        end

        player["Score"]:SetText(tostring(score))
        player["Kills"]:SetText(tostring(kills))
        player["Assists"]:SetText(tostring(assists))
        player["Deaths"]:SetText(tostring(deaths))
        player["Status"]:SetText(playerStatus)
        player["Resources"]:SetText(resourcesStr)
        player["Ping"]:SetText(pingStr)
        
        local white = GUIScoreboard.kWhiteColor
        local baseColor, nameColor, statusColor = white, white, white
        
        if isDead then
        
            nameColor, statusColor = kDeadColor, kDeadColor

        elseif isInfested then
            
            nameColor, statusColor = kInfestedColor, kInfestedColor
            
        end
        
        player["Score"]:SetColor(baseColor)
        player["Kills"]:SetColor(baseColor)
        player["Assists"]:SetColor(baseColor)
        player["Deaths"]:SetColor(baseColor)
        player["Status"]:SetColor(statusColor)
        player["Resources"]:SetColor(baseColor)   
        player["Name"]:SetColor(nameColor)
            
        if ping < GUIScoreboard.kLowPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kLowPingColor)
        elseif ping < GUIScoreboard.kMedPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kMedPingColor)
        elseif ping < GUIScoreboard.kHighPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kHighPingColor)
        else
            player["Ping"]:SetColor(GUIScoreboard.kInsanePingColor)
        end
        currentY = currentY + (GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * GUIScoreboard.kScalingFactor
        currentPlayerIndex = currentPlayerIndex + 1
        
        -- New scoreboard positioning
        
        local numberSize = 0
        if player["Number"]:GetIsVisible() then
            numberSize = kPlayerNumberWidth
        end
        
        for i = 1, #player["BadgeItems"] do
            player["BadgeItems"][i]:SetPosition(Vector(numberSize + kPlayerItemLeftMargin + (i-1) * kPlayerVoiceChatIconSize + (i-1) * kPlayerBadgeRightPadding, -kPlayerVoiceChatIconSize/2, 0) * GUIScoreboard.kScalingFactor)
        end
        
        local statusPos = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth + 30, (self:GetTeamItemWidth() - GUIScoreboard.kTeamColumnSpacingX * 10) + 60)
        local playerStatus = player["Status"]:GetText()
        if playerStatus == "-" or (playerStatus ~= Locale.ResolveString("STATUS_SPECTATOR") and teamNumber ~= 1 and teamNumber ~= 2) then
            player["Status"]:SetText("")
            statusPos = statusPos + GUIScoreboard.kTeamColumnSpacingX * ConditionalValue(GUIScoreboard.screenWidth < 1280, 2.75, 1.75)
        end
        
        SetPlayerItemBadges( player, Badges_GetBadgeTextures(clientIndex, "scoreboard") )
        
        local numBadges = math.min(#Badges_GetBadgeTextures(clientIndex, "scoreboard"), #player["BadgeItems"])
        local pos = (numberSize + kPlayerItemLeftMargin + numBadges * kPlayerVoiceChatIconSize + numBadges * kPlayerBadgeRightPadding) * GUIScoreboard.kScalingFactor
        
        player["Name"]:SetPosition(Vector(pos, 0, 0))
        
        -- Icons on the right side of the player name
        player["SteamFriend"]:SetIsVisible(playerRecord.IsSteamFriend)
        player["Voice"]:SetIsVisible(ChatUI_GetClientMuted(clientIndex))
        player["Text"]:SetIsVisible(ChatUI_GetSteamIdTextMuted(steamId))
        
        local nameRightPos = pos + (kPlayerBadgeRightPadding * GUIScoreboard.kScalingFactor)
        
        pos = (statusPos - kPlayerBadgeRightPadding) * GUIScoreboard.kScalingFactor
        
        for _, icon in ipairs(player["IconTable"]) do
            if icon:GetIsVisible() then
                local iconSize = icon:GetSize()
                pos = pos - iconSize.x
                icon:SetPosition(Vector(pos, (-iconSize.y/2), 0))
            end
        end
        
        local finalName = player["Name"]:GetText()
        local finalNameWidth = player["Name"]:GetTextWidth(finalName) * GUIScoreboard.kScalingFactor
        local dotsWidth = player["Name"]:GetTextWidth("...") * GUIScoreboard.kScalingFactor
        -- The minimum truncated length for the name also includes the "..."
        while nameRightPos + finalNameWidth > pos and string.UTF8Length(finalName) > kMinTruncatedNameLength do
            finalName = string.UTF8Sub(finalName, 1, string.UTF8Length(finalName)-1)
            finalNameWidth = (player["Name"]:GetTextWidth(finalName) * GUIScoreboard.kScalingFactor) + dotsWidth
            player["Name"]:SetText(finalName .. "...")
        end
        
        local color = Color(0.5, 0.5, 0.5, 1)
        if isCommander then
            color = GUIScoreboard.kCommanderFontColor * 0.8
        else
            color = teamColor * 0.8
        end
        
        if not self.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then
            if MouseTracker_GetIsVisible() and GUIItemContainsPoint(player["Background"], mouseX, mouseY) then
                local canHighlight = true
                local hoverBadge = false
                for _, icon in ipairs(player["IconTable"]) do
                    if icon:GetIsVisible() and GUIItemContainsPoint(icon, mouseX, mouseY) and not icon.allowHighlight then
                        canHighlight = false
                        break
                    end
                end

                for i = 1, #player.BadgeItems do
                    local badgeItem = player.BadgeItems[i]
                    if GUIItemContainsPoint(badgeItem, mouseX, mouseY) and badgeItem:GetIsVisible() then
                        local clientIndex = player["ClientIndex"]
                        local _, badgeNames = Badges_GetBadgeTextures(clientIndex, "scoreboard")
                        local badge = ToString(badgeNames[i])
                        self.badgeNameTooltip:SetText(GetBadgeFormalName(badge))
                        hoverBadge = true
                        break
                    end
                end
            
                if canHighlight then
                    self.hoverPlayerClientIndex = clientIndex
                    player["Background"]:SetColor(color)
                else
                    self.hoverPlayerClientIndex = 0
                end
                
                if hoverBadge then
                    self.badgeNameTooltip:Show()
                else
                    self.badgeNameTooltip:Hide()
                end
            end
        elseif steamId == GetSteamIdForClientIndex(self.hoverPlayerClientIndex) then
            player["Background"]:SetColor(color)
        end
        
    end

end