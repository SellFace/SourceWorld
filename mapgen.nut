IncludeScript("vmf_parser.nut")
IncludeScript("lists/list_enemies.nut")
IncludeScript("lists/list_loot.nut")
IncludeScript("lists/list_items.nut")
IncludeScript("lists/list_soundscapes.nut")

IncludeScript("lists/list_tilesets.nut")

//local LAYOUT_SIZE=40

function GetWorldSizeFromSeed(seed,tilesetid)
{
	local tileset=GetTilesetFromID(tilesetid)
	
	local min_size=tileset.min_size
	local max_size=tileset.max_size
	
	return (min_size+seed%(max_size-min_size+1))
}

local StageID=Globals.GetCounter(Globals.GetIndex("StageID"))
local TilesetID=Globals.GetCounter(Globals.GetIndex("TilesetID"))
local LAYOUT_SIZE=GetWorldSizeFromSeed(Globals.GetCounter(Globals.GetIndex("StageSeed"+StageID)),TilesetID)


//local LAYOUT_SIZE=10

local GenerationTime=999+clock()

//Use this for overriding the seed

//LoadTileset("example")
LoadTileset(GetTilesetFromID(TilesetID).filename)

//local SEED=13371
//local LAYOUT_SIZE=20
//SetRNGSeed(SEED);SetRNGSeed(SEED)

local START=Vector(-268,1834,516)

::GLOBAL_OFFSET<-Vector()

::VMFs<-[]
//::Connectors<-[]
::Connections<-array(LAYOUT_SIZE);	// array of connectors was stupid for shortcuts, so we'll use matrix for edge connections like normal people do. Used only when actually spawning doors.
for (local i = 0 ; i < LAYOUT_SIZE ; i++) Connections[i]=array(LAYOUT_SIZE)
::Blocks<-[]
::BlockedSockets<-array(128)
::Shortcuts<-array(128)

::StartingTile<-(0);

//::TileSet<-{}

//local Tiles=GetTileList("example")
//foreach (Tile in Tiles)
//{
//	Tile
//}

local FreeSockets=[]

local KEYS=-1

function ConnectRooms(VMF1,VMF2,socket1,socket2)
{
	if (!("angles" in socket1)) socket1.rawset("angles","0 0 0")
	if (!("angles" in socket2)) socket2.rawset("angles","0 0 0")
	VMF2.Offsets.OffsetYaw=VMF1.Offsets.OffsetYaw+ToVector(socket1.angles).y+(180-ToVector(socket2.angles).y)
	VMF2.Offsets.Offset=GetOffsetVector(socket1.origin,VMF1.Offsets.Offset,VMF1.Offsets.OffsetYaw)-GetOffsetVector(socket2.origin,Vector(0,0,0),VMF2.Offsets.OffsetYaw)
	VMF2.Sockets[GetSocketField(socket2,VMF2)].taken<-VMFs.find(VMF1)
	
	VMF2.ZFloor=VMF1.ZFloor
	if (("Stairs" in VMF1)) VMF2.ZFloor-=VMF1.Stairs;
	
	
	if ("direction" in socket1&&socket1.direction.tointeger()!=0)
	{
		// in case the room was already connected by directional socket, we don't apply different zfloor to any tiles that go from sockets with same direction.
		// in english, this means that having two sockets that both go up or both go down, will practically make their rooms have same zfloor.
		if (!("StartDirection" in VMF1)||(VMF1.StartDirection!=socket1.direction.tointeger()))
		{
			VMF2.ZFloor+=socket1.direction.tointeger();
			
			// sometimes there are multiple sockets that go down/up, so we don't want to change current room's ZFloor twice.
			if (!("Stairs" in VMF1))
			{
				VMF1.Stairs<-socket1.direction.tointeger()/2.0
				VMF1.ZFloor+=socket1.direction.tointeger()/2.0;
			}
		}
	}
	
	// if we're connecting to a room by using its socket with direction, we remember that this direction was used.
	if ("direction" in socket2&&socket2.direction.tointeger()!=0)
	{
		VMF2.StartDirection<-socket2.direction.tointeger()
	}
}

local FailedRooms=0

local History=[]	//Used for storing info necessary for UNDOing tiles.

local PlayerSpawns=[]

function PlaceDoor(VMF1,VMF2,socket1,socket2)
{
	local ConnectorsAdded=0
	
	
	local DontRemember=false
	
	if (!("blocked" in socket1)&&VMF1!=VMF2&&(Connections[socket1.parent][socket2.parent]==true||Connections[socket2.parent][socket1.parent]==true))
	{
		return;
	}
	
	//printl("        HOW KEYS "+KEY_SPAWNS.len())
	//if (KEY_SPAWNS.len()>100000000&&KEYS<3) //	KEYS AND LOCKED DOORS TEMPORARILY DISABLED, sowwy.
	//{
	//	local KeyID=clamp(KEYS+1,1,3)
	//	local Door=GetVMFTable(TileSetFile,"locked_door00"+KeyID)
	//	local SocketRealPos=GetOffsetVector(socket1.origin,VMF1.Offsets.Offset,VMF1.Offsets.OffsetYaw)
	//	local DoorRealYaw=VMF1.Offsets.OffsetYaw+ToVector(socket1.angles).y
	//	local DoorTileRealAndSocketRotatedPos=GetOffsetVector(ToVector(Door.tile_info.origin),Vector(0,0,0),DoorRealYaw)
	//	if (socket1.socket_class=="default") 
	//	{
	//		Connectors.append(SpawnEntitiesFromVMF(Door,SocketRealPos-DoorTileRealAndSocketRotatedPos,DoorRealYaw,true));
	//		local KeyTilePos=ToVector(GetVMFTable(TileSetFile,"key00"+KeyID).tile_info.origin)
	//		Connectors.append(SpawnEntitiesFromVMF(GetVMFTable(TileSetFile,"key00"+KeyID),KEY_SPAWNS[RandInt(0,KEY_SPAWNS.len()/4)]-KeyTilePos,0,true))
	//		//debugoverlay.Text(KEY_SPAWNS[RandInt(0,KEY_SPAWNS.len()/4)]-KeyTilePos,"key00"+KeyID,10);
	//		KEY_SPAWNS=[]
	//		KEYS++
	//		ConnectorsAdded+=2
	//	}
	//	else return 0
	//}
	//else
	//{
	if ("no_door" in socket1||"no_door" in socket2) return 0;
	local randomdoor=GetRandomDoor(socket1.socket_class)
	if (randomdoor!=0)
	{
		local Door=GetVMFTable(TileSetFile,randomdoor)
		if (("blocked" in socket1)&&!("shortcut" in socket1)) {Door=GetVMFTable(TileSetFile,GetRandomBlocker(socket1.socket_class)); printl("Chose random blocker "+Door)}
		if (("blocked" in socket1)&&("shortcut" in socket1)) Door=GetVMFTable(TileSetFile,"shortcut"+socket1.shortcut.tostring())
		if (("blocked" in socket1)&&("shortcut" in socket1)&&socket1.shortcut==1) DontRemember=true;
		local SocketRealPos=GetOffsetVector(socket1.origin,VMF1.Offsets.Offset,VMF1.Offsets.OffsetYaw)
		local DoorRealYaw=VMF1.Offsets.OffsetYaw+ToVector(socket1.angles).y
		local DoorTileRealAndSocketRotatedPos=GetOffsetVector(ToVector(Door.tile_info.origin),Vector(0,0,0),DoorRealYaw)
		if ("blocked" in socket1)
		{
			//Entities.First().SetContextThink(UniqueString("stupidoverlay"),function(...){
			//debugoverlay.Cross3D(GetOffsetVector(socket1.origin,VMF1.Offsets.Offset,VMF1.Offsets.OffsetYaw),24,199,25,20,true,33)
			//}.bindenv(this),3)
			foreach (Tile in VMFs) foreach (Socket in Tile.Sockets)
			{
				if (Tile==VMF1) continue
				local distance=((GetOffsetVector(Socket.origin,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw)-GetOffsetVector(socket1.origin,VMF1.Offsets.Offset,VMF1.Offsets.OffsetYaw)).Length()).tointeger()
			
				if (distance<16)
				{
					local pos=GetOffsetVector(socket1.origin,VMF1.Offsets.Offset,VMF1.Offsets.OffsetYaw)
					local d=distance
					// Declaring locals for distance and pos again because they seem to be entirely different whenever contextthink is ran.
					
					Connections[socket1.parent][Socket.parent]=true
					Connections[Socket.parent][socket1.parent]=true
					socket1.rawdelete("blocked")
					if ("blocked" in Socket) Socket.rawdelete("blocked")
					
					socket1.taken<-VMFs.find(Tile)
					Socket.taken<-VMFs.find(VMF1)
					
					// Connect rooms for PVS and remove blocker marks from sockets
					
					Door=GetVMFTable(TileSetFile,randomdoor)
					// Change the selected connector from random blocker to random door.
					
					//Entities.First().SetContextThink(UniqueString("_stupidoverlay2"),function(...){
						//debugoverlay.Cross3D(pos,55,25,255,10,true,33);
					//}.bindenv(this),4)
					break
				}
			}
		}
		
		SpawnEntitiesFromVMF(Door,SocketRealPos-DoorTileRealAndSocketRotatedPos,DoorRealYaw,false);
	}

	Connections[socket1.parent][socket2.parent]=true
	Connections[socket2.parent][socket1.parent]=true

	return
}

local BadChoices=[]

local LastBlockedSocket=null

function UndoLastTile() //each history contains[connectors to remove, reference to socket that we added 'taken' to, copy of socket removed from freesockets, amount of free sockets added in the end]
{
	if (History.len()==0) return
	local LastState=History[History.len()-1]
	
	VMFs.remove(VMFs.len()-1)	//remove last tile info
	//for (local i=0;i<LastState[0];i++) Connectors.remove(Connectors.len()-1);	//remove last connector as many times as how many connectors were added last time (can be 0, can be 1 door, can be 2 like door and key.)
	//for (local i=0;i<LastState[0];i++) if ((Connectors.len()-(1+i))>=0) BlockedSockets[Connectors.len()-(1+i)]=null;	//remove last connector as many times as how many connectors were added last time (can be 0, can be 1 door, can be 2 like door and key.)
	Hulls.remove(Hulls.len()-1)	//remove last hull info
	local PreviousTileHaver=VMFs[LastState[5]]
	PreviousTileHaver.Sockets[LastState[0]].rawdelete("taken")	//make socket marked as free again
	//for (local i=0;i<LastState[3];i++) if () FreeSockets.remove(FreeSockets.len()-1);	// Remove free sockets which appeared last time.
	FreeSockets=GetAllFreeSockets()
	KEYS=LastState[3]
	KEY_SPAWNS=LastState[4]
	for (local i=0;i<LastState[6];i++) EXIT_SPAWNS.remove(EXIT_SPAWNS.len()-1);	// Remove free sockets which appeared last time.
	SocketID-=LastState[2]-1
	
	
	
	BadChoices=[]
	
	History.remove(History.len()-1)	//remove last piece of undo history after we rolled back. 
	LastBlockedSocket=null
	return
}

local RoomSpawnTime=[]

local blocks=0

function AddRandomConnectedRoom()
{
	local CodeTime=clock()
	if (FreeSockets.len()==0) return false;
	local socket1=FreeSockets[RandInt(0,FreeSockets.len()-1)]
	if (socket1==false) return false
	
	if (socket1.parent>(VMFs.len()-1)) {UndoLastTile();return true;}
	
	//printl("deciding on a room")

	//local TileSetSize=RoomBox.len()
	
	
	if ((GenerationTime+9)<clock())
	{
		//SendToConsoleServer("mapgen_clear");
		//SendToConsoleServer("changelevel mapgen_test");
		//CleanMapgen(1)

		//Entities.First().SetContextThink("MAPGEN_CLEAN",function (_) {CleanMapgen(1);return}.bindenv(this),0.5)
		Entities.First().SetContextThink("MAPGEN_RESTART",function (_) {RestartGenerator(1);player.SetMoveType(0);EntFire("camera_first","enable");return}.bindenv(this),1)
		Entities.First().SetContextThink("MAPGEN_RESTART2",function (_) {player.SetMoveType(2);return}.bindenv(this),2)
		
		CleanMapgen(1)
		SendToConsoleServer("fadein 1");
		//RestartGenerator(1)
		EntFire("camera_first","enable")
		
		
		//
		//	How many times these messages scared people shitless? I lost count.
		//  I really initially had to make some generic warning message whenever generator fails and RESTARTS
		//  Then decided to leave a deus ex reference for the funny, except I didn't think that this would happen frequently.
		//
		printl("Level generation restarted.");
		NXPrintDev(40, 255, 115, 115, true, 15, "Level generation restarted.");
		//NXPrint(40, 255, 115, 115, true, 15, "ICARUS FOUND YOU! ");
		//NXPrint(45, 255, 115, 115, true, 15, "ICARUS FOUND YOU!  ");
		//NXPrint(50, 255, 115, 115, true, 15, "ICARUS FOUND YOU!   ");
		//NXPrint(55, 255, 115, 115, true, 15, "ICARUS FOUND YOU!    ");
		//NXPrint(60, 255, 115, 115, true, 15, "ICARUS FOUND YOU!     ");
		//NXPrint(65, 255, 115, 115, true, 15, "ICARUS FOUND YOU!      ");
		//NXPrint(70, 255, 115, 115, true, 15, "RUN WHILE YOU CAN!     ");
		//NXPrint(75, 255, 115, 115, true, 15, "RUN WHILE YOU CAN!    ");
		//NXPrint(80, 255, 115, 115, true, 15, "RUN WHILE YOU CAN!   ");
		//NXPrint(85, 255, 115, 115, true, 15, "RUN WHILE YOU CAN!  ");
		//NXPrint(90, 255, 115, 115, true, 15, "RUN WHILE YOU CAN! ");
		//NXPrint(95, 255, 115, 115, true, 15, "RUN WHILE YOU CAN!");
		return false
	}
	
	local StartBiome="default"
	
	if (socket1.parent<=(VMFs.len()-1))
	{
		StartBiome=VMFs[socket1.parent].tile_info.biome
	}
	
	local MaxSockets=clamp(LAYOUT_SIZE-(VMFs.len()+GetAllFreeSockets().len())+1,1,99)
	
	local ChooseTile=function() 
	{
		local tile=GetRandomWeightedRoom(StartBiome,MaxSockets)
		
		local SocketCount=TileSet[tile].Sockets.len()
		
		//local UnclosedSockets=(SocketCount-1)+(GetAllFreeSockets().len()-1) // amount of rooms we will must add after placing this one, due to unclosed sockets.
		//local RoomsLeftToSpawn=LAYOUT_SIZE-VMFs.len()-1	// 0 if this room is final and must have only one socket. >0 if we can add extra rooms afterwards.
		
		foreach (s in TileSet[tile].Sockets)
		{
			if ("random_group" in s&&s.random_group.len()>0) SocketCount--
		}
		
		local Failures=0
		//while (((SocketCount==1)&&(RoomsAllowedForLater>0)&&(FreeSockets.len()==1))||((RoomsAllowedForLater<=0)&&(SocketCount>1)))
		while (((SocketCount<2)&&(GetAllFreeSockets().len()<2&&(VMFs.len())<(LAYOUT_SIZE-1)))||(SocketCount>1&&((VMFs.len()+GetAllFreeSockets().len())>(LAYOUT_SIZE-1)))||GetRandomSocket(TileSet[tile],socket1.socket_class)==false)
		{
			tile=GetRandomWeightedRoom(StartBiome,MaxSockets)
			
			SocketCount=TileSet[tile].Sockets.len()
			
			
			foreach (s in TileSet[tile].Sockets)
			{
				if ("random_group" in s&&s.random_group.len()>0) SocketCount--
			}
			Failures++
			
			if (Failures>100)
			{
				UndoLastTile();return false;
			}
		
			//UnclosedSockets=(SocketCount-1)+(GetAllFreeSockets().len()-1) // amount of rooms we will must add after placing this one, due to unclosed sockets.
			//RoomsLeftToSpawn=LAYOUT_SIZE-VMFs.len()-1	// 0 if this room is final and must have only one socket. >0 if we can add extra rooms afterwards.
		}
		
		
		
		return tile
	}

	local RoomChoice=ChooseTile()
	if (RoomChoice==false) return true;
	
	if (socket1.parent<=(VMFs.len()-1))
	{
		if (!("doubles_allowed" in VMFs[socket1.parent].tile_info)||VMFs[socket1.parent].tile_info.doubles_allowed==0) while ( (RoomChoice == VMFs[socket1.parent].tile_info.tile_name) || (TilesCompatible(RoomChoice,VMFs[socket1.parent].tile_info.tile_name) == false )) {printl(RoomChoice+" didn't work because it was incompatible with "+VMFs[socket1.parent].tile_info.tile_name+" or a double.");RoomChoice=ChooseTile();}
		if (RoomChoice==false) return true;
		//while (TilesCompatible(RoomChoice,VMFs[socket1.parent].tile_info.tile_name)) RoomChoice=ChooseTile();
	}
		
	local Tile=SpawnEntitiesFromVMF(GetVMFTable(TileSetFile,RoomChoice),Vector(0,0,0),0,true)
	//local Tile=SpawnEntitiesFromVMF(GetVMFTable("example","room00"),Vector(0,0,0),0,true)
	if (Tile==false) {printerror("Failed to spawn a connected room.");return true}

	while (GetRandomSocket(Tile,socket1.socket_class)==false) {
		printl("Couldn't find right socket class in "+RoomChoice)
		RoomChoice=ChooseTile()
		if (socket1.parent<=(VMFs.len()-1))
		{
			if (!("doubles_allowed" in VMFs[socket1.parent].tile_info)||VMFs[socket1.parent].tile_info.doubles_allowed==0) while ( (RoomChoice == VMFs[socket1.parent].tile_info.tile_name) || (TilesCompatible(RoomChoice,VMFs[socket1.parent].tile_info.tile_name) == false )) {printl(RoomChoice+" didn't work because it was incompatible with "+VMFs[socket1.parent].tile_info.tile_name+" or a double.");RoomChoice=ChooseTile();}
		}
		
		if (RoomChoice==false) return true;
		
		Tile=SpawnEntitiesFromVMF(GetVMFTable(TileSetFile,RoomChoice),Vector(0,0,0),0,true)
	}
	
	local socket2=GetRandomSocket(Tile,socket1.socket_class);
	//local VMF1=FindSocketParent(VMFs,socket1)
	if (socket1.parent>(VMFs.len()-1)) {UndoLastTile();return true;}
	local VMF1=VMFs[socket1.parent]

	ConnectRooms(VMF1,Tile,socket1,socket2)
	
	local HullA=GetOffsetVector(Tile.tile_info.TileBBoxA,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw)
	local HullB=GetOffsetVector(Tile.tile_info.TileBBoxB,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw)
	
	foreach (hull in Hulls)
	{
		//if ((hull[0]-HullA).Length()>1200) continue;
		//net2=null
		if (CheckHullOverlap(HullA,HullB,hull[0],hull[1])) {
			//local center=(HullA+HullB)/2
			//local center2=(hull[0]+hull[1])/2
			//debugoverlay.Box(center,center-HullA,center-HullB,255,20,20,40,2.5);
			//debugoverlay.Box(center2,center2-hull[0],center2-hull[1],255,255,20,45,3.25);
			printerror("ROOMS OVERLAPPING");
			printerror("FREE SOCKETS "+FreeSockets.len());
			FailedRooms++
			if (FailedRooms<1) {
			return true}
			else {
			//debugoverlay.Box(center,center-HullA,center-HullB,255,20,20,40,2.5);
			//debugoverlay.Box(center2,center2-hull[0],center2-hull[1],255,255,20,45,3.25);
			
			if (GetAllFreeSockets().len()>1&&(!("noblocking" in socket1&&socket1.noblocking.tostring()=="1")))
			{
				local TakenSocket=GetSocketField(socket1,VMF1)	//This should be a reference to socket that we just took. Hopefully this works.
				socket1.taken<-(VMFs.find(VMF1))	// yes, blocked sockets are marked as taken by themselves.
				VMF1.Sockets[TakenSocket].taken<-(VMFs.find(VMF1))	// yes, blocked sockets are marked as taken by themselves.
				FreeSockets.remove(FreeSockets.find(socket1))
				FreeSockets=GetAllFreeSockets()
				socket1.blocked<-(1);
				VMF1.Sockets[TakenSocket].blocked<-(1);
				//local FreeSocketsToAdd=GetFreeSockets(VMFs[VMFs.len()-1],"any")
				FailedRooms=0;
				
				if (LastBlockedSocket!=null&&RandInt(1,10)==1&&GetVMFTable(TileSetFile,"shortcut1")!=0)
				{
					VMFs[LastBlockedSocket[0]].Sockets[LastBlockedSocket[1]].shortcut<-(1)
					VMF1.Sockets[TakenSocket].shortcut<-(2)
				
					LastBlockedSocket=null
				}
				else LastBlockedSocket=[VMFs.find(VMF1),TakenSocket];
				
				RoomSpawnTime.append(clock()-CodeTime)
				//NXPrintDev(41+RandomInt(-5,5), 255, 115, 115, true, 15, "BLOCKED SOCKET");
				blocks++;
				//printl("                                                    BLOCKED SOCKET")
				return true
			}
			
			UndoLastTile()
			FailedRooms=0
			//AddRandomConnectedRoom()
			//Entities.First().SetContextThink("aboba",RestartGenerator.bindenv(this),0)
			//RestartGenerator(1)
			return true
			}
			return false
			}
	}
	
	if (GetSocketField(socket1,VMF1)==false) {UndoLastTile();return true;}
	VMFs.append(Tile)
	//local ConnectorsAdded=PlaceDoor(VMF1,Tile,socket1,socket2)
	Hulls.append([HullA,HullB])
	local TakenSocket=GetSocketField(socket1,VMF1)	//This should be a reference to socket that we just took. Hopefully this works.
	VMF1.Sockets[TakenSocket].taken<-VMFs.find(Tile)
	socket1.taken<-(VMFs.find(Tile))
	FreeSockets=GetAllFreeSockets()
	local UnfreedSocket=0	//copy information about socket that we just removed from free sockets array
	
	//local center=(HullA+HullB)/2

	//debugoverlay.Box(center,center-HullA,center-HullB,205,200,200,25,2)
	local FreeSocketsToAdd=GetFreeSockets(VMFs[VMFs.len()-1],"any")
	if (GetFreeSockets(VMFs[VMFs.len()-1],"any")!=false) 
	{
		foreach (S in FreeSocketsToAdd) FreeSockets.append(S);
	}
	printl("available sockets "+FreeSockets.len())
	FailedRooms=0;
	
	if ((typeof FreeSocketsToAdd)!="array") FreeSocketsToAdd=[];
	
	History.append([TakenSocket,UnfreedSocket,FreeSocketsToAdd.len(),KEYS,RealCopy(KEY_SPAWNS),VMFs.find(VMF1),GetExitSpawns(VMFs[VMFs.len()-1])])
	//each history contains[connectors to remove, reference to socket that we added 'taken' to, copy of socket removed from freesockets, amount of free sockets added in the end]
	GetKeySpawns(Tile)
	printl("ROOM "+VMFs.len()+" SPAWNED AFTER "+(clock()-CodeTime))
	RoomSpawnTime.append(clock()-CodeTime)
	
	return true
}

function PrintTime()
{
	local sum=0
	foreach (t in RoomSpawnTime) sum+=t
	NXPrintDev(30, 255, 115, 115, true, 15, "AVERAGE ROOM SPAWN TIME - "+(sum/RoomSpawnTime.len()));
	NXPrintDev(32, 255, 115, 115, true, 15, "TOTAL SPAWN TIME - "+(clock()-GenerationTime));
	NXPrintDev(34, 255, 115, 115, true, 15, "BLOCKED SOCKETS - "+blocks);
}

function AddConnectedRoom(file,pos=Vector(0,0,0))	//	UNUSED. TODO: MAKE WORK BY SPECIFYING BOTH VMF AND TILE
{
	local Tile=null
	if (VMFs.len()>1)
	{
		local socket1=FreeSockets[RandInt(0,FreeSockets.len()-1)]
		if (socket1==false) return false

		local Tile=SpawnEntitiesFromVMF(GetVMFTable(TileSetFile,file),pos,0,true)
		if (Tile==false) {printerror("Failed to spawn a connected room.");return false}
		VMFs.append(Tile)

		local socket2=GetRandomSocket(VMFs[VMFs.len()-1],socket1.socket_class)
		if (socket2==false) return true;

		ConnectRooms(VMFs[VMFs.len()-2],VMFs[VMFs.len()-1],socket1,socket2)
	}
	else 
	{
		Tile=SpawnEntitiesFromVMF(GetVMFTable(TileSetFile,file),pos,0,true)
		if (Tile==false) {printerror("Failed to spawn a connected room.");return false}
		VMFs.append(Tile)
	}
	
	local HullA=GetOffsetVector(Tile.tile_info.TileBBoxA,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw)
	local HullB=GetOffsetVector(Tile.tile_info.TileBBoxB,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw)
	
	foreach (hull in Hulls)
	{
		if (CheckHullOverlap(HullA,HullB,hull[0],hull[1])) {
			local center=(HullA+HullB)/2
			local center2=(hull[0]+hull[1])/2
			//debugoverlay.Box(center,center-HullA,center-HullB,255,20,20,40,6);
			//debugoverlay.Box(center2,center2-hull[0],center2-hull[1],255,255,20,45,5);
			printerror("ROOMS OVERLAPPING");
			SendToConsole("mapgen_test")
			return false
			}
	}
	//printl("Adding hull with "+HullA+" "+HullB)
	Hulls.append([HullA,HullB])
	
	local center=(HullA+HullB)/2

	FreeSockets.extend(GetFreeSockets(VMFs[VMFs.len()-1],"any"))
	GetKeySpawns(VMFs[VMFs.len()-1])
	return true
}

local RESTARTS=0

function CleanMapgen(_)
{
	Hulls=[]
	VMFs=[]
	//Connectors=[]
	Connections<-array(LAYOUT_SIZE);	// array of connectors was stupid for shortcuts, so we'll use matrix for edge connections like normal people do. Used only when actually spawning doors.
	for (local i = 0 ; i < LAYOUT_SIZE ; i++) Connections[i]=array(LAYOUT_SIZE)
	Blocks=[]
	BlockedSockets=array(128)
	Shortcuts=array(128)
	FreeSockets=[]
	BadChoices=[]
	NAMES=[]
	KEY_SPAWNS=[]
	History=[]
	KEYS=0
	SocketID=0
	EXIT_SPAWNS=[]
	
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START",function (_) {EntFire("player","SetAbsOrigin",SpawnVector.x+" "+SpawnVector.y+" "+SpawnVector.z,0);return}.bindenv(this),3)
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START4",function (_) {EntFire("start_particle_main","kill","",0);return}.bindenv(this),5)
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START2",function (_) {EntFire("map_start","trigger","",0);EntFire("start_move","setspeedreal","1",0);return}.bindenv(this),1.5)
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START3",function (_) {EntFire("start_particle_main","SetAbsOrigin",SpawnVector.x+" "+SpawnVector.y+" "+(SpawnVector.z+5),0);EntFire("start_shockwave","SetAbsOrigin",SpawnVector.x+" "+SpawnVector.y+" "+(SpawnVector.z+264),0);return}.bindenv(this),2.5)
	
	local ent=null
	while (ent=Entities.FindByClassnameWithin(ent,"prop*",Vector(),5000)) ent.Destroy();
	while (ent=Entities.FindByClassnameWithin(ent,"ambient_generi*",Vector(),5000)) {if (ent.GetName().find("SW")==null&&ent.GetName().find("start")==null) ent.Destroy();}
	while (ent=Entities.FindByClassnameWithin(ent,"func_useableladder",Vector(),5000)) ent.Destroy();
	ent=null
	while (ent=Entities.FindByClassnameWithin(ent,"item*",Vector(),5000)) ent.Destroy();
	while (ent=Entities.FindByClassnameWithin(ent,"beam",Vector(),5000)) ent.Destroy();
	while (ent=Entities.FindByClassnameWithin(ent,"point*",Vector(),5000)) {if (ent.GetName().find("camera_first")==null) ent.Destroy();}
	while (ent=Entities.FindByClassnameWithin(ent,"logic_auto",Vector(),5000)) ent.Destroy();
	while (ent=Entities.FindByClassnameWithin(ent,"filter*",Vector(),5000)) {if (ent.GetName().find("SW")==null) ent.Destroy();}
	//while (ent=Entities.FindByClassnaWithinme(ent,"weapon*")) {if (ent.GetOwner()==null) ent.Destroy();}
	while (ent=Entities.FindByClassnameWithin(ent,"npc*",Vector(),5000)) ent.Destroy();
	while (ent=Entities.FindByClassnameWithin(ent,"env*",Vector(),5000)) {if (ent.GetName().find("start")==null) ent.Destroy();}
	while (ent=Entities.FindByClassnameWithin(ent,"info_part*",Vector(),5000)) {if (ent.GetName().find("start")==null) ent.Destroy();}
	//while (ent=Entities.FindByClassnameWithin(ent,"info_player*",Vector(),5000)) ent.Destroy();
	while (ent=Entities.FindByClassnameWithin(ent,"light_dynamic",Vector(),5000)) {if (ent.GetName()!="stunsticklight") ent.Destroy();}
	
	return
}


::MinPos<-Vector(5000,5000,5000)
::MaxPos<-Vector(-5000,-5000,-5000)

function RestartGenerator(_)
{

	GenerationTime=999+clock()

	//LoadTileset("example")
	LoadTileset(GetTilesetFromID(TilesetID).filename)

	START=Vector(-268,1834,516)
	::GLOBAL_OFFSET<-Vector()

	::StartingTile<-(0);


	::MinPos<-Vector(5000,5000,5000)
	::MaxPos<-Vector(-5000,-5000,-5000)
	blocks=0
	RoomSpawnTime=[]
	LastBlockedSocket=null
	PlayerSpawns=[]
	FailedRooms=0

	RESTARTS++
	Hulls=[]
	//local SEED=RandInt(10,99999999)
	SetRNGSeed(Globals.GetCounter(Globals.GetIndex("InitialRNGSeed"))+RESTARTS-1);
	SetRNGSeed(Globals.GetCounter(Globals.GetIndex("InitialRNGSeed"))+RESTARTS-1);
	//LAYOUT_SIZE=3
	VMFs=[]
	//Connectors=[]
	::Connections<-array(LAYOUT_SIZE);	// array of connectors was stupid for shortcuts, so we'll use matrix for edge connections like normal people do. Used only when actually spawning doors.
	for (local i = 0 ; i < LAYOUT_SIZE ; i++) Connections[i]=array(LAYOUT_SIZE)
	Blocks=[]
	BlockedSockets=array(128)
	Shortcuts=array(128)
	FreeSockets=[]
	BadChoices=[]
	NAMES=[]
	KEY_SPAWNS=[]
	EXIT_SPAWNS=[]
	PLAYER_SPAWNS=[]
	History=[]
	KEYS=0
	SocketID=0
	GenerationTime=clock()
	
	
	//printl("Retrying with seed: "+SEED)
	RandInt(1,2)
	
	local ent=null
	if (RESTARTS>1)
	{
		//while (ent=Entities.FindByClassnameWithin(ent,"prop*",Vector(),5000)) ent.Destroy();
		//while (ent=Entities.FindByClassnameWithin(ent,"ambient_generi*",Vector(),5000)) {if (ent.GetName().find("SW")==null) ent.Destroy();}
		//while (ent=Entities.FindByClassnameWithin(ent,"func_useableladder",Vector(),5000)) ent.Destroy();
		//ent=null                           
		//while (ent=Entities.FindByClassnameWithin(ent,"item*",Vector(),5000)) ent.Destroy();
		//while (ent=Entities.FindByClassnameWithin(ent,"beam",Vector(),5000)) ent.Destroy();
		//while (ent=Entities.FindByClassnameWithin(ent,"point*",Vector(),5000)) ent.Destroy();
		//while (ent=Entities.FindByClassnameWithin(ent,"env*",Vector(),5000)) ent.Destroy();
		//while (ent=Entities.FindByClassnameWithin(ent,"info_partic*",Vector(),5000)) ent.Destroy();
		//while (ent=Entities.FindByClassnameWithin(ent,"logic_auto",Vector(),5000)) ent.Destroy();
		//while (ent=Entities.FindByClassnameWithin(ent,"filter*",Vector(),5000)) {if (ent.GetName().find("SW")==null) ent.Destroy();}
		//while (ent=Entities.FindByClassnameWithin(ent,"weapon*",Vector(),5000)) {if (ent.GetOwner()==null) ent.Destroy();}
		//while (ent=Entities.FindByClassnameWithin(ent,"npc*")) ent.Destroy();
		//while (ent=Entities.FindByClassnameWithin(ent,"light_dynamic")) {if (ent.GetName()!="stunsticklight") ent.Destroy();}
	}
	
	AddConnectedRoom(GetRandomStartRoom(),START)
	
	GetPlayerSpawns(VMFs[0])
	
	while (AddRandomConnectedRoom()==true) {printl("Placed tile")}
	
	//local MinPos=Vector(5000,5000,5000)
	//local MaxPos=Vector(-5000,-5000,-5000)
	
	foreach (Hull in Hulls)
	{
		local HullMinX=min(Hull[0].x,Hull[1].x)
		local HullMinY=min(Hull[0].y,Hull[1].y)
		local HullMinZ=min(Hull[0].z,Hull[1].z)
		local HullMaxX=max(Hull[0].x,Hull[1].x)
		local HullMaxY=max(Hull[0].y,Hull[1].y)
		local HullMaxZ=max(Hull[0].z,Hull[1].z)
	
		if (HullMinX<MinPos.x||HullMinY<MinPos.y||HullMinZ<MinPos.z) MinPos=Vector(min(MinPos.x,HullMinX),min(MinPos.y,HullMinY),min(MinPos.z,HullMinZ))
		if (HullMaxX>MaxPos.x||HullMaxY>MaxPos.y||HullMaxZ>MaxPos.z) MaxPos=Vector(max(MaxPos.x,HullMaxX),max(MaxPos.y,HullMaxY),max(MaxPos.z,HullMaxZ))
	}
	//printl(MinPos)
	//printl(MaxPos)
	//NXPrintDev(38, 155, 255, 115, true, 15, MinPos+" MinPos");
	//NXPrintDev(40, 255, 115, 115, true, 15, MaxPos+" MaxPos");
	
	//debugoverlay.Line(MinPos+START,MaxPos+START,255,255,255,true,10)
	//debugoverlay.Line(MinPos,MaxPos,255,255,255,true,10)
	GLOBAL_OFFSET.z=((-500)-MinPos.z)
	GLOBAL_OFFSET.x=((-5350)-MinPos.x)
	GLOBAL_OFFSET.y=((-1000)-MinPos.y)
	
	foreach (Hull in Hulls)
	{
		Hull[0]+=GLOBAL_OFFSET;
		Hull[1]+=GLOBAL_OFFSET;
	}
	
	//AddConnectedRoom("room002")
	foreach (VMF in VMFs) SpawnEntitiesFromVMF(VMF,VMF.Offsets.Offset+GLOBAL_OFFSET,VMF.Offsets.OffsetYaw)
	//foreach (VMF in Connectors) SpawnEntitiesFromVMF(VMF,VMF.Offsets.Offset+GLOBAL_OFFSET,VMF.Offsets.OffsetYaw)
	
	foreach (VMF in VMFs) foreach (Socket in VMF.Sockets)
	{
		local socket2=null
		foreach (s in VMFs[Socket.taken].Sockets) if (s.taken==VMFs.find(VMF)) socket2=s;
		PlaceDoor(VMF,VMFs[Socket.taken],Socket,socket2)
	}
	
	foreach (VMF in Blocks) SpawnEntitiesFromVMF(VMF,VMF.Offsets.Offset+GLOBAL_OFFSET,VMF.Offsets.OffsetYaw)
	local ExitTilePos=ToVector(GetVMFTable(TileSetFile,"exit").tile_info.origin)
	
	local RightID=EXIT_SPAWNS.len()-1
	
	
	local SpawnNum=RandInt(0,PLAYER_SPAWNS.len()-1)
	local SpawnVector=PLAYER_SPAWNS[SpawnNum][0]+GLOBAL_OFFSET
	local SpawnAngle=PLAYER_SPAWNS[SpawnNum][1]
	
	foreach (i,exit in EXIT_SPAWNS)
	{
		if ((EXIT_SPAWNS[RightID]-SpawnVector).Length()<(exit-SpawnVector).Length()) RightID=i;
	}
	
	SpawnEntitiesFromVMF(GetVMFTable(TileSetFile,"exit"),EXIT_SPAWNS[RightID]-ExitTilePos+GLOBAL_OFFSET,0)
	EXIT_SPAWNS=[]
	printl(Hulls.len()+" HULLS and "+VMFs.len()+" TILES WITH "+KEYS+" KEYS")
	NXPrintDev(10, 155, 255, 115, true, 15, VMFs.len()+" TILES");
	NXPrintDev(15, 255, 115, 115, true, 15, KEYS+" KEYS");
	NXPrintDev(20, 255, 115, 115, true, 15, RESTARTS+" TOTAL RESTARTS");
	NXPrintDev(25, 155, 255, 115, true, 15, "SEED: "+Globals.GetCounter(Globals.GetIndex("InitialRNGSeed")));
	
	// PLAYTEST DEBUG
	//if (Convars.GetInt("budget_show_peaks")==1) NXPrint(10, 5, 175, 5, true, 999, "SEED: "+Globals.GetCounter(Globals.GetIndex("InitialRNGSeed"))+" : "+VMFs.len()+"                                    ");
	
	
	PrintTime()
	//EntFire("ambienc*","ToggleSound","",0.5)
	//EntFire("ambienc*","ToggleSound","",5.5)
	
	//local SpawnVector=PLAYER_SPAWNS[RandInt(0,PLAYER_SPAWNS.len()-1)]+GLOBAL_OFFSET
	
	foreach (i,hull in Hulls)
	{
		if (IsOriginInBBox(SpawnVector,hull[0],hull[1]))
		{
			StartingTile=i;
			break
		}
	}
	
	//player.SetOrigin(SpawnVector)
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START",function (_) {EntFire("player","SetAbsOrigin",SpawnVector.x+" "+SpawnVector.y+" "+SpawnVector.z,0);return}.bindenv(this),3)
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START5",function (_) {player.SetAngles(SpawnAngle);return}.bindenv(this),4.1)
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START4",function (_) {EntFire("start_particle_main","kill","",0);return}.bindenv(this),5)
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START2",function (_) {EntFire("map_start","trigger","",0);EntFire("start_move","setspeedreal","1",0);return}.bindenv(this),1.5)
	Entities.First().SetContextThink("MAPGEN_PLAYER_TP_START3",function (_) {EntFire("start_particle_main","SetAbsOrigin",SpawnVector.x+" "+SpawnVector.y+" "+(SpawnVector.z+5),0);EntFire("start_shockwave","SetAbsOrigin",SpawnVector.x+" "+SpawnVector.y+" "+(SpawnVector.z+264),0);return}.bindenv(this),2.5)
	//EntFire("player","SetAbsOrigin",SpawnVector.x+" "+SpawnVector.y+" "+SpawnVector.z,4.5)
	//EntFire("player","SetAbsOrigin",SpawnVector.x+" "+SpawnVector.y+" "+SpawnVector.z,0.2)
	return
}


Convars.RegisterCommand( "mapgen_test", RestartGenerator.bindenv(this), "", FCVAR_NONE );
Convars.RegisterCommand( "mapgen_clear", CleanMapgen.bindenv(this), "", FCVAR_NONE );
Convars.RegisterCommand( "mapgen_tileset", LoadTileset.bindenv(this), "", FCVAR_NONE );

SendToConsoleServer("mapgen_test");
//EntFire("func_button","Use","",1)

function DrawHull(hull,r,g,b,a)
{
	//local center=(hull[0]+hull[1])/2
	// I think debugoverlays cause some sort of leak which causes mod perfomance to worsen over time, visible by fps getting lower.
	//debugoverlay.Box(center,center-hull[0],center-hull[1],r,g,b,a,0.12);
	//debugoverlay.Box(center,center-hull[0]+Vector(0,0,(center.z-hull[1].z)*2+2),center-hull[1],r,g,b,a,0.12);
}

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
    return ((oa*ob < 0) && (oc*od < 0));
}

function AreEqual(a,b)
{
	if (fabs(a-b)<1) return true;
	return false;
}

function SocketsVisible(SocketA,SocketB,SocketC)
{
	local A=SocketA[0]
	local B=SocketB[0]
	
	local Mid1=SocketC[0]
	local Mid2=SocketC[1]
	
	local ALen=SocketA[1]-SocketA[0]
	local BLen=SocketB[1]-SocketB[0]
	
	if (AreEqual(SocketB[0].x,SocketC[1].x)&&AreEqual(SocketA[1].x,SocketC[0].x)||AreEqual(SocketB[0].y,SocketC[1].y)&&AreEqual(SocketA[1].y,SocketC[0].y))
	{
		return false;
	}
	// Parallel sockets cannot see each other.
	
	if (SocketB[0].x==SocketC[0].x&&SocketB[0].y==SocketC[0].y) 
	{
		//debugoverlay.Line(A+ALen.Normalized()*ALen.Length()/2,B+BLen.Normalized()*BLen.Length()/2,25,255,25,true,0.12)
		return true;
	}
	//printl(SocketB[0]+" "+SocketB[1])
	//printl(SocketC[0]+" "+SocketC[1])
	
	for (local i=0;i<max(ALen.Length(),BLen.Length());i+=8)
	{
		local Point1=A+ALen.Normalized()*i
		local Point2=B+BLen.Normalized()*i
		
		if (LineInter(Point1,Point2,Mid1,Mid2))
		{
			//debugoverlay.Line(A+ALen.Normalized()*ALen.Length()/2,B+BLen.Normalized()*BLen.Length()/2,25,255,25,true,0.12)
			return true
		}
		//debugoverlay.Line(Point1,Point2,255,25,25,true,0.12)
	}
	return false
}

function GetAdjacentTiles(CurTile)	//returns arrays containing IDs of adjacent tiles along with references to their sockets.
{
	local AdjTiles=[]
	if ((typeof CurTile)=="integer") CurTile=VMFs[CurTile];
	
	foreach (socket in CurTile.Sockets)
	{
		if ("taken" in socket) if (socket.taken<=VMFs.len())
		{
			AdjTiles.append([socket.taken,socket])
			//AdjTilesSocketPointers.append(socket)
		}
	}
	return AdjTiles
}

function GetSocketLine(CurTile,socket)
{
	local radius=24
	if ("radius" in socket&&socket.radius&&socket.radius!="0")
	{
		radius=socket.radius;
	}

	local SocketA=GetOffsetVector(ToVector(socket.origin)+RotateVectorYaw(Vector(0,radius,0),ToVector(socket.angles).y),CurTile.Offsets.Offset,CurTile.Offsets.OffsetYaw)
	local SocketB=GetOffsetVector(ToVector(socket.origin)+RotateVectorYaw(Vector(0,-radius,0),ToVector(socket.angles).y),CurTile.Offsets.Offset,CurTile.Offsets.OffsetYaw)
	
	return [SocketA,SocketB]
}
// Takes Tile and the socket. Returns an array of 2 vector points representing the socket portal.

local PVSLocked=false;
local LastPos=Vector(0,0,0)
local ExploredTiles=[]

local MapInfoSent=0
local NodesSent=false
local NodesBuilt=false

local EntIndexes=[]

local PVSData={}
::PVSStatus<-{}

local aigens=0

local NodesAmount=0
local NodesVecs=[]
local NodesTiles=[]
local TakenNodes=[]
local EnemyTiles=[]


local Global_EnemyBudget=null
local Global_TrapBudget=null
local Global_LootBudget=null

local Global_LootHulls=[]

local npc_spawns=0

function IsDeadEnd(id)
{
	local TrueSockets=VMFs[id].Sockets.len()
	foreach (s in VMFs[id].Sockets)
	{
		if (s.taken==id) TrueSockets--;
	}
	return (TrueSockets==1)
}
function IsNextToDeadEnd(id)
{
	if (RandFloat(0,1)<GetTilesetFromID(TilesetID).enemyspawn_random_chance) return true;
	if (IsDeadEnd(id)&&(RandFloat(0,1)<GetTilesetFromID(TilesetID).enemyspawn_deadend_chance)) return true;
	
	foreach (neighbour in GetAdjacentTiles(id))
	{
		if (neighbour[0]!=id&&IsDeadEnd(neighbour[0])) return true;
	}
	return false;
}

function PlaySoundScape(name)
{
	SendToConsole("playsoundscape "+name)
	SendToConsole("dsp_automatic 0")
}


local LastPlayerTile=0
local LastPlayerZ=5000


if (SERVER_DLL)
{

	::OBJECTIVES<-[]

	class Objective
	{
		ID=null
		DisplayName=""
		Description=""
		Status=false;
		Reward=0;

		constructor(id)
		{
			switch(id)
			{
				case 1: {DisplayName="Exploration";Description="Explore the area.";Reward=25*Hulls.len();break}
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
		
		NetMsg.Start("OBJECTIVE_ADD")
		NetMsg.WriteShort(id)
		NetMsg.Send(player,true)
		printl("Added objective "+id)
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
		
		NetMsg.Start("OBJECTIVE_COMPLETE")
		NetMsg.WriteShort(id)
		NetMsg.Send(player,true)
		
		AddPlayerMoney(obj.Reward)
		AddPlayerXP((obj.Reward/5.0).tointeger())
		
		printl("Completed objective "+id)
	}
	
	function ObjectiveActive(id)
	{
		local obj=null;
		
		foreach (o in OBJECTIVES) if (o.ID==id) obj=o;
		
		if (obj.Status==false) return true;
		else return false;
	}

}

::VisibleSet<-[]

local LastPlayerZ=0

function ShowHulls()
{
	VisibleSet=[]
	local VisibleSocketPointers=[]
	// Socket pointer of same ID as Tile's ID in Visible set references the socket that we enter the tile from. As in, player needs to see this socket in order to see the tile.
	local Queue=[]
	
	if (!PVSLocked) LastPos=player.GetCenter();
	
	if (PVSLocked) {
		//debugoverlay.Cross3D(LastPos,20,25,255,25,true,0.12)
		DrawHull([LastPos-Vector(0,0,48)+player.GetBoundingMins(),LastPos-Vector(0,0,48)+player.GetBoundingMaxs()],255,55,125,30*fabs(sin(Time()*4)))
		//debugoverlay.Text(LastPos,"Player Viewpoint",0.12)
	}
	
	local CurTile=-1;
	
	local PlayerPosSent=false
	
	foreach (i,hull in Hulls)
	{
		if (PlayerPosSent) break;
		
		if (IsOriginInBBox(LastPos,hull[0],hull[1])) 
		{
			DrawHull(hull,55,255,2,0);
			CurTile=i
			if ((CurTile!=LastPlayerTile)||(fabs(LastPlayerZ-VMFs[i].ZFloor)>0.15))
			{
				
				
				
				local PlayerElevation=0
				
				local FlatTile=true
				if (CurTile!=(-1)) foreach (socket in VMFs[CurTile].Sockets)
				{
					if (abs((ToVector(socket.origin).z)-(ToVector(VMFs[CurTile].Sockets[0].origin).z))>16)
					{
						FlatTile=false;
						break
					}
				}
				
				if (LastPos.z>((hull[0].z+hull[1].z)/2)) PlayerElevation=(0.5)
				else PlayerElevation=(-0.5)
				
				if (FlatTile) PlayerElevation=0;
				
				if (LastPlayerZ!=(VMFs[i].ZFloor+PlayerElevation))
				{
					NetMsg.Start("MAPGEN_PLAYER_Z");
					NetMsg.WriteFloat(VMFs[i].ZFloor+PlayerElevation)
					NetMsg.WriteShort(i)
					NetMsg.Send(player, true);
					printl("sent playerz")
					PlayerPosSent=true
					LastPlayerZ=(VMFs[i].ZFloor+PlayerElevation)
				}
			}
		}
		if (PVSStatus.len()<Hulls.len()) PVSStatus.rawset(i.tostring(),true)
		if (PVSStatus.len()<Hulls.len()) EntFire(i+"_*","addeffects",32)
	}
	
	//foreach (t in VMFs)
	//{
	//	foreach (l in t.Loot)
	//	{
	//		debugoverlay.Text(GetOffsetVector(ToVector(l.origin),t.Offsets.Offset,t.Offsets.OffsetYaw),"Loot",0.3)
	//		local center=GetOffsetVector(ToVector(l.origin),t.Offsets.Offset,t.Offsets.OffsetYaw)
	//		// I think debugoverlays cause some sort of leak which causes mod perfomance to worsen over time, visible by fps getting lower.
	//		debugoverlay.Box(center,GetOffsetVector(ToVector(l.size_mins),Vector(),t.Offsets.OffsetYaw),GetOffsetVector(ToVector(l.size_maxs),Vector(),t.Offsets.OffsetYaw),255,255,25,20,0.3);
	//		//debugoverlay.Box(center,center-hull[0]+Vector(0,0,(center.z-hull[1].z)*2+2),center-hull[1],r,g,b,a,0.12);
	//	}
	//}
	
	local soundscape=null
	
	if (CurTile!=(-1)&&(Hulls[CurTile][1]-Hulls[CurTile][0]).Length()<500)
	{
		soundscape="general.concrete_quiet"
	}
	else soundscape="coast.bridge_concrete_room";
	
	if (CurTile==(-1)) soundscape="ep1_citadel.deep_dropoff_inside";
	
	if (CurTile!=(-1)) soundscape=LIST_SOUNDSCAPES[(CurTile+(Hulls[CurTile][1]-Hulls[CurTile][0]).Length())%LIST_SOUNDSCAPES.len()];
	
	PlaySoundScape(soundscape);
	
	if (!Convars.GetFloat("sourceworld_minimap_size")) CurTile=-1;
	if (CurTile!=(-1)) {
		if (ExploredTiles.find(CurTile)==null)
		{
			//NetMsg.Reset()
			NetMsg.Start("MAPGEN_EXPLORATION");
			NetMsg.WriteShort(CurTile)
			NetMsg.Send(player, true);
			//printl("sent exploration")
			ExploredTiles.append(CurTile)
			if (ExploredTiles.len()==Hulls.len()&&ObjectiveActive(1)) CompleteObjective(1)
		}
		VisibleSet.append(CurTile)
		VisibleSocketPointers.append(0)
		CurTile=VMFs[CurTile];
	}
	
	//if (Time()>180&&CurTile==LastPlayerTile) return;
	
	//else return 0.1;
	
	if (!(CurTile.tostring() in PVSData))
	{
		
		local DrawnHulls=[]
		
		if (CurTile!=(-1)) foreach (socket in CurTile.Sockets)
		{
			if ("taken" in socket) if (socket.taken<=VMFs.len())
			{
				VisibleSet.append(socket.taken)
				VisibleSocketPointers.append(socket)
				
				DrawnHulls.append(socket.taken)
				
				//DrawHull(Hulls[socket.taken],255,175,5,0);
				//debugoverlay.Cross3D(GetOffsetVector(socket.origin,CurTile.Offsets.Offset,CurTile.Offsets.OffsetYaw),8,255,155,80,true,0.12)
				
				local radius=24
				if ("radius" in socket&&socket.radius&&socket.radius!="0")
				{
					radius=socket.radius;
				}
				local SocketA=GetOffsetVector(ToVector(socket.origin)+RotateVectorYaw(Vector(0,radius,0),ToVector(socket.angles).y),CurTile.Offsets.Offset,CurTile.Offsets.OffsetYaw)
				local SocketB=GetOffsetVector(ToVector(socket.origin)+RotateVectorYaw(Vector(0,-radius,0),ToVector(socket.angles).y),CurTile.Offsets.Offset,CurTile.Offsets.OffsetYaw)
				
				//debugoverlay.Cross3D(SocketA,4,80,80,255,true,0.12)
				//debugoverlay.Cross3D(GetOffsetVector(ToVector(socket.origin)+RotateVectorYaw(Vector(24,0,0),ToVector(socket.angles).y),CurTile.Offsets.Offset,CurTile.Offsets.OffsetYaw),4,80,255,80,true,0.12)
				//debugoverlay.Cross3D(SocketB,4,80,80,255,true,0.12)
			}
		}
		// By this moment, our queue is empty, but visibleset has current player tile and its adjacent tiles.
		foreach (id in VisibleSet)
		{
			foreach (neighbour in GetAdjacentTiles(id))
			{
				if (VisibleSet.find(neighbour[0])!=null) continue;
				if (Queue.find([neighbour[0],neighbour[1]])!=null) continue;
				Queue.append([neighbour[0],neighbour[1]])
				// Add all visibleset's adjacent tiles to the queue, unless they're in visibleset already too. 0 is ID, 1 is socket reference.
			}
		}
		while (Queue.len()>0)
		{
				local TileVIS=Queue[0];
				local Tile=VMFs[TileVIS[0]]
				local Socket=TileVIS[1]
				// Take first ID&Socket from the Queue.
				// Socket's parent returns ID of a previous tile.
				local PrevTile=Socket.parent
				local PrevTileReal=Socket.parent
				
				if (VisibleSet.find(PrevTile)!=null) 
				{
					while (VisibleSocketPointers[VisibleSet.find(PrevTile)]!=0) {
						PrevTile=VisibleSocketPointers[VisibleSet.find(PrevTile)].parent; 
						if (VisibleSet.find(PrevTile)!=0) PrevTileReal=PrevTile;
					}
				}
				local PlayerSocket=VisibleSocketPointers[VisibleSet.find(PrevTileReal)]
				local CurSocket=VisibleSocketPointers[VisibleSet.find(Socket.parent)]
				// This warcrime gives us an ID of a tile 
				
				local TestingLine=GetSocketLine(VMFs[Socket.parent],Socket)
				local CurTileLine=GetSocketLine(VMFs[CurSocket.parent],CurSocket)
				local PlayerTileLine=GetSocketLine(VMFs[PlayerSocket.parent],PlayerSocket)
				
				//debugoverlay.Cross3D(ToVector(Socket.origin),24,80,80,255,true,0.12)
				//debugoverlay.Cross3D(ToVector(CurSocket.origin),24,80,80,255,true,0.12)
				
				//debugoverlay.Line(TestingLine[0],TestingLine[1],255,0,0,true,0.12)
				//debugoverlay.Line(CurTileLine[0]+Vector(0,0,5),CurTileLine[1]+Vector(0,0,5),255,180,0,true,0.12)
				//debugoverlay.Line(PlayerTileLine[0]+Vector(0,0,10),PlayerTileLine[1]+Vector(0,0,10),55,255,55,true,0.12)
				
				// Firing rays between TestingLine and PlayerTileLine should intersect with CurTileLine if we have LOS
				
				if (SocketsVisible(TestingLine,PlayerTileLine,CurTileLine))
				{
					VisibleSet.append(Queue[0][0])
					VisibleSocketPointers.append(Queue[0][1])
					
					foreach (neighbour in GetAdjacentTiles(Queue[0][0]))
					{
						if (VisibleSet.find(neighbour[0])==0) continue;
						if (VisibleSet.find(neighbour[0])!=null) continue;
						if (Queue.find([neighbour[0],neighbour[1]])!=null) continue;
						Queue.append([neighbour[0],neighbour[1]])
						// Add all visibleset's adjacent tiles to the queue, unless they're in visibleset already too. 0 is ID, 1 is socket reference.
					}
				}
				
				Queue.remove(0)
				//Remove Queue's first element
		}
		PVSData.rawset(CurTile.tostring(),VisibleSet)
		printl("Writing PVS Data for tile "+CurTile)
	}
	else
	{
		VisibleSet=PVSData[CurTile.tostring()]
	}
	
	if (CurTile!=LastPlayerTile) foreach (i,hull in Hulls)
	{
		//if (!(i.tostring() in PVSStatus)) PVSStatus.rawset(i.tostring(),null);
		//printl(PVSStatus.len())
		if (PVSStatus.len()==0) break;
		
		if (VisibleSet.find(i)==null)
		{
			
			// INVISIBLE
			//printl("invisibleee")
			DrawHull(hull,55,55,55,0);
			
			//EntFire(i+"_*","addeffects",32)
			//printl(PVSStatus[i.tostring()])
			if (PVSStatus[i.tostring()]!=false)
			{
			
				//EntFire(i+"_*","disabledraw",1)
				local prop=null
				local ent=null
				EntFire(i+"_*","addeffects",32)
				while (ent=Entities.FindByClassname(ent,"light_d*"))
				{
					if (!IsOriginInBBox(ent.GetCenter(),hull[0],hull[1])) continue;
					//EntFireByHandle(ent,"TurnOff")
					ent.AcceptInput("TurnOff","",ent,ent)
					//ent.SetRenderMode(6)
					//debugoverlay.Cross3D(ent.GetOrigin(),8,215,2,2,true,0.12)
				}
				PVSStatus.rawset(i.tostring(),false)
				//printl("setting "+i+" to be invisible")
			}
		}
		else if (PVSStatus[i.tostring()]!=true)
		{
			// VISIBLE
			//printl("visibleee")
			DrawHull(hull,255,175,5,0);
			//EntFire(i+"_*","enabledraw",0)
			EntFire(i+"_*","removeeffects",32)
			local prop=null
			local ent=null
			while (ent=Entities.FindByClassname(ent,"light_d*"))
			{
				if (!IsOriginInBBox(ent.GetCenter(),hull[0],hull[1])) continue;
				//EntFireByHandle(ent,"TurnOn")
				ent.AcceptInput("TurnOn","",ent,ent)
				//ent.SetRenderMode(0)
				//debugoverlay.Cross3D(ent.GetOrigin(),8,5,215,2,true,0.12)
			}
			PVSStatus.rawset(i.tostring(),true)
			//printl("setting "+i+" to be visible")
		}
		
	}
	
	LastPlayerTile=CurTile
	
	//printl(VisibleSet.len())
	
	local TotalLines=0
	if (MapInfoSent<VMFs.len()) foreach (Tile in VMFs)
	{
		foreach (Lin in Tile.Markers)
		{
			if ("target" in Lin)
			{
				TotalLines++
			}
			//printl(GetOffsetVector(Lin.origin,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw))
			//debugoverlay.Text(GetOffsetVector(ToVector(Lin.origin),Tile.Offsets.Offset,Tile.Offsets.OffsetYaw),"M",0.12)
		}
	}
	
	
	if (Convars.GetFloat("sourceworld_minimap_size")&&(MapInfoSent<VMFs.len())) foreach (tileid,Tile in VMFs)
	{
		//if (tileid!=MapInfoSent) continue;

		foreach (Lin in Tile.Markers)
		{
			if ("target" in Lin)
			{
				local Lin2=Tile.Markers[Lin.target]
				
				NetMsg.Start("MAPGEN_LINE");
				NetMsg.WriteShort(TotalLines)
				NetMsg.WriteShort(tileid)
				NetMsg.WriteVec3Coord(GetOffsetVector(Lin.origin,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw))
				NetMsg.WriteVec3Coord(GetOffsetVector(Lin2.origin,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw))
				//WriteVector(GetOffsetVector(Lin.origin,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw))
				//WriteVector(GetOffsetVector(Lin2.origin,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw))
				NetMsg.Send(player, true);
				//printl("sent line")
			}
		}
		
		foreach (Socket in Tile.Sockets)
		{
			if ("taken" in Socket&&Socket.taken==tileid&&!("shortcut" in Socket))
			{
				local sline=GetSocketLine(Tile,Socket)
				NetMsg.Start("MAPGEN_LINE_COLORED");
				NetMsg.WriteShort(TotalLines)
				NetMsg.WriteShort(tileid)
				NetMsg.WriteVec3Coord(sline[0])
				NetMsg.WriteVec3Coord(sline[1])
				NetMsg.WriteVec3Coord(Vector(255,5,5))
				NetMsg.Send(player, true);
				printl("sent colored line")
			}
			else if ("taken" in Socket&&Socket.taken==tileid&&("shortcut" in Socket))
			{
				local sline=GetSocketLine(Tile,Socket)
				NetMsg.Start("MAPGEN_LINE_COLORED");
				NetMsg.WriteShort(TotalLines)
				NetMsg.WriteShort(tileid)
				NetMsg.WriteVec3Coord(sline[0])
				NetMsg.WriteVec3Coord(sline[1])
				NetMsg.WriteVec3Coord(Vector(255,25,255))
				NetMsg.Send(player, true);
				//printl("sent colored line")
			}
			else if ("taken" in Socket)
			{
				local sline=GetSocketLine(Tile,Socket)
				NetMsg.Start("MAPGEN_SOCKET");
				NetMsg.WriteShort(TotalLines)
				NetMsg.WriteByte(tileid)
				NetMsg.WriteByte(Socket.taken)
				
				if (!("minimap_offset_x" in Socket)) Socket.minimap_offset_x<-0;
				if (!("minimap_offset_y" in Socket)) Socket.minimap_offset_y<-0;
				
				NetMsg.WriteBool((Socket.minimap_offset_x!=0)||(Socket.minimap_offset_y!=0))
				
				local offset=Vector(Socket.minimap_offset_x,Socket.minimap_offset_y,0)
				offset=RotateVectorYaw(offset,Tile.Offsets.OffsetYaw)
				NetMsg.WriteVec3Coord(sline[0]+offset)
				NetMsg.WriteVec3Coord(sline[1]+offset)
				NetMsg.Send(player, true);
				//printl("sent socket")
			}
		}
		
		NetMsg.Start("MAPGEN_Z");
		NetMsg.WriteShort(tileid)
		NetMsg.WriteFloat(VMFs[tileid].ZFloor)
		NetMsg.Send(player, true);
		
		NetMsg.Start("MAPGEN_HULL");
		NetMsg.WriteShort(tileid)
		NetMsg.WriteVec3Coord(Hulls[tileid][0])
		NetMsg.WriteVec3Coord(Hulls[tileid][1])
		NetMsg.Send(player, true);
		printl("sent hull")
		//printl(NetMsg.GetNumBitsWritten())
	}
	/*
	if (NodesSent) for (local ent=Entities.First();ent;ent=Entities.FindByClassname(ent,"prop_physics"))
	{
		if (EntIndexes.find(ent.entindex())!=null) continue;
		//debugoverlay.Text(ent.GetOrigin(),"This was sent to client",2)
		//NetMsg.Start("MAPGEN_PROP");
		//NetMsg.WriteShort(ent.entindex())
		//NetMsg.Send(player, true);
		//printl("sent prop")
		EntIndexes.append(ent.entindex())
	}
	*/
	if (Convars.GetFloat("sourceworld_minimap_size")) MapInfoSent=VMFs.len();
	
	
	foreach (id,Tile in VMFs)
	{
		if (id<aigens) continue;
		if (id>aigens+60) break;
		if (NodesSent) break;
		foreach (Node in TileSet[Tile.tile_info.tile_name].Nodes)
		{
			if ("origin" in Node)
			{
				local node_pos=GetOffsetVector(ToVector(Node.origin),Tile.Offsets.Offset,Tile.Offsets.OffsetYaw)
				//debugoverlay.Text(node_pos,"Node",10.12)
				//debugoverlay.Box(node_pos,Vector(-5,-5,-5),Vector(5,5,5),255,220,20,40,11);
				if (NodesVecs.find(node_pos.x+" "+node_pos.y+" "+node_pos.z)==null)
				{
					//printl("placing node")
					SendToConsoleServer("ai_create_info_node "+node_pos.x.tointeger()+" "+node_pos.y.tointeger()+" "+(node_pos.z+394).tointeger())
					NodesAmount++;
					NodesVecs.append(node_pos.x+" "+node_pos.y+" "+node_pos.z)
					NodesTiles.append(id)
					if (NodesAmount%50==0) yield "Node"
				}
			}
			//printl(GetOffsetVector(Lin.origin,Tile.Offsets.Offset,Tile.Offsets.OffsetYaw))
			//debugoverlay.Text(GetOffsetVector(ToVector(Lin.origin),Tile.Offsets.Offset,Tile.Offsets.OffsetYaw),"M",0.12)
		}
		aigens+=0.5;
	}
	if (NodesSent&&!NodesBuilt) 
	{
		SendToConsoleServer("ai_rebuld_graph");
		NodesBuilt=true
		Entities.First().SetContextThink("DISABLE_GRAPH_RENDERING",function(...){SendToConsoleServer("ai_show_connect");return},3)
		Entities.First().SetContextThink("SEND_RADAR_OBJECTS",function(...)
		{
			NetMsg.Start("MAPGEN_GATHER_OBJECTS");
			NetMsg.Send(player, true);
			printl("Mapgen gathering objects")
		},4)
	}

	if ((aigens>=VMFs.len()-1)&&VMFs.len()>1) NodesSent=true;
	
	local EnemyNames=[]
	foreach(name,tab in LIST_ENEMIES) EnemyNames.append(name);
	
	local hostdif=0
	
	if (NodesBuilt&&("worldName" in SW_WORLD_INFO)&&Global_EnemyBudget==null)
	{
		//SW_WORLD_INFO.Difficulty<-120
		local dif=SW_WORLD_INFO.Difficulty.tofloat()
		local hazfrac=SW_WORLD_INFO.HazardFraction.tofloat()
		hostdif=dif*(1-hazfrac)
		local trapdif=dif*(hazfrac)
		printl("--------------------------------")
		printl("Mapgen has data!\n")
		printl("\tNodes: "+NodesAmount)
		printl("\tDifficulty: "+dif)
		printl("\tDifficulty of Hostiles: "+hostdif)
		printl("\tTotal enemy budget: "+(hostdif*NodesAmount).tointeger())
		printl("--------------------------------")
		Global_EnemyBudget=(hostdif*NodesAmount).tointeger()
		Global_TrapBudget=(trapdif*NodesAmount).tointeger()
		Global_LootBudget=(dif*NodesAmount/5.0).tointeger()
		
		
		printl("Reducing loot spawns:")
		printl("Initial loot items: "+LIST_LOOT_NAMES.len())
		LIST_LOOT_REDUCE(dif)
		printl("New loot items: "+LIST_LOOT_NAMES.len())
		printl("New loot items: "+LIST_LOOT.len())
		
		AddObjective(1)
	}
	
	if (NodesBuilt&&!("worldName" in SW_WORLD_INFO)&&Global_EnemyBudget==null)
	{
		local dif=30
		SW_WORLD_INFO.Difficulty<-dif
		local hazfrac=0.3
		SW_WORLD_INFO.HazardFraction<-hazfrac
		hostdif=dif*(1-hazfrac)
		local trapdif=dif*(hazfrac)
		//NodesAmount=0
		printl("--------------------------------")
		printl("Mapgen has NO data! Using fallback values.\n")
		printl("\tNodes: "+NodesAmount)
		printl("\tDifficulty: "+dif)
		printl("\tDifficulty of Hostiles: "+hostdif)
		printl("\tTotal enemy budget: "+(hostdif*NodesAmount).tointeger())
		printl("--------------------------------")
		Global_EnemyBudget=(hostdif*NodesAmount).tointeger()
		Global_TrapBudget=(trapdif*NodesAmount).tointeger()
		Global_LootBudget=(dif*NodesAmount/5.0).tointeger()
		
		AddObjective(1)
	}
	
	
	
	local fails=0;
	
	local DesiredFaction="hecu"
	
	if (Globals.GetCounter(Globals.GetIndex("StageSeed"+StageID))%3==0) DesiredFaction="undead"
	if (Globals.GetCounter(Globals.GetIndex("StageSeed"+StageID))%3==1) DesiredFaction="combine"
	DesiredFaction="corruptors"
	//DesiredFaction="combine"
	
	while(Global_EnemyBudget!=null&&Global_EnemyBudget>0)
	{
		local dif=SW_WORLD_INFO.Difficulty.tofloat()
		local hazfrac=SW_WORLD_INFO.HazardFraction.tofloat()
		hostdif=dif*(1-hazfrac)
		
		Global_EnemyBudget--;
		
		printl("DIFFICULTY "+hostdif)
		
		local randomid=RandInt(0,NodesVecs.len()-1)	//add here array of free nodes
		
		
		local enemyname=LIST_ENEMY_NAMES[GetWeightedRandom(LIST_ENEMY_WEIGHTS)]
		if ("min_difficulty" in LIST_ENEMIES[enemyname] && LIST_ENEMIES[enemyname].min_difficulty>hostdif) 
		{
			//LIST_ENEMY_WEIGHTS.remove(LIST_ENEMY_NAMES.find(enemyname));
			//LIST_ENEMY_NAMES.remove(LIST_ENEMY_NAMES.find(enemyname));
			//printl("disregard "+enemyname+" because min diff")
			continue;
		}
		if ("max_difficulty" in LIST_ENEMIES[enemyname] && LIST_ENEMIES[enemyname].max_difficulty<=hostdif) 
		{
			//LIST_ENEMY_WEIGHTS.remove(LIST_ENEMY_NAMES.find(enemyname));
			//LIST_ENEMY_NAMES.remove(LIST_ENEMY_NAMES.find(enemyname));
			//printl("disregard "+enemyname+" because min diff")
			continue;
		}
		if (Global_EnemyBudget>LIST_ENEMIES[enemyname].cost*NodesAmount/2.0)
		{
			//LIST_ENEMY_WEIGHTS.remove(LIST_ENEMY_NAMES.find(enemyname));
			//LIST_ENEMY_NAMES.remove(LIST_ENEMY_NAMES.find(enemyname));
			//printl("disregard "+enemyname+" because budget too high for the cost.")
			continue;
		}
		
		
		
		if ("faction" in LIST_ENEMIES[enemyname] && LIST_ENEMIES[enemyname].faction!=DesiredFaction)
		{
			//LIST_ENEMY_WEIGHTS.remove(LIST_ENEMY_NAMES.find(enemyname));
			//LIST_ENEMY_NAMES.remove(LIST_ENEMY_NAMES.find(enemyname));
			//printl("disregard "+enemyname+" because faction")
			continue;
		}
		
		local enemy=LIST_ENEMIES[enemyname]
		
		while (TakenNodes.find(randomid)!=null||(!IsNextToDeadEnd(NodesTiles[randomid])&&fails<50&&!("ambush" in enemy))) {randomid=RandInt(10,NodesVecs.len()-1);fails++}
		local randomnode=NodesVecs[randomid]
		local randomnodeVec=ToVector(randomnode)+Vector(RandInt(-16,16),RandInt(-16,16),0)
		
		local trace=TraceHullComplex(ToVector(randomnode), ToVector(randomnode), Vector(-enemy.hull.x/2,-enemy.hull.y/2,0), Vector(enemy.hull.x/2,enemy.hull.y/2,enemy.hull.z), Entities.First(),MASK_SHOT_HULL,0)
		if (!trace.DidHit()&&NodesTiles[randomid]!=StartingTile)
		{
			enemy.rawset("origin",randomnode)
			enemy.rawset("angles","0 "+RandomInt(0,359)+" 0")
			enemy.rawset("squadname","squaddy_"+NodesTiles[randomid])
			local enemyentity = SpawnEntityFromTable(enemy.classname,enemy)
			if ("model" in enemy) enemyentity.SetModel(enemy.model)
			if ("maxhealth" in enemy) enemyentity.SetMaxHealth(enemy.maxhealth)
			if ("health" in enemy) enemyentity.SetHealth(enemy.health)
			enemyentity.GetOrCreatePrivateScriptScope().EnemyName<-enemyname
			Global_EnemyBudget-=enemy.cost;
			Global_EnemyBudget++;
			
			fails=0
			TakenNodes.append(randomid)
			if (EnemyTiles.find(NodesTiles[randomid])==null) EnemyTiles.append(NodesTiles[randomid]);
			//enemyentity.SetSchedule("SCHED_IDLE_WANDER")
			if (TakenNodes.len()%2==0) yield "NPCs";
		}
	}
	
	
	//loot SPAWN
	// choose random item based on weight
	// choose random loot zone
	// get zone for item spawn by subtracting Hulls. dont forget to rotate item hull based on lootzone angle.
	// if any coord for zone is 0 or negative, try again.
	// get random point for loot(maybe on bottom)
	// check with spawn loot hulls. if fails, try all again.
	// spawn item and get its hull(rotated again) into the array.
	// deduct the item's cost
	
	local LootZones=[]
	foreach (vmf in VMFs) foreach(Z in vmf.Loot) LootZones.append([Z,vmf]);
	
	while(Global_LootBudget!=null&&Global_LootBudget>0)
	{
		Global_LootBudget-=0.01
	
		local Item=null
		Item=LIST_LOOT[LIST_LOOT_NAMES[GetWeightedRandom(LIST_LOOT_WEIGHTS)]]
		
		//local Tile=VMFs[RandInt(0,VMFs.len()-1)]
		//if (Tile.Loot.len()==0) continue;
		//local Zone=clone Tile.Loot[RandInt(0,Tile.Loot.len()-1)]
		
		// all loot zones now have even chances of being selected by default.
		local LootZoneInfo=LootZones[RandInt(0,LootZones.len()-1)]
		local Zone=clone LootZoneInfo[0]
		local Tile=LootZoneInfo[1]
		
		if ("is_ground" in Zone&&Zone.is_ground.tostring()=="1") continue;
		
		if (!("rarity" in Zone)) Zone.rawset("rarity",1)
		Zone.rarity=Zone.rarity.tointeger()
		if (Zone.rarity>1)
		{
			local Items=[Item.name]
			local MaxWeight=10000000
			local Selection=0;
			//printl("\tRARE ITEM SPAWNING:")
			//printl("\tFirst Item is "+Item.name)
			//printl("\tRarity = "+Zone.rarity)
			//printl("\tAvailable loot items = "+LIST_LOOT_NAMES.len())
			for (local i=0;i<min(Zone.rarity-1,LIST_LOOT_NAMES.len()-1);i++)
			{
				local name=LIST_LOOT_NAMES[GetWeightedRandom(LIST_LOOT_WEIGHTS)]
				//printl("Trying "+name)
				
				while (Items.find(name)!=null) {
					name=LIST_LOOT_NAMES[GetWeightedRandom(LIST_LOOT_WEIGHTS)];
					//printl("Didn't work. Trying "+name)
				}
				
				Items.append(name)
				//printl(name+" "+LIST_LOOT[name].weight)
			}
			foreach (i,Obj in Items)
			{
				if (LIST_LOOT[Obj].weight<MaxWeight)
				{
					MaxWeight=LIST_LOOT[Obj].weight
					Selection=i;
				}
			}
			Item=clone LIST_LOOT[Items[Selection]];
			//printl("The winner is: "+Item.name)
		}
		
		
		Zone.angles=RotateVectorYaw(Vector(),Tile.Offsets.OffsetYaw)
		Zone.angles.x=0
		Zone.angles.z=0
		Zone.origin=GetOffsetVector(ToVector(Zone.origin),Tile.Offsets.Offset,Tile.Offsets.OffsetYaw)
		
		if ("angle" in Item)
		{
			Item.hull_min=RotateVector(Item.hull_min,Item.angle)
			Item.hull_max=RotateVector(Item.hull_max,Item.angle)
			Zone.angles+=Item.angle
		}
		
		local yaw=Zone.angles.y.tointeger()
		
		local hullmin=Vector(Item.hull_min.x,Item.hull_min.y,Item.hull_min.z)
		local hullmax=Vector(Item.hull_max.x,Item.hull_max.y,Item.hull_max.z)
		
		
		local ItemHull=[RotateVectorYaw(hullmin,yaw),RotateVectorYaw(hullmax,yaw)]	// i suffered for about an hour with trying to fix this only to see that rotating item hulls somehow rotated them in the global list too.
		
		//if (Item.name.find("pistol")!=null)printl(ItemHull[0]+"   "+ItemHull[1]+"   "+yaw)
		if (ItemHull[0].x>ItemHull[1].x)
		{
			ItemHull[0].x=-ItemHull[0].x
			ItemHull[1].x=-ItemHull[1].x
			ItemHull[1].y=-ItemHull[1].y
			ItemHull[0].y=-ItemHull[0].y
		}
		
		local LootHull=[GetOffsetVector(ToVector(Zone.size_mins),Vector(),Tile.Offsets.OffsetYaw),GetOffsetVector(ToVector(Zone.size_maxs),Vector(),Tile.Offsets.OffsetYaw)]

		
		if (LootHull[0].x>LootHull[1].x)
		{
			local minx=LootHull[0].x
			local maxy=LootHull[1].y
			
			LootHull[0].x=LootHull[1].x
			LootHull[1].x=minx
			LootHull[1].y=LootHull[0].y
			LootHull[0].y=maxy
		}
		
		local SpawnHullMin=Vector(min(LootHull[0].x,LootHull[1].x)-min(ItemHull[0].x,ItemHull[1].x),min(LootHull[0].y,LootHull[1].y)-min(ItemHull[0].y,ItemHull[1].y),min(LootHull[0].z,LootHull[1].z)-min(ItemHull[0].z,ItemHull[1].z))
		local SpawnHullMax=Vector(max(LootHull[0].x,LootHull[1].x)-max(ItemHull[0].x,ItemHull[1].x),max(LootHull[0].y,LootHull[1].y)-max(ItemHull[0].y,ItemHull[1].y),max(LootHull[0].z,LootHull[1].z)-max(ItemHull[0].z,ItemHull[1].z))
		
		local SpawnZone=[SpawnHullMin,SpawnHullMax]
		
		//if (SpawnZone[0].Length()>LootHull[0].Length()) SpawnZone[0]=LootHull[0]-ItemHull[1]
		//if (SpawnZone[1].Length()>LootHull[1].Length()) SpawnZone[1]=LootHull[1]-ItemHull[0]
		
		if (SpawnZone[0].x>SpawnZone[1].x||SpawnZone[0].y>SpawnZone[1].y||SpawnZone[0].z>SpawnZone[1].z) continue;
		
		local SpawnPoint=Zone.origin+Vector(RandFloat(SpawnZone[0].x,SpawnZone[1].x),RandFloat(SpawnZone[0].y,SpawnZone[1].y),SpawnZone[0].z+2)
		
		local LootOverlap=false
		foreach (hull in Global_LootHulls)
		{
			if (CheckHullOverlap(hull[0],hull[1],SpawnPoint+ItemHull[0],SpawnPoint+ItemHull[1])) {LootOverlap=true;break}
		}
		if (LootOverlap) continue;
		
		local itemtable=
		{
			model=LIST_ITEMS[Item.name].model
			origin=SpawnPoint.x+" "+SpawnPoint.y+" "+SpawnPoint.z
			angles=Zone.angles.x+" "+Zone.angles.y+" "+Zone.angles.z
			vscripts="items/item.nut"
			ResponseContext="item:"+Item.name+",count:"+RandInt(Item.min,Item.max)
			//spawnflags=8
		}
		
		local center=Zone.origin
		// I think debugoverlays cause some sort of leak which causes mod perfomance to worsen over time, visible by fps getting lower.
		//debugoverlay.Box(center,LootHull[0],LootHull[1],255,255,25,2,120);
		
		local center=Zone.origin
		// I think debugoverlays cause some sort of leak which causes mod perfomance to worsen over time, visible by fps getting lower.
		//debugoverlay.Box(center,SpawnZone[0],SpawnZone[1],255,25,25,2,120);
		
		local center=SpawnPoint
		// I think debugoverlays cause some sort of leak which causes mod perfomance to worsen over time, visible by fps getting lower.
		//debugoverlay.Box(center,ItemHull[0],ItemHull[1],0,0,255,2,120);
		
		local LootItem=SpawnEntityFromTable("prop_physics",itemtable)
		
		EntFireByHandle(LootItem,"disablemotion","",0.1)
		EntFireByHandle(LootItem,"enablemotion","",0.5)
		
		Global_LootHulls.append([SpawnPoint+ItemHull[0],SpawnPoint+ItemHull[1]])
		
		Global_LootBudget-=Item.cost
		Global_LootBudget+=0.01;
		yield "Loot"
	}
	
	local traps=0
	
	while(Global_TrapBudget!=null&&Global_TrapBudget>0)
	{
		local randomid=RandInt(0,VMFs.len()-1)
		if (VMFs[randomid].Traps.len()==0) continue;
		Global_TrapBudget--;
		if (EnemyTiles.find(randomid)!=null) continue;
		
		local trap=VMFs[randomid].Traps[RandInt(0,VMFs[randomid].Traps.len()-1)]
		//local trace=TraceHullComplex(ToVector(randomnode), ToVector(randomnode), Vector(-enemy.hull.x/2,-enemy.hull.y/2,0), Vector(enemy.hull.x/2,enemy.hull.y/2,enemy.hull.z), Entities.First(),MASK_SHOT_HULL,0)
		if (randomid!=StartingTile)
		{
			if (!"angles" in trap) trap.rawset("angles","0 0 0")
			
			local vect=GetOffsetVector(trap.origin,VMFs[randomid].Offsets.Offset,VMFs[randomid].Offsets.OffsetYaw)
			local ang=ToVector(trap.angles)+Vector(0,VMFs[randomid].Offsets.OffsetYaw,0)

			trap.angles=ang.x+" "+ang.y+" "+ang.z
			trap.origin=vect.x+" "+vect.y+" "+vect.z

			local trapentity = SpawnEntityFromTable(trap.classname,trap)
			
			//foreach (k,v in trap) printl(k+" "+v)
			
			if ("damage" in trap) EntFireByHandle(trapentity,"SetDamage",trap.damage.tointeger());
			if ("PlantOrientation" in trap) EntFireByHandle(trapentity,"setposeparameter","blendstates 0");
			
			// no matter what i tried, you can't change DmgRadius for some reason.
			//if ("DmgRadius" in trap) EntFireByHandle(trapentity,"SetRadius",trap.DmgRadius.tointeger());
			
			Global_TrapBudget-=trap.trap_cost;
			Global_TrapBudget++;

			traps++
			
			// Below we repeat same logic for any traps with same name, except we don't spend budget
			if (("trap_name" in trap)&&trap.trap_name.tostring()!=""&&trap.trap_name.tostring()!="0")
			{
			
				local trapsize=VMFs[randomid].TrapNames[trap.trap_name.tostring()].len()
			
				//printl("Original traplist:")
				//foreach (id in VMFs[randomid].TrapNames[trap.trap_name.tostring()]) printl(id);
				//printl("")
				foreach (i,ID in VMFs[randomid].TrapNames[trap.trap_name.tostring()])
				{
					local trapID=VMFs[randomid].TrapNames[trap.trap_name.tostring()][i]
				
					if (VMFs[randomid].Traps.find(trap)==trapID) continue;
					
				
					//printl("Named trap. looking for id "+trapID)
				
					local trap = VMFs[randomid].Traps[trapID]
					
					if (!"angles" in trap) trap.rawset("angles","0 0 0")
			
					local vect=GetOffsetVector(trap.origin,VMFs[randomid].Offsets.Offset,VMFs[randomid].Offsets.OffsetYaw)
					local ang=ToVector(trap.angles)+Vector(0,VMFs[randomid].Offsets.OffsetYaw,0)

					trap.angles=ang.ToKVString()
					trap.origin=vect.ToKVString()

					local trapentity = SpawnEntityFromTable(trap.classname,trap)
					
					//foreach (k,v in trap) printl(k+" "+v)
					
					if ("damage" in trap) EntFireByHandle(trapentity,"SetDamage",trap.damage.tointeger());
					if ("PlantOrientation" in trap) EntFireByHandle(trapentity,"setposeparameter","blendstates 0");
					//if ("DmgRadius" in trap) EntFireByHandle(trapentity,"SetRadius",trap.damage.tointeger());
						
					VMFs[randomid].Traps.remove(trapID)
					//printl("Spawned, we remove "+trapID)
					trapsize--;
					
					// After removing trap, all IDs that are higher from ID of removed trap, will shift down.
					foreach (i,trapnames in VMFs[randomid].TrapNames) 
						foreach (i2,id in trapnames)
							if (id>trapID) VMFs[randomid].TrapNames[i][i2]--;
					
					
					//printl("Original traplist:")
					//foreach (id in VMFs[randomid].TrapNames[trap.trap_name.tostring()]) printl(id);
					//printl("")
				}
			}
			local idToRemove=VMFs[randomid].Traps.find(trap)
			VMFs[randomid].Traps.remove(idToRemove)
			
			foreach (i,trapnames in VMFs[randomid].TrapNames) 
						foreach (i2,id in trapnames)
					if (id>idToRemove) VMFs[randomid].TrapNames[i][i2]--;
			
			if (traps%3==0) yield "Traps"
			
		}
	}
	//printl(format("Explored %i/%i",ExploredTiles.len(),Hulls.len()))
}

Entities.First().SetContextThink("retriers",function (_) {SendToConsoleServer("give item_suit"); return;},0.2)

local gen = ShowHulls();

local PerfCost=GetTilesetFromID(TilesetID).perfomance_cost

Entities.First().SetContextThink("MAPGEN_HULLS",function (_)
{
    if ( gen.getstatus() != "suspended" )
        gen = ShowHulls();

    local r = resume gen;
    //printl( "ShowHulls @ " + r );

	if (r!=null) printl("Spawning "+r)
	if (r!=null) return 0;

    return 0.01*Hulls.len()*PerfCost
}.bindenv(this),0.25)

Convars.RegisterCommand( "mapgen_lock_pvs", function (_){PVSLocked=!PVSLocked;SendToConsole("play buttons/button15.wav")}.bindenv(this), "", FCVAR_NONE );
Convars.RegisterCommand( "place_node", function (_){SendToConsoleServer("ai_create_info_node "+player.GetOrigin().x+" "+player.GetOrigin().y+" "+(player.GetOrigin().z+388))}.bindenv(this), "", FCVAR_NONE );