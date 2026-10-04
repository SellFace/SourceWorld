local opened=true
IncludeScript("base.nut")
self.PrecacheSoundScript("Doors.Move13")
self.PrecacheSoundScript("Doors.FullClose2")
local origin=self.GetOrigin();
local Start=Time()
local End=Time()
local OriginalPos=origin
local Light=Entities.FindByName(null,self.GetName().slice(0,self.GetName().find("r")+1)+"_blight")


function Think()
{
	Light=Entities.FindByName(null,self.GetName().slice(0,self.GetName().find("r")+1)+"_blight")
	local Door=Entities.FindByName(null,self.GetName()+"_door")
	local zdif=abs(self.GetOrigin().z-Door.GetOrigin().z)
	if (!Light) return
	local Distance=CalcDistanceToLine(player.GetOrigin(),(self.GetOrigin()+RotateVectorByAngle(Vector(0,-44,-130),self.GetAngles().y)),(self.GetOrigin()+RotateVectorByAngle(Vector(10,-44,-130),self.GetAngles().y)))
	if (Distance>100&&self.GetOrigin().z<200) EntFireByHandle(Light,"HideSprite")
	if (Distance<100&&self.GetOrigin().z<200&&zdif>60) EntFireByHandle(Light,"ShowSprite")
	else EntFireByHandle(Light,"HideSprite")
}
function Use()
{
	EntFire(self.GetName()+"_door","runscriptcode","Use()",0)
	local Door=Entities.FindByName(null,self.GetName()+"_door")
}

self.ConnectOutput( "OnPressed", "Use" )
