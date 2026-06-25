--[[
	ShopController.client.lua
	Handles the shop user interface and purchase flow.
	Communicates with ShopManager via ShopPurchase RemoteEvent.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Remotes)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Player = Players.LocalPlayer

local ShopPurchaseRemote = Remotes.ShopPurchase

local ShopController = {}

local shopOpen = false

-- Opens or closes the shop UI.
function ShopController.ToggleShop()
	shopOpen = not shopOpen

	local playerGui = Player:WaitForChild("PlayerGui")
	local mainUI = playerGui:FindFirstChild("MainUI")
	if not mainUI then
		return
	end

	local shopFrame = mainUI:FindFirstChild("ShopFrame", true)
	if not shopFrame then
		return
	end

	shopFrame.Visible = shopOpen

	if shopOpen then
		ShopController.PopulateCatalog()
	end
end

-- Populates the shop UI with equipment listings.
function ShopController.PopulateCatalog()
	local playerGui = Player:WaitForChild("PlayerGui")
	local mainUI = playerGui:FindFirstChild("MainUI")
	if not mainUI then
		return
	end

	local catalogList = mainUI:FindFirstChild("ShopFrame"):FindFirstChild("CatalogList")
	if not catalogList then
		return
	end

	-- Clear existing entries
	for _, child in catalogList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Populate from config
	for weaponKey, config in GameConfig.Equipment do
		local entryFrame = Instance.new("Frame")
		entryFrame.Size = UDim2.new(1, 0, 0, 50)
		entryFrame.BackgroundTransparency = 0.8
		entryFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		entryFrame.BorderSizePixel = 1
		entryFrame.Parent = catalogList

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Font = Enum.Font.SourceSans
		nameLabel.TextSize = 20
		nameLabel.Text = ("%s"):format(config.Name)
		nameLabel.Parent = entryFrame

		local costLabel = Instance.new("TextLabel")
		costLabel.Size = UDim2.new(0.25, 0, 1, 0)
		costLabel.Position = UDim2.new(0.5, 0, 0, 0)
		costLabel.BackgroundTransparency = 1
		costLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
		costLabel.TextXAlignment = Enum.TextXAlignment.Center
		costLabel.Font = Enum.Font.SourceSans
		costLabel.TextSize = 20
		if config.Cost == 0 then
			costLabel.Text = "FREE"
		else
			costLabel.Text = ("%d Coins"):format(config.Cost)
		end
		costLabel.Parent = entryFrame

		local buyButton = Instance.new("TextButton")
		buyButton.Size = UDim2.new(0.25, 0, 1, 0)
		buyButton.Position = UDim2.new(0.75, 0, 0, 0)
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.Font = Enum.Font.SourceSansBold
		buyButton.TextSize = 18
		buyButton.Text = "Buy"

		buyButton.MouseButton1Click:Connect(function()
			ShopController.PurchaseWeapon(weaponKey)
		end)

		buyButton.Parent = entryFrame
	end
end

-- Sends a purchase request to the server.
function ShopController.PurchaseWeapon(weaponKey: string)
	local result = ShopPurchaseRemote:InvokeServer(weaponKey)
	if result and result.Success then
		print("Purchased:", result.Message)
		-- Update equipment controller
		local equipmentController = require(script.Parent:WaitForChild("EquipmentController"))
		equipmentController.EquipWeapon(weaponKey)
	else
		local failMsg = result and result.Message or "Purchase failed"
		warn("Shop:", failMsg)
	end
end

-- Keybind: B to open/close shop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		ShopController.ToggleShop()
	end
end)

return ShopController