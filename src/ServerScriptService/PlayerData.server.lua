--[[
	PlayerData.server.lua
	Manages per-player data: coins, equipment, wave progress.
	Lives in ServerScriptService, provides API for other modules.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)

local UpdateCoinsRemote = Remotes.UpdateCoins
local UpdateWaveRemote = Remotes.UpdateWave

local PlayerData = {}
local playerDataMap = {} :: { [Player]: {
	Coins: number,
	CurrentWeapon: string,
	Ammo: number,
	MaxAmmo: number,
	WaveSurvived: number,
	HasStarted: boolean,
} }

-- Initializes data for a new player joining the server.
function PlayerData.InitPlayer(player: Player)
	local data = {
		Coins = GameConfig.StartingCoins,
		CurrentWeapon = "BasicBlaster",
		Ammo = GameConfig.Equipment.BasicBlaster.MaxAmmo,
		MaxAmmo = GameConfig.Equipment.BasicBlaster.MaxAmmo,
		WaveSurvived = 0,
		HasStarted = false,
	}
	playerDataMap[player] = data
	UpdateCoinsRemote:FireClient(player, data.Coins)
end

-- Removes player data when they leave.
function PlayerData.RemovePlayer(player: Player)
	playerDataMap[player] = nil
end

-- Returns the data table for a player.
function PlayerData.GetData(player: Player): { any }?
	return playerDataMap[player]
end

-- Adds coins to a player's balance and syncs to client.
function PlayerData.AddCoins(player: Player, amount: number)
	local data = playerDataMap[player]
	if not data then
		return
	end
	data.Coins += amount
	UpdateCoinsRemote:FireClient(player, data.Coins)
end

-- Deducts coins if the player has enough. Returns true on success.
function PlayerData.SpendCoins(player: Player, amount: number): boolean
	local data = playerDataMap[player]
	if not data or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	UpdateCoinsRemote:FireClient(player, data.Coins)
	return true
end

-- Returns the player's current coin balance.
function PlayerData.GetCoins(player: Player): number
	local data = playerDataMap[player]
	if not data then
		return 0
	end
	return data.Coins
end

-- Sets the player's current weapon and refills ammo.
function PlayerData.SetWeapon(player: Player, weaponName: string)
	local data = playerDataMap[player]
	if not data then
		return
	end
	local weaponConfig = GameConfig.Equipment[weaponName]
	if not weaponConfig then
		return
	end
	data.CurrentWeapon = weaponName
	data.MaxAmmo = weaponConfig.MaxAmmo
	data.Ammo = weaponConfig.MaxAmmo
end

-- Gets the player's current weapon name.
function PlayerData.GetWeapon(player: Player): string
	local data = playerDataMap[player]
	if not data then
		return "BasicBlaster"
	end
	return data.CurrentWeapon
end

-- Returns current ammo count for the player.
function PlayerData.GetAmmo(player: Player): number
	local data = playerDataMap[player]
	if not data then
		return 0
	end
	return data.Ammo
end

-- Consumes one unit of ammo. Returns ammo remaining.
function PlayerData.UseAmmo(player: Player): number
	local data = playerDataMap[player]
	if not data then
		return 0
	end
	if data.Ammo > 0 then
		data.Ammo -= 1
	end
	return data.Ammo
end

-- Reloads ammo to max for the current weapon.
function PlayerData.ReloadAmmo(player: Player)
	local data = playerDataMap[player]
	if not data then
		return
	end
	local weaponConfig = GameConfig.Equipment[data.CurrentWeapon]
	if not weaponConfig then
		return
	end
	data.Ammo = weaponConfig.MaxAmmo
end

-- Records the wave number the player survived.
function PlayerData.SetWaveSurvived(player: Player, wave: number)
	local data = playerDataMap[player]
	if not data then
		return
	end
	data.WaveSurvived = wave
	UpdateWaveRemote:FireClient(player, wave)
end

-- Returns the player's survived wave count.
function PlayerData.GetWaveSurvived(player: Player): number
	local data = playerDataMap[player]
	if not data then
		return 0
	end
	return data.WaveSurvived
end

-- Marks that the player has started (spawned in lobby).
function PlayerData.SetStarted(player: Player)
	local data = playerDataMap[player]
	if not data then
		return
	end
	data.HasStarted = true
end

return PlayerData