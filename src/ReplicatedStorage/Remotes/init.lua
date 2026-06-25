-- Remotes/init.lua
-- Creates a Remotes folder in ReplicatedStorage and ensures all
-- required RemoteEvents exist before any gameplay code uses them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")

if not RemotesFolder then
RemotesFolder = Instance.new("Folder")
RemotesFolder.Name = "Remotes"
RemotesFolder.Parent = ReplicatedStorage
end

local RemoteNames = {
"CreatureHit",
"ShopPurchase",
"UpdateCoins",
"UpdateWave",
"UpdateCreatureCount",
}

local Remotes = {}

for _, RemoteName in ipairs(RemoteNames) do
local Remote = RemotesFolder:FindFirstChild(RemoteName)

```
if not Remote then
	Remote = Instance.new("RemoteEvent")
	Remote.Name = RemoteName
	Remote.Parent = RemotesFolder
end

Remotes[RemoteName] = Remote
```

end

return Remotes
