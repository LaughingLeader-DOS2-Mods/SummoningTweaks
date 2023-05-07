Ext.Require("Shared.lua")

local _EXTVERSION = Ext.Utils.Version()
local _DEBUG = Ext.Debug.IsDeveloperMode()

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
	checkSessionLoaded = true
	if Mods.LeaderLib ~= nil then
		Mods.LeaderLib.Events.ModSettingsChanged:Subscribe(function (e)
			PersistentVars.MaxSummons = e.Value
			for player in Mods.LeaderLib.GameHelpers.Character.GetPlayers() do
				UpdateMaxSummons(player.MyGuid, true)
			end
		end, {MatchArgs={ModuleUUID=ModuleUUID, ID="MaxSummons"}})
	end
end

RegisterSettingsListener()

InfusionCopyingData = {
	Skills = {},
	Statuses = {},
	LargeInfusionStatus = {}
}

Ext.Events.SessionLoaded:Subscribe(function()
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

	for i,v in pairs(Ext.Stats.GetStats("StatusData")) do
		if not string.find(v, "LLSUMMONINF") then
			local stat = Ext.Stats.Get(v, nil, false) --[[@as StatEntryStatusData]]
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

	for _,id in pairs(Ext.Stats.GetStats("SkillData")) do
		if id ~= "Summon_Incarnate" then
			local stat = Ext.Stats.Get(id, nil, false) --[[@as StatEntrySkillData]]
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

---@param player Guid
---@param template Guid
---@param xs string
---@param ys string
---@param zs string
---@param lifetimestr string
---@param totemstr string
function SummonTemplateAtPosition(player, template, xs, ys, zs, lifetimestr, totemstr)
	local x = tonumber(xs)
	local y = tonumber(ys)
	local z = tonumber(zs)
	local lifetime = tonumber(lifetimestr)
	local totem = tonumber(totemstr)
	local level = Osi.CharacterGetLevel(player)
	--Ext.Utils.Print("NRD_Summon: "..player, template, x, y, z, lifetime, level, totem)
	local summon = Osi.NRD_Summon(player, template, x, y, z, lifetime, level, totem, 1)
	--local summon = NRD_Summon("S_GLO_CharacterCreationDummy_001_da072fe7-fdd5-42ae-9139-8bd4b9fca406", "13f9314d-e744-4dc5-acf2-c6bf77a04892", 0, 0, 0, 60.0, 10, 0, 1)
	--local last_underscore = string.find(template, "_[^_]*$")
	--local stripped_template = string.sub(template, last_underscore+1)
	--Osi.LLSUMMONINF_SummonTemplateAtPosition_Go(player, stripped_template, x, y, z, lifetime, totem)
	--PlayEffectAtPosition("RS3_FX_UI_Icon_SkipTurn_UsedScroll_01", x, y + 2.0, z)
	Osi.PlayEffect(summon, "RS3_FX_UI_Icon_SkipTurn_UsedScroll_01", "Dummy_OverheadFX")
	Osi.PlayEffectAtPosition("LLSUMMONINF_Skills_InvokeContract_Cast_Summon_01", x, y, z)
	Osi.PlayEffectAtPosition("RS3_FX_Skills_Totem_Target_Nebula_01", x, y, z)
end

--local me = Ext.GetCharacter(CharacterGetHostCharacter()); print(me.Stats.MaxSummons)
--RemoveStatus(CharacterGetHostCharacter(), "LLSUMMONINF_MAX_SUMMONS_INC")
---@param uuid Guid
---@param skipUpdatingSettings? boolean
function UpdateMaxSummons(uuid, skipUpdatingSettings)
	local player = Ext.Entity.GetCharacter(uuid)
	if player then
		Osi.RemoveStatus(player.MyGuid, "LLSUMMONINF_MAX_SUMMONS_INC")
		if type(PersistentVars.MaxSummons) ~= "number" then
			PersistentVars.MaxSummons = 3
		end
		if not skipUpdatingSettings and Mods.LeaderLib then
			---@type ModSettings
			local settings = Mods.LeaderLib.SettingsManager.GetMod(ModuleUUID, false, true)
			if settings then
				PersistentVars.MaxSummons = settings.Global:GetVariable("MaxSummons", PersistentVars.MaxSummons)
			end
		end
		local boost = PersistentVars.MaxSummons - player.Stats.DynamicStats[1].MaxSummons
		if player.Stats.DynamicStats[2].MaxSummons ~= boost then
			if _DEBUG then
				Ext.Utils.PrintWarning(string.format("[SummoningTweaks] Setting MaxSummons for (%s) to (%i)", player.DisplayName, PersistentVars.MaxSummons))
			end
			player.Stats.DynamicStats[2].MaxSummons = boost
		end
		if Ext.Osiris.IsCallable() then
			Osi.CharacterAddAttribute(uuid, "Dummy", 0)
			Osi.ApplyStatus(player.MyGuid, "LLSUMMONINF_MAX_SUMMONS_INC", 0.0, 0, player.MyGuid)
		else
			local status = Ext.PrepareStatus(player.Handle, "LLSUMMONINF_MAX_SUMMONS_INC", 0.0)
			Ext.ApplyStatus(status)
		end
	end
end

---@param uuid Guid
function ClearMaxSummons(uuid)
	Osi.NRD_CharacterSetPermanentBoostInt(uuid, "MaxSummons", 0)
	Osi.CharacterAddAttribute(uuid, "Dummy", 0)
	Osi.RemoveStatus(uuid, "LLSUMMONINF_MAX_SUMMONS_INC")
end

Ext.IO.AddPathOverride("Public/SummoningTweaks_9fd43c0f-96de-4343-ba47-6f491aef2819/Scripts/LLSUMMONINF_Main.gameScript", "Public/SummoningTweaks_9fd43c0f-96de-4343-ba47-6f491aef2819/Scripts/LLSUMMONINF_MainDisabled.gameScript")

local ModifyMaxFlags = {
	LLSUMMONINF_MaxSummons_Increase = 1,
	LLSUMMONINF_MaxSummons_Increase_5 = 5,
	LLSUMMONINF_MaxSummons_Decrease = -1,
	LLSUMMONINF_MaxSummons_Decrease_5 = -5,
}

---@param amount integer
---@param player Guid	
---@param fromFlag? boolean
local function SetMaxSummons(amount, player, fromFlag)
	amount = math.max(0, amount)
	local amountChanged = PersistentVars.MaxSummons ~= amount
	PersistentVars.MaxSummons = amount
	if Ext.Osiris.IsCallable()  then
		Osi.DialogSetVariableInt("LLSUMMONINF_SettingsMenu", "LLSUMMONINF_MaxSummonLimit_89adccef-225e-47ab-8f10-5add6644ec3b", amount)
		if player then
			Osi.CharacterStatusText(player, string.format("Max Summons Set to <font color='#00FF00' size='26'>%i</font>", amount))
		end
		for i,v in pairs(Osi.DB_IsPlayer:Get(nil)) do
			UpdateMaxSummons(v[1], true)
		end
	end
	if Mods.LeaderLib then
		---@type ModSettings
		local settings = Mods.LeaderLib.SettingsManager.GetMod(ModuleUUID, false)
		if settings then
			settings.Global.Variables.MaxSummons.Value = amount
		end
		if amountChanged and fromFlag then
			Mods.LeaderLib.Timer.StartOneshot("LLSUMMONINF_SyncGlobalSettings", 250, function ()
				Mods.LeaderLib.SaveGlobalSettings()
				Mods.LeaderLib.SettingsManager.SyncGlobalSettings()
			end)
		end
	end
end

function UpdateDialogVars()
	local maxValue = PersistentVars.MaxSummons or 3
	Osi.DialogSetVariableInt("LLSUMMONINF_SettingsMenu", "LLSUMMONINF_MaxSummonLimit_89adccef-225e-47ab-8f10-5add6644ec3b", maxValue)
end

Ext.Osiris.RegisterListener("ObjectFlagSet", 3, "after", function (flag, obj, inst)
	if ModifyMaxFlags[flag] then
		SetMaxSummons(PersistentVars.MaxSummons + ModifyMaxFlags[flag], obj, true)
	elseif flag == "LLSUMMONINF_MaxSummons_Reset" then
		SetMaxSummons(3, obj, true)
	elseif flag == "LLSUMMONINF_MaxSummons_ResetToDOS2Default" then
		SetMaxSummons(1, obj, true)
	end
end)

---@param char Guid
---@param skill string
local function RefreshSkill(char, skill)
	Osi.NRD_SkillSetCooldown(char, skill, 0.0)
	if Mods.LeaderLib then
		Mods.LeaderLib.Timer.StartOneshot("", 250, function()
			Osi.NRD_SkillSetCooldown(char, skill, 0.0)
		end)
	end
end

Ext.Osiris.RegisterListener("SkillCast", 4, "after", function (char, skill, skillType, skillElement)
	if Osi.CharacterIsInCombat(char) == 0
	and Osi.CharacterIsPlayer(char) == 1
	and Osi.GlobalGetFlag("LLSUMMONINF_InstantSummonCooldownDisabled") == 0
	then
		if skillType == "summon" then
			RefreshSkill(char, skill)
		else
			local stat = Ext.Stats.Get(skill, nil, false)
			if stat and stat.SkillProperties then
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

---@param owner Guid
---@param statusId string
local function OwnerHasInfusionSkill(owner, statusId)
	local skills = InfusionCopyingData.Skills[statusId]
	if skills then
		for id,b in pairs(skills) do
			if Osi.CharacterHasSkill(owner, id) == 1 then
				return true
			end
		end
	end
	return false
end

---@param owner Guid
---@param summon Guid
function CopyInfusions(owner, summon)
	local summon = Ext.Entity.GetCharacter(summon)
	if summon then
		local success = false
		PersistentVars.CopiedInfusions[owner] = {}
		for _,statusId in pairs(summon:GetStatuses()) do
			if InfusionCopyingData.Statuses[statusId] and OwnerHasInfusionSkill(owner, statusId) then
				PersistentVars.CopiedInfusions[owner][statusId] = true
				success = true
			end
		end
		if Osi.CharacterIsControlled(owner) == 1 then
			if success then
				Osi.ShowNotification(owner, "LLSUMMONINF_Notification_InfusionsStored")
			else
				Osi.ShowNotification(owner, "LLSUMMONINF_Notification_NoInfusionsStored")
			end
		end
	end
end

---@param owner Guid
---@param summon Guid
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