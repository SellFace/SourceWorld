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

local ThinkingTime=0.0001

local disabled=false;

function Think()
{
	
	if ((player.GetOrigin()-self.GetOrigin()).Length()>500) ThinkingTime=0.1
	if ((player.GetOrigin()-self.GetOrigin()).Length()>1000) ThinkingTime=0.5
	
	if ((player.GetOrigin()-self.GetOrigin()).Length()>1000&&!disabled&&GetMapName().find("mapgens")!=null) {EntFireByHandle(self,"setthinknull");disabled=true}
	if ((player.GetOrigin()-self.GetOrigin()).Length()<=1000&&disabled&&GetMapName().find("mapgens")!=null) {EntFireByHandle(self,"setthinknpc");disabled=false}

	//local schedule=self.GetSchedule()
	if (self.GetHealth()<=0) return
	local activity=self.GetActivity()
	speedmod=clamp(((Time()-lastwalktime)/2.0),0,3)
	if (self.FindGestureLayer("ACT_FLINCH_LEFTLEG")!=-1||self.FindGestureLayer("ACT_FLINCH_RIGHTLEG")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_RIGHTARM")!=-1||self.FindGestureLayer("ACT_GESTURE_FLINCH_LEFTARM")!=-1||(self.GetLastDamageTime()>(Time()-0.25))||((parrytime+1)>Time())) return ThinkingTime
	EntFireByHandle(self,"setplaybackrate",1.1,0.00);
	EntFireByHandle(self,"setspeedmodifier",1.1,0.00);
	//if (self.GetClassname()=="npc_zombie"&&self.GetEnemy()!=player) self.SetEnemy(player)
	
	if (self.GetSchedule()=="SCHED_IDLE_STAND"&&(self.entindex()%4)==0) self.SetSchedule("SCHED_IDLE_WANDER")
	
	if (!self.GetEnemy()) return ThinkingTime;
	if ((self.GetActivity()=="ACT_MELEE_ATTACK1")&&(self.GetCycle()<0.2)) {self.SetVelocity((self.GetEnemy().GetVelocity()/3+self.GetEnemy().GetOrigin()-self.GetOrigin()).Normalized()*170)};
    if (((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<100)&&(self.GetActivity()!="ACT_MELEE_ATTACK1"))
	{
		//printl("KILL")
		//self.SetSchedule("SCHED_ZOMBIE_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		self.SetSchedule("SCHED_MELEE_ATTACK1")
		self.SetActivity("ACT_MELEE_ATTACK1")
	}
    return ThinkingTime;
}


Hooks.Add( this, "HandleAnimEvent", HandleAttack, "HandleAttack" );