IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawPistol")
self.PrecacheSoundScript("Weapon_Colt.Shoot")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_colt") return 0.005
	weapon.Update()
	return 0.005
}
//::aPlayer<-null
function InitWeapon(...)
{
	//IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	local WeaponInfo=
	{
		AmmoType="item_ammo_45"
		Model="models/weapons/dods/v_colt.mdl"
		Firerate=0.02
		RecoilMult=11
		InAccuracy=2
		Damage=10
		Clip=7
		ShootSound="Weapon_Colt.Shoot"
		SemiAuto=true
		DrawSound="SW.Weapon.DrawPistol"
		Dual="weapon_dual_colt"
		UseEmptyAnims=true
	}
	
	weapon=C_BaseWeapon("weapon_colt",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
//Entities.First().SetContextThink(UniqueString("")+"COLT",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}