---@type ModSettings
local settings = nil

---@param globalSettings GlobalSettings
local function SettingsLoaded(globalSettings)
	PersistentVars.MaxSummons = Settings.Global.Variables.MaxSummons.Value
	PersistentVars.SummonAmountPerAbility = Settings.Global.Variables.SummonAmountPerAbility.Value
end

local function InitSettings()
	---@type ModSettings
	local ModSettings = Mods.LeaderLib.Classes.ModSettingsClasses.ModSettings
	settings = ModSettings:Create("9fd43c0f-96de-4343-ba47-6f491aef2819")
	settings.Global:AddLocalizedFlag("LLSUMMONINF_InstantSummonCooldownDisabled")
	settings.Global:AddLocalizedVariable("MaxSummons", "LLSUMMONINF_Variables_MaxSummons", 3)
	--settings.Global:AddLocalizedVariable("SummonAmountPerAbility", "LLSUMMONINF_Variables_SummonAmountPerAbility", 1)

	Mods.LeaderLib.SettingsManager.AddSettings(settings)

	if Ext.IsServer() then
		local function ApplyToPersistentVars(id, value)
			if PersistentVars[id] then
				PersistentVars[id] = value
			end
			for player in Mods.LeaderLib.GameHelpers.Character.GetPlayers() do
				UpdateMaxSummons(player.MyGuid)
			end
		end
	
		settings.Global.Variables.MaxSummons:AddListener(ApplyToPersistentVars)
		--settings.Global.Variables.SummonAmountPerAbility:AddListener(ApplyToPersistentVars)
	end

	return settings
end

return InitSettings