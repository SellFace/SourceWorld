IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("Weapon_AK47.Single")
self.PrecacheSoundScript("Weapon_AK47.Single2")
self.PrecacheSoundScript("Weapon_AK47.Clipout")
self.PrecacheSoundScript("Weapon_AK47.Clipin")
self.PrecacheSoundScript("Weapon_AK47.Boltpull")
self.PrecacheSoundScript("SW.Weapon.DrawRifle")

local weapon=null

function Think2(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_ak101") return 0.005
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
		Model="models/weapons/v_rif_ak47.mdl"
		Firerate=0.115
		RecoilMult=6.2
		InAccuracy=0.41
		Spread=0.08
		RecoverySpeed=-0.75
		Damage=13
		Clip=30
		ShootSound="Weapon_AK47.Single"
		ShootSound2="Weapon_AK47.Single2"
		DrawSound="SW.Weapon.DrawRifle"
	}
	
	weapon=C_BaseWeapon("weapon_ak101",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
