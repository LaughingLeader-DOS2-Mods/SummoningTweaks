local _ISCLIENT = Ext.IsClient()

---@return EsvGameState gameState
function _GS()
	if _ISCLIENT then
		return Ext.Client.GetGameState()
	else
		return Ext.Server.GetGameState()
	end
end

local modifySkillsOnRunning = 0

function AddInfusionSkills_Button(buttonData, character)
	if _GS() == "Running" then
		AddInfusionSkills()
	else
		modifySkillsOnRunning = 1
	end
end

function RemoveInfusionSkills_Button(buttonData, character)
	if _GS() == "Running" then
		RemoveInfusionSkills()
	else
		modifySkillsOnRunning = -1
	end
end

Ext.Events.GameStateChanged:Subscribe(function(e)
	if e.ToState == "Running" and modifySkillsOnRunning ~= 0 then
		if modifySkillsOnRunning == 1 then
			AddInfusionSkills()
		elseif modifySkillsOnRunning == -1 then
			RemoveInfusionSkills()
		end
		modifySkillsOnRunning = 0
	end
end)

---@param prioritizeSecondPlayer boolean|nil
---@return EclCharacter|nil
local function _GetPlayerManagerCharacter(prioritizeSecondPlayer)
	local playerManager = Ext.Entity.GetPlayerManager()
	if playerManager then
		if prioritizeSecondPlayer then
			local player2Data = playerManager.ClientPlayerData[2]
			if player2Data then
				local client = Ext.Entity.GetCharacter(player2Data.CharacterNetId)
				if client then
					return client
				end
			end
		end
		for id,data in pairs(playerManager.ClientPlayerData) do
			local client = Ext.Entity.GetCharacter(data.CharacterNetId)
			if client then
				return client
			end
		end
	end
	return nil
end

function AddInfusionSkills(netid)
	if _ISCLIENT then
		local clientCharacter = _GetPlayerManagerCharacter()
		if clientCharacter then
			Ext.Net.PostMessageToServer("LLSUMMONINF_AddInfusionSkills", tostring(clientCharacter.NetID))
		end
	else
		netid = tonumber(netid)
		local player = Ext.Entity.GetCharacter(netid)
		if player then
			--Pet Power
			if Ext.Mod.IsModLoaded("d2507d43-efce-48b8-ba5e-5dd136c715a7") then
				Osi.CharacterAddSkill(player.MyGuid, "Target_LLSUMMONINF_CopyInfusions_LarianModVersion", 0)
				Osi.CharacterAddSkill(player.MyGuid, "Target_LLSUMMONINF_ApplyInfusions_LarianModVersion", 0)
			else
				Osi.CharacterAddSkill(player.MyGuid, "Target_LLSUMMONINF_CopyInfusions", 0)
				Osi.CharacterAddSkill(player.MyGuid, "Target_LLSUMMONINF_ApplyInfusions", 0)
			end
		end
	end
end

function RemoveInfusionSkills(netid)
	if _ISCLIENT then
		local clientCharacter = _GetPlayerManagerCharacter()
		if clientCharacter then
			Ext.Net.PostMessageToServer("LLSUMMONINF_RemoveInfusionSkills", tostring(clientCharacter.NetID))
		end
	else
		netid = tonumber(netid)
		local player = Ext.Entity.GetCharacter(netid)
		if player then
			Osi.CharacterRemoveSkill(player.MyGuid, "Target_LLSUMMONINF_CopyInfusions_LarianModVersion")
			Osi.CharacterRemoveSkill(player.MyGuid, "Target_LLSUMMONINF_ApplyInfusions_LarianModVersion")
			Osi.CharacterRemoveSkill(player.MyGuid, "Target_LLSUMMONINF_CopyInfusions")
			Osi.CharacterRemoveSkill(player.MyGuid, "Target_LLSUMMONINF_ApplyInfusions")
		end
	end
end

if not _ISCLIENT then
	Ext.RegisterNetListener("LLSUMMONINF_AddInfusionSkills", function(cmd, netid)
		AddInfusionSkills(netid)
	end)

	Ext.RegisterNetListener("LLSUMMONINF_RemoveInfusionSkills", function(cmd, netid)
		RemoveInfusionSkills(netid)
	end)
end