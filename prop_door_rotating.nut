
local whitelisted=null
local whitelist_time=0;

if (self.GetClassname()=="prop_door_rotating")
{
	local opened=false
	self.PrecacheSoundScript("ep2_outland_11.hunter_bang_door")

	local IsEnabled=false

	function InputUse()
	{
		IsEnabled=true
		EntFireByHandle(self,"SetAnimation","open",0.01)
		EntFireByHandle(self,"SetAnimation","idle",0.18)
		if (!opened) { EntFireByHandle(self,"openawayfrom","!player",0); opened=true } 
		else { EntFireByHandle(self,"close","",0.2); self.EmitSound("DoorHandles.Unlocked1"); opened=false } 
		//printl("forcefully moving the door")
	}
	function TextureMe(room_id=0, type=0)
	{
		if (self.GetClassname()=="prop_door_rotating")
		{
			self.SetSkin(type);
		}
	}

	function KillBlocker(room_id=0, type=0)
	{
		//printl("BLOCKED by "+activator)
		if (activator==player) return;
		if ((Time()-whitelist_time)<1.5) return;
		activator.SetHealth(activator.GetHealth()-50)
		local Damage=CreateDamageInfo(player,player,Vector(0,0,0),Vector(0,0,0),70,128)
		Damage.SetDamageForce((self.GetOrigin()-player.GetOrigin()).Normalized()*20000)
		EntFireByHandle(self,"setspeed","900",0.0)
		EntFireByHandle(self,"setspeed","135",0.3)
		activator.TakeDamage(Damage)
		DestroyDamageInfo(Damage);
		EntFireByHandle(self,"openawayfrom","!player",0)
		self.EmitSound("ep2_outland_11.hunter_bang_door")
		activator.EmitSound("ep2_outland_11.hunter_bang_door")
	}
}
function Think()
{
	local npc=null
	npc=Entities.FindByClassnameWithin(npc, "npc*", self.GetOrigin(), 64)
	if (npc&&"GetNPCState" in npc&&npc.GetNPCState()>0&&npc.GetBoundingMaxs().z>36)
	{
		local name=npc.GetName()
		npc.SetName("DOOR_OPENER")
		if (self.GetClassname()=="prop_door_rotating") self.AcceptInput("openawayfrom", "DOOR_OPENER", npc,npc);
		else self.AcceptInput("open", "", npc,npc);
		npc.SetName(name)
		whitelisted=npc
		whitelist_time=Time()
		if ((player.GetOrigin()-self.GetOrigin()).Length()>400&&(self.GetClassname()=="prop_door_rotating"))
		{
			self.AddSpawnFlags(4096)
			EntFireByHandle(self,"removespawnflags",4096,2)
		}
		return 5
	}
	return 1
}

self.SetThinkFunction("Think",3)
self.ConnectOutput( "OnBlockedOpening", "KillBlocker" )


local FirstClientSound=false
// set speedmod. and probably also set thinking to null(unless angry)

function CheckObstruction()
{
	
	local lastEnable=IsEnabled
	foreach (i,hull in Hulls)
	{
		//if (!(i.tostring() in PVSStatus)) PVSStatus.rawset(i.tostring(),null);
		//printl(PVSStatus.len())
		if (PVSStatus.len()==0) break;
		
		if (VisibleSet.find(i)==null)
		{
			// INVISIBLE
			//DrawHull(hull,55,55,55,0);
			
			//EntFire(i+"_*","addeffects",32)
			//printl(PVSStatus[i.tostring()])
			if (IsOriginInBBox(self.GetCenter(),hull[0],hull[1])) {IsEnabled=false;break}
		}
		else
		{
			if (IsOriginInBBox(self.GetCenter(),hull[0],hull[1])) {IsEnabled=true;break}
		}
	}
	
	if (lastEnable!=IsEnabled||!FirstClientSound)
	{
		NetMsg.Start("EMITSOUND_CL")
		NetMsg.WriteEntity(self)
		printl("sending "+IsEnabled)
		NetMsg.WriteBool(IsEnabled);
		NetMsg.Send(player,true);
		FirstClientSound=true
	}
}

