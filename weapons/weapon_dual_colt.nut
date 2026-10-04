IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawDualPistol")
self.PrecacheSoundScript("SW.Weapon.DualPistol.Reload")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_dual_colt") return 0.005
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
		Model="models/weapons/v_dualcolts.mdl"
		Firerate=0.16
		RecoilMult=3.5
		InAccuracy=0.55
		Spread=0.2
		Damage=10
		Clip=14
		ShootSound="Weapon_Colt.Shoot"
		//ReloadSound="SW.Weapon.DualPistol.Reload"
		DrawSound="SW.Weapon.DrawDualPistol"
	}
	
	weapon=C_BaseWeapon("weapon_dual_colt",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"COLTS",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}