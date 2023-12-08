local WEAPON = script:FindBasicByType('Weapon')
if not WEAPON then
    error(script.name .. " should be part of Weapon object hierarchy.")
end
local CAN_AIM = WEAPON:GetCustomProperty("EnableAim")
local AIM_BINDING = WEAPON:GetCustomProperty("AimBinding")
local AIM_WALK_SPEED_PERCENTAGE = WEAPON:GetCustomProperty("AimWalkSpeedPercentage")
local AIM_ACTIVE_STANCE = WEAPON:GetCustomProperty("AimActiveStance")
local speedReduced = 0
local pressedHandle = nil
local releasedHandle = nil
local playerDieHandle = nil
local UNARMED_STANCE = "unarmed_stance"
function SetAimingSpeed(player)
    if Object.IsValid(player) and player == WEAPON.owner then
    speedReduced = player.maxWalkSpeed * AIM_WALK_SPEED_PERCENTAGE
    player.maxWalkSpeed = player.maxWalkSpeed - speedReduced
    player.animationStance = AIM_ACTIVE_STANCE
    end
end
function ResetPlayerSpeed(player)
    if WEAPON and Object.IsValid(player) then
    player.maxWalkSpeed = player.maxWalkSpeed + speedReduced
    player.animationStance = WEAPON.animationStance
    speedReduced = 0
    end
end
function OnBindingPressed(player, actionName)
    if actionName == AIM_BINDING then
        SetAimingSpeed(player)
    end
end
function OnBindingReleased(player, actionName)
    if actionName == AIM_BINDING then
    ResetPlayerSpeed(player)
    end
end
function OnPlayerDied(player, damage)
    ResetPlayerSpeed(player)
end
function OnEquipped(weapon, player)
    if not CAN_AIM then return end

    pressedHandle = player.bindingPressedEvent:Connect(OnBindingPressed)
    releasedHandle = player.bindingReleasedEvent:Connect(OnBindingReleased)
    playerDieHandle = player.diedEvent:Connect(OnPlayerDied)
end
function OnUnequipped(weapon, player)
    if not CAN_AIM then return end

    if (pressedHandle) then pressedHandle:Disconnect() end
    if (releasedHandle) then releasedHandle:Disconnect() end
    if (playerDieHandle) then playerDieHandle:Disconnect() end

    -- Reset player speed and animation stance on unequip
    ResetPlayerSpeed(player)
    player.animationStance = UNARMED_STANCE
end
WEAPON.equippedEvent:Connect(OnEquipped)
WEAPON.unequippedEvent:Connect(OnUnequipped)