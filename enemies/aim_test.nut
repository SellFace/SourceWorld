clip<-(18);

function Precache()
{
	PrecacheModel("models/weapons/smg45/w_smg1.mdl", true)
}
function NPC_TranslateActivity()
{
    local newactivity = -1;
    if (activity.find("ACT_MELEE_ATTACK1") != null)
	{
		//if (RandomInt(0,1)==1) return "ACT_MELEE_ATTACK2"
	}
	 if (activity.find("ACT_RANGE_ATTACK_SMG1") != null)
	{
		//self.EmitSound("Weapon_SMG45.Single")
	}
    return newactivity;
}
local ammo=45

local muzzleFlashTable = {
	brightnessscale = 2,
	farz = 850,
	lightcolor = "255 255 255 225",
	lightfov = 80,
	nearz = 10,
	spawnflags = 1,
	texturename = "effects/muzzleflash_light"
}

local muzzlelight = {
	_cone = 0,
	_inner_cone = 0,
	_light = "249 205 67 2200",
	brightness = 3,
	distance = 250
	pitch = -90,
	//spawnflags = 1,
	style=1
}
PrecacheParticleSystem("weapon_muzzle_flash_assaultrifle")

function HandleAttack(event)
{
	//if (self.GetActiveWeapon)
	
	//printl(event.GetEvent())
	//printl(event.GetType())
	//printl(event.GetEventTime())
	if (event.GetEvent()==3002||event.GetEvent()==3014) {Entities.First().SetContextThink("DelayedSound",function(_) {self.GetActiveWeapon().EmitSound("Weapon_Pistol.NPC_Single")}.bindenv(this),0.01);
	local info = CreateFireBulletsInfo(1, self.ShootPosition(), self.EyeDirection3D(), VECTOR_CONE_5DEGREES, 1, self)
	info.SetTracerFreq(2)
	//self.EmitSound("Weapon_357.Single")
	info.SetAmmoType(1)
	info.SetDamage(5)
	info.SetDamageForceScale(201)
	info.SetShots(1)
	info.SetDistance(5000)
	//printl("Firing !")
	//self.GetActiveWeapon().FireBullets(info)
	self.FireBullets(info)
	self.DoMuzzleFlash()
	
	//local flashEnt = SpawnEntityFromTable("env_projectedtexture", muzzleFlashTable)
	local flashEnt2 = SpawnEntityFromTable("light_dynamic", muzzlelight)
	local attach=self.GetActiveWeapon().LookupAttachment("muzzle")
	local muzzle=self.GetActiveWeapon().GetAttachmentOrigin(attach)
	EntFireByHandle(flashEnt2, "SetParent", "!player", 0)
	//debugoverlay.Text(muzzle,"shoot",0.5)
	//flashEnt.SetOrigin(self.ShootPosition())
	flashEnt2.SetOrigin(self.ShootPosition())
	flashEnt2.SetOrigin(muzzle)
	local flashAngle = VectorAngles(self.EyeDirection3D())
	flashAngle.z = RandomFloat(0, 360)
	//flashEnt.SetAngles(flashAngle)
	//EntFireByHandle(flashEnt, "Kill", "", min(0.02 * 0.8, 0.025))
	EntFireByHandle(flashEnt2, "Kill", "", 0.1)
	//DispatchParticleEffect("weapon_muzzle_flash_assaultrifle",muzzle,self.GetActiveWeapon().GetAngles(),player)
	
	
	//DestroyFireBulletsInfo(info)
	//player.GetActiveWeapon().FireBullets(info)
	//self.EmitSound("Weapon_SMG45.Single")
	//local gun=self.GetActiveWeapon()
	//Entities.First().SetContextThink("DelayedSound1",function(_) {self.ResetActivity();self.SetActivity(self.GetActivity());return}.bindenv(this),0.0)

	
	//Entities.First().SetContextThink("DelayedSound3",function(_) {gun.SetSequence(1);gun.SetCycle(1);self.FireBullets(info);self.GetActiveWeapon().EmitSound("Weapon_Pistol.Single");DestroyFireBulletsInfo(info);return}.bindenv(this),0.1)
	//self.GetActiveWeapon().SetClip1(self.GetActiveWeapon().Clip1()-1)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0.01)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0.02)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0.04)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0.06)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0.08)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0.1)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0.12)
	//EntFireByHandle(self,"changevariable","m_flNextAttack -20",0.14)
	//EntFireByHandle(self,"setcycle","1",0.0)
	//self.SetCycle(1)
	//EntFireByHandle(self,"setplaybackrate","12",0.0)
	//EntFire("ai_weaponmodifier","reset","1",0.0)

	//gun.SetSequence(1);gun.SetCycle(1)
	return false
	}
	return true
}

Hooks.Add( this, "HandleAnimEvent", HandleAttack, "HandleAttack" );