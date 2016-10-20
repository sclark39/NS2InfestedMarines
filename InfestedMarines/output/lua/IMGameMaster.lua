-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGameMaster.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Controls the events that occur during a round of Infested Marines (eg when/which air
--    purifiers are attacked).  So named because this role was more or less filled by a human
--    during initial game design/testing.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IMGameMasterUtilities.lua")
Script.Load("lua/IMGameMasterData.lua")

local gameMaster = nil
local useAutomatedGameMaster = true

function GetGameMaster()
    
    if not gameMaster then
        gameMaster = CreateGameMaster()
    end
    
    return gameMaster
    
end

function CreateGameMaster()
    
    local newGM = IMGameMaster()
    newGM:OnCreate()
    return newGM
    
end

function DestroyGameMaster()
    
    gameMaster = nil
    DestroyCystManager()
    
end

function ResetGameMaster()
    
    DestroyGameMaster()
    GetGameMaster()
    
end

class 'IMGameMaster'

IMGameMaster.kDefaultMaxLives = 5
IMGameMaster.kUpdatePeriod = 0.25
IMGameMaster.kMarineSquadRange = 25 -- any marines within 25m of another marine are grouped into
                                    -- the same "squad"
IMGameMaster.kMarineSquadRangeSq = IMGameMaster.kMarineSquadRange * IMGameMaster.kMarineSquadRange
IMGameMaster.kMarineWeldTime = 4    -- approximately the amount of seconds required once at a node to weld it fully.
IMGameMaster.kTimeBeforeInfectedChosen = 30

function IMGameMaster:OnCreate()
    
    self.maxLives = IMGameMaster.kDefaultMaxLives
    self.currentLives = self.maxLives
    
    self.cooldownPeriod = 0.0 -- used to delay the next round of purifiers being damaged.
    self.timeBuffer = 5.0 -- extra five seconds by default.  This is adjusted based on team performance to adjust difficulty
    
end

function IMGameMaster:GetDillyDallyTime()
    return self.timeBuffer
end

function IMGameMaster:GetLivesRemaining()
    return self.currentLives
end

function IMGameMaster:SetLives(lives)
    self.maxLives = lives
    self.currentLives = lives
end

function IMGameMaster:GetIsPurifierSaved(purifier)
    
    -- for now, just look at the health and armor.  Later, we'll need to require they clear the room
    -- of infestation.
    if purifier:GetHealth() >= purifier:GetMaxHealth() * 0.995 and purifier:GetArmor() >= purifier:GetMaxArmor() * 0.995 then
        return true
    end
    
    return false
    
end

function IMGameMaster:GetHasInfectedBeenChosenYet()
    
    return self.pickedInfected
    
end

function IMGameMaster:DoGameStart()
    
    self:SetupStartingInfestation()
    
    self.pickedInfected = false
    self.infectedChooseDelay = IMGameMaster.kTimeBeforeInfectedChosen
    
end

function IMGameMaster:SetupStartingInfestation()
    
    local purifiers = IMGetUndamagedExtractors()
    -- pick a random marine, remove the closest extractor from the table -- we
    -- don't want the extractor in marine starting area to become infested!
    
    local randomMarine = IMGetRandomMarine()
    assert(randomMarine ~= nil)
    local closestIndex = IMGetClosestIndexToPoint(purifiers, randomMarine:GetOrigin())
    local homeNode = purifiers[closestIndex]
    table.remove(purifiers, closestIndex)
    
    -- pick N nodes randomly, preferring nodes further away from both the starting node,
    -- and each picked node.
    local infestCount = 1 -- todo
    local pickedNodes = IMComputeStartingInfestedNodes(infestCount, purifiers, homeNode)
    
    for i=1, #pickedNodes do
        IMInfestNode(pickedNodes[i])
    end
    
end

local function UpdatePurifierStatus(self)
    
    local now = Shared.GetTime()
    
    self.damagedPurifiers = self.damagedPurifiers or {}
    for i=#self.damagedPurifiers, 1, -1 do
        assert(self.damagedPurifiers[i] ~= nil)
        assert(self.damagedPurifiers[i].purId ~= nil)
        local purifier = Shared.GetEntity(self.damagedPurifiers[i].purId)
        local keepProcessing = true
        if purifier then
            if self:GetIsPurifierSaved(purifier) then
                self:RemoveDamagedPurifier(purifier)
                keepProcessing = false
            end
            
            if keepProcessing and now > self.damagedPurifiers[i].endTime then
                -- purifier destroyed!!!
                -- remove from table, but leave blip so it stays on the interface
                table.remove(self.damagedPurifiers, i)
                local blip = Shared.GetEntity(purifier.purifierBlipId)
                blip:SetState(IMAirPurifierBlip.kPurifierState.Destroyed)
                local purifier = Shared.GetEntity(blip.entId)
                assert(purifier ~= nil)
                purifier:Kill()
                self.currentLives = self.currentLives - 1
            end
        end
    end
    
    GetAirStatusBlip().currLives = self.currentLives
    GetAirStatusBlip().maxLives = self.maxLives
    
end

local function UpdateQueuedDamages(self)
    
    self.queuedDamages = self.queuedDamages or {}
    if #self.queuedDamages > 0 then
        self.damageCooldown = self.damageCooldown or 0
        if self.damageCooldown <= 0 then
            local purifier = Shared.GetEntity(self.queuedDamages[1].purId)
            local duration = self.queuedDamages[1].duration
            if purifier and duration then
                self:AddDamagedPurifier(purifier, duration)
            end
            table.remove(self.queuedDamages, 1)
            self.damageCooldown = 0.75
        else
            self.damageCooldown = self.damageCooldown - IMGameMaster.kUpdatePeriod
        end
    end
    
end

local function PerformNodeDamage(self)
    
    local marineConfigTable = IMBuildMarineConfigurationTable()
    
    -- execute randomly picked "scenario".  Scenario is responsible for damaging nodes, and does so
    -- in a unique way.  For example, one scenario might damage many nodes, but give plenty of time,
    -- another might damage few, but give very little time.  One might pick nodes that are far away
    -- from marines... another might attempt to group marines together more.  It's just a way of
    -- churning the players around more randomly, to hopefully prevent the games from feeling the
    -- same every time.
    IMGetRandomScenario()(marineConfigTable)
    
end

local function UpdateGameMasterDuties(self, deltaTime)
    
    if not GetGamerules():GetGameStarted() then
        return
    end
    
    if #self.damagedPurifiers > 0 then
        return
    end
    
    if self.queuedDamages and #self.queuedDamages > 0 then
        return
    end
    
    -- NOTE: the cooldown period will only decrease once there are no more damaged
    -- purifiers.  Cooldown period is set when the damage occurs.
    if self.cooldownPeriod > 0 then
        self.cooldownPeriod = self.cooldownPeriod - deltaTime
        return
    end
    
    PerformNodeDamage(self)
    assert(self.cooldownPeriod > 0) -- cooldown period MUST be set after this
    
end

local function PickInfected(self)
    
    -- TODO pick X players, X scales with player count.
    local numPlayers = GetGamerules().team1:GetNumPlayers()
    
    local infectedIndex = math.random(1, numPlayers)
    local infectedPlayer = GetGamerules().team1:GetPlayer(infectedIndex)
    infectedPlayer:SetIsInfected(true)
    
    assert(infectedPlayer)
    
    Log("infectedPlayer = %s (name is '%s')", infectedPlayer, infectedPlayer.name)
    for i=1, numPlayers do
        Server.SendNetworkMessage(GetGamerules().team1:GetPlayer(i), "InfectedStatusMessage", { infected = (i==infectedIndex) }, true)
    end
    
end

local function UpdateInfectionPick(self)
    
    if not GetGamerules():GetGameStarted() then
        return
    end
    
    if not self.infectedChooseDelay then
        return
    end
    
    self.infectedChooseDelay = self.infectedChooseDelay - IMGameMaster.kUpdatePeriod
    if self.infectedChooseDelay <= 0 then
        self.infectedChooseDelay = nil
        self.pickedInfected = true
        
        PickInfected(self)
    end
    
end

local function UpdateCysts(self)
    
    if not GetGamerules():GetGameStarted() then
        return
    end
    
    self.nextCyst = self.nextCyst or 0
    if self.nextCyst <= 0 then
        if GetCystManager():AddNewCyst() then -- keep trying until successful.
            self.nextCyst = 1
        end
    end
    
    self.nextCyst = self.nextCyst - IMGameMaster.kUpdatePeriod
    
end

function IMGameMaster:OnUpdate(deltaTime)
    
    self.throttle = self.throttle or 0
    self.throttle = self.throttle + deltaTime
    if self.throttle >= IMGameMaster.kUpdatePeriod then
        self.throttle = 0
    else
        return
    end
    
    UpdatePurifierStatus(self)
    UpdateQueuedDamages(self)
    UpdateInfectionPick(self)
    UpdateCysts(self)
    
    if useAutomatedGameMaster then
        UpdateGameMasterDuties(self, IMGameMaster.kUpdatePeriod)
    end
    
end

function IMGameMaster:QueuePurifierDamage(purifier, duration)
    
    self.queuedDamages = self.queuedDamages or {}
    table.insert(self.queuedDamages, { purId = purifier:GetId(), duration = duration })
    
end

function IMGameMaster:AddDamagedPurifier(purifier, duration)
    
    local newBlip = CreateEntity(IMAirPurifierBlip.kMapName, purifier:GetOrigin(), kMarineTeamType)
    newBlip:SetEntityId(purifier:GetId())
    newBlip:SetRampTime(duration)
    
    local purId = purifier:GetId()
    local blipId = newBlip:GetId()
    
    self.damagedPurifiers = self.damagedPurifiers or {}
    for i=#self.damagedPurifiers,1,-1 do
        if self.damagedPurifiers[i].purId == purId then
            self.damagedPurifiers[i].endTime = Shared.GetTime() + duration
            local oldBlip = Shared.GetEntity(self.damagedPurifiers[i].blipId)
            if oldBlip then
                DestroyEntity(oldBlip)
            end
            self.damagedPurifiers[i].blipId = blipId
            return
        end
    end
    
    table.insert(self.damagedPurifiers,
    {
        purId = purId,
        endTime = Shared.GetTime() + duration,
        blipId = blipId,
    })
    
    -- damage the extractor so it must be repaired
    purifier:SetHealth(purifier:GetMaxHealth() * 0.1)
    purifier:SetArmor(0)
    
end

function IMGameMaster:RemoveDamagedPurifier(purifier)
    
    local purId = purifier:GetId()
    
    self.damagedPurifiers = self.damagedPurifiers or {}
    for i=1, #self.damagedPurifiers do
        local iterPurId = self.damagedPurifiers[i].purId
        if iterPurId == purId then
            local blip = Shared.GetEntity(self.damagedPurifiers[i].blipId)
            assert(blip)
            DestroyEntity(blip)
            table.remove(self.damagedPurifiers, i)
            return
        end
    end
    
    Log("Attempted to remove purifier from damaged purifiers table that didn't exist! (%s)", purifier)
    
end

local function OnUpdateGameMaster(deltaTime)
    GetGameMaster():OnUpdate(deltaTime)
end
Event.Hook("UpdateServer", OnUpdateGameMaster)

function IMGameMaster:SetAutomationState(state)
    useAutomatedGameMaster = state
end