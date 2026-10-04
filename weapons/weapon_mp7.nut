IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawSMG")

local weapon=null
local a=UniqueString("")
function Think(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_mp7") return 0.005
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
		Model="models/weapons/v_smg1.mdl"
		Firerate=0.065
		RecoilMult=2
		InAccuracy=0.5
		Spread=0.5
		Damage=5
		Clip=45
		ShootSound="Weapon_SMG1.Single"
		ReloadSound="Weapon_SMG1.NPC_Reload"
		DrawSound="SW.Weapon.DrawSMG"
	}
	
	weapon=C_BaseWeapon("weapon_mp7",WeaponInfo)
	Init(weapon)
}

Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"MP7",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
