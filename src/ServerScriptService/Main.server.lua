--[[
	Main.server.lua
	Bootstraps all server-side systems. Requires all modules and wires
	dependencies together. This is the entry point for server execution.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load all server modules
local PlayerData = require(ServerScriptService.PlayerData)
local WaveManager = require(ServerScriptService.WaveManager)
local CreatureSpawner = require(ServerScriptService.CreatureSpawner)
local CreatureAI = require(ServerScriptService.CreatureAI)
local Economy = require(ServerScriptService.Economy)
local ShopManager = require(ServerScriptService.ShopManager)
local Remotes = require(ReplicatedStorage.Remotes)

-- Wire dependencies
WaveManager.SetDependencies(CreatureSpawner, CreatureAI, Economy)
CreatureAI.SetWaveManager(WaveManager)

-- Track last attacker per creature for kill credit
local creatureLastAttacker = {} :: { [Model]: Player }

-- Override CreatureSpawner.SpawnCreature to attach death handling and kill credit
local originalSpawn = CreatureSpawner.SpawnCreature
CreatureSpawner.SpawnCreature = function(creatureType, waveNumber)
	local creatureData = originalSpawn(CreatureSpawner, creatureType, waveNumber)
	if not creatureData then
		return nil
	end

	local humanoid = creatureData.Humanoid
	local creatureModel = creatureData.Instance

	-- On death: award kill credit, notify WaveManager, destroy model, remove from AI tracking
	humanoid.Died:Connect(function()
		local killer = creatureLastAttacker[creatureModel]
		creatureLastAttacker[creatureModel] = nil

		if killer then
			PlayerData.AddCoins(killer, creatureData.Reward)
		end

		WaveManager.OnCreatureDefeated(creatureData.CreatureType, killer)
		CreatureAI.RemoveCreature(creatureData)

		if creatureModel and creatureModel.Parent then
			creatureModel:Destroy()
		end
	end)

	return creatureData
end

-- Handle CreatureHit: validate and apply damage server-side
Remotes.CreatureHit.OnServerEvent:Connect(function(player: Player, creature: Model, damage: number)
	if typeof(damage) ~= "number" or damage <= 0 or damage > 200 then
		warn("Main: Invalid damage value from", player)
		return
	end

	if not creature or not creature.Parent then
		return
	end

	local creatureTypeValue = creature:FindFirstChild("CreatureType")
	if not creatureTypeValue then
		return
	end

	local humanoid = creature:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Track who last damaged this creature for kill credit
	creatureLastAttacker[creature] = player

	humanoid:TakeDamage(damage)
end)

-- Handle player joining
Players.PlayerAdded:Connect(function(player: Player)
	player:LoadCharacter()

	task.wait(0.5)

	PlayerData.InitPlayer(player)
	PlayerData.SetStarted(player)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player: Player)
	PlayerData.RemovePlayer(player)
end)

-- Wait for at least one player before starting wave loop
local function WaitForPlayers()
	while #Players:GetPlayers() == 0 do
		task.wait(1)
	end
end

WaitForPlayers()

-- Start game systems
CreatureAI.StartAILoop()
WaveManager.Start()

print("ProjectOutbreak: All systems initialized.")