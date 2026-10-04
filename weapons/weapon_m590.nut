IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("Weapon_M590.Special1")
self.PrecacheSoundScript("Weapon_M590.Reload")
self.PrecacheSoundScript("Weapon_M590.Single")
self.PrecacheSoundScript("SW.Weapon.DrawRifle")

local weapon=null

function Think4(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_m590") return 0.005
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
		AmmoType="item_ammo_shotgun"
		Model="models/weapons/v_m590.mdl"
		Firerate=0.15
		RecoilMult=45
		InAccuracy=15
		Damage=6
		BulletsPerShot=20
		IsShotgun=true
		Clip=8
		ShootSound="Weapon_M590.Single"
		SemiAuto=false
		ReloadSound="Weapon_M590.Reload"
		DrawSound="SW.Weapon.DrawRifle"
		ReloadsSingly=true
		PumpSound="Weapon_M590.Special1"
		
	}
	
	weapon=C_BaseWeapon("weapon_m590",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"M590",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}