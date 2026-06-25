--[[
	CreatureAI.server.lua
	Manages creature pathfinding, targeting, and attacks.
	Uses Roblox PathfindingService for navigation.
	Updated on a throttled loop (3 times/second).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CreatureAI = {}

-- Active creature list
local activeCreatures = {} :: { { Instance: Model, Health: number, MaxHealth: number, CreatureType: string, Speed: number, Damage: number, Reward: number, Target: Player?, Humanoid: Humanoid, RootPart: BasePart, Path: Path, NextRecalc: number, LastAttack: number, TargetLostTime: number? } }

-- Reference to WaveManager (set externally)
local waveManager = nil

function CreatureAI.SetWaveManager(wm)
	waveManager = wm
end

-- Adds a creature to active tracking.
function CreatureAI.TrackCreature(creatureData)
	table.insert(activeCreatures, creatureData)
end

-- Removes a creature from active tracking.
function CreatureAI.RemoveCreature(creatureData)
	for i, data in activeCreatures do
		if data == creatureData then
			table.remove(activeCreatures, i)
			return
		end
	end
end

-- Finds the nearest alive player to a given position.
function FindNearestPlayer(position: Vector3): Player?
	local nearestPlayer = nil
	local nearestDist = math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			continue
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if not rootPart then
			continue
		end

		local dist = (position - rootPart.Position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearestPlayer = player
		end
	end

	return nearestPlayer
end

-- Moves a creature along a path toward its target.
function MoveCreature(creatureData, targetPosition: Vector3)
	local humanoid = creatureData.Humanoid
	local rootPart = creatureData.RootPart
	if not humanoid or not rootPart then
		return
	end

	humanoid.WalkSpeed = creatureData.Speed

	local now = tick()

	if not creatureData.Path or now > (creatureData.NextRecalc or 0) then
		creatureData.NextRecalc = now + GameConfig.CreaturePathRecalcInterval

		local pathParams = {
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			AgentMaxSlope = 45,
		}

		local path = PathfindingService:CreatePath(pathParams)
		local success = pcall(function()
			path:ComputeAsync(rootPart.Position, targetPosition)
		end)

		if success and path.Status == Enum.PathStatus.Success then
			creatureData.Path = path
			local waypoints = path:GetWaypoints()
			for _, wp in waypoints do
				if wp.Action == Enum.PathWaypointAction.Jump then
					humanoid.Jump = true
				end
			end
			humanoid:MoveTo(targetPosition)
		end
	else
		humanoid:MoveTo(targetPosition)
	end
end

-- Makes the creature attack its current target.
function AttackTarget(creatureData)
	local target = creatureData.Target
	if not target then
		return
	end

	local character = target.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		creatureData.Target = nil
		return
	end

	local now = tick()
	local attackCooldown = 1.5
	if now < (creatureData.LastAttack or 0) + attackCooldown then
		return
	end
	creatureData.LastAttack = now

	humanoid:TakeDamage(creatureData.Damage)
end

-- Main AI update loop. Runs on a throttled timer.
function CreatureAI.StartAILoop()
	task.spawn(function()
		while true do
			task.wait(0.3)

			local i = 1
			while i <= #activeCreatures do
				local data = activeCreatures[i]

				-- Skip dead or orphaned creatures (Main's Died handler removes them)
				if not data.Instance or not data.Instance.Parent then
					table.remove(activeCreatures, i)
					continue
				end

				local humanoid = data.Humanoid
				if not humanoid or humanoid.Health <= 0 then
					table.remove(activeCreatures, i)
					continue
				end

				local rootPart = data.RootPart
				if not rootPart then
					i += 1
					continue
				end

				-- Find or update target
				local target = data.Target
				local targetValid = false

				if target then
					local character = target.Character
					if character and character:FindFirstChild("HumanoidRootPart") then
						local targetHumanoid = character:FindFirstChildOfClass("Humanoid")
						if targetHumanoid and targetHumanoid.Health > 0 then
							local tRoot = character:FindFirstChild("HumanoidRootPart") :: BasePart
							local dist = (rootPart.Position - tRoot.Position).Magnitude
							if dist <= GameConfig.CreatureSearchRadius then
								targetValid = true
							end
						end
					end
				end

				if not targetValid then
					if data.Target then
						data.TargetLostTime = tick()
					end
					data.Target = nil

					if not data.TargetLostTime or tick() - data.TargetLostTime > GameConfig.CreatureLostTargetTimeout then
						data.Target = FindNearestPlayer(rootPart.Position)
						data.TargetLostTime = nil
					end
				end

				-- Move toward target or attack if in range
				if data.Target then
					local character = data.Target.Character
					if character and character:FindFirstChild("HumanoidRootPart") then
						local tRoot = character:FindFirstChild("HumanoidRootPart") :: BasePart
						local dist = (rootPart.Position - tRoot.Position).Magnitude

						if dist <= GameConfig.CreatureAttackRange then
							humanoid:MoveTo(rootPart.Position)
							AttackTarget(data)
						else
							MoveCreature(data, tRoot.Position)
						end
					end
				elseif not data.TargetLostTime then
					data.TargetLostTime = tick()
				end

				i += 1
			end
		end
	end)
end

-- Removes all active creatures (used on server shutdown or clean reset).
function CreatureAI.ClearAllCreatures()
	for _, data in activeCreatures do
		if data.Instance and data.Instance.Parent then
			data.Instance:Destroy()
		end
	end
	activeCreatures = {}
end

-- Returns the count of currently active creatures.
function CreatureAI.GetActiveCreatureCount(): number
	return #activeCreatures
end

return CreatureAI