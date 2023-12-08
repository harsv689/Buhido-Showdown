local WEAPON = script:GetCustomProperty("Weapon")

-- Store a list of players in the game so that
-- the events can be disconnected later when
-- they leave.
local players = {}

-- Enable weapon abilities for the player
local function EnableWeapon(player)
    if Object.IsValid(player) and players[player.id] and Object.IsValid(players[player.id].weapon) then
        local abilities = players[player.id].weapon:FindDescendantsByType("Ability")

        for index, ability in ipairs(abilities) do
            ability.isEnabled = true
        end
    end
end

-- Disable weapon abilities for the player
local function DisableWeapon(player)
    if Object.IsValid(player) and players[player.id] and Object.IsValid(players[player.id].weapon) then
        local abilities = players[player.id].weapon:FindDescendantsByType("Ability")

        for index, ability in ipairs(abilities) do
            ability.isEnabled = false
        end
    end
end

-- Look for a valid target that is a damageable object
local function GetValidTarget(target)
    if not Object.IsValid(target) then
        return nil
    end

    if target:IsA("Damageable") then
        return target
    end

    return target:FindAncestorByType("Damageable")
end

-- See if the target is invulnerable, if so, broadcast
-- to the player for feedback.
local function OnImpact(weaponObj, impactData)
    local target = GetValidTarget(impactData.targetObject)

    if Object.IsValid(target) then
        if target.isInvulnerable then
            Events.BroadcastToPlayer(impactData.weaponOwner, "ShowDamage", 0, true)
        end
    end
end

-- When a player joins, give a weapon
local function OnPlayerJoined(player)
    local weapon = World.SpawnAsset(WEAPON, nil)

    weapon:Equip(player)
    weapon.targetImpactedEvent:Connect(OnImpact)

    players[player.id] = {

        pressedEvt = player.bindingPressedEvent:Connect(function(obj, binding)
            if binding == "ability_feet" then
                player.maxWalkSpeed = 1000
            end
        end),

        releasedEvt = player.bindingReleasedEvent:Connect(function(obj, binding)
            if binding == "ability_feet" then
                player.maxWalkSpeed = 640
            end
        end),

        weapon = weapon
    }

    DisableWeapon(player)
end

-- Clean up the events when a player leaves
local function OnPlayerLeft(player)
    if players[player.id].pressedEvt.isConnected then
        players[player.id].pressedEvt:Disconnect()
    end

    if players[player.id].releasedEvt.isConnected then
        players[player.id].releasedEvt:Disconnect()
    end

    players[player.id] = nil
end

Game.playerJoinedEvent:Connect(OnPlayerJoined)
Game.playerLeftEvent:Connect(OnPlayerLeft)

Events.Connect("EnableWeapon", EnableWeapon)
Events.Connect("DisableWeapon", DisableWeapon)