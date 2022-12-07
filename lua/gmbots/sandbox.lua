--[[
	You can read the wiki at:
	https://github.com/Noobz4Life/GMBots/wiki

	Note that this wiki may not be up to date.
]]

if SERVER and not game.SinglePlayer() then
	for a,ply in pairs(player.GetAll()) do
		if SERVER and ply and ply:IsValid() and ply:IsListenServerHost() then
			ply:SendLua([[chat.AddText( Color(255,255,0), "[GMBots] Hey, you should install Zeta Players instead of this for sandbox use, it works much better in Sandbox compared to GMBots!\n")]])
		end
	end
end

GMBots:AddSpotType("Build",true)

hook.Add("GMBotsConnected","GMBots_BotConnected",function(ply) -- Runs when a bot has been added.
	ply:SetGMBotVar("Enemy", nil)
end)

local function spawnProp(ply,model)
	ply:SetGMBotVar("SpawnedProp",nil)
	ply:SetEyeAngles(Angle(10,0,0))
	ply:ConCommand("gm_spawn "..model)
	return ply:GetGMBotVar("SpawnedProp")
end

local function fakeToolGunShoot(ply,hitpos,hitnormal)
	if not(ply and ply:IsValid()) then return end

	local gun = ply:GetActiveWeapon()
	print(gun)
	if gun and gun:IsValid() and gun:GetClass() == "gmod_tool" then
		local eyetrace = ply:GetEyeTrace()

		gun:DoShootEffect(hitpos or eyetrace.HitPos,hitnormal or eyetrace.HitNormal,eyetrace.Entity,eyetrace.PhysicsBone,IsFirstTimePredicted())
	end
end

local function selectWeapon(ply,weapon)
	if not ply:HasWeapon(weapon) then
		ply:Give(weapon)
	end
	return ply:SelectWeapon(weapon)
end

local function getDupe(ply)
	local dupes = file.Find( "zetaplayerdata/duplications/*.json", "DATA" )
	if #dupes <= 0 then return end


	local dupeJson = file.Read("zetaplayerdata/duplications/"..dupes[1])
	local dupe = util.JSONToTable(util.Decompress(dupeJson))

	local entities = dupe["Entities"]
	PrintTable(entities)

	selectWeapon(ply,"weapon_physgun")

	--[[
	for a,entData in pairs(entities) do
		local prop = spawnProp(ply,entData.Model)
		if prop and prop:IsValid() then
			prop:SetPos(entData.Pos - dupe.Mins)
			prop:SetAngles(entData.Angle)

			prop:GetPhysicsObject():EnableMotion( false )
		end
	end
	]]

	return dupe
end

hook.Add("GMBotsStart","GMBots_RunStart",function(ply,cmd) -- Initialize the hook.
	cmd:ClearButtons() -- Clear any buttons the bot is pressing (for nextbots, this is by default crouch for some reason)
	cmd:ClearMovement() -- Clear any movement the bot is doing, this usually doesn't do anything but it's here just in case.

	if ply:GetGMBotVar("activity") == 1 then
		if not (ply:GetGMBotVar("Dupe")) then
			ply:SetGMBotVar("Dupe",getDupe(ply))
			ply:SetGMBotVar("DupeOrigin",ply:GetPos())
			fakeToolGunShoot(ply)
			spawnProp(ply,"models/props_c17/oildrum001.mdl")
		end

		local dupe = ply:GetGMBotVar("Dupe") or getDupe(ply)
		ply:SetGMBorVar("Dupe",dupe)
		local dupeCurrentPropNum = ply:GetGMBotVar("DupeCurrentPropNum") or 0
		if not dupe["Entities"][dupeCurrentPropNum] then
			ply:SetGMBotVar("DupeCurrentPropNum",dupeCurrentPropNum+1)
			ply:SetGMBotVar("DupeCurrentProp",nil)

			ply:SetGMBotVar("DupeLastSwapTime",CurTime())
			return
		end

		local propData = dupe["Entities"][dupeCurrentPropNum]
		if not (ply:GetGMBotVar("DupeCurrentProp") and ply:GetGMBotVar("DupeCurrentProp"):IsValid()) then
			ply:SetGMBotVar("DupeCurrentProp",spawnProp(ply,propData.Model))
			return selectWeapon(ply,"weapon_physgun")
		end

		local propPos = propData.Pos + dupe.Maxs + Vector(0,00,1000)
		local propAng = propData.Angle or propData.Angles or Angle()

		if(ply:GetGMBotVar("PhysgunnedProp") == ply:GetGMBotVar("DupeCurrentProp")) then
			local prop = ply:GetGMBotVar("DupeCurrentProp")

			cmd:SetButtons(IN_ATTACK)
			local lookAt = (propPos - ply:EyePos()):GetNormalized():Angle()
			ply:SetEyeAngles(lookAt)

			if ply:GetPos():Distance(prop:GetPos()) < propPos:Distance(ply:GetPos()) then
				cmd:AddKey(IN_USE)
				cmd:AddKey(IN_FORWARD)
			else
				cmd:AddKey(IN_USE)
				cmd:AddKey(IN_BACK)
			end

			if prop:GetAngles().pitch-propAng.pitch > 15 then
				cmd:SetMouseY(50)
			end

			if prop:GetAngles().pitch-propAng.yaw > 15 then
				cmd:SetMouseX(50)
			end
			prop:SetAngles(propAng)

			if (ply:GetGMBotVar("DupeLastSwapTime") or 0)+15 <= CurTime() or prop:GetPos():Distance(propPos) < 2 then
				PrintTable(prop:GetKeyValues())

				cmd:AddKey(IN_ATTACK2)
				ply:SetGMBotVar("DupeCurrentPropNum",dupeCurrentPropNum+1)
				ply:GetGMBotVar("DupeLastSwapTime",CurTime())

				prop:GetPhysicsObject():EnableMotion(false)
				prop:SetPos(propPos)
				prop:SetAngles(propAng or Angle())

				ply:SetGMBotVar("DupeCurrentProp",nil)
			end
		elseif not (ply:GetGMBotVar("PhysgunnedProp") and ply:GetGMBotVar("PhysgunnedProp"):IsValid()) then
			ply:BotLookAt(ply:GetGMBotVar("DupeCurrentProp"):GetPos())
			ply:GetGMBotVar("DupeCurrentProp"):SetAngles(Angle(0,0,0))
			selectWeapon(ply,"weapon_physgun")
			cmd:SetButtons(IN_ATTACK)

		end
	else
		ply:BotWander()
	end
	//fakeToolGunShoot(ply)

	if ply:GetGMBotVar("Enemy") and ply:GetGMBotVar("Enemy"):IsValid() then
		ply:Pathfind(ply:GetGMBotVar("Enemy") :GetPos(),false)
	else
		//ply:BotWander()
	end
end)

hook.Add("GMBotsTakeDamage","GMBots_TakeDamage",function(ply,dmg)
	local attacker = dmg:GetAttacker()
	if(attacker and attacker:IsPlayer() and attacker ~= ply) then
		ply:SetGMBotVar("Enemy",attacker)
		print(attacker)
	end
end)

hook.Add("GMBotsDeath","GMBots_BotDeath",function(ply,inflictor,attacker)
	ply:SetGMBotVar("Enemy",nil)
end)

hook.Add("PlayerSpawnedProp","GMBotsBuildingSpawnProp",function(ply,model,ent)
	ply:SetGMBotVar("SpawnedProp",ent)
	ply:SetGMBotVar("LastProp",ent)

	local plyProps = ply:GetGMBotVar("Props") or {}
	plyProps[#plyProps + 1] = ent

	ply:SetGMBotVar("Props",plyProps)
end)

hook.Add("Think","GMBots_Sandbox_DeathThink",function()
	for a,ply in pairs(player.GetAll()) do
		if ply and ply:IsValid() and ply:IsGMBot() and !ply:Alive() and hook.Run("PlayerDeathThink",ply) then
			ply:Spawn()
		end
	end
end)

hook.Add("OnPhysgunPickup","GMBots_PhysgunPickup",function(ply,ent)
	if ply and ply:IsValid() then
		ply:SetGMBotVar("PhysgunnedProp",ent)
	end
end)

hook.Add("PhysgunDrop","GMBots_PhysgunPickup",function(ply,ent)
	if ply and ply:IsValid() then
		ply:SetGMBotVar("PhysgunnedProp",nil)
	end
end)