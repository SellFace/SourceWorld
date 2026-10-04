
local shutit=false

::NPC_NextIdleYapTime<-Time()+(RandomInt(10,200)+RandomInt(10,200)+RandomInt(10,200))/3

local LastUse=0

function InputUse()
{
	if (Time()-LastUse<1.5) return;
	
	LastUse=Time()
	
	NPC_NextIdleYapTime-=10;
	
	if (self.GetName()=="SGT")
	{
		EntFire("stamina_system","RunScriptCodeQuotable","Capty("+RandomInt(6,9)+",''"+self.GetName()+"'')",0)
		return
	}
	if (self.GetName()=="vest_cop"&&!shutit)
	{
		if (EQUIPMENT[1]==null) EntFire("stamina_system","RunScriptCodeQuotable","Capty("+RandomInt(101,104)+",''"+self.GetName()+"'')",0)
		else
		{
			EntFire("stamina_system","RunScriptCodeQuotable","Capty(106,''"+self.GetName()+"'')",6)
			EntFire("stamina_system","RunScriptCodeQuotable","Capty(105,''"+self.GetName()+"'')",0)
			EntFire("dooropen","BeginSequence","",1)
			shutit=true;
			return
		}
		return
	}
	if (self.GetName()!="vest_cop") EntFire("stamina_system","RunScriptCodeQuotable","Capty("+RandomInt(1,5)+",''"+self.GetName()+"'')",0)

}


self.PrecacheSoundScript("dsecurity.idle1")
self.PrecacheSoundScript("dsecurity.idle2")
self.PrecacheSoundScript("dsecurity.idle3")
self.PrecacheSoundScript("dsecurity.idle4")
self.PrecacheSoundScript("dsecurity.idle5")
self.PrecacheSoundScript("dsecurity.idle6")
self.PrecacheSoundScript("dsecurity.idle7")
self.PrecacheSoundScript("dsecurity.idle8")

function Think()
{
	// Vanilla response system idle concept made them yap too frequently which was annoying, so I've vscripted their idle noises
	// They can't yap when player cant see them or too far, and the interval is much bigger now.
	
	// Pressing use on them makes them more likely to yap though.
	
	if (self.IsEntVisible(player)&&self.GetOrigin().DistTo(player.GetOrigin())<800&&(Time()>NPC_NextIdleYapTime))
	{
		self.EmitSound("dsecurity.idle"+RandomInt(1,8))
		NPC_NextIdleYapTime=Time()+(RandomInt(10,200)+RandomInt(10,200)+RandomInt(10,200))/3
		return 1
	}
	//printl(NPC_NextIdleYapTime-Time())
	return RandomFloat(5,30)
}
self.SetThinkFunction("Think",1)