PersistentVars = {
	MaxSummons = 3,
	SummonAmountPerAbility = 1
}

---@type ModSettings
Settings = nil
local initSettings = Ext.Require("LeaderLibGlobalSettings.lua")

Ext.RegisterListener("SessionLoaded", function()
	if Mods.LeaderLib ~= nil then
		local b,result = xpcall(initSettings, debug.traceback)
		if not b then
			Ext.PrintError(result)
		else
			Settings = result
		end
	end
end)

function SummonTemplateAtPosition(player, template, xs, ys, zs, lifetimestr, totemstr)
	local x = tonumber(xs)
	local y = tonumber(ys)
	local z = tonumber(zs)
	local lifetime = tonumber(lifetimestr)
	local totem = tonumber(totemstr)
	local level = CharacterGetLevel(player)
	--Ext.Print("NRD_Summon: "..player, template, x, y, z, lifetime, level, totem)
	local summon = NRD_Summon(player, template, x, y, z, lifetime, level, totem, 1)
	--local summon = NRD_Summon("S_GLO_CharacterCreationDummy_001_da072fe7-fdd5-42ae-9139-8bd4b9fca406", "13f9314d-e744-4dc5-acf2-c6bf77a04892", 0, 0, 0, 60.0, 10, 0, 1)
	--local last_underscore = string.find(template, "_[^_]*$")
	--local stripped_template = string.sub(template, last_underscore+1)
	--Osi.LLSUMMONINF_SummonTemplateAtPosition_Go(player, stripped_template, x, y, z, lifetime, totem)
	--PlayEffectAtPosition("RS3_FX_UI_Icon_SkipTurn_UsedScroll_01", x, y + 2.0, z)
	PlayEffect(summon, "RS3_FX_UI_Icon_SkipTurn_UsedScroll_01", "Dummy_OverheadFX")
	PlayEffectAtPosition("LLSUMMONINF_Skills_InvokeContract_Cast_Summon_01", x, y, z)
	PlayEffectAtPosition("RS3_FX_Skills_Totem_Target_Nebula_01", x, y, z)
end

function UpdateMaxSummons(uuid)
	local player = Ext.GetCharacter(uuid)
	Ext.EnableExperimentalPropertyWrites()
	player.Stats.MaxSummons = PersistentVars.MaxSummons
end

function ClearMaxSummons(uuid)
	local player = Ext.GetCharacter(uuid)
	Ext.EnableExperimentalPropertyWrites()
	player.Stats.MaxSummons = 0
end

Ext.AddPathOverride("Public/SummoningTweaks_9fd43c0f-96de-4343-ba47-6f491aef2819/Scripts/LLSUMMONINF_Main.gameScript", "Public/SummoningTweaks_9fd43c0f-96de-4343-ba47-6f491aef2819/Scripts/LLSUMMONINF_MainDisabled.gameScript")