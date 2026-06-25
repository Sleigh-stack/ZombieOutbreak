--[[
	Constants.lua
	Shared constants used across all game systems.
]]

local Constants = {
	-- Round flow timings (seconds)
	LOBBY_COUNTDOWN = 10,
	INTERMISSION_DURATION = 15,
	WAVE_START_DELAY = 3,

	-- Wave scaling
	BASE_CREATURE_COUNT = 10,
	CREATURES_PER_WAVE_INCREASE = 5,
	SWIFT_WAVE_INTERVAL = 3,
	HEAVY_WAVE_INTERVAL = 5,

	-- Economy
	COIN_REWARD_STANDARD = 10,
	COIN_REWARD_SWIFT = 15,
	COIN_REWARD_HEAVY = 25,
	WAVE_COMPLETION_BONUS = 50,

	-- Equipment
	EQUIPMENT = {
		BasicBlaster = {
			Name = "Basic Blaster",
			Cost = 0,
			Damage = 15,
			FireRate = 0.5,
			MaxAmmo = 30,
			ReloadTime = 2,
		},
		RapidBlaster = {
			Name = "Rapid Blaster",
			Cost = 250,
			Damage = 8,
			FireRate = 0.15,
			MaxAmmo = 50,
			ReloadTime = 2.5,
		},
		HeavyBlaster = {
			Name = "Heavy Blaster",
			Cost = 500,
			Damage = 40,
			FireRate = 1.2,
			MaxAmmo = 15,
			ReloadTime = 3.5,
		},
	},

	-- RemoteEvent names
	REMOTES = {
		CreatureHit = "CreatureHit",
		ShopPurchase = "ShopPurchase",
		UpdateCoins = "UpdateCoins",
		UpdateWave = "UpdateWave",
		UpdateCreatureCount = "UpdateCreatureCount",
	},

	-- Player
	PLAYER_RESPAWN_TIME = 5,
	STARTING_COINS = 0,
}

return Constants