local DecayTime=0;

PrecacheParticleSystem("corruptor_splash")
PrecacheParticleSystem("blood_impact_purple_01")
PrecacheParticleSystem("blood_impact_synth_01_spurt")

local LastSound=0

function DecayCorpse(ent)
{
	//printl("Decaying!!!")
	
	if (ent&&ent.IsValid()&&ent.GetClassname()=="prop_ragdoll"&&ent.GetModelName().find("corrupt")!=null)
	{
		//EntFireByHandle(ent,"sleep")
		
		//printl("Decaying"+(Time()-ent.GetScriptScope().DecayTime))
		if (ent.GetScriptScope().DecayTime==0) ent.GetScriptScope().DecayTime=Time();
		
		local DecayMod=(Time()-ent.GetScriptScope().DecayTime)
		
		if (Time()-LastSound>3) 
		{
			ent.PrecacheSoundScript("Corruptor.Decay")
			ent.EmitSound("Corruptor.Decay")
			
			LastSound=Time()
		}
		//ent.SetModelScale(1-DecayMod*0.18,0)
		//printl(ent.GetRagdollObject(0))
		//for(local i=0;i<16;i++)

	
		//DispatchParticleEffect("blood_impact_red_01",ent.GetOrigin(),Vector(),ent)
		
		for (local i=0;i<clamp(RandomInt(0,30),2,ent.GetNumBones());i++)
		{
			local m=matrix3x4_t()
			ent.GetBoneTransform(i,m)
			
			local a=Vector()
			local b=Vector()
			
			MatrixAngles(m,a,b)
			
			local endpos=TraceLineComplex(b+Vector(0,0,20),b+Vector(0,0,-100),ent,MASK_SHOT,1).EndPos()
			
			local tim=Time()-ent.GetScriptScope().DecayTime
			
			
			if (RandomInt(0,tim<1 ? 90 : 40)==1) DispatchParticleEffect("corruptor_splash",endpos,Vector(-90,0,0),ent)
			if (RandomInt(0,40)==1) DispatchParticleEffect("blood_impact_purple_01",b,Vector(-45,0,0),ent)
				
			if (Time()-ent.GetScriptScope().DecayTime<0.2&&RandomInt(1,10)==1)
			{
				local dmgtrace2=TraceLineComplex(b,b+Vector(RandomInt(-50,50),RandomInt(-50,50),-100),ent,MASK_SHOT,1)
				DecalTrace(dmgtrace2,"PurpleBlood")
			}
			
			
			
			if (tim>0.5&&i<16) 
			{
				ent.GetPhysicsObject().Wake()
				ent.GetPhysicsObject().EnableGravity(false)
				ent.SetMoveType(7)
				ent.SetVelocity(Vector(0,0,-1))
				ent.SetGravity(10)
				
				ent.GetRagdollObject(i).EnableGravity(false)
				ent.GetRagdollObject(i).EnableCollisions(false)
				ent.GetRagdollObject(i).ApplyForceCenter(Vector(0,0,-tim*0.1)*ent.GetRagdollObject(i).GetMass());
			}
			//if (RandomInt(0,100)==1) DispatchParticleEffect("blood_impact_synth_01_spurt",b,Vector(-45,0,0),ent)
		
		//printl(a+" "+b)
		}
		
		ent.SetRenderColor(255, clamp(255-DecayMod*200,0,255), 255)
		ent.SetRenderMode(3)
		ent.SetAlpha(clamp(255-DecayMod*105+180,0,255))
		//ent.Destroy()
	}
	else return;
	
	if (Time()-ent.GetScriptScope().DecayTime<5) return 0.05;
	else
	{
		ent.Destroy()
		return -1
	}
}

function InitCorruptorCorpse(ent)
{
	if (ent.GetClassname()=="prop_ragdoll")
	{
		ent.GetOrCreatePrivateScriptScope().DecayTime<-0;
		
		Entities.First().SetContextThink(UniqueString("CorpseDecay"),function(_){return DecayCorpse(ent)}.bindenv(this),2.5)
	}		
}



Hooks.Add(this,"OnEntityCreated",function (ent) {InitCorruptorCorpse(ent)}.bindenv(this),"corruptor_corpse"+RandomInt(1,1000));