IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawDualPistol")
self.PrecacheSoundScript("SW.Weapon.DualPistol.Reload")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_dual_pistol") return 0.005
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
		Model="models/weapons/v_dualpistols.mdl"
		Firerate=0.15
		RecoilMult=2
		InAccuracy=0.25
		Spread=0.25
		Damage=5
		Clip=36
		ShootSound="Weapon_Pistol.Single"
		ReloadSound="SW.Weapon.DualPistol.Reload"
		DrawSound="SW.Weapon.DrawDualPistol"
	}
	
	weapon=C_BaseWeapon("weapon_dual_pistol",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"PISTOLS",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}