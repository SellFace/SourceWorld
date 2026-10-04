local MoveSpeed=0
local MoveVector=Vector()
local LastPos=Vector()
local LastRun=Time()
local IsAccelerating=false
local IsDeccelerating=false
//printl("SPEEDFIX STARTED")

/*
function NPC_TranslateActivity()
{
	if ((Time()-LastRun)<2.0) return;
	if (self.GetClassname()=="monster_generic") return;
	local vel = GetPhysVelocity(self.GetPhysicsObject())
    local newactivity = -1;
    if (activity.find("WALK") != null)
	{
		local counter=0
		Entities.First().SetContextThink("NPCMOVEW"+RandomInt(0,100),function(...)
		{
			vel = GetPhysVelocity(self.GetPhysicsObject())
			//self.SetVelocity(vel.Normalized()*84);
			counter++
		}.bindenv(this),0.15)
		Entities.First().SetContextThink("NPCMOVEW"+RandomInt(0,100),function(...)
		{
			vel = GetPhysVelocity(self.GetPhysicsObject())
			//self.SetVelocity(vel.Normalized()*84);
			counter++
		}.bindenv(this),0.05)
		//LastPos=self.GetOrigin()
		LastRun=Time()
	}
	if (activity.find("RUN") != null)
	{
		local counter=0
		//printl("SPEEDFIX ACTIVE")
		Entities.First().SetContextThink("NPCMOVE"+RandomInt(0,100),function(...)
		{
			vel = GetPhysVelocity(self.GetPhysicsObject())
			//self.SetVelocity(vel.Normalized()*210);
			counter++
		}.bindenv(this),0.05)
		Entities.First().SetContextThink("NPCMOVE"+RandomInt(0,100),function(...)
		{
			vel = GetPhysVelocity(self.GetPhysicsObject())
			//self.SetVelocity(Vector());
			counter++
		}.bindenv(this),0.16)
		//LastPos=self.GetOrigin()
		LastRun=Time()
	}
	else
	{
		//moving=false
	}
    return newactivity;
}
*/

//def citizen speeds 84, 220
local PrevDir=0


AttackStartTime<-0
local parrytime=0
attacktime<-0

function SpeedThink()
{
	if ((self.GetActivity().find("ACT_MELEE_ATTACK")!=null)&&(self.GetCycle()<0.2)) {self.SetVelocity((self.GetEnemy().GetVelocity()/3+self.GetEnemy().GetOrigin()-self.GetOrigin()).Normalized()*330)};
    
	if (self.GetClassname()=="monster_generic") return;
	local activity=self.GetActivity()
	
	EntFireByHandle(self,"ChangeVariable","m_vecLean 0 0 0",0)
	
	if (activity.find("WALK") != null||activity.find("RUN") != null)
	{
		local Difference=(self.GetOrigin()-LastPos).Length();
		MoveVector=(self.GetOrigin()-LastPos)*10

		MoveSpeed=Difference*10
		LastPos=self.GetOrigin();
		//printl("Speed: "+MoveSpeed)
		//printl(GetPhysVelocity(self.GetPhysicsObject()))
	}
	
	local Direction=VectorAngles(GetPhysVelocity(self.GetPhysicsObject()).Normalized()).y
	
	if (activity.find("IDLE"))
	{
		MoveSpeed=0
		//EntFireByHandle(self,"setspeedmodifier",0,0)
		PrevDir=Direction
		EntFireByHandle(self,"ChangeVariable","m_vecLean 0 0 0",0)
		return 0.1
	}
	
	if (activity.find("WALK"))
	{
		local vel = GetPhysVelocity(self.GetPhysicsObject())
		//self.SetVelocity(vel.Normalized()*84);
		//if (vel>140) self.SetVelocity(vel.Normalized()*0);
	}
	
	if (activity.find("RUN"))
	{	
		//printl("SPEEDFIX THINK ACTIVE")
		local vel = GetPhysVelocity(self.GetPhysicsObject())
		local speed=vel.Length()
		//printl(220.0/speed*2.0)
		//EntFireByHandle(self,"SetSpeedModifier",clamp(pow(220/speed,6),1,8),0)
		self.AcceptInput("SetSpeedModifier",clamp(pow(220/speed,3),1,8).tostring(),self,self)
		//self.AcceptInput("AddOutput","BaseSpeedModifier "+clamp(pow(220/speed,4),1,16),self,self)
		NetProps.SetPropFloat(self,"m_flHealth",0.5)
		EntFireByHandle(self,"ChangeVariable","m_vecLean 0 0 0",0)
		//printl(speed)
		//printl(vel)
		//printl(vel.Length())
		//if ((fabs(Direction-PrevDir)<20)&&(vel.Length()>10)) self.SetVelocity(vel.Normalized()*210);
		//else
		//{
			//self.SetVelocity(Vector());
			//self.SetActivity("ACT_IDLE")
		//}
	}
	if (self.GetTask().find("WAIT_FOR_MOVEMENT")!=null)
	{
		local vel = GetPhysVelocity(self.GetPhysicsObject())
		//self.SetVelocity(vel/1.5);
		//self.SetVelocity(vel.Normalized()*0);
		//if (fabs(Direction-PrevDir))>170) self.SetVelocity(vel.Normalized()*0);
	}
	//printl(self.GetTask().find("WAIT_FOR_MOVEMENT")==null)
	
	PrevDir=Direction
	
	return 0.11
}