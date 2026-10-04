Entities.First().PrecacheSoundScript("k_lab.teleport_breathing")

local Defeated=false

function CheatDeath(...)
{
	if (Defeated) return false;
	
	EntFire("boss_die","BeginSequence","",0)
	self.EmitSound("k_lab.teleport_breathing")
	//EntFire("gordon","SetPlaybackRate","",0)
	SendToConsole("host_pitchscale 1")
	player.SetHealth(clamp(player.GetHealth()+45,0,100))
	
	Defeated=true
	
	return false;
}
function OnPostSpawn()
{
	self.SetMaxHealth(2500)
	self.SetHealth(2500)
	EntFire("gordon","SetBloodColor","3",0.5)
	player.RemoveAmmo(10,22)	//NO BALLS
	Hooks.Add(this,"OnDeath",CheatDeath,"CheatDeath");
}

function Think()
{
	if (self.GetHealth()>250) self.SetPlaybackRate(1.5)
	Convars.SetFloat("sk_advisor_health",self.GetHealth())
}