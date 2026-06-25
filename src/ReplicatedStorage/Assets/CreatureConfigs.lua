--[[
	CreatureConfigs.lua
	Configuration-driven creature type definitions.
	Add new creature types by extending this table.
]]

local CreatureConfigs = {
	Standard = {
		Name = "Standard Infected",
		Speed = 12,
		Health = 30,
		Damage = 10,
		Reward = 10,
		-- optional: ModelPath = "rbxassetid://1234567890"
	},
	Swift = {
		Name = "Swift Infected",
		Speed = 24,
		Health = 20,
		Damage = 6,
		Reward = 15,
	},
	Heavy = {
		Name = "Heavy Infected",
		Speed = 7,
		Health = 80,
		Damage = 20,
		Reward = 25,
	},
}

-- Returns a deep copy of a creature config to prevent mutation.
function CreatureConfigs.GetConfig(creatureType: string): { any }?
	local config = CreatureConfigs[creatureType]
	if not config then
		return nil
	end
	local copy = {}
	for k, v in pairs(config) do
		copy[k] = v
	end
	return copy
end

-- Returns a list of all creature type keys.
function CreatureConfigs.GetAllTypes(): { string }
	local types = {}
	for key in pairs(CreatureConfigs) do
		if key ~= "GetConfig" and key ~= "GetAllTypes" then
			table.insert(types, key)
		end
	end
	return types
end

return CreatureConfigs