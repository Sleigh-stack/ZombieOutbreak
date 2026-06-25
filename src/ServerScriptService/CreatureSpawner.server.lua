--[[
    CreatureSpawner.server.lua
    Handles creature spawning from defined spawn points.
    Retrieves creature configurations and creates creature models in the world.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CreatureConfigs = require(ReplicatedStorage.Assets.CreatureConfigs)

local CreatureSpawner = {}

local spawnPoints = Workspace:WaitForChild("CreatureSpawns")

-- Cache of spawn point parts
local spawnPartList: { BasePart } = {}

-- Refreshes the spawn point list from the CreatureSpawns folder.
function CreatureSpawner.RefreshSpawnPoints()
    spawnPartList = {}
    for _, child in spawnPoints:GetChildren() do
        if child:IsA("BasePart") or child:IsA("Part") then
            table.insert(spawnPartList, child)
        end
    end
end

-- Returns a random spawn point position.
function CreatureSpawner.GetRandomSpawnPosition(): Vector3?
    if #spawnPartList == 0 then
        return nil
    end
    local spawnPart = spawnPartList[math.random(1, #spawnPartList)]
    return spawnPart.Position + Vector3.new(0, 2, 0)
end

--[[
    Creates a creature model in the workspace.
    Uses a simple part-based proxy model since actual meshes would require
    external assets. To replace with custom models, change the CreateModel function.
    Returns the creature's root part, humanoid, and config.
]]
function CreatureSpawner.SpawnCreature(creatureType: string, waveNumber: number): { Instance: Model, Health: number, MaxHealth: number, CreatureType: string, Speed: number, Damage: number, Reward: number, Humanoid: Humanoid, RootPart: BasePart }?
    local config = CreatureConfigs.GetConfig(creatureType)
    if not config then
        warn("CreatureSpawner: Unknown creature type:", creatureType)
        return nil
    end

    local spawnPos = CreatureSpawner.GetRandomSpawnPosition()
    if not spawnPos then
        warn("CreatureSpawner: No spawn points available")
        return nil
    end

    -- Apply health scaling per wave
    local healthScale = GameConfig.HealthScalingPerWave ^ (waveNumber - 1)
    local scaledHealth = math.floor(config.Health * healthScale)

    -- Create the creature model
    local model = Instance.new("Model")
    model.Name = ("%s_%d"):format(creatureType, tick())

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = scaledHealth
    humanoid.Health = scaledHealth
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model

    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(3, 4, 2)
    rootPart.Anchored = false
    rootPart.CanCollide = true
    rootPart.Position = spawnPos
    rootPart.BrickColor = BrickColor.new("Bright red")
    rootPart.Parent = model

    local headPart = Instance.new("Part")
    headPart.Name = "Head"
    headPart.Size = Vector3.new(2, 2, 2)
    headPart.Anchored = false
    headPart.CanCollide = false
    headPart.BrickColor = BrickColor.new("Dark red")
    headPart.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = headPart
    weld.Part1 = rootPart
    weld.Parent = model

    -- Tag the creature type
    local attribute = Instance.new("StringValue")
    attribute.Name = "CreatureType"
    attribute.Value = creatureType
    attribute.Parent = model

    model.Parent = Workspace

    return {
        Instance = model,
        Health = scaledHealth,
        MaxHealth = scaledHealth,
        CreatureType = creatureType,
        Speed = config.Speed,
        Damage = config.Damage,
        Reward = config.Reward,
        Humanoid = humanoid,
        RootPart = rootPart,
    }
end

-- Initial setup
CreatureSpawner.RefreshSpawnPoints()

-- Re-scan spawn points when new ones are added
spawnPoints.ChildAdded:Connect(function()
    CreatureSpawner.RefreshSpawnPoints()
end)

return CreatureSpawner