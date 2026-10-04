IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawDualPistol")
self.PrecacheSoundScript("Weapon_Glock.Single")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_dual_glock") return 0.005
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
		AmmoType="item_ammo_pistol"
		Model="models/weapons/v_dualglocks.mdl"
		Firerate=0.13
		RecoilMult=1.5
		InAccuracy=0.3
		Spread=0.17
		Damage=7
		Clip=30
		ShootSound="Weapon_Glock.Single"
		DrawSound="SW.Weapon.DrawDualPistol"
	}
	
	weapon=C_BaseWeapon("weapon_dual_glock",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"GLOCKS",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}