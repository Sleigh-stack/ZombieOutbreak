--[[
	Remotes Module (init.lua)
	Creates and returns all RemoteEvents used for client-server communication.
	Each RemoteEvent is parented as a child of this module so they exist in the
	Roblox instance tree, while also being accessible via require().
]]

local Remotes = {}

local remoteNames = {
	"CreatureHit",
	"ShopPurchase",
	"UpdateCoins",
	"UpdateWave",
	"UpdateCreatureCount",
}

for _, name in remoteNames do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = script
	Remotes[name] = remote
end

return Remotes