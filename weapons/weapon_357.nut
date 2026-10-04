IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawPistol")
self.PrecacheSoundScript("Weapon_357.Reload")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_357") return 0.005
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
		AmmoType="item_ammo_357"
		Model="models/weapons/v_357.mdl"
		Firerate=0.25
		RecoilMult=50
		InAccuracy=0.01
		Damage=40
		Clip=6
		ShootSound="Weapon_357.Single"
		SemiAuto=true
		ReloadSound="Weapon_357.Reload"
		DrawSound="SW.Weapon.DrawPistol"
		RecoveryBonus=1.1
		AccuracyBonus=130	//actually this changes how inaccurate it gets after each shot. the bigger number is more inaccuracy
		Spread=-0.09
		RecoverySpeed=-0.08
	}
	
	weapon=C_BaseWeapon("weapon_357",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
//Entities.First().SetContextThink(UniqueString("")+"MAGNUM",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}