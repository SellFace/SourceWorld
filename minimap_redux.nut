IncludeScript("vs_math.nut")
IncludeScript("lists/list_maps.nut")
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
	local panel=null

	local MinX=0x10000
	local MaxX=-0x10000
	local MinY=0x10000
	local MaxY=-0x10000
	
	local MapSize=0.25;
	
	local Zoomed=false;
	local LastZoom=0;

	function GetMapPositionX(Originx,Center=null)
	{
		local dif=max(MaxX-MinX,MaxY-MinY)
		local centerx=(MaxX+MinX)/2
		local centery=(MaxY+MinY)/2
		
		local mod=clamp(Time()-LastZoom,0,0.5)*2
		
		dif=1500
		local MinimapX = RemapVal(Originx-player.GetOrigin().x+centerx,centerx-dif/2,centerx+dif/2,XRES(320)-YRES(240)*MapSize,XRES(320)+YRES(240)*MapSize);
		dif=max(MaxX-MinX,MaxY-MinY)
		
		if (input.IsButtonDown(ButtonCode.KEY_LALT))
		{
			if (!Zoomed) LastZoom=Time();
			Zoomed=true
			
			mod=clamp(Time()-LastZoom,0,0.5)*2
			
			return MinimapX*mod+RemapVal(Originx,centerx-dif/2,centerx+dif/2,XRES(320)-YRES(240)*MapSize,XRES(320)+YRES(240)*MapSize)*(1-mod)
		}
		else
		{
			if (Zoomed) LastZoom=Time()-(1-mod)/2.0;
			Zoomed=false
		}
		return RemapVal(Originx,centerx-dif/2,centerx+dif/2,XRES(320)-YRES(240)*MapSize,XRES(320)+YRES(240)*MapSize)*mod+MinimapX*(1-mod);
	}
	function GetMapDist(Dist)
	{
		return RemapVal(Dist,0,MaxX-MinX+16,0,YRES(480))*MapSize
	}
	function GetMapPositionY(Originy,Center=null)
	{
		local dif=max(MaxX-MinX,MaxY-MinY)
		local centerx=(MaxX+MinX)/2
		local centery=(MaxY+MinY)/2
		
		local mod=clamp(Time()-LastZoom,0,0.5)*2
		
		dif=1500
		local MinimapY = RemapVal(Originy-player.GetOrigin().y+centery,centery-dif/2,centery+dif/2,YRES(240)+YRES(240)*MapSize,YRES(240)-YRES(240)*MapSize);
		dif=max(MaxX-MinX,MaxY-MinY)
		
		if (input.IsButtonDown(ButtonCode.KEY_LALT))
		{
			if (!Zoomed) LastZoom=Time();
			Zoomed=true
			
			mod=clamp(Time()-LastZoom,0,0.5)*2
			
			return MinimapY*mod+RemapVal(Originy,centery-dif/2,centery+dif/2,YRES(240)+YRES(240)*MapSize,YRES(240)-YRES(240)*MapSize)*(1-mod)
		}
		else
		{
			if (Zoomed) LastZoom=Time()-(1-mod)/2.0;;
			Zoomed=false
		}
		
		return RemapVal(Originy,centery-dif/2,centery+dif/2,YRES(240)+YRES(240)*MapSize,YRES(240)-YRES(240)*MapSize)*mod+MinimapY*(1-mod);
	}

	function GetMapPosition(Origin)
	{
		return [GetMapPositionX(Origin.x),GetMapPositionY(Origin.y)]
	}


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

	function orient(a, b, c) {
		return cross(b-a, c-a);
	}

	function LineInter(a, b, c, d) {
		local oa = orient(c,d,a); 
		local ob = orient(c,d,b);            
		local oc = orient(a,b,c);            
		local od = orient(a,b,d);      
		// Proper intersection exists if opposite signs 
		
		local interpoint=(a*ob - b*oa) / (ob-oa)
		
		return ((oa*ob < 0) && (oc*od < 0));
	}
	
	function LineInterPoint(a, b, c, d) {
		local oa = orient(c,d,a); 
		local ob = orient(c,d,b);            
		local oc = orient(a,b,c);            
		local od = orient(a,b,d);      
		// Proper intersection exists if opposite signs 
		
		if ((oa*ob < 0) && (oc*od < 0))
		{
			local interpoint=(a*ob - b*oa) / (ob-oa)
			return [interpoint.x,interpoint.y]
		}
		return null;
	}
	
	function PointInSector(p,sector)
	{
		local prevpoint=null
		local firstpoint=null
		
		local inters=0;
		
		foreach (point in sector.Points)
		{
			if (point[0]==null) continue;
			
			if (!firstpoint) firstpoint=point;
		
		
			
			if (prevpoint) if (LineInter(Vector(prevpoint[0],prevpoint[1]),Vector(point[0],point[1]),Vector(p[0],p[1]),Vector(MinX-100,MinY-100))) inters++;
			
			prevpoint=point;
		}
		
		if (LineInter(Vector(prevpoint[0],prevpoint[1]),Vector(firstpoint[0],firstpoint[1]),Vector(p[0],p[1]),Vector(MinX-100,MinY-100))) inters++;
		
		
		return (inters%2==1)
	}
	
	function LineInSector(p1,p2,sector)
	{
		
		local prevpoint=null
		local firstpoint=null
		
		local inters=0;
		
		local points=[]
		
		foreach (point in sector.Points)
		{
			if (point[0]==null) continue;
			
			if (!firstpoint) firstpoint=point;
		
		
			
			if (prevpoint) if (LineInterPoint(Vector(prevpoint[0],prevpoint[1]),Vector(point[0],point[1]),Vector(p1[0],p1[1]),Vector(p2[0],p2[1]))) 
			{
				inters++;
				points.append(LineInterPoint(Vector(prevpoint[0],prevpoint[1]),Vector(point[0],point[1]),Vector(p1[0],p1[1]),Vector(p2[0],p2[1])))
			}
			prevpoint=point;
		}
		
		if (LineInterPoint(Vector(prevpoint[0],prevpoint[1]),Vector(firstpoint[0],firstpoint[1]),Vector(p1[0],p1[1]),Vector(p2[0],p2[1]))) 
		{
			inters++;
			points.append(LineInterPoint(Vector(prevpoint[0],prevpoint[1]),Vector(firstpoint[0],firstpoint[1]),Vector(p1[0],p1[1]),Vector(p2[0],p2[1])))
		}

		return points;
	}
	
	local DrawColoredTextCentered=function(font, x, y, r, g, b, a, text)
	{
		surface.DrawColoredText(font, x-surface.GetTextWidth(font, text)/2, y-surface.GetFontTall(font)/2, r, g, b, a, text)
	}

	local Closing=false;
	local LastMapOpenTime=Time()

	function MinimapInit()
	{
		if ( panel && panel.IsValid() )
		{
			if (Closing) return;
			
			Closing=true;
			LastMapOpenTime=Time()
			surface.PlaySound("common/menu_off.wav")
			return;
		}	
		
		local texture=surface.ValidateTexture("vgui/cursors/arrow",true,true,true)
		local iconatlas=surface.ValidateTexture("vgui/map_icons",true,true,true)

		local AlphaMultiplier=0.75
		
		LastMapOpenTime=Time()
		
		local MapData=null
		foreach(i,map in LIST_MAPS)
		{
			if (GetMapName().find(i)!=null) MapData=map;
		}
		
		if (MapData==null)
		{
			//HintText="No map available for this area"
			//HintTime=Time()
			
			BigNotifications.append( [Time(), "No map available for this area", Vector(250,0,0),2,0.5] )
			if (BigNotifications.len()>3) BigNotifications.remove(0);
			
			surface.PlaySound("buttons/button11.wav")
			return
		}
		
		surface.PlaySound("common/menu_on.wav")
		
		local PlayerSector=null;
		
		
		
		
		function DrawProperLine(a,b,c,d,thickness=1)
		{
			if (thickness==1)
			{
				surface.DrawLine(a,b,c,d);
				return
			}
			
			surface.DrawLine(a,b,c,d);
			for (local i=1;i<thickness;i++)
			{			
				surface.DrawLine(a,b+i,c,d+i);
				surface.DrawLine(a,b-i,c,d-i);
				
				surface.DrawLine(a+i,b,c+i,d);
				surface.DrawLine(a-i,b,c-i,d);
			}
		}
		
		foreach (sector in MapData.Sectors)
		{
			foreach (point in sector.Points)
			{
				if (!point[0]) continue
				
				MinX=min(MinX,point[0])
				MaxX=max(MaxX,point[0])
				
				MinY=min(MinY,point[1])
				MaxY=max(MaxY,point[1])
			}
		}
		
		local scanlines=surface.ValidateTexture("effects/monitorscreen_scanline1b", true, false, false)
		local GlowSprite=surface.ValidateTexture("vgui/glow",true,false,false)
		
		function Paint()
		{
			local Anim=clamp(pow((Time()-LastMapOpenTime)*4,0.5),0,1)
			
			if (Closing) Anim=1-clamp(pow((Time()-LastMapOpenTime)*6,0.5),0,1);
			
			if (Closing&&Anim<=0)
			{
				panel.Destroy()
				panel=null
				Closing=false;
				return;
			}
			
			MapSize=Lerp(Anim,0,0.75)
			
			panel.SetAlpha(255*Anim)
			
			if (FrameTime()==0) return;
			if (player.GetHealth()<=0) 
			{
				panel.SetPaintBackgroundEnabled(false)
				return
			}
			
			local colm=fabs(sin(Time()/4.0)*sin(Time()/2.0+34))
			colm=clamp(colm,0.6,1)
			
			surface.SetColor(5*colm, 175*colm, 255*colm, 2)
			surface.SetTexture(scanlines)
			surface.DrawTexturedSubRect(0, 0, ScreenWidth(), ScreenHeight(), 0, 0, 1, 1)
			
			
			foreach (i,sector in MapData.Sectors)
			{
				if (player.GetOrigin().z<sector.MinZ||player.GetOrigin().z>sector.MaxZ) continue;
				
				if (PointInSector([player.GetOrigin().x,player.GetOrigin().y],sector))
				{
					PlayerSector=i;
					break
				}
			}
			
			panel.SetPaintBackgroundEnabled(true)
			
			surface.SetColor(5, 175, 255, 255)
			
			local prevpoint=null;
			local firstpoint=null;
			
			

			
			local C0=[5, 175, 255]
			local C1=[115, 255, 115]
			
			foreach (i,sector in MapData.Sectors)
			{
				if (player.GetOrigin().z<sector.MinZ||player.GetOrigin().z>sector.MaxZ) continue;
				
				if (PlayerSector==i)
				{
					local a=1-clamp(sin(Time()*4)*1.5,0,1)
					
					surface.SetColor((C0[0]*a+C1[0]*(1-a))/4, (C0[1]*a+C1[1]*(1-a))/4, (C0[2]*a+C1[2]*(1-a))/4, 255)
				}
				else surface.SetColor(5/4, 175/4, 255/4, 255);
				
				prevpoint=null;
				firstpoint=null;
				
				local minx=0x10000
				local maxx=-0x10000
				local miny=0x10000
				local maxy=-0x10000
				
				
				if (PlayerSector==i)
				{
					local a=1-clamp(sin(Time()*4)*1.5,0,1)
					
					surface.SetColor(C0[0]*a+C1[0]*(1-a), C0[1]*a+C1[1]*(1-a), C0[2]*a+C1[2]*(1-a), 255)
					
					/*
					local lines=LineInSector([player.GetOrigin().x-1512*cos(Time()*4),player.GetOrigin().y-1512*sin(Time()*4)],[player.GetOrigin().x+1512*cos(Time()*4),player.GetOrigin().y+1512*sin(Time()*4)],sector)
					
					if (lines) foreach (point in lines)
					{
						if (point[0]==null) {prevpoint=null;continue}
						
						if (!firstpoint) firstpoint=point;
						
						if (prevpoint)
						{
							DrawProperLine(GetMapPositionX(prevpoint[0]),GetMapPositionY(prevpoint[1]),GetMapPositionX(point[0]),GetMapPositionY(point[1]),1)
						}
						
						prevpoint=point;
					}
					if (lines) 
					{
						DrawProperLine(GetMapPositionX(player.GetOrigin().x),GetMapPositionY(player.GetOrigin().y),GetMapPositionX(prevpoint[0]),GetMapPositionY(prevpoint[1]),2)
					}
					*/
				}
				else surface.SetColor(5, 175, 255, 255);
				
				prevpoint=null
				firstpoint=null;
					
				
				foreach (point in sector.Points)
				{
					if (point[0]==null) {prevpoint=null;continue}
					
					GetMapPositionX(0)
					
					if (!firstpoint) firstpoint=point;
					
					if (prevpoint)
					{
						DrawProperLine(GetMapPositionX(prevpoint[0]),GetMapPositionY(prevpoint[1]),GetMapPositionX(point[0]),GetMapPositionY(point[1]),2)
					}
					
					prevpoint=point;
					
					minx=min(minx,point[0])
					maxx=max(maxx,point[0])
					
					miny=min(miny,point[1])
					maxy=max(maxy,point[1])
				}
				if (prevpoint) DrawProperLine(GetMapPositionX(prevpoint[0]),GetMapPositionY(prevpoint[1]),GetMapPositionX(firstpoint[0]),GetMapPositionY(firstpoint[1]),2)
				
				surface.SetColor(255,255,255, 255);
				surface.SetTexture(iconatlas)
				
				if (PlayerSector==i)
				{
					local a=1-clamp(sin(Time()*4)*1.5,0,1)
					
					surface.SetColor((C0[0]*a+C1[0]*(1-a))/4, (C0[1]*a+C1[1]*(1-a))/4, (C0[2]*a+C1[2]*(1-a))/4, 255)
				}
				else surface.SetColor(5/4, 175/4, 255/4, 255);
				
				
				local size=YRES(32)
				//if (PlayerSector==i) DrawColoredTextCentered(surface.GetFont("KeyHint5",true),GetMapPositionX((minx+maxx)/2),GetMapPositionY((miny+maxy)/2),115, 255, 115,255,sector.Text)
				//else DrawColoredTextCentered(surface.GetFont("KeyHint5",true),GetMapPositionX((minx+maxx)/2),GetMapPositionY((miny+maxy)/2),35, 195, 255,255,sector.Text)
			}
			
			foreach (gray in MapData.GraySectors)
			{
				//if (gray.Text!=sector.Text) continue;
				prevpoint=null
				firstpoint=null
				
				foreach (point in gray.Points)
				{
					if (point[0]==null) {prevpoint=null;continue}
					
					if (!firstpoint) firstpoint=point;
					
					if (prevpoint)
					{
						DrawProperLine(GetMapPositionX(prevpoint[0]),GetMapPositionY(prevpoint[1]),GetMapPositionX(point[0]),GetMapPositionY(point[1]),1)
					}
					
					prevpoint=point;
				}
				
			}
			
			surface.SetColor(5, 255, 25, 255)
			
			foreach (gray in MapData.DoorSectors)
			{
				//if (gray.Text!=sector.Text) continue;
				prevpoint=null
				firstpoint=null
				
				foreach (i,point in gray.Points)
				{
					if (point[0]==null) {prevpoint=null;continue}
					//if (i>1) continue;
					
					if (!firstpoint) firstpoint=point;
					
					if (prevpoint)
					{
						DrawProperLine(GetMapPositionX(prevpoint[0]),GetMapPositionY(prevpoint[1]),GetMapPositionX(point[0]),GetMapPositionY(point[1]),3)
					}
					
					prevpoint=point;
				}
				
			}
			
			foreach (sector in MapData.Sectors)
			{
				if (player.GetOrigin().z<sector.MinZ||player.GetOrigin().z>sector.MaxZ) continue;
				
				local size=GetMapDist(32)*1.5
				local staticsize=GetMapDist(32)*1.5
				
				size=size*clamp(10-(Time()-LastMapOpenTime-0.2)*20,1.5,10)*(1.5+sin(Time())/8.0)
				
				size*=2
				
				size=clamp(size,0,YRES(32))
				
				foreach (marker in MapData.Markers)
				{
					if (marker[2]!=sector.Text) continue;
					
					local x=GetMapPositionX(marker[0])
					local y=GetMapPositionY(marker[1])
					

					
					switch(marker[3])
					{
						case "SAVE":
						{
							
							surface.SetColor(5,125,255, fabs(sin(Time())*155));
							surface.SetTexture(GlowSprite)
							surface.DrawTexturedRectRotated(x-size,y-size,size*2,size*2,Time()*360)
							
							surface.SetTexture(iconatlas)
							surface.SetColor(255,255,255, 255);
							surface.DrawTexturedSubRect(x-size/2,y-size/2,x+size/2,y+size/2,0,0,0.5,0.5)
							break
						}
						case "SHOP":
						{
							
							surface.SetColor(5/2,125/2,255/2, fabs(sin(Time())*155));
							surface.SetTexture(GlowSprite)
							surface.DrawTexturedRectRotated(x-size,y-size,size*2,size*2,Time()*360)
							
							surface.SetTexture(iconatlas)
							surface.SetColor(255,255,255, 255);
							surface.DrawTexturedSubRect(x-size/2,y-size/2,x+size/2,y+size/2,0.5,0,1,0.5)
							break
						}
					}
				}
			}
			
			surface.SetColor(5, 255, 57, 255)
			surface.SetTexture(texture)
			
			DrawColoredTextCentered(surface.GetFont("Smol",true),XRES(320),YRES(240)-YRES(240)*0.75-YRES(30),35, 195, 255,255,MapData.DisplayName)
			
			local playerx=GetMapPositionX(player.GetOrigin().x)
			local playery=GetMapPositionY(player.GetOrigin().y)
		
			
			
			local size=GetMapDist(32)*1.5
			local staticsize=GetMapDist(32)*1.5
			
			size=size*clamp(10-(Time()-LastMapOpenTime-0.2)*20,1.5,10)*(1.5+sin(Time()*4)/2.0)
			
			surface.DrawTexturedRectRotated(playerx-size/2,playery-size/2,size,size,MainViewAngles().y-135)
		}

		
		panel = vgui.CreatePanel("Panel", vgui.GetRootPanel(), "RealMinimap")
		panel.MakeReadyForUse()
		panel.SetVisible(true)
		panel.SetPos(0,0)
		panel.SetSize(ScreenWidth(),ScreenHeight())
		panel.SetPaintEnabled(true)
		panel.SetPaintBorderEnabled(true)
		panel.SetPaintBackgroundEnabled(true)
		panel.SetPaintBackgroundType(0)
		panel.SetFgColor( 252, 0, 0, 0 )
		panel.SetBgColor( 0, 0, 0, 254 )
		panel.SetZPos(0)
		panel.SetAlpha(0)
		panel.SetCallback( "Paint", Paint.bindenv(this) )
		
	}
	
	NetMsg.Receive("Minimap", function() {
		MinimapInit()
	}.bindenv(this))

}

if (SERVER_DLL)
{
	printl("map init")
	
	EntFire("minimap_client","CallScriptFunction","MinimapInit",1)
	//EntFire("minimap_client","CallScriptFunctionClient","MinimapInit",1.7)
	//EntFireByHandle(self,"AddOutput","ClientThink 1",0)
	
	
	function Map()
	{
		if (Convars.GetFloat("sourceworld_hud")==2||player.GetHealth()<=0) {return};
		NetMsg.Start("Minimap");
		NetMsg.Send(player, true);
		printl("Toggling minimap")
	}
	
	Convars.RegisterCommand( "minimap", function(_)
	{
		Map()
	}.bindenv(this), "", FCVAR_CLIENTDLL );
	
	local SectorText=""
	
	Convars.RegisterCommand( "dot", function(_)
	{
		local trace=TraceLineComplex(player.EyePosition(), player.EyePosition()+player.GetEyeForward()*1000, player, MASK_SHOT, 0)
		
		local hitpos=trace.EndPos()
		
		debugoverlay.Line(hitpos,hitpos+Vector(0,0,4),255,30,30,true,6)
		debugoverlay.Line(hitpos,hitpos+Vector(2,0,4),255,30,30,true,6)
		debugoverlay.Line(hitpos,hitpos+Vector(-2,0,4),255,30,30,true,6)
		debugoverlay.Line(hitpos,hitpos+Vector(0,2,4),255,30,30,true,6)
		debugoverlay.Line(hitpos,hitpos+Vector(0,-2,4),255,30,30,true,6)
		
		printl("["+(hitpos.x+0.5).tointeger().tostring()+", "+(hitpos.y+0.5).tointeger().tostring()+"],")
		
		SectorText=SectorText+"["+(hitpos.x+0.5).tointeger().tostring()+", "+(hitpos.y+0.5).tointeger().tostring()+"],"
		
	}.bindenv(this), "", FCVAR_CLIENTDLL );
	
	Convars.RegisterCommand( "dotno", function(_)
	{
		printl("[null],")
		debugoverlay.ClearAllOverlays()
		SectorText=SectorText+"[null],"
		
	}.bindenv(this), "", FCVAR_CLIENTDLL );
	
	Convars.RegisterCommand( "sector_finalise", function(_)
	{
		printl("")
		printl("Sector(["+SectorText+"],\"\")")
		printl("")
		
		
	}.bindenv(this), "", FCVAR_CLIENTDLL );
	
	Convars.RegisterCommand( "sector_clear", function(_)
	{
		printl("Sector clear")
		SectorText=""
		
	}.bindenv(this), "", FCVAR_CLIENTDLL );
	
}

function ClientThink()
{
	return
}

function Think()
{
	return
}
