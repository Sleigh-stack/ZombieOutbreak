--[[
	Utility.lua
	Shared utility functions for math, tables, and general helpers.
]]

local Utility = {}

-- Returns a random integer between min and max (inclusive).
function Utility.RandomInt(min: number, max: number): number
	return math.random(min, max)
end

-- Returns a random element from a list.
function Utility.RandomChoice(list: { any }): any
	return list[math.random(1, #list)]
end

-- Clamps a value between min and max.
function Utility.Clamp(value: number, min: number, max: number): number
	return math.max(min, math.min(max, value))
end

-- Linear interpolation between a and b by t.
function Utility.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Rounds a number to the nearest integer.
function Utility.Round(value: number): number
	return math.floor(value + 0.5)
end

-- Formats a number with commas for display.
function Utility.FormatNumber(value: number): string
	local formatted = tostring(math.floor(value))
	local result = ""
	local count = 0
	for i = #formatted, 1, -1 do
		count += 1
		result = string.sub(formatted, i, i) .. result
		if count % 3 == 0 and i > 1 then
			result = "," .. result
		end
	end
	return result
end

-- Deep copies a table (non-recursive for simple tables).
function Utility.CopyTable(t: { any }): { any }
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

-- Checks if a part is within a given distance from another part.
function Utility.IsInRange(partA: BasePart, partB: BasePart, distance: number): boolean
	if not partA or not partB then
		return false
	end
	return (partA.Position - partB.Position).Magnitude <= distance
end

return Utility