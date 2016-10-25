-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMNS2Gamerules.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Overrides functionality in NS2Gamerules.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kTimeToReadyRoom = 8

if Server then
    
    -- blind reflection damage: where you don't know if you're going to be reflection-killed until it's
    -- time to die.  Before such time, you see damage as usual.
    function NS2Gamerules:GetUsesBlindReflectedDamage()
        return true
    end
    
    local function SetupPowerNodes()
        local rezNodes = EntityListToTable(Shared.GetEntitiesWithClassname("Extractor"))
        local roomsWithRezNodes = {}
        for i=1, #rezNodes do
            if rezNodes[i] then
                roomsWithRezNodes[Shared.GetString(rezNodes[i]:GetLocationId())] = true
            end
        end
        local powerNodes = EntityListToTable(Shared.GetEntitiesWithClassname("PowerPoint"))
        for i=1, #powerNodes do
            if powerNodes[i] then
                if not powerNodes[i]:GetIsSocketed() then
                    powerNodes[i]:SocketPowerNode()
                end
                if not powerNodes[i]:GetIsBuilt() then
                    powerNodes[i]:SetConstructionComplete()
                end
                if not roomsWithRezNodes[Shared.GetString(powerNodes[i]:GetLocationId())] then
                    -- power is permanently destroyed in all other rooms
                    powerNodes[i]:SetInternalPowerState(PowerPoint.kPowerState.destroyed)
                    powerNodes[i]:SetLightMode(kLightMode.NoPower)
                    powerNodes[i]:Kill()
                end
            end
        end
    end
    
    -- let them try to join any team at any time.
    function NS2Gamerules:GetCanJoinTeamNumber()
        return true
    end
    
    -- prevent late joiners from starting alive
    function NS2Gamerules:GetCanSpawnImmediately()
        return not self:GetGameStarted()
    end
    
    -- prevents players from joining alien team.
    local old_NS2Gamerules_JoinTeam = NS2Gamerules.JoinTeam
    function NS2Gamerules:JoinTeam(player, newTeamNumber, force)
        
        if newTeamNumber == kTeam2Index then
            newTeamNumber = kTeam1Index
        end
        
        if not self:GetGameStarted() then
            self.timeSinceGameStateChanged = 0
        end
        
        old_NS2Gamerules_JoinTeam(self, player, newTeamNumber, force)
        
    end
    
    function NS2Gamerules:GetPregameLength()
        return 5
    end
    
    function NS2Gamerules:GetWarmUpPlayerLimit()
        return 0
    end
    
    function NS2Gamerules:CheckGameStart()
        if self:GetGameState() <= kGameState.PreGame then
            if self.team1:GetNumPlayers() < 2 then
                if self:GetGameState() ~= kGameState.NotStarted then
                    self:SetGameState(kGameState.NotStarted)
                end
            else
                if self:GetGameState() ~= kGameState.PreGame then
                    self:SetGameState(kGameState.PreGame)
                end
            end
        end
    end
    
    function NS2Gamerules:CheckGameEnd()
        if self:GetGameStarted() then
            -- game may have "started", but check first to ensure it's actually at a point where it
            -- should be able to end before checking the end conditions.
            if GetGameMaster():GetHasInfectedBeenChosenYet() then
                -- check for if all infected are dead or all uninfected are dead
                local foundInfected = false
                local foundUninfected = false
                
                local marines = EntityListToTable(Shared.GetEntitiesWithClassname("Marine"))
                for i=1, #marines do
                    if marines[i] and marines[i].GetIsInfected and marines[i].GetIsAlive and marines[i]:GetIsAlive() then
                        if marines[i]:GetIsInfected() then
                            foundInfected = true
                        else
                            foundUninfected = true
                        end
                    end
                end
                
                if foundInfected and not foundUninfected then
                    Log("Found infected, but no uninfected.  Ending with a win for team2.")
                    self:EndGame( self.team2 )
                elseif (not foundInfected) and foundUninfected then
                    Log("Found uninfected, but no infected.  Ending with a win for team1.")
                    self:EndGame( self.team1 )
                elseif (not foundInfected) and (not foundUninfected) then
                    Log("Didn't find infected or uninfected marines.  Ending with a draw.")
                    self:DrawGame()
                end
                
                -- check for if uninfected have toxic air quality
                if GetGameMaster():GetAirQuality() <= 0.00001 then
                    Log("Air quality is toxic.  Ending with a win for team2.")
                    self:EndGame( self.team2 )
                end
            else
                local marines = EntityListToTable(Shared.GetEntitiesWithClassname("Marine"))
                local foundAlive = false
                for i=1, #marines do
                    if marines[i] and marines[i].GetIsAlive and marines[i]:GetIsAlive() then
                        foundAlive = true
                        break
                    end
                end
                if not foundAlive then
                    Log("All marines dead before first infected even chosen.  Ending with a win for team2.")
                    self:EndGame( self.team2 )
                end
            end
        end
    end
    
    --[[
     * Starts a new game by resetting the map and all of the players. Keep everyone on current teams (readyroom, playing teams, etc.) but 
     * respawn playing players.
    ]]
    function NS2Gamerules:ResetGame()

        self:SetGameState(kGameState.NotStarted)

        TournamentModeOnReset()
        
        -- Destroy any map entities that are still around
        DestroyLiveMapEntities()
        
        -- Reset all players, delete other not map entities that were created during 
        -- the game (hives, command structures, initial resource towers, etc)
        -- We need to convert the EntityList to a table since we are destroying entities
        -- within the EntityList here.
        for index, entity in ientitylist(Shared.GetEntitiesWithClassname("Entity")) do
        
            -- Don't reset/delete NS2Gamerules or TeamInfo.
            -- NOTE!!!
            -- MapBlips are destroyed by their owner which has the MapBlipMixin.
            -- There is a problem with how this reset code works currently. A map entity such as a Hive creates
            -- it's MapBlip when it is first created. Before the entity:isa("MapBlip") condition was added, all MapBlips
            -- would be destroyed on map reset including those owned by map entities. The map entity Hive would still reference
            -- it's original MapBlip and this would cause problems as that MapBlip was long destroyed. The right solution
            -- is to destroy ALL entities when a game ends and then recreate the map entities fresh from the map data
            -- at the start of the next game, including the NS2Gamerules. This is how a map transition would have to work anyway.
            -- Do not destroy any entity that has a parent. The entity will be destroyed when the parent is destroyed or
            -- when the owner manually destroyes the entity.
            local shieldTypes = { "GameInfo", "MapBlip", "NS2Gamerules", "PlayerInfoEntity" }
            local allowDestruction = true
            for i = 1, #shieldTypes do
                allowDestruction = allowDestruction and not entity:isa(shieldTypes[i])
            end
            
            if allowDestruction and entity:GetParent() == nil then
            
                local isMapEntity = entity:GetIsMapEntity()
                local mapName = entity:GetMapName()
                
                -- Reset all map entities and all player's that have a valid Client (not ragdolled players for example).
                local resetEntity = entity:isa("TeamInfo") or entity:GetIsMapEntity() or (entity:isa("Player") and entity:GetClient() ~= nil)
                if resetEntity then
                
                    if entity.Reset then
                        entity:Reset()
                    end
                    
                else
                    DestroyEntity(entity)
                end
                
            end       
            
        end
        
        -- Clear out obstacles from the navmesh before we start repopualating the scene
        RemoveAllObstacles()
        
        -- Build list of tech points
        local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
        if table.maxn(techPoints) < 2 then
            Print("Warning -- Found only %d %s entities.", table.maxn(techPoints), TechPoint.kMapName)
        end
        
        local resourcePoints = Shared.GetEntitiesWithClassname("ResourcePoint")
        if resourcePoints:GetSize() < 2 then
            Print("Warning -- Found only %d %s entities.", resourcePoints:GetSize(), ResourcePoint.kPointMapName)
        end
        
        -- add obstacles for resource points back in
        for index, resourcePoint in ientitylist(resourcePoints) do        
            resourcePoint:AddToMesh()        
        end
        
        local team1TechPoint = nil
        local team2TechPoint = nil
        
        if Server.teamSpawnOverride and #Server.teamSpawnOverride > 0 then
           
            for t = 1, #techPoints do

                local techPointName = string.lower(techPoints[t]:GetLocationName())
                local selectedSpawn = Server.teamSpawnOverride[1]
                if techPointName == selectedSpawn.marineSpawn then
                    team1TechPoint = techPoints[t]
                elseif techPointName == selectedSpawn.alienSpawn then
                    team2TechPoint = techPoints[t]
                end
                
            end
            
            if not team1TechPoint or not team2TechPoint then
                Shared.Message("Invalid spawns, defaulting to normal spawns")
                if Server.spawnSelectionOverrides then
        
                    local selectedSpawn = self.techPointRandomizer:random(1, #Server.spawnSelectionOverrides)
                    selectedSpawn = Server.spawnSelectionOverrides[selectedSpawn]
                    
                    for t = 1, #techPoints do
                    
                        local techPointName = string.lower(techPoints[t]:GetLocationName())
                        if techPointName == selectedSpawn.marineSpawn then
                            team1TechPoint = techPoints[t]
                        elseif techPointName == selectedSpawn.alienSpawn then
                            team2TechPoint = techPoints[t]
                        end
                        
                    end
                        
                else
                    
                    -- Reset teams (keep players on them)
                    team1TechPoint = self:ChooseTechPoint(techPoints, kTeam1Index)
                    team2TechPoint = self:ChooseTechPoint(techPoints, kTeam2Index)

                end
            
            end
            
        elseif Server.spawnSelectionOverrides then
        
            local selectedSpawn = self.techPointRandomizer:random(1, #Server.spawnSelectionOverrides)
            selectedSpawn = Server.spawnSelectionOverrides[selectedSpawn]
            
            for t = 1, #techPoints do
            
                local techPointName = string.lower(techPoints[t]:GetLocationName())
                if techPointName == selectedSpawn.marineSpawn then
                    team1TechPoint = techPoints[t]
                elseif techPointName == selectedSpawn.alienSpawn then
                    team2TechPoint = techPoints[t]
                end
                
            end
            
        else
        
            -- Reset teams (keep players on them)
            team1TechPoint = self:ChooseTechPoint(techPoints, kTeam1Index)
            team2TechPoint = self:ChooseTechPoint(techPoints, kTeam2Index)

        end
        
        self.team1:ResetPreservePlayers(team1TechPoint)
        self.team2:ResetPreservePlayers(team2TechPoint)
        
        self.worldTeam:ResetPreservePlayers(nil)
        self.spectatorTeam:ResetPreservePlayers(nil)    
        
        -- Replace players with their starting classes with default loadouts at spawn locations
        self.team1:ReplaceRespawnAllPlayers()
        self.team2:ReplaceRespawnAllPlayers()
        
        self.clientpres = {}
        
        -- Create team specific entities
        local commandStructure1 = self.team1:ResetTeam()
        
        -- login the commanders again
        local function LoginCommander(commandStructure, client)
            local player = client and client:GetControllingPlayer()
            if commandStructure and player then
                -- make up for not manually moving to CS and using it
                commandStructure.occupied = not client:GetIsVirtual()
                player:SetOrigin(commandStructure:GetDefaultEntryOrigin())
                commandStructure:LoginPlayer(player,true)
            end
        end
        
        -- Create living map entities fresh
        CreateLiveMapEntities()
        
        -- Make rooms with extractors bright, rooms without dark
        SetupPowerNodes()
        
        self.forceGameStart = false
        self.preventGameEnd = nil
        -- Reset banned players for new game
        self.bannedPlayers = {}
        
        -- Send scoreboard and tech node update, ignoring other scoreboard updates (clearscores resets everything)
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            Server.SendCommand(player, "onresetgame")
            player.sendTechTreeBase = true
        end
        
        -- Reset the infested marines game mode controller
        ResetGameMaster()
        
        self.team1:OnResetComplete()
        self.team2:OnResetComplete()
        
    end
    
    local function StartCountdown(self)
    
        self:ResetGame()
        
        self:SetGameState(kGameState.Countdown)
        self.countdownTime = kCountDownLength
        
        self.lastCountdownPlayed = nil
        
    end
    
    function NS2Gamerules:UpdatePregame(timePassed)

        if self:GetGameState() == kGameState.PreGame then
        
            local preGameTime = self:GetPregameLength()
            
            if self.timeSinceGameStateChanged > preGameTime then
            
                StartCountdown(self)
                if Shared.GetCheatsEnabled() then
                    self.countdownTime = 1
                end
                
            end
            
        elseif self:GetGameState() == kGameState.Countdown then
        
            self.countdownTime = self.countdownTime - timePassed
            
            -- Play count down sounds for last few seconds of count-down
            local countDownSeconds = math.ceil(self.countdownTime)
            if self.lastCountdownPlayed ~= countDownSeconds and (countDownSeconds < 4) then
            
                self.worldTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.team1:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.team2:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.spectatorTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                
                self.lastCountdownPlayed = countDownSeconds
                
            end
            
            if self.countdownTime <= 0 then
            
                self.team1:PlayPrivateTeamSound(ConditionalValue(self.team1:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                self.team2:PlayPrivateTeamSound(ConditionalValue(self.team2:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                
                self:SetGameState(kGameState.Started)
                self.sponitor:OnStartMatch()
                self.playerRanking:StartGame()
                
                GetGameMaster():DoGameStart()
                
            end
            
        end
        
    end
    
    function NS2Gamerules:UpdateToReadyRoom()

        local state = self:GetGameState()
        if(state == kGameState.Team1Won or state == kGameState.Team2Won or state == kGameState.Draw) and (not self.concedeStartTime) then
            if self.timeSinceGameStateChanged >= kTimeToReadyRoom then
                -- reset teams
                self:ResetGame()
            end
        end
    end

    --reset (update) scores at round end
    local oldEndGame = NS2Gamerules.EndGame
    function NS2Gamerules:EndGame(...)
        oldEndGame(self, ...)

        self:ResetPlayerScores()
    end

end