IncludeScript("enemies/base_enemy.nut")

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
	if (event.GetEvent()==65||event.GetEvent()==66)
	{
		local step=TraceLineComplex(self.GetCenter(), self.GetOrigin()-Vector(0,0,10), self, MASK_SHOT, 0)
		if (step.DidHit()&&step.Surface().SurfaceProps())
		{
			self.EmitSound(event.GetEvent()==65 ? step.Surface().SurfaceProps().GetSoundStepRight() : step.Surface().SurfaceProps().GetSoundStepLeft())
		}
	}
	
	if ((self.GetActivity()=="ACT_MELEE_ATTACK1")&&((parrytime+1)>Time())) return false
	if (self.FindGestureLayer("ACT_FLINCH_LEFTLEG")!=-1||self.FindGestureLayer("ACT_FLINCH_RIGHTLEG")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_RIGHTARM")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_LEFTARM")!=-1) {parrytime=Time()-0.5;return false}
	return true
}

local lastactivity=null

function NPC_TranslateActivity()
{
    local newactivity = -1;
    if (activity.find("ACT_WALK") != null||activity.find("ACT_RUN") != null)
	{
        lastwalktime=Time()
	}
	
	if ((activity=="ACT_MELEE_ATTACK1")&&self.GetEnemy().GetVelocity().Length()<70) 
	{
		lastactivity="ACT_MELEE_ATTACK2"
		return "ACT_MELEE_ATTACK2"
	}
	else if (activity=="ACT_MELEE_ATTACK1")
	{
		lastactivity="ACT_MELEE_ATTACK1"
		local gesture=self.AddGesture("ACT_GESTURE_MELEE_ATTACK1",true)
		return lastactivity
	}
	lastactivity=activity
    return newactivity;
}

local nextsound=null

local ThinkingTime=0.0001

local disabled=false;

local NextIdleSound=0;

function Think()
{

	if ((player.GetOrigin()-self.GetOrigin()).Length()>500) ThinkingTime=0.1
	if ((player.GetOrigin()-self.GetOrigin()).Length()>1000)
	
	
	if ((player.GetOrigin()-self.GetOrigin()).Length()>1000&&!disabled&&GetMapName().find("mapgens")!=null) {EntFireByHandle(self,"setthinknull");disabled=true}
	if ((player.GetOrigin()-self.GetOrigin()).Length()<=1000&&disabled&&GetMapName().find("mapgens")!=null) {EntFireByHandle(self,"setthinknpc");disabled=false}
	
	if (NextIdleSound<Time()) 
	{
		nextsound="ZombieFeral.Idle"
		if (self.GetEnemy()) nextsound="ZombieFeral.Alert"
		NextIdleSound=Time()+RandomInt(3,10)
		self.EmitSound(nextsound)
	}

	//local schedule=self.GetSchedule()
	if (self.GetHealth()<=0) return
	local activity=self.GetActivity()
	speedmod=clamp(((Time()-lastwalktime)/2.0),0,3)
	if (self.FindGestureLayer("ACT_FLINCH_LEFTLEG")!=-1||self.FindGestureLayer("ACT_FLINCH_RIGHTLEG")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_RIGHTARM")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_LEFTARM")!=-1||(self.GetLastDamageTime()>(Time()-0.25))||((parrytime+1)>Time())) return ThinkingTime
	EntFireByHandle(self,"setplaybackrate",1.1,0.00);
	EntFireByHandle(self,"setspeedmodifier",1.1,0.00);
	//if (self.GetClassname()=="npc_zombie"&&self.GetEnemy()!=player) self.SetEnemy(player)
	if (((activity.find("ACT_WALK") != null)||(activity.find("ACT_RUN") != null))&&(self.GetEnemy()==player))
	{
		//printl(speedmod)
		//if (!(self.GetActivity()=="ACT_MELEE_ATTACK1")) EntFireByHandle(self,"setplaybackrate",1.1+speedmod*2,0.00);
		EntFireByHandle(self,"setspeedmodifier",1.1+sin(Time()+self.entindex())*0.15,0.00);
		EntFireByHandle(self,"setplaybackrate",1.1+sin(Time()+self.entindex())*0.15,0.00);
		
		self.SetVelocity(self.GetEnemy().GetVelocity().Normalized()*(1500/(self.GetEnemy().GetOrigin()-self.GetOrigin()).Length())*(speedmod+1));
	}
	else
	{
		if (!(self.GetActivity()=="ACT_MELEE_ATTACK1")) EntFireByHandle(self,"setplaybackrate",1.1,0.00);
		EntFireByHandle(self,"setspeedmodifier",1.1,0.00);
	}
	
	if (self.GetSchedule()=="SCHED_IDLE_STAND"&&(self.entindex()%4)==0) self.SetSchedule("SCHED_IDLE_WANDER")
	
	if (!self.GetEnemy()) return ThinkingTime;

	if ((lastactivity=="ACT_MELEE_ATTACK1")) 
	{
		self.SetVelocity((self.GetEnemy().GetVelocity()/3+self.GetEnemy().GetOrigin()-self.GetOrigin()).Normalized()*308*(1.1+sin(Time()+self.entindex())*0.15))
		EntFireByHandle(self,"setplaybackrate",1.1+sin(Time()+self.entindex())*0.15,0.00);
		//printl(lastactivity)
	}

	
	if ((lastactivity=="ACT_MELEE_ATTACK2")&&self.GetCycle()<0.4) 
	{
		EntFireByHandle(self,"setplaybackrate",1.4,0);
		self.SetVelocity((self.GetEnemy().GetVelocity()/3+self.GetEnemy().GetOrigin()-self.GetOrigin()).Normalized()*150)
		//printl(lastactivity)
	}
	
    if (((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<100)&&(self.GetActivity()!="ACT_MELEE_ATTACK1")&&(self.GetActivity()!="ACT_MELEE_ATTACK2")&&self.GetEnemy().GetVelocity().Length()>=70)
	{
		//printl("KILL")
		//self.SetSchedule("SCHED_ZOMBIE_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		//self.SetSchedule("SCHED_MELEE_ATTACK1")
		//self.SetActivity("ACT_MELEE_ATTACK1")
		
		local gesture=self.AddGesture("ACT_GESTURE_MELEE_ATTACK1",true)
	}
	if (((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<80)&&(self.GetActivity()!="ACT_MELEE_ATTACK1")&&(self.GetActivity()!="ACT_MELEE_ATTACK2")&&self.GetEnemy().GetVelocity().Length()<70)
	{
		//printl("KILL")
		//self.SetSchedule("SCHED_ZOMBIE_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		self.SetSchedule("SCHED_MELEE_ATTACK2")
		self.SetActivity("ACT_MELEE_ATTACK2")
	}
    return ThinkingTime;
}

function Precache()
{
	self.PrecacheSoundScript("ZombieFeral.Attack")
	self.PrecacheSoundScript("ZombieFeral.AttackHit")
	self.PrecacheSoundScript("ZombieFeral.AttackMiss")
	self.PrecacheSoundScript("ZombieFeral.Alert")
	self.PrecacheSoundScript("ZombieFeral.Pain")
	self.PrecacheSoundScript("ZombieFeral.Idle")
	self.PrecacheSoundScript("ZombieFeral.FootstepRight")
	self.PrecacheSoundScript("ZombieFeral.FootstepLeft")
	self.PrecacheSoundScript("NPC_BaseZombieFeral.Swat")
	self.PrecacheSoundScript("NPC_BaseZombieFeral.Moan1")
	self.PrecacheSoundScript("NPC_BaseZombieFeral.Moan2")
	self.PrecacheSoundScript("NPC_BaseZombieFeral.Moan3")
	self.PrecacheSoundScript("NPC_BaseZombieFeral.Moan4")
}

function ModifyEmitSoundParams()
{
	local name=params.GetSoundName()
	if (name.find("Feral")!=null) return;
	if (name.find("Zombie")==null) return;
	//params.SetSoundTime(-1)
	
	name=name.slice(0,name.find("Zombie")+6)+"Feral"+name.slice(name.find("Zombie")+6)
	params.SetSoundName(name)
	//EmitSoundParamsOn(params,self)
	//nextsound=name
}

Hooks.Add( this, "HandleAnimEvent", HandleAttack, "HandleAttack" );