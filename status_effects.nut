// Basic class for defining any Status Effects
::LIST_STATUS_EFFECTS<-{}

class StatusEffect
{
	tech_name=null
	DisplayName=""
	Description=""
	Icon=[0,0]
	// Uses icon atlas, values are X,Y coordinates
	Color=[255,255,255,255]
	
	// Functions to be applied to status effect receiver.
	// Argument is the active status effect object.
	OnTick=null
	OnStart=null
	OnEnd=null
	OnPaint=null
	
	constructor(name,params)
	{
		tech_name=name
		
		OnTick=function(status) {return}
		OnStart=function(status) {return}
		OnEnd=function(status) {return}
		OnPaint=function(status) {return}
		
		foreach (k,v in params) 
			this[k]=v;
		
		LIST_STATUS_EFFECTS.rawset(tech_name,this)
	}
}

//Dispatching particle effects works only for static particles that can't be parented.
//For the lack of a better solution I'll stick to spawning info_particle_systems.


PrecacheParticleSystem("blood_impact_red_01_droplets")
PrecacheParticleSystem("blood_impact_red_01_smalldroplets")
PrecacheParticleSystem("blood_impact_red_01_goop")

::DispatchParticleEffectParented<-function(name,pos,ang,ent,attachment="",duration=1,hardattach=false)
{
	local BloodParticle_t={
		effect_name=name
		start_active=1
		cpoint1="!self"
		//cpoint1_parent=victim.GetName()
		origin=(pos).ToKVString()
		angles=(ang).ToKVString()
	}
	local Blood = SpawnEntityFromTable("info_particle_system",BloodParticle_t)
	if (!hardattach) Blood.SetParent(ent,"");
	if (attachment!=""&&!hardattach)
		EntFireByHandle(Blood,"setparentattachmentmaintainoffset",attachment,0)
	EntFireByHandle(Blood,"DestroyImmediately","",duration)
	EntFireByHandle(Blood,"Kill","",duration+0.1)
	
	if (hardattach)
	{
		local StartTime=Time()
		Entities.First().SetContextThink("ParticleAttach_"+Blood.entindex(),function(...)
		{
			if (!Blood||!ent.IsAlive())
			{
				Blood.AcceptInput("DestroyImmediately","",Blood,Blood)
				return;
			}
			else 
			{
				Blood.SetOrigin(ent.GetAttachmentOrigin(ent.LookupAttachment("eyes"))-ent.HeadDirection3D()*6+Vector(0,0,6))
				return 0.001
			}
		}.bindenv(this),0.1)
	}
	
	return Blood
}

StatusEffect("BLEED",{
		DisplayName="BLEED"
		Description="Slowly depletes your health. Use Bandage to stop."
		Color=[255,60,60,255]
		OnStart=function(status)
		{
			if (CLIENT_DLL)
				SW_CreateScreenGradient([255,15,15,85],YRES(50),1,0.1,1.5);
			else
				status.Victim.PrecacheSoundScript("Player.Bleed")
				status.Victim.EmitSound("Player.Bleed");
		}
		OnTick=function(status)
		{
			local victim=status.Victim
			local attacker=status.Attacker
			
			if (CLIENT_DLL)
			{
				SW_CreateScreenGradient([170,15,0,55],YRES(35),1,0.1,1.2);
				return
			}
			local info = CreateDamageInfo( attacker, attacker, Vector(0,0,0), Vector(0,0,0), 1, DMG_PREVENT_PHYSICS_FORCE );
			info.SetDamageBonus(RandomInt(1,3))
			// Bonus works as extra pain amounts without modifying damage itself. Like cutting yourself with a paper
			
			local trace=TraceLineComplex(victim.GetCenter(),victim.GetCenter()-Vector(RandomFloat(-48,48),RandomFloat(-48,48),128),victim,MASK_SHOT,0)
			DecalTrace(trace,"Blood_s")
			
			if (trace.DidHit())
			{
				local bloodpos=trace.StartPos()-(trace.StartPos()-trace.EndPos())*trace.Fraction()
				DispatchParticleEffect("blood_impact_red_01_smalldroplets",bloodpos,Vector(-90,0,0),victim) 
				DispatchParticleEffect("blood_impact_red_01_smalldroplets",bloodpos,Vector(-90,0,0),victim) 
				DispatchParticleEffect("blood_impact_red_01_smalldroplets",bloodpos,Vector(-90,0,0),victim) 
				//DispatchParticleEffect("blood_impact_red_01_goop",bloodpos,Vector(90,0,0),victim)
				local snd=EmitSound_t()
				snd.SetSoundName("Bounce.Flesh")
				snd.SetOrigin(bloodpos)
				EmitSoundParamsOn(snd,Entities.First())
			}
			
			Entities.First().SetContextThink("BloodDroplets"+victim.entindex(),function(...)
			{
				DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter()+Vector(RandomInt(-4,4),RandomInt(-4,4),RandomInt(-4,4)),Vector(90,0,0),victim);
				DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter()+Vector(RandomInt(-4,4),RandomInt(-4,4),RandomInt(-4,4)),Vector(90,0,0),victim);
				DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter()+Vector(RandomInt(-4,4),RandomInt(-4,4),RandomInt(-4,4)),Vector(90,0,0),victim);
				DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter()+Vector(RandomInt(-4,4),RandomInt(-4,4),RandomInt(-4,4)),Vector(90,0,0),victim);
				DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter()+Vector(RandomInt(-4,4),RandomInt(-4,4),RandomInt(-4,4)),Vector(90,0,0),victim);
				return
			}.bindenv(this),0.5)
			
			DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter(),Vector(90,0,0),victim)
			DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter(),Vector(90,0,0),victim)
			DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter(),Vector(90,0,0),victim)
			DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter(),Vector(90,0,0),victim)
			DispatchParticleEffectParented("blood_impact_red_01_droplets",victim.GetCenter(),Vector(90,0,0),victim)
			//victim.SetHealth(victim.GetHealth()-1)
			//victim.SetTakeDamage(DAMAGE_NO)
			//if (victim.GetHealth()<=0) victim.SetTakeDamage(DAMAGE_YES);
			if ((status.RemainingTicks%2)==1) 
			{
				if (victim.GetHealth()>1) victim.SetHealth(victim.GetHealth()-info.GetDamage());
				else victim.TakeDamage( info );;
			}
			Entities.FindByName(null,"stamina_system").GetScriptScope().PassesFinalDamageFilter(victim, info)
		}
})


StatusEffect("REGEN",{
		DisplayName="REGENERATION"
		Description="Slowly regenerates health."
		Color=[45,225,45,255]
		Icon=[1,0]
		OnTick=function(status)
		{
			local victim=status.Victim
			local attacker=status.Attacker
			
			if (CLIENT_DLL&&victim.GetHealth()<PlayerMaxHealth)
				SW_CreateScreenGradient([0,155,0,25],YRES(20),1,0.1,1.3);
			
			if (SERVER_DLL) 
				victim.SetHealth(clamp(victim.GetHealth()+1,0,victim.GetMaxHealth()));
		}
})


StatusEffect("STUN",{
		DisplayName="STUN"
		Description="Makes it harder to aim."
		Color=[225,225,25,255]
		Icon=[1,1]
		
		OnStart=function(status)
		{
			if ( status.Victim!=player ) 
			{
				local info = CreateDamageInfo( status.Attacker, status.Attacker, Vector(0,0,0), Vector(0,0,0), 1, DMG_PREVENT_PHYSICS_FORCE );
				
				status.Victim.TakeDamage(info)
				status.Victim.SetHealth(status.Victim.GetHealth()+1)
				if (status.Victim.GetClassname()=="npc_citizen") status.Victim.EmitSound("npc_citizen.pain0"+RandomInt(7,9))
				// Do this only to make them emit pain sound.
				
				//status.Victim.EmitSound
				status.Victim.SetActivity("ACT_COWER")
				
				local StunEffect = null
				
				if (status.RemainingTicks>1&&status.Victim.LookupAttachment("eyes")==0)
				{
					StunEffect = DispatchParticleEffectParented("stun_main",status.Victim.GetOrigin()+Vector(0,0,status.Victim.GetBoundingMaxs().z),Vector(),status.Victim,"",status.InitialTicks)
				
				}
				else if (status.RemainingTicks>1)
				{
					local HeadPos=status.Victim.GetAttachmentOrigin(status.Victim.LookupAttachment("eyes"))-status.Victim.HeadDirection3D()*8
					StunEffect = DispatchParticleEffectParented("stun_main",HeadPos,Vector(),status.Victim,"eyes",status.InitialTicks,true)
				}
				
				return
			}
			
			if (CLIENT_DLL)
				SW_CreateScreenGradient([220,220,220,255],YRES(980),1,0.1,2);
			if (CLIENT_DLL)
				SW_CreateScreenGradient([220,220,220,255],YRES(480),1,0.1,2);
			if (SERVER_DLL)
				status.Victim.PrecacheSoundScript("coast.thumper_hit")
			if (SERVER_DLL)
				if (status.Victim==player) status.Victim.EmitSound("coast.thumper_hit");
		}
		OnPaint=function(status)
		{
			local TimeLeft=(status.RemainingTicks.tofloat()+status.LastTickTime-Time())
			
			
			local stunpower=1.0		
			// Decrease effect during last 3 seconds
			stunpower*=(TimeLeft<=3 ? TimeLeft/3.0 : 1)
			
			surface.SetColor(255,255,255,100*stunpower)
			surface.SetTexture(surface.ValidateTexture("player_pov",true,false,false))
			local Xtra=YRES(50)*stunpower
			surface.DrawTexturedRect(Xtra*sin(Time())-Xtra,Xtra*cos(Time())-Xtra,XRES(640)+2*Xtra,YRES(480)+2*Xtra)
			surface.DrawTexturedRect(Xtra*sin(Time())-Xtra,Xtra*cos(Time())-Xtra,XRES(640)+2*Xtra,YRES(480)+2*Xtra)
			
			stunpower=1.0		
			// Decrease effect after first 3 seconds
			stunpower*=(TimeLeft<=status.InitialTicks-2 ? RemapValClamped(TimeLeft,status.InitialTicks-5,status.InitialTicks-2,0,1) : 1)
			
			surface.SetColor(255,255,255,clamp(255*pow(stunpower,2),0,255))
			if (2==1) 
				surface.DrawFilledRect(0,0,ScreenWidth(),ScreenHeight());
		}
		OnTick=function(status)
		{
			local victim=status.Victim
			local attacker=status.Attacker
			
			local TimeLeft=(status.RemainingTicks.tofloat()+status.LastTickTime-Time())
			
			if ( SERVER_DLL && victim!=player ) 
			{
				if (victim.GetSchedule()!="SCHED_COWER") 
					victim.SetSchedule("SCHED_COWER");
				
				
				if (status.Victim.GetActivity()!="ACT_COWER")
					victim.SetActivity("ACT_COWER");
				
				Entities.First().SetContextThink("EnemyStun"+victim.entindex(),function(...)
				{
					printl("changing playbackrate")
					victim.SetPlaybackRate(0.01)
				}.bindenv(this),0.6)
				
				return
			}
			
			
			if (SERVER_DLL)
			{
				
				Convars.SetInt("dsp_room",51)
				Entities.First().SetContextThink("StunViewpunch",function(...)
				{
					TimeLeft=(status.RemainingTicks.tofloat()+status.LastTickTime-Time())
					
					local stunpower=1.0
					
					// Decrease effect during last 3 seconds
					stunpower*=(TimeLeft<=3 ? TimeLeft/3.0 : 1)
					
					victim.ViewPunch(Vector(sin(Time())*stunpower,cos(Time())*stunpower,cos(Time())*stunpower/2))
					return 0
				}.bindenv(this),0)
			}
		}
		OnEnd=function(status)
		{
			if (SERVER_DLL)
			{
				if (status.Victim!=player) 
				{
					Entities.First().SetContextThink("EnemyStun"+status.Victim.entindex(),function(...)
					{
						status.Victim.SetPlaybackRate(1)
						return
					}.bindenv(this),0)
					
					return
				}
				Entities.First().SetContextThink("StunViewpunch",function(...)
				{
					return
				}.bindenv(this),0)
				Convars.SetInt("dsp_room",0)
			}
		}
})

StatusEffect("POISON",{
		DisplayName="POISON"
		Description="Quickly depletes your health up to 1."
		Color=[195,255,25,255]
		Icon=[0,1]
		OnStart=function(status)
		{
			if (CLIENT_DLL)
			{
				SW_CreateScreenGradient([245,245,15,165],YRES(580),1.4,0.1,2);
				SW_CreateScreenGradient([245,245,15,165],YRES(580),1,0.1,2);
			}
			if (SERVER_DLL)
			{
				status.Victim.PrecacheSoundScript("npc_citizen.moan01")
				status.Victim.PrecacheSoundScript("npc_citizen.moan02")
				status.Victim.PrecacheSoundScript("npc_citizen.moan03")
				status.Victim.PrecacheSoundScript("npc_citizen.moan04")
				status.Victim.PrecacheSoundScript("npc_citizen.moan05")
				status.Victim.EmitSound("npc_citizen.moan0"+RandomInt(1,5));
			}
		}
		OnPaint=function(status)
		{
			local TimeLeft=(status.RemainingTicks.tofloat()+status.LastTickTime-Time())
			
			local stunpower=1.0		
			// Decrease effect during last 3 seconds
			stunpower*=(TimeLeft<=3 ? TimeLeft/3.0 : 1)
			
			surface.SetColor(255,255,5,130*stunpower)
			surface.SetTexture(surface.ValidateTexture("player_pov",true,false,false))
			local Xtra=YRES(5)*stunpower
			surface.DrawTexturedRect(Xtra*sin(Time())-Xtra,Xtra*cos(Time())-Xtra,XRES(640)+2*Xtra,YRES(480)+2*Xtra)
			surface.DrawTexturedRect(Xtra*sin(Time())-Xtra,Xtra*cos(Time())-Xtra,XRES(640)+2*Xtra,YRES(480)+2*Xtra)
		}
		OnTick=function(status)
		{
			local victim=status.Victim
			local attacker=status.Attacker
			
			Convars.SetInt("dsp_room",51)
			
			if (CLIENT_DLL)
			{
				SW_CreateScreenGradient([190,220,0,125],YRES(55),1,0.1,1.2);
				return
			}
			local info = CreateDamageInfo( attacker, attacker, Vector(0,0,0), Vector(0,0,0), clamp(1,0,victim.GetHealth()-1), DMG_PREVENT_PHYSICS_FORCE );
			
			for (local i=1;i<9;i++)
			{
				Entities.First().SetContextThink("Poison"+i,function(...)
				{
					if (status.RemainingTicks>0) this.OnTick(status);
					return
				}.bindenv(this),0.1*i)
			}
			info.SetDamageBonus(-1)
			
			if (victim.GetHealth()>1) Entities.FindByName(null,"stamina_system").GetScriptScope().PassesFinalDamageFilter(victim, info)
			if (victim.GetHealth()>1) victim.SetHealth(victim.GetHealth()-clamp(1,0,victim.GetHealth()-1))
		}
		OnEnd=function(status)
		{
			Convars.SetInt("dsp_room",0)
			printl("poison end")
			if (SERVER_DLL)
			{
				for (local i=1;i<9;i++)
				{
					Entities.First().SetContextThink("Poison"+i,function(...)
					{
						return
					}.bindenv(this),0.1*i)
				}
				
			}
		}
})

::ACTIVE_STATUS_EFFECTS<-array(32)

::ActiveStatusEffect <- class
{
	Victim=null	// who received status effect
	Attacker=Entities.First() // who applied status effect. By default it's worldspawn
	RemainingTicks=0
	InitialTicks=0
	LastTickTime=Time()
	Effect=null	// Reference to actual predefined status effect.
	ID=0
	
	constructor(name,ent,ticks,owner=Entities.First(),id=ACTIVE_STATUS_EFFECTS.find(null))
	{
		Effect=LIST_STATUS_EFFECTS[name]
		Victim=ent
		Attacker=owner
		RemainingTicks=ticks
		InitialTicks=ticks
		LastTickTime=Time()
		ID=id
		if (ID==null)
			ID=ACTIVE_STATUS_EFFECTS.find(null);
		ACTIVE_STATUS_EFFECTS[ID]=this
		this.Activate()
	}
	function SetRemainingTicks(ticks)
	{
		RemainingTicks=ticks
		if (SERVER_DLL&&Victim==player)
		{
			
			NetMsg.Start("SetStatusEffectTicksOnClient")
			NetMsg.WriteShort(ID)
			NetMsg.WriteShort(RemainingTicks)
			NetMsg.Send(player,true)
			// Does the client need to know who put the status effect on them? Don't think it does.
		}
	}
	function Activate()
	{
		printl("Applied "+Effect.DisplayName+" to "+Victim)
		
		if (SERVER_DLL)
			Entities.First().SetContextThink(UniqueString(Effect.tech_name)+"_"+ID,this.Tick.bindenv(this),0);
		
		Effect.OnStart(this)
		
		if (SERVER_DLL&&Victim==player)
		{
			NetMsg.Start("SendStatusEffectToClient")
			NetMsg.WriteString(Effect.tech_name)
			NetMsg.WriteShort(RemainingTicks)
			NetMsg.WriteShort(ID)
			NetMsg.Send(player,true)
			// Does the client need to know who put the status effect on them? Don't think it does.
		}
	}
	function Tick(...)
	{
		if ((!Victim)||(!Victim.IsValid())||(Victim.GetHealth()<=0))
		{
			End()
			return
		}
		
		if (SERVER_DLL&&Victim==player)
		{
			local client_effects=-1
			foreach (s in ACTIVE_STATUS_EFFECTS)
			{
				if (s&&s.Victim==player) client_effects++;
			}
			
			NetMsg.Start("TickStatusEffectOnClient")
			NetMsg.WriteShort(ID)
			// We assume that status effects are always created on both sides, so the array index will be the same too.
			NetMsg.Send(player,true)
		}
		
		LastTickTime=Time()
		
		//printl(RemainingTicks)
		Effect.OnTick(this)
		RemainingTicks--
		if (RemainingTicks<=0)
		{
			End()
			return
		}
		return 1
	}
	function End()
	{
		if (SERVER_DLL&&Victim==player)
		{
			NetMsg.Start("EndStatusEffectOnClient")
			NetMsg.WriteShort(ID)
			// We assume that status effects are always created on both sides, so the array index will be the same too.
			NetMsg.Send(player,true)
		}
		
		Effect.OnEnd(this)
		ACTIVE_STATUS_EFFECTS[ACTIVE_STATUS_EFFECTS.find(this)]=null
	}
}

::SW_ApplyStatusEffect<-function(name,ent,ticks,owner=Entities.First(),id=null)
{
	
	foreach(Status in ACTIVE_STATUS_EFFECTS)
	{
		if (Status==null) continue;
		
		// Originally, status effects wouldn't stack and instead override the duration of one another.
		// This meant nerfing all healing items, as their heal-over-time could stack.
		//
		//if (Status.Effect.tech_name==name&&Status.Victim==ent)
		//{
		//	Status.InitialTicks=ticks
		//	Status.RemainingTicks=ticks
		//	
		//	Status.Effect.OnStart(Status.Victim,Status.Attacker)
		//
		//	if (SERVER_DLL&&Status.Victim==player)
		//	{
		//		NetMsg.Start("SendStatusEffectToClient")
		//		NetMsg.WriteString(Status.Effect.tech_name)
		//		NetMsg.WriteShort(Status.RemainingTicks)
		//		NetMsg.Send(player,true)
		//		// Does the client need to know who put the status effect on them? Don't think it does.
		//	}
		//	return
		//}
		
		
		
	}
	
	return ActiveStatusEffect(name,ent,ticks,owner,id)
}

::SW_CreateScreenGradient<-function(color,width,dur,hold,power)
{
	if (SERVER_DLL)
	{
		NetMsg.Start("ScreenVignetteGradient")
		NetMsg.WriteByte(color[0])
		NetMsg.WriteByte(color[1])
		NetMsg.WriteByte(color[2])
		NetMsg.WriteByte(color[3])
		NetMsg.WriteShort(width)
		NetMsg.WriteFloat(dur)
		NetMsg.WriteFloat(hold)
		NetMsg.WriteFloat(power)
		NetMsg.Send(player,true)
	}
	if (CLIENT_DLL)
	{
		ScreenOverlay_t(color,width,dur,hold,power)
	}
}

NetMsg.Receive("SendStatusEffectToClient", function()
{
	SW_ApplyStatusEffect(NetMsg.ReadString(),player,NetMsg.ReadShort(),Entities.First(),NetMsg.ReadShort())
}.bindenv(this))

NetMsg.Receive("TickStatusEffectOnClient", function()
{
	local ID=NetMsg.ReadShort()
	if (ACTIVE_STATUS_EFFECTS[ID]==null)
	{
		throw("Updating non-existing status effect on client!")
	}
	local StatusEffect=ACTIVE_STATUS_EFFECTS[ID]
	StatusEffect.Tick()
}.bindenv(this))

NetMsg.Receive("SetStatusEffectTicksOnClient", function()
{
	local ID=NetMsg.ReadShort()
	if (ACTIVE_STATUS_EFFECTS[ID]==null)
	{
		throw("Changing remaining ticks for non-existing status effect on client!")
	}
	local StatusEffect=ACTIVE_STATUS_EFFECTS[ID]
	StatusEffect.SetRemainingTicks(NetMsg.ReadShort())
}.bindenv(this))

NetMsg.Receive("EndStatusEffectOnClient", function()
{
	local ID=NetMsg.ReadShort()
	if (ACTIVE_STATUS_EFFECTS[ID]==null)
	{
		return;
	}
	local StatusEffect=ACTIVE_STATUS_EFFECTS[ID]
	StatusEffect.End()
}.bindenv(this))

if (CLIENT_DLL)
{
	surface.CreateFont( "StatusEffectTimer",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "MxPlus HP 150 re."    // Name of the font file
        "tall"            : 8        // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
       // "antialias"     : true            // Enables font smoothing
	   "dropshadow"     : true            // Adds a drop shadow to the font
       "outline"     : true            // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	surface.CreateFont( "StatusEffectName8",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "MxPlus HP 150 re."    // Name of the font file
        "tall"            : 10      // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		"dropshadow"     : true            // Adds a drop shadow to the font
        "outline"     : true            // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
        "custom"     : true
    } );
	
	surface.CreateFont( "StatusEffectThin12",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "MxPlus HP 150 re."    // Name of the font file
        "tall"            : 10      // Size of the text
        "weight"        : 200        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		//"dropshadow"     : true            // Adds a drop shadow to the font
        //"outline"     : true            // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
        "custom"     : true
    } );
	
	surface.CreateFont( "StatusEffectSmall61",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "MxPlus HP 150 re."    // Name of the font file
        "tall"            : 8      // Size of the text
        "weight"        : 1200        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		//"dropshadow"     : true            // Adds a drop shadow to the font
        //"outline"     : true            // Adds a drop shadow to the font
		//"antialias"     : true            // Enables font smoothing
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
        "custom"     : true
    } );
	
	surface.CreateFont( "StatusEffectTiny55",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "MxPlus HP 150 re."    // Name of the font file
        "tall"            : 6      // Size of the text
        "weight"        : 500        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		//"dropshadow"     : true            // Adds a drop shadow to the font
        //"outline"     : true            // Adds a drop shadow to the font
		//"antialias"     : true            // Enables font smoothing
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
        "custom"     : true
    } );
	
	
	// Used for colored vignette effects for more subtle indication of status effects being active.
	// Can be used for other stuff too.
	// Actually similar to Fade usermessage.
	::ACTIVE_SCREEN_OVERLAYS<-[]
	
	class ScreenOverlay_t
	{
		Color=[255,255,255,255]
		Width=YRES(120)
		StartTime=Time()
		Duration=1
		HoldTime=0.3
		Power=2
		
		constructor(color,width,dur,hold,power)
		{
			Color=color
			Width=width
			Duration=dur
			HoldTime=hold
			Power=power
			
			StartTime=Time()
			
			ACTIVE_SCREEN_OVERLAYS.append(this)
			//printl("Added overlay to queue")
		}
	}
	
	NetMsg.Receive("ScreenVignetteGradient", function()
	{
		local Color=[NetMsg.ReadByte(),NetMsg.ReadByte(),NetMsg.ReadByte(),NetMsg.ReadByte()]
		local Width=NetMsg.ReadShort()
		local Duration=NetMsg.ReadFloat()
		local HoldTime=NetMsg.ReadFloat()
		local Power=NetMsg.ReadFloat()
		ScreenOverlay_t(Color,Width,Duration,HoldTime,Power)
	}.bindenv(this))
	
	NetMsg.Receive("EndStatusEffectOnClient", function()
	{
		local ID=NetMsg.ReadShort()
		if (ACTIVE_STATUS_EFFECTS[ID]==null)
		{
			return;
		}
		local StatusEffect=ACTIVE_STATUS_EFFECTS[ID]
		StatusEffect.End()
	}.bindenv(this))
	
}

function DrawScreenOverlays()
{
	foreach (i,Overlay in ACTIVE_SCREEN_OVERLAYS)
	{
		//printl("Drawing overlay "+i)
		
		local power=Overlay.Power
		local col=Overlay.Color
		local holdtime=Overlay.HoldTime
		local duration=Overlay.Duration
		
		local mod=clamp(pow(duration-(Time()-Overlay.StartTime),power),holdtime,1)
		surface.SetColor(col[0],col[1],col[2],col[3]*pow(mod-holdtime,power))
		
		local width=mod*Overlay.Width
		local iwidth=(1-mod)*Overlay.Width
		
		//printl("Duration: "+duration+" holdtime:"+holdtime+" width:"+Overlay.Width+" power:"+power)
		
		surface.DrawFilledRectFade(0,ScreenHeight()-width,ScreenWidth(),width,0,clamp(255*mod,0,255),false)
		
		//surface.DrawFilledRectFade(0,0,ScreenWidth(),width,clamp(255*mod,0,255),0,false)
		
		//surface.DrawFilledRectFade(0,0,width,ScreenHeight(),clamp(255*mod,0,255),0,true)
		
		//surface.DrawFilledRectFade(ScreenWidth()-width,0,width,ScreenHeight(),0,clamp(255*mod,0,255),true)
		
		if (Overlay.StartTime+Overlay.Duration<Time()) ACTIVE_SCREEN_OVERLAYS.remove(i)
	}
}

function DrawStatusEffects()
{
	local StatusFXFont=surface.GetFont( "StatusEffectName8", true )
	local StatusTimerFont=surface.GetFont( "StatusEffectTimer", true )
	
	local i=0
	
	//surface.SetColor(255,255,255,255)
	//surface.SetTexture(surface.ValidateTexture("player_pov",true,false,false))
	//local Xtra=YRES(50)
	//surface.DrawTexturedSubRect(0,0,XRES(640),YRES(480),1,0,0,1)
	
	local IconSize=32
		
	if (YRES(18)>50)
		IconSize=64;
	
	foreach (j,Status in ACTIVE_STATUS_EFFECTS)
	{
		if (Status==null) continue;
		if (!Status.RemainingTicks.tofloat()) continue;
		
		Status.Effect.OnPaint(Status)
		
		local gap=YRES(25)*i
		local Clr=Status.Effect.Color
		
		local y=YRES(480)-YRES(180)-gap
		
		
		surface.SetColor(Clr[0],Clr[1],Clr[2],Clr[3])

		
		local NameTall=surface.GetFontTall(StatusFXFont)
		local TimerTall=surface.GetFontTall(StatusTimerFont)
		
		local AtlasSize=0.5
		local IconX=AtlasSize*Status.Effect.Icon[0]
		local IconY=AtlasSize*Status.Effect.Icon[1]
		
		local TimerFrac=clamp((Status.RemainingTicks.tofloat()+Status.LastTickTime-Time())/(Status.InitialTicks-1).tofloat(),0,1)
		
		local Flash=(Status.RemainingTicks<3)
		
		if (Flash)
		{
			surface.SetColor(Clr[0],Clr[1],Clr[2],fabs(sin(Time()*4))*255)
			surface.DrawColoredText(StatusFXFont,YRES(25)+IconSize+2,y+2,Clr[0]/4,Clr[1]/4,Clr[2]/4,fabs(sin(Time()*4))*255,Status.Effect.DisplayName)
			surface.DrawColoredText(StatusFXFont,YRES(25)+IconSize,y,Clr[0],Clr[1],Clr[2],fabs(sin(Time()*4))*255,Status.Effect.DisplayName)
		}
		else
		{
			surface.SetColor(Clr[0],Clr[1],Clr[2],Clr[3])
			surface.DrawColoredText(StatusFXFont,YRES(25)+IconSize+2,y+2,Clr[0]/4,Clr[1]/4,Clr[2]/4,Clr[3],Status.Effect.DisplayName)
			surface.DrawColoredText(StatusFXFont,YRES(25)+IconSize,y,Clr[0],Clr[1],Clr[2],Clr[3],Status.Effect.DisplayName)
		}
		local BarHeight=(IconSize+4)*TimerFrac
		local IBarHeight=(IconSize+4)*(1-TimerFrac)
		BarHeight=(BarHeight+0.5).tointeger()
		IBarHeight=(IBarHeight+0.5).tointeger()
		
		
		surface.DrawFilledRect(YRES(20)-2,y+NameTall/2-IconSize/2-2+IBarHeight,IconSize+4,BarHeight)
		
		surface.SetColor(255,255,255,255)
		if (Flash)
			surface.SetColor(255,255,255,fabs(sin(Time()*4))*255);
		
		surface.SetTexture(surface.ValidateTexture("vgui/status_effects",true,false,false))
		surface.DrawTexturedSubRect(YRES(20),y+NameTall/2-IconSize/2,YRES(20)+IconSize,y+NameTall/2-IconSize/2+IconSize,IconX,IconY,IconX+AtlasSize,IconY+AtlasSize)

		surface.SetColor(Clr[0],Clr[1],Clr[2],Clr[3])
		
		//surface.DrawColoredText(StatusTimerFont,YRES(20)+IconSize/2-surface.GetTextWidth(StatusTimerFont,Status.RemainingTicks.tostring())/2,y+IconSize,255,255,255,255,Status.RemainingTicks.tostring())
		i++
	}
}