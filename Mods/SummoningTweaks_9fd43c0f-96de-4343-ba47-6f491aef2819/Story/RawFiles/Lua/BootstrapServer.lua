Ext.Require("Shared.lua")

---@class SummoningTweaksPersistentVars
local defaultPersistentVars = {
	MaxSummons = 3,
	SummonAmountPerAbility = 1,
	CopiedInfusions = {}
}

local function CopyTable(target)
	local tbl = {}
	for k,v in pairs(target) do
		tbl[k] = v
	end
	return tbl
end

---@type SummoningTweaksPersistentVars
PersistentVars = CopyTable(defaultPersistentVars)

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

InfusionCopyingData = {
	Skills = {},
	Statuses = {},
	LargeInfusionStatus = {}
}

Ext.RegisterListener("SessionLoaded", function()
	if PersistentVars == nil then
		PersistentVars = CopyTable(defaultPersistentVars)
	else
		for k,v in pairs(defaultPersistentVars) do
			if PersistentVars[k] == nil then
				PersistentVars[k] = v
			end
		end
	end
	if checkSessionLoaded then
		RegisterSettingsListener()
	end

	for i,v in pairs(Ext.GetStatEntries("StatusData")) do
		if not string.find(v, "LLSUMMONINF") then
			local stat = Ext.GetStat(v)
			if string.find(string.lower(v), "infusion") then
				InfusionCopyingData.Statuses[v] = true
			else
				if string.find(string.lower(stat.StatsId), "infusion") then
					InfusionCopyingData.Statuses[v] = true
				end
			end
			if InfusionCopyingData.Statuses[stat.Using] then
				InfusionCopyingData.LargeInfusionStatus[stat.Using] = v
			end
		end
	end

	for _,id in pairs(Ext.GetStatEntries("SkillData")) do
		if id ~= "Summon_Incarnate" then
			local stat = Ext.GetStat(id)
			if stat.SkillProperties then
				for _,prop in pairs(stat.SkillProperties) do
					if prop.Type == "Status" and InfusionCopyingData.Statuses[prop.Action] then
						if InfusionCopyingData.Skills[prop.Action] == nil then
							InfusionCopyingData.Skills[prop.Action] = {}
						end
						InfusionCopyingData.Skills[prop.Action][id] = true
					end
				end
			end
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
	if player then
		if type(PersistentVars.MaxSummons) ~= "number" then
			PersistentVars.MaxSummons = 3
		end
		if player.Stats.MaxSummons ~= PersistentVars.MaxSummons then
			local boost = PersistentVars.MaxSummons - player.Stats.DynamicStats[1].MaxSummons
			if boost > 0 then
				NRD_CharacterSetPermanentBoostInt(uuid, "MaxSummons", boost)
				player.Stats.MaxSummons = PersistentVars.MaxSummons
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
			if stat.SkillProperties then
				for _,v in pairs(stat.SkillProperties) do
					if v.Type == "Summon" then
						RefreshSkill(char, skill)
						break
					end
				end
			end
		end
	end
end)

local function OwnerHasInfusionSkill(owner, statusId)
	local skills = InfusionCopyingData.Skills[statusId]
	if skills then
		for id,b in pairs(skills) do
			if CharacterHasSkill(owner, id) == 1 then
				return true
			end
		end
	end
	return false
end

function CopyInfusions(owner, summon)
	local summon = Ext.GetCharacter(summon)
	if summon then
		local success = false
		PersistentVars.CopiedInfusions[owner] = {}
		for _,statusId in pairs(summon:GetStatuses()) do
			if InfusionCopyingData.Statuses[statusId] and OwnerHasInfusionSkill(owner, statusId) then
				PersistentVars.CopiedInfusions[owner][statusId] = true
				success = true
			end
		end
		if success then
			ShowNotification(owner, "LLSUMMONINF_Notification_InfusionsStored")
		else
			ShowNotification(owner, "LLSUMMONINF_Notification_NoInfusionsStored")
		end
	end
end

function ApplyInfusions(owner, summon)
	local statusIds = PersistentVars.CopiedInfusions[owner]
	if statusIds then
		for id,b in pairs(statusIds) do
			local targetStatus = id
			if IsTagged(summon, "INCARNATE_G") == 1 then
				local largeVersion = InfusionCopyingData.LargeInfusionStatus[id]
				if largeVersion then
					targetStatus = largeVersion
				end
			end
			ApplyStatus(summon, targetStatus, -1.0, 0, owner)
		end
	end
end