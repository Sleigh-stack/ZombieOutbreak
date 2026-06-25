--[[
	EquipmentController.client.lua
	Handles client-side equipment: shooting, ammo management, reloading.
	Fire events are sent to server via CreatureHit RemoteEvent.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)
local Player = Players.LocalPlayer

local CreatureHitRemote = Remotes.CreatureHit

local EquipmentController = {}

-- State (module-level so UIController can read via require)
local currentWeaponKey = "BasicBlaster"
local currentAmmo = GameConfig.Equipment.BasicBlaster.MaxAmmo
local currentMaxAmmo = GameConfig.Equipment.BasicBlaster.MaxAmmo
local lastFireTime = 0
local isReloading = false
local reloadTimer = nil

-- Returns current ammo count.
function EquipmentController.GetCurrentAmmo(): number
	return currentAmmo
end

-- Returns max ammo for current weapon.
function EquipmentController.GetMaxAmmo(): number
	return currentMaxAmmo
end

-- Returns current weapon key.
function EquipmentController.GetCurrentWeapon(): string
	return currentWeaponKey
end

-- Equips a new weapon and resets ammo.
function EquipmentController.EquipWeapon(weaponKey: string)
	local config = GameConfig.Equipment[weaponKey]
	if not config then
		return
	end
	currentWeaponKey = weaponKey
	currentMaxAmmo = config.MaxAmmo
	currentAmmo = config.MaxAmmo
	isReloading = false
	if reloadTimer then
		reloadTimer:Cancel()
		reloadTimer = nil
	end
end

-- Starts the reload process.
function EquipmentController.StartReload()
	if isReloading then
		return
	end
	local config = GameConfig.Equipment[currentWeaponKey]
	if not config then
		return
	end
	if currentAmmo >= config.MaxAmmo then
		return
	end

	isReloading = true

	-- Reload timer
	reloadTimer = task.delay(config.ReloadTime, function()
		currentAmmo = config.MaxAmmo
		isReloading = false
	end)
end

-- Attempts to fire the weapon. Returns true if shot was fired.
function EquipmentController.TryFire(): boolean
	if isReloading then
		return false
	end

	local config = GameConfig.Equipment[currentWeaponKey]
	if not config then
		return false
	end

	if currentAmmo <= 0 then
		-- Auto-reload when empty
		EquipmentController.StartReload()
		return false
	end

	local now = tick()
	local fireRate = config.FireRate
	if now - lastFireTime < fireRate then
		return false
	end

	lastFireTime = now
	currentAmmo -= 1

	return true
end

-- Fires a hit event at a specific creature.
function EquipmentController.HitCreature(creature: Model)
	local config = GameConfig.Equipment[currentWeaponKey]
	if not config then
		return
	end

	CreatureHitRemote:FireServer(creature, config.Damage)
end

-- Reload keybind (R key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		EquipmentController.StartReload()
	end
end)

-- Mouse click to fire
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Fire is handled per-frame via a mouse target system
	end
end)

-- Mouse target detection (click to shoot)
RunService.RenderStepped:Connect(function()
	local character = Player.Character
	if not character then
		return
	end

	if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		return
	end

	local success = EquipmentController.TryFire()
	if not success then
		return
	end

	-- Cast a ray from camera to mouse position
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
	if result and result.Instance then
		local hitPart = result.Instance
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChild("CreatureType") then
			EquipmentController.HitCreature(model)
		end
	end
end)

return EquipmentController