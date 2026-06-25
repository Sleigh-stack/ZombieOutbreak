--[[
    WaveManager.server.lua
    Orchestrates the round flow: lobby, wave, and intermission states.
    Controls wave progression, creature count scaling, and special creature
    introduction based on wave number.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Remotes)
local PlayerData = require(script.Parent.PlayerData)

local UpdateWaveRemote = Remotes.UpdateWave
local UpdateCreatureCountRemote = Remotes.UpdateCreatureCount

local WaveManager = {}

-- State tracking
local currentState = "lobby" -- "lobby", "wave", "intermission"
local currentWave = 0
local totalCreaturesThisWave = 0
local creaturesRemaining = 0
local creaturesSpawned = 0
local waveActive = false
local isRunning = false

-- Module references (set externally)
local creatureSpawner = nil
local creatureAI = nil
local economy = nil

-- Connects dependencies from other modules.
function WaveManager.SetDependencies(spawner, ai, eco)
    creatureSpawner = spawner
    creatureAI = ai
    economy = eco
end

-- Starts the wave manager loop.
function WaveManager.Start()
    if isRunning then
        return
    end
    isRunning = true
    task.spawn(function()
        StartLobby()
    end)
end

-- === LOBBY STATE ===

function StartLobby()
    currentState = "lobby"
    currentWave = 0
    BroadcastWave(0, "Lobby")

    task.wait(GameConfig.LobbyCountdown)

    if not isRunning then return end
    StartWave()
end

-- === WAVE STATE ===

function StartWave()
    currentWave += 1
    currentState = "wave"
    waveActive = true
    creaturesSpawned = 0

    local waveConfig = BuildWaveConfig(currentWave)
    totalCreaturesThisWave = waveConfig.TotalCreatures
    creaturesRemaining = totalCreaturesThisWave

    BroadcastWave(currentWave, "Wave")
    UpdateCreatureCount()

    task.spawn(function()
        SpawnWaveCreatures(waveConfig)
    end)
end

-- Builds a wave configuration based on wave number.
function BuildWaveConfig(waveNumber)
    local baseCount = GameConfig.BaseCreatureCount
    local increasePerWave = GameConfig.CreatureIncreasePerWave
    local swiftInterval = GameConfig.SwiftWaveInterval
    local heavyInterval = GameConfig.HeavyWaveInterval

    local totalCount
    if waveNumber == 1 then
        totalCount = 10
    elseif waveNumber == 2 then
        totalCount = 15
    elseif waveNumber == 3 then
        totalCount = 20
    else
        totalCount = 20 + (waveNumber - 3) * increasePerWave
    end

    local standardCount = totalCount
    local swiftCount = 0
    local heavyCount = 0

    -- Add Swift creatures every 3 waves
    if waveNumber % swiftInterval == 0 then
        swiftCount = math.floor(totalCount * 0.3)
        standardCount -= swiftCount
    end

    -- Add Heavy creatures every 5 waves
    if waveNumber % heavyInterval == 0 then
        heavyCount = math.floor(totalCount * 0.2)
        standardCount -= heavyCount
    end

    -- Ensure at least some standard creatures
    if standardCount < 1 then
        standardCount = 1
    end

    -- Cap at max concurrent
    local maxConcurrent = GameConfig.MaxConcurrentCreatures
    if totalCount > maxConcurrent then
        local ratio = maxConcurrent / totalCount
        standardCount = math.floor(standardCount * ratio)
        swiftCount = math.floor(swiftCount * ratio)
        heavyCount = math.floor(heavyCount * ratio)
        totalCount = standardCount + swiftCount + heavyCount
    end

    return {
        WaveNumber = waveNumber,
        TotalCreatures = totalCount,
        StandardCount = standardCount,
        SwiftCount = swiftCount,
        HeavyCount = heavyCount,
        SpawnDelay = math.max(0.3, 1.5 - waveNumber * 0.02),
    }
end

-- Spawns all creatures for the wave with staggered timing.
function SpawnWaveCreatures(waveConfig)
    if not creatureSpawner then return end

    local spawnQueue = {}
    for i = 1, waveConfig.StandardCount do
        table.insert(spawnQueue, "Standard")
    end
    for i = 1, waveConfig.SwiftCount do
        table.insert(spawnQueue, "Swift")
    end
    for i = 1, waveConfig.HeavyCount do
        table.insert(spawnQueue, "Heavy")
    end

    -- Shuffle so creature types are mixed
    for i = #spawnQueue, 2, -1 do
        local j = math.random(1, i)
        spawnQueue[i], spawnQueue[j] = spawnQueue[j], spawnQueue[i]
    end

    local spawnIndex = 1
    while spawnIndex <= #spawnQueue and isRunning do
        local creatureType = spawnQueue[spawnIndex]
        local creature = creatureSpawner.SpawnCreature(creatureType, currentWave)
        if creature then
            creatureAI:TrackCreature(creature)
            creaturesSpawned += 1
        end
        spawnIndex += 1
        task.wait(waveConfig.SpawnDelay)

        -- Check if all existing creatures are dead (early completion check)
        if not isRunning then return end
    end
end

-- Called by CreatureAI when a creature is defeated.
function WaveManager.OnCreatureDefeated(creatureType: string, playerWhoKilled: Player?)
    creaturesRemaining -= 1
    UpdateCreatureCount()

    if playerWhoKilled and economy then
        economy.RewardCreatureKill(playerWhoKilled, creatureType)
    end

    if creaturesRemaining <= 0 and waveActive then
        OnWaveCompleted()
    end
end

-- Called when all creatures in the wave are defeated.
function OnWaveCompleted()
    waveActive = false

    -- Award wave completion bonus to all players
    if economy then
        for _, player in Players:GetPlayers() do
            economy.RewardWaveBonus(player)
            PlayerData.SetWaveSurvived(player, currentWave)
        end
    end

    currentState = "intermission"
    BroadcastWave(currentWave, "Intermission")

    task.wait(GameConfig.IntermissionDuration)

    if isRunning then
        StartWave()
    end
end

-- === HELPERS ===

function BroadcastWave(waveNumber: number, stateLabel: string)
    for _, player in Players:GetPlayers() do
        UpdateWaveRemote:FireClient(player, waveNumber, stateLabel)
    end
end

function UpdateCreatureCount()
    for _, player in Players:GetPlayers() do
        UpdateCreatureCountRemote:FireClient(player, creaturesRemaining)
    end
end

-- Public accessors
function WaveManager.GetCurrentWave(): number
    return currentWave
end

function WaveManager.GetState(): string
    return currentState
end

function WaveManager.GetCreaturesRemaining(): number
    return creaturesRemaining
end

-- Stops the wave manager cleanly.
function WaveManager.Stop()
    isRunning = false
    waveActive = false
end

return WaveManager