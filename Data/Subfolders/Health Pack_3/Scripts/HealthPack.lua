--[[
    Made by Anthony (Dev_Anthony#6986)

    How to configure:

    The HealthPack folder has three custom properties that you can change:
    ? float CooldownTimer - the amount of time before the health pack respawns
    ? float HealAmount - the amount of health the player will restore
    ? int NumberOfUses - the amount of times this health pack can be collected before disappearing completely (-1 == never disappears)
]]

--// Constants
local HEALTH_PACK = script.parent
local HEART = HEALTH_PACK:FindChildByName("Heart")
local TRIGGER = HEALTH_PACK:FindChildByName("Trigger")
local VFX = HEALTH_PACK:FindChildByName("HealVFX")

--// SFX
local HEAL_SOUND_1 = HEALTH_PACK:FindChildByName("HealSound1")
local HEAL_SOUND_2 = HEALTH_PACK:FindChildByName("HealSound2")

--// Variables
local sinZ = 0
local debounce = false
local numUses = HEALTH_PACK:GetCustomProperty("NumberOfUses")

--// Moves the heart up and down on a sin wave
function Tick(dt)
    local HEART_ROOT = HEART:GetPosition()
    sinZ = sinZ + (dt * 1)
    HEART:SetPosition(Vector3.New(HEART_ROOT.x, HEART_ROOT.y, HEART_ROOT.z + (math.sin(sinZ) / 5)))
end

--// Healing logic
local function healPlayer(trigger, obj)
    if not debounce and obj ~= nil and obj:IsA("Player") then
        debounce = true
        obj.hitPoints = obj.hitPoints + HEALTH_PACK:GetCustomProperty("HealAmount")
        VFX:Play()
        HEAL_SOUND_1:Play()
        HEAL_SOUND_2:Play()
        HEART.isVisible = false

        if not (numUses < 0) then
            numUses = numUses - 1
        end

        if numUses ~= 0 then
            Task.Wait(HEALTH_PACK:GetCustomProperty("CooldownTimer"))
            HEART.isVisible = true
            debounce = false
        else
            Task.Wait(3)
            HEALTH_PACK:Destroy()
        end
    end
end

--// Continuously otates the heart
HEART:RotateContinuous(Rotation.New(0,0,5), 5, true)
TRIGGER.beginOverlapEvent:Connect(healPlayer)