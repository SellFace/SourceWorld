local opened=true
IncludeScript("base.nut")
self.PrecacheSoundScript("Doors.Move13")
self.PrecacheSoundScript("Doors.FullClose2")
self.PrecacheSoundScript("d3_citadel.breenlift1_move")
self.PrecacheSoundScript("Town.d1_town_02_elevbell1")
self.PrecacheSoundScript("Airboat_NoSound")
local origin=self.GetOrigin();
local Start=Time()
local End=Time()
local OriginalPos=origin
local Blocked=true
function Open()
{
	Start=Time()
	End=Time()+1.0
	OriginalPos=origin
	self.SetThinkFunction("Think",0)
	self.EmitSound("Doors.Move13")
	Blocked=false
}
function CheckClose()
{
	if (opened) return;
	Blocked=true
	printl("changefloor!")
	local Destination=self.GetName().slice(self.GetName().find("r")+2,self.GetName().find("_door"))
	local Door=Entities.FindByName(null,self.GetName().slice(0,self.GetName().find("_door")))
	local Light=Entities.FindByName(null,self.GetName().slice(0,self.GetName().find("r")+1)+"_light")
	printl(Destination)
	EntFire("logic_scri*","runscriptcode","TeleportToFloor("+Destination+")",3)
	EntFire("elevator_shake","startshake","",0.45)
	EntFire("elevator_shake","stopshake","",2.25)
	//self.EmitSound("d3_citadel.small_elevator_move")
	Entities.First().SetContextThink("Elev1",function(...){self.EmitSound("d3_citadel.breenlift1_move")}.bindenv(this),0.45)
	//Entities.First().SetContextThink("Elev2",function(...){self.StopSound()}.bindenv(this),2.5)
	Entities.First().SetContextThink("Elev3",function(...)
	{
		//self.EmitSound("Airboat_NoSound");
		self.StopSound("d3_citadel.breenlift1_move");
		Light.Destroy();
		Door.Destroy();
		self.Destroy()
	}.bindenv(this),4)
	local Elev=null
	
	local Ent=null
	local ElevatorContent=[]
	local MovedPlayer=false
	while (Ent = Entities.FindByClassnameWithinBox(Ent,"*",self.GetOrigin()+Vector(-64,-64,-100),self.GetOrigin()+Vector(64,64,100)))
	{
		if ("GetModelName" in Ent) if (Ent.GetModelName().find("mapgen")!=null&&Ent.GetModelName().find("elev")==null) continue;
		if (Ent.GetClassname()=="env_sprite") continue
		ElevatorContent.append(Ent)
	}
	
	while (Elev=Entities.FindByName(Elev,"*_elevato*"))
	{
		if (Elev!=self&&Elev!=Light&&Elev!=Door) Elev.Destroy();
	}

	local Up=Vector(0,0,260)
	local playerpos=player.GetOrigin()
	foreach (item in ElevatorContent)
	{
		local targetpos=(item.GetOrigin()+Up)
		item.AcceptInput("setabsorigin",targetpos.x+" "+targetpos.y+" "+targetpos.z,null,null)
		item.AcceptInput("setlocalorigin",targetpos.x+" "+targetpos.y+" "+targetpos.z,null,null)
		EntFireByHandle(item,"setabsorigin",targetpos.x+" "+targetpos.y+" "+targetpos.z,0)
		item.SetOrigin(targetpos)
		if (item==player) MovedPlayer=true;
	}
	if (!MovedPlayer||(player.GetOrigin().z<260))
	{
		player.SetOrigin(player.GetOrigin()+Vector(0,0,260))
		NPrint(25,"Forcefully teleporting player up.");
		printl("Forcefully teleporting player up.");
	}
	player.SetOrigin(playerpos+Vector(0,0,260))
	//self.SetOrigin(self.GetOrigin()+Up)
	//Door.SetOrigin(Door.GetOrigin()+Up)
	//Light.SetOrigin(Light.GetOrigin()+Up)
	//player.SetOrigin(player.GetOrigin()+Up)
}

function Think()
{
	if (End<Time()) { CheckClose();self.EmitSound("Doors.FullClose2"); self.StopThinkFunction(); return}
	local Distance=CalcDistanceToLine(player.GetOrigin(),(self.GetOrigin()+RotateVectorByAngle(Vector(0,-64,-130),self.GetAngles().y)),(self.GetOrigin()+RotateVectorByAngle(Vector(10,-64,-130),self.GetAngles().y)))
	if (Distance>100&&!opened) player.SetVelocity((self.GetOrigin()-Vector(0,0,130)-player.GetOrigin())*4);
	local diff=(End-Time())/1.0
	self.SetOrigin(OriginalPos+Vector(0,0,95)*opened.tointeger()-Vector(0,0,95*(opened.tointeger()-0.5)*2)*diff)
	return 0
}
function Use()
{
	local Distance=CalcDistanceToLine(player.GetOrigin(),(self.GetOrigin()+RotateVectorByAngle(Vector(0,-64,-130),self.GetAngles().y)),(self.GetOrigin()+RotateVectorByAngle(Vector(10,-64,-130),self.GetAngles().y)))
	if (End>Time()||Blocked) return;
	if (!opened) { printl("open"); opened=true}  
	else { 
		printl("close")
		//self.EmitSound("Doors.Move13") 
		if (Convars.GetBool("developer")) debugoverlay.Line(player.GetOrigin(),self.GetOrigin()+RotateVectorByAngle(Vector(0,-64,-130),self.GetAngles().y),2,1,212,false,20.0)
		printl(Distance)
		if (Distance<100) opened=false 
	} 
	if (Distance<100) Open();
	printl("forcefully moving the door")
}
self.EmitSound("Town.d1_town_02_elevbell1")
//printl("prekol")
//Open()

function OnPostSpawn()
{
	//opened=false
	EntFireByHandle(self,"Runscriptcode","Open()",1.5)
}

self.ConnectOutput( "OnPressed", "Use" )
