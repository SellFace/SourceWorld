/*
Your wings weren't mine—
I knew from the start.
I hoped you'd keep me
in your heart.

Now you've found new skies,
new voice, new light—
and I'm left asking why
the angel took flight.
*/


local dosound=true;

local Slipping=false;
local LastExitTime=0;

function DoSound()
{
	if (dosound)
	{
		GetNamedEnt("stamina_system").GetScriptScope().FootstepSound("concrete")
		Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().RightStep=!Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().RightStep
	}
	dosound=!dosound
}

local SlipPoint=null
local SlipEnd=null

local sequence=null
local seat=null

function StartSlip()
{
	Slipping=true;
	
	local SlipDir=(SlipEnd.GetOrigin()-SlipPoint.GetOrigin()).Normalized()
	local StartPos=SlipPoint.GetOrigin()+Vector(0,0,-8)-SlipDir*14
	
	//player.SetMoveType(0)
	player.SetVelocity(Vector())
	player.SetOrigin(StartPos-SlipDir*48)
	player.SetLocalOrigin(StartPos-SlipDir*48)
	
	local playertable={
		model="models/player.mdl"
		origin=StartPos.ToKVString()
		angles=VectorAngles(SlipDir).ToKVString()
		model="models/player.mdl"
		targetname="PlayerModel"
		spawnflags=1048576+16384+1024
		SpawnWithStartScripting=1
		rendermode=1
		citizentype=4
		rendermode=6
	}
	local npc=SpawnEntityFromTable("npc_citizen",playertable)
	
	local mins = NetProps.GetPropVector( npc, "m_Collision.m_vecMins" );
	local maxs = NetProps.GetPropVector( npc, "m_Collision.m_vecMaxs" );
	maxs.Multiply( 0.5 );
	mins.Multiply( 0.5 );

	NetProps.SetPropVector( npc, "m_Collision.m_vecMins", mins );
	NetProps.SetPropVector( npc, "m_Collision.m_vecMaxs", maxs );
	NetProps.SetPropVector( npc, "m_Collision.m_vecSurroundingMins", mins );
	NetProps.SetPropVector( npc, "m_Collision.m_vecSurroundingMaxs", maxs );
	
	local animid=GetNamedEnt("PlayerModel").LookupSequence("slipthrough_enter")
	
	local scripttable={
		spawnflags=32+256
		m_fMoveTo=0
		m_iszPlay="slipthrough_enter"
		m_iszPostIdle="slipthrough_idle"
		m_iszEntity="PlayerModel"
	}
	sequence=SpawnEntityFromTable("scripted_sequence",scripttable);
	EntFireByHandle(sequence,"BeginSequence","",0)
	
	
	local seattable={
		model="models/vehicles/vehicle_blackout_e1_dogintro.mdl"
		rendermode=6
		angles=(VectorAngles(SlipDir)+Vector(0,-90,0)).ToKVString()
		origin=StartPos.ToKVString()
		parentname="PlayerModel"
		vehiclescript="scripts/vehicles/choreo_vehicle_ep2.txt"
		ignoremoveparent=1
		ignoreplayer=1
		solid=0
	}
	
	seat=SpawnEntityFromTable("prop_vehicle_choreo_generic",seattable);
	
	EntFireByHandle(seat,"SetParent","PlayerModel")
	EntFireByHandle(seat,"SetParentAttachment","eyes")
	EntFireByHandle(seat,"entervehicle","")
	EntFireByHandle(seat,"lock","")
	EntFireByHandle(seat,"setlocalorigin","0 0 0")
	EntFireByHandle(npc,"setrendermode","1",0.8)
	EntFireByHandle(npc,"disableshadow","",0.2)
	SendToConsole("r_nearz 3")
	
}

local savedangle=Vector()

NetMsg.Receive("GetPlayerCameraAngles",function(...) {
	savedangle=NetMsg.ReadVec3Coord()
}.bindenv(this))

function Exit(Reverse=false)
{
	LastExitTime=Time()
	
	local npc=GetNamedEnt("PlayerModel")
	
	GetNamedEnt("stamina_system").GetScriptScope().Unstuck=false;
	GetNamedEnt("stamina_system").GetScriptScope().Unstuck2=false;
	GetNamedEnt("stamina_system").GetScriptScope().StuckTime=Time();	// Sometimes we can get stuck in the ceiling, so we activate anti-stucker. Anything is better than a stupid softlock.
	EntFireByHandle(npc,"kill","",3)	// Sometimes playermodel will simply not disappear, so we MAKE SURE with this
	
	local exitpos=null
	local exitang=null
	Slipping=false;
	
	Entities.First().SetContextThink("slipthrough_exit",function(...){
		npc.SetRenderMode(6)
		seat.SetOrigin(Vector(0,0,99990))
		seat.AcceptInput("unlock","",null,null)
		seat.AcceptInput("unlock","",null,null)
		seat.AcceptInput("exitvehicle","",null,null)
		seat.AcceptInput("exitvehicle","",null,null)
		seat.AcceptInput("exitvehicle","",null,null)
		EntFireByHandle(seat,"exitvehicle","",0)
		EntFire("viewmodel","setmodel","models/blackout.mdl",0)
		EntFireByHandle(seat,"exitvehicle","",0.01)
		EntFireByHandle(seat,"exitvehicle","",0.02)
		exitpos=player.GetOrigin()
		exitang=player.GetAngles()
		//player.SetOrigin(npc.GetOrigin())
		//player.SetAngles(npc.GetAngles())
		//if (npc.GetOrigin().DistTo(SlipPoint.GetOrigin())<32) player.SetAngles(npc.GetAngles()+Vector(0,180,0))
		sequence.Destroy()
		//npc.Destroy()
		Slipping=false;
		//player.SetMoveType(MOVETYPE_WALK)
		EntFireByHandle(npc,"freechildren","",0)
		
		//SW_ScreenFade(0.1,0.1,0,0,0,225,true)
		
	}.bindenv(this),npc.SequenceDuration(npc.LookupSequence("slipthrough_exit"))-0.1)
	
	local times=0
	Entities.First().SetContextThink("slipthrough_exit2",function(...){
		if (player.GetVehicleEntity()) 
		{
			NetMsg.Start("GetPlayerCameraAngles")
			NetMsg.Send(player,false)
			return 0;
		}
		//if (Reverse) player.SetOrigin(npc.GetOrigin()-npc.GetForwardVector()*14+Vector(0,0,5))
		//else player.SetOrigin(npc.GetOrigin()+npc.GetForwardVector()*14+Vector(0,0,5))
	
        player.SetAngles(savedangle)
	
		SendToConsole("r_nearz -1")
	
		times++
		if (times>10)
		{
			if (seat) seat.Destroy()
			if (npc) npc.Destroy()
			return
		}
		
		return 0
	}.bindenv(this),npc.SequenceDuration(npc.LookupSequence("slipthrough_exit"))-0.1)
}

function Think()
{
	if (!Slipping&&Entities.FindByNameWithin(null,"sw_slipthrough_*",player.GetOrigin(),40)&&(Time()-LastExitTime)>3)
	{
		SlipPoint=Entities.FindByNameWithin(null,"sw_slipthrough_*",player.GetOrigin(),40)
		local SlipName=SlipPoint.GetName().slice(("sw_slipthrough_").len(),("sw_slipthrough_").len()+1)
		
		//printl("SlipPoint "+SlipPoint)
		//printl("SlipName "+SlipName)
		local SlipSide=SlipPoint.GetName().slice(-1)
		//printl("SlipSide "+SlipSide)
		
		SlipEnd=Entities.FindByName(null,"sw_slipthrough_"+SlipName+"_"+(SlipSide=="a" ? "b" : "a"))
		
		//printl("SlipEnd "+SlipEnd)
		
		local MidPos=(SlipEnd.GetOrigin()-SlipPoint.GetOrigin()).Normalized()*64+SlipPoint.GetOrigin()
		
		printl(player.EyeDirection3D().Dot((MidPos+Vector(0,0,64)-player.EyePosition()).Normalized()))
		
		if (player.EyeDirection3D().Dot((MidPos+Vector(0,0,64)-player.EyePosition()).Normalized())>(0.85))
		{
			printl("SLIP!")
			if (player.GetButtons()&IN.USE)
			{
				StartSlip()
			}
		}
		
	}
	
	if (Slipping)
	{
		local npc=GetNamedEnt("PlayerModel")
		local SlipDir=(SlipEnd.GetOrigin()-SlipPoint.GetOrigin()).Normalized()
		
		if (npc.GetSequenceName(npc.GetSequence())=="slipthrough_idle")
		{
			local diff=(SlipEnd.GetOrigin()-npc.GetOrigin()).Normalized()
			if (npc.GetOrigin().DistTo(SlipEnd.GetOrigin())<npc.GetOrigin().DistTo(SlipPoint.GetOrigin())) 
				diff=-diff
			
			local progress=(SlipEnd.GetOrigin()-npc.GetOrigin()+diff*28)/((SlipEnd.GetOrigin()-SlipPoint.GetOrigin()).x+(SlipEnd.GetOrigin()-SlipPoint.GetOrigin()).y)
			progress=1-(progress.x+progress.y)
			printl(progress)
			
			if (player.GetButtons()&IN.MOVELEFT||player.GetButtons()&IN.MOVERIGHT)
			{
				if (!((player.GetButtons()&IN.MOVELEFT&&progress>1)||(player.GetButtons()&IN.MOVERIGHT&&progress<0)))
				{
					if (player.GetButtons()&IN.MOVERIGHT) EntFireByHandle(sequence,"AddOutput","m_iszPlay slipthrough_move_mirrored",0)
					else EntFireByHandle(sequence,"AddOutput","m_iszPlay slipthrough_move",0)
					EntFireByHandle(sequence,"CancelSequence","",0)
					EntFireByHandle(sequence,"BeginSequence","",0)
					//printl("move")
					
					//Unexplainable, but i must disable shadow every time he moves, disabling once isn't enough. This is stupid.
					EntFireByHandle(npc,"disableshadow","",0)
				}
				else
				{
					if (progress>1) EntFireByHandle(sequence,"AddOutput","m_iszPlay slipthrough_exit_mirrored",0)
					else EntFireByHandle(sequence,"AddOutput","m_iszPlay slipthrough_exit",0)
					
					EntFireByHandle(sequence,"AddOutput","m_iszPostIdle  ",0)
					EntFireByHandle(sequence,"CancelSequence","",0)
					EntFireByHandle(sequence,"BeginSequence","",0)
					printl("exit")
					Exit(progress<0)
				}
				//DoSound()
			}
		}
		
	}
	return 0
}
