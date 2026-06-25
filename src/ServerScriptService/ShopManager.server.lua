--[[
	ShopManager.server.lua
	Handles equipment purchases. Validates coin balance server-side
	and processes weapon assignments. Listens for ShopPurchase RemoteEvent.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)
local PlayerData = require(script.Parent.PlayerData)

local ShopManager = {}

local ShopPurchaseRemote = Remotes.ShopPurchase

-- Returns the list of purchasable equipment.
function ShopManager.GetCatalog(): { { Name: string, Cost: number } }
	local catalog = {}
	for weaponKey, config in GameConfig.Equipment do
		table.insert(catalog, {
			Key = weaponKey,
			Name = config.Name,
			Cost = config.Cost,
		})
	end
	return catalog
end

-- Processes a purchase request from a client.
function ShopManager.ProcessPurchase(player: Player, weaponKey: string): (boolean, string)
	local weaponConfig = GameConfig.Equipment[weaponKey]
	if not weaponConfig then
		return false, "Unknown weapon"
	end

	if weaponConfig.Cost > 0 and not PlayerData.SpendCoins(player, weaponConfig.Cost) then
		return false, "Not enough coins"
	end

	PlayerData.SetWeapon(player, weaponKey)

	-- Refill ammo on purchase
	PlayerData.ReloadAmmo(player)

	return true, weaponConfig.Name
end

-- Connect remote event handler
ShopPurchaseRemote.OnServerInvoke = function(player: Player, weaponKey: string)
	local success, message = ShopManager.ProcessPurchase(player, weaponKey)
	return { Success = success, Message = message }
end

return ShopManager