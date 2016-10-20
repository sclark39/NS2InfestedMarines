-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIScoreboard.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Hide privileged/irrelevant information from scoreboard.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kIconSize = Vector(40, 40, 0)
local kIconOffset = Vector(-15, -10, 0)
local kPlayerItemLeftMargin = 10
local kPlayerNumberWidth = 20
local kPlayerVoiceChatIconSize = 20
local kPlayerBadgeIconSize = 20
local kPlayerBadgeRightPadding = 4
local kSkillBarSize = Vector(48, 15, 0)
local kSkillBarPadding = 4
local lastScoreboardVisState = false
local kSteamProfileURL = "http://steamcommunity.com/profiles/"
local kHiveProfileURL = "http://hive.naturalselection2.com/profile/"
local kMinTruncatedNameLength = 8
local kDeadColor = Color(1,0,0,1)
local kConnectionProblemsIcon = PrecacheAsset("ui/ethernet-connect.dds") -- red plug network connection issue
local kScriptErrorProblemsIcon = PrecacheAsset("ui/script-error.dds")
local kSeverScriptErrorProblemsIcon = PrecacheAsset("ui/script-error-server.dds")
local kMutedTextTexture = PrecacheAsset("ui/sb-text-muted.dds")
local kMutedVoiceTexture = PrecacheAsset("ui/sb-voice-muted.dds")

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

local function CreateTeamBackground(self, teamNumber)

    local color = nil
    local teamItem = GUIManager:CreateGraphicItem()
    teamItem:SetStencilFunc(GUIItem.NotEqual)
    
    -- Background
    teamItem:SetSize(Vector(self:GetTeamItemWidth(), GUIScoreboard.kTeamItemHeight, 0) * GUIScoreboard.kScalingFactor)
    if teamNumber == kTeamReadyRoom then
    
        color = GUIScoreboard.kSpectatorColor
        teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
        
    elseif teamNumber == kTeam1Index then
    
        color = GUIScoreboard.kBlueColor
        teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
        
    elseif teamNumber == kTeam2Index then
    
        color = GUIScoreboard.kRedColor
        teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
        
    end
    
    teamItem:SetColor(Color(0, 0, 0, 0.75))
    teamItem:SetIsVisible(false)
    teamItem:SetLayer(kGUILayerScoreboard)
    
    -- Team name text item.
    local teamNameItem = GUIManager:CreateTextItem()
    teamNameItem:SetFontName(GUIScoreboard.kTeamNameFontName)
    teamNameItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(teamNameItem)
    teamNameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamNameItem:SetTextAlignmentX(GUIItem.Align_Min)
    teamNameItem:SetTextAlignmentY(GUIItem.Align_Min)
    teamNameItem:SetPosition(Vector(10, 5, 0) * GUIScoreboard.kScalingFactor)
    teamNameItem:SetColor(color)
    teamNameItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(teamNameItem)
    
    -- Add team info (team resources and number of players).
    local teamInfoItem = GUIManager:CreateTextItem()
    teamInfoItem:SetFontName(GUIScoreboard.kTeamInfoFontName)
    teamInfoItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(teamInfoItem)
    teamInfoItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamInfoItem:SetTextAlignmentX(GUIItem.Align_Min)
    teamInfoItem:SetTextAlignmentY(GUIItem.Align_Min)
    teamInfoItem:SetPosition(Vector(12, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
    teamInfoItem:SetColor(color)
    teamInfoItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(teamInfoItem)
    
    local currentColumnX = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth, self:GetTeamItemWidth() - GUIScoreboard.kTeamColumnSpacingX * 10)
    local playerDataRowY = 10
    
    -- Status text item.
    local statusItem = GUIManager:CreateTextItem()
    statusItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    statusItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(statusItem)
    statusItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    statusItem:SetTextAlignmentX(GUIItem.Align_Min)
    statusItem:SetTextAlignmentY(GUIItem.Align_Min)
    statusItem:SetPosition(Vector(currentColumnX + 60, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    statusItem:SetColor(color)
    statusItem:SetText("")
    statusItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(statusItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 2 + 33
    
    -- Score text item.
    local scoreItem = GUIManager:CreateTextItem()
    scoreItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    scoreItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(scoreItem)
    scoreItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    scoreItem:SetTextAlignmentX(GUIItem.Align_Center)
    scoreItem:SetTextAlignmentY(GUIItem.Align_Min)
    scoreItem:SetPosition(Vector(currentColumnX + 42.5, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    scoreItem:SetColor(color)
    scoreItem:SetText(Locale.ResolveString("SB_SCORE"))
    scoreItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(scoreItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX + 40
    
    -- Kill text item.
    local killsItem = GUIManager:CreateTextItem()
    killsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    killsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(killsItem)
    killsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    killsItem:SetTextAlignmentX(GUIItem.Align_Center)
    killsItem:SetTextAlignmentY(GUIItem.Align_Min)
    killsItem:SetPosition(Vector(currentColumnX, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    killsItem:SetColor(color)
    killsItem:SetText("")
    killsItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(killsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    -- Assist text item.
    local assistsItem = GUIManager:CreateTextItem()
    assistsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    assistsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(assistsItem)
    assistsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    assistsItem:SetTextAlignmentX(GUIItem.Align_Center)
    assistsItem:SetTextAlignmentY(GUIItem.Align_Min)
    assistsItem:SetPosition(Vector(currentColumnX, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    assistsItem:SetColor(color)
    assistsItem:SetText("")
    assistsItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(assistsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    -- Deaths text item.
    local deathsItem = GUIManager:CreateTextItem()
    deathsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    deathsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(deathsItem)
    deathsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    deathsItem:SetTextAlignmentX(GUIItem.Align_Center)
    deathsItem:SetTextAlignmentY(GUIItem.Align_Min)
    deathsItem:SetPosition(Vector(currentColumnX, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    deathsItem:SetColor(color)
    deathsItem:SetText("")
    deathsItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(deathsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    -- Resources text item.
    local resItem = GUIManager:CreateGraphicItem()
    resItem:SetPosition((Vector(currentColumnX, playerDataRowY, 0) + kIconOffset) * GUIScoreboard.kScalingFactor)
    resItem:SetTexture("ui/buildmenu.dds")
    resItem:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.CollectResources)))
    resItem:SetSize(kIconSize * GUIScoreboard.kScalingFactor)
    resItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(resItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    -- Ping text item.
    local pingItem = GUIManager:CreateTextItem()
    pingItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    pingItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(pingItem)
    pingItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    pingItem:SetTextAlignmentX(GUIItem.Align_Min)
    pingItem:SetTextAlignmentY(GUIItem.Align_Min)
    pingItem:SetPosition(Vector(currentColumnX, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    pingItem:SetColor(color)
    pingItem:SetText(Locale.ResolveString("SB_PING"))
    pingItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(pingItem)
    
    return { Background = teamItem, TeamName = teamNameItem, TeamInfo = teamInfoItem }
    
end

function GUIScoreboard:Initialize()

    self.updateInterval = 0.2
    
    self.visible = false
    
    self.teams = { }
    self.reusePlayerItems = { }
    self.slidePercentage = -1
    GUIScoreboard.screenWidth = Client.GetScreenWidth()
    GUIScoreboard.screenHeight = Client.GetScreenHeight()
    GUIScoreboard.kScalingFactor = ConditionalValue(GUIScoreboard.screenHeight > 1280, GUIScale(1), 1)
    self.centerOnPlayer = true -- For modding
    
    self.scoreboardBackground = GUIManager:CreateGraphicItem()
    self.scoreboardBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.scoreboardBackground:SetLayer(kGUILayerScoreboard)
    self.scoreboardBackground:SetColor(GUIScoreboard.kBgColor)
    self.scoreboardBackground:SetIsVisible(false)
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetLayer(kGUILayerScoreboard)
    self.background:SetColor(GUIScoreboard.kBgColor)
    self.background:SetIsVisible(false)
    
    self.backgroundStencil = GUIManager:CreateGraphicItem()
    self.backgroundStencil:SetIsStencil(true)
    self.backgroundStencil:SetClearsStencilBuffer(true)
    self.scoreboardBackground:AddChild(self.backgroundStencil)
    
    self.slidebar = GUIManager:CreateGraphicItem()
    self.slidebar:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.slidebar:SetSize(GUIScoreboard.kSlidebarSize * GUIScoreboard.kScalingFactor)
    self.slidebar:SetLayer(kGUILayerScoreboard)
    self.slidebar:SetColor(Color(1, 1, 1, 1))
    self.slidebar:SetIsVisible(true)
    
    self.slidebarBg = GUIManager:CreateGraphicItem()
    self.slidebarBg:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.slidebarBg:SetSize(Vector(GUIScoreboard.kSlidebarSize.x * GUIScoreboard.kScalingFactor, GUIScoreboard.kBgMaxYSpace-20, 0))
    self.slidebarBg:SetPosition(Vector(-12.5 * GUIScoreboard.kScalingFactor, 10, 0))
    self.slidebarBg:SetLayer(kGUILayerScoreboard)
    self.slidebarBg:SetColor(Color(0.25, 0.25, 0.25, 1))
    self.slidebarBg:SetIsVisible(false)
    self.slidebarBg:AddChild(self.slidebar)
    self.scoreboardBackground:AddChild(self.slidebarBg)
    
    self.gameTimeBackground = GUIManager:CreateGraphicItem()
    self.gameTimeBackground:SetSize(GUIScoreboard.kGameTimeBackgroundSize)
    self.gameTimeBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.gameTimeBackground:SetPosition( Vector(- GUIScoreboard.kGameTimeBackgroundSize.x / 2, 10, 0) )
    self.gameTimeBackground:SetIsVisible(false)
    self.gameTimeBackground:SetColor(Color(0,0,0,0.5))
    self.gameTimeBackground:SetLayer(kGUILayerScoreboard)
    
    self.gameTime = GUIManager:CreateTextItem()
    self.gameTime:SetFontName(GUIScoreboard.kGameTimeFontName)
    self.gameTime:SetScale(GetScaledVector())
    GUIMakeFontScale(self.gameTime)
    self.gameTime:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.gameTime:SetTextAlignmentX(GUIItem.Align_Center)
    self.gameTime:SetTextAlignmentY(GUIItem.Align_Center)
    self.gameTime:SetColor(Color(1, 1, 1, 1))
    self.gameTime:SetText("")
    self.gameTimeBackground:AddChild(self.gameTime)
    
    -- Teams table format: Team GUIItems, color, player GUIItem list, get scores function.
    -- Spectator team.
    table.insert(self.teams, { GUIs = CreateTeamBackground(self, kTeamReadyRoom), TeamName = ScoreboardUI_GetSpectatorTeamName(),
                               Color = GUIScoreboard.kSpectatorColor, PlayerList = { }, HighlightColor = GUIScoreboard.kSpectatorHighlightColor,
                               GetScores = ScoreboardUI_GetSpectatorScores, TeamNumber = kTeamReadyRoom })
                               
    -- Blue team.
    table.insert(self.teams, { GUIs = CreateTeamBackground(self, kTeam1Index), TeamName = ScoreboardUI_GetBlueTeamName(),
                               Color = GUIScoreboard.kBlueColor, PlayerList = { }, HighlightColor = GUIScoreboard.kBlueHighlightColor,
                               GetScores = ScoreboardUI_GetBlueScores, TeamNumber = kTeam1Index})                              
                       
    -- Red team.
    table.insert(self.teams, { GUIs = CreateTeamBackground(self, kTeam2Index), TeamName = ScoreboardUI_GetRedTeamName(),
                               Color = GUIScoreboard.kRedColor, PlayerList = { }, HighlightColor = GUIScoreboard.kRedHighlightColor,
                               GetScores = ScoreboardUI_GetRedScores, TeamNumber = kTeam2Index })

    self.background:AddChild(self.teams[1].GUIs.Background)
    self.background:AddChild(self.teams[2].GUIs.Background)
    self.background:AddChild(self.teams[3].GUIs.Background)
    
    self.playerHighlightItem = GUIManager:CreateGraphicItem()
    self.playerHighlightItem:SetSize(Vector(self:GetTeamItemWidth() - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0) * GUIScoreboard.kScalingFactor)
    self.playerHighlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.playerHighlightItem:SetColor(Color(1, 1, 1, 1))
    self.playerHighlightItem:SetTexture("ui/hud_elements.dds")
    self.playerHighlightItem:SetTextureCoordinates(0, 0.16, 0.558, 0.32)
    self.playerHighlightItem:SetStencilFunc(GUIItem.NotEqual)
    self.playerHighlightItem:SetIsVisible(false)
    
    self.clickForMouseBackground = GUIManager:CreateGraphicItem()
    self.clickForMouseBackground:SetSize(GUIScoreboard.kClickForMouseBackgroundSize)
    self.clickForMouseBackground:SetPosition(Vector(-GUIScoreboard.kClickForMouseBackgroundSize.x / 2, -GUIScoreboard.kClickForMouseBackgroundSize.y - 5, 0))
    self.clickForMouseBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.clickForMouseBackground:SetIsVisible(false)
    
    self.clickForMouseIndicator = GUIManager:CreateTextItem()
    self.clickForMouseIndicator:SetFontName(GUIScoreboard.kClickForMouseFontName)
    self.clickForMouseIndicator:SetScale(GetScaledVector())
    GUIMakeFontScale(self.clickForMouseIndicator)
    self.clickForMouseIndicator:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.clickForMouseIndicator:SetTextAlignmentX(GUIItem.Align_Center)
    self.clickForMouseIndicator:SetTextAlignmentY(GUIItem.Align_Center)
    self.clickForMouseIndicator:SetColor(Color(0, 0, 0, 1))
    self.clickForMouseIndicator:SetText(GUIScoreboard.kClickForMouseText)
    self.clickForMouseBackground:AddChild(self.clickForMouseIndicator)
    
    self.connectionProblemsIcon = GUIManager:CreateGraphicItem()
    self.connectionProblemsIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.connectionProblemsIcon:SetPosition(GUIScale(Vector(32, 0, 0)))
    self.connectionProblemsIcon:SetSize(GUIScale(Vector(64, 64, 0)))
    self.connectionProblemsIcon:SetLayer(kGUILayerScoreboard)
    self.connectionProblemsIcon:SetTexture(kConnectionProblemsIcon)
    self.connectionProblemsIcon:SetColor(Color(1, 0, 0, 1))
    self.connectionProblemsIcon:SetIsVisible(false)
    self.connectionProblemsDetector = CreateTokenBucket(8, 20)
    
    self.scriptErrorProblemsIcon = GUIManager:CreateGraphicItem()
    self.scriptErrorProblemsIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.scriptErrorProblemsIcon:SetPosition(GUIScale(Vector(32+64+8, 0, 0)))
    self.scriptErrorProblemsIcon:SetSize(GUIScale(Vector(64, 64, 0)))
    self.scriptErrorProblemsIcon:SetLayer(kGUILayerScoreboard)
    self.scriptErrorProblemsIcon:SetTexture(kScriptErrorProblemsIcon)
    self.scriptErrorProblemsIcon:SetColor(Color(1, 1, 0, 0))
    self.scriptErrorProblemsIcon:SetIsVisible(false)
    
    self.serverScriptErrorProblemsIcon = GUIManager:CreateGraphicItem()
    self.serverScriptErrorProblemsIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.serverScriptErrorProblemsIcon:SetPosition(GUIScale(Vector(32+64+8+64+8, 0, 0)))
    self.serverScriptErrorProblemsIcon:SetSize(GUIScale(Vector(64, 64, 0)))
    self.serverScriptErrorProblemsIcon:SetLayer(kGUILayerScoreboard)
    self.serverScriptErrorProblemsIcon:SetTexture(kSeverScriptErrorProblemsIcon)
    self.serverScriptErrorProblemsIcon:SetColor(Color(1, 0, 1, 0))
    self.serverScriptErrorProblemsIcon:SetIsVisible(false)
    
    self.mousePressed = { LMB = { Down = nil }, RMB = { Down = nil } }
    self.badgeNameTooltip = GetGUIManager():CreateGUIScriptSingle("menu/GUIHoverTooltip")
    
    self.hoverMenu = GetGUIManager():CreateGUIScriptSingle("GUIHoverMenu")
    self.hoverMenu:Hide()
    
    self.hoverPlayerClientIndex = 0
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
    local isVisibleTeam = true
    
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
    --local teamResourcesString = ConditionalValue(isVisibleTeam, string.format(Locale.ResolveString("SB_TEAM_RES"), ScoreboardUI_GetTeamResources(teamNumber)), "")
    teamInfoGUIItem:SetText(string.format("%s", ""))
    
    -- Make sure there is enough room for all players on this team GUI.
    teamGUIItem:SetSize(Vector(self:GetTeamItemWidth(), (GUIScoreboard.kTeamItemHeight) + ((GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * numPlayers), 0) * GUIScoreboard.kScalingFactor)
    
    -- Resize the player list if it doesn't match.
    if table.count(playerList) ~= numPlayers then
        self:ResizePlayerList(playerList, numPlayers, teamGUIItem)
    end
    
    local currentY = (GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize + 10) * GUIScoreboard.kScalingFactor
    local currentPlayerIndex = 1
    local deadString = Locale.ResolveString("STATUS_DEAD")
    
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

        player["Score"]:SetText("")
        player["Kills"]:SetText("")
        player["Assists"]:SetText("")
        player["Deaths"]:SetText("")
        player["Status"]:SetText("")
        player["Resources"]:SetText("")
        player["Ping"]:SetText(pingStr)
        
        local white = GUIScoreboard.kWhiteColor
        local baseColor, nameColor, statusColor = white, white, white
        
        if isDead and isVisibleTeam then
        
            --nameColor, statusColor = kDeadColor, kDeadColor

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