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
	settings.Global:AddFlags({
		"LLSUMMONINF_InvokeContractAutoAddDisabled",
		"LLSUMMONINF_ScaleCapWithSummoningLevel",
	})
	settings.Global:AddVariable("MaxSummons", 3)
	settings.Global:AddVariable("SummonAmountPerAbility", 1)

	---@param self SettingsData
	---@param name string
	---@param data VariableData
	settings.UpdateVariable = function(self, name, data)
		
	end
	Mods.LeaderLib.SettingsManager.AddSettings(settings)
	return settings
end

return InitSettings