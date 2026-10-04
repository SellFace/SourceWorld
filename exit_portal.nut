self.PrecacheSoundScript("d3_citadel.portal_shoot_beam2")
self.PrecacheSoundScript("ambient/levels/labs/teleport_mechanism_windup3.wav")

local StageID=Globals.GetCounter(Globals.GetIndex("StageID"))
local WorldID=Globals.GetCounter(Globals.GetIndex("WorldID"))
local StageCount=Globals.GetCounter(Globals.GetIndex("StageCount"))
local PortalToLab=(StageCount-1)<=StageID;

function Precache()
{
	PrecacheParticleSystem("vortigaunt_hand_glow_c")
}
function OnPostSpawn()
{
	DispatchParticleEffect("vortigaunt_hand_glow_c",self.GetOrigin(),Vector(0,0,0),self)
}

local prog=0

function Progress()
{
	prog+=0.3;
	Convars.SetFloat("mat_local_contrast_vignette_end_override",0)
	Convars.SetFloat("mat_local_contrast_scale_override",prog*(-0.02))
	player.ViewPunch(Vector(cos(Time()*3)*prog*0.008,sin(Time()*3)*prog*0.008,cos(Time()*2)*prog*0.01))
	player.SetVelocity((self.GetOrigin()-player.GetCenter()).Normalized()*12)
	
	if (prog>100&&prog<200) Teleport()
	if (prog>100&&prog<200) prog=200;
}

function Teleport()
{
	if (player.GetHealth()<=0) return;
	
	
	
	player.AddFlag(32)
	local NextSeed=0
	if (!PortalToLab)
	{
		NextSeed=Globals.GetCounter(Globals.GetIndex("StageSeed"+(StageID+1)))
		SendToConsole("global_set RNGSeed 1");
		SendToConsole("global_counter RNGSeed "+NextSeed);
		SendToConsole("global_set InitialRNGSeed 1");
		SendToConsole("global_counter InitialRNGSeed "+NextSeed);
		SendToConsole("global_counter StageID "+(StageID+1));
	}
	else
	{
		SW_MULTIVERSE.rawset(WorldID.tostring(),3)
	}
	
	Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().SaveData()
	if (PortalToLab) Entities.First().SetContextThink("Exit_Teleport",function(...){SendToConsole("changelevel teleporting_room_v1")}.bindenv(this),1);
	else Entities.First().SetContextThink("Exit_Teleport",function(...){SendToConsole("changelevel mapgen_test")}.bindenv(this),1);
	self.EmitSound("d3_citadel.portal_shoot_beam2")
	EntFire("exit_fad*","Fade","",0)
}	
local First=false;

local InProgress=false

function Think()
{
	if (prog==200) return;
	local PlayerPos=player.GetCenter();
	//if (!First) DispatchParticleEffect("vortigaunt_hand_glow_c",self.GetOrigin(),Vector(0,0,0),self);
	//if (!First) First=true;
	local PortalPos=self.GetOrigin()
	local Distance=(PlayerPos-PortalPos).Length()
	//printl(prog)
	local s2=EmitSound_t()
	if (prog>0)
	{
		Convars.SetFloat("mat_local_contrast_vignette_end_override",0)
		Convars.SetFloat("mat_local_contrast_scale_override",prog*(-0.02))
		s2.SetVolume(clamp(RemapVal(prog,0,100,0,2),0,1))
		s2.SetFlags(1+2+128)
		s2.SetSoundName("ambient/levels/labs/teleport_mechanism_windup3.wav")
		s2.SetOrigin(self.GetOrigin())
	}
	else if (InProgress)
	{
		Convars.SetFloat("mat_local_contrast_scale_override",0)
		s2.SetVolume(0)
		s2.SetFlags(1+2)
		s2.SetSoundName("ambient/levels/labs/teleport_mechanism_windup3.wav")
		self.StopSound("ambient/levels/labs/teleport_mechanism_windup3.wav")
		InProgress=false
	}
	EmitSoundParamsOn(s2,self)
	if (Distance<32)
	{
		InProgress=true;
		Progress()
		//return 0.1
	}
	else prog=clamp(prog-1,0,100);
	EntFire("ambience_porta*","SetAbsAngles",VectorAngles(self.GetOrigin()-player.EyePosition()).x+" "+VectorAngles(self.GetOrigin()-player.GetOrigin()).y+" 0",0)
	EntFire("portal*","SetAbsAngles",VectorAngles(self.GetOrigin()-player.EyePosition()).x+" "+VectorAngles(self.GetOrigin()-player.GetOrigin()).y+" 0",0)
	//printl(VectorAngles(self.GetOrigin()-player.GetOrigin()).y)
	
	if (self.IsEntVisible(player))
	{
		EntFire("ambience_porta*","Volume","10",0)
		return 0
	}
	else
	{
		EntFire("ambience_porta*","Volume","2",0)
	}
	return 0.1
}
