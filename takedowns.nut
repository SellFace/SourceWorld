if (SERVER_DLL)
{


::LastGrabbedTime<-(-60);

PrecacheParticleSystem("weapon_muzzle_flash_assaultrifle")

function CreatePlayerNPC(invincible=false)
{
	if (Entities.FindByName(null,"PlayerModel")) return;
	local weapon=player.GetActiveWeapon() ? player.GetActiveWeapon().GetClassname():""
	local playertable={
		model="models/player.mdl"
		targetname="PlayerModel"
		origin=player.GetOrigin().x+" "+player.GetOrigin().y+" "+(player.GetOrigin().z+990)
		angles="0 "+player.GetAngles().y+" 0"
		additionalequipment=weapon
		spawnflags=1048576+16384+1024
		SpawnWithStartScripting=1
		rendermode=1
		citizentype=4
		OnDeath="dialogue_manager:callscriptfunctionclient:HidePanels:0:1"
		//OnDeath="player:SetHealth:-200:0.01:1"
		//OnDeath="!self:kill::0:1"
	}
	if (invincible) playertable.rawset("maxhealth",999999999)
	if (invincible) playertable.rawset("health",999999999)
	local npc=SpawnEntityFromTable("npc_citizen",playertable);
	npc.SetMaxHealth(10000)
	npc.SetHealth(10000)
	EntFireByHandle(npc,"AddOutput","OnDeath dialogue_manager:callscriptfunctionclient:HidePanels:0:1",0)
	EntFireByHandle(npc,"AddOutput","OnDeath dialogue_manager:callscriptfunctionclient:HidePanels:0:1",0)
	EntFireByHandle(npc,"AddOutput","OnDeath point_viewcontrol:disable::0:1",0)
	//EntFireByHandle(npc,"AddOutput","OnDeath player:SetHealth:-200:0.1:1",0)
	EntFireByHandle(npc,"AddOutput","OnDeath !self:kill:0:0:1",0)
	EntFire("PlayerModel","AddOutput","OnDeath dialogue_manager:callscriptfunctionclient:HidePanels:0:1",0)
	npc.SetCollisionGroup(18)
	
	local mins = NetProps.GetPropVector( npc, "m_Collision.m_vecMins" );
	local maxs = NetProps.GetPropVector( npc, "m_Collision.m_vecMaxs" );
	maxs.Multiply( 2 );
	mins.Multiply( 2 );

	NetProps.SetPropVector( npc, "m_Collision.m_vecMins", mins );
	NetProps.SetPropVector( npc, "m_Collision.m_vecMaxs", maxs );
	NetProps.SetPropVector( npc, "m_Collision.m_vecSurroundingMins", mins );
	NetProps.SetPropVector( npc, "m_Collision.m_vecSurroundingMaxs", maxs );
	
	npc.SetOrigin(player.GetOrigin())
}

enemy<-null;

function HeatActionReady()
{
	enemy=null
	
	if (GetNamedEnt("PlayerModel")) return false;
	if (!SKILLS.HeatFinisher.Unlocked) return false;
	if (PlayerHeat<50) return false;
	
	local trace=TraceLineComplex(player.EyePosition(), player.EyePosition()+player.GetEyeForward()*80, player, MASK_SHOT, 0)
	if (trace.Entity()&&trace.Entity().IsNPC())
		enemy=trace.Entity()
	
	if (!enemy) return false;
	if (enemy.GetRelationship(player)==3) return false;
	return enemy
}

function HeatAction(name,enemy=null,DrawWeapons=true,TurnHead=true,Forced=false)
{
	if (!player.IsAlive())
		return;
	
	
	if (!Forced&&!HeatActionReady()) return;
	
	printl(HeatActionReady())
	
	if (!enemy) enemy=HeatActionReady();
	
	if (!enemy) return false;
	
	printl(enemy.GetName())
	//printl((SW_COMPANIONS.find(enemy.GetName().tolower())&&enemy.GetName()!=null))
	
	if (SW_COMPANIONS.find(enemy.GetName().tolower())!=null&&enemy.GetName()!=null)
	{
		name="pairtest"
		DrawWeapons=false;
		TurnHead=false
		//enemy.GetExpresser().SpeakRawScene("scenes/npc/$gender01/yougotit02.vcd",0.8)	// The delay parameter doesn't work for shit. I have to time it manually
		
		
		Entities.First().SetContextThink(UniqueString("_TD_SPEAK"),function(_){enemy.GetExpresser().SpeakRawScene("scenes/npc/$gender01/yougotit02.vcd",0)}.bindenv(this),0.7)
		Entities.First().SetContextThink(UniqueString("_TD_SPEAK"),function(_){AddPlayerHeat(15)}.bindenv(this),0.7)
	}
	
	CreatePlayerNPC()
	
	local camera=null
	
	if (!Forced) AddPlayerHeat(-50);
	
	if (!GetNamedEnt("PlayerCamera"))
	{
		local cameratable={
		targetname="PlayerCamera"
		origin=player.EyePosition().x+" "+player.EyePosition().y+" "+player.EyePosition().z
		angles=player.EyeAngles().x+" "+player.EyeAngles().y+" "+player.EyeAngles().z
		spawnflags=4+8+32+128
		fov=Convars.GetInt("fov_desired")
		fov_rate=0.5
		vscripts="swfm/antistuck.nut"
		ThinkFunction="Think"
		}
		camera=SpawnEntityFromTable("point_viewcontrol",cameratable);
	}
	camera.SetFov(95,0.5)
	
	EntFireByHandle(GetNamedEnt("PlayerModel"),"setexpressionoverride","",0.)
	EntFireByHandle(GetNamedEnt("PlayerModel"),"setexpressionoverride","scenes/Expressions/citizen_angry_idle_01.vcd",0.01)
	
	local weaponmodel=null
	
	if (DrawWeapons&&player.GetActiveWeapon()&&"Weapon" in aPlayer&&aPlayer.Weapon)
	{
		local wmodel=LIST_ITEMS[aPlayer.Weapon.Name].model	
		weaponmodel=SpawnEntityFromTable("prop_dynamic_ornament",{model=wmodel})
		EntFireByHandle(weaponmodel,"setattached","PlayerModel")
		EntFireByHandle(weaponmodel,"DisableShadow","")

		if (weaponmodel&&weaponmodel.GetModelName()!=wmodel) {weaponmodel.SetModel(wmodel);};
	}
	
	GetNamedEnt("PlayerModel").EmitSound("SW.Weapon.Foley")
	
	EntFireByHandle(camera,"Enable","",0.01)
	EntFire("Playermodel","Setplaybackrate","0.01",0.05)
	EntFire("Playermodel","StartScripting")
	EntFireByHandle(camera,"SetParent","PlayerModel")
	//EntFireByHandle(camera,"SetParentAttachmentMaintainOffset","sw_camera")
	camera.SetAbsOrigin(player.EyePosition())
	camera.SetAbsAngles(player.EyeAngles())
	
	SendToConsole("crosshair 0")
	
	local animid=GetNamedEnt("PlayerModel").LookupSequence(name)
	
	local scripttable={
		spawnflags=32
		m_fMoveTo=0
		m_iszPlay=name
		m_iszEntity="PlayerModel"
	}
	local sequence=SpawnEntityFromTable("scripted_sequence",scripttable);
	EntFireByHandle(sequence,"BeginSequence","",0)
	
	local diff=AngleVectors(player.GetAngles()+Vector(0,-180,0))
	diff.z=0;
	
	local targetang=GetNamedEnt("PlayerModel").GetAngles()+Vector(0,180,0)
	local targetpos=GetNamedEnt("PlayerModel").GetOrigin()-diff*44
	targetpos.z=enemy.GetOrigin().z
	
	//enemy.SetAngles(GetNamedEnt("PlayerModel").GetAngles()+Vector(0,180,0))
	
	local StartTime=Time()
	
	if (!DrawWeapons) enemy.GetActiveWeapon().SetRenderMode(6)
		
	local HealthRegen=15;
	player.SetHealth(clamp( player.GetHealth()+HealthRegen,0,max(PlayerMaxHealth,player.GetHealth()) ) )
	
	if (name.find("takedown")!=null)
	{
		enemy.ResetSequenceInfo()
	}
	
	Entities.First().SetContextThink("TakeDownEnemyMove",function(_) 
	{
		if (TurnHead) GetNamedEnt("PlayerModel").AddLookTarget(enemy,0.5,41,0);
		if (TurnHead) enemy.AddLookTargetPos(enemy.GetOrigin()+enemy.GetForwardVector()*500,0.5,41,0);
		if (!TurnHead) enemy.CapabilitiesRemove(4096)
		//enemy.SetSequence(enemy.LookupSequence(name+"_v"))
		enemy.SetMoveType(8)
		enemy.SetVelocity((targetpos-enemy.GetOrigin()).Normalized()*200)
		enemy.SetAngles(enemy.GetAngles()+Vector(0,AngleDiff(targetang.y,enemy.GetAngles().y)).Normalized()*3)
		//enemy.SetSequence(enemy.LookupSequence(name+"_v"))
		if ((enemy.GetOrigin()-targetpos).Length()<2) 
		{
			//EntFireByHandle(camera,"Enable","",0.01)
			//camera.SetAbsOrigin(player.EyePosition())
			//camera.SetAbsAngles(player.EyeAngles())
			
			enemy.SetVelocity(Vector())
			enemy.SetAngles(targetang)
			enemy.SetOrigin(targetpos)
			//enemy.SetSequence(enemy.LookupSequence(name+"_v"))
			enemy.SetCycle(0)
			GetNamedEnt("PlayerModel").SetCycle(0)
			EntFire("Playermodel","Setplaybackrate","1",0.05)
			
			camera.GetScriptScope().ReturnPos=player.EyePosition()
			camera.GetScriptScope().ReturnAng=player.EyeAngles()
			camera.GetScriptScope().ReturnSpeed=3
			camera.GetScriptScope().ReturnTime=Time()+GetNamedEnt("PlayerModel").SequenceDuration(animid)-0.25
			
			Entities.First().SetContextThink("HeatActionEnd",function(...){
				if (!DrawWeapons) enemy.GetActiveWeapon().SetRenderMode(0)
				if (enemy&&enemy.IsValid()) enemy.SetMoveType(3);
				if (!TurnHead) enemy.CapabilitiesAdd(4096)
				EntFireByHandle(camera,"Disable")
				SendToConsole("r_nearz -1")
				camera.Destroy()
				GetNamedEnt("PlayerModel").Destroy()
				EntFireByHandle(sequence,"Kill")
				SendToConsole("crosshair 1")
				player.GetViewModel(0).SetModel("models/blackout.mdl")
				return
			}.bindenv(this),GetNamedEnt("PlayerModel").SequenceDuration(animid))
			
			return;
		}
		return 0
	}.bindenv(this),0)
	
	//local ogZ=enemy.GetOrigin().z
	
	//enemy.SetOrigin(GetNamedEnt("PlayerModel").GetOrigin()-diff*44)
	//enemy.SetOrigin(Vector(enemy.GetOrigin().x,enemy.GetOrigin().y,ogZ))
	
	EntFireByHandle(enemy,"StartScripting")
	
	local animid_v=enemy.LookupSequence(name+"_v")
	if (enemy.GetName().len()<1) enemy.SetName("poor_guy");
	
	local scripttable2={
		spawnflags=32+64+512+4096+2048
		m_fMoveTo=0
		m_iszPlay=name+"_v"
		m_iszEntity=enemy.GetName()
	}
	local sequence2=SpawnEntityFromTable("scripted_sequence",scripttable2);
	EntFireByHandle(sequence2,"BeginSequence","",0)
	EntFireByHandle(sequence2,"BeginSequence","",0.1)
	EntFireByHandle(sequence2,"BeginSequence","",0.2)
	EntFireByHandle(sequence2,"BeginSequence","",0.3)
	EntFireByHandle(sequence2,"BeginSequence","",0.4)
	EntFireByHandle(sequence2,"BeginSequence","",0.45)
	EntFireByHandle(sequence2,"BeginSequence","",0.5)

	
	
	
	
	
	local plr=GetNamedEnt("PlayerModel").GetOrCreatePrivateScriptScope()
	
	function HandleEvent(event)
	{
		//printl("ANIM EVENT INFO: "+event.GetEvent()+" - "+event.GetType()+" - "+event.GetOptions())
		local type=event.GetOptions()
		
		if (type=="punch")
		{
			SendToConsole("host_timescale 0.6")
			SendToConsole("host_pitchscale 0.9")
			Convars.SetFloat("mat_autoexposure_min",10.5)
			Convars.SetFloat("mat_bloom_scalefactor_scalar",3)
			
			local EffectTable={
			targetname="bt_effect",
			type=0
			}
			
			local hittime=Time()
			
			local mod=clamp(0.2-(Time()-hittime),0,0.2)*5
			local ve=Vector(RandomFloat(-2,2),RandomFloat(-2,2),RandomFloat(-2,2))
			camera.SetLocalOrigin(ve*mod)
			
			Entities.First().SetContextThink("heatactionshake",function(_) 
			{
				mod=clamp(0.2-(Time()-hittime),0,0.2)*5
				ve=Vector(RandomFloat(-4,4),RandomFloat(-4,4),RandomFloat(-4,4))
				camera.SetLocalAngles(ve*mod)
				
				if (mod==0) return
				
				return 0
			}.bindenv(this),0)
			
			
			local dmg=CreateDamageInfo(player,player,Vector(),Vector(),min(enemy.GetHealth()-1,5),DMG_DIRECT)
			dmg.ScaleDamageForce(0)
			if (enemy.GetHealth()>1) enemy.TakeDamage(dmg);
			
			ScrFX<-Entities.FindByName(null,"bt_effect")
			
			if (!ScrFX) ScrFX<-SpawnEntityFromTable("env_screeneffect",EffectTable);
			EntFireByHandle(ScrFX,"StartEffect",1,0)
			EntFireByHandle(ScrFX,"StopEffect",0.2,0)
			
			Entities.First().SetContextThink("heatactionslowmo",function(_) 
			{
				SendToConsole("host_timescale 1");
				//SendToConsole("host_pitchscale 1")
				Convars.SetFloat("mat_autoexposure_min",0.5);
				Convars.SetFloat("mat_bloom_scalefactor_scalar",1)
			}.bindenv(this),0.1)
			Entities.First().SetContextThink("delaedsounddum",function(_) 
			{
				GetNamedEnt("PlayerModel").EmitSound("PlayerPunch")
			}.bindenv(this),0)
		}
		
		if (type=="blunt")
		{
			Convars.SetFloat("mat_autoexposure_min",6.5)
			Convars.SetFloat("mat_bloom_scalefactor_scalar",3)
			local hittime=Time()
			
			local head=enemy.LookupAttachment("eyes")
			local headpos=enemy.GetAttachmentOrigin(head)
			
			//debugoverlay.Line(muzzle, (headpos-muzzle).Normalized()*64,255,30,30,true,3)
			
			local info = CreateFireBulletsInfo(1, headpos, -(AngleVectors(enemy.GetAngles())).Normalized(), Vector(), 0.1, player)
			info.SetDamage(1)
			info.SetTracerFreq(1)
			info.SetDamageForceScale(0)
			info.SetAmmoType(3)
			info.SetDistance(5000)
			if (enemy.GetHealth()>1) weaponmodel.FireBullets(info);
			
			local mod=clamp(0.35-(Time()-hittime),0,0.35)*120
			local ve=Vector(RandomFloat(-2,2),RandomFloat(-2,2),RandomFloat(-2,2))
			//camera.SetLocalOrigin(ve*mod)
			
			Entities.First().SetContextThink("heatactionshake",function(_) 
			{
				mod=clamp(0.35-(Time()-hittime),0,0.35)*4
				ve=Vector(RandomFloat(-4,4),RandomFloat(-4,4),RandomFloat(-1,1))
				camera.SetLocalAngles(ve*mod)
				
				if (mod==0) return
				
				return 0
			}.bindenv(this),0)
			
			local EffectTable={
			targetname="bt_effect",
			type=0
			}
			
			local dmg=CreateDamageInfo(player,player,Vector(),Vector(),1,DMG_DIRECT)
			dmg.ScaleDamageForce(0)
			if (enemy.GetHealth()>1) enemy.TakeDamage(dmg);
			
			ScrFX<-Entities.FindByName(null,"bt_effect")
			
			if (!ScrFX) ScrFX<-SpawnEntityFromTable("env_screeneffect",EffectTable);
			EntFireByHandle(ScrFX,"StartEffect",1,0)
			EntFireByHandle(ScrFX,"StopEffect",0.2,0)
			
			Entities.First().SetContextThink("heatactionslowmo",function(_) 
			{
				Convars.SetFloat("mat_autoexposure_min",0.5);
				Convars.SetFloat("mat_bloom_scalefactor_scalar",1)
			}.bindenv(this),0.1)
			Entities.First().SetContextThink("delaedsounddum",function(_) 
			{
				GetNamedEnt("PlayerModel").EmitSound("PlayerPunch")
				enemy.EmitSound("Canister.ImpactHard")
			}.bindenv(this),0)
		}
		
		if (type=="death")
		{
			local dmg=CreateDamageInfo(player,player,player.GetForwardVector()*7000,enemy.GetCenter()+Vector(0,0,1130),100,DMG_DIRECT)
			//dmg.ScaleDamageForce(0)
			enemy.TakeDamage(dmg);
		}
		if (type=="shoot")
		{
			local attach=weaponmodel.LookupAttachment("muzzle")
			local muzzle=weaponmodel.GetAttachmentOrigin(attach)
			local hittime=Time()
			
			local mod=clamp(0.35-(Time()-hittime),0,0.35)*120
			local ve=Vector(RandomFloat(-2,2),RandomFloat(-2,2),RandomFloat(-2,2))
			//camera.SetLocalOrigin(ve*mod)
			
			Entities.First().SetContextThink("heatactionshake",function(_) 
			{
				mod=clamp(0.2-(Time()-hittime),0,0.2)*2
				ve=Vector(RandomFloat(-4,4),RandomFloat(-4,4),RandomFloat(-1,1))
				camera.SetLocalAngles(ve*mod)
				
				if (mod==0) return
				
				return 0
			}.bindenv(this),0)
			
			DispatchParticleEffect("weapon_muzzle_flash_assaultrifle",muzzle,weaponmodel.GetAngles(),player)
			
			GetNamedEnt("PlayerModel").EmitSound(aPlayer.Weapon.ShootSound);
			
			local head=enemy.LookupAttachment("eyes")
			local headpos=enemy.GetAttachmentOrigin(head)
			
			//debugoverlay.Line(muzzle, (headpos-muzzle).Normalized()*64,255,30,30,true,3)
			
			local info = CreateFireBulletsInfo(1, headpos, -(AngleVectors(enemy.GetAngles())).Normalized(), Vector(), 100, player)
			info.SetTracerFreq(1)
			info.SetDamageForceScale(10)
			info.SetAmmoType(3)
			info.SetDistance(5000)
			weaponmodel.FireBullets(info);
			
			
			
			SendToConsole("host_timescale 0.35")
			SendToConsole("host_pitchscale 0.9")
			Convars.SetFloat("mat_autoexposure_min",10.5)
			Convars.SetFloat("mat_bloom_scalefactor_scalar",3)
			
			local EffectTable={
			targetname="bt_effect",
			type=0
			}
			
			ScrFX<-Entities.FindByName(null,"bt_effect")
			
			if (!ScrFX) ScrFX<-SpawnEntityFromTable("env_screeneffect",EffectTable);
			EntFireByHandle(ScrFX,"StartEffect",1,0)
			EntFireByHandle(ScrFX,"StopEffect",0.2,0)
			
			Entities.First().SetContextThink("heatactionslowmo2",function(_) 
			{
				SendToConsole("host_timescale 1");
				Convars.SetFloat("mat_autoexposure_min",0.5);
				Convars.SetFloat("mat_bloom_scalefactor_scalar",1)
				SendToConsole("host_pitchscale 1")
			}.bindenv(this),0.15)
			
		}
		
		
		return true
	}
	
	Hooks.Add( plr, "HandleAnimEvent", HandleEvent, "HandleEvent" );
}

function DeathCam(npc,npcmodel,deadtime=Time(),force=Vector())
{
	local eyevec=Vector(player.GetEyeForward().x,player.GetEyeForward().y,0)
	local eyevec2=Vector(player.GetEyeRight().x,player.GetEyeRight().y,0)
	
	
	cameraT<-{targetname="deathcam",speed=50,moveto="",trackspeed=2000,wait=10,target="!player",spawnflags=4+8+16+32+128,fov=70,fov_rate=0.05}
	//SendToConsole("thirdperson")

	player.SetVelocity(Vector())
	
	local EffectTable={
		targetname="bt_effect",
		type=0
	}
	
	SW_ScreenFade(0,0.2,255,255,255,25,true)
	
	ScrFX<-Entities.FindByName(null,"bt_effect")
			
	if (!ScrFX) ScrFX<-SpawnEntityFromTable("env_screeneffect",EffectTable);
	EntFireByHandle(ScrFX,"StartEffect",0.2,0)
	EntFireByHandle(ScrFX,"StopEffect",0.2,1)

	bosscamera<-SpawnEntityFromTable("point_viewcontrol",cameraT)
	bosscamera.AcceptInput("enable","",null,null)
	bosscamera.SetOrigin(player.EyePosition())
	bosscamera.SetAngles(player.EyeAngles())

		
	local DeathThinkOn=false
	
	LastDmgTime=Time()
	//Entities.FindByModel(null,model).SetName("player_body")
		//plr<-Entities.FindByModel(null,model)
		//body<-Entities.FindByModel(plr,model)
		//body.SetName("player_body")
		//bosscamera.AcceptInput("settarget","player_body",null,null)
	Entities.First().SetContextThink("CreateBossDeathcam",function(_)
	{
		body<-Entities.FindByModel(null,npcmodel)
		body.SetName("boss_body")
		body.SetCollisionGroup(1)
		
		bosscamera.AcceptInput("settarget","boss_body",null,null)
		
		eyes<-body.LookupAttachment("chest")
		ang<-body.GetAttachmentAngles(eyes)
		ang=AngleVectors(ang)
		
		local playerorigin=null
		playerorigin=body.GetAttachmentOrigin(eyes)+Vector(0,0,20)
		
		//printl(TraceLineComplex(playerorigin,playerorigin-eyevec*65,plr, MASK_SHOT, 1).DidHit())
		local fails=0;
		
		/*
		else if (!TraceLineComplex(playerorigin,playerorigin-eyevec*33,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin-eyevec*32;
		else if (!TraceLineComplex(playerorigin,playerorigin-eyevec2*65,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin-eyevec2*64;
		else if (!TraceLineComplex(playerorigin,playerorigin-eyevec2*33,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin-eyevec2*32;
		else if (!TraceLineComplex(playerorigin,playerorigin+eyevec2*65,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin+eyevec*64;
		*/
		
		//bosscamera.SetOrigin(playerorigin)
		
		//bosscamera.SetAngles(Entities.FindByModel(plr,model).GetAttachmentAngles(eyes))
		
		//BE.SetParent(Entities.FindByModel(plr,model),"chest")
		bosscamera.SetCollisionGroup(1)

		bosscamera.AcceptInput("enable","",null,null);
		//printl("bosscamera ENABLE")

		local deadtime=Time()
		local stoptime=Time()+100
		SendToConsole("crosshair 0")
		
		EntFireByHandle(bosscamera,"SetFOVRate",0.1,0);
		EntFireByHandle(bosscamera,"SetFOVRate",IntervalPerTick(),1);
		
		local forcepushed=false;

		Entities.First().SetContextThink("CreateBossDeathcamThink",function(_)
		{
			
			body<-Entities.FindByModel(null,npcmodel)
			if (body.GetClassname().find("npc")!=null) body=Entities.FindByModel(body,npcmodel)
			body.SetName("boss_body")
			body.SetCollisionGroup(1)
			playerorigin=body.GetAttachmentOrigin(eyes)
			
			if ("ApplyForceOffset" in body.GetPhysicsObject()&&!forcepushed)
			{
				forcepushed=true
				body.GetPhysicsObject().ApplyForceOffset(force*2,body.GetAttachmentOrigin(body.LookupAttachment("eyes")));
				body.GetPhysicsObject().ApplyForceOffset(force/2,body.GetAttachmentOrigin(body.LookupAttachment("chest")));
			}
	
			if (!DeathThinkOn&&TraceLineComplex(playerorigin,bosscamera.GetOrigin()-(playerorigin-bosscamera.GetOrigin()).Normalized()*2,body, MASK_SOLID, 1).Fraction()<0.8) 
			{
				bosscamera.AcceptInput("enable","",null,null);
				bosscamera.SetOrigin(playerorigin+(bosscamera.GetOrigin()-playerorigin)*TraceLineComplex(playerorigin,bosscamera.GetOrigin(),body, MASK_SOLID, 1).Fraction());
				bosscamera.AcceptInput("enable","",null,null);
			}
			
			
			bosscamera.AcceptInput("settarget","boss_body",null,null)
			
			eyes<-body.LookupAttachment("chest")
			ang<-body.GetAttachmentAngles(eyes)
			ang=AngleVectors(ang)
			
			//EntFireByHandle(bosscamera,"enable")
			local DeadUnZoom=clamp(Time()-deadtime-2,0,50)
			
			printl(DeadUnZoom)
			
		if (DeadUnZoom<1) {EntFireByHandle(bosscamera,"SetFOV",clamp(7000/(body.GetOrigin()-bosscamera.GetOrigin()).Length(),0,90));printl("ZOOMING TO BODY")}
			else 
			{
				if (!DeathThinkOn)
				{
					EntFireByHandle(bosscamera,"SetFOVRate",1,0);
					EntFireByHandle(bosscamera,"SetFOV",Convars.GetInt("fov_desired"),0.01);
					DeathThinkOn=true
					stoptime=Time()+1
					printl("STARTED UNZOOM")
					bosscamera.SetOrigin(player.EyePosition())
				}
			}
			if ((Time()-deadtime)>0)
			{
				if ((Time()-deadtime)<1.5) SendToConsole("host_timescale "+clamp(min(Time()-deadtime,Time()-LastDmgTime+0.2)-0.2,0.1,1));
				else SendToConsole("host_timescale "+clamp(Time()-deadtime-0.06,0.3,1));
				SendToConsole("host_pitchscale "+clamp((Time()-deadtime-0.06)/2+0.3,0.5,1))
			}
			local dist=0

			//EntFire("npc_combin*","updateenemymemory","deathcam_bullseye")
			//EntFire("npc_zomb*","updateenemymemory","deathcam_bullseye")
			//EntFire("npc_*zomb*","updateenemymemory","deathcam_bullseye")
			if (Time()>stoptime)
			{
				EntFire("deathcam","disable")
				SendToConsole("r_nearz -1")
				SendToConsole("crosshair 1")
				player.SetAngles(bosscamera.GetAngles())
				return
			}

			return 0
		}.bindenv(this),0)
		
		
	}.bindenv(this),0.01)
}

function IntroAction(name,WeaponHeld="weapon_colt",DrawWeapons=true,TurnHead=false,Forced=true)
{
	if (!player.IsAlive())
		return;
	
	CreatePlayerNPC(true)
	
	local camera=null
	
	if (!GetNamedEnt("PlayerCamera"))
	{
		local cameratable={
		targetname="PlayerCamera"
		origin=player.EyePosition().x+" "+player.EyePosition().y+" "+player.EyePosition().z
		angles=player.EyeAngles().x+" "+player.EyeAngles().y+" "+player.EyeAngles().z
		spawnflags=4+8+32+128
		fov=Convars.GetInt("fov_desired")
		fov_rate=0.5
		vscripts="swfm/antistuck.nut"
		ThinkFunction="Think"
		}
		camera=SpawnEntityFromTable("point_viewcontrol",cameratable);
	}
	camera.SetFov(95,0.5)
	
	EntFireByHandle(GetNamedEnt("PlayerModel"),"setexpressionoverride","",0.)
	EntFireByHandle(GetNamedEnt("PlayerModel"),"setexpressionoverride","scenes/Expressions/citizen_angry_idle_01.vcd",0.01)
	
	local weaponmodel=null
	
	if (WeaponHeld!=""&&DrawWeapons)
	{
		local wmodel=LIST_ITEMS[WeaponHeld].model	
		weaponmodel=SpawnEntityFromTable("prop_dynamic_ornament",{model=wmodel})
		EntFireByHandle(weaponmodel,"setattached","PlayerModel")
		EntFireByHandle(weaponmodel,"DisableShadow","")

		if (weaponmodel&&weaponmodel.GetModelName()!=wmodel) {weaponmodel.SetModel(wmodel);};
	}
	
	GetNamedEnt("PlayerModel").EmitSound("SW.Weapon.Foley")
	
	EntFireByHandle(camera,"Enable","",0.01)
	EntFire("Playermodel","StartScripting")
	EntFireByHandle(camera,"SetParent","PlayerModel")
	EntFireByHandle(camera,"SetParentAttachment","sw_camera")
	//EntFireByHandle(camera,"SetParentAttachmentMaintainOffset","sw_camera")
	camera.SetAbsOrigin(player.EyePosition())
	camera.SetAbsAngles(player.EyeAngles())
	
	SendToConsole("crosshair 0")
	SendToConsole("sourceworld_hud 2")
	
	local animid=GetNamedEnt("PlayerModel").LookupSequence(name)
	
	local scripttable={
		spawnflags=32
		m_fMoveTo=0
		m_iszPlay=name
		m_iszEntity="PlayerModel"
	}
	local sequence=SpawnEntityFromTable("scripted_sequence",scripttable);
	//EntFireByHandle(sequence,"BeginSequence","",0)
	//EntFireByHandle(sequence,"BeginSequence","",0)
	sequence.AcceptInput("BeginSequence","",null,null)
	sequence.AcceptInput("BeginSequence","",null,null)
	
	GetNamedEnt("PlayerModel").CapabilitiesRemove(4096)
	
	local diff=AngleVectors(player.GetAngles()+Vector(0,-180,0))
	diff.z=0;
	
	local targetang=GetNamedEnt("PlayerModel").GetAngles()+Vector(0,180,0)
	local targetpos=GetNamedEnt("PlayerModel").GetOrigin()-diff*44
	
	//enemy.SetAngles(GetNamedEnt("PlayerModel").GetAngles()+Vector(0,180,0))
	
	local StartTime=Time()
		
	
	Entities.First().SetContextThink("TakeDownEnemyMove",function(_) 
	{
		camera.GetScriptScope().ReturnPos=player.EyePosition()
		camera.GetScriptScope().ReturnAng=player.EyeAngles()
		camera.GetScriptScope().ReturnSpeed=3
		camera.GetScriptScope().ReturnTime=Time()+GetNamedEnt("PlayerModel").SequenceDuration(animid)-0.25
		
		GetNamedEnt("PlayerModel").AddLookTargetPos(GetNamedEnt("PlayerModel").EyePosition()+GetNamedEnt("PlayerModel").GetForwardVector()*1000,0.5,41,0);
		
		Entities.First().SetContextThink("HeatActionEnd",function(...){
			EntFireByHandle(camera,"Disable")
			camera.Destroy()
			GetNamedEnt("PlayerModel").Destroy()
			EntFireByHandle(sequence,"Kill")
			SendToConsole("crosshair 1")
			SendToConsole("r_nearz -1")
			SendToConsole("sourceworld_hud 0")
			//player.GetViewModel(0).SetModel("models/blackout.mdl")
			return
		}.bindenv(this),GetNamedEnt("PlayerModel").SequenceDuration(animid))
		
		return;
		return 0
	}.bindenv(this),0)
	
	function HandleEvent(event)
	{
		local EventFrame=event.GetCycle()*GetNamedEnt("PlayerModel").SequenceDuration(GetNamedEnt("PlayerModel").GetSequence())*30
		// Assuming that all animations are at 30 fps(there's no way to get the fps of current animation sadly) we can get the frame this event was triggered
		
		printl("ANIM EVENT INFO: "+event.GetEvent()+" - "+EventFrame+" - "+event.GetOptions())
		local type=event.GetOptions()
		
		if (type.find("fov")!=null)
		{
			local parms=split(type," ")
			local fov=parms[1].tointeger()
			local rate=parms[2].tofloat()
			EntFireByHandle(camera,"SetFovRate",rate)
			EntFireByHandle(camera,"SetFov",fov)
		}
		
		if (type.find("camerachange")!=null)
		{
			local parms=split(type," ")
			local fov=null
			if (parms.len()>1) 
			{
				fov=parms[1].tointeger()
				EntFireByHandle(camera,"SetFovRate",0)
				EntFireByHandle(camera,"SetFov",fov,0.15)
			}
			camera.AcceptInput("SetParent","",null,null)
			camera.AcceptInput("SetParent","PlayerModel",null,null)
			EntFireByHandle(camera,"SetParentAttachment","sw_camera",0.15)
		}

		return true
	}
	
	local plr=GetNamedEnt("PlayerModel").GetOrCreatePrivateScriptScope()
	Hooks.Add( plr, "HandleAnimEvent", HandleEvent, "HandleEvent" );
	
}

WillEscape<-false;

function GrabAction(name,enemy=null)
{
	if (!player.IsAlive()||GetNamedEnt("deathcam"))
		return;
	
	if (!enemy) return false;
	
	CreatePlayerNPC()
	
	WillEscape=false;
	
	LastGrabbedTime=Time()
	
	EndGrab<-0;
	
	local camera=null
	
	enemy.SetVelocity(Vector())
	
	if (!GetNamedEnt("PlayerCamera"))
	{
		local cameratable={
		targetname="PlayerCamera"
		origin=player.EyePosition().x+" "+player.EyePosition().y+" "+player.EyePosition().z
		angles=player.EyeAngles().x+" "+player.EyeAngles().y+" "+player.EyeAngles().z
		spawnflags=4+8+32+128
		fov=Convars.GetInt("fov_desired")
		fov_rate=0.5
		vscripts="swfm/antistuck.nut"
		ThinkFunction="ThinkAlt"
		}
		camera=SpawnEntityFromTable("point_viewcontrol",cameratable);
		camera.GetOrCreatePrivateScriptScope().Enemy=enemy;
	}
	camera.SetFov(95,0.5)
	camera.GetOrCreatePrivateScriptScope().Enemy=enemy;
	
	EntFireByHandle(GetNamedEnt("PlayerModel"),"setexpressionoverride","",0.)
	EntFireByHandle(GetNamedEnt("PlayerModel"),"setexpressionoverride","scenes/Expressions/citizen_angry_idle_01.vcd",0.01)
	
	local weaponmodel=null
	
	GetNamedEnt("PlayerModel").EmitSound("SW.Weapon.Foley")
	
	local newname=UniqueString("poor_guy")
	
	if (enemy.GetName().len()<1) enemy.SetName(newname);
	
	EntFireByHandle(camera,"Enable","",0.01)
	EntFire("Playermodel","Setplaybackrate","0.01",0.05)
	EntFire("Playermodel","StartScripting")
	EntFireByHandle(camera,"SetParent",newname)
	
	Entities.First().SetContextThink("GrabReparent",function(_) 
	{	
		if (!camera.GetMoveParent()) 
		{
			camera.GetOrCreatePrivateScriptScope().Enemy=enemy;
			camera.GetScriptScope().ReturnPos=player.EyePosition()
			camera.GetScriptScope().ReturnAng=player.EyeAngles()
			camera.GetScriptScope().ReturnSpeed=3
			camera.GetScriptScope().ReturnTime=Time()+GetNamedEnt("PlayerModel").SequenceDuration(animid)+0.25
		}
		if (!camera.GetMoveParent()) EntFireByHandle(camera,"SetParent",newname)
		else return;
	}.bindenv(this),0.01);
	//EntFireByHandle(camera,"SetParent",newname,0.01)
	//EntFireByHandle(camera,"SetParent",newname,0.1)
	//EntFireByHandle(camera,"SetParent",newname,0.2)
	//if (cam)
	//camera.AcceptInput("setparent",enemy,self,self)
	//EntFireByHandle(camera,"SetParentAttachmentMaintainOffset","sw_camera")
	camera.SetAbsOrigin(player.EyePosition())
	camera.SetAbsAngles(player.EyeAngles())
	
	SendToConsole("crosshair 0")
	
	local animid=GetNamedEnt("PlayerModel").LookupSequence(name+"_v")
	
	local scripttable={
		spawnflags=32
		m_fMoveTo=0
		m_iszPlay=name+"_death_v"
		m_iszEntry=name+"_v"
		m_iszEntity="PlayerModel"
	}
	local sequence=SpawnEntityFromTable("scripted_sequence",scripttable);
	EntFireByHandle(sequence,"BeginSequence","",0)
	EntFireByHandle(self,"callscriptfunctionclient","GrabUI",0.1)
	EntFireByHandle(self,"callscriptfunctionclient","GrabUIClose",5)
	
	local diff=AngleVectors(player.GetAngles()+Vector(0,-180,0))
	diff.z=0;
	
	local targetang=GetNamedEnt("PlayerModel").GetAngles()+Vector(0,180,0)
	local targetpos=GetNamedEnt("PlayerModel").GetOrigin()-diff*44
	targetpos.z=enemy.GetOrigin().z
	
	//enemy.SetAngles(GetNamedEnt("PlayerModel").GetAngles()+Vector(0,180,0))
	
	local StartTime=Time()
	
	if (enemy.GetActiveWeapon()) enemy.GetActiveWeapon().SetRenderMode(6)
		
	//local HealthRegen=15;
	//player.SetHealth(clamp( player.GetHealth()+HealthRegen,0,max(PlayerMaxHealth,player.GetHealth()) ) )
	
	function HeatActionEnd()
	{
		Entities.First().SetContextThink("DrainPlayerHealth",function(_) 
		{	
			return;
		}.bindenv(this),0);
		
		if (!WillEscape&&enemy&&enemy.IsValid()&&enemy.IsAlive())
		{
			local Damage=CreateDamageInfo(enemy,enemy,enemy.GetForwardVector()*100,enemy.GetForwardVector()*100,10000000,4194304 )
			Damage.SetAttacker(enemy)
			SW_GAMEOVER(Damage,"models/player.mdl",true)
			enemy.SetMaxHealth(999999)
			enemy.SetHealth(999999)
			camera.GetScriptScope().ReturnTime=Time()+1000
			player.SetHealth(0);
			EndGrab=Time()+enemy.SequenceDuration(enemy.LookupSequence(name+"_escape"))
			return
		}
		else
		{
			if (EndGrab==0)
			{
				if (!(enemy&&enemy.IsValid()&&enemy.IsAlive())) return 0;
				EndGrab=1;
				camera.GetScriptScope().ReturnTime=Time()+enemy.SequenceDuration(enemy.LookupSequence(name+"_escape"))
				return enemy.SequenceDuration(enemy.LookupSequence(name+"_escape"))
			}
			
			if (enemy&&enemy.IsValid()&&enemy.IsAlive()&&enemy.GetActiveWeapon()) enemy.GetActiveWeapon().SetRenderMode(0)
			if (enemy&&enemy.IsValid()&&enemy.IsValid()&&enemy.IsAlive()) enemy.SetMoveType(3);
			EntFireByHandle(camera,"Disable")
			camera.Destroy()
			if (GetNamedEnt("PlayerModel")&&GetNamedEnt("PlayerModel").IsValid()) GetNamedEnt("PlayerModel").Destroy()
			EntFireByHandle(sequence,"Kill")
			SendToConsole("crosshair 1")
			SendToConsole("r_nearz -1")
			if (enemy&&enemy.IsValid()&&enemy.IsAlive()&&enemy.GetName().find("poor_guy")!=null) enemy.SetName("");
			
			player.GetViewModel(0).SetModel("models/blackout.mdl")
			
			if (enemy&&enemy.IsValid()&&enemy.IsAlive()) Entities.First().SetContextThink("HeatActionEndFlinch",function(...){
				enemy.SetSchedule("SCHED_COWER")
			}.bindenv(this),0.1)
			
			
			if (enemy&&enemy.IsValid()&&enemy.IsAlive()&&enemy.GetActiveWeapon()) enemy.GetActiveWeapon().SetRenderMode(0)
			return
		}
		return 0;
	}
	
	enemy.ResetSequenceInfo()
	
	Entities.First().SetContextThink("Check_liveness_grab",function(_) 
	{	
		if ((!enemy)||(!enemy.IsValid())||(!enemy.IsAlive()))
		{
			WillEscape=true
			HeatActionEnd()
			HeatActionEnd()
			EntFireByHandle(self,"callscriptfunctionclient","GrabUIClose",0)
			return
		}
		return 0
	}.bindenv(this),0);
	
	Entities.First().SetContextThink("DrainPlayerHealth",function(_) 
	{	
		player.SetHealth(max(player.GetHealth()-1,1))
		return 0.2
	}.bindenv(this),0);
	
	Entities.First().SetContextThink("TakeDownEnemyMove",function(_) 
	{	
		GetNamedEnt("PlayerModel").AddLookTarget(enemy,0.5,41,0);
		enemy.AddLookTarget(GetNamedEnt("PlayerModel"),0.5,41,0);
		//if (!TurnHead) enemy.CapabilitiesRemove(4096)
		//enemy.SetSequence(enemy.LookupSequence(name+"_v"))
		enemy.SetMoveType(8)
		enemy.SetVelocity((targetpos-enemy.GetOrigin()).Normalized()*200)
		enemy.SetAngles(enemy.GetAngles()+Vector(0,AngleDiff(targetang.y,enemy.GetAngles().y)).Normalized()*3)
		//enemy.SetSequence(enemy.LookupSequence(name+"_v"))
		if ((enemy.GetOrigin()-targetpos).Length()<2) 
		{
			//EntFireByHandle(camera,"Enable","",0.01)
			//camera.SetAbsOrigin(player.EyePosition())
			//camera.SetAbsAngles(player.EyeAngles())
			
			enemy.SetVelocity(Vector())
			enemy.SetAngles(targetang)
			enemy.SetOrigin(targetpos)
			//enemy.SetSequence(enemy.LookupSequence(name+"_v"))
			enemy.SetCycle(0)
			GetNamedEnt("PlayerModel").SetCycle(0)
			EntFire("Playermodel","Setplaybackrate","1",0.05)
			
			camera.GetScriptScope().ReturnPos=player.EyePosition()
			camera.GetScriptScope().ReturnAng=player.EyeAngles()
			camera.GetScriptScope().ReturnSpeed=3
			camera.GetScriptScope().ReturnTime=Time()+GetNamedEnt("PlayerModel").SequenceDuration(animid)+0.25
			
			Entities.First().SetContextThink("HeatActionEnd",function(...){
				return HeatActionEnd()
			}.bindenv(this),enemy.SequenceDuration(enemy.LookupSequence(name))-0.1)
			
			return;
		}
		return 0
	}.bindenv(this),0)
	
	//local ogZ=enemy.GetOrigin().z
	
	//enemy.SetOrigin(GetNamedEnt("PlayerModel").GetOrigin()-diff*44)
	//enemy.SetOrigin(Vector(enemy.GetOrigin().x,enemy.GetOrigin().y,ogZ))
	
	EntFireByHandle(enemy,"StartScripting")
	
	local animid_v=enemy.LookupSequence(name)
	
	local scripttable2={
		spawnflags=32+64+512+4096+2048
		m_fMoveTo=0
		m_iszPlay=name+"_death"
		m_iszEntry=name
		m_iszEntity=enemy.GetName()
	}
	local sequence2=SpawnEntityFromTable("scripted_sequence",scripttable2);
	EntFireByHandle(sequence2,"BeginSequence","",0)
	EntFireByHandle(sequence2,"BeginSequence","",0.1)
	EntFireByHandle(sequence2,"BeginSequence","",0.2)
	EntFireByHandle(sequence2,"BeginSequence","",0.3)
	EntFireByHandle(sequence2,"BeginSequence","",0.4)
	EntFireByHandle(sequence2,"BeginSequence","",0.45)
	EntFireByHandle(sequence2,"BeginSequence","",0.5)

	
	
	NetMsg.Receive("GrabEscape", function( player )
	{
		if (!enemy||!enemy.IsValid()||!enemy.IsAlive()) return;
		
		WillEscape=true;
		EntFireByHandle(sequence,"addoutput","m_iszPlay "+name+"_escape_v")
		EntFireByHandle(sequence2,"addoutput","m_iszPlay "+name+"_escape")
		enemy.SetCycle(1)
		GetNamedEnt("PlayerModel").SetCycle(1)
		HeatActionEnd()
		Entities.First().SetContextThink("HeatActionEnd",function(...){
			return HeatActionEnd()
		}.bindenv(this),enemy.SequenceDuration(enemy.LookupSequence(name+"_escape")))
		
	}.bindenv(this) );
	
	NetMsg.Receive("GrabEscapeProgress", function( player )
	{
		local speed=NetMsg.ReadFloat()*0.15
		
		local hittime=Time()
			
		local mod=clamp(0.2-(Time()-hittime),0,0.2)*speed
		local ve=Vector(RandomFloat(-2,2),RandomFloat(-2,2),RandomFloat(-2,2))
		if (camera&&camera.IsValid()) camera.SetLocalOrigin(ve*mod)
		
		if (Time()-LastGrabbedTime>0.5) Entities.First().SetContextThink("heatactionshake",function(_) 
		{
			mod=clamp(0.2-(Time()-hittime),0,0.2)*speed+0.001
			ve=Vector(RandomFloat(-1,1),RandomFloat(-5,5),RandomFloat(-4,4))
			if (camera&&camera.IsValid()) camera.SetLocalAngles(ve*mod)
			
			if (mod==0) return
			
			return 0
		}.bindenv(this),0)
		
	}.bindenv(this) );
	
	
	local plr=GetNamedEnt("PlayerModel").GetOrCreatePrivateScriptScope()
	
	function HandleEvent(event)
	{
		//printl("ANIM EVENT INFO: "+event.GetEvent()+" - "+event.GetType()+" - "+event.GetOptions())
		local type=event.GetOptions()
		
		if (type=="punch")
		{
			SendToConsole("host_timescale 0.6")
			SendToConsole("host_pitchscale 0.9")
			Convars.SetFloat("mat_autoexposure_min",10.5)
			Convars.SetFloat("mat_bloom_scalefactor_scalar",3)
			
			local EffectTable={
			targetname="bt_effect",
			type=0
			}
			
			local hittime=Time()
			
			local mod=clamp(0.2-(Time()-hittime),0,0.2)*5
			local ve=Vector(RandomFloat(-2,2),RandomFloat(-2,2),RandomFloat(-2,2))
			camera.SetLocalOrigin(ve*mod)
			
			Entities.First().SetContextThink("heatactionshake",function(_) 
			{
				mod=clamp(0.2-(Time()-hittime),0,0.2)*5
				ve=Vector(RandomFloat(-4,4),RandomFloat(-4,4),RandomFloat(-4,4))
				camera.SetLocalAngles(ve*mod)
				
				if (mod==0) return
				
				return 0
			}.bindenv(this),0)
			
			
			local dmg=CreateDamageInfo(player,player,Vector(),Vector(),min(enemy.GetHealth()-1,5),DMG_DIRECT)
			dmg.ScaleDamageForce(0)
			if (enemy.GetHealth()>1) enemy.TakeDamage(dmg);
			
			ScrFX<-Entities.FindByName(null,"bt_effect")
			
			if (!ScrFX) ScrFX<-SpawnEntityFromTable("env_screeneffect",EffectTable);
			EntFireByHandle(ScrFX,"StartEffect",1,0)
			EntFireByHandle(ScrFX,"StopEffect",0.2,0)
			
			Entities.First().SetContextThink("heatactionslowmo",function(_) 
			{
				SendToConsole("host_timescale 1");
				//SendToConsole("host_pitchscale 1")
				Convars.SetFloat("mat_autoexposure_min",0.5);
				Convars.SetFloat("mat_bloom_scalefactor_scalar",1)
			}.bindenv(this),0.1)
			Entities.First().SetContextThink("delaedsounddum",function(_) 
			{
				GetNamedEnt("PlayerModel").EmitSound("PlayerPunch")
			}.bindenv(this),0)
		}
		
		if (type=="death")
		{
			local dmg=CreateDamageInfo(player,player,player.GetForwardVector()*7000,enemy.GetCenter()+Vector(0,0,1130),100,DMG_DIRECT)
			//dmg.ScaleDamageForce(0)
			enemy.TakeDamage(dmg);
		}

		return true
	}
	
	Hooks.Add( plr, "HandleAnimEvent", HandleEvent, "HandleEvent" );
}


Convars.RegisterCommand( "takedown", function(_)
{
	if (aPlayer.Weapon.Name=="weapon_pipe") HeatAction("takedown_pipe");
	else HeatAction("takedown_pistol");
}.bindenv(this), "", FCVAR_CLIENTDLL );

}

if (CLIENT_DLL)
{
	local grab_panel=null
	
	local EscapeMeter=0;
	local speed=0
	local LastDir=true
	
	local GrabTime=Time()
	local LastBeat=0;
	
	function PaintGrab()
	{
		if (Time()-LastBeat>0&&player.GetHealth()>10)
		{
			surface.PlaySound("player/heartbeatloop.wav")
			LastBeat=Time()+clamp((5-(Time()-GrabTime))/5.0,0.3,0.7)
		}
		
		surface.SetColor(255,255,255,255)
		surface.SetTexture(surface.ValidateTexture("vgui/hud/gameinstructor_iconsheet2",true,false,false))
		
		local KeyHintFont=surface.GetFont( "KeyHint5", true )
		local BigNotificationFont=surface.GetFont("BigNotification",true)
		local BigNotificationBlurFont=surface.GetFont("BigNotificationBlur",true)
		local GlowSprite=surface.ValidateTexture("vgui/glow",true,false,false)
		
		
		local x=ScreenWidth()/2
		local y=YRES(355)
		
		local xoffset=surface.GetTextWidth(BigNotificationBlurFont,"Break Free")+YRES(8)
		local yoffset=(-YRES(24)/2+surface.GetFontTall(BigNotificationBlurFont)/2.0)
		
		local right=(Time()%0.4)>=0.2 ? 0 : 0.25
		
		local size=YRES(32)+YRES(2)*sin(Time()*12)
		
		surface.SetColor(220+35*sin(Time()*15),40,40,20+235*fabs(cos(Time()*15)))
		surface.SetTexture(GlowSprite)
		surface.DrawTexturedRectRotated(x-size*2.5+YRES(speed*0.05),y-YRES(32)-size-YRES(5),size*5,size*2,RandomInt(-30,30))
		surface.DrawTexturedRectRotated(x-size*2.5+YRES(speed*0.05),y-YRES(32)-size-YRES(5),size*5,size*2,RandomInt(-30,30))
		surface.DrawTexturedRectRotated(x-size*2.5+YRES(speed*0.05),y-YRES(32)-size-YRES(5),size*5,size*2,RandomInt(0,359))
		
		surface.SetTexture(surface.ValidateTexture("vgui/hud/gameinstructor_iconsheet2",true,false,false))
		surface.SetColor(255,255,255,255)
		surface.DrawTexturedSubRect(x-size/2+YRES(speed*0.05),y+yoffset-YRES(32)-size/2,x+size/2+YRES(speed*0.05),y+yoffset-YRES(32)+size/2,0+right,0.75,0.25+right,1)
		surface.DrawTexturedSubRect(x-size/2+YRES(speed*0.05),y+yoffset-YRES(32)-size/2,x+size/2+YRES(speed*0.05),y+yoffset-YRES(32)+size/2,0+right,0.75,0.25+right,1)
		surface.DrawTexturedSubRect(x-size/2+YRES(speed*0.05),y+yoffset-YRES(32)-size/2,x+size/2+YRES(speed*0.05),y+yoffset-YRES(32)+size/2,0+right,0.75,0.25+right,1)
		//surface.DrawColoredText(KeyHintFont,x+xoffset+YRES(24)/2.0-surface.GetTextWidth(KeyHintFont,"")/2.0,y+yoffset+YRES(24)/2.0-surface.GetFontTall(KeyHintFont)/2.0,25,185,255,255,"E")
			 
		surface.DrawColoredText(BigNotificationFont,x-surface.GetTextWidth(BigNotificationBlurFont,"Break Free")/2,y,255, 255, 255,255,"Break Free")
		surface.DrawColoredText(BigNotificationBlurFont,x-surface.GetTextWidth(BigNotificationBlurFont,"Break Free")/2,y,255, 30, 25,255*sin(Time()*12),"Break Free")
		surface.DrawColoredText(BigNotificationBlurFont,x-surface.GetTextWidth(BigNotificationBlurFont,"Break Free")/2,y,255, 2, 2,255*cos(Time()*12),"Break Free")
	}
	function KeyCodeGrab(a)
	{
		printl("KEY PRESSED")
	}
	local LastX=ScreenWidth()/2
	local LastY=ScreenHeight()/2
	local Escaped=false;
	
	function GrabUIClose()
	{
		if (grab_panel && grab_panel.IsValid() )
		{
			grab_panel.Destroy();
			grab_panel = null;
		}
	}
	
	function GrabStruggle(x,y)
	{
		if (FrameTime()==0) return;
		
		speed=(YRES(x-LastX)/FrameTime())/250.0
		printl("HORIZONTAL: "+speed)
		if (fabs(speed)>1)
		{
			local NewDir=(speed>=0)
			
			if (NewDir!=LastDir) {
				EscapeMeter+=sqrt(fabs(speed));
				NetMsg.Start("GrabEscapeProgress");
				NetMsg.WriteFloat(sqrt(fabs(speed)))
				NetMsg.Send();
			}
			LastDir=NewDir;
		}
		LastX=x
		LastY=y
		
		if (!Escaped&&EscapeMeter>=100)
		{
			Escaped=true;
			
			NetMsg.Start("GrabEscape");
			NetMsg.Send();
			
			GrabUIClose()
		}
	}
	function GrabUI()
	{
		EscapeMeter=0;
		Escaped=false;
		GrabTime=Time()
		
		grab_panel = vgui.CreatePanel( "Panel", vgui.GetClientDLLRootPanel(), "ExamplePanel" );
		grab_panel.MakeReadyForUse();
		grab_panel.SetBgColor( 0, 0, 0, 0 );
		grab_panel.SetPos( 0,0 );
		grab_panel.SetSize( ScreenWidth(),ScreenHeight() );
		grab_panel.SetCallback( "Paint", PaintGrab.bindenv(this) )
		grab_panel.SetCallback( "OnKeyCodePressed", KeyCodeGrab.bindenv(this) );
		grab_panel.SetCallback( "OnCursorMoved", GrabStruggle.bindenv(this) );
		grab_panel.MakePopup()
		grab_panel.SetCursor(CursorCode.dc_blank)
	}
}