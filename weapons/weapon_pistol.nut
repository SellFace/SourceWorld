IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawPistol")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_pistol") return 0.005
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
		Model="models/weapons/v_pistol.mdl"
		Firerate=0.02
		RecoilMult=5
		InAccuracy=1.5
		Spread=0.1
		Damage=5
		Clip=18
		ShootSound="Weapon_Pistol.Single"
		SemiAuto=true
		ReloadSound="Weapon_Pistol.Reload"
		DrawSound="SW.Weapon.DrawPistol"
		Dual="weapon_dual_pistol"
	}
	
	weapon=C_BaseWeapon("weapon_pistol",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"PISTOL",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}