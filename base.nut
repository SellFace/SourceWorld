IncludeScript("lists/list_props.nut")
IncludeScript("lists/list_lights.nut")
IncludeScript("lists/list_map_detail.nut")

function ThisHas(str, str2)
{
	if (str==null) {return false}
	if ((typeof str)!="string") {str=str.tostring()}
	if (str.find(str2)!=null) { return true }
	return false
}

RotateVector<-function(A,B,RotatedByAngle=Vector()){local m=matrix3x4_t();AngleMatrix(B,Vector(0,0,0),m);return VectorRotate(A,m)}

function IntToLetter(a)
{
	switch(a)
		{
			case null: a=".";return a;break
			case "+": return "+";break
			case 10: a="A";break
			case 11: a="B";break
			case 12: a="C";break
			case 13: a="D";break
			case 14: a="E";break
			case 15: a="F";break
			case 16: a="G";break
			case 17: a="H";break
			case 18: a="I";break
			case 19: a="J";break
			case 20: a="K";break
			case 21: a="L";break
			case 22: a="M";break
			case 23: a="N";break
			case 24: a="$";break
			case 25: a="P";break
			case 26: a="R";break
			case 27: a="S";break
			case 28: a="T";break
			case 29: a="V";break
			case 30: a="U";break
			case 31: a="Q";break
			case 32: a="W";break
			case 33: a="X";break
			case 34: a="Y";break
			case 35: a="Z";break/*
			case 36: a="a";break
			case 37: a="b";break
			case 38: a="c";break
			case 39: a="d";break
			case 40: a="e";break
			case 41: a="f";break
			case 42: a="g";break
			case 43: a="h";break
			case 44: a="i";break
			case 45: a="j";break
			case 46: a="k";break
			case 47: a="l";break*/
			case 36: a="A";break
			case 37: a="A";break
			case 38: a="A";break
			case 39: a="A";break
			case 40: a="A";break
			case 41: a="A";break
			case 42: a="A";break
			case 43: a="A";break
			case 44: a="A";break
			case 45: a="A";break
			case 46: a="A";break
			case 47: a="A";break
			case 48: a="m";break
			case 49: a="n";break
			case 50: a="o";break
			case 51: a="p";break
			case 52: a="r";break
			case 53: a="s";break
			case 54: a="t";break
			case 55: a="v";break
			case 56: a="u";break
			case 57: a="q";break
			case 58: a="w";break
			case 59: a="x";break
			case 60: a="y";break
			case 61: a="z";break
			case 62: a="Й";break
			case 63: a="Ё";break
			case 64: a="Ы";break
			case 65: a="Ч";break
			case 66: a="Я";break
			case 67: a="Ь";break
			case 68: a="Ж";break
			case 69: a="Э";break
			case 70: a="Ъ";break
		}
	if (a.tostring().find("-")!=null) {return "#"}
	return a
}

function PlaceDoor(skin, pos = Vector(0,0,0), angles = 0, inbetween = false)
{
	if (Entities.FindByClassnameWithin(null,"prop_door_rotating",pos+Vector(0,0,54),30)) { /*debugoverlay.Sphere(pos+Vector(0,0,54),30,200,0,0,false,10);*/return }
	pos=pos+Vector(0,0,54)
	angles+=90
	local model_offset=Vector(0,0,0)
	local singular_offset = 0
	if (inbetween==true) { singular_offset=4 }
	switch(angles)
	{
		case 0: 
			model_offset=Vector(-singular_offset,-23,0); break;
		case 90: 
			model_offset=Vector(23,-singular_offset,0); break;
		case 180: 
			model_offset=Vector(singular_offset,23,0); break;
		case 270: 
			model_offset=Vector(-23,singular_offset,0); break;
		default:
			model_offset=Vector(-singular_offset,-23,0); break;
	}
	pos+=model_offset
	local S = {
	IDENTIFIER = "door",
	hardware = 1,
	vscripts = "prop_door_rotating.nut",
	angles = "0 "+angles+" 0",
	origin = pos.x+" "+pos.y+" "+pos.z,
	model = "models/props_c17/door01_left.mdl",
	skin = skin,
	opendir = 0
	}
	
	SpawnEntityFromTable("prop_door_rotating",S);
}

function PlacePoint(thing, pos = Vector(0,0,0), angles = 0)
{
	if (thing.GetClassname()=="prop_door_rotating") {return}
	if (ThisHas(thing.GetName(),"doorway")) {return}
	if (ThisHas(thing.GetName(),"_")!=true) {return}
	local id = thing.GetName().slice(0,thing.GetName().find("_"))
	local targetnam = id+"_doorway"
	local i = 1
	local duplicate=null
	
	while (duplicate = Entities.FindByName(null, targetnam))
	{
		i++
		targetnam=id+"_doorway"+i
	}
	pos=pos+Vector(0,0,54)
	angles+=90
	local S = {
	IDENTIFIER = "entranceinfotarget",
	targetname=targetnam
	angles = "0 "+angles+" 0",
	origin = pos.x+" "+pos.y+" "+pos.z
	}
	
	SpawnEntityFromTable("info_target",S);
}

function TraceHull(a,b)
{
	debugoverlay.Box(a,Vector(0,0,0),b-a,55,5,20,50,0.55)
	//local hull =TraceHullComplex(a,a,Vector(0,0,0),b-a,Entities.First(),100679691,0)
	//if (hull.DidHit()) {printl("collided with "+hull.Entity().GetClassname())}
	return TraceHullComplex(a,a,Vector(0,0,0),b-a,Entities.First(),100679691,0)
}
function DrawDebugBox(pos,size,colormod=1)
{
	local a=pos-(size/2)
	local b=pos+(size/2)
	//debugoverlay.Box(a,Vector(0,0,0),b-a,55*colormod,252/colormod,40*colormod,20/colormod,0.25*fabs(colormod))
}
function TraceHullSize(vector,pos)
{
	//TraceHullComplex(Vector(propx-prop.size.x/2,propy-prop.size.y/2,17),Vector(propx+prop.size.x/2,propy+prop.size.y/2,16+prop.size.z),Vector(0,0,0),Vector(prop.size.x*1.1,prop.size.y*1.1,prop.size.z*1.1),self,100679691,0)
	return TraceHull(Vector(pos.x-vector.x/2,pos.y-vector.y/2,pos.z),Vector(pos.x+vector.x/2,pos.y+vector.y/2,pos.z+vector.z))
}

function PropSizeAtAngles(prop,angles) // this is a crappy way of tracing bounding boxes, but i guess it's better than nothing
{
	//sin 1.57 = 1
	local diagonal=1-fabs(((angles+90)%90)/90.0-0.5)*2
	angles=angles/57.32
	local direction=fabs(sin(angles)) //0 means we keep same size, 1 means we invert x and y
	local direction_inv=(1-direction)
	local sizex=prop.size.x
	local sizey=prop.size.y
	//printl(direction+" "+direction_inv+" "+diagonal)
	
	local rsizex=(sizex*direction_inv+sizey*direction)*(1+0.41*diagonal)
	local rsizey=(sizey*direction_inv+sizex*direction)*(1+0.41*diagonal)
	return Vector(rsizex,rsizey,prop.size.z)
}

function RotateVectorByAngle(vector,angles)
{
	return RotateVector(vector,Vector(0,angles,0))
}

function DecideOrientation(num,ix,iy,w,h)
{
	switch(num)
	{
		case 1:
			if (ix==0) { return 0 }; break;
		case 2:
			if (iy==h-1) { return 90 }; break;
		case 3:
			if (ix==w-1) { return 180 }; break;
		case 4:
			if (iy==0) { return 270 }; break;
	}
	return -1
}
/*
function SpawnItem(itemid=2,count=1,pos=Vector(0,0,0))
{
	if (count==0||itemid<=0) { return false }
	local id=1
	local itemmodel=LIST_ITEMS[itemid].model
	if (Entities.FindByName(null,LIST_ITEMS[itemid].itemname+"100")) {id=101}
	while (Entities.FindByName(null,LIST_ITEMS[itemid].itemname+id)) {id++}
	local S = {
	IDENTIFIER = "ammo",
	origin = pos.x+" "+pos.y+" "+pos.z,
	rendermode = 1,
	targetname = LIST_ITEMS[itemid].itemname+id,
	vscripts = "items/"+LIST_ITEMS[itemid].itemname+".nut",
	health = count,
	model = itemmodel,
	effects = 256
	angles = "0 "+Entities.FindByName(null,"script_generation").GetScriptScope().RandInt(0,359)+" 0"
	}
	//printl("spawning "+count+" items")
	local itement=SpawnEntityFromTable("prop_physics",S)
	itement.SetHealth(count)
	itement.SetCollisionGroup(11)
	return itement
}
*/
function Replace(thing,name,inbetween)
{
	if (thing.GetClassname()=="prop_door_rotating") {return}
	if (ThisHas(thing.GetName(),"doorway")) {return}
	if (ThisHas(thing.GetName(),"_")!=true) {return}
	if (inbetween==true) { name="doorway_double" }
	local id = thing.GetName().slice(0,thing.GetName().find("_"))
	local targetnam = id+"_doorway"
	local i = 1
	local duplicate=null
	
	while (duplicate = Entities.FindByName(null, targetnam))
	{
		i++
		targetnam=id+"_doorway"+i
	}
	local pos = thing.GetOrigin()
	local angles = thing.GetAngles()
	local skin = thing.GetSkin()
	local S = {
	IDENTIFIER = "doorway",
	targetname = targetnam
	solid = 6,
	angles = angles.x+" "+angles.y+" "+angles.z,
	model = "models/mapgen/"+name+".mdl",
	origin = pos.x+" "+pos.y+" "+pos.z,
	skin = skin
	}
	SpawnEntityFromTable("prop_dynamic",S);
	
	angles.y-=90
	local dot = (thing.GetCenter()+Vector(0,0,50))+AngleVectors(angles)*30
	/*
	debugoverlay.Line(dot,dot+Vector(0,0,4),2,1,212,false,20.0)
	debugoverlay.Line(dot,dot+Vector(0,0,-4),212,1,2,false,20.0)
	debugoverlay.Line(dot,dot+Vector(0,4,0),2,1,111,false,20.0)
	debugoverlay.Line(dot,dot+Vector(0,-4,0),111,1,2,false,20.0)
	debugoverlay.Line(dot,dot+Vector(4,0,0),2,1,111,false,20.0)
	debugoverlay.Line(dot,dot+Vector(-4,0,0),111,1,2,false,20.0)
	*/
	
}

function ForceReplace(thing,name,inbetween)
{
	if (ThisHas(thing.GetName(),"_")!=true) {return}
	if (inbetween==true) { name="doorway_double" }
	local id = thing.GetName().slice(0,thing.GetName().find("_"))
	local targetnam = id+"_"+name
	local i = 1
	local duplicate=null
	
	while (duplicate = Entities.FindByName(null, targetnam))
	{
		i++
		targetnam=id+"_"+name+""+i
	}
	local pos = thing.GetOrigin()
	local angles = thing.GetAngles()
	local skin = thing.GetSkin()
	local S = {
	IDENTIFIER = "forcereplaced",
	targetname = targetnam
	solid = 6,
	angles = angles.x+" "+angles.y+" "+angles.z,
	model = "models/mapgen/"+name+".mdl",
	origin = pos.x+" "+pos.y+" "+pos.z,
	skin = skin
	}
	SpawnEntityFromTable("prop_dynamic",S);
	
	angles.y-=90
	local dot = (thing.GetCenter()+Vector(0,0,50))+AngleVectors(angles)*30
	/*
	debugoverlay.Line(dot,dot+Vector(0,0,4),2,1,212,false,20.0)
	debugoverlay.Line(dot,dot+Vector(0,0,-4),212,1,2,false,20.0)
	debugoverlay.Line(dot,dot+Vector(0,4,0),2,1,111,false,20.0)
	debugoverlay.Line(dot,dot+Vector(0,-4,0),111,1,2,false,20.0)
	debugoverlay.Line(dot,dot+Vector(4,0,0),2,1,111,false,20.0)
	debugoverlay.Line(dot,dot+Vector(-4,0,0),111,1,2,false,20.0)
	*/
	
}

function CheckForHull(name, pos="0 0 0")
{
	//if (ThisHas(name,"wall")) { return false }
	/*
	local pos2=""
	local pos3=""
	local realpos=null
	pos2=pos.slice(pos.find(" ")+1,pos.len())
	pos3=pos2.slice(pos2.find(" ")+1,pos2.len())
	pos2=pos.slice(pos.find(" ")+1,pos.len()).slice(0,pos.find(" ")+1)
	realpos=Vector(pos.slice(0,pos.find(" ")).tointeger(),pos2.tointeger(),pos3.tointeger())
	local checker = Vector(0,0,0)
	switch(name)
	{
	case "template_floor": checker=Vector(63, 63, 0); realpos=realpos+Vector(64,64,8);
	case "template_ceiling": checker=Vector(63, 63, 0); realpos=realpos+Vector(64,64,152);
	case "template_floor2x2": checker=Vector(191, 191, 0); realpos=realpos+Vector(0,0,8);
	case "template_ceiling2x2": checker=Vector(191, 191, 0); realpos=realpos+Vector(0,0,152);
	case "template_floor3x3": checker=Vector(319, 319, 0); realpos=realpos+Vector(0,0,8);
	case "template_ceiling3x3": checker=Vector(319, 319, 0); realpos=realpos+Vector(0,0,152);
	default: checker=Vector(0, 0, 0);
	}
	*/
	return false
}
function CheckForTile(ent, z=10, orientation="E", same_id_only=false, allow_conjoined=true)
{
	local v=Vector(0,0,0)
	switch(orientation)
	{
		case "N":
			v=Vector(0,65,z); break;
		case "N2":
			v=Vector(0,193,z); break;
		case "N3":
			v=Vector(0,321,z); break;
		case "E2N":
			v=Vector(193,65,z); break;
		case "E":
			v=Vector(65,0,z); break;
		case "E2":
			v=Vector(193,0,z); break;
		case "E3":
			v=Vector(321,0,z); break;
		case "N2E":
			v=Vector(65,193,z); break;
		case "S":
			v=Vector(0,-65,z); break;
		case "W":
			v=Vector(-65,0,z); break;
		case "NE":
			v=Vector(65,65,z); break;
		case "NE2":
			v=Vector(193,193,z); break;
	}
	if ((TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity()!=null)&&(same_id_only))
	{
		local ourID=ent.GetName().slice(0,ent.GetName().find("_"))
		local theirID="0"
		if (ThisHas(TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName(),"_"))
		{
			theirID=TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName().slice(0,TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName().find("_"))
		}
		if (ourID!=theirID) { return false }
		if (allow_conjoined==false)
		{
			if (ThisHas(ent.GetName(),"x")) { return false }
			if (ThisHas(TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName(),"x")) { return false }
		}
	}
	return TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).DidHit()
}
function CheckForCloseCollisions(ent, z=10, orientation="E", same_id_only=false, allow_conjoined=true)
{
	local v=Vector(0,0,0)
	switch(orientation)
	{
		case "N":
			v=Vector(0,16,z); break;
		case "E":
			v=Vector(16,0,z); break;
		case "S":
			v=Vector(0,-16,z); break;
		case "W":
			v=Vector(-16,0,z); break;
	}
	return TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),player,33570819,0).DidHit()
}
function FindTileNextTo(ent,z=10,orientation="E")
{
	local v=Vector(0,0,0)
	switch(orientation)
	{
		case "N":
			v=Vector(0,65,z); break;
		case "N2":
			v=Vector(0,193,z); break;
		case "N3":
			v=Vector(0,321,z); break;
		case "E2N":
			v=Vector(193,65,z); break;
		case "E":
			v=Vector(65,0,z); break;
		case "E2":
			v=Vector(193,0,z); break;
		case "E3":
			v=Vector(321,0,z); break;
		case "N2E":
			v=Vector(65,193,z); break;
		case "S":
			v=Vector(0,-65,z); break;
		case "W":
			v=Vector(-65,0,z); break;
		case "NE":
			v=Vector(65,65,z); break;
		case "NE2":
			v=Vector(193,193,z); break;
	}
	return TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity()
}

function FindWallNextTo(ent,z=50,orientation="W")
{
	if (ThisHas(ent.GetName(),"x")) { return null }
	local v=Vector(0,0,0)
	switch(orientation)
	{
		case "N":
			v=Vector(75,0,z); break;	//we were supposed to use 65 here, but we might hit the edged corner of a different wall, so we take a lil bit further
		case "E":
			v=Vector(0,-75,z); break;
		case "S":
			v=Vector(-75,0,z); break;
		case "W":
			v=Vector(0,75,z); break;
	}
	if (TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity()!=null)
	{
		if (ThisHas(TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName(),"x")) { return null }
		if (ThisHas(TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName(),"door")) { return null }
		
		local ourID=ent.GetName().slice(0,ent.GetName().find("_"))
		local theirID="0"
		if (ThisHas(TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName(),"_"))
		{
			theirID=TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName().slice(0,TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity().GetName().find("_"))
		}
		if (ourID!=theirID) { return null }
		if (ent==TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity()) { return null }
		return TraceLineComplex(ent.GetOrigin()+v,ent.GetOrigin()+v+Vector(0,0,1),ent,33570819,0).Entity()
	}
	return null
}

function KillWalls(vec1, vec2, entrance_type=1, room_type=0, room_type2=0)
{
	
	vec1.z=90
	vec2.z=90
	local first_wall = TraceLineComplex(vec1, vec2,self,33570819,0).Entity()
	local second_wall = TraceLineComplex(vec2, vec1,self,33570819,0).Entity()
	local inbetween = false
	if (first_wall==null&&second_wall==null) {return}
	if ((vec1-vec2).Length()<130) { inbetween = true }
	if (first_wall.GetClassname()=="prop_door_rotating") {return}
	if (second_wall.GetClassname()=="prop_door_rotating") {return}
	
	switch(entrance_type)
	{
		case 0:
		if (TraceLineComplex(vec1, vec2,self,33570819,0).DidHit()) { PlacePoint(first_wall,first_wall.GetOrigin(), first_wall.GetAngles().y); ; first_wall.Destroy();  };
		if ((second_wall!=first_wall)&&(ThisHas(second_wall.GetName(),"wall"))) 
		{ 
			PlacePoint(second_wall,second_wall.GetOrigin(), second_wall.GetAngles().y); 
			second_wall.Destroy()  
		};break
		case 1:
		if (TraceLineComplex(vec1, vec2,self,33570819,0).DidHit()) { Replace(first_wall,"doorway", inbetween); PlaceDoor(room_type, first_wall.GetOrigin(), first_wall.GetAngles().y,inbetween); first_wall.Destroy();  };
		if ((second_wall!=first_wall)&&(ThisHas(second_wall.GetName(),"wall"))) 
		{ 
			Replace(second_wall,"doorway", inbetween); 
			if (inbetween==false) { PlaceDoor(room_type2, second_wall.GetOrigin(), second_wall.GetAngles().y) }
			second_wall.Destroy()  
		}
	}
}

function SpawnPropDetail(name, pos = Vector(0,0,0), angles = 0, type=0)
{
	if (Entities.FindByNameWithin(null,"*door*",pos,86)) { return }
	local prop={ }
	local targetname="subwll"
	if (!ThisHas(name,"sub")) { targetname="map_detail" }
	//prop.static_only <- false
	for (local i=0;i<LIST_MAP_DETAIL.len();i++)
	{
		if (LIST_MAP_DETAIL[i].model==name) { prop = LIST_MAP_DETAIL[i] }
	}
	local S = {
	IDENTIFIER = "map_prop",
	angles = "0 "+angles+" 0",
	origin = pos.x+" "+pos.y+" "+pos.z,
	model = name,
	targetname = targetname,
	rendermode = 1,
	solid = 6,
	skin = type
	}
	SpawnEntityFromTable("prop_dynamic",S)
}

function PlaceMapDetail(rooms, room_info)
{
	for (local i = 1;i<=rooms;i++)
	{
		local x=room_info[i+"_StartX"]
		local y=room_info[i+"_StartY"]
		local w=(room_info[i+"_EndX"]-room_info[i+"_StartX"])/128
		local h=(room_info[i+"_EndY"]-room_info[i+"_StartY"])/128
		local tiles=w*h
		local type=room_info[i+"_Type"]
		local intensity=RandInt(3,7)
		local counter=0
		local subwall_intensity=1
		if (RandInt(1,10)>8) { subwall_intensity++ }
		for (local ix=0;ix<w;ix++)
		{
			for (local iy=0;iy<h;iy++)
			{
				if ((iy==0)||(ix==0)||(iy==h-1)||(ix==w-1)) //we place props on the sides and corners of the room first
				{
						counter++
						if ((counter%intensity)>intensity-2) { continue }
						local prop=LIST_MAP_DETAIL[RandInt(0,LIST_MAP_DETAIL.len()-1)]	//selecting prop and random position, if door is near then skip the tile
						
						local propx=RandInt(64+x+ix*128+prop.size.x/2,x+ix*128+128-prop.size.x/2-64)
						local propy=RandInt(64+y+iy*128+prop.size.y/2,y+iy*128+128-prop.size.y/2-64)
						
						local angles=DecideOrientation(RandInt(1,4),ix,iy,w,h)
						while (angles==(-1)) { angles=DecideOrientation(RandInt(1,4),ix,iy,w,h) }
						
						function RecalculateAnglesAndPos()
						{
							switch(angles)
								{
									case 0:
										propx=8.2+x+prop.size.x/2;break
									case 90:
										propy=8.2+y+prop.size.x/2;propx=RandInt(x+ix*128+prop.size.y/2,x+ix*128+128-prop.size.y/2);break
									case 180:
										propx=x+w*128-prop.size.x/2-8.2;break
									case 270:
										propy=128+y+iy*128-prop.size.x/2-8.2;propx=RandInt(x+ix*128+prop.size.y/2,x+ix*128+128-prop.size.y/2);break
								}
						}
						RecalculateAnglesAndPos()
						local offset=Vector(0,0,0)
						if (prop.symmetrical==false&&angles==0) { propy-=(propy+y)%128-56;offset.x=-8;offset.y=8 }
						if (prop.symmetrical==false&&angles==90) { propx-=(propx+x)%128-56;offset.y=-8;offset.x=8 }
						if (prop.symmetrical==false&&angles==180) { propy-=(propy+y)%128-56;offset.x=8;offset.y=8 }
						if (prop.symmetrical==false&&angles==270) { propx-=(propx+x)%128-56;offset.y=8;offset.x=8 }
						
						if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),196)) { continue }
						
						local realsize = PropSizeAtAngles(prop,angles)
					
						local hull = TraceHull(Vector(propx-realsize.x/2,propy-realsize.y/2,16.1),Vector(propx+realsize.x/2,propy+realsize.y/2,16.1+realsize.z))
						local retries=4	//we have only 4 tries to place a prop, if all failed, then choose another tile
						while (hull.DidHit()||propy>(y+h*128+5))
						{
							//if (ThisHas(hull.Entity().GetName(),"floor")) { debugoverlay.Box(Vector(propx-realsize.x/2,propy-realsize.y/2,16),Vector(0,0,0),Vector(realsize.x,realsize.y,realsize.z),255,25,250,20,15.25) }
							retries--
							//printl(hull.Entity())
							if (retries<0) { break }
							propx=RandInt(64+x+ix*128+prop.size.x/2,x+ix*128+128-prop.size.x/2-64)
							propy=RandInt(64+y+iy*128+prop.size.y/2,y+iy*128+128-prop.size.y/2-64)
							RecalculateAnglesAndPos()
							if (prop.symmetrical==false&&angles==0) { propy-=(propy+y)%128-56;offset.x=-8;offset.y=8 }
							if (prop.symmetrical==false&&angles==90) { propx-=(propx+x)%128-56;offset.y=-8;offset.x=8 }
							if (prop.symmetrical==false&&angles==180) { propy-=(propy+y)%128-56;offset.x=8;offset.y=8 }
							if (prop.symmetrical==false&&angles==270) { propx-=(propx+x)%128-56;offset.y=8;offset.x=8 }
							if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),196)) { continue }
							hull = TraceHull(Vector(propx-realsize.x/2,propy-realsize.y/2,16.1),Vector(propx+realsize.x/2,propy+realsize.y/2,16.1+realsize.z))
						}
						if (retries<1) { printl("Prop placement failed after 4 retries");continue }
						
						if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),196)) { continue }
						if (Entities.FindByNameWithin(null,"*dligh*",Vector(propx,propy,54),196)) { continue }
						local subwalls=0
						local wall=null
						while (wall=Entities.FindByClassnameWithin(wall,"prop_dynamic",Vector(propx,propy,80),182)) { if (wall.GetModelName()=="models/mapgen/subwall.mdl") { subwalls++ } }
						if (subwalls>=1) { continue }
						
						SpawnPropDetail(prop.model, Vector(propx,propy,16)+RotateVectorByAngle(prop.offset,angles)+offset, angles, type)
						debugoverlay.Box(Vector(propx-realsize.x/2,propy-realsize.y/2,16),Vector(0,0,0),Vector(realsize.x,realsize.y,realsize.z),10,255,10,20,3.25)
						//printl((propx-prop.offset.x+8)+" "+(x+w*128-realsize.x-16))
						if (prop.symmetrical==true)
						{
							if (angles==0) { angles+=180; propx+=w*128-realsize.x-16; SpawnPropDetail(prop.model, Vector(propx,propy,16)+RotateVectorByAngle(prop.offset,angles), angles, type); continue}
							if (angles==180) { angles+=180; propx-=w*128-16-realsize.x; SpawnPropDetail(prop.model, Vector(propx,propy,16)+RotateVectorByAngle(prop.offset,angles), angles, type); continue}
							if (angles==90) { angles+=180; propy+=h*128-realsize.x; SpawnPropDetail(prop.model, Vector(propx,propy,16)+RotateVectorByAngle(prop.offset,angles), angles, type); continue}
							if (angles==270) { angles+=180; propy-=h*128-realsize.x; SpawnPropDetail(prop.model, Vector(propx,propy,16)+RotateVectorByAngle(prop.offset,angles), angles, type); continue}
						}
				}
				else
				{
						counter++
						if ((counter%intensity)>intensity-2) { continue }
						local prop=LIST_MAP_DETAIL[RandInt(1,LIST_MAP_DETAIL.len()-1)]	//selecting prop and random position, if door is near then skip the tile
						
						local propx=64+x+ix*128
						local propy=64+y+iy*128
						
						local angles=0
						
						//if (prop.symmetrical==false&&angles==0) { propy-=(propy+y)%128-56 }
						//if (prop.symmetrical==false&&angles==90) { propx-=(propx+x)%128-56 }
						//if (prop.symmetrical==false&&angles==180) { propy-=(propy+y)%128-56 }
						//if (prop.symmetrical==false&&angles==270) { propx-=(propx+x)%128-56 }
						
						if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),196)) { continue }
						if (Entities.FindByNameWithin(null,"*dligh*",Vector(propx,propy,54),196)) { continue }
						
						local realsize = PropSizeAtAngles(prop,angles)
					
						local hull = TraceHull(Vector(propx-realsize.x/2,propy-realsize.y/2,16.1),Vector(propx+realsize.x/2,propy+realsize.y/2,16.1+realsize.z/2))
						local retries=4	//we have only 4 tries to place a prop, if all failed, then choose another tile
						while (hull.DidHit()||propy>(y+h*128+5))
						{
							//if (ThisHas(hull.Entity().GetName(),"floor")) { debugoverlay.Box(Vector(propx-realsize.x/2,propy-realsize.y/2,16),Vector(0,0,0),Vector(realsize.x,realsize.y,realsize.z),255,25,250,20,15.25) }
							retries--
							//printl(hull.Entity())
							if (retries<0) { break }
							propx=64+x+ix*128
							propy=64+y+iy*128
							//if (prop.symmetrical==false&&angles==0) { propy-=(propy+y)%128-56 }
							//if (prop.symmetrical==false&&angles==90) { propx-=(propx+x)%128-56 }
							//if (prop.symmetrical==false&&angles==180) { propy-=(propy+y)%128-56 }
							//if (prop.symmetrical==false&&angles==270) { propx-=(propx+x)%128-56 }
							
							if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),196)) { continue }
							if (Entities.FindByNameWithin(null,"*dligh*",Vector(propx,propy,54),196)) { continue }
						
							hull = TraceHull(Vector(propx-realsize.x/2,propy-realsize.y/2,16.1),Vector(propx+realsize.x/2,propy+realsize.y/2,16.1+realsize.z/2))
						}
						if (retries<1) { /*printl("Prop placement failed after 4 retries");*/continue }
						
						if (Entities.FindByNameWithin(null,"*door*",Vector(propx,propy,54),196)) { continue }
						if (Entities.FindByNameWithin(null,"*dligh*",Vector(propx,propy,54),196)) { continue }
						local subwalls=0
						local wall=null
						while (wall=Entities.FindByClassnameWithin(wall,"prop_dynamic",Vector(propx,propy,80),220)) { if (wall.GetModelName()=="models/mapgen/subwall.mdl") { subwalls++ } }
						if (subwalls>=subwall_intensity) { continue }
						
						SpawnPropDetail(prop.model, Vector(propx,propy,16)+RotateVectorByAngle(prop.offset,angles), angles, type)
						debugoverlay.Box(Vector(propx-realsize.x/2,propy-realsize.y/2,16),Vector(0,0,0),Vector(realsize.x,realsize.y,realsize.z),10,255,10,20,3.25)
						//printl((propx-prop.offset.x+8)+" "+(x+w*128-realsize.x-16))
				}
			}
		}
	}
}