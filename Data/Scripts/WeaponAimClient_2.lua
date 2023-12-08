local WEAPON = script:FindBasicByType('Weapon')
if not WEAPON then
    error(script.name .. " should be part of Weapon object hierarchy.")
end
local CAN_AIM = WEAPON:GetCustomProperty("EnableAim")
local AIM_BINDING = WEAPON:GetCustomProperty("AimBinding")
local ZOOM_DISTANCE = WEAPON:GetCustomProperty("AimZoomDistance")
local pressedHandle = nil
local releasedHandle = nil
local playerDieHandle = nil
local cameraResetDistance = 0
local cameraTargetDistance = 0
local lerpTime = 0
local activeCamera = nil
function Tick(deltaTime)
    if not CAN_AIM then return end
    -- Setup the new weapon camera owner
    if WEAPON and WEAPON.owner and activeCamera == nil then
        OnEquipped(WEAPON, WEAPON.owner)
    end
    -- Smoothly lerps the camera distance when player aims
    LerpCameraDistance(deltaTime)
end
function LerpCameraDistance(deltaTime)
    if lerpTime >= 1 then return end
    if not activeCamera then return end

    lerpTime = lerpTime + deltaTime
    activeCamera.currentDistance = CoreMath.Lerp(activeCamera.currentDistance, cameraTargetDistance, lerpTime)
end
function GetPlayerActiveCamera(player)
    if not Object.IsValid(player) then
        return nil
    end

    if player:GetOverrideCamera() then
        return player:GetOverrideCamera()
    else
        return player:GetDefaultCamera()
    end
end
function EnableScoping(player)
    if player.isDead then return end
    cameraTargetDistance = ZOOM_DISTANCE
    lerpTime = 0
    Events.Broadcast("WeaponAiming", player, true)
end
function ResetScoping(player)
    cameraTargetDistance = cameraResetDistance
    lerpTime = 0
    Events.Broadcast("WeaponAiming", player, false)
end
function OnBindingPressed(player, actionName)
    if actionName == AIM_BINDING then
        EnableScoping(player)
    end
end

function OnBindingReleased(player, actionName)
    if actionName == AIM_BINDING then
        ResetScoping(player)
    end
end
function OnPlayerDied(player, damage)
    ResetScoping(player)
end
function OnEquipped(weapon, player)
    if not CAN_AIM then return end

    pressedHandle = player.bindingPressedEvent:Connect(OnBindingPressed)
    releasedHandle = player.bindingReleasedEvent:Connect(OnBindingReleased)
    playerDieHandle = player.diedEvent:Connect(OnPlayerDied)

    -- Set new active camera
    activeCamera = GetPlayerActiveCamera(player)
    if activeCamera then
        cameraResetDistance = activeCamera.currentDistance
        cameraTargetDistance = cameraResetDistance
    end
    lerpTime = 0
end
function OnUnequipped(weapon, player)
    if not CAN_AIM then return end

    if (pressedHandle) then pressedHandle:Disconnect() end
    if (releasedHandle) then releasedHandle:Disconnect() end
    if (playerDieHandle) then playerDieHandle:Disconnect() end

    ResetScoping(player)

    -- Remove the reference to the camera
    if activeCamera then
        activeCamera.currentDistance = cameraResetDistance
        activeCamera = nil
    end
end
WEAPON.unequippedEvent:Connect(OnUnequipped)