IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawPistol")
self.PrecacheSoundScript("Weapon_Glock.Single")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_glock") return 0.005
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
		AmmoType="item_ammo_pistol"
		Model="models/weapons/v_pist_glock18.mdl"
		Firerate=0.03
		RecoilMult=5
		InAccuracy=2
		Spread=0.04
		Damage=7
		Clip=15
		ShootSound="Weapon_Glock.Single"
		SemiAuto=true
		DrawSound="SW.Weapon.DrawPistol"
		Dual="weapon_dual_glock"
		RecoveryBonus=0.08
		RecoverySpeed=0.02
	}
	
	weapon=C_BaseWeapon("weapon_glock",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
//Entities.First().SetContextThink(UniqueString("")+"GLOCK",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}