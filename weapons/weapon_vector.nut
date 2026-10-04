IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawSMG")
self.PrecacheSoundScript("SW.Weapon_Vector.Single")
self.PrecacheSoundScript("SW.Weapon_Vector.Reload")

local weapon=null
local a=UniqueString("")
function Think(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_vector") return 0.005
	//if (SERVER_DLL) printl("thinking for "+a)
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
		Model="models/weapons/v_vector.mdl"
		Firerate=0.05
		RecoilMult=1.5
		InAccuracy=0.2
		Spread=0.05
		Damage=5
		Clip=30
		ShootSound="SW.Weapon_Vector.Single"
		ReloadSound="SW.Weapon_Vector.Reload"
		DrawSound="SW.Weapon.DrawSMG"
	}
	
	weapon=C_BaseWeapon("weapon_vector",WeaponInfo)
	Init(weapon)
}

Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"VECTOR",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
