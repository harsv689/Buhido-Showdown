--[[
Copyright 2021 Manticore Games, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

-- Internal custom properties
local VEHICLE = script:FindAncestorByType('Vehicle')
if not VEHICLE:IsA('Vehicle') then
    error(script.name .. " should be part of Vehicle object hierarchy.")
end
local TURRET_ROOT = script:GetCustomProperty("TurretRoot"):WaitForObject()
local TURRET_WEAPON = script:GetCustomProperty("TurretWeapon"):WaitForObject()
local TURRET_GUN = script:GetCustomProperty("TurretGun"):WaitForObject()

local ROTATE_TURRET_YAW = script:GetCustomProperty("RotateTurretYaw")

local ROTATE_GUN_PITCH = script:GetCustomProperty("RotateTurretGunPitch")
local PITCH_ANGLE = script:GetCustomProperty("PitchMinMaxAngle")
local PITCH_CENTER_OFFSET = script:GetCustomProperty("PitchCenterOffset")

local ROTATION_SMOOTHNESS = script:GetCustomProperty("RotationSmoothness")

-- Exposed variables
local FRIENDLY_EXPLOSION = script:GetCustomProperty("FriendlyExplosionDamage")
local EXPLOSION_DAMAGE_RANGE = script:GetCustomProperty("ExplosionDamageRange")
local EXPLOSION_RADIUS = script:GetCustomProperty("ExplosionRadius")
local EXPLOSION_KNOCKBACK_SPEED = script:GetCustomProperty("ExplosionKnockbackSpeed")
local IMPACT = script:GetCustomProperty("ProjectileImpact")
local BOUNCE_SOUND = script:GetCustomProperty("ProjectileBounceSound")
local DEBUG_EXPLOSION = script:GetCustomProperty("DebugExplosion")

-- Constant variables
local TURRET_ATTACK_ABILITY = TURRET_WEAPON:GetAbilities()[1]

function Tick(deltaTime)
	if not Object.IsValid(VEHICLE) then return end
    if not Object.IsValid(VEHICLE.driver) then return end

    -- Rotate turret
    if ROTATE_TURRET_YAW then
        RotateTurret()
    end

    -- Rotate turret gun
    if ROTATE_GUN_PITCH then
        RotateTurretGun()
    end

    Task.Wait()
end

function RotateTurret()
    if not Object.IsValid(VEHICLE) then return end
    if not Object.IsValid(VEHICLE.driver) then return end

    local targetRot = VEHICLE.driver:GetViewWorldRotation()
    targetRot = -VEHICLE:GetWorldRotation() * targetRot
    
    targetRot.x = 0
    targetRot.y = 0

    TURRET_ROOT:RotateTo(targetRot, ROTATION_SMOOTHNESS, true)
end

function RotateTurretGun()
    if not Object.IsValid(VEHICLE) then return end
    if not Object.IsValid(VEHICLE.driver) then return end

    local targetRot = VEHICLE.driver:GetViewWorldRotation()
    targetRot = -VEHICLE:GetWorldRotation() * targetRot

    targetRot.x = 0
    targetRot.z = 0
    targetRot.y = CoreMath.Clamp(targetRot.y, PITCH_ANGLE.x, PITCH_ANGLE.y) + PITCH_CENTER_OFFSET

    TURRET_GUN:RotateTo(targetRot, ROTATION_SMOOTHNESS, true)
end

-- nil Blast(Vector3)
-- Creates a explosion at the projectile impact position
-- Damages players within the blast
function Blast(center)
    if DEBUG_EXPLOSION then
        CoreDebug.DrawSphere(center, EXPLOSION_RADIUS, {color = Color.RED, duration = 5})
    end

    -- If VEHICLE is destroyed by the time the blast happens, stop the script
    if not Object.IsValid(VEHICLE) then return end
    -- If driver left the server by the time the blast happens, stop the script
    if not Object.IsValid(VEHICLE.driver) then return end

    local players = Game.FindPlayersInSphere(center, EXPLOSION_RADIUS)
    for _, player in pairs(players) do
        local canDamage = false

        -- Checks to blast the enemy team
        if Teams.AreTeamsEnemies(player.team, VEHICLE.driver.team) then
            canDamage = true
        -- Checks to blast the ally team (including damaging to self)
        elseif not Teams.AreTeamsEnemies(player.team, VEHICLE.driver.team) 
               and FRIENDLY_EXPLOSION then
            canDamage = true
        end

        -- If canDamage is true and there is no objects obstructing the explosion then damage the player
        if canDamage then
            local displacement = player:GetWorldPosition() - center

            -- The farther the player from the blast the less damage that player takes
            local minDamage = EXPLOSION_DAMAGE_RANGE.x
            local maxDamage = EXPLOSION_DAMAGE_RANGE.y
            displacement.z = 0
            local t = (displacement).size / EXPLOSION_RADIUS
            local damageAmount = CoreMath.Lerp(maxDamage, minDamage, t)

            -- Create damage information
            local damage = Damage.New(damageAmount)
            damage.sourcePlayer = VEHICLE.driver

            -- Apply damage to player
            player:ApplyDamage(damage)

            -- Create a direction at which the player is pushed away from the blast
            player:AddImpulse((displacement):GetNormalized() * player.mass * EXPLOSION_KNOCKBACK_SPEED)
        end
    end

end

function OnDriverEntered(vehicle, player)
    TURRET_ATTACK_ABILITY.owner = player
end

function OnDriverExited(vehicle, player)
    TURRET_ATTACK_ABILITY.owner = nil
end

-- nil OnTargetImpactedEvent (Weapon, ImpactData)
-- Spawns explosion on the projectile impact
function OnTargetImpactedEvent (weapon, impactData)
    local impactPosition = impactData:GetHitResult():GetImpactPosition()

    -- Explode when interacted with player
    if impactData.targetObject:IsA("Player") then
        Blast(impactPosition)
        return
    end

    -- Explode if the remaining bounces is 0
    if Object.IsValid(impactData.projectile) then
        if impactData.projectile.bouncesRemaining == 0 then
            Blast(impactPosition)
            return
        end
    end
end

-- nil OnProjectileSpawned(Weapon, Projectile)
-- Register lifespan end explosion to simulate projectile cooking
function OnProjectileSpawned(weapon, projectile)
    projectile.lifeSpanEndedEvent:Connect(function(destroyedProjectile)
        Blast(destroyedProjectile:GetWorldPosition())
    end)
end

-- Initialize
VEHICLE.driverEnteredEvent:Connect(OnDriverEntered)
VEHICLE.driverExitedEvent:Connect(OnDriverExited)
TURRET_WEAPON.targetImpactedEvent:Connect(OnTargetImpactedEvent)
TURRET_WEAPON.projectileSpawnedEvent:Connect(OnProjectileSpawned)
