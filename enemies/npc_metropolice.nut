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

clip<-(18);

function HandleAttack(event)
{
	
	//printl(event.GetEvent())
	//printl(event.GetType())
	//printl(event.GetEventTime())
	if (event.GetEvent()==3002) {Entities.First().SetContextThink("DelayedSound",function(_) {self.EmitSound("Weapon_SMG45.Single")}.bindenv(this),0.01);
	local info = CreateFireBulletsInfo(1, self.ShootPosition(), self.EyeDirection3D(), VECTOR_CONE_10DEGREES, 3, self)
	info.SetTracerFreq(1)
	info.SetAmmoType(3)
	info.SetDistance(5000)
	self.GetActiveWeapon().FireBullets(info)
	self.FireBullets(info)
	//player.GetActiveWeapon().FireBullets(info)
	self.EmitSound("Weapon_SMG45.Single")
	local gun=self.GetActiveWeapon()
	//Entities.First().SetContextThink("DelayedSound1",function(_) {printl("hha");gun.SetSequence(1);gun.SetCycle(1);self.FireBullets(info);self.GetActiveWeapon().EmitSound("Weapon_SMG45.Single");DestroyFireBulletsInfo(info);return}.bindenv(this),0.05)
	//Entities.First().SetContextThink("DelayedSound2",function(_) {printl("hhaASD");gun.SetSequence(1);gun.SetCycle(1);self.FireBullets(info);self.GetActiveWeapon().EmitSound("Weapon_SMG45.Single");DestroyFireBulletsInfo(info);return}.bindenv(this),0.08)
	self.GetActiveWeapon().SetClip1(self.GetActiveWeapon().Clip1()-1)
	return false
	}
	return true
}

function Think()
{
	//if (self.GetActiveWeapon().GetClassname()=="weapon_smg1") self.GetActiveWeapon().SetModel("models/weapons/smg45/w_smg1.mdl");
	//printl(self.GetActiveWeapon())
	//printl(self.GetActiveWeapon().GetModelName())
	if (!self.GetEnemy()) return
	//if (self.GetActiveWeapon().GetClassname()!="weapon_stunstick") return
	if ((self.GetActivity().find("ACT_MELEE_ATTACK")!=null)&&(self.GetCycle()<0.2)) {self.SetVelocity((self.GetEnemy().GetVelocity()/3+self.GetEnemy().GetOrigin()-self.GetOrigin()).Normalized()*330)};
    if (((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<110)&&(self.GetActivity().find("ACT_MELEE_ATTACK")==null))
	{
		//printl("KILL")
		//self.SetSchedule("SCHED_ZOMBIE_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		//self.SetSchedule("SCHED_MELEE_ATTACK1")
		//self.SetActivity("ACT_MELEE_ATTACK1")
	}
	if (self.GetActiveWeapon()) clip=self.GetActiveWeapon().Clip1()
	
}

function H(event)
{
	printl("hi");
	print(event.GetEvent())
}

IncludeScript("items/ammo_smg.nut")
function OnPostSpawn()
{
	//EntFireByHandle(self,"setspeedmodifier","1.5",0.00);
	self.ConnectOutput( "OnDeath","SpawnAmmo" )
	if (!(self.GetActiveWeapon())) return;
	if (self.GetActiveWeapon().GetClassname()=="weapon_smg1")
	{
		self.GetActiveWeapon().SetRenderMode(6)
		local W={
			targetname=self.GetName()+"_gun"
			model="models/weapons/smg45/w_smg1.mdl"
			InitialOwner=self.GetName()
		}
		SpawnEntityFromTable("prop_dynamic_ornament", W)
		
		local M={
			BurstShotCountRange="15:30"
			BurstInterval="10:20"
			RestInterval="0.25:0.6"
			Target=self.GetName()
		}
		SpawnEntityFromTable("ai_weaponmodifier", M)
	}
	self.SetEnemy(player)
}

Hooks.Add( this, "HandleAnimEvent", HandleAttack, "HandleAttack" );