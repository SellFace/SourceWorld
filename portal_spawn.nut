local Num=AINetwork.NumNodes()

local Nodes=[]
for (local i=0;i<Num;i++) Nodes.append(i);

local ChosenNodes=[]

/*
function NodeCloseToChosens(Node)
{
	foreach (c in ChosenNodes)
	{
		local pos1=AINetwork.GetNodePosition(Node)+Vector(0,0,48)
		local pos2=AINetwork.GetNodePosition(c)+Vector(0,0,48)
		
		if (pos1.DistTo(pos2)<500) return true
	}
	return false
}
*/
local restart=false;

for (local j=0;j<Num;j++)
{
	restart=false;
	foreach (i,Node in Nodes)
	{
		local Pos=AINetwork.GetNodePosition(Node)+Vector(0,0,48)
		
		local dist=58
		
		local trig=null
		while (trig=Entities.FindByName(trig,"SW_NO_PORTAL"))	// exclude all nodes in SW_NO_PORTAL zones
		{
			if (trig.PointIsWithin(Pos))
			{
				Nodes.remove(i)
				i--;
				restart=true
			}
		}
		if (restart) break;
		
		if (TraceLineComplex(Pos+Vector(dist,0,0),Pos-Vector(dist,0,0),player, MASK_SHOT, 1).DidHit()||TraceLineComplex(Pos+Vector(0,dist,0),Pos-Vector(0,dist,0),player, MASK_SHOT, 1).DidHit()||TraceLineComplex(Pos+Vector(0,0,48),Pos-Vector(0,0,40),player, MASK_SHOT, 1).DidHit())
		{
			Nodes.remove(i)
			i--;
		}

	}
}

function get_angles(p1, p2, p3)	//takes vectors
{
	p1.z=0;
	p2.z=0;
	p3.z=0;
	
    local a = p2.DistTo(p3)
    local b = p1.DistTo(p3)
    local c = p1.DistTo(p2)
    
    local alpha = acos(clamp((b*b + c*c - a*a) / (2 * b * c), -1.0, 1.0))
    local beta = acos(clamp((a*a + c*c - b*b) / (2 * a * c), -1.0, 1.0))
    local gamma = PI - alpha - beta
    
    return [alpha*180/PI, beta*180/PI, gamma*180/PI]
}

function is_inside_triangle(p, p1, p2, p3)
{
    local denom = (p2.y - p3.y) * (p1.x - p3.x) + (p3.x - p2.x) * (p1.y - p3.y)
    if (abs(denom) < 0.1)
        return false;
        
    local w1 = ((p2.y - p3.y) * (p.x - p3.x) + (p3.x - p2.x) * (p.y - p3.y)) / denom
    local w2 = ((p3.y - p1.y) * (p.x - p3.x) + (p1.x - p3.x) * (p.y - p3.y)) / denom
    local w3 = 1.0 - w1 - w2
	
	if (w1<0.1||w2<0.1||w3<0.1) return false;
    
    return ((w1 > 0) && (w2 > 0) && (w3 > 0))
}

local best_triangle_indices = null
local best_center_index = null
local best_score = 99999999;

local best_centroid=Vector()

const a=75
const b=74
const m=65537
rng<-null

::RNG<-function()
{
	local seed=date().sec.tostring()+date().min.tostring()+date().hour.tostring()+((clock()*100)%1000).tostring()
	if (rng==null) rng=seed.tointeger();
	rng=(rng*a+b)%m
	//printl(rng)
	return rng
}

rng<-null


local i=(-1);
Entities.First().SetContextThink("PortalPrespawnSpots",function(_)
{

while (i<Nodes.len())
{
	i++;
    local tri_idx = [null,null,null]
	while (tri_idx.find(null)!=null)	// take 3 random points;
	{
		local rnd=Nodes[RandomInt(0,Nodes.len()-1)]
		if (tri_idx.find(rnd)==null)
			tri_idx[tri_idx.find(null)]=rnd;
	}
    local p1=AINetwork.GetNodePosition(tri_idx[0])
    local p2=AINetwork.GetNodePosition(tri_idx[1])
    local p3=AINetwork.GetNodePosition(tri_idx[2])
    
    local angles = get_angles(p1, p2, p3)
    local score = pow((angles[0] - 60),2)+pow((angles[1] - 60),2)+pow((angles[2] - 60),2)+abs(RNG())%1000
	if (p1.DistTo(p3)<1000) score+=10
	if (p1.DistTo(p2)<1000) score+=10
	if (p3.DistTo(p2)<1000) score+=10
	if (p1.DistTo(p3)<600) score+=1000
	if (p1.DistTo(p2)<600) score+=1000
	if (p3.DistTo(p2)<600) score+=1000
    
    if (score >= best_score)
        continue;
        
	local centroid = Vector((p1.x+p2.x+p3.x)/3.0,(p1.y+p2.y+p3.y)/3.0,0)
	
    
    local rem_indices = []
	for (local j=0;j<Nodes.len();j++)
		if (tri_idx.find(Nodes[j])==null) rem_indices.append(Nodes[j]);
    
    function Sorter(a,b)
	{
		local p1=AINetwork.GetNodePosition(a)
		local p2=AINetwork.GetNodePosition(b)
		p1.z=0;p2.z=0;
		
		if (p1.DistTo(centroid)<p2.DistTo(centroid)) return -1
		if (p1.DistTo(centroid)>p2.DistTo(centroid)) return 1
		return 0;
	}
	rem_indices.sort(Sorter)
    
    local found_center = false
    foreach (idx in rem_indices)
	{
        local pt = AINetwork.GetNodePosition(idx)
        
        if (is_inside_triangle(pt, p1, p2, p3))
		{
            best_triangle_indices = tri_idx
            best_center_index = idx
            best_centroid = centroid
            best_score = score
            found_center = true
            break
		}
	}
	return 0.01
}
return;

}.bindenv(this),0.1)

/*
while (Num>3&&Nodes.len()>0)
{
	foreach (i,Node in Nodes)
	{
		local Pos=AINetwork.GetNodePosition(Node)+Vector(0,0,48)
		
		local dist=64
		
		
		if (TraceLineComplex(Pos+Vector(dist,0,0),Pos-Vector(dist,0,0),player, MASK_SHOT, 1).DidHit()||TraceLineComplex(Pos+Vector(0,dist,0),Pos-Vector(0,dist,0),player, MASK_SHOT, 1).DidHit()||TraceLineComplex(Pos+Vector(0,0,dist*0.5),Pos-Vector(0,0,dist*0.25),player, MASK_SHOT, 1).DidHit())
		{
			Nodes.remove(i)
		}
		else
		{
			Nodes.remove(i)
			ChosenNodes.append(Node)
		}
	}
}
*/

function OpenPortal()
{
	local pos=AINetwork.GetNodePosition(best_center_index)+Vector(0,0,48)
	
	
	ShakePlayerScreen(150,4,5,false,3)
	
	local portal=SpawnEntityFromTable("prop_dynamic",{
		origin=pos.ToKVString(),
		model="models/effects/combineball.mdl",
		rendermode=10,
		disableshadows=1,
		solid=0,
		thinkfunction="Think",
		vscripts="exit_portal.nut",
	})
	
	local amb1=SpawnEntityFromTable("ambient_generic",{
		origin=pos.ToKVString(),
		health=10
		message="debris/beamstart7.wav"
		spawnflags=16+32
		radius=1500
	})
	local amb2=SpawnEntityFromTable("ambient_generic",{
		origin=pos.ToKVString(),
		health=10
		message="ambient/levels/citadel/core_contained_loop1.wav"
		spawnflags=16+32
		radius=500
	})
	local amb3=SpawnEntityFromTable("ambient_generic",{
		origin=pos.ToKVString(),
		health=5
		message="ambient/levels/citadel/citadel_drone_loop3.wav"
		pitch=60
		spawnflags=16+32
		radius=500
	})
	EntFireByHandle(amb1,"playsound")
	EntFireByHandle(amb2,"playsound")
	EntFireByHandle(amb3,"playsound")
	
	
	local warp1=SpawnEntityFromTable("prop_dynamic",{
		origin=pos.ToKVString(),
		model="models/effects/intro_vortshield.mdl",
		disableshadows=1,
		modelscale=0.1,
		rendermode=1,
		rendercolor="56 237 239",
		targetname="portal_warp"
	})
	
	warp1.PrecacheSoundScript("k_lab.teleport_post_thunder")
	warp1.EmitSound("k_lab.teleport_post_thunder")
	
	warp1.SetModelScale(1.2,0.5)
	local warp2=SpawnEntityFromTable("prop_dynamic",{
		origin=pos.ToKVString(),
		model="models/effects/intro_vortshield.mdl",
		modelscale=0.1,
		disableshadows=1,
		rendermode=1,
		rendercolor="56 237 239",
		targetname="portal_warp"
	})
	warp2.SetModelScale(1.35,0.5)
	local warp3=SpawnEntityFromTable("prop_dynamic",{
		origin=pos.ToKVString(),
		model="models/effects/intro_vortshield.mdl",
		disableshadows=1,
		modelscale=0.1,
		rendermode=1,
		rendercolor="107 234 100",
		targetname="portal_warp"
	})
	warp3.SetModelScale(1.5,0.5)
	local light=SpawnEntityFromTable("light_dynamic",{
		origin=pos.ToKVString(),
		_cone=0,
		_inner_cone=0,
		_light="13 239 103 200",
		brightness=3,
		distance=10,
		style=1
	})
	for (local i=0;i<20;i++)
	EntFireByHandle(light,"distance",200*(i/20.0),i*0.03);

	for (local i=0;i<50;i++)
	{
		EntFireByHandle(warp1,"setmodelscale",1.2*(i/50.0),i*0.015);
		EntFireByHandle(warp2,"setmodelscale",1.35*(i/50.0),i*0.015);
		EntFireByHandle(warp3,"setmodelscale",1.5*(i/50.0),i*0.015);
	}
	local dustParticles = SpawnEntityFromTable("info_particle_system", {
		origin=pos.ToKVString(),
		targetname = "green_dust_particles",
		effect_name = "portal_dust", // Replace with a valid asset name from your game
		start_active = 1
	});
	dustParticles = SpawnEntityFromTable("info_particle_system", {
		origin=pos.ToKVString(),
		targetname = "green_dust_particles",
		effect_name = "portal_dust", // Replace with a valid asset name from your game
		start_active = 1
	});
}
local PortalOpenTime=0;

local sparklight = {
	_cone = 0,
	_inner_cone = 0,
	_light = "55 150 255 220",
	brightness = 1,
	distance = 180
	pitch = -90,
	//spawnflags = 1,
	style=0
}

local LastRubble=0;

NetMsg.Receive("OpenExitPortal",function(player) {
		PortalOpenTime=Time()
		
		local pos=AINetwork.GetNodePosition(best_center_index)+Vector(0,0,48)
		
		Entities.First().SetContextThink("OpenPortalShake",function(_)
		{
			ShakePlayerScreen(200,1.1,3,false,6)
			player.PrecacheSoundScript("outland_05.rubble5")
			player.EmitSound("outland_05.rubble5")
			return;
			
		},10.5)
		
		Entities.First().SetContextThink("OpenPortalSparks",function(_)
		{
			if (Time()-LastRubble>3.5)
			{
				LastRubble=Time()
				player.PrecacheSoundScript("outland_05.rubble5")
				player.EmitSound("outland_05.rubble5")
			}
			
			local ppos=pos+Vector(RandomInt(-16,16),RandomInt(-16,16),RandomInt(-16,16))
			
			ShakePlayerScreen(200,1.1,3,false,1)
			
			local BiggerSpark=(Time()-PortalOpenTime>13)
			
			Entities.First().PrecacheSoundScript("DoSpark")
			Entities.First().PrecacheSoundScript("LoudSpark")
			
			PrecacheParticleSystem("electrical_arc_01")
			PrecacheParticleSystem("blood_impact_synth_01_arc")
			
			
			DispatchParticleEffect(BiggerSpark ? "electrical_arc_01" : "blood_impact_synth_01_arc",ppos,Vector(),player)
			
			local Light = SpawnEntityFromTable("light_dynamic", sparklight)
			Light.SetOrigin(ppos)

			EntFireByHandle(Light,"kill","",0.25)
			
			local s3=EmitSound_t()
			s3.SetSoundName(BiggerSpark ? "LoudSpark" : "DoSpark")
			s3.SetVolume(1)
			s3.SetOrigin(ppos)
			EmitSoundParamsOn(s3,Entities.First())
			
			local intensity=clamp((Time()-PortalOpenTime-10)/5.0,0,1)
			
			if (Time()-PortalOpenTime>15) return;
			else return RandomFloat(0.5-0.4*intensity,1-0.8*intensity)
			
		},9)
		
		Entities.First().SetContextThink("OpenPortalSparks2",function(_)
		{
			local ppos=pos+Vector(RandomInt(-16,16),RandomInt(-16,16),RandomInt(-16,16))
			
			local BiggerSpark=(Time()-PortalOpenTime>13)
			
			ShakePlayerScreen(200,1.1,3,false,2)
			
			Entities.First().PrecacheSoundScript("DoSpark")
			Entities.First().PrecacheSoundScript("LoudSpark")
			
			PrecacheParticleSystem("electrical_arc_01")
			PrecacheParticleSystem("blood_impact_synth_01_arc")
			
			
			DispatchParticleEffect(BiggerSpark ? "electrical_arc_01" : "blood_impact_synth_01_arc",ppos,Vector(),player)
			
			local Light = SpawnEntityFromTable("light_dynamic", sparklight)
			Light.SetOrigin(ppos)

			EntFireByHandle(Light,"kill","",0.25)
			
			local s3=EmitSound_t()
			s3.SetSoundName(BiggerSpark ? "LoudSpark" : "DoSpark")
			s3.SetVolume(1)
			s3.SetOrigin(ppos)
			EmitSoundParamsOn(s3,Entities.First())
			
			local intensity=clamp((Time()-PortalOpenTime-10)/5.0,0,1)
			
			if (Time()-PortalOpenTime>15) return;
			else return RandomFloat(0.5-0.4*intensity,1-0.8*intensity)
			
		},12)
		
		
		Entities.First().SetContextThink("OpenPortal",function(_)
		{
			OpenPortal()
		}.bindenv(this),15)
		
}.bindenv(this))

NetMsg.Receive("OpenExitPortal2",function(player) {
		ShakePlayerScreen(200,1.1,3,false,6)
		player.PrecacheSoundScript("outland_05.rubble5")
		player.EmitSound("outland_05.rubble5")
		
}.bindenv(this))

local Spots=[]

Entities.First().SetContextThink("PortalSpawnSpots",function(_)
{
	
//while (ChosenNodes.len()>3) ChosenNodes.remove(RandomInt(0,ChosenNodes.len()-1))
	//printl("Final Score"+best_score)

	//debugoverlay.Text(Vector(best_centroid.x,best_centroid.y,0), "x", 2)
	
	foreach( i, Chosen in best_triangle_indices )
	{
		//debugoverlay.Text(AINetwork.GetNodePosition(Chosen)+Vector(0,0,48), "o", 35)
		debugoverlay.Line(AINetwork.GetNodePosition(Chosen)+Vector(0,0,16),AINetwork.GetNodePosition(Chosen)+Vector(0,0,1048), 25,255,25,true,112)
		
		local spawnPos = AINetwork.GetNodePosition(Chosen)+Vector(0,0,48); // Replace with your coordinates
		
		local dustParticles = SpawnEntityFromTable("info_particle_system", {
			origin = spawnPos,
			targetname = "green_dust_particles",
			effect_name = "portal_dust", // Replace with a valid asset name from your game
			start_active = 1
		});
		
		Spots.append(spawnPos)

	}
	
	//debugoverlay.Text(AINetwork.GetNodePosition(best_center_index)+Vector(0,0,48), "P", 5)
	
	debugoverlay.Line(AINetwork.GetNodePosition(best_center_index)+Vector(0,0,16),AINetwork.GetNodePosition(best_center_index)+Vector(0,0,1048), 25,135,255,true,112)
	
	local centerspot=AINetwork.GetNodePosition(best_center_index)+Vector(0,0,48)
	
	Spots.append(centerspot)
	
	return
}.bindenv(this),3)

::SW_ENABLE_EXIT<-function()
{
	for (local i=0;i<4;i++)
	{
		NetMsg.Start("PortalSpot")
		NetMsg.WriteByte(i)
		NetMsg.WriteVec3Coord(Vector(Spots[i].x,-Spots[i].y,Spots[i].z))
		NetMsg.Send(player,true)
	}
Entities.First().SetContextThink("Exit_Available",function(_){SWHint("Mission is over. Use your phone to open exit portal.")}.bindenv(this),20);
}