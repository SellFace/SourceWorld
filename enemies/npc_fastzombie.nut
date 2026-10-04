IncludeScript("enemies/base_enemy.nut")
local disabled=false;
function Think()
{
	if ((player.GetOrigin()-self.GetOrigin()).Length()>1000&&!disabled&&GetMapName().find("mapgens")!=null) {EntFireByHandle(self,"setthinknull");disabled=true}
	if ((player.GetOrigin()-self.GetOrigin()).Length()<=1000&&disabled&&GetMapName().find("mapgens")!=null) {EntFireByHandle(self,"setthinknpc");disabled=false}

	if (self.GetSchedule()=="SCHED_IDLE_STAND"&&(self.entindex()%4)==0) self.SetSchedule("SCHED_IDLE_WANDER")
    return 3;
}