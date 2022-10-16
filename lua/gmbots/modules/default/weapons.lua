GMBots.BlacklistedWeapons = {"weapon_satchel","weapon_frag","weapon_handgrenade","weapon_physgun","weapon_physcannon","weapon_medkit","gmod_tool","gmod_camera","weapon_tripmine","weapon_slam","weapon_bugbait","manhack_welder"}
GMBots.WeaponWeight = {}

local PLAYER = FindMetaTable( "Player" )
local WEAPON = FindMetaTable( "Weapon" )

function WEAPON:GetFireRate()
    if self:IsScripted() and SWEP ~= nil then
        return SWEP.Primary.Firerate
        or SWEP.Primary.FireRate
        or SWEP.Primary.Delay
        or SWEP.Primary.Cooldown

        or SWEP.Firerate
        or SWEP.FireRate
        or SWEP.Delay
        or SWEP.Cooldown

        or SWEP.Secondary.Firerate
        or SWEP.Secondary.FireRate
        or SWEP.Secondary.Delay
        or SWEP.Secondary.Cooldown

        or -1
    end
    return 10
    //return -1
end

function WEAPON:GetWeaponDamage()
    if self:IsScripted() and SWEP ~= nil then
        return SWEP.Primary.Damage or SWEP.Damage or SWEP.Secondary.Damage or 0
    end
    return game.GetAmmoPlayerDamage( self:GetPrimaryAmmoType() or self:GetSecondaryAmmoType() )
end

function PLAYER:ChooseBestWeapon(tbl)
    local weapons = tbl or self:GetWeapons()
    if #weapons <= 0 then return NULL end

    local highestWeight = -999999
    local highestWeightWeapon = NULL

    for i = 1,#weapons do
        local weapon = weapons[i]
        if not (weapon and weapon:IsValid() and weapon:IsWeapon() and weapon:HasAmmo()) then continue end

        local weapon_name = string.lower(weapon:GetClass())
        if table.HasValue(GMBots.BlacklistedWeapons,weapon_name) then continue end

        local weapon_dps = GMBots.WeaponWeight[weapon_name]
        if(not GMBots.WeaponWeight[weapon_name]) then
            local damage = weapon:GetWeaponDamage()
            local firerate = weapon:GetFireRate()
            if(damage and firerate) then
                weapon_dps = damage / (1 / firerate)
            end
        end

        if weapon_dps and weapon_dps > 0 and weapon_dps > highestWeight then
            highestWeight = weapon_dps
            highestWeightWeapon = weapon_name
        end
    end

    return highestWeightWeapon
end

function PLAYER:SelectBestWeapon(tbl)
    local bestweapon = self:ChooseBestWeapon(tbl)
    if bestweapon and IsValid(bestweapon) and ((IsEntity(bestweapon) and bestweapon:IsWeapon() and bestweapon:GetOwner() == self) or self:HasWeapon(bestweapon)) then
        return self:SelectWeapon(bestweapon)
    end
end