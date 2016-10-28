-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Flamethrower.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
--    Full file replace, because locals make me sad. :(
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/Weapons/Marine/Flame.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")

class 'Flamethrower' (ClipWeapon)

if Client then
    Script.Load("lua/Weapons/Marine/Flamethrower_Client.lua")
end

Flamethrower.kMapName = "flamethrower"

Flamethrower.kModelName = PrecacheAsset("models/marine/flamethrower/flamethrower.model")
local kViewModels = GenerateMarineViewModelPaths("flamethrower")
local kAnimationGraph = PrecacheAsset("models/marine/flamethrower/flamethrower_view.animation_graph")

local kFireLoopingSound = PrecacheAsset("sound/NS2.fev/marine/flamethrower/attack_loop")

local kRange = kFlamethrowerRange
local kUpgradedRange = kFlamethrowerUpgradedRange

local kConeWidth = 0.34

local networkVars =
{ 
    createParticleEffects = "boolean",
    animationDoneTime = "float",
    loopingSoundEntId = "entityid",
    range = "integer (0 to 11)"
}

AddMixinNetworkVars(LiveMixin, networkVars)

local function CheckForDestroyedEffects(self)
    if self.trailCinematic and not IsValid(self.trailCinematic) then
        self.trailCinematic = nil
    end
    if self.pilotCinematic and not IsValid(self.pilotCinematic) then
        self.pilotCinematic = nil
    end
    if self.loopingFireSound and not IsValid(self.loopingFireSound) then
        self.loopingFireSound = nil
    end
end

function Flamethrower:OnCreate()

    ClipWeapon.OnCreate(self)
    
    self.loopingSoundEntId = Entity.invalidId
    
    if Server then
    
        self.createParticleEffects = false
        self.animationDoneTime = 0
        
        self.loopingFireSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingFireSound:SetAsset(kFireLoopingSound)
        self.loopingFireSound:SetParent(self)
        self.loopingSoundEntId = self.loopingFireSound:GetId()
        
    elseif Client then
    
        self:SetUpdates(true)
        self.lastAttackEffectTime = 0.0
        
    end
    
    InitMixin(self, PickupableWeaponMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)

end

function Flamethrower:GetMaxClips()
    return 1
end

function Flamethrower:OnDestroy()
    
    CheckForDestroyedEffects(self)
    
    ClipWeapon.OnDestroy(self)
    
    -- The loopingFireSound was already destroyed at this point, clear the reference.
    if Server then
        self.loopingFireSound = nil
    elseif Client then
    
        if self.trailCinematic then
            Client.DestroyTrailCinematic(self.trailCinematic)
            self.trailCinematic = nil
        end
        
        if self.pilotCinematic then
            Client.DestroyCinematic(self.pilotCinematic)
            self.pilotCinematic = nil
        end
        
    end
    
end

function Flamethrower:GetAnimationGraphName()
    return kAnimationGraph
end

function Flamethrower:GetWeight()
    return kFlamethrowerWeight
end

function Flamethrower:OnHolster(player)
    
    ClipWeapon.OnHolster(self, player)
    
    self.createParticleEffects = false
    
end

function Flamethrower:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player, previousWeaponMapName)
    
    self.createParticleEffects = false
    self.animationDoneTime = Shared.GetTime()
    
end

function Flamethrower:GetClipSize()
    return kFlamethrowerClipSize
end

function Flamethrower:CreatePrimaryAttackEffect(player)

    -- Remember this so we can update gun_loop pose param
    self.timeOfLastPrimaryAttack = Shared.GetTime()

end

function Flamethrower:GetRange()
    return self.range
end

function Flamethrower:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

local function BurnSporesAndUmbra(self, startPoint, endPoint)

    local toTarget = endPoint - startPoint
    local distanceToTarget = toTarget:GetLength()
    toTarget:Normalize()
    
    local stepLength = 2

    for i = 1, 5 do
    
        -- stop when target has reached, any spores would be behind
        if distanceToTarget < i * stepLength then
            break
        end
    
        local checkAtPoint = startPoint + toTarget * i * stepLength
        local spores = GetEntitiesWithinRange("SporeCloud", checkAtPoint, kSporesDustCloudRadius)
        
        local umbras = GetEntitiesWithinRange("CragUmbra", checkAtPoint, CragUmbra.kRadius)
        table.copy(GetEntitiesWithinRange("StormCloud", checkAtPoint, StormCloud.kRadius), umbras, true)
        table.copy(GetEntitiesWithinRange("MucousMembrane", checkAtPoint, MucousMembrane.kRadius), umbras, true)
        table.copy(GetEntitiesWithinRange("EnzymeCloud", checkAtPoint, EnzymeCloud.kRadius), umbras, true)
        
        local bombs = GetEntitiesWithinRange("Bomb", checkAtPoint, 1.6)
        table.copy(GetEntitiesWithinRange("WhipBomb", checkAtPoint, 1.6), bombs, true)
        
        for index, bomb in ipairs(bombs) do
            bomb:TriggerEffects("burn_bomb", { effecthostcoords = Coords.GetTranslation(bomb:GetOrigin()) } )
            DestroyEntity(bomb)
        end
        
        for index, spore in ipairs(spores) do
            self:TriggerEffects("burn_spore", { effecthostcoords = Coords.GetTranslation(spore:GetOrigin()) } )
            DestroyEntity(spore)
        end
        
        for index, umbra in ipairs(umbras) do
            self:TriggerEffects("burn_umbra", { effecthostcoords = Coords.GetTranslation(umbra:GetOrigin()) } )
            DestroyEntity(umbra)
        end
    
    end

end

local function CreateFlame(self, player, position, normal, direction)

    -- create flame entity, but prevent spamming:
    local nearbyFlames = GetEntitiesForTeamWithinRange("Flame", self:GetTeamNumber(), position, 1.5)    

    if table.count(nearbyFlames) == 0 then
    
        local flame = CreateEntity(Flame.kMapName, position, player:GetTeamNumber())
        flame:SetOwner(player)
        
        local coords = Coords.GetTranslation(position)
        coords.yAxis = normal
        coords.zAxis = direction
        
        coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
        coords.xAxis:Normalize()
        
        coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)
        coords.zAxis:Normalize()
        
        flame:SetCoords(coords)
        
    end

end

local function PrioritizeClosestPlayer(weapon, player, newTarget, oldTarget)
    if not oldTarget then
        return true
    end
    
    if newTarget:isa("Marine") then
        if oldTarget:isa("Marine") then
            -- both are marines
            return (newTarget:GetOrigin() - player:GetOrigin()):GetLengthSquared() < (oldTarget:GetOrigin() - player:GetOrigin()):GetLengthSquared()
        else
            -- new is a marine, old is not, new takes priority.
            return true
        end
    else
        if oldTarget:isa("Marine") then
            -- old is a marine, it takes priority
            return false
        else
            -- neither is marine.
            return (newTarget:GetOrigin() - player:GetOrigin()):GetLengthSquared() < (oldTarget:GetOrigin() - player:GetOrigin()):GetLengthSquared()
        end
    end
    
end

local function ApplyConeDamage(self, player)
    
    local eyePos  = player:GetEyePos()    
    local ents = {}


    local fireDirection = player:GetViewCoords().zAxis
    local extents = Vector(kConeWidth, kConeWidth, kConeWidth)
    local remainingRange = self:GetRange()
    
    local startPoint = Vector(eyePos)
    local filterEnts = {self, player}
    
    for i = 1, 20 do
    
        if remainingRange <= 0 then
            break
        end
        
        --local trace = TraceMeleeBox(self, startPoint, fireDirection, extents, remainingRange, PhysicsMask.Flame, EntityFilterList(filterEnts))
        
        local coords = player:GetViewAngles():GetCoords()
        coords.origin = startPoint
        local success = false
        local target = nil
        local traceEndPoint = nil
        local traceDirection = nil
        local traceSurface = nil
        local traceStartPoint = nil
        local traceSelectedTrace = nil
        success, target, traceEndPoint, traceDirection, traceSurface, traceStartPoint, traceSelectedTrace = CheckMeleeCapsule(self, player, 0, remainingRange, coords, nil, nil, PrioritizeClosestPlayer, EntityFilterList(filterEnts), PhysicsMask.Flame)
        local fraction = remainingRange / (traceEndPoint - traceStartPoint):GetLength()
        
        -- Check for spores in the way.
        if Server and i == 1 then
            BurnSporesAndUmbra(self, startPoint, traceEndPoint)
        end
        
        if success then
        
            if target then
            
                if HasMixin(target, "Live") then
                    table.insertunique(ents, target)
                end
                
                table.insertunique(filterEnts, target)
            end
        else
            break
        end

    end
    
    for index, ent in ipairs(ents) do
    
        if ent ~= player then
        
            local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - eyePos)
            local health = ent:GetHealth()
            
            local attackDamage = kFlamethrowerDamage
            
            if HasMixin( ent, "Fire" ) then
                local time = Shared.GetTime()
                if ( ent:isa("AlienStructure") or HasMixin( ent, "Maturity" ) ) and ent:GetIsOnFire() and (ent.timeBurnInit + time) >= (ent.timeBurnInit + kCompoundFireDamageDelay) then
                    attackDamage = kFlamethrowerDamage + ( kFlamethrowerDamage * kCompundFireDamageScalar )
                end
            end
            
            self:DoDamage( attackDamage, ent, ent:GetModelOrigin(), toEnemy )
            
            -- Only light on fire if we successfully damaged them
            if ent:GetHealth() ~= health and HasMixin(ent, "Fire") then
                ent:SetOnFire(player, self)
            end
            
            if ent.GetEnergy and ent.SetEnergy then
                ent:SetEnergy(ent:GetEnergy() - kFlameThrowerEnergyDamage)
            end
            
            if Server and ent:isa("Alien") then
                ent:CancelEnzyme()
            end
            
        end
    
    end

end

local function ShootFlame(self, player)

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    
    viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * (-0.4) + viewCoords.xAxis * (-0.2)
    local endPoint = self:GetBarrelPoint(player) + viewCoords.xAxis * (-0.2) + viewCoords.yAxis * (-0.3) + viewCoords.zAxis * self:GetRange()
    
    local trace = Shared.TraceRay(viewCoords.origin, endPoint, CollisionRep.Damage, PhysicsMask.Flame, EntityFilterAll())
    
    local range = (trace.endPoint - viewCoords.origin):GetLength()
    if range < 0 then
        range = range * (-1)
    end
    
    if trace.endPoint ~= endPoint and trace.entity == nil then
    
        local angles = Angles(0,0,0)
        angles.yaw = GetYawFromVector(trace.normal)
        angles.pitch = GetPitchFromVector(trace.normal) + (math.pi/2)
        
        local normalCoords = angles:GetCoords()
        normalCoords.origin = trace.endPoint
        range = range - 3
        
    end
    
    ApplyConeDamage(self, player)

end

function Flamethrower:FirePrimary(player, bullets, range, penetration)
    ShootFlame(self, player)
end

function Flamethrower:GetDeathIconIndex()
    return kDeathMessageIcon.Flamethrower
end

function Flamethrower:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Flamethrower:GetIsAffectedByWeaponUpgrades()
    return false
end

function Flamethrower:OnPrimaryAttack(player)
    
    CheckForDestroyedEffects(self)
    
    self.ammo = self:GetMaxAmmo()
    
    if not self:GetIsReloading() then
    
        ClipWeapon.OnPrimaryAttack(self, player)
        
        if self:GetIsDeployed() and self:GetClip() > 0 and self:GetPrimaryAttacking() then
        
            if not self.createParticleEffects then
                self:TriggerEffects("flamethrower_attack_start")
            end
        
            self.createParticleEffects = true
            
            if Server and not self.loopingFireSound:GetIsPlaying() then
                self.loopingFireSound:Start()
            end
            
        end
        
        if self.createParticleEffects and self:GetClip() == 0 then
        
            self.createParticleEffects = false
            
            if Server then
                self.loopingFireSound:Stop()
            end
            
        end
    
        -- Fire the cool flame effect periodically
        -- Don't crank the period too low - too many effects slows down the game a lot.
        if Client and self.createParticleEffects and self.lastAttackEffectTime + 0.5 < Shared.GetTime() then
            
            self:TriggerEffects("flamethrower_attack")
            self.lastAttackEffectTime = Shared.GetTime()

        end
        
    end
    
end

function Flamethrower:OnPrimaryAttackEnd(player)
    
    CheckForDestroyedEffects(self)
    
    ClipWeapon.OnPrimaryAttackEnd(self, player)

    self.createParticleEffects = false
        
    if Server then    
        self.loopingFireSound:Stop()        
    end
    
end

function Flamethrower:OnReload(player)
    
    CheckForDestroyedEffects(self)
    
    if self:CanReload() then
    
        if Server then
        
            self.createParticleEffects = false
            self.loopingFireSound:Stop()
        
        end
        
        self:TriggerEffects("reload")
        self.reloading = true
        
    end
    
end

function Flamethrower:GetMeleeBase()
    return kConeWidth, kConeWidth
end

function Flamethrower:GetUpgradeTechId()
    return kTechId.FlamethrowerRangeTech
end

function Flamethrower:GetHasSecondary(player)
    return false
end

function Flamethrower:GetSwingSensitivity()
    return 0.8
end

function Flamethrower:Dropped(prevOwner)
    
    CheckForDestroyedEffects(self)
    
    ClipWeapon.Dropped(self, prevOwner)
    
    if Server then
    
        self.createParticleEffects = false
        self.loopingFireSound:Stop()
        
    end
    
end

function Flamethrower:GetAmmoPackMapName()
    return FlamethrowerAmmo.kMapName
end

function Flamethrower:GetNotifiyTarget()
    return false
end

function Flamethrower:GetIdleAnimations(index)
    local animations = {"idle", "idle_fingers", "idle_clean"}
    return animations[index]
end

function Flamethrower:ModifyDamageTaken(damageTable, attacker, doer, damageType)
    if damageType ~= kDamageType.Corrode then
        damageTable.damage = 0
    end
end

function Flamethrower:GetCanTakeDamageOverride()
    return self:GetParent() == nil
end

if Server then

    function Flamethrower:OnKill()
        DestroyEntity(self)
    end
    
    function Flamethrower:GetSendDeathMessageOverride()
        return false
    end 
    
    function Flamethrower:OnProcessMove(input)
        
        ClipWeapon.OnProcessMove(self, input)
        
        local hasRangeTech = false
        local parent = self:GetParent()
        if parent then
            hasRangeTech = GetHasTech(parent, kTechId.FlamethrowerRangeTech)
        end
        
        self.range = hasRangeTech and kUpgradedRange or kRange

    end
    
end

if Client then

    function Flamethrower:GetUIDisplaySettings()
        return { xSize = 128, ySize = 256, script = "lua/GUIFlamethrowerDisplay.lua" }
    end

end

Shared.LinkClassToMap("Flamethrower", Flamethrower.kMapName, networkVars)
