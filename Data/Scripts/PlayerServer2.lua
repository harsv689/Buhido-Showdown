local WEAPON = script:GetCustomProperty("Weapon")

local function OnPlayerJoined(player)
    local weapon = World.SpawnAsset(WEAPON)

    weapon:Equip(player)
end

Game.playerJoinedEvent:Connect(OnPlayerJoined)