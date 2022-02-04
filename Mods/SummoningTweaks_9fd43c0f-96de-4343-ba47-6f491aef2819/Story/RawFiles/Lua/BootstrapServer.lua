Ext.Require("Shared.lua")

PersistentVars = {
	MaxSummons = 3,
	SummonAmountPerAbility = 1
}

local checkSessionLoaded = false

local function RegisterSettingsListener()
	if Mods.LeaderLib ~= nil then
		Mods.LeaderLib.RegisterListener("ModSettingsLoaded", ModuleUUID, function ()
			---@type ModSettings
			local settings = Mods.LeaderLib.SettingsManager.GetMod(ModuleUUID, false)
			if settings and settings.Global.Variables.MaxSummons then
				settings.Global.Variables.MaxSummons:AddListener(function (id, value)
					if Ext.OsirisIsCallable() then
						PersistentVars.MaxSummons = value
						for player in Mods.LeaderLib.GameHelpers.Character.GetPlayers() do
							UpdateMaxSummons(player.MyGuid)
						end
					end
				end)
			end
		end)
	else
		checkSessionLoaded = true
	end
end

RegisterSettingsListener()

Ext.RegisterListener("SessionLoaded", function()
	if PersistentVars == nil then
		PersistentVars = {
			MaxSummons = 3,
			SummonAmountPerAbility = 1
		}
	else
		if PersistentVars.MaxSummons == nil then
			PersistentVars.MaxSummons = 3
		end
		if PersistentVars.SummonAmountPerAbility == nil then
			PersistentVars.SummonAmountPerAbility = 1
		end
	end
	if checkSessionLoaded then
		RegisterSettingsListener()
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
	if player then
		if player.Stats.MaxSummons ~= PersistentVars.MaxSummons then
			local boost = PersistentVars.MaxSummons - player.Stats.DynamicStats[1].MaxSummons
			if boost > 0 then
				NRD_CharacterSetPermanentBoostInt(uuid, "MaxSummons", boost)
				CharacterAddAttribute(uuid, "Dummy", 0)
			end
		end
	end
end

function ClearMaxSummons(uuid)
	NRD_CharacterSetPermanentBoostInt(uuid, "MaxSummons", 0)
	CharacterAddAttribute(uuid, "Dummy", 0)
end

Ext.AddPathOverride("Public/SummoningTweaks_9fd43c0f-96de-4343-ba47-6f491aef2819/Scripts/LLSUMMONINF_Main.gameScript", "Public/SummoningTweaks_9fd43c0f-96de-4343-ba47-6f491aef2819/Scripts/LLSUMMONINF_MainDisabled.gameScript")

local function RefreshSkill(char, skill)
	NRD_SkillSetCooldown(char, skill, 0.0)
	if Mods.LeaderLib then
		Mods.LeaderLib.Timer.StartOneshot("", 250, function()
			NRD_SkillSetCooldown(char, skill, 0)
		end)
	end
end

Ext.RegisterOsirisListener("SkillCast", 4, "after", function (char, skill, skillType, skillElement)
	if CharacterIsInCombat(char) == 0
	and CharacterIsPlayer(char) == 1
	and GlobalGetFlag("LLSUMMONINF_InstantSummonCooldownDisabled") == 0
	then
		if skillType == "summon" then
			RefreshSkill(char, skill)
		else
			local stat = Ext.GetStat(skill)
			for _,v in pairs(stat.SkillProperties) do
				if v.Type == "Summon" then
					RefreshSkill(char, skill)
					break
				end
			end
		end
	end
end)