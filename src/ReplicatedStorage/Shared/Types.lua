--[[
	Types.lua
	Type definitions for Luau type-checking support.
]]

export type CreatureConfig = {
	Name: string,
	Speed: number,
	Health: number,
	Damage: number,
	Reward: number,
	ModelPath: string?,
}

export type EquipmentConfig = {
	Name: string,
	Cost: number,
	Damage: number,
	FireRate: number,
	MaxAmmo: number,
	ReloadTime: number,
}

export type PlayerData = {
	Coins: number,
	CurrentWeapon: string,
	Ammo: number,
	WaveSurvived: number,
}

export type WaveConfig = {
	WaveNumber: number,
	TotalCreatures: number,
	StandardCount: number,
	SwiftCount: number,
	HeavyCount: number,
	SpawnDelay: number,
}

export type CreatureInstance = {
	Instance: Model,
	Health: number,
	MaxHealth: number,
	CreatureType: string,
	Speed: number,
	Damage: number,
	Reward: number,
	Target: Player?,
	Humanoid: Humanoid,
	RootPart: BasePart,
}

return {}