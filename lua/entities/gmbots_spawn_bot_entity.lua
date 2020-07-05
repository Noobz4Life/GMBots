ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "GMBot"
ENT.Category = "Nextbot"

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

function ENT:Initialize()
	if SERVER then
		if GMBots and GMBots.AddBot then
			local bot = GMBots:AddBot()
			if bot and bot:IsValid() then
				bot:SetPos(self:GetPos())
			end
		else
			RunConsoleCommand("gmbots_bot_add")
		end
		self:Remove()
	end
end

if CLIENT then
	language.Add( "Hint_GMBots_ServerFull", "Can't spawn bot! Server is full!" )
end

function ENT:SpawnFunction( ply, tr, ClassName )
	print("test",ply)
	if ply and ply:IsValid() and SERVER then
		print( player.GetCount(),game.MaxPlayers())
		if player.GetCount() >= game.MaxPlayers() then
			ply:SendHint( "GMBots_ServerFull", 0 )
			return
		end
	end
	if player.GetCount() >= game.MaxPlayers() then
		return
	end
	
	local ent = ents.Create( "gmbots_spawn_bot_entity" )
	ent:Spawn()
	ent:Activate()
	
	return ent
end

pcall(function()
	list.Set( "NPC", "gmbots_spawn_bot_entity", {
		Name = "GMBot",
		Class = "gmbots_spawn_bot_entity",
		Category = "Nextbot"
	})
end)