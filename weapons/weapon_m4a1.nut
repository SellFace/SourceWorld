IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("Weapon_M4A1.Single")
self.PrecacheSoundScript("Weapon_M4A1.Clipout")
self.PrecacheSoundScript("Weapon_M4A1.Clipin")
self.PrecacheSoundScript("Weapon_M4A1.Boldpull")
self.PrecacheSoundScript("Weapon_M4A1.Deploy")

local weapon=null

function Think2(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_m4a1") return 0.005
	weapon.Update()
	//printl("thinking")
	return 0.005
}
::aPlayer<-null
function InitWeapon(...)
{
	//IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	
	local WeaponInfo=
	{
		AmmoType="item_ammo_556"
		Model="models/weapons/v_rif_m4a1.mdl"
		Firerate=0.08
		RecoilMult=2
		InAccuracy=0.35
		Damage=8
		Clip=30
		ShootSound="Weapon_M4A1.Single"
	}
	
	weapon=C_BaseWeapon("weapon_m4a1",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"M4A1",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
