--[[
	Economy.server.lua
	Manages coin rewards for creature kills and wave completions.
	Provides an interface for other modules to grant rewards.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)

local Economy = {}

-- Rewards a player coins for defeating a creature.
-- creatureType: string matching creature config key.
function Economy.RewardCreatureKill(player: Player, creatureType: string)
	local reward = GameConfig.CoinReward[creatureType]
	if not reward then
		reward = GameConfig.CoinReward.Standard
	end
	PlayerData.AddCoins(player, reward)
end

-- Rewards a player the wave completion bonus.
function Economy.RewardWaveBonus(player: Player)
	PlayerData.AddCoins(player, GameConfig.WaveCompletionBonus)
end

-- Returns the coin reward amount for a creature type.
function Economy.GetKillReward(creatureType: string): number
	return GameConfig.CoinReward[creatureType] or GameConfig.CoinReward.Standard
end

return Economy