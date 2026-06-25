--[[
	GameConfig.lua
	Central configuration. Adjust values here to rebalance without touching game scripts.
]]

local GameConfig = {
	-- Round flow
	IntermissionDuration = 15,
	LobbyCountdown = 10,
	WaveStartDelay = 3,

	-- Wave scaling
	BaseCreatureCount = 10,
	CreatureIncreasePerWave = 5,
	SwiftWaveInterval = 3,
	HeavyWaveInterval = 5,

	-- Maximum concurrent creatures to prevent server overload
	MaxConcurrentCreatures = 50,

	-- Creature AI
	CreatureSearchRadius = 100,
	CreatureAttackRange = 5,
	CreaturePathRecalcInterval = 2,
	CreatureLostTargetTimeout = 5,

	-- Economy
	CoinReward = {
		Standard = 10,
		Swift = 15,
		Heavy = 25,
	},
	WaveCompletionBonus = 50,
	StartingCoins = 0,

	-- Equipment stats
	Equipment = {
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

	-- Creature base stats (scaled at spawn)
	CreatureStats = {
		Standard = {
			Speed = 12,
			Health = 30,
			Damage = 10,
			Reward = 10,
		},
		Swift = {
			Speed = 24,
			Health = 20,
			Damage = 6,
			Reward = 15,
		},
		Heavy = {
			Speed = 7,
			Health = 80,
			Damage = 20,
			Reward = 25,
		},
	},

	-- Health scaling per wave (multiplier applied to base creature health)
	HealthScalingPerWave = 1.1,

	-- Player settings
	PlayerRespawnTime = 5,
	PlayerHealth = 100,
}

return GameConfig