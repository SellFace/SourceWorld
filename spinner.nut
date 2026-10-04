function OnPostSpawn()
{
	SpawnOrigin<-self.GetOrigin()+Vector(0,0,-8);
}

Active<-false;	
AnimTime<-0;
LastYaw<-0;

function FacePlayer()
{
	Active=true
	LastYaw=self.GetAngles().y
	AnimTime=Time()
}

function StopFacingPlayer()
{
	Active=false
	LastYaw=self.GetAngles().y
	AnimTime=Time()
}

NetMsg.Receive("SaveSpin", function( player )
{
	//StopFacingPlayer()
	
	local savepoint=null
	while (savepoint=Entities.FindByName(savepoint,"sw_savepoint"))
	{
		savepoint.GetScriptScope().StopFacingPlayer()
	}
	
}.bindenv(this))

function Think()
{
	local z=sin(Time())*4
	local YawSpin=LastYaw+((Time()-AnimTime)*75)%360
	local YawActive=VectorAngles(player.GetOrigin()-self.GetOrigin()).y-90;
	
	local yaw=YawSpin
	
	if (Active) yaw=YawActive;
	
	if (Active&&((Time()-AnimTime)<1))
	{
		local a=sqrt(Time()-AnimTime)
		
		yaw=LastYaw+AngleDiff(YawActive,LastYaw)*a
	}
	
	if (!Active&&((Time()-AnimTime)<1))
	{
		local a=sqrt(Time()-AnimTime)
		
		yaw=YawActive-AngleDiff(YawActive,YawSpin)
	}
	
	//self.SetVelocity(Vector(0,cos(Time())*4,0)
	//self.SetAngularVelocity(0,70,0)
	self.SetOrigin(SpawnOrigin+Vector(0,0,z))
	self.SetAngles(Vector(0,yaw,0))
	return 0
}

