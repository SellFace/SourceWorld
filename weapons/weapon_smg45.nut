IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawSMG")
self.PrecacheSoundScript("Weapon_SMG45.Single")
self.PrecacheSoundScript("Weapon_SMG45.Reload")

local weapon=null
local a=UniqueString("")
function Think(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_smg45") return 0.005
	//if (SERVER_DLL) printl("thinking for "+a)
	weapon.Update()
	return 0.005
}
::aPlayer<-null
function InitWeapon(...)
{
	//IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	
	local WeaponInfo=
	{
		AmmoType="item_ammo_45"
		Model="models/weapons/v_smg45.mdl"
		Firerate=0.105
		RecoilMult=2
		InAccuracy=0.4
		Spread=0.05
		Damage=8
		Clip=30
		ShootSound="Weapon_SMG45.Single"
		ReloadSound="Weapon_SMG45.Reload"
		DrawSound="SW.Weapon.DrawSMG"
	}
	
	weapon=C_BaseWeapon("weapon_smg45",WeaponInfo)
	Init(weapon)
}

Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"SMG45",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
