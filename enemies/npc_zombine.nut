local lastwalktime=0
local speedmod=clamp(((Time()-lastwalktime)/2.0),0,3)
local parrytime=0
function Parry(parrysequence)
{
	parrytime=Time()
	self.SetPlaybackRate(-1)
	local gesture=self.AddGesture("ACT_GESTURE_FLINCH_HEAD",true)
	self.SetLayerWeight(gesture,0.3)
	//self.SetContextThink("a",function(...){self.SetCycle(0.45);self.SetPlaybackRate(-1)}.bindenv(this),0.2)
}

function HandleAttack(event)
{
	if ((self.GetActivity()=="ACT_MELEE_ATTACK1")&&((parrytime+1)>Time())) return false
	if (self.FindGestureLayer("ACT_FLINCH_LEFTLEG")!=-1||self.FindGestureLayer("ACT_FLINCH_RIGHTLEG")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_RIGHTARM")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_LEFTARM")!=-1) {parrytime=Time()-0.5;return false}
	return true
}

function NPC_TranslateActivity()
{
    local newactivity = -1;
    if (activity.find("ACT_WALK") != null||activity.find("ACT_RUN") != null)
	{
        lastwalktime=Time()
	}
    return newactivity;
}

function Think()
{
	//local schedule=self.GetSchedule()
	if (self.GetHealth()<=0) return
	local activity=self.GetActivity()
	speedmod=clamp(((Time()-lastwalktime)/2.0),0,3)
	if (self.FindGestureLayer("ACT_FLINCH_LEFTLEG")!=-1||self.FindGestureLayer("ACT_FLINCH_RIGHTLEG")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_RIGHTARM")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_LEFTARM")!=-1||(self.GetLastDamageTime()>(Time()-0.25))||((parrytime+1)>Time())) return 0.0001
	EntFireByHandle(self,"setplaybackrate",1.1,0.00);
	EntFireByHandle(self,"setspeedmodifier",1.1,0.00);
	//if (self.GetClassname()=="npc_zombie"&&self.GetEnemy()!=player) self.SetEnemy(player)
	if (((activity.find("ACT_WALK") != null)||(activity.find("ACT_RUN") != null))&&(self.GetEnemy()==player))
	{
		//printl(speedmod)
		EntFireByHandle(self,"setplaybackrate",1.1+speedmod*2,0.00);
		EntFireByHandle(self,"setspeedmodifier",1.1+speedmod*2,0.00);
		
		self.SetVelocity(self.GetEnemy().GetVelocity().Normalized()*(1500/(self.GetEnemy().GetOrigin()-self.GetOrigin()).Length())*(speedmod+1));
		/*
		local gesture=self.FindGestureLayer("ACT_DI_ALYX_ZOMBIE_MELEE")
		if (gesture==-1) 
		{
			self.AddGesture("ACT_DI_ALYX_ZOMBIE_MELEE",true)
			gesture=self.FindGestureLayer("ACT_DI_ALYX_ZOMBIE_MELEE")
			self.SetLayerWeight(gesture,speedmod/5.0)
			self.SetLayerDuration(gesture,100)
			self.SetLayerCycle(gesture,0.30)
			self.SetLayerLooping(gesture,true)
		}
		gesture=self.FindGestureLayer("ACT_WALK_ON_FIRE")
		self.AddGesture("ACT_DI_ALYX_ZOMBIE_MELEE",true)
		gesture=self.FindGestureLayer("ACT_DI_ALYX_ZOMBIE_MELEE")
		self.SetLayerWeight(gesture,speedmod/5.0)
		self.SetLayerDuration(gesture,100)
		self.SetLayerCycle(gesture,0.30)
		self.SetLayerLooping(gesture,true)*/
		//if (gesture!=-1) self.SetLayerWeight(gesture,speedmod/3.0)
		//if (gesture!=-1) self.SetLayerLooping(gesture,true)
		//if (gesture!=-1) self.SetLayerPlaybackRate(gesture,1+speedmod)
	}
	else
	{
		EntFireByHandle(self,"setplaybackrate",1.1,0.00);
		EntFireByHandle(self,"setspeedmodifier",1.1,0.00);
	}
	if (!self.GetEnemy()) return 0.0001;
	if ((self.GetActivity()=="ACT_MELEE_ATTACK1")&&(self.GetCycle()<0.2)) {self.SetVelocity((self.GetEnemy().GetVelocity()/3+self.GetEnemy().GetOrigin()-self.GetOrigin()).Normalized()*330)};
    if (((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<110)&&(self.GetActivity()!="ACT_MELEE_ATTACK1"))
	{
		//printl("KILL")
		//self.SetSchedule("SCHED_ZOMBIE_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		self.SetSchedule("SCHED_MELEE_ATTACK1")
		self.SetActivity("ACT_MELEE_ATTACK1")
	}
    return 0.0001;
}


function OnPostSpawn()
{
	//EntFireByHandle(self,"setspeedmodifier","1.5",0.00);
	if (!(self.GetActiveWeapon())) return;
	if (self.GetActiveWeapon().GetClassname()=="weapon_smg1")
	{
		self.ConnectOutput( "OnDeath","SpawnAmmo" )
	}
	self.SetEnemy(player)
}
IncludeScript("items/ammo_smg.nut")
Hooks.Add( this, "HandleAnimEvent", HandleAttack, "HandleAttack" );