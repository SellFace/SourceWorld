local flash = {
	_cone = 0,
	_inner_cone = 0,
	_light = "255 255 255 2200",
	brightness = 1,
	distance = 520
	pitch = -90,
	//spawnflags = 1,
	style=1
}

function Precache()
{
	self.PrecacheSoundScript("weapons/flashbang_explode2.wav")
}

function SetTimer(a)
{
	Entities.First().SetContextThink("FlashbangTimer_"+self.entindex(),function(...)
	{
		local flashEnt2 = SpawnEntityFromTable("light_dynamic", flash)
		flashEnt2.SetOrigin(self.GetOrigin())
		EntFireByHandle(flashEnt2, "Kill", "", 0.15)
		
		self.EmitSound("weapons/flashbang_explode2.wav")
		
		local npc=null
		
		while (npc=Entities.FindByClassname(npc,"npc_*"))
		{
			if (npc.GetClassname().find("maker")!=null||npc.GetClassname().find("grenade")!=null)
				continue;
			if (self.IsEntVisible(npc))
				SW_ApplyStatusEffect("STUN",npc,8)
		}
		
		if (self.IsEntVisible(player))
		{
			local stunstrength=0
			
			local front=CalcDistanceToLineSegment(self.GetOrigin(),player.EyePosition(),player.EyePosition()+player.GetEyeForward()*1024)
			local back=CalcDistanceToLineSegment(self.GetOrigin(),player.EyePosition(),player.EyePosition()+player.GetEyeForward()*(-1024))
			
			stunstrength=RemapValClamped(front,50,500,10,1).tointeger()
			if (front>back) stunstrength=0;
			
			printl("FLASHED for "+stunstrength)
			if (stunstrength>0)
			{
				SW_ApplyStatusEffect("STUN",player,stunstrength)
				SendToConsole("dsp_room 50")
				SendToConsole("fadein "+stunstrength*0.5+" 255 255 255 255")
			}
		}
		self.Destroy()
		return
	}.bindenv(this),a)
}