--[[
    UIController.client.lua
    Manages UI updates on the client side. Listens to RemoteEvents
    and updates the GUI elements accordingly.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)
local Player = Players.LocalPlayer

-- Locate UI elements
local playerGui = Player:WaitForChild("PlayerGui")
local mainUI = playerGui:WaitForChild("MainUI")

-- Helper to find UI elements safely
local function FindUI(name: string): Instance?
    local frame = mainUI:FindFirstChild("MainFrame")
    if not frame then
        return nil
    end
    return frame:FindFirstChild(name, true)
end

-- Connect RemoteEvent listeners

Remotes.UpdateCoins.OnClientEvent:Connect(function(coins: number)
    local coinLabel = FindUI("CoinsLabel")
    if coinLabel and coinLabel:IsA("TextLabel") then
        coinLabel.Text = ("Coins: %d"):format(coins)
    end
end)

Remotes.UpdateWave.OnClientEvent:Connect(function(waveNumber: number, stateLabel: string)
    local waveLabel = FindUI("WaveLabel")
    if waveLabel and waveLabel:IsA("TextLabel") then
        if stateLabel == "Lobby" then
            waveLabel.Text = "Lobby - Waiting for players..."
        elseif stateLabel == "Intermission" then
            waveLabel.Text = ("Wave %d Complete! Next wave incoming..."):format(waveNumber)
        else
            waveLabel.Text = ("Wave %d"):format(waveNumber)
        end
    end

    local stateLabelUI = FindUI("StateLabel")
    if stateLabelUI and stateLabelUI:IsA("TextLabel") then
        stateLabelUI.Text = stateLabel
    end
end)

Remotes.UpdateCreatureCount.OnClientEvent:Connect(function(count: number)
    local creatureLabel = FindUI("CreaturesLabel")
    if creatureLabel and creatureLabel:IsA("TextLabel") then
        creatureLabel.Text = ("Creatures: %d"):format(count)
    end
end)

-- Update health display on heartbeat
RunService.Heartbeat:Connect(function()
    local character = Player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local healthBar = FindUI("HealthBar")
    if healthBar and healthBar:IsA("Frame") then
        local healthRatio = humanoid.Health / humanoid.MaxHealth
        healthBar.Size = UDim2.new(healthRatio, 0, 1, 0)

        -- Color code health
        if healthRatio > 0.5 then
            healthBar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        elseif healthRatio > 0.25 then
            healthBar.BackgroundColor3 = Color3.fromRGB(200, 200, 0)
        else
            healthBar.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        end
    end

    local healthLabel = FindUI("HealthLabel")
    if healthLabel and healthLabel:IsA("TextLabel") then
        healthLabel.Text = ("%d / %d"):format(math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
    end
end)

-- Ammo display update
local equipmentController = require(script.Parent.EquipmentController)

RunService.Heartbeat:Connect(function()
    local ammoLabel = FindUI("AmmoLabel")
    if not ammoLabel or not ammoLabel:IsA("TextLabel") then
        return
    end

    local ammo = equipmentController.GetCurrentAmmo()
    local maxAmmo = equipmentController.GetMaxAmmo()
    ammoLabel.Text = ("%d / %d"):format(ammo, maxAmmo)
end)

-- Intermission countdown display
local countdownLabel = FindUI("CountdownLabel")
if countdownLabel and countdownLabel:IsA("TextLabel") then
    countdownLabel.Text = ""
end

-- Track countdown from wave state changes
local countdownValue = 0
local countdownActive = false

Remotes.UpdateWave.OnClientEvent:Connect(function(waveNumber: number, stateLabel: string)
    if stateLabel == "Lobby" then
        countdownValue = 10
        countdownActive = true
    elseif stateLabel == "Intermission" then
        countdownValue = 15
        countdownActive = true
    elseif stateLabel == "Wave" then
        countdownActive = false
        if countdownLabel and countdownLabel:IsA("TextLabel") then
            countdownLabel.Text = ""
        end
    end
end)

-- Countdown tick
task.spawn(function()
    while true do
        task.wait(1)
        if countdownActive and countdownValue > 0 then
            countdownValue -= 1
            if countdownLabel and countdownLabel:IsA("TextLabel") then
                if countdownValue > 0 then
                    countdownLabel.Text = ("%d..."):format(countdownValue)
                else
                    countdownLabel.Text = ""
                end
            end
        end
    end
end)