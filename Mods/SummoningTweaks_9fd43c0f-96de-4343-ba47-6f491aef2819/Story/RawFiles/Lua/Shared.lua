local isClient = Ext.IsClient()

local modifySkillsOnRunning = 0

function AddInfusionSkills_Button(buttonData, character)
	if Ext.GetGameState() == "Running" then
		AddInfusionSkills()
	else
		modifySkillsOnRunning = 1
	end
end

function RemoveInfusionSkills_Button(buttonData, character)
	if Ext.GetGameState() == "Running" then
		RemoveInfusionSkills()
	else
		modifySkillsOnRunning = -1
	end
end

Ext.RegisterListener("GameStateChanged", function (from, to)
	if to == "Running" and modifySkillsOnRunning ~= 0 then
		if modifySkillsOnRunning == 1 then
			AddInfusionSkills()
		elseif modifySkillsOnRunning == -1 then
			RemoveInfusionSkills()
		end
		modifySkillsOnRunning = 0
	end
end)

function AddInfusionSkills(netid)
	if isClient then
		Ext.PostMessageToServer("LLSUMMONINF_AddInfusionSkills", Mods.LeaderLib.Client:GetCharacter().NetID)
	else
		netid = tonumber(netid)
		local player = Ext.GetCharacter(netid)
		if player then
			--Pet Power
			if Ext.IsModLoaded("d2507d43-efce-48b8-ba5e-5dd136c715a7") then
				CharacterAddSkill(player.MyGuid, "Target_LLSUMMONINF_CopyInfusions_LarianModVersion", 1)
			else
				CharacterAddSkill(player.MyGuid, "Target_LLSUMMONINF_CopyInfusions", 1)
			end
			CharacterAddSkill(player.MyGuid, "Target_LLSUMMONINF_ApplyInfusions", 1)
		end
	end
end

function RemoveInfusionSkills(netid)
	if isClient then
		Ext.PostMessageToServer("LLSUMMONINF_AddInfusionSkills", Mods.LeaderLib.Client:GetCharacter().NetID)
	else
		netid = tonumber(netid)
		local player = Ext.GetCharacter(netid)
		if player then
			CharacterRemoveSkill(player.MyGuid, "Target_LLSUMMONINF_CopyInfusions_LarianModVersion")
			CharacterRemoveSkill(player.MyGuid, "Target_LLSUMMONINF_CopyInfusions")
			CharacterRemoveSkill(player.MyGuid, "Target_LLSUMMONINF_ApplyInfusions")
		end
	end
end

if not isClient then
	Ext.RegisterNetListener("LLSUMMONINF_AddInfusionSkills", function(cmd, netid)
		AddInfusionSkills(netid)
	end)

	Ext.RegisterNetListener("LLSUMMONINF_RemoveInfusionSkills", function(cmd, netid)
		RemoveInfusionSkills(netid)
	end)
end