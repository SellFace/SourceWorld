IncludeScript("vs_math.nut")
self.PrecacheSoundScript("Menu.On")
self.PrecacheSoundScript("Menu.Off")

local playeryaw=0


function GetOrCreateScriptScope(file)
{
	if (Entities.FindByName(null, file.slice(0,file.find(".")))==null)
	{
		//printf("Script not found. Spawning...");
		local S = {
		targetname = file.slice(0,file.find(".")),
		vscripts = file,
		thinkfunction="Think"
		origin = [0, 0, 0]
		}
		local script=SpawnEntityFromTable("logic_script",S)
		//printl("creating! "+file.slice(0,file.find(".")))
		return script.GetOrCreatePrivateScriptScope()
	}
	return Entities.FindByName(null, file.slice(0,file.find("."))).GetOrCreatePrivateScriptScope()
}

if (CLIENT_DLL)
{

local panelbg=null
local panel=null

local MinX=0x10000
local MaxX=-0x10000
local MinY=0x10000
local MaxY=-0x10000

local Lines=[]
local ScreenLines={}
local SocketLines=[]
local Hulls={}
local Ents=[]
local Objs=[]
local ObjFloors={}

local ExploredTiles=[]
local Floors={}

function GetMapPositionX(Originx,Center=null)
{
	//if (Convars.GetFloat("sourceworld_minimap_range")<10) {Center=player.GetOrigin()}
	//
	//if (Center==null) return RemapVal(Originx,MinX-8,MaxX+8,0,panel.GetWide());
	//else return RemapVal(Originx,Center.x-450,Center.x+450,0,panel.GetWide());
	
	
	return RemapVal(Originx,MinX-8,MaxX+8,0,YRES(400));
}
function GetMapDist(Dist)
{
	local Addendum=0
	if (Convars.GetFloat("sourceworld_minimap_range")<10) {Addendum=YRES(50);return RemapVal(Dist,0,1100,0,panel.GetWide()+Addendum*2)}
	return RemapVal(Dist,0,MaxX-MinX+16,0,panel.GetWide()+Addendum*2)
}
function GetMapPositionY(Originy,Center=null)
{
	//if (Convars.GetFloat("sourceworld_minimap_range")<10) {Center=player.GetOrigin()}
	//
	//if (Center==null) return RemapVal(Originy,MinY-8,MaxY+8,panel.GetTall(),0);
	//else return RemapVal(Originy,Center.y-450,Center.y+450,panel.GetTall(),0);
	
	return RemapVal(Originy,MinY-8,MaxY+8,YRES(400),0);
}
function GetMapPosition(Origin)
{
	return [GetMapPositionX(Origin.x),GetMapPositionY(Origin.y)]
}
function IsOriginInBBox(origin,minv,maxv)
{
	//check if origin is within a 3-dimensional box by checking interval overlapping on every axis
	if (origin.x>minv.x&&origin.x<maxv.x) if (origin.y>minv.y&&origin.y<maxv.y)
	{
		return true
	}
	return false
}
function IsOriginInBBox3D(origin,minv,maxv)
{
	//check if origin is within a 3-dimensional box by checking interval overlapping on every axis
	if (origin.x>minv.x&&origin.x<maxv.x) if (origin.y>minv.y&&origin.y<maxv.y) if (origin.z>minv.z&&origin.z<maxv.z)
	{
		return true
	}
	return false
}
function IsInsideTileHull(x,y,id)
{
	//printl(x+"  "+Hulls[id.tostring()][0].x+"  -  "+Hulls[id.tostring()][1].x)
	return IsOriginInBBox(Vector(x,y),Hulls[id.tostring()][0]-Vector(4,4),Hulls[id.tostring()][1]+Vector(4,4))
}
function IsInsideTileHull3D(x,y,id)
{
	//printl(x+"  "+Hulls[id.tostring()][0].x+"  -  "+Hulls[id.tostring()][1].x)
	return IsOriginInBBox3D(Vector(x,y),Hulls[id.tostring()][0]-Vector(4,4),Hulls[id.tostring()][1]+Vector(4,4))
}
function GetHullFromPoint(x,y)
{
	foreach (id,hull in Hulls)
	{
		if (IsInsideTileHull(x,y,id)) 
		{
			//printl(id)
			return id;
		}
	}
	return -1
}

function GetPointZ(pos)
{
	//printl("getting z of "+pos)
	foreach (id,hull in Hulls)
	{
		if (IsOriginInBBox3D(pos,Hulls[id.tostring()][0]-Vector(4,4,4),Hulls[id.tostring()][1]+Vector(4,4,4))) 
		{
			//printl(Floors[id.tointeger()])
			return Floors[id.tointeger()]
		}
	}
	return 0
}

function IsPointExploredOLD(x,y)
{
	foreach (id,hull in Hulls)
	{
		if (ExploredTiles.find(id)==null) continue;
		
		if (IsInsideTileHull(x,y,id))
		{
			return true
		}
	}
	return false
}

function IsPointExplored(x,y)	//Much faster than the one above.
{
	if (Hulls.len()==ExploredTiles.len()) return true;
	
	for (local i=0;i<ExploredTiles.len();i++)
	{
		//if (ExploredTiles.find(id.tointeger())==null) continue;
		if (IsInsideTileHull(x,y,ExploredTiles[i]))
		{
			return true
		}
	}
	return false
}

local LastLineMsg=Time()+0x10000
local MapInfoSent=false

NetMsg.Receive("MAPGEN_LINE", function() {
	local TotalLines=NetMsg.ReadShort()
	local TileID=NetMsg.ReadShort()
	local p1=NetMsg.ReadVec3Coord()
	local p2=NetMsg.ReadVec3Coord()
	if (Lines.len()>TotalLines+256) return;
	
	if (min(p1.x,p2.x)<MinX) MinX=min(p1.x,p2.x)
	if (max(p1.x,p2.x)>MaxX) MaxX=max(p1.x,p2.x)
		
	if (min(p1.y,p2.y)<MinY) MinY=min(p1.y,p2.y)
	if (max(p1.y,p2.y)>MaxY) MaxY=max(p1.y,p2.y)
		
	local MaxDist=max(MaxX-MinX,MaxY-MinY)
	MaxX=MinX+MaxDist
	MaxY=MinY+MaxDist
	//Make sure that distances between both axis are the same. We want to render the map as square.

	Lines.append([p1,p2,TileID])
	LastLineMsg=Time()
	//printl("received a signal L")
}.bindenv(this))

NetMsg.Receive("MAPGEN_SOCKET", function() {
	local TotalLines=NetMsg.ReadShort()
	local TileID=NetMsg.ReadByte()
	local TileNext=NetMsg.ReadByte()
	local OnlyVertical=NetMsg.ReadBool()
	local p1=NetMsg.ReadVec3Coord()
	local p2=NetMsg.ReadVec3Coord()
	if (Lines.len()>TotalLines+256) return;
	
	if (min(p1.x,p2.x)<MinX) MinX=min(p1.x,p2.x)
	if (max(p1.x,p2.x)>MaxX) MaxX=max(p1.x,p2.x)
		
	if (min(p1.y,p2.y)<MinY) MinY=min(p1.y,p2.y)
	if (max(p1.y,p2.y)>MaxY) MaxY=max(p1.y,p2.y)
		
	local MaxDist=max(MaxX-MinX,MaxY-MinY)
	MaxX=MinX+MaxDist
	MaxY=MinY+MaxDist
	//printl("received a signal S")
	//Make sure that distances between both axis are the same. We want to render the map as square.

	SocketLines.append([p1,p2,TileID,TileNext,OnlyVertical])
	LastLineMsg=Time()
}.bindenv(this))

NetMsg.Receive("MAPGEN_LINE_COLORED", function() {
	local TotalLines=NetMsg.ReadShort()
	local TileID=NetMsg.ReadShort()
	local p1=NetMsg.ReadVec3Coord()
	local p2=NetMsg.ReadVec3Coord()
	local c=NetMsg.ReadVec3Coord()
	if (Lines.len()>TotalLines+256) return;
	
	if (min(p1.x,p2.x)<MinX) MinX=min(p1.x,p2.x)
	if (max(p1.x,p2.x)>MaxX) MaxX=max(p1.x,p2.x)
		
	if (min(p1.y,p2.y)<MinY) MinY=min(p1.y,p2.y)
	if (max(p1.y,p2.y)>MaxY) MaxY=max(p1.y,p2.y)
		
	local MaxDist=max(MaxX-MinX,MaxY-MinY)
	MaxX=MinX+MaxDist
	MaxY=MinY+MaxDist
	//printl("received a signal LC")
	//Make sure that distances between both axis are the same. We want to render the map as square.

	Lines.append([p1,p2,TileID,c])
	LastLineMsg=Time()
}.bindenv(this))

NetMsg.Receive("MAPGEN_HULL", function() {
	local TileID=NetMsg.ReadShort()
	local p1=NetMsg.ReadVec3Coord()
	local p2=NetMsg.ReadVec3Coord()
	
	local mins=Vector(min(p1.x,p2.x),min(p1.y,p2.y),min(p1.z,p2.z))
	local maxs=Vector(max(p1.x,p2.x),max(p1.y,p2.y),max(p1.z,p2.z))

	local h1=Vector(mins.x,mins.y,mins.z)
	local h2=Vector(maxs.x,maxs.y,maxs.z)
	//printl("received a signal H")

	printl("TOTAL RADAR OBJECTS: "+Objs.len())

	Hulls.rawset(TileID.tostring(),[h1,h2])
}.bindenv(this))
local PlayerZ=0
local PlayerRoom=0
NetMsg.Receive("MAPGEN_PLAYER_Z", function() {
	PlayerZ=NetMsg.ReadFloat()
	PlayerRoom=NetMsg.ReadShort()
}.bindenv(this))

NetMsg.Receive("MAPGEN_Z", function() {
	local TileID=NetMsg.ReadShort()
	local Z=NetMsg.ReadFloat()
	Floors.rawset(TileID,Z)
}.bindenv(this))

NetMsg.Receive("MAPGEN_PROP", function() {
	local entIndex=NetMsg.ReadShort()
	//printl("GOT PROP")
	//printl("received a signal P")
	if (Ents.find(entIndex)==null) 
		Ents.append(entIndex);
}.bindenv(this))

NetMsg.Receive("MAPGEN_EXPLORATION", function() {
	local CurTile=NetMsg.ReadShort()
	//printl("received a signal E")
	//printl("GOT EXPLORED WITH "+CurTile)
	//printl(ExploredTiles.len())
	if (ExploredTiles.find(CurTile)==null)
		ExploredTiles.append(CurTile);
	//printl(ExploredTiles.len())
}.bindenv(this))

NetMsg.Receive("MAPGEN_GATHER_OBJECTS", function() {

	local entSearch=null
	while (entSearch=Entities.FindByClassname(entSearch,"*"))
	{
		if (entSearch&&entSearch.GetClassname().find("_AI")!=null&&Objs.find(entSearch.entindex())==null) Objs.append(entSearch.entindex());
		//if (entSearch&&entSearch.GetClassname().find("Door")!=null&&Objs.find(entSearch.entindex())==null) Objs.append(entSearch.entindex());
		if (entSearch&&entSearch.GetName().find("portal_warp")!=null&&Objs.find(entSearch.entindex())==null) Objs.append(entSearch.entindex());
		
		//ObjFloors.append(GetPointZ(entSearch.GetOrigin()))
	}
	
	printl("TOTAL RADAR OBJECTS: "+Objs.len())
}.bindenv(this))

function RotateVectorYaw(origin1,yaw)
{
	local x1=origin1.x
	local y1=origin1.y
	
	origin1.x=x1*cos(yaw/180.0*PI)-y1*sin(yaw/180.0*PI)
	origin1.y=y1*cos(yaw/180.0*PI)+x1*sin(yaw/180.0*PI)
	
	return origin1
}
RotateVector<-function(A,B,RotatedByAngle=Vector()){local m=VS.matrix3x4_t();VS.AngleMatrix(B,Vector(),m);return VS.VectorRotate(A,m)}
function cross(a, b) {
    return a.x*b.y - a.y*b.x;
}




if (CLIENT_DLL)
{

	::OBJECTIVES<-[]

	class Objective
	{
		ID=null
		DisplayName=""
		Description=""
		Status=false;
		Reward=0;
		CompletionTime=null;

		constructor(id)
		{
			switch(id)
			{
				case 1: {DisplayName="Exploration";Description="Explore the area.";Reward=250;break}
				case 2: {DisplayName="Rescue";Description="Find and rescue the lost scientist by bringing them to exit portal.";Reward=400;break}
				case 3: {DisplayName="Elimination";Description="Eliminate all hostiles in the area.";Reward=350;break}
				case 4: {DisplayName="Search";Description="Find intel case.";Reward=300;break}
			}
			ID=id;
		}
		
		
	}

	function AddObjective(id)
	{
		foreach (o in OBJECTIVES) if (o.ID==id)
		{
			printl("ERROR: Tried adding an already existing objective "+id)
			return;
		}
		// can't add duplicate objectives.
		
		OBJECTIVES.append(Objective(id))
	}

	function CompleteObjective(id)
	{
		local obj=null
		foreach (o in OBJECTIVES) if (o.ID==id) obj=o;
		
		if (obj==null)
		{
			printl("ERROR: Couldn't complete missing objective "+id)
			return
		}
		obj.Status=true;
		obj.CompletionTime=Time();
		surface.PlaySound("ui/bigreward.wav")
	}
	
	
	NetMsg.Receive("OBJECTIVE_ADD", function() {
		local ID=NetMsg.ReadShort()
		
		AddObjective(ID)
		
	}.bindenv(this))
	
	NetMsg.Receive("OBJECTIVE_COMPLETE", function() {
		local ID=NetMsg.ReadShort()
		
		CompleteObjective(ID)
		
	}.bindenv(this))
	
	surface.CreateFont( "Objective3",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 18        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	surface.CreateFont( "ObjectiveS3",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 18        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        "blur"            : 3        // Amount of blur to add (optional)
		"scanlines"	:	2
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );

}







local Props=array(0x1000)
local Doors=array(0x1000)
local PropsLast=array(0x1000)

function MinimapInit()
{
	//printl("hi")
	if (CLIENT_DLL)
	{
	
		Convars.RegisterConvar( "sourceworld_minimap_size" "1", "1 minimap_size", FCVAR_NONE )
		Convars.RegisterConvar( "sourceworld_minimap_range" "6", "1 minimap_range", FCVAR_NONE )
		//printl("HII")
		//printl("HII")
		//local Level=array(MAP_GRID_SIZE)
		
		//if (SERVER_DLL) GetLevelMatrix();
		
		//local LevelData=Entities.FindByName(null,"mapgen/layout").GetOrCreatePrivateScriptScope().Level
		
		//printmap()
		local ROOMCOLORS={}
		IncludeScript("rng_seed.nut")
		local texture=surface.ValidateTexture("vgui/cursors/arrow",true,true,true)
		local texturestair_up=surface.ValidateTexture("vgui/cursors/icon_arrow",true,true,true)
		local texturestair_down=surface.ValidateTexture("sellface-icons/sw_exit",true,true,true)
		local size=Convars.GetFloat("sourceworld_minimap_size");
		local range=Convars.GetFloat("sourceworld_minimap_range");
		local AlphaMultiplier=0.75
		
		local LastMapOpenTime=-1;
		
		// Praying with my whole existence for a day
		// When all VScript memory leaks are gonna be fixed.
		
		// Prayers have been answered.
		// Mister Sam has fixed all leaks.
		
		
		function DrawProperLine(a,b,c,d,thickness=1)
		{
			//surface.DrawLine(a,b,c,d); return;
			//surface.DrawLine(a,b,c,d);
			
			if (thickness==1)
			{
				surface.DrawLine(a,b,c,d);
				return
			}
			
			surface.DrawLine(a,b,c,d);
			for (local i=1;i<thickness;i++)
			{			
				if (abs(a-c)<2)
				{
					surface.DrawLine(a+i,b,c+i,d);
					surface.DrawLine(a-i,b,c-i,d);
				}
				else
				{
					surface.DrawLine(a,b+i,c,d+i);
					surface.DrawLine(a,b-i,c,d-i);
				}
			}
		}
		
		function Paint()
		{
			//return
		
			if (FrameTime()==0) return;
			//if (FrameTime()) return;
			//Don't render in pause. 
			
			
			if (!MapInfoSent) if ((Time()-LastLineMsg)>0.25)
			{
				MapInfoSent=true
			}
			
			//printl(Level)
			size=Convars.GetFloat("sourceworld_minimap_size");
			range=Convars.GetFloat("sourceworld_minimap_range");
			if (Convars.GetFloat("sourceworld_hud")==2||player.GetHealth()<=0) 
			{
				panel.SetPaintBackgroundEnabled(false)
				panelbg.SetAlpha(0)
				return
			}
			panel.SetPaintBackgroundEnabled(true)
			//panelbg.SetAlpha(255)

			surface.SetColor(5, 255, 57, 255)
			surface.SetTexture(texture)
			
			local playerx=GetMapPositionX(player.GetOrigin().x)
			local playery=GetMapPositionY(player.GetOrigin().y)
		
			
			local offsetx=0
			local offsety=0
			
			if (range<10)
			{
				offsetx=playerx-panel.GetWide()/2
				offsety=playery-panel.GetTall()/2
			}
			
			local size=GetMapDist(32)*1.5
			local staticsize=GetMapDist(32)*1.5
			
			if (range>10) size=size*clamp(10-(Time()-LastMapOpenTime)*20,1.5,10)*(1.5+sin(Time()*4)/2.0)
			
			surface.DrawTexturedRectRotated(playerx-size/2-offsetx,playery-size/2-offsety,size,size,MainViewAngles().y-135)
			
			surface.SetColor(5, 175, 255, 255)
			
			//printl(Lines.len())
			
			//local TotalDrawn=0
			
			//foreach (hull in Hulls)
			//{
			//	surface.DrawLine(GetMapPositionX(hull[0]),GetMapPositionY(hull[0]),GetMapPositionX(hull[1]),GetMapPositionY(hull[1]))
			//	printl(GetHullFromPoint(((hull[0]+hull[1])/2).x,((hull[0]+hull[1])/2).y))
			//}
			
			local InvisRooms=[]
			
			foreach (i,Line in Lines)
			{

				if (InvisRooms.find(Line[2])!=null) continue;
			
				local playerorigin=player.GetOrigin()
				
				if (ExploredTiles.find(Line[2])==null) {InvisRooms.append(Line[2]);continue;}	// Don't draw lines from unexplored tiles
				if (Line[2] in Floors&&fabs(Floors[Line[2]]-PlayerZ)>0.5) {InvisRooms.append(Line[2]);continue;}	// Don't draw lines from unexplored tiles
				
				//if (range<10&&max((playerorigin-Line[0]).Length(),(playerorigin-Line[1]).Length())>(650+(Line[0]-Line[1]).Length())) continue;
				// Don't draw far lines when in minimap mode
				
				//local HeightDif=((Line[0].z+Line[1].z)/2-playerorigin.z)
				local HeightDif=255
				//HeightDif=abs(HeightDif)
				//HeightDif=clamp(RemapVal(HeightDif,100,120,255,0),0,255)
				//HeightDif=255-clamp((HeightDif-100)*12.75,0,255)
				// Calculate height difference for dynamic alpha
				
				local l1x=null
				local l1y=null
				local l2x=null
				local l2y=null
				
				surface.SetColor(5, 175, 255, HeightDif)
				if (!(i in ScreenLines))
				{
					l1x=(GetMapPositionX(Line[0].x))
					l1y=(GetMapPositionY(Line[0].y))
					l2x=(GetMapPositionX(Line[1].x))
					l2y=(GetMapPositionY(Line[1].y))
					if (Time()>5) ScreenLines.rawset(i,[Vector(l1x,l1y),Vector(l2x,l2y)])
					//printl("Storing minimap data for line "+i)
				}
				else
				{
					l1x=ScreenLines[i][0].x
					l1y=ScreenLines[i][0].y
					l2x=ScreenLines[i][1].x
					l2y=ScreenLines[i][1].y
				}
				
				local RadarSize=panel.GetWide()
				
				if (range<10&&( min(abs(playerx-l1x),abs(playerx-l2x))>RadarSize&&min(abs(playery-l1y),abs(playery-l2y))>RadarSize ))
				{
					continue
				}

				l1x-=offsetx
				l1y-=offsety
				l2x-=offsetx
				l2y-=offsety
				

					
				//local l2x=l1x*1.1
				//local l2y=l1x*1.2
				//continue
				local thickness=1
				if (Line.len()>3) surface.SetColor(Line[3].x, Line[3].y, Line[3].z, HeightDif)
				if (Line.len()>3&&Line[3].z>100) thickness=3;
				
				DrawProperLine(l1x,l1y,l2x,l2y,thickness)
				//continue
				// Draw a line.
				
				surface.SetColor(3, 105, 155, HeightDif)
				if (Line.len()>3) surface.SetColor(Line[3].x*0.7, Line[3].y*0.7, Line[3].z*0.7, HeightDif)
				if (range<10) DrawProperLine(l1x+1,l1y+1,l2x+1,l2y+1,1)
				// When in minimap mode, draw another line acting as shadow to the previous one.
			}
			//printl(TotalDrawn)
			//printl(TotalDrawn)
			//surface.DrawLine(GetMapPositionX(Vector(MinX,0,0)),GetMapPositionY(Vector(0,MinY,0)),GetMapPositionX(Vector(MaxX,0,0)),GetMapPositionY(Vector(0,MaxY,0)))
			//surface.DrawLine(GetMapPositionX(Vector(MinX,0,0)),GetMapPositionY(Vector(0,MaxY,0)),GetMapPositionX(Vector(MaxX,0,0)),GetMapPositionY(Vector(0,MinY,0)))
			
			//printl((player.GetAngles().y))
			//surface.DrawTexturedRectRotated(XRES(5*size)+XRES(5*size)*differencey,XRES(5*size)+XRES(5*size)*differencex,XRES(5*size),XRES(5*size),(((playeryaw-135)/22.5+rounder).tointeger())*22.5)
			surface.SetColor(5, 175, 255, 255)
			//surface.DrawTexturedRectRotated(XRES(5*size)*(offset)+XRES(5*size)*differencex,XRES(5*size)*(offset)+XRES(5*size)*differencey,XRES(5*size),XRES(5*size),MainViewAngles().y-135)
			//return
			
			
			local enemy=null
			local MapDist=staticsize/3.0
			//printl(Lines.len())
			foreach (i,ent_i in Objs)
			{
				enemy=EntIndexToHScript(ent_i)
				if (!enemy) continue;
				local Origin=enemy.GetOrigin()
				
				if (range<10&&(player.GetOrigin()-enemy.GetOrigin()).Length()>700) if (enemy.GetName().find("portal_warp")==null) continue;
				
				if (enemy.GetClassname().find("_AI")!=null&&enemy.GetName()=="Richard")
				{
					
					//if (!IsPointExplored(Origin.x,Origin.y)) continue;
					
					local enemyx=GetMapPositionX(Origin.x)-offsetx
					local enemyy=GetMapPositionY(Origin.y)-offsety
					
					//local size=GetMapPositionX(Origin.x+48)-offsetx-enemyx
					
					//local HeightDif=255
					
					surface.SetColor(20, 135, 240, 255)
					
					if (enemy.GetBoundingMaxs().z<70&&(Time()-Time().tointeger())<0.5) surface.SetColor(255, 45, 45, 255) 
					
					surface.DrawTexturedRectRotated(enemyx-size/2,enemyy-size/2,size,size,enemy.GetAngles().y-135);
					continue
				}
				
				if (!IsPointExplored(Origin.x,Origin.y)) continue;
				
				if (ent_i in ObjFloors)
				{
					if (fabs(ObjFloors[ent_i]-PlayerZ)>0.5) continue;	// Don't draw lines from unexplored tiles)
				}
				else
				{
					ObjFloors.rawset(ent_i,GetPointZ(Origin))
					if (fabs(GetPointZ(Origin)-PlayerZ)>0.5) continue;	// Don't draw lines from unexplored tiles
				}
				
				
				
				
				if (enemy.GetName().find("portal_warp")!=null)
				{
					//if (!IsPointExplored(Origin.x,Origin.y)) continue;
					local enemyx=GetMapPositionX(Origin.x)-offsetx
					local enemyy=GetMapPositionY(Origin.y)-offsety
					
					//local size=GetMapPositionX(Origin.x+64)-offsetx-enemyx
					
					surface.SetColor(255, 255, 255, 150+sin(Time()*2)*105)
					surface.SetTexture(texturestair_down)
					surface.DrawTexturedRectRotated(clamp(enemyx-size/2,0,panel.GetWide()-size),clamp(enemyy-size/2,size/2,panel.GetTall()-size),size,size,0);
					continue
				}
				
				/*
				if (enemy.GetClassname().find("Door")!=null)
				{
					//if (!IsPointExplored(Origin.x,Origin.y)) continue;
					local enemyx=(GetMapPositionX(Origin.x))-offsetx
					local enemyy=(GetMapPositionY(Origin.y))-offsety
					
					local Side=Origin+(enemy.GetCenter()-Origin)*2
					
					local enemyx2=(GetMapPositionX(Side.x))-offsetx
					local enemyy2=(GetMapPositionY(Side.y))-offsety
					
					local HeightDif=255
					
					
					surface.SetColor(35, 255, 40, HeightDif)
					
					surface.DrawLine(enemyx,enemyy,enemyx2,enemyy2);
					surface.DrawLine(enemyx+1,enemyy,enemyx2+1,enemyy2);
					surface.DrawLine(enemyx,enemyy+1,enemyx2,enemyy2+1);
					surface.DrawLine(enemyx+1,enemyy+1,enemyx2+1,enemyy2+1);
					continue
				}
				*/
				
				//continue
			}
			
			//printl(PlayerZ)
			//printl(PlayerRoom)
			
			foreach (i,Line in SocketLines)
			{		
				local playerorigin=player.GetOrigin()
				
				local vertical=false
				local GoesDown=false
				local UnExplored=false
				
				if (ExploredTiles.find(Line[2])==null) continue
				
				local nextfloor=Floors[Line[3]]
				foreach(id,h in Hulls)
				{
					if (Floors[Line[2]]!=Floors[Line[3]]&&Floors[id.tointeger()]==nextfloor&&(fabs(PlayerZ-Floors[Line[2]])>0.5||fabs(PlayerZ-Floors[Line[3]])>0.5))
					{
						vertical=true;
						if (ExploredTiles.find(id.tointeger())==null) 
							UnExplored=true;
						if (PlayerZ>=Floors[Line[2]])
							GoesDown=true;
					}
				}
				
				if (ExploredTiles.find(Line[3])!=null&&!vertical) continue
				
				
				if (Line[2] in Floors&&fabs(Floors[Line[2]]-PlayerZ)>0.5) continue;
				
				if (range<10&&max((playerorigin-Line[0]).Length2D(),(playerorigin-Line[1]).Length2D())>(1000+(Line[0]-Line[1]).Length2D())) continue;
				// Don't draw far lines when in minimap mode
				
				local HeightDif=255
				// Calculate height difference for dynamic alpha

				surface.SetColor(255,255-vertical.tointeger()*100,0, HeightDif*fabs(sin(Time()*2)))
				
				local l1x=(GetMapPositionX(Line[0].x))-offsetx
				local l1y=(GetMapPositionY(Line[0].y))-offsety
				local l2x=(GetMapPositionX(Line[1].x))-offsetx
				local l2y=(GetMapPositionY(Line[1].y))-offsety
				
				if (vertical)
				{
					if (range>=10) size=staticsize*2
				
				
					local MidPointX=(l1x+l2x)/2
					local MidPointY=(l1y+l2y)/2
					
					if (UnExplored) surface.SetColor(255,255,0, HeightDif*fabs(sin(Time()*2)))
					else surface.SetColor(255,255,255, HeightDif*fabs(sin(Time()*2)))
				
					local Downer=(size/4)
					if (GoesDown) Downer*=sin(Time()*2)
					else Downer*=cos(Time()*2)
				
					surface.SetTexture(texturestair_up)
					surface.DrawTexturedRectRotated(MidPointX-size/2,MidPointY-size/2+Downer,size,size,180*GoesDown.tointeger());
				}
				else DrawProperLine(l1x,l1y,l2x,l2y,6);
				// Draw a line.
				
				// When in minimap mode, draw another line acting as shadow to the previous one.
			}

			
			//enemy=null
			
			//printl(Ents.len())
			
			//foreach (i,entindex in Ents)
			//{
			//	//if (range>10) break
			//	local ent=EntIndexToHScript(entindex)
			//	if (!ent) {Ents.remove(Ents.find(entindex));i--;continue}
			//	
			//	local Origin=ent.GetOrigin()
			//	
			//	if (!IsPointExplored(Origin.x,Origin.y)) continue;
			//	
			//	local Angles=ent.GetAngles()
			//	local Mins=ent.GetBoundingMins()
			//	local Maxs=ent.GetBoundingMaxs()
			//	
			//	local HeightDif=(Origin.z-player.GetOrigin().z)
			//	HeightDif=abs(HeightDif)
			//	HeightDif=clamp(RemapVal(HeightDif,100,120,255,0),0,255)
			//	
			//	
			//	
			//	if (((player.GetOrigin()-Origin+Maxs).Length()>700&&range<10)||HeightDif<240) continue;
			//	
			//	
			//	local Prop=[]
			//	local PropV=array(4)
			//	
			//	
			//	
			//	surface.SetColor(35, 255, 40, 255)
			//	if (PropsLast[entindex]!=null&&(PropsLast[entindex]-Vector(Origin.x,Origin.y)).Length()>0||Props[entindex]==null)
			//	{
			//		// Vector rotations leak like crazy. get a proper codebase with fix!
			//		Prop.append(Origin+RotateVector(Vector(Mins.x,Mins.y,Mins.z),Angles))
			//		Prop.append(Origin+RotateVector(Vector(Mins.x,Maxs.y,Mins.z),Angles))			
			//		Prop.append(Origin+RotateVector(Vector(Maxs.x,Maxs.y,Mins.z),Angles))
			//		Prop.append(Origin+RotateVector(Vector(Maxs.x,Mins.y,Mins.z),Angles))
			//		Prop.append(Origin+RotateVector(Vector(Mins.x,Mins.y,Maxs.z),Angles))
			//		Prop.append(Origin+RotateVector(Vector(Mins.x,Maxs.y,Maxs.z),Angles))
			//		Prop.append(Origin+RotateVector(Vector(Maxs.x,Maxs.y,Maxs.z),Angles))
			//		Prop.append(Origin+RotateVector(Vector(Maxs.x,Mins.y,Maxs.z),Angles))
			//
			//		
			//		for (local i=0;i<Prop.len();i++)
			//		{
			//			if (Prop[i].z<ent.GetCenter().z) {Prop.remove(i);i--}
			//		}
			//		if (Prop.len()!=4) continue;
			//		Props[entindex]=Prop;
			//		PropsLast[entindex]=Vector(Origin.x,Origin.y);
			//		//surface.SetColor(255, 0, 0, 255)
			//	}
			//	else Prop=Props[entindex];
			//	//surface.SetColor(35, 255, 40, 255)
			//	
			//	foreach (i,p in Prop)
			//	{
			//		PropV[i]=(Vector(GetMapPositionX(p),GetMapPositionY(p)))
			//	}
			//	
			//	
			//	if (abs(cross(PropV[2]-PropV[1],PropV[0]-PropV[3]))>50)
			//	{
			//		local a=PropV[2]
			//		PropV[2]=PropV[3];
			//		PropV[3]=a;
			//	}
			//	
			//	DrawProperLine(PropV[0].x,PropV[0].y,PropV[1].x,PropV[1].y);
			//															  
			//	DrawProperLine(PropV[1].x,PropV[1].y,PropV[2].x,PropV[2].y);
			//															  
			//	DrawProperLine(PropV[2].x,PropV[2].y,PropV[3].x,PropV[3].y);
			//															  
			//	DrawProperLine(PropV[3].x,PropV[3].y,PropV[0].x,PropV[0].y);
			//
			//
			//	//if (Props[entindex]!=Prop) Props[entindex]=Prop;
			//	
			//}
			
			
		}
		
		panelbg = vgui.CreatePanel("Panel", vgui.GetRootPanel(), "Screen3")
		printl("PANELS CREATED")
		panelbg.MakeReadyForUse()
		panelbg.SetVisible(false)
		panelbg.SetPos(XRES(0), XRES(0))
		panelbg.SetBgColor( 0, 0, 0, 250 )
		panelbg.SetSize(XRES(640),YRES(480))
		panelbg.SetZPos(-10)
		
		local InitialSeed=null
		local MapTitleText="MAP OF SEED "+InitialSeed
		
		local MapTitleWide=MapTitleText.len()*XRES(12)
		local MapTitle=vgui.CreatePanel("Label", panelbg, "MapTitle")
		MapTitle.MakeReadyForUse()
		MapTitle.SetFgColor( 0, 153, 255, 255 );
		MapTitle.SetPos( XRES(320)-MapTitleWide/2, 0 );
		MapTitle.SetSize(MapTitleWide, YRES(35) );
		MapTitle.SetContentAlignment( Alignment.center );
		MapTitle.SetFont(20);
		MapTitle.SetText( MapTitleText );
		
		/*
		local PObjectives=vgui.CreatePanel("Label", panelbg, "Objectives")
		local ObjectivesWide=XRES(12)*11
		PObjectives.MakeReadyForUse()
		PObjectives.SetFgColor( 0, 153, 255, 255 );
		PObjectives.SetPos( XRES(70)-ObjectivesWide/2, YRES(115) );
		PObjectives.SetSize(ObjectivesWide, YRES(75) );
		PObjectives.SetContentAlignment( Alignment.north );
		PObjectives.SetFont(20);
		PObjectives.SetText("");
		*/
		
		panel = vgui.CreatePanel("Panel", vgui.GetRootPanel(), "Screen2")
		panel.MakeReadyForUse()
		panel.SetVisible(true)
		panel.SetPos(XRES(638)-XRES(5*size)*(range+0.5)*2, XRES(2))
		//panel.SetSize(XRES(640),YRES(480))
		panel.SetSize(XRES(5*size)*(range+0.5)*2,XRES(5*size)*(range+0.5)*2)
		panel.SetPaintEnabled(true)
		panel.SetPaintBorderEnabled(true)
		panel.SetPaintBackgroundEnabled(true)
		panel.SetPaintBackgroundType(2)
		panel.SetFgColor( 252, 0, 0, 0 )
		panel.SetBgColor( 0, 0, 0, 200 )
		panel.SetZPos(0)
		panel.SetAlpha(255)
		panel.SetCallback( "Paint", Paint.bindenv(this) )
		
		function PaintBG()
		{
			panel.SetPaintBackgroundEnabled(true)
			playeryaw=player.GetAngles().y
			local size=Convars.GetFloat("sourceworld_minimap_size");
			local range=Convars.GetFloat("sourceworld_minimap_range");
			
			//MapTitleText="WORLD ["+format("%X",InitialSeed)+"]"
			//MapTitleText="WORLD ["+InitialSeed+"]"
			if ("worldName" in SW_WORLD_INFO) MapTitleText="WORLD: "+SW_WORLD_INFO.worldName
			MapTitle.SetText( MapTitleText );
			local perc=format("%.0f",ExploredTiles.len()*1.0/Hulls.len()*100.0)
			surface.DrawColoredText(surface.GetFont("WeaponSelectorGlow13",true), XRES(520), YRES(10),0,150,255,25,"Explored: ")
			surface.DrawColoredText(surface.GetFont("WeaponSelector13",true), XRES(520)+2, YRES(10)+2,50,250,55,255,"Explored: ")
			surface.DrawColoredText(surface.GetFont("WeaponSelectorGlow13",true), XRES(520)+surface.GetTextWidth(surface.GetFont("WeaponSelector13",true),"Explored: "), YRES(10),0,250,25,55,perc.tostring()+"%")
			surface.DrawColoredText(surface.GetFont("WeaponSelector13",true), XRES(520)+surface.GetTextWidth(surface.GetFont("WeaponSelector13",true),"Explored: "), YRES(10),66,255,65,255,perc.tostring()+"%")
			if ("SW_MAPGEN_STAGE_CURRENT" in getroottable()) surface.DrawColoredText(20,XRES(290), YRES(30),0,150,255,255,format("STAGE %i/%i",SW_MAPGEN_STAGE_CURRENT,SW_MAPGEN_STAGE_COUNT))
			/*
			local ObjectiveString=""
			foreach (Objective in Objectives)
			{
				local state="X"
				if (Objective.state==true) state="✓";
				ObjectiveString+=" - "+Objective.name+" ["+state+"]\n"
				//printl("Received objective for HUD!")
			}
			PObjectives.SetText("EXPLORED: "+format("%.2f", Exploration)+"%\nOBJECTIVES:\n"+ObjectiveString);
			*/
			//printl(Objectives.len())
			
			if (range>10&&OBJECTIVES.len()>0)
			{
				surface.DrawColoredText(surface.GetFont("Smolss",true),XRES(15),YRES(30),55, 253, 65, 255,"ACTIVE OBJECTIVES")
				surface.DrawColoredText(surface.GetFont("Smol",true),XRES(15),YRES(30),55, 253, 65, 255,"ACTIVE OBJECTIVES")
				
				foreach(i,o in OBJECTIVES)
				{
					//surface.DrawColoredText(surface.GetFont("VerySmolShadow",true),XRES(30)+1,YRES(50)+YRES(25)*i+1,55, 253, 55, 255-210*o.Status.tointeger(),o.DisplayName)
					surface.DrawColoredText(surface.GetFont("ObjectiveS3",true),XRES(15)+2,YRES(55)+YRES(25)*i,75, 183, 255, 155-140*o.Status.tointeger(),"* "+o.DisplayName)
					surface.DrawColoredText(surface.GetFont("Objective3",true),XRES(15),YRES(55)+YRES(25)*i,65, 173, 255, 255-240*o.Status.tointeger(),"* "+o.DisplayName)
					surface.DrawColoredText(surface.GetFont("VerySmolShadow",true),XRES(32),YRES(60)+YRES(25)*i+surface.GetFontTall(surface.GetFont("Objective3",true)),0, 253, 55, 55-50*o.Status.tointeger(),"- "+o.Description)
					surface.DrawColoredText(surface.GetFont("VerySmol",true),XRES(32),YRES(60)+YRES(25)*i+surface.GetFontTall(surface.GetFont("Objective3",true)),0, 153, 255, 255-255*o.Status.tointeger(),"- "+o.Description)
													
					surface.DrawColoredText(surface.GetFont("ObjectiveS3",true),XRES(15),YRES(55)+YRES(25)*i,30, 255, 55, 155*o.Status.tointeger(),"* COMPLETED")
					surface.DrawColoredText(surface.GetFont("Objective3",true),XRES(15),YRES(55)+YRES(25)*i,60, 173, 255, 255*o.Status.tointeger(),"* COMPLETED")
				}
			}
			
		}
		panelbg.SetCallback( "Paint", PaintBG.bindenv(this) )
		
		NetMsg.Receive("Minimap", function() {
			if (NetMsg.ReadBool())
			{
				Convars.SetFloat("sourceworld_minimap_range",23);
				Convars.SetFloat("sourceworld_minimap_size",1.4);
				//Convars.SetFloat("sourceworld_hud_crosshair",0);
				//Convars.SetFloat("sourceworld_hud_ammo",0);
				size=Convars.GetFloat("sourceworld_minimap_size");
				range=Convars.GetFloat("sourceworld_minimap_range");
				surface.PlaySound("common/menu_on.wav")
				panel.SetSize(YRES(400),YRES(400))
				panel.SetBgColor( 0, 0, 0, 0 )
				panelbg.SetVisible(true)
				panel.SetPos(ScreenWidth()/2-YRES(200),YRES(40))
				AlphaMultiplier=1
				LastMapOpenTime=Time()
				//SetHudElementVisible("CHudFlashlight",false)
				//SetHudElementVisible("CHudHealth",false)
				//SetHudElementVisible("CHudBattery",false)
				//SetHudElementVisible("CHudSuitPower",false)
			}
			else
			{
				Convars.SetFloat("sourceworld_minimap_range",6);
				Convars.SetFloat("sourceworld_minimap_size",1);
				surface.PlaySound("common/menu_off.wav")
				size=Convars.GetFloat("sourceworld_minimap_size");
				range=Convars.GetFloat("sourceworld_minimap_range");
				//Convars.SetFloat("sourceworld_hud_crosshair",1);
				//Convars.SetFloat("sourceworld_hud_ammo",1);
				panel.SetSize(XRES(5*size)*(range+0.5)*2,XRES(5*size)*(range+0.5)*2)
				panel.SetBgColor( 0, 0, 0, 200 )
				panel.SetPos(XRES(638)-XRES(5*size)*(range+0.5)*2, XRES(2))
				panelbg.SetVisible(false)
				AlphaMultiplier=0.75
				//SetHudElementVisible("CHudFlashlight",true)
				//SetHudElementVisible("CHudHealth",true)
				//SetHudElementVisible("CHudBattery",true)
				//SetHudElementVisible("CHudSuitPower",true)
			}
			InitialSeed=NetMsg.ReadLong()
			MapTitleText="MAP OF SEED "+InitialSeed;
			MapTitle.SetText( MapTitleText );
			
			/*
			local ObjectiveString=""
			foreach (Objective in Objectives)
			{
				local state="X"
				if (Objective.state==true) state="✓";
				ObjectiveString+=" - "+Objective.name+" ["+state+"]\n"
				//printl("Received objective for HUD!")
			}
			printl(Objectives.len())
			PObjectives.SetText("OBJECTIVES:\n"+ObjectiveString);
			*/
		}.bindenv(this))
		//ClientThink()
	}
}

}

if ( IsServer() )
{
	printl("map init")
	
	EntFire("minimap_client","CallScriptFunction","MinimapInit",1)
	EntFire("minimap_client","CallScriptFunctionClient","MinimapInit",1.7)
	//EntFireByHandle(self,"AddOutput","ClientThink 1",0)
	
	
	function Map(State)
	{
		if (Convars.GetFloat("sourceworld_hud")==2||player.GetHealth()<=0) {return};
		NetMsg.Start("Minimap");
		NetMsg.WriteBool(State)
		NetMsg.WriteLong(Globals.GetCounter(Globals.GetIndex("InitialRNGSeed")))
		NetMsg.Send(player, true);
		printl("Opening minimap")
	}

	function Hideme()
	{
		NetMsg.Start("HideMinimap");
		NetMsg.Send(player, true);
		printl("Hiding minimap")
	}
	
	Convars.RegisterCommand( "minimap", function(_)
	{
		local size=Convars.GetFloat("sourceworld_minimap_size");
		local range=Convars.GetFloat("sourceworld_minimap_range");
		
		if (range>20) {
			Map(false)
		}
		else
		{
			Map(true)
		}
	}.bindenv(this), "", FCVAR_CLIENTDLL );
	
}

function ClientThink()
{
	return
}

function Think()
{
	if (Time()<3) return 3;
	//local initial_seed=Globals.GetIndex("InitialRNGSeed")
	//SendToConsole("cl_discord_state In Mapgen"+" Room: "+"UNKNOWN"+"  [ LVL "+((1+0.07*sqrt(PlayerExperience)).tointeger()).tostring()+" ]"+" [ $"+PlayerMoney.tostring()+" ]")
	//SendToConsole("cl_discord_details Seed: "+format("%X",Globals.GetCounter(initial_seed)).tostring())
	//if (SERVER_DLL) GetLevelMatrix();
	return 2
}
