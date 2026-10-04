local Distance=750
if (self.GetClassname()=="func_dustmotes") Distance=450;

function Think()
{
	if ((self.GetCenter()-player.GetCenter()).Length()>Distance)
	{
		EntFireByHandle(self,"TurnOff")
	}
	else
	{
		EntFireByHandle(self,"TurnOn")
	}
	
	return 2.0
}

// This is necessary to fix flickering decals in demo_city.
// Since I was too lazy to bother putting triggers on the map for disabling these, i decided to just make a simple script.

// This is also used for dustmotes. Valve didn't bother to code them actually NOT rendering when you're outside their radius, so even if you were far enough, they'd still fill particle limits.
// That was really dumb, you always knew you put too many dustmotes when explosives stopped showing up. Thankfully, not on my shift.