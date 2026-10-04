local mapmaker = Entities.FindByName(null, "map_maker_angles");
local player = Entities.FindByClassname(null, "player");
if (SERVER_DLL)
{
	function Generate()
	{
		function Place(name, pos, angles = "")
		{
			name=name+angles;
			if (name!="template_lightbulb")
			{
				//EntFire("map_maker","AddOutput","OutSpawnedEntity !activator:RunScriptCode:TextureMe("+type+"):0:-1",0);
			}
			EntFire("map_maker","AddOutput","EntityTemplate "+ name ,0);
			if (pos == "0 0 0")
			{
				EntFire("map_maker","ForceSpawnAtEntityCenter","map_maker",0);
			}
			EntFire("map_maker","ForceSpawnAtPosition", pos ,0);
			local placed_brush = name.slice(9,name.len())+"t"
			//EntFire(placed_brush,"SetTextureIndex",RandomInt(0,2),0);
			//printl("changing texture of "+placed_brush);
		}
		
		function GenerateRoom(size_x, size_y, type=3)
		{	
			local x = -size_x*64
			local y = -size_y*64
			local doorplaced = 0
			local lightplaced = 0
			EntFire("map_maker","AddOutput","OutSpawnedEntity !activator:RunScriptCode:TextureMe("+type+"):0:-1",0);
			for (local ix = 0 ; ix < size_x ; ix++) 
			{
				//printl(i)
				for (local iy = 0 ; iy < size_y ; iy++) 
				{
					if ((doorplaced == 0) && ((RandomInt(0,size_y*size_x/2)==1) || ((ix>=size_x-1) && (iy>=size_y-1))))
					{
						if (ix==0 && doorplaced==0) { Place("template_doorway01", x+" "+y+" 0", "W"); doorplaced = 1 }
						if (iy==0 && doorplaced==0) { Place("template_doorway01", x+" "+y+" 0", "S"); doorplaced = 2 }
						if (iy==size_y-1 && doorplaced==0) { Place("template_doorway01", x+" "+y+" 0", "N"); doorplaced = 3 }
						if (ix==size_x-1 && doorplaced==0) { Place("template_doorway01", x+" "+y+" 0", "E"); doorplaced = 4 }
					}
					
					if ((lightplaced == 0) && ((RandomInt(0,size_y*size_x/2)==1) || ((ix>=size_x-1) && (iy>=size_y-1))))
					{
						Place("template_lightbulb", x+" "+y+" 0", "")
						lightplaced=1
					}
					
					if (ix==0 && doorplaced!=1) { Place("template_wall01", x+" "+y+" 0", "W") }
					if (iy==0 && doorplaced!=2) { Place("template_wall01", x+" "+y+" 0", "S") }
					if (iy==size_y-1 && doorplaced!=3) { Place("template_wall01", x+" "+y+" 0", "N") }
					if (ix==size_x-1 && doorplaced!=4) { Place("template_wall01", x+" "+y+" 0", "E") }
					
					Place("template_floor", x+" "+y+" 0")
					
					y=y+128;
					//printl("Room size: "ix+" "+iy+"door is "+doorplaced)
					if (doorplaced !=0) { doorplaced = 5; }
				}
				y=-size_y*64
				x=x+128;
			}
			EntFire("map_maker","RemoveOutput","*",0);
			printl("Room size: "+size_x+" "+size_y+" Type: "+type)
			//printl(TraceLineComplex(Vector(100,0, 5),Vector(100,0, 10), self,33570819,0).DidHit())
			/*
			if (TraceLineComplex(Vector(100,0, 5),Vector(100,0, 10), self,33570819,0).DidHit()==true)
			{
				Place("template_floor", x+" "+y+" 0")
				printl("huyak")
			}
			*/
		}
		GenerateRoom(RandomInt(1,4),RandomInt(1,4),RandomInt(0,2));
		
		Convars.RegisterCommand( "generate_room", function(_)
		{
			EntFire("func_wall","kill","",0);
			EntFire("func_brush","kill","",0);
			EntFire("prop_door_rotating","kill","",0);
			EntFire("func_clip_client","kill","",0);
			EntFire("lightbulb","kill","",0);
			GenerateRoom(RandomInt(1,4),RandomInt(1,4),RandomInt(0,2));
			EntFire("prop_door_rotating","open","",0.1);
		}.bindenv(this), "", FCVAR_CLIENTDLL );
	
	}
	
}








