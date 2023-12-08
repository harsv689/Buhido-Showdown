-- Internal properties
local ROOT = script:GetCustomProperty("Root"):WaitForObject()
local BINDING_LABELS = require(script:GetCustomProperty("BindingLabels"))
local PANEL = script:GetCustomProperty("Panel"):WaitForObject()
local ABILITY_NAME = script:GetCustomProperty("AbilityName"):WaitForObject()
local ABILITY_ICON = script:GetCustomProperty("AbilityIcon"):WaitForObject()
local COOLDOWN_BAR = script:GetCustomProperty("CooldownBar"):WaitForObject()
local COOLDOWN_TIME = script:GetCustomProperty("CooldownTime"):WaitForObject()
local ABILITY_BUTTON = script:GetCustomProperty("AbilityButton"):WaitForObject()
local ACTION_BINDING_NAME = script:GetCustomProperty("ActionBindingName"):WaitForObject()

-- Exposed properties
local ACTION_NAME = ROOT:GetCustomProperty("ActionName")
local SHOW_ABILITY_NAME = ROOT:GetCustomProperty("ShowAbilityName")
local SHOW_ACTION_LABEL = ROOT:GetCustomProperty("ShowActionLabel")
local HIDE_WHEN_DISABLED = ROOT:GetCustomProperty("HideWhenDisabled")

-- Constants
local LOCAL_PLAYER = Game.GetLocalPlayer()
local DEFAULT_ICON = ABILITY_ICON:GetImage()

-- Variables
local currentAbility = nil

local executeDuration = 0.0
local recoveryDuration = 0.0
local cooldownDuration = 0.0

local playerCooldownRemaining = 0
local totalPlayerCooldown = 0

-- Finds the first ability that matches the given binding
function GetLocalPlayerAbilityWithBinding()
    local abilities = LOCAL_PLAYER:GetAbilities()
    for _, ability in pairs(abilities) do
        if ability.actionName == ACTION_NAME then
            return ability
        end
    end

    return nil
end

-- Updates the state when the ability matching the given binding changes
function UpdateCurrentAbility(forceUpdate)
    local newAbility = GetLocalPlayerAbilityWithBinding()

    if currentAbility == newAbility and not forceUpdate then
        return
    end

    currentAbility = newAbility

    if currentAbility then
        PANEL.visibility = Visibility.INHERIT

        -- Sets ability icon, if the ability has Icon proprty reference
        local icon = currentAbility:GetCustomProperty("Icon")
        if icon then
            ABILITY_ICON:SetImage(icon)
        else
            ABILITY_ICON:SetImage(DEFAULT_ICON)
        end

        -- Sets ability name text
        if SHOW_ABILITY_NAME then
            ABILITY_NAME.visibility = Visibility.INHERIT
            ABILITY_NAME.text = currentAbility.name
        else
            ABILITY_NAME.visibility = Visibility.FORCE_OFF
        end

        -- Sets binding label text
        if SHOW_ACTION_LABEL then
            ACTION_BINDING_NAME.visibility = Visibility.INHERIT

            local label = Input.GetActionInputLabel(currentAbility.actionName)
            if label then
                if BINDING_LABELS[label] then
                    ACTION_BINDING_NAME.text = BINDING_LABELS[label].ShortLabel
                else
                    ACTION_BINDING_NAME.text = label
                end
            else
                ACTION_BINDING_NAME.visibility = Visibility.FORCE_OFF
            end
        else
            ACTION_BINDING_NAME.visibility = Visibility.FORCE_OFF
        end

        -- Caches ability phase total cooldown duration
        executeDuration = currentAbility.executePhaseSettings.duration
        recoveryDuration = currentAbility.recoveryPhaseSettings.duration
        cooldownDuration = currentAbility.cooldownPhaseSettings.duration
    else
        PANEL.visibility = Visibility.FORCE_OFF
    end
end

-- Checks for changes to the players abiltiies, or icons on those abilities
function Tick(deltaTime)
    UpdateCurrentAbility()

    if currentAbility then
        local currentPhase = currentAbility:GetCurrentPhase()
        local phaseTime = currentAbility:GetPhaseTimeRemaining()

        if HIDE_WHEN_DISABLED then
            if currentAbility.isEnabled then
                PANEL.visibility = Visibility.INHERIT
            else
                PANEL.visibility = Visibility.FORCE_OFF
            end
        else
            if currentAbility.isEnabled then
                ABILITY_BUTTON.isInteractable = true
            else
                ABILITY_BUTTON.isInteractable = false
            end
        end

        if currentPhase == AbilityPhase.READY or currentPhase == AbilityPhase.CAST then
            COOLDOWN_TIME.visibility = Visibility.FORCE_OFF
            COOLDOWN_BAR.visibility = Visibility.FORCE_OFF
        else
            -- For a player, recovery, cooldown and execute phases all constitute an ability's cooldown
            playerCooldownRemaining = phaseTime

            if currentPhase ~= AbilityPhase.COOLDOWN then   -- Execute or recovery
                playerCooldownRemaining = playerCooldownRemaining + cooldownDuration
            end

            if currentPhase == AbilityPhase.EXECUTE then
                playerCooldownRemaining = playerCooldownRemaining + recoveryDuration
            end

            totalPlayerCooldown = executeDuration + recoveryDuration + cooldownDuration
            
            if totalPlayerCooldown > 0.3 then
                COOLDOWN_TIME.visibility = Visibility.INHERIT
                COOLDOWN_BAR.visibility = Visibility.INHERIT

                COOLDOWN_TIME.text = string.format("%.1f", playerCooldownRemaining)
                COOLDOWN_BAR.progress = CoreMath.Clamp(playerCooldownRemaining / totalPlayerCooldown)
            else
                COOLDOWN_TIME.visibility = Visibility.FORCE_OFF
                COOLDOWN_BAR.visibility = Visibility.FORCE_OFF
            end
        end
    end
end

function OnInputTypeChanged(player, changedInputType)
    UpdateCurrentAbility(true)
end

Input.inputTypeChangedEvent:Connect(OnInputTypeChanged)


function OnClicked(button)
	print("button clicked: " .. button.name)
	
end

ABILITY_BUTTON.clickedEvent:Connect(OnClicked)

UpdateCurrentAbility(true)
