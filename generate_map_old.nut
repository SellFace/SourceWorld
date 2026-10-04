IncludeScript("base.nut")
local mapmaker = Entities.FindByName(null, "map_maker_angles");
local rooms = 0;
local room_info = { };
local seed = RandomInt(1,65537)
local rn = seed
local MAX_ROOM_SIZE = 8
local MAX_ROOMS = 18
local MAX_ROOM_DISTANCE = 1300
local MAX_CORRIDOR_LENGTH = 1400
local freed_edicts = 0
// 											TODO: PREVENT ROOMS FROM CONNECTING INTO EACH OTHER TO SOLVE THE ISSUE OF INACCESSIBLE AREAS
function RandInt(a=0 , b=0)
{
	local result = null
	rn = (75*rn+74)%65537
	result = (rn%(abs(a-b)+1))+a
	return result
}

function RandFloat(a=0 , b=0)
{
	local result = null
	rn = (75*rn+74)%65537
	result = (rn%(abs(a-b)+1))+a
	return result.tofloat()
}

function Precache()
{
	PrecacheModel("models/props/wall.mdl", true)
	PrecacheModel("models/props/wallx2.mdl", true)
	PrecacheModel("models/props/floor.mdl", true)
	PrecacheModel("models/props/floor2x1.mdl", true)
	PrecacheModel("models/props/floor4x1.mdl", true)
	PrecacheModel("models/props/floor2x1.mdl", true)
	PrecacheModel("models/props_c17/door01_left.mdl", true)
	PrecacheModel("models/props/floor3x3.mdl", true)
	PrecacheModel("models/props/doorway.mdl", true)
	
	for (local i=0;i<LIST_PROPS.len();i++)
	{
		PrecacheModel(LIST_PROPS[i].model, true)
	}
}

if (SERVER_DLL)
{
	function Generate()
	{
		printl("Seed: "+seed)
		function Place(room_id, name, pos, orientation = "", type=0)
		{
			local offset=null
			local angles=0
			local prop=name
			name=name+orientation;
			switch(name)
			{
				case "floor": 
					offset=Vector(64,64,0); break;
				case "floor2x1": 
					offset=Vector(0,0,0); angles=90; break;
				case "floor4x1": 
					offset=Vector(0,0,0); angles=90; break;
				case "floor2x2": 
					offset=Vector(0,0,0); angles=0; break;
				case "floor3x3": 
					offset=Vector(0,0,0); angles=0; break;
				case "floor1x2": 
					offset=Vector(0,0,0); angles=0; prop="floor2x1"; break;
				case "floor1x4": 
					offset=Vector(0,0,0); angles=0; prop="floor4x1"; break;
				case "wallW": 
					offset=Vector(4,64,16); angles=270; break;
				case "wallE": 
					offset=Vector(124,64,16); 
					angles=90; break;
				case "wallN": 
					offset=Vector(64,124,16); 
					angles=180; break;
				case "wallS": 
					offset=Vector(64,4,16); angles=0; break;
				case "wallx2W": 
					offset=Vector(0,64,16); angles=270; break;
				case "wallx2E": 
					offset=Vector(0,-64,16); 
					angles=90; break;
				case "wallx2N": 
					offset=Vector(64,0,16); 
					angles=180; break;
				case "wallx2S": 
					offset=Vector(-64,0,16); angles=0; break;
				default:
					offset=Vector(64,64,16); break;
			}
			pos=pos+offset
			local S = {
			IDENTIFIER = "floor",
			solid = 6,
			angles = "0 "+angles+" 0",
			targetname = room_id+"_"+name,
			model = "models/props/"+prop+".mdl",
			origin = pos.x+" "+pos.y+" "+pos.z,
			skin=type,
			}
			
			SpawnEntityFromTable("prop_dynamic",S);
		}
		
		function PlaceModel(name, pos, angles = 0,lightskin=1)
		{
			local solidity=0
			if (pos.z<130) {solidity=6}
			local S = {
			IDENTIFIER = "model",
			angles = "0 "+angles+" 0",
			model = name,
			origin = pos.x+" "+pos.y+" "+pos.z,
			skin = lightskin
			solid=solidity
			}
			
			SpawnEntityFromTable("prop_dynamic",S);
		}
		
		function PlaceEntity(name, pos = Vector(0,0,0), angles = 0)
		{
			local flags = 0
			local sleepstate = 0
			local wakeradius = 0
			local vscripts = ""
			if (ThisHas(name,"npc")) { flags = 3, sleepstate = 3, wakeradius = 1000, vscripts = "enemies/npc_zombie.nut" }
			local S = {
			IDENTIFIER = "some_ent",
			angles = "0 "+angles+" 0",
			origin = pos.x+" "+pos.y+" "+pos.z,
			SetForceServerRagdoll = 1,
			spawnflags = flags,
			sleepstate = sleepstate,
			vscripts = vscripts,
			wakeradius = wakeradius
			}
			
			SpawnEntityFromTable(name,S);
		}

		function PlaceProp(name, pos = Vector(0,0,0), angles = 0)
		{
			local prop={ }
			local solidity=6
			local pitch=0
			for (local i=0;i<LIST_PROPS.len();i++)
			{
				if (LIST_PROPS[i].model==name) { prop = LIST_PROPS[i] }
			}
			if ("angle_offset" in prop) { angles+=prop.angle_offset }
			if ("force_solid" in prop) { solidity=2 }
			if ("no_collisions" in prop) { solidity=0 }
			if ("vertical" in prop) { pitch=90 }
			local S = {
			IDENTIFIER = "some_prop",
			angles = pitch+" "+angles+" 0",
			origin = pos.x+" "+pos.y+" "+pos.z,
			model = name,
			rendermode = 0,
			solid = solidity,
			skin = RandInt(0,prop.max_skin),
			rendercolor = (245+RandInt(0,10))+" "+(245+RandInt(0,10))+" "+(245+RandInt(0,10))
			}
			if ("static_only" in prop) { SpawnEntityFromTable("prop_dynamic",S); return}
			SpawnEntityFromTable("prop_physics",S);
		}
		
		function PlaceLight(room_id, name, pos, angles=RandInt(0,3)*90, distancemod=1)
		{
			local light={ }
			for (local i=0;i<LIST_LIGHTS.len();i++)
			{
				if (LIST_LIGHTS[i].model==name) { light = LIST_LIGHTS[i] }
			}
			local model_offset=RotateVectorByAngle(light.model_offset,angles)
			pos=pos+light.offset
			local lightstyle=0
			local lightwide=Vector(0,0,0)
			if ("wide" in light) {lightwide=RotateVectorByAngle(Vector(0,light.wide,0),angles)}
			if (CheckForEntity(pos+model_offset*0.95+lightwide,pos+model_offset*0.8-lightwide)!=null) { return }
			if (Entities.FindByNameWithin(null,"*door*",pos,20)) { return }
			if (RandInt(0,100)<=light.flickering_chance) {lightstyle=1}
			local S = {
			IDENTIFIER = "dynlight",
			angles = "0 "+angles+" 0",
			targetname = room_id+"_dlight",
			origin = pos.x+" "+pos.y+" "+pos.z,
			_cone = 0,
			_inner_cone = 0,
			_light = (light.color.x+RandInt(0,light.color_deviation))+" "+(light.color.y+RandInt(0,light.color_deviation))+" "+(light.color.z+RandInt(0,light.color_deviation))+" 200",
			brightness = light.base_brightness,
			distance = light.base_distance/distancemod
			pitch = -90,
			spawnflags = 1,
			style = 0
			}
			SpawnEntityFromTable("light_dynamic",S);
			pos.z=144
			PlaceModel(light.model, pos+model_offset, angles, light.skin)
		}
		
		function PlaceDelay(parameters)
		{
			local room_id=null
			local name=null
			local ipos=null
			local pos=null
			local type=0
			local orientation=""
			room_id=split(parameters,"Q")[0]
			name=split(parameters,"Q")[1]
			ipos=split(parameters,"Q")[2]
			pos=Vector(split(ipos," ")[0].tointeger(),split(ipos," ")[1].tointeger(),split(ipos," ")[2].tointeger())
			type=split(parameters,"Q")[3]
			if (split(parameters,"Q").len()==5) { orientation=split(parameters,"Q")[4] }
			
			local offset=null
			local angles=0
			local prop=name
			name=name+orientation;
			switch(name)
			{
				case "floor": 
					offset=Vector(64,64,0); break;
				case "wallW": 
					offset=Vector(4,64,16); angles=270; break;
				case "wallE": 
					offset=Vector(124,64,16); 
					angles=90; break;
				case "wallN": 
					offset=Vector(64,124,16); 
					angles=180; break;
				case "wallS": 
					offset=Vector(64,4,16); angles=0; break;
			}
			pos=pos+offset
			local S = {
			IDENTIFIER = "floor",
			solid = 6,
			angles = "0 "+angles+" 0",
			targetname = room_id+"_"+name,
			model = "models/props/"+prop+".mdl",
			origin = pos.x+" "+pos.y+" "+pos.z,
			skin=type
			}
			
			SpawnEntityFromTable("prop_dynamic",S);
			function PlaceHallwayLight(pos,room_id)
			{
				if (Entities.FindByClassnameWithin(null,"light_dynamic",pos+Vector(64,64,0),260)==null)
				{
					local rand_id=RandInt(0,LIST_LIGHTS.len()-1)
					local rand_angle=RandInt(0,3)*90
					local light_pos=pos+Vector(-64,-64,0)
					local wall_test_vector=pos+Vector(0,0,95)-RotateVectorByAngle(Vector(56,0,0),rand_angle)
					if (LIST_LIGHTS[rand_id].requires_wall==true)
					{
						light_pos=light_pos+Vector(0,0,16)-RotateVectorByAngle(Vector(32,0,0),rand_angle)
					}
					while (LIST_LIGHTS[rand_id].requires_wall==true&&TraceHull(wall_test_vector,wall_test_vector+Vector(1,1,5)).DidHit()==false)
					{
						if (rand_angle>360)
						{
							while(LIST_LIGHTS[rand_id].requires_wall==true) { rand_id=RandInt(0,LIST_LIGHTS.len()-1) }
							light_pos=pos+Vector(-64,-64,0)+Vector(0,0,16)
							break
						}
						rand_angle+=90
						light_pos=pos+Vector(-64,-64,0)-RotateVectorByAngle(Vector(32,0,0),rand_angle)
						wall_test_vector=pos+Vector(0,0,95)-RotateVectorByAngle(Vector(56,0,0),rand_angle)
					}
					//PlaceWeakLight(room_id,LIST_LIGHTS[rand_id].model, light_pos,rand_angle,0)
					PlaceLight(room_id,LIST_LIGHTS[rand_id].model, light_pos,rand_angle,1.2)
				}
				return -1
			}
			if (name.find("f")!=null) 
			{
				self.SetContextThink("PlaceHallwayLights"+room_id+pos.x+pos.y,function(_) { PlaceHallwayLight(pos,room_id) }.bindenv(this),4)
			}
		}
		
		local x = RandInt(-16,16)*128
		local y = RandInt(-16,16)*128
		
		function CheckForEntity(vec1, vec2)
		{
			if  (TraceLineComplex(vec1,vec2,self,33570819,0).DidHit()==true) { return TraceLineComplex(vec1,vec2,self,33570819,0).Entity() }
			return null
		}
		
		function GenerateRoom(size_x, size_y, type=0)
		{	
			if (rooms>0)
			{
				x = room_info[rooms+"_StartX"]+RandInt(-15,15)*128
				y = room_info[rooms+"_StartY"]+RandInt(-15,15)*128
			}
			while ((x<(0-2200)) || (x>2200)) { x = room_info[rooms+"_StartX"]+RandInt(-15,15)*128 }
			while ((y<(0-2200)) || (y>2200)) { y = room_info[rooms+"_StartY"]+RandInt(-15,15)*128 }
			local end_x = x+size_x*128
			local end_y = y+size_y*128
			local doorplaced = 0
			local room_id = rooms+1
			if (rooms>0)
			{
				if ((Vector(room_info[rooms+"_StartX"], room_info[rooms+"_StartY"],64)-Vector(x, y,64)).Length()>MAX_ROOM_DISTANCE)
				{
						debugoverlay.Sphere(Vector(x,y,64),MAX_ROOM_DISTANCE,200,0,0,false,1)
						printcl(235, 235, 10, "Tried to generate a room too far, trying again...")
						debugoverlay.Box(Vector(x,y,0), Vector(0,0,0),Vector(128*size_x,128*size_y,160),255,10,10,200,0.25)
						GenerateRoom(size_x, size_y, type)
						return
				}
			}
			
			for (local i=0 ; i < size_x ; i++)
			{
				if (TraceLineComplex(Vector((x+(128*i))+64, y+64, 10),Vector((x+(128*i))+64, end_y-64, 10), self,33570819,0).DidHit()==true)
				{
					GenerateRoom(size_x, size_y, type)
					debugoverlay.Line(Vector((x+(128*i))+64, y+64, 20),Vector((x+(128*i))+64, end_y-64, 20),255,12,12,false,1.0)
					printcl(235, 235, 10, "Tried to generate an overlapping room, trying again...")
					debugoverlay.Box(Vector(x,y,0), Vector(0,0,0),Vector(128*size_x,128*size_y,160),255,10,10,200,0.25)
					return
				}
				debugoverlay.Line(Vector((x+(128*i))+64, y+64, 20),Vector((x+(128*i))+64, end_y-64, 20),12,252,12,false,1.0)
			}
			debugoverlay.Box(Vector(x,y,0), Vector(0,0,0),Vector(128*size_x,128*size_y,160),10,155,10,30,0.35)
			
			room_info[room_id+"_StartX"] <- x;
			room_info[room_id+"_StartY"] <- y;
			room_info[room_id+"_EndX"] <- end_x;
			room_info[room_id+"_EndY"] <- end_y;
			room_info[room_id+"_Entrances"] <- 0;
			room_info[room_id+"_Type"] <- type;
			for (local ix = 0 ; ix < size_x ; ix++) 
			{
				for (local iy = 0 ; iy < size_y ; iy++) 
				{
					if (ix==0 && doorplaced!=1) { Place(room_id, "wall", Vector(x,y,0), "W",type) }
					if (iy==0 && doorplaced!=2) { Place(room_id, "wall", Vector(x,y,0), "S",type) }
					if (iy==size_y-1 && doorplaced!=3) { Place(room_id, "wall", Vector(x,y,0), "N",type) }
					if (ix==size_x-1 && doorplaced!=4) { Place(room_id, "wall", Vector(x,y,0), "E",type) }
					Place(room_id, "floor", Vector(x,y,0),"", type)
					y=y+128;
					if (doorplaced !=0) { doorplaced = 5; }
				}
				y=end_y-size_y*128
				x=x+128;
			}
			printl("Room ID: "+room_id+" Room size: "+size_x+" by "+size_y+" Type: "+type)
			rooms++
			local ent=null
			local ent_count=0
			local lastid=0
			while( ent = Entities.FindByName(ent, "*") )
			{
			   ent_count++
			   lastid=ent.entindex()
			}
			printcl(255,255-pow(ent_count,2)/15700,255-pow(ent_count,2)/15700, "Total ents: "+ent_count+". Last index is "+lastid+".")
			OptimiseFloors()
			PrintFreedEdicts()
		}
		
		function PrintEntrances()
		{
			foreach (k,v in room_info) {
					if(k.find("_")!=null)
					{
						printl(k+": "+v)
					}
			}
		}
		function OptimiseFloors()
		{
			local ent2=null
				
				while( ent2 = Entities.FindByName(ent2, "*floo*") )					//replacing 3x3 floors makes lighting look bad cuz we cant have more than 4 lights hitting same prop
				{
					
					if (((CheckForTile(ent2, 10, "E", true, false))&&(CheckForTile(ent2, 10, "N", true, false)))&&(CheckForTile(ent2, 10, "NE", true, false)))
					{
						if ((CheckForTile(ent2, 10, "E2", true, false))&&(CheckForTile(ent2, 10, "N2", true, false))&&(CheckForTile(ent2, 10, "E2N", true, false))&&(CheckForTile(ent2, 10, "N2E", true, false))&&(CheckForTile(ent2, 10, "NE2", true, false)))
						{
							printl(CheckForTile(ent2, 10, "NE2", true, false))
							FindTileNextTo(ent2,10,"E").Destroy()
							FindTileNextTo(ent2,10,"N").Destroy()
							FindTileNextTo(ent2,10,"NE").Destroy()
							FindTileNextTo(ent2,10,"E2").Destroy()
							FindTileNextTo(ent2,10,"N2").Destroy()
							FindTileNextTo(ent2,10,"E2N").Destroy()
							FindTileNextTo(ent2,10,"N2E").Destroy()
							FindTileNextTo(ent2,10,"NE2").Destroy()
							Place(ent2.GetName().slice(0,ent2.GetName().find("_")), "floor3x3", Vector(ent2.GetOrigin().x+128,ent2.GetOrigin().y+128,0),"", ent2.GetSkin())
							ent2.Destroy()
							AddFreedEdicts(8)
						}
					}				
				}
				
				while( ent2 = Entities.FindByName(ent2, "*floo*") )
				{
					
					if (((CheckForTile(ent2, 10, "E", true, false))&&(CheckForTile(ent2, 10, "N", true, false)))&&(CheckForTile(ent2, 10, "NE", true, false)))
					{
						FindTileNextTo(ent2,10,"E").Destroy()
						FindTileNextTo(ent2,10,"N").Destroy()
						FindTileNextTo(ent2,10,"NE").Destroy()
						Place(ent2.GetName().slice(0,ent2.GetName().find("_")), "floor2x2", Vector(ent2.GetOrigin().x+64,ent2.GetOrigin().y+64,0),"", ent2.GetSkin())
						ent2.Destroy()
						AddFreedEdicts(3)
					}				
				}
				while( ent2 = Entities.FindByName(ent2, "*floo*") )
				{
					
					if ((CheckForTile(ent2, 10, "E", true, false))&&(CheckForTile(ent2, 10, "E2", true, false))&&(CheckForTile(ent2, 10, "E3", true, false)))
					{
						FindTileNextTo(ent2,10,"E").Destroy()
						FindTileNextTo(ent2,10,"E2").Destroy()
						FindTileNextTo(ent2,10,"E3").Destroy()
						Place(ent2.GetName().slice(0,ent2.GetName().find("_")), "floor4x1", Vector(ent2.GetOrigin().x+192,ent2.GetOrigin().y,0),"", ent2.GetSkin())
						ent2.Destroy()
						AddFreedEdicts(3)
					}				
				}
				while( ent2 = Entities.FindByName(ent2, "*floo*") )
				{
					if ((CheckForTile(ent2, 10, "N", true, false))&&(CheckForTile(ent2, 10, "N2", true, false))&&(CheckForTile(ent2, 10, "N3", true, false)))
					{
						FindTileNextTo(ent2,10,"N").Destroy()
						FindTileNextTo(ent2,10,"N2").Destroy()
						FindTileNextTo(ent2,10,"N3").Destroy()
						Place(ent2.GetName().slice(0,ent2.GetName().find("_")), "floor1x4", Vector(ent2.GetOrigin().x,ent2.GetOrigin().y+192,0),"", ent2.GetSkin())
						ent2.Destroy()
						AddFreedEdicts(3)
					}
				}
				while( ent2 = Entities.FindByName(ent2, "*floo*") )
				{
					
					if (CheckForTile(ent2, 10, "E", true, false))
					{
						FindTileNextTo(ent2,10,"E").Destroy()
						Place(ent2.GetName().slice(0,ent2.GetName().find("_")), "floor2x1", Vector(ent2.GetOrigin().x+64,ent2.GetOrigin().y,0),"", ent2.GetSkin())
						ent2.Destroy()
						AddFreedEdicts(1)
					}				
				}
				while( ent2 = Entities.FindByName(ent2, "*floo*") )
				{
					if (CheckForTile(ent2, 10, "N", true, false))
					{
						FindTileNextTo(ent2,10,"N").Destroy()
						Place(ent2.GetName().slice(0,ent2.GetName().find("_")), "floor1x2", Vector(ent2.GetOrigin().x,ent2.GetOrigin().y+64,0),"", ent2.GetSkin())
						ent2.Destroy()
						AddFreedEdicts(1)
					}
				}
		}
		function OptimiseWalls()
		{
			local ent2=null
				while( ent2 = Entities.FindByName(ent2, "*wal*") )
				{
					local wallangle="W"
					switch (ent2.GetAngles().y)
					{
						case 270:
							wallangle="W"; break;
						case 0:
							wallangle="S"; break;
						case 90:
							wallangle="E"; break;
						case 180:
							wallangle="N"; break;
					}
					if (FindWallNextTo(ent2,50,wallangle)!=null)
					{
						FindWallNextTo(ent2,50,wallangle).Destroy()
						Place(ent2.GetName().slice(0,ent2.GetName().find("_")), "wallx2", Vector(ent2.GetOrigin().x,ent2.GetOrigin().y,0),wallangle, ent2.GetSkin())
						ent2.Destroy()
						AddFreedEdicts(1)
					}				
				}
		}
		function RemoveBadDoors()
		{
			local ent2=null
			local count=0
				while( ent2 = Entities.FindByName(ent2, "*doorwa*") )
				{
					if (ent2.GetClassname()=="info_target"&&Entities.FindByClassnameWithin(null,"prop_door_rotating",ent2.GetOrigin(),30)) { Entities.FindByClassnameWithin(null,"prop_door_rotating",ent2.GetOrigin(),30).Destroy();count++;continue }
					if (ent2.GetClassname()=="info_target") { continue }
					if ((!(CheckForCloseCollisions(ent2, -10, "N", true, false)))||(!(CheckForCloseCollisions(ent2, -10, "S", true, false)))||(!(CheckForCloseCollisions(ent2, -10, "W", true, false)))||(!(CheckForCloseCollisions(ent2, -10, "E", true, false))))
					{
						count++
						ForceReplace(ent2,"wall", false)
						Entities.FindByClassnameWithin(null,"prop_door_rotating",ent2.GetOrigin()+Vector(0,0,54),30).Destroy()
						ent2.Destroy()
					}				
				}
			if (count>0) { printl("Fixing "+count+" bad doors...") }
		}
		local total_freed_edicts = 0
		function AddFreedEdicts(value)
		{
			freed_edicts+=value
			total_freed_edicts+=value
		}
		function PrintFreedEdicts()
		{
			printcl(100,255,100,"Room optimisation freed "+freed_edicts+" edicts!")
			freed_edicts=0
		}
		function PrintFreedEdicts2()
		{
			local ent=null
			local ent_count=1
			local lastid=0
			while( ent = Entities.FindByName(ent, "*") )
			{
			   ent_count++
			   lastid=ent.entindex()
			}
			printcl(100,255,100,"Hallway optimisation freed "+freed_edicts+" edicts!")
			printcl(40,255,40,"Total freed edicts: "+total_freed_edicts+". That's "+(((total_freed_edicts.tofloat())/(ent_count.tofloat()+total_freed_edicts.tofloat()))*100).tointeger()+"% less entities than without optimising.")
			freed_edicts=0
		}
			
		function PlaceHalls()
		{
			local ent=null
			while( ent = Entities.FindByName(ent, "*-*floo*") )
			{
				//ent.SetRenderColor(197,157,157)
				//printl(ent.GetName())
				if ((CheckForTile(ent,10,"N")==false) || (CheckForTile(ent,45,"N")==true))
				{
					local temp_x = ent.GetOrigin().x-64
					local temp_y = ent.GetOrigin().y-64
					local hall_id = ent.GetName().slice(0,ent.GetName().find("f")-1)
					EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+hall_id+"+''Q''+''wall''+''Q''+"+temp_x+"+'' ''+"+temp_y+"+'' 0Q''+2+''QN'')",RandFloat(0,0.97))
					//printl(ent.GetName()+ent.GetCenter())
					////debugoverlay.Line(ent.GetCenter()+Vector(0,67,2), ent.GetCenter()+Vector(0,0,2),12,252,252,false,3)
					////debugoverlay.Line(ent.GetCenter(), self.GetCenter(),12,252,122,false,3)
				}
			}
			EntFireByHandle(self,"RunScriptCode","OptimiseWalls()",1.05)
		}
		function PlaceHalls2()
		{
			local ent=null
			while( ent = Entities.FindByName(ent, "*-*floo*") )
			{
				//ent.SetRenderColor(197,157,157)
				//printl(ent.GetName())
				if ((CheckForTile(ent,10,"S")==false) || (CheckForTile(ent,45,"S")==true))
				{
					local temp_x = ent.GetOrigin().x-64
					local temp_y = ent.GetOrigin().y-64
					local hall_id = ent.GetName().slice(0,ent.GetName().find("f")-1)
					EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+hall_id+"+''Q''+''wall''+''Q''+"+temp_x+"+'' ''+"+temp_y+"+'' 0Q''+2+''QS'')",RandFloat(0,0.97))
					//printl(ent.GetName()+ent.GetCenter())
					////debugoverlay.Line(ent.GetCenter()+Vector(0,67,2), ent.GetCenter()+Vector(0,0,2),12,252,252,false,3)
					////debugoverlay.Line(ent.GetCenter(), self.GetCenter(),12,252,122,false,3)
				}
			}
			EntFireByHandle(self,"RunScriptCode","OptimiseWalls()",1.05)
		}
		function PlaceHalls3()
		{
			local ent=null
			while( ent = Entities.FindByName(ent, "*-*floo*") )
			{
				//ent.SetRenderColor(197,157,157)
				//printl(ent.GetName())
				if ((CheckForTile(ent,10,"E")==false) || (CheckForTile(ent,45,"E")==true))
				{
					local temp_x = ent.GetOrigin().x-64
					local temp_y = ent.GetOrigin().y-64
					local hall_id = ent.GetName().slice(0,ent.GetName().find("f")-1)
					EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+hall_id+"+''Q''+''wall''+''Q''+"+temp_x+"+'' ''+"+temp_y+"+'' 0Q''+2+''QE'')",RandFloat(0,0.97))
					//printl(ent.GetName()+ent.GetCenter())
					////debugoverlay.Line(ent.GetCenter()+Vector(0,67,2), ent.GetCenter()+Vector(0,0,2),12,252,252,false,3)
					////debugoverlay.Line(ent.GetCenter(), self.GetCenter(),12,252,122,false,3)
				}
			}
			EntFireByHandle(self,"RunScriptCode","OptimiseWalls()",1.05)
		}
		function PlaceHalls4()
		{
			local ent=null
			while( ent = Entities.FindByName(ent, "*-*floo*") )
			{
				//ent.SetRenderColor(197,157,157)
				//printl(ent.GetName())
				if ((CheckForTile(ent,10,"W")==false) || (CheckForTile(ent,45,"W")==true))
				{
					local temp_x = ent.GetOrigin().x-64
					local temp_y = ent.GetOrigin().y-64
					local hall_id = ent.GetName().slice(0,ent.GetName().find("f")-1)
					EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+hall_id+"+''Q''+''wall''+''Q''+"+temp_x+"+'' ''+"+temp_y+"+'' 0Q''+2+''QW'')",RandFloat(0,0.97))
					//printl(ent.GetName()+ent.GetCenter())
					////debugoverlay.Line(ent.GetCenter()+Vector(0,67,2), ent.GetCenter()+Vector(0,0,2),12,252,252,false,3)
					////debugoverlay.Line(ent.GetCenter(), self.GetCenter(),12,252,122,false,3)
				}
			}
			EntFireByHandle(self,"RunScriptCode","OptimiseWalls()",1.05)
		}

		function DidItHit(vec1, vec2)
		{
			if ((vec2-vec1).Length()<130) { return false }
			vec1.z=20
			vec2.z=20
			////debugoverlay.Line(vec1, vec2,255,252,12,false,33)
			return TraceLineComplex(vec1,vec2,self,33570819,0).DidHit()		
		}
		function DidItHit2(vec1, vec2)
		{
			if ((vec2-vec1).Length()<130) { return false }
			//debugoverlay.Line(vec1, vec2,255,252,12,false,33)
			return TraceLineComplex(vec1,vec2,self,33570819,0).DidHit()		
		}
		local corridor=0
		local Connections=null
		function GenerateCorridors()
		{
			local life = 1
			//SendToConsole("play common/wpn_moveselect.wav");
			if (Connections==null)
			{
				Connections = array(rooms)
			}
			room_info[1+"_Entrances"] <- 0;
			function HallPossible(a, b)
			{
				local first = a
				local second = b
				
				local first_height=(room_info[first+"_EndY"]-room_info[first+"_StartY"])/128
				local first_width=(room_info[first+"_EndX"]-room_info[first+"_StartX"])/128
				local second_height=(room_info[second+"_EndY"]-room_info[second+"_StartY"])/128
				local second_width=(room_info[second+"_EndX"]-room_info[second+"_StartX"])/128
				
				local first_x=room_info[first+"_StartX"]
				local first_endx=room_info[first+"_EndX"]
				local second_x=room_info[second+"_StartX"]
				local second_endx=room_info[second+"_EndX"]
				
				local first_y=room_info[first+"_StartY"]
				local first_endy=room_info[first+"_EndY"]
				local second_y=room_info[second+"_StartY"]
				local second_endy=room_info[second+"_EndY"]
			
				local h = RandInt(0, first_height-1)
				local w = RandInt(0, second_width-1)
				
				for (local i=0; i<first_height; i++)
				{
					h=i
					for (local i2=0; i2<second_width; i2++)
					{
						w=i2
						if ((first_x<second_endx)&&(first_endx>second_x))
						{
							second_width=first_width
							w=w*128+first_x+64
							h=h*128+first_y+64
							if (first_y<second_y)
							{
								//printl("bumper cars lower")
								local crashsafe=0
								if (DidItHit(Vector(w,first_endy+5,2), Vector(w,second_y-5,2))==true) { continue }
								if (((!((w<second_endx)&&(w>second_x))) && (crashsafe<140)))
								{
									continue
								}
								//debugoverlay.Line(Vector(w,first_endy-64,20), Vector(w,second_y+64,20),12,252,12,false,life)
								local start = Vector(w,first_endy-64,1)
								local hall_vector = Vector(0,second_y-first_endy,0)
							}
							if (first_y>second_y)
							{
								//printl("bumper cars higher")
								local crashsafe=0
								if (DidItHit(Vector(w,first_y-5,2), Vector(w,second_endy+5,2))==true) { continue }
								if (((!((w<second_endx)&&(w>second_x))) && (crashsafe<140)))
								{
									continue
								}
								//debugoverlay.Line(Vector(w,first_y+64,20), Vector(w,second_endy-64,20),12,252,12,false,life)

								local start = Vector(w,first_y+64,1)
								local hall_vector = Vector(0,second_endy-first_y,0)
							}
							//printl("overlap width")
							return true
						}
						if ((first_y<second_endy)&&(first_endy>second_y))
						{
							w=w*128+first_x+64
							h=h*128+first_y+64
							if (first_x<second_x)
							{
								//printl("bumper cars left")
								local crashsafe=0
								if (DidItHit(Vector(first_endx+5,h,2), Vector(second_x-5,h,2))==true) { continue }
								if (((!((h<second_endy)&&(h>second_y))) && (crashsafe<140)))
								{
									break
								}
								//debugoverlay.Line(Vector(first_endx-64,h,20), Vector(second_x+64,h,20),12,252,12,false,life)

								local start = Vector(first_endx-64,h,1)
								local hall_vector = Vector(second_x-first_endx,0,0)
							}
							if (first_x>second_x)
							{
								//printl("bumper cars right")
								local crashsafe=0
								if (DidItHit(Vector(first_x-5,h,2), Vector(second_endx+5,h,2))==true) { continue }
								if (((!((h<second_endy)&&(h>second_y))) && (crashsafe<140)))
								{
									break
								}
								//debugoverlay.Line(Vector(first_x+64,h,20), Vector(second_endx-64,h,20),12,252,12,false,life)
								
								local start = Vector(first_x+64,h,1)
								local hall_vector = Vector(second_endx-first_x,0,0)
							}
							//printl("overlap height")
							return true
						}
						
						local corridor_point1 = null
						if (first_x<second_x)
						{
							//printl("Firing first ray to right")
							if (DidItHit(Vector(first_endx+5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2))==true) { continue }
							//debugoverlay.Line(Vector(first_endx-64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),12,252,12,false,life)
							corridor_point1 = Vector(second_x+w*128+64, first_y+(128*h)+64,20)
							
							local start = Vector(first_endx-64, first_y+(128*h)+64,1)
							local hall_vector = Vector(second_x+w*128-first_endx,0,0)
						}
						if (first_x>second_x)
						{
							if (DidItHit(Vector(first_x-5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2))==true) { continue }
							//debugoverlay.Line(Vector(first_x+64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),12,252,12,false,life)
							corridor_point1 = Vector(second_x+w*128+64, first_y+(128*h)+64,20)
							
							local start = Vector(first_x+64, first_y+(128*h)+64,1)
							local hall_vector = Vector(corridor_point1.x-first_x+64,0,0)
						}
							
						if (first_y<second_y)
						{
							//printl("Firing second ray up")
							if (DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_y-5, 2))==true) { continue }
							//debugoverlay.Line(corridor_point1, Vector(corridor_point1.x, second_y+64, 20),12,252,12,false,life)
							corridor_point1.z=1
							local start = corridor_point1
							local hall_vector = Vector(0,second_y+64-corridor_point1.y,0)
						}
						if (first_y>second_y)
						{
						//printl("Firing second ray down")
						if (DidItHit2(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_endy+5, 2))==true) { continue }
						//debugoverlay.Line(corridor_point1+Vector(0,0,-21), Vector(corridor_point1.x, second_endy-64, 2),12,252,12,false,life)
						corridor_point1.z=1
						local start = corridor_point1
						local hall_vector = Vector(0,second_y+64-corridor_point1.y,0)
						}
						return true
					}
				}
				return false
			}

			
			for (local i = 2+corridor; i <= 2+corridor; i++)
			{
				if (rooms==2) { break }
				local destination = RandInt(1,i-1)
				//printl("GONNA TRY "+i+" AND "+destination)
				if (i==2) { destination=1 }
				local crashsave = 0
				local distance = (Vector(room_info[destination+"_StartX"],room_info[destination+"_StartY"],0)-Vector(room_info[i+"_StartX"],room_info[i+"_StartY"],0)).Length()
				//printl("Trying to connect room "+i+" and "+destination) 
				while ( ((i==destination) || (room_info[destination+"_Entrances"]>3)) || ((distance>MAX_CORRIDOR_LENGTH ) || (HallPossible(i, destination)==false)) )
				{ 
					if (room_info[destination+"_Entrances"]>3) { printl("Room "+destination+" is about to get its "+(room_info[destination+"_Entrances"]+1)+"rd entrance! Trying another one.") }
					if (distance>MAX_CORRIDOR_LENGTH) { printl("Rooms "+i+" and "+destination+" are too far away from each other to connect! Trying another one.") }
					destination = RandInt(1,i-1); 
					distance = (Vector(room_info[destination+"_StartX"],room_info[destination+"_StartY"],0)-Vector(room_info[i+"_StartX"],room_info[i+"_StartY"],0)).Length()
					crashsave++
					if (crashsave>100) { destination = RandInt(1,rooms);  }
					if (crashsave>800) { printl("oh shit"); break }
				}
				//Connections.append(destination) Connections.find(i-1)
				Connections[i-1]=destination
				room_info[i+"_Entrances"]++
				room_info[destination+"_Entrances"]++
			}
			
			for (local i = 1+corridor; i <= 1+corridor; i++)
			{
				if (rooms==2) { break }
				local first = i+1
				local second = Connections[i]
				
				local first_height=(room_info[first+"_EndY"]-room_info[first+"_StartY"])/128
				local first_width=(room_info[first+"_EndX"]-room_info[first+"_StartX"])/128
				local second_height=(room_info[second+"_EndY"]-room_info[second+"_StartY"])/128
				local second_width=(room_info[second+"_EndX"]-room_info[second+"_StartX"])/128
				
				local first_x=room_info[first+"_StartX"]
				local first_endx=room_info[first+"_EndX"]
				local second_x=room_info[second+"_StartX"]
				local second_endx=room_info[second+"_EndX"]
				
				local first_y=room_info[first+"_StartY"]
				local first_endy=room_info[first+"_EndY"]
				local second_y=room_info[second+"_StartY"]
				local second_endy=room_info[second+"_EndY"]
				
				printl("Connected rooms "+first+" and "+second)
				
				//GENERATION FOR OVERLAPPING ROOMS BY 1 LINE

				if ((first_x<second_endx)&&(first_endx>second_x))
				{
					if (first_y<second_y)
					{
						local w = RandInt(0, first_width-1)*128+first_x+64
						//printl("bumper cars lower")
						local crashsafe=0
						while (((!((w<second_endx)&&(w>second_x))) && (crashsafe<140)) || (DidItHit(Vector(w,first_endy+5,2), Vector(w,second_y-5,2))))
						{
							w = RandInt(0, first_width-1)*128+first_x+64
							crashsafe++
							//if (crashsafe>39) { break; printl("OOOOHH MA GAAWD1") }
						}
						debugoverlay.Line(Vector(w,first_endy-64,20), Vector(w,second_y+64,20),12,252,12,false,life)
						
						KillWalls(Vector(w,first_endy-64,20), Vector(w,second_y+64,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						local start = Vector(w,first_endy-64,1)
						local hall_vector = Vector(0,second_y-first_endy,0)
						for (local t = 0 ; t<=(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
						//printl(TraceLineComplex(Vector(w,first_endy-64,10), Vector(w,second_y+64,10),self,33570819,0).FractionLeftSolid())
					}
					if (first_y>second_y)
					{
						local w = RandInt(0, first_width-1)*128+first_x+64
						//printl("bumper cars higher")
						local crashsafe=0
						while (((!((w<second_endx)&&(w>second_x))) && (crashsafe<140)) || (DidItHit(Vector(w,first_y-5,2), Vector(w,second_endy+5,2))))
						{
							w = RandInt(0, first_width-1)*128+first_x+64
							crashsafe++
							//if (crashsafe>39) { break; printl("OOOOHH MA GAAWD2") }
						}
						debugoverlay.Line(Vector(w,first_y+64,20), Vector(w,second_endy-64,20),12,252,12,false,life)
						
						KillWalls(Vector(w,first_y+64,20), Vector(w,second_endy-64,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						local start = Vector(w,first_y+64,1)
						local hall_vector = Vector(0,second_endy-first_y,0)
						for (local t = 0 ; t<=(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
					}
					//printl("overlap width")
					continue
				}
				if ((first_y<second_endy)&&(first_endy>second_y))
				{
					if (first_x<second_x)
					{
						local h = RandInt(0, first_height-1)*128+first_y+64
						//printl("bumper cars left")
						local crashsafe=0
						while (((!((h<second_endy)&&(h>second_y))) && (crashsafe<140)) || (DidItHit(Vector(first_endx+5,h,2), Vector(second_x-5,h,2))))
						{
							h = RandInt(0, first_height-1)*128+first_y+64
							crashsafe++
							//if (crashsafe>39) { break; printl("OOOOHH MA GAAWD3") }
						}
						debugoverlay.Line(Vector(first_endx-64,h,20), Vector(second_x+64,h,20),12,252,12,false,life)
						
						KillWalls(Vector(first_endx-64,h,20), Vector(second_x+64,h,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						
						local start = Vector(first_endx-64,h,1)
						local hall_vector = Vector(second_x-first_endx,0,0)
						for (local t = 0 ; t<(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
					}
					if (first_x>second_x)
					{
						local h = RandInt(0, first_height-1)*128+first_y+64
						//printl("bumper cars right")
						local crashsafe=0
						while (((!((h<second_endy)&&(h>second_y))) && (crashsafe<140)) || (DidItHit(Vector(first_x-5,h,2), Vector(second_endx+5,h,2))))
						{
							h = RandInt(0, first_height-1)*128+first_y+64
							crashsafe++
							//if (crashsafe>39) { break; printl("OOOOHH MA GAAWD4") }
						}
						debugoverlay.Line(Vector(first_x+64,h,20), Vector(second_endx-64,h,20),12,252,12,false,life)
						
						KillWalls(Vector(second_endx-64,h,20), Vector(first_x+64,h,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						local start = Vector(first_x+64,h,1)
						local hall_vector = Vector(second_endx-first_x,0,0)
						for (local t = 0 ; t<(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
					}
					//printl("overlap height")
					continue
				}
				
				
				//GENERATION WITH 2 LINES
				function GenerateLHall()
				{
					//printl(first_x+" "+second_x)
					
					local h = RandInt(0, first_height-1)
					local w = RandInt(0, second_width-1)
					
					local corridor_point1 = null
					if (first_x<second_x)
					{
						//printl("Firing first ray to right")
						if (DidItHit(Vector(first_endx+5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2))==true) { GenerateLHall(); return }
						debugoverlay.Line(Vector(first_endx-64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),12,252,12,false,life)
						KillWalls(Vector(first_endx-64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						corridor_point1 = Vector(second_x+w*128+64, first_y+(128*h)+64,20)
						
						local start = Vector(first_endx-64, first_y+(128*h)+64,1)
						local hall_vector = Vector(second_x+w*128-first_endx,0,0)
						if (hall_vector.x==0) { hall_vector.x=64 } // EXCUSE ME WHAT???? HOW DOES THIS WORK?
							
						//this monstrosity is needed to recheck whether out first ray was generated correctly before building floors
						if ((DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_y-5, 2))==true)&&(DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_endy+5, 2))==true)) { GenerateLHall(); return }
						
						KillWalls(Vector(first_endx-64, first_y+(128*h)+64,20),corridor_point1,RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						for (local t = 0 ; t<=(hall_vector.Length()/128) ; t++)
						{
							//debugoverlay.Line(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 26),255,252,222,false,55)
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
						//Place("corridor", "template_floor", (corridor_point1.x-64)+" "+(corridor_point1.y-64)+" 0")
					}
					if (first_x>second_x)
					{
						//printl("Firing first ray to left")
						//debugoverlay.Line(Vector(first_x-5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2),255,2,12,false,5)
						if (DidItHit(Vector(first_x-5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2))==true) { GenerateLHall(); return }
						debugoverlay.Line(Vector(first_x+64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),12,252,12,false,life)
						//debugoverlay.Line(Vector(first_x-5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2),255,2,12,false,5)
						corridor_point1 = Vector(second_x+w*128+64, first_y+(128*h)+64,20)
						
						local start = Vector(first_x+64, first_y+(128*h)+64,1)
						local hall_vector = Vector(corridor_point1.x-first_x+64,0,0)
						if (hall_vector.Length()==0) { hall_vector.x=(-64) }
						
						//this monstrosity is needed to recheck whether out first ray was generated correctly before building floors
						if ((DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_y-5, 2))==true)&&(DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_endy+5, 2))==true)) { GenerateLHall(); return }
						
							
						KillWalls(Vector(first_x+64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
							
						////debugoverlay.Line(start+Vector(0,0,30),start+Vector(0,0,30)+hall_vector,12,252,122,false,life)
						for (local t = 0 ; t<=(hall_vector.Length()/128) ; t++)
						{
							//debugoverlay.Line(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),12,252,12,false,life)
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
						//Place("corridor", "template_floor", (corridor_point1.x-64)+" "+(corridor_point1.y-64)+" 0")
					}
					
					if (first_y<second_y)
					{
						//printl("Firing second ray up")
						if (DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_y-5, 2))==true) { GenerateLHall(); return }
						debugoverlay.Line(corridor_point1, Vector(corridor_point1.x, second_y+64, 20),12,252,12,false,life)
						corridor_point1.z=1
						local start = corridor_point1
						local hall_vector = Vector(0,second_y+64-corridor_point1.y,0)
							
						KillWalls(corridor_point1+Vector(0,0,20), Vector(corridor_point1.x, second_y+64, 20),RandInt(0,1),room_info[second+"_Type"],room_info[first+"_Type"])
							
						for (local t = 0 ; t<(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
					}
					if (first_y>second_y)
					{
						//printl("Firing second ray down")
						if (DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_endy+5, 2))==true) { GenerateLHall(); return }
						debugoverlay.Line(corridor_point1, Vector(corridor_point1.x, second_endy-64, 20),12,252,12,false,life)
						corridor_point1.z=1
						local start = corridor_point1
						local hall_vector = Vector(0,second_y+64-corridor_point1.y,0)
							
						KillWalls(corridor_point1+Vector(0,0,20), Vector(corridor_point1.x, second_endy-64, 20),RandInt(0,1),room_info[second+"_Type"],room_info[first+"_Type"])
							
						for (local t = 0 ; t<(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
					}
				}
				
				GenerateLHall()
			}
			//for (local i = 0; i<Connections.len();i++) { printl(Connections[i]) }
					
		function GenerateCorridors2()
		{
			SendToConsole("play common/wpn_moveselect.wav");
			printl("_________________________")
			foreach (k,v in room_info) {
				if(k.find("Entrance")!=null)
				{
					v=0
				}
			}
			
			if (Connections==null) { Connections = array(rooms) }
			
			for (local i = rooms; i <= rooms; i++)
			{
				local destination = RandInt(1,i-1)
				if (i==2) { destination=1 }
				local crashsave = 0
				local distance = (Vector(room_info[destination+"_StartX"],room_info[destination+"_StartY"],0)-Vector(room_info[i+"_StartX"],room_info[i+"_StartY"],0)).Length()
				//printl("Trying to connect room "+i+" and "+destination) 
				while ( ((i==destination) || (room_info[destination+"_Entrances"]>3)) || ((distance>MAX_CORRIDOR_LENGTH ) || (HallPossible(i, destination)==false)) )
				{ 
					if (room_info[destination+"_Entrances"]>3) { printl("Room "+destination+" is about to get its "+(room_info[destination+"_Entrances"]+1)+"rd entrance! Trying another one.") }
					if (distance>MAX_CORRIDOR_LENGTH) { printl("Rooms "+i+" and "+destination+" are too far away from each other to connect! Trying another one.") }
					destination = RandInt(1,i-1); 
					distance = (Vector(room_info[destination+"_StartX"],room_info[destination+"_StartY"],0)-Vector(room_info[i+"_StartX"],room_info[i+"_StartY"],0)).Length()
					crashsave++
					if (crashsave>100) { destination = RandInt(1,rooms);  }
					if (crashsave>1000) { printl("oh shit"); break }
		
				}
				//Connections.append(destination) Connections.find(i-1)
				Connections[i-1]=destination
				room_info[i+"_Entrances"]++
				room_info[destination+"_Entrances"]++
			}
			
			for (local i = Connections.len()-1; i <= Connections.len()-1; i++)
			{
				local first = i+1
				local second = Connections[i]
				
				local first_height=(room_info[first+"_EndY"]-room_info[first+"_StartY"])/128
				local first_width=(room_info[first+"_EndX"]-room_info[first+"_StartX"])/128
				local second_height=(room_info[second+"_EndY"]-room_info[second+"_StartY"])/128
				local second_width=(room_info[second+"_EndX"]-room_info[second+"_StartX"])/128
				
				local first_x=room_info[first+"_StartX"]
				local first_endx=room_info[first+"_EndX"]
				local second_x=room_info[second+"_StartX"]
				local second_endx=room_info[second+"_EndX"]
				
				local first_y=room_info[first+"_StartY"]
				local first_endy=room_info[first+"_EndY"]
				local second_y=room_info[second+"_StartY"]
				local second_endy=room_info[second+"_EndY"]
				
				printl("Connected rooms "+first+" and "+second)
				
				
				//GENERATION FOR OVERLAPPING ROOMS BY 1 LINE

				if ((first_x<second_endx)&&(first_endx>second_x))
				{
					if (first_y<second_y)
					{
						local w = RandInt(0, first_width-1)*128+first_x+64
						//printl("bumper cars lower")
						local crashsafe=0
						while (((!((w<second_endx)&&(w>second_x))) && (crashsafe<140)) || (DidItHit(Vector(w,first_endy+5,2), Vector(w,second_y-5,2))))
						{
							w = RandInt(0, first_width-1)*128+first_x+64
							crashsafe++
							if (crashsafe>39) { break; printl("OOOOHH MA GAAWD1") }
						}
						debugoverlay.Line(Vector(w,first_endy-64,20), Vector(w,second_y+64,20),12,252,12,false,life)
						
						KillWalls(Vector(w,first_endy-64,20),Vector(w,second_y+64,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						local start = Vector(w,first_endy-64,1)
						local hall_vector = Vector(0,second_y-first_endy,0)
						for (local t = 0 ; t<=(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								Place(first+"-"+second,"floor", Vector(temp_x,temp_y,0),"",2)
							}
						}
						//printl(TraceLineComplex(Vector(w,first_endy-64,10), Vector(w,second_y+64,10),self,33570819,0).FractionLeftSolid())
					}
					if (first_y>second_y)
					{
						local w = RandInt(0, first_width-1)*128+first_x+64
						//printl("bumper cars higher")
						local crashsafe=0
						while (((!((w<second_endx)&&(w>second_x))) && (crashsafe<140)) || (DidItHit(Vector(w,first_y-5,2), Vector(w,second_endy+5,2))))
						{
							w = RandInt(0, first_width-1)*128+first_x+64
							crashsafe++
							if (crashsafe>39) { break; printl("OOOOHH MA GAAWD2") }
						}
						debugoverlay.Line(Vector(w,first_y+64,20), Vector(w,second_endy-64,20),12,252,12,false,life)
						
						KillWalls(Vector(w,first_y+64,20),Vector(w,second_endy-64,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						local start = Vector(w,first_y+64,1)
						local hall_vector = Vector(0,second_endy-first_y,0)
						for (local t = 0 ; t<=(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								Place(first+"-"+second,"floor", Vector(temp_x,temp_y,0),"",2)
							}
						}
					}
					//printl("overlap width")
					continue
				}
				if ((first_y<second_endy)&&(first_endy>second_y))
				{
					if (first_x<second_x)
					{
						local h = RandInt(0, first_height-1)*128+first_y+64
						//printl("bumper cars left")
						local crashsafe=0
						while (((!((h<second_endy)&&(h>second_y))) && (crashsafe<140)) || (DidItHit(Vector(first_endx+5,h,2), Vector(second_x-5,h,2))))
						{
							h = RandInt(0, first_height-1)*128+first_y+64
							crashsafe++
							if (crashsafe>39) { break; printl("OOOOHH MA GAAWD3") }
						}
						debugoverlay.Line(Vector(first_endx-64,h,20), Vector(second_x+64,h,20),12,252,12,false,life)
						
						KillWalls(Vector(first_endx-64,h,20),Vector(second_x+64,h,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						
						local start = Vector(first_endx-64,h,1)
						local hall_vector = Vector(second_x-first_endx,0,0)
						for (local t = 0 ; t<(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64 //OFFSET WITH DIVISION AND START Z TO 1
								Place(first+"-"+second,"floor", Vector(temp_x,temp_y,0),"",2)
							}
						}
					}
					if (first_x>second_x)
					{
						local h = RandInt(0, first_height-1)*128+first_y+64
						//printl("bumper cars right")
						local crashsafe=0
						while (((!((h<second_endy)&&(h>second_y))) && (crashsafe<140)) || (DidItHit(Vector(first_x-5,h,2), Vector(second_endx+5,h,2))))
						{
							h = RandInt(0, first_height-1)*128+first_y+64
							crashsafe++
							if (crashsafe>39) { break; printl("OOOOHH MA GAAWD4") }
						}
						debugoverlay.Line(Vector(first_x+64,h,20), Vector(second_endx-64,h,20),12,252,12,false,life)
						
						KillWalls(Vector(first_x+64,h,20),Vector(second_endx-64,h,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						local start = Vector(first_x+64,h,1)
						local hall_vector = Vector(second_endx-first_x,0,0)
						for (local t = 0 ; t<(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								Place(first+"-"+second,"floor", Vector(temp_x,temp_y,0),"",2)
							}
						}
					}
					//printl("overlap height")
					continue
				}
				
				//GENERATION WITH 2 LINES
				//GENERATION WITH 2 LINES
				function GenerateLHall()
				{
					//printl(first_x+" "+second_x)
					
					local h = RandInt(0, first_height-1)
					local w = RandInt(0, second_width-1)
					
					local corridor_point1 = null
					if (first_x<second_x)
					{
						//printl("Firing first ray to right")
						if (DidItHit(Vector(first_endx+5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2))==true) { GenerateLHall(); return }
						debugoverlay.Line(Vector(first_endx-64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),12,252,12,false,life)
						KillWalls(Vector(first_endx-64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						corridor_point1 = Vector(second_x+w*128+64, first_y+(128*h)+64,20)
						
						local start = Vector(first_endx-64, first_y+(128*h)+64,1)
						local hall_vector = Vector(second_x+w*128-first_endx,0,0)
						if (hall_vector.x==0) { hall_vector.x=64 } // EXCUSE ME WHAT???? HOW DOES THIS WORK?
							
						//this monstrosity is needed to recheck whether out first ray was generated correctly before building floors
						if ((DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_y-5, 2))==true)&&(DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_endy+5, 2))==true)) { GenerateLHall(); return }
						
						KillWalls(Vector(first_endx-64, first_y+(128*h)+64,20),corridor_point1,RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
						
						for (local t = 0 ; t<=(hall_vector.Length()/128) ; t++)
						{
							//debugoverlay.Line(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 26),255,252,222,false,55)
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
						//Place("corridor", "template_floor", (corridor_point1.x-64)+" "+(corridor_point1.y-64)+" 0")
					}
					if (first_x>second_x)
					{
						//printl("Firing first ray to left")
						//debugoverlay.Line(Vector(first_x-5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2),255,2,12,false,5)
						if (DidItHit(Vector(first_x-5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2))==true) { GenerateLHall(); return }
						debugoverlay.Line(Vector(first_x+64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),12,252,12,false,life)
						//debugoverlay.Line(Vector(first_x-5, first_y+(128*h)+64,2),Vector(second_x+w*128+64, first_y+(128*h)+64,2),255,2,12,false,5)
						corridor_point1 = Vector(second_x+w*128+64, first_y+(128*h)+64,20)
						
						local start = Vector(first_x+64, first_y+(128*h)+64,1)
						local hall_vector = Vector(corridor_point1.x-first_x+64,0,0)
						if (hall_vector.Length()==0) { hall_vector.x=(-64) }
						
						//this monstrosity is needed to recheck whether out first ray was generated correctly before building floors
						if ((DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_y-5, 2))==true)&&(DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_endy+5, 2))==true)) { GenerateLHall(); return }
						
							
						KillWalls(Vector(first_x+64, first_y+(128*h)+64,20),Vector(second_x+w*128+64, first_y+(128*h)+64,20),RandInt(0,1),room_info[first+"_Type"],room_info[second+"_Type"])
							
						////debugoverlay.Line(start+Vector(0,0,30),start+Vector(0,0,30)+hall_vector,12,252,122,false,life)
						for (local t = 0 ; t<=(hall_vector.Length()/128) ; t++)
						{
							//debugoverlay.Line(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),12,252,12,false,life)
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
						//Place("corridor", "template_floor", (corridor_point1.x-64)+" "+(corridor_point1.y-64)+" 0")
					}
					
					if (first_y<second_y)
					{
						//printl("Firing second ray up")
						if (DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_y-5, 2))==true) { GenerateLHall(); return }
						debugoverlay.Line(corridor_point1, Vector(corridor_point1.x, second_y+64, 20),12,252,12,false,life)
						corridor_point1.z=1
						local start = corridor_point1
						local hall_vector = Vector(0,second_y+64-corridor_point1.y,0)
							
						KillWalls(corridor_point1+Vector(0,0,20), Vector(corridor_point1.x, second_y+64, 20),RandInt(0,1),room_info[second+"_Type"],room_info[first+"_Type"])
							
						for (local t = 0 ; t<(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
					}
					if (first_y>second_y)
					{
						//printl("Firing second ray down")
						if (DidItHit(corridor_point1+Vector(0,0,-15), Vector(corridor_point1.x, second_endy+5, 2))==true) { GenerateLHall(); return }
						debugoverlay.Line(corridor_point1, Vector(corridor_point1.x, second_endy-64, 20),12,252,12,false,life)
						corridor_point1.z=1
						local start = corridor_point1
						local hall_vector = Vector(0,second_y+64-corridor_point1.y,0)
							
						KillWalls(corridor_point1+Vector(0,0,20), Vector(corridor_point1.x, second_endy-64, 20),RandInt(0,1),room_info[second+"_Type"],room_info[first+"_Type"])
							
						for (local t = 0 ; t<(hall_vector.Length()/128) ; t++)
						{
							if (TraceLineComplex(start+hall_vector/(hall_vector.Length()/128)*(t+1),start+hall_vector/(hall_vector.Length()/128)*(t+1)+Vector(0,0, 16),self,33570819,0).DidHit()==false)
							{
								local temp_x = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).x-64
								local temp_y = (start+hall_vector/(hall_vector.Length()/128)*(t+1)).y-64
								EntFireByHandle(self,"RunScriptCodeQuotable","PlaceDelay("+first+"+''-''+"+second+"+''QfloorQ''+''"+temp_x+" "+temp_y+" 0Q''+2)",RandFloat(0,0.02))
							}
						}
					}
				}
				
				GenerateLHall()
			}
			//for (local i = 0; i<Connections.len();i++) { printl(Connections[i]) }
			EntFireByHandle(self,"RunScriptCode","RemoveBadDoors()",0.1);
			EntFireByHandle(self,"RunScriptCode","OptimiseWalls()",0.15);
			EntFireByHandle(self,"RunScriptCode","PlaceHalls()",0.25);
			EntFireByHandle(self,"RunScriptCode","PlaceHalls2()",1.25);
			EntFireByHandle(self,"RunScriptCode","PlaceHalls3()",2.25);
			EntFireByHandle(self,"RunScriptCode","PlaceHalls4()",3.25);
			EntFireByHandle(self,"CallScriptFunction","PrintFreedEdicts2",4.65)
			local start_x = RandInt((64+room_info[1+"_StartX"]),(room_info[1+"_EndX"]-64))
			local start_y = RandInt((64+room_info[1+"_StartY"]),(room_info[1+"_EndY"]-64))
			EntFire("player","SetLocalOrigin",start_x+" "+start_y+" 16.5",8)
			EntFire("?_dlight","TurnOff","",1)
			EntFire("??_dlight","TurnOff","",1)
			EntFireByHandle(self,"CallScriptFunction","OptimiseFloors",4.5)
		}
			if (rooms==2) {GenerateCorridors2(); return }
			corridor++
			if (corridor==(rooms-2)) { EntFireByHandle(self,"CallScriptFunction","GenerateCorridors2",0.04) }
			if (corridor<(rooms-2)) { EntFireByHandle(self,"CallScriptFunction","GenerateCorridors",0.04) }
		}
		
		function GetPlayerRoom()
		{
			local plx=player.GetOrigin().x
			local ply=player.GetOrigin().y
			for (local i=1; i<=rooms; i++)
			{
				local rx = room_info[i+"_StartX"]
				local rx2 = room_info[i+"_EndX"]
				local ry = room_info[i+"_StartY"]
				local ry2 = room_info[i+"_EndY"]
				if (((plx>rx)&&(plx<rx2))&&((ply>ry)&&(ply<ry2))) { return i }
			}
			return
		}
		
		function PlaceProps()
		{
			for (local i = 1;i<=rooms;i++)
			{
				local x=room_info[i+"_StartX"]
				local y=room_info[i+"_StartY"]
				local room_id=i
				local w=(room_info[i+"_EndX"]-room_info[i+"_StartX"])/128
				local h=(room_info[i+"_EndY"]-room_info[i+"_StartY"])/128
				local intensity=1
				for (local ix=0;ix<w;ix++)
				{
					for (local iy=0;iy<h;iy++)
					{
						local prop_intensity=intensity
						if (!((iy==0)||(ix==0)||(iy==h-1)||(ix==w-1))) { prop_intensity+=RandInt(1,2) }
						//if ((iy==0)||(ix==0)||(iy==h-1)||(ix==w-1)||dontrequirewall==1) //we place props on the sides and corners of the room first
						for (local repeats=0;repeats<prop_intensity;repeats++)
						{
							local prop=LIST_PROPS[RandInt(0,LIST_PROPS.len()-1)]	//selecting prop and random position, if door is near then skip the tile
							if (prop.alignment==0)
							{
								prop=LIST_PROPS[RandInt(0,LIST_PROPS.len()-1)]
							}
							if (!((iy==0)||(ix==0)||(iy==h-1)||(ix==w-1))&&prop.alignment==0)
							{
								prop=LIST_PROPS[RandInt(0,LIST_PROPS.len()-1)]
							}
							if (("massive" in prop)&&!((iy==0)||(ix==0)||(iy==h-1)||(ix==w-1))) { continue }	
							local propx=RandInt(8+x+ix*128+prop.size.x/2,x+ix*128+128-prop.size.x/2-8)
							local propy=RandInt(8+y+iy*128+prop.size.y/2,y+iy*128+128-prop.size.y/2-8)
							if ((!Entities.FindByNameWithin(null,"*dligh*",Vector(x+ix*128+64,y+iy*128+64,95),300))&&!(TraceLineComplex(Vector(x+ix*128+64,y+iy*128+64,95),Vector(x+ix*128+64,y+iy*128+64,100),null,33570819,0).DidHit()))
							{
								local rand_id=RandInt(0,LIST_LIGHTS.len()-1)
								local rand_angle=RandInt(0,3)*90
								local light_pos=Vector(x+ix*128,y+iy*128,0)
								local wall_test_vector=Vector(x+ix*128+64,y+iy*128+64,95)-RotateVectorByAngle(Vector(64,0,0),rand_angle)
								while (LIST_LIGHTS[rand_id].requires_wall==true&&TraceHull(wall_test_vector-Vector(1,1,5),wall_test_vector+Vector(1,1,5)).DidHit()==false)
								{
									if (rand_angle>360)
									{
										while(LIST_LIGHTS[rand_id].requires_wall==true) { rand_id=RandInt(0,LIST_LIGHTS.len()-1) }
										light_pos=Vector(x+ix*128,y+iy*128,16)
										break
									}
									rand_angle+=90
									light_pos=Vector(x+ix*128,y+iy*128,0)-RotateVectorByAngle(Vector(40,0,0),rand_angle)
									wall_test_vector=Vector(x+ix*128+64,y+iy*128+64,95)-RotateVectorByAngle(Vector(64,0,0),rand_angle)
								}
								if (LIST_LIGHTS[rand_id].requires_wall==true)
								{
									light_pos=Vector(x+ix*128,y+iy*128,16)-RotateVectorByAngle(Vector(40,0,0),rand_angle)
									if (TraceHull(wall_test_vector+RotateVectorByAngle(Vector(7,0,20),rand_angle),wall_test_vector+RotateVectorByAngle(Vector(7,0,20),rand_angle)+Vector(1,1,5)).DidHit()==true)
									{
										light_pos+=RotateVectorByAngle(Vector(8,0,0),rand_angle)
									}
									//PlaceWeakLight(room_id,LIST_LIGHTS[rand_id].model, light_pos,rand_angle,0)
									PlaceLight(room_id,LIST_LIGHTS[rand_id].model, light_pos,rand_angle,1.75)
								}
								else { PlaceLight(room_id,LIST_LIGHTS[rand_id].model, light_pos,rand_angle,1) }
							}
							if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),136)&&("static_only" in prop)) { continue }
							if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),260)&&("massive" in prop)) { continue }
							if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),120)) { continue }
							
							local angles=RandFloat(0,359)	//calculating prop angles depending on alignment characteristic
							if ((prop.alignment!=0)&&((iy==0)||(ix==0)||(iy==h-1)||(ix==w-1)))
							{
								angles=DecideOrientation(RandInt(1,4),ix,iy,w,h)
								while (angles==(-1)) { angles=DecideOrientation(RandInt(1,4),ix,iy,w,h) }
							}
							if ((prop.alignment!=0)&&!((iy==0)||(ix==0)||(iy==h-1)||(ix==w-1))) { angles=RandInt(0,3);angles*=90 }
							if (prop.alignment==1) { angles+=RandFloat(-10,10) }
							local attachment=0
							local offsetx=0
							local offsety=0
							function RecalculateAnglesAndPos(origin=Vector(0,0,0))
							{
								if (prop.alignment==2) {
									switch(angles)
										{
											case 0:
												propx=8.2+x+ix*128+prop.size.x/2;propy=RandInt(y+iy*128+prop.size.y/2,y+iy*128+128-prop.size.y/2);attachment=1;offsetx=120;break
											case 90:
												propy=8.2+y+prop.size.x/2+iy*128;propx=RandInt(x+ix*128+prop.size.y/2,x+ix*128+128-prop.size.y/2);propx=RandInt(x+ix*128+prop.size.y/2,x+ix*128+128-prop.size.y/2);attachment=3;offsety=120;break
											case 180:
												propx=128+x+ix*128-prop.size.x/2-8.2;propy=RandInt(y+iy*128+prop.size.y/2,y+iy*128+128-prop.size.y/2);attachment=2;offsetx=-120;break
											case 270:
												propy=128+y+iy*128-prop.size.x/2-8.2;propx=RandInt(x+ix*128+prop.size.y/2,x+ix*128+128-prop.size.y/2);attachment=4;offsety=-120;break
										}
								}
								if (prop.alignment==1) {
									if (angles<30 || angles>340){
										propx=RandInt(x+ix*128+prop.size.x,x+ix*128+64-prop.size.x*2.5) }
									if (angles<120 && angles>70){
										propy=RandInt(8+y+iy*128+prop.size.y/2,y+prop.size.y/2) }
									if (angles<200 && angles>160){
										propx=RandInt(x+ix*128+prop.size.x*2+32,x+ix*128+128-prop.size.x*1.5) }
									if (angles<290 && angles>250){
										propy=RandInt(y+iy*128+prop.size.y+32,y+iy*128+128-prop.size.y*1.5) }
								}
							}
							RecalculateAnglesAndPos()
							local realsize = PropSizeAtAngles(prop,angles)
						
							local hull = TraceHull(Vector(propx-realsize.x/2,propy-realsize.y/2,16.1),Vector(propx+realsize.x/2,propy+realsize.y/2,16.1+realsize.z))
							local retries=3	//we have only 2 tries to place a prop, if all failed, then choose another tile
							while ((hull.DidHit()||propy>(y+h*128+5))&&retries>0)
							{
								retries--
								if (propy>(y+h*128+5)) { retries=0;break }
								if (retries<0) { break }
								propx=RandInt(8+x+ix*128+prop.size.x/2,x+ix*128+128-prop.size.x/2-8)
								propy=RandInt(8+y+iy*128+prop.size.y/2,y+iy*128+128-prop.size.y/2-8)
								RecalculateAnglesAndPos()
								local randoffset=RandInt(prop.size.y/2-64,64-prop.size.y/2)
								if (prop.size.y>=128) { randoffset=0 }
								if (prop.size.y>=150) { retries=0;break }
								if (ThisHas(hull.Entity().GetModelName(),"subwall")&&attachment<3) { propx+=offsetx;propy=hull.Entity().GetOrigin().y+randoffset }
								if (ThisHas(hull.Entity().GetModelName(),"subwall")&&attachment>2) { propx=hull.Entity().GetOrigin().x+randoffset;propy+=offsety }
								hull = TraceHull(Vector(propx-realsize.x/2,propy-realsize.y/2,16.1),Vector(propx+realsize.x/2,propy+realsize.y/2,16.1+realsize.z))
							}
							if (retries<1) { /*printl("Prop placement failed after 4 retries");*/continue }
							local testvector=RotateVectorByAngle(Vector(prop.size.x/2+5,0,0),angles)
							local testline = TraceLineComplex(Vector(propx+1,propy+1,20)-testvector,Vector(propx,propy,30)-testvector,null,33570819,0)
							if (prop.alignment>0&&testline.DidHit()==false) { continue }
							PlaceProp(prop.model, Vector(propx,propy,16)+RotateVectorByAngle(prop.offset,angles), angles)
							local propspawnpos=Vector(propx,propy,16)+RotateVectorByAngle(prop.offset,angles)
							if ( IsServer() )
							{
								if (RandInt(1,20)==1||!("itemspawns" in prop))
								{
									local type = RandInt(0,2)
									local count = clamp(RandInt(1,18),1,LIST_ITEMS[type].MaxSpawnStack)
									if (RandInt(1,20)!=1) {type=0}
								}
								else
								{
									for (local c=0;c<prop.itemspawns.len();c++)
									{
										local type = RandInt(0,3)
										if (type==2&&RandInt(1,5)<3) {type=1}
										if (RandInt(1,8)<5) {type=0}
										if (type==3&&RandInt(1,10)>2) {type=RandInt(0,2)}
										local count = RandInt(1,LIST_ITEMS[type].MaxSpawnStack)
										if (LIST_ITEMS[type].isammo=true) {count = clamp(count,5,LIST_ITEMS[type].MaxSpawnStack)}
										SpawnItem(type,count,Vector(propx,propy,16)+RotateVectorByAngle(prop.itemspawns[c],angles))
									}
								}
							}
							local randpos=Vector(RandInt(8+x+ix*128+16/2,x+ix*128+128-16/2-8),RandInt(8+y+iy*128+16/2,y+iy*128+128-16/2-8),16)
							local enemyspawn = RandInt(0,27) //default is 0 7
							if (enemyspawn==6&&!TraceHull(randpos+Vector(-16,-16,1),randpos+Vector(16,16,96)).DidHit()) {PlaceEntity("npc_zombie", randpos,RandInt(0,359))}
							if (enemyspawn==5&&!TraceHull(randpos+Vector(-16,-16,1),randpos+Vector(16,16,96)).DidHit()) {PlaceEntity("npc_fastzombie", randpos,RandInt(0,359))}
							debugoverlay.Box(Vector(propx-realsize.x/2,propy-realsize.y/2,16),Vector(0,0,0),Vector(realsize.x,realsize.y,realsize.z),10,255,10,20,3.25)
							DecalTrace(TraceLineComplex(Vector(ix*128+x+64,iy*128+y+64,17),Vector(ix*128+x+64,iy*128+y+64,1),player,33570819,0),"Dirt")
						}
						
					}
				}
			}
		}
		
		function GenerateLayout()
		{
			GenerateRoom(RandInt(2,MAX_ROOM_SIZE),RandInt(2,MAX_ROOM_SIZE),RandInt(0,6));
		}
		Convars.RegisterCommand( "generate_room", function(_)
		{
			GenerateRoom(RandInt(2,MAX_ROOM_SIZE),RandInt(2,MAX_ROOM_SIZE),RandInt(0,6));
			//debugoverlay.Box(Vector(0,0,0), Vector(0,0,0),Vector(33,323,33),170,15,10,130,22)
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		
		Convars.RegisterCommand( "generate_corridors", function(_)
		{
			GenerateCorridors();
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		Convars.RegisterCommand( "generate_layout", function(_)
		{
			for (local i = 0;i<MAX_ROOMS;i++)
			{
				EntFireByHandle(self,"CallScriptFunction","GenerateLayout",RandFloat(0,MAX_ROOMS/12))
			}
			EntFireByHandle(self,"CallScriptFunction","GenerateCorridors",MAX_ROOMS/22+1.23)
			EntFireByHandle(self,"CallScriptFunction","PlaceDefaultMapDetail",MAX_ROOMS/22+4.03)
			EntFireByHandle(self,"CallScriptFunction","PlaceProps",MAX_ROOMS/22+5.03)
			EntFireByHandle(self,"CallScriptFunction","PlaceProps",MAX_ROOMS/22+6.53)
			EntFireByHandle(self,"CallScriptFunction","PlaceProps",MAX_ROOMS/22+8.03)
			SendToConsole("playsoundscape coast.bridge_concrete_room")
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		Convars.RegisterCommand( "place_walls", function(_)
		{
			PlaceHalls();
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		Convars.RegisterCommand( "print_entrances", function(_)
		{
			PrintEntrances();
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		
		Convars.RegisterCommand( "optimise_walls", function(_)
		{
			OptimiseWalls()
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		
		Convars.RegisterCommand( "remove_bad_doors", function(_)
		{
			RemoveBadDoors();
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		
		Convars.RegisterCommand( "place_props", function(_)
		{
			PlaceProps();
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		Convars.RegisterCommand( "place_map_detail", function(_)
		{
			PlaceMapDetail(rooms, room_info);
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		function PlaceDefaultMapDetail() {PlaceMapDetail(rooms, room_info);}
		Convars.RegisterCommand( "getroom", function(_)
		{
			printl(GetPlayerRoom())
		}.bindenv(this), "", FCVAR_CLIENTDLL );
	}

}
function Think()
{
	if (rooms<1) { return }
	local dlight = null
	if (GetPlayerRoom()!=null)
	{
		EntFire(GetPlayerRoom()+"_dlight","TurnOn","",0)
	}
	for (local i = 1; i<=rooms; i++)
	{
		if (i==GetPlayerRoom()) { continue }
		local roompos=Vector(room_info[i+"_StartX"],room_info[i+"_StartY"],0)
		if ((player.GetOrigin()-roompos).Length()>MAX_ROOM_SIZE*250) { EntFire(i+"_dlight","TurnOff","",0); continue }
		local entrance_point = null
		for (local i2=1; i2<=4;i2++)
		{
			local id=i2
			if (i2==1) {id=""}
			entrance_point = Entities.FindByName(null,i+"_doorway"+id)
			if (entrance_point==null) { break }
			local angles = entrance_point.GetAngles()
			angles.y-=90
			local dot = (entrance_point.GetCenter()+Vector(0,0,50))+AngleVectors(angles)*30
			//debugoverlay.Line(dot,player.EyePosition()+Vector(0,0,17),2,1,212,false,0.5)
			if (TraceLineComplex(dot,player.EyePosition(),self,33570819,0).Entity()==player)
			{
				EntFire(i+"_dlight","TurnOn","",0)
				break
			}
			else
			{
				EntFire(i+"_dlight","TurnOff","",0)
			}
		}
	}
}