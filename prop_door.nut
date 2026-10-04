

local state=false // false - closed, true - open.

local closepos=null
local openpos=null

local door=null

local doortable=
{
	movedir="-90 0 0"
	spawnflags=32
	speed=100
	lip=0
	model=self.GetModelName()
	origin="-1100 450 128"
}

if (Entities.FindByName(null,self.GetName())&&Entities.FindByName(null,self.GetName()).GetClassname()=="func_door") return;

doorspawned<-false

function OnPostSpawn()
{
	closepos=self.GetOrigin()
	openpos=closepos+Vector(0,0,(-self.GetBoundingMins()+self.GetBoundingMaxs()).z*2)
	
	self.SetMoveType(7)
	self.SetSolid(6)
	self.AddSpawnFlags(256)
	//self.AddSpawnFlags(512)
	//self.AcceptInput("disablemotion","",null,null)
	self.SetCollisionGroup(0)
	self.AddSpawnFlags(512)
	self.GetPhysicsObject().SetMass(9999)
	Use(false)
}

local speed=2

local TargetPos=null

local lastvel=Vector()

function VPhysicsCollision()
{
	//printl(entity)
	//entity.SetVelocity((TargetPos - ((state) ? closepos : openpos))*speed)
}

local opensound=""
local fullyopensound=""
local lastsound=""


function ToVector(str)
{
	if ((typeof str)=="Vector") return str
	local ar=split(str," ")
	return Vector(ar[0].tofloat(),ar[1].tofloat(),ar[2].tofloat())
}
RotateVector<-function(A,B,RotatedByAngle=Vector()){local m=matrix3x4_t();AngleMatrix(B,Vector(0,0,0),m);return VectorRotate(A,m)}

function Use(move=true)
{
	if (!doorspawned)
	{
		doortable=SW_PROP_DOORS[self.GetContext("doortable")]
		doortable.model=self.GetModelName();
		doortable.targetname<-self.GetName()
		doortable.vscripts<-""
		doortable.classname<-"func_door"
		local neworigin=self.GetOrigin()+Vector(0,0,-5000)
		local newangle=self.GetAngles()
		if ((self.GetAngles().y%180)!=0&&ToVector(doortable.movedir).y!=0)
		{
			local xsize=(self.GetBoundingMaxs().x-self.GetBoundingMins().x)
			local ysize=(self.GetBoundingMaxs().y-self.GetBoundingMins().y)
		
			doortable.lip=doortable.lip.tointeger()+(xsize-ysize)
		}
		doortable.origin=neworigin.x+" "+neworigin.y+" "+neworigin.z
		doortable.angles=newangle.ToKVString()
		
		local dirvec=ToVector(doortable.movedir)
		
		doortable.movedir=(Vector(dirvec.x,dirvec.y+self.GetAngles().y,dirvec.z)).ToKVString()
		door=SpawnEntityFromTable("func_door",doortable)
		//door.SetOrigin(self.GetOrigin()+Vector(0,0,-2000))
		//door.SetSize(Vector(),Vector(1,1,1)*doortable.distance.tointeger())
		doorspawned=true;
		
		self.SetParent(door,"")
		
		self.PrecacheSoundScript(doortable.noise1)
		self.PrecacheSoundScript(doortable.noise2)
		
		foreach( k,v in doortable) printl(k+" "+v)
		
		opensound=doortable.noise1
		fullyopensound=doortable.noise2

		door.GetOrCreatePrivateScriptScope().ModifyEmitSoundParams<-function ()
		{
			self.PrecacheSoundScript(params.GetSoundName())
			//I really spent like half of an hour trying to figure out how to stop looping sounds and found this combination of flags to do it.
			params.SetFlags(SND_STOP+SND_STOP_LOOPING+SND_IGNORE_NAME)
			EmitSoundParamsOn(params,self)
			params.SetFlags(0)
			EmitSoundParamsOn(params,self)
			lastsound=params.GetSoundName()
		}.bindenv(this)
		
		function OnFullyOpen()
		{
			self.EmitSound(fullyopensound)
			//self.StopSound(lastsound)
		}

		function OnClose()
		{
			self.EmitSound(opensound)
			
			if ("open_others_radius" in doortable)
			{
				local NextDoor=null
				while (NextDoor=Entities.FindByClassnameWithin(NextDoor,"prop_interactable",self.GetOrigin(),doortable.open_others_radius.tofloat()))
				{
					NextDoor.AcceptInput("Close","",null,null);
				}
			}
		}
		function OnFullyClosed()
		{
			self.EmitSound(fullyopensound)
			//self.StopSound(lastsound)
		}
		

		door.ConnectOutput("OnOpen","OnOpen")
		door.ConnectOutput("OnClose","OnClose")
		door.ConnectOutput("OnFullyOpen","OnFullyOpen")
		door.ConnectOutput("OnFullyClosed","OnFullyClosed")
	}

	state=!state
	//printl(state ? "closing" : "opening")
	//printl(door)
	//printl(door.GetOrigin())
	if (move) 
	{
		door.AcceptInput("toggle","",null,null);
		
		if ("open_others_radius" in doortable)
		{
			//printl("Opening adjacent doors in radius "+doortable.open_others_radius)
			local NextDoor=null
			while (NextDoor=Entities.FindByClassnameWithin(NextDoor,"prop_interactable",self.GetOrigin(),doortable.open_others_radius.tofloat()))
			{
				NextDoor.AcceptInput("Use","",null,null);
			}
		}
	}
}

function Think()
{
	local npc=null
	npc=Entities.FindByClassnameWithin(npc, "npc*", self.GetOrigin(), 100)
	if (npc&&"GetNPCState" in npc&&npc.GetNPCState()>0&&npc.GetBoundingMaxs().z>36)
	{
		self.AcceptInput("use", "", npc,npc)
		return 5
	}
	return 1
}

//function InputOpen() {if (!doorspawned) Use();}
//function Inputopen() {if (!doorspawned) Use();}
//function InputClose() {if (!doorspawned) Use();}
//function Inputclose() {if (!doorspawned) Use();}

self.ConnectOutput("OnPressed","Use")
self.ConnectOutput("OnPlayerUse","Use")