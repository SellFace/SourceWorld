function DirectionToAngle(direction)
{
	switch(direction)
	{
		case 1: return 0; break;
		case 2: return 90; break;
		case 4: return 180; break;
		case 8: return 270; break;
	}
}

function DecidePropAngleAndDir(walls,alignment,offset=0)
{
	local wallarray=[]
	if (walls&1) wallarray.append(1)	// east
	if (walls&2) wallarray.append(2)	// north
	if (walls&4) wallarray.append(4)	// west
	if (walls&8) wallarray.append(8)	// south
	
	if (alignment==0||walls==0) return [RandInt(0,359),-1];
	local Direction=wallarray[RandInt(0,wallarray.len()-1)]
	local Angle=DirectionToAngle(Direction)+180 //Because prop needs to face the opposite way
	
	if (alignment==1) Angle+=(RandInt(-30,30)+RandInt(-30,30))/2
	Angle=AngleNormalize(Angle)
	return [Angle,Direction]
}

function RollPropAlignment()
{
	local Roll=RandFloat(0,1)
	if (Roll<0.08) return 0
	if (Roll<0.40) return 1
	return 2
}

function PropSizeAtAngles(prop,angles) // this is a crappy way of tracing bounding boxes, but i guess it's better than nothing
{
	local sizex=prop.size.x
	local sizey=prop.size.y
	
	local rsizex=fabs(sizex*cos(angles/180.0*PI)) + fabs(sizey*sin(angles/180.0*PI))
	local rsizey=fabs(sizex*sin(angles/180.0*PI)) + fabs(sizey*cos(angles/180.0*PI))
	return Vector(fabs(rsizex),fabs(rsizey),prop.size.z)
}

function DecidePropPos(MinPos,MaxPos,Size,Direction)
{
	local PropX1=MinPos.x+Size.x/2
	local PropX2=MaxPos.x-Size.x/2
	local PropY1=MinPos.y+Size.y/2
	local PropY2=MaxPos.y-Size.y/2
	
	switch(Direction)
	{
		case 1: PropX1=PropX2; break;
		case 4: PropX2=PropX1; break;
		case 8: PropY2=PropY1; break;
		case 2: PropY1=PropY2; break;
		default: break;
	}
	
	local PropX=RandInt(PropX1,PropX2)
	local PropY=RandInt(PropY1,PropY2)
	
	return [PropX,PropY]
}

function TagsMatch(prop,tags)
{
	if (tags.len()==0) return true;
	
	if (!("tags" in prop)) return false;
	
	foreach (tag in tags)
	{
		if (prop.tags.find(tag)!=null) return true
	}
	return false;
}

function UnpackPropzone(Propzone,Ents)	//Pass propzone table and Entities array to add props to.
{
	if (!("origin" in Propzone)) Propzone.rawset("origin","0 0 0");
	
	local Center=ToVector(Propzone.origin)
	local Area=ToVector(Propzone.size_maxs)-ToVector(Propzone.size_mins)
	local MinPos=Center+ToVector(Propzone.size_mins)
	local MaxPos=Center+ToVector(Propzone.size_maxs)
	local Walls=(Propzone.spawnflags).tointeger()
	
	local TakenHulls=[]
	local Attempts=0
	
	local Prop=null;
	local PropIndex=null;
	local PropsList = (clone LIST_PROPS)
	
	local AngleOffset=0;
	
	local FreeZone=Area.x*Area.y;
	
	const MIN_SPACE=0.2	//Percentage of minimum free area after which we can consider zone as being full.
	
	local Tags=null
	if ("prop_tags" in Propzone) Tags=Propzone.prop_tags;
	
	if (!Tags||Tags=="") Tags=[];
	else Tags=split(Tags,",");
	
	while (Attempts<50&&(FreeZone*Propzone.intensity.tofloat()*0.25>(Area.x*Area.y*MIN_SPACE)))
	{
		Attempts++
		
		local RolledAlignment=RollPropAlignment()
		if (RolledAlignment!=0&&Walls==0) RolledAlignment=0;
		
		PropIndex=RandInt(0,PropsList.len()-1)
		Prop=PropsList[PropIndex]
		
		while ((Prop.alignment>RolledAlignment)||(Prop.size.x>Area.x||Prop.size.y>Area.y||Prop.size.y>Area.x||Prop.size.x>Area.y||Prop.size.z>Area.z)||("repeat_up" in Prop)||(!TagsMatch(Prop,Tags))) {
			if (PropsList.len()==0) return;
			
			PropsList.remove(PropIndex)
			
			if (PropsList.len()==0) return;
			
			PropIndex=RandInt(0,PropsList.len()-1)
			Prop=PropsList[PropIndex]
		}
		
		if (("extra_yaw" in Prop)&&(RandInt(0,1)==1)) AngleOffset=Prop.extra_yaw;
		
		local AngleDir=DecidePropAngleAndDir(Walls,RolledAlignment,AngleOffset)
		local angles=AngleDir[0]
		local PropDirection=AngleDir[1]
		local PropSize=PropSizeAtAngles(Prop,angles)
		
		if (!("static_only" in Prop)) PropSize.x+=8
		if (!("static_only" in Prop)) PropSize.y+=8
		if (!("static_only" in Prop)) PropSize.z+=2
		
		local PropPos=DecidePropPos(MinPos,MaxPos,PropSize,PropDirection)
		local PropX=PropPos[0]
		local PropY=PropPos[1]
		
		local PropHull=[Vector(PropX,PropY,MinPos.z+Prop.size.z/2)+PropSize/2,Vector(PropX,PropY,MinPos.z+Prop.size.z/2)-PropSize/2]
		
		local PropOverlap=false;
		foreach (Hull in TakenHulls)
		{
			if (CheckHullOverlap(PropHull[0],PropHull[1],Hull[0],Hull[1])) {PropOverlap=true;break}
		}
		if (PropOverlap) continue;
		TakenHulls.append(PropHull)
		
		local PropTable={
			classname=("static_only" in Prop) ? "prop_dynamic" : "prop_physics",
			origin=(Vector(PropX,PropY,MinPos.z)+RotateVectorYaw(Prop.offset,angles)).ToKVString()
			angles=Vector(0,AngleDir[0],0).ToKVString()
			model=Prop.model
			solid=6
			ResponseContext="direction:"+PropSize.x+"_"+PropSize.y+"_"+PropSize.z
		}
		Ents.append(PropTable)
		
		FreeZone-=PropSize.x*PropSize.y
		
		Attempts=0;
	}
}