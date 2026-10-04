/*
::SKILLS<-{}
class Skill
{
	Name=""
	
	constructor(name,desc,x,y,c,required=null,previ=0,action=null) {

		}
	}
}
*/
IncludeScript("lists/list_items.nut")
IncludeScript("lists/list_questitems.nut")
IncludeScript("utils/text.nut")
IncludeScript("quests.nut")

const COLS=12	//	amount of cell collumns 
const ROWS=6	// amount of cell rows

// === ВКЛАДКИ МЕНЮ ===
const TAB_INVENTORY = 0
const TAB_QUESTS    = 1
const TAB_SKILLS    = 2

CURRENT_TAB <- TAB_INVENTORY

//le example
	
/*
if (ActiveContainer!=null&&INVENTORY.len()==(COLS*ROWS)) INVENTORY.extend(container.inventory)	//do this on open. both sides
	
if INVENTORY.len()>(COLS*ROWS) CONTAINERS[ActiveContainer].INVENTORY=INVENTORY.slice(COLS*ROWS)	//do this on close. both sides
if INVENTORY.len()>(COLS*ROWS) INVENTORY=INVENTORY.slice(0,COLS*ROWS)	//do this on close. both sides

inventory.len() will be fixed! no need to change fors or IDs

//we only need to change cols and rows along with the id itself so that all coords are treated in same way
//also swap FRAME and CELLS with C_ counterpart
local Cols=COLS	//dont do this warcrime with giving same name
local Rows=ROWS
local Cells_X=CELLS_X
local Cells_Y=CELLS_Y	
... and so on
local i=j
if (i>=cols*rows) replace all these also i-=cols*rows	//only replace i when drawing or checking collisions! anything else needs real id. maybe backup the og.

*/

//XRES(64), YRES(248),  XRES(512), YRES(214)
	
::INVENTORY<-array(COLS*ROWS) //10x6
::EQUIPMENT<-array(3) // Armor slots

// The aPlayer.Weapons IDs get stored here when player assigns weapons to slots. This is stored on both client/server because im too lazy to do networking for saving. It still needs networking anyways btw.
::WEAPON_SLOTS<-array(6)
::QUICK_USE_SLOTS<-array(4)

if (CLIENT_DLL) 
{
	::LAST_WEAPON_SLOT<-0;
}

::CONTAINERS<-{}

local ItemChest={
	INVENTORY=array(12*5),
	Name="Item Chest",
	Shop=false,
	COLS=12,
	ROWS=5
}

local TutorialChest={
	INVENTORY=array(10*4),
	Name="Training Chest",
	Shop=false,
	COLS=10,
	ROWS=4
}

local SMGCrate={
	INVENTORY=array(10*4),
	Name="SMG Ammo Crate",
	Shop=false,
	COLS=10,
	ROWS=4
}

local Trader={
	INVENTORY=array(18*6),
	Name="Weapons",
	Shop=true,
	COLS=18,
	ROWS=6
	Pages=["Trader","Trader2"]
}

local Trader2={
	INVENTORY=array(18*6),
	Name="Supplies",
	Shop=true,
	COLS=18,
	ROWS=6
	Pages=["Trader","Trader2"]
}

local Corpse={
	INVENTORY=array(8*4),
	Name="(Dead) Combine Soldier",
	Shop=false,
	COLS=8,
	ROWS=4
}

local Footlocker={
	INVENTORY=array(8*3),
	Name="Footlocker",
	Shop=false,
	COLS=8,
	ROWS=3
}

::ActiveContainer<-null
::ContainerPages<-null

class ::Item
{
	Name="default"
	Desc=""
	SizeX=1
	SizeY=1
	Icon=""
	Sound=""
	Rotated=false
	Count=1;
	Clip=0;
	Durability=0;
	MaxDurability=0;
	MaxStack=1;
	UseAction=null
	tech_name=""
	DropFlag=false
	Cost=0
	armorslot=null
	Dual=null
	SingleUse=false
	SellMultiplier=0.5
	Hovering=false
	LastHover=0.0
	
	WeaponInvID=null	// id of which slot of aPlayer.Weapons does this weapon take
	WeaponSlot=null	// id of assignable weapon(WEAPON_SLOTS) slot used solely for weapon selection. 
	
	constructor(name,count=1,clip=0,dur=1.0) {
		local ItemEntry=LIST_ITEMS[name]
		tech_name=name
		Name=ItemEntry.name
		if ("desc" in ItemEntry) Desc=ItemEntry.desc
		if ("armorslot" in ItemEntry) armorslot=ItemEntry.armorslot
		SizeX=ItemEntry.sizex
		SizeY=ItemEntry.sizey
		Sound=ItemEntry.sound
		Cost=ItemEntry.cost
		MaxDurability=ItemEntry.cost
		//printl("DURABILITY "+dur)
		//printl("MAX DURABILITY "+MaxDurability)
		Durability=(MaxDurability*dur).tointeger()
		//printl("TOTAL "+Durability)
		Icon=""
		Clip=clip;
		Count=count
		if ("Use" in ItemEntry) UseAction=ItemEntry.Use
		if ("dual" in ItemEntry) Dual=ItemEntry.dual
		if ("singleuse" in ItemEntry) SingleUse=ItemEntry.singleuse
		MaxStack=ItemEntry.maxstack
		if (CLIENT_DLL) Icon=ItemEntry.icon
		SellMultiplier=0.5
		//if ("ammoitem" in ItemEntry) SellMultiplier=0.2
	}
	function ChangeWeaponSlot(a)
	{
		if (WeaponSlot==a) return;
		
		local Cols=COLS
		local Rows=ROWS
		local ID=INVENTORY.find(this)
		local RealID=INVENTORY.find(this)
		if (INVENTORY.find(this)>=COLS*ROWS)
		{
			return;
		}
		
		//printl(WeaponSlot+" cl- "+a)
		
		if (a!=null)
		{
			foreach(item in INVENTORY)
			{
				if (item&&(typeof item)!="integer"&&item.WeaponSlot==a) {WEAPON_SLOTS[a]=null;item.WeaponSlot=null;break}
			}
			foreach(i,slot in WEAPON_SLOTS)
			{
				if (slot==WeaponInvID) {WEAPON_SLOTS[i]=null;printl("reset slot "+i)}
			}
			
			if (SingleUse) foreach(item in INVENTORY)
			{
				if (item&&(typeof item)!="integer"&&item.tech_name==tech_name) {item.WeaponSlot=a}
			}
			
			WeaponSlot=a;
			WEAPON_SLOTS[a]=WeaponInvID;
			
		}
		else if (WeaponSlot!=null)
		{
			WEAPON_SLOTS[WeaponSlot]=null;
			WeaponSlot=null;
			
			if (SingleUse) foreach(item in INVENTORY)
			{
				if (item&&(typeof item)!="integer"&&item.tech_name==tech_name) {item.WeaponSlot=null}
			}
		}
		if (CLIENT_DLL)
		{
			//printl("changing weaponslot!")
			
			if (InvP) LastSwitchTime=Time()-1
			
			NetMsg.Start("WeaponSlotChanged")
			NetMsg.WriteShort(INVENTORY.find(this))
			NetMsg.WriteShort((a==null) ? (-1) : a)
			NetMsg.Send()
		}
	}
	/*
	function ChangeQuickUseSlot(a)
	{
		if (QuickUseSlot==a) return;
		
		local Cols=COLS
		local Rows=ROWS
		local ID=INVENTORY.find(this)
		local RealID=INVENTORY.find(this)
		if (INVENTORY.find(this)>=COLS*ROWS)
		{
			return;
		}
		
		//printl(WeaponSlot+" cl- "+a)
		
		if (a!=null)
		{
			foreach(item in INVENTORY)
			{
				if (item&&(typeof item)!="integer"&&item.QuickUseSlot==a) {QUICK_USE_SLOTS[a]=null;item.QuickUseSlot=null;break}
			}
			foreach(i,slot in QUICK_USE_SLOTS)
			{
				if (slot==ID) {QUICK_USE_SLOTS[i]=null;}
			}
			
			QuickUseSlot=a;
			QUICK_USE_SLOTS[a]=ID;
			
		}
		else if (QuickUseSlot!=null)
		{
			QUICK_USE_SLOTS[QuickUseSlot]=null;
			QuickUseSlot=null;
		}
		if (CLIENT_DLL)
		{
			printl("changing quick use slot!")
			surface.PlaySound("common/menu3.wav")
			
			NetMsg.Start("QuickUseSlotChanged")
			NetMsg.WriteShort(INVENTORY.find(this))
			NetMsg.WriteShort((a==null) ? (-1) : a)
			NetMsg.Send()
		}
	}
	*/
	function Rotate()
	{
		
		local Cols=COLS
		local Rows=ROWS
		local ID=INVENTORY.find(this)
		local RealID=INVENTORY.find(this)
		if (INVENTORY.find(this)>=COLS*ROWS)
		{
			Cols=CONTAINERS[ActiveContainer].COLS
			Rows=CONTAINERS[ActiveContainer].ROWS
			ID-=COLS*ROWS
		}
		
		for (local j=1;j<(SizeX*SizeY);j++) if ((ID%Cols+j%SizeY)>(Cols-1)) return false;
		for (local j=1;j<(SizeX*SizeY);j++) if ((ID/Cols+j/SizeY)>(Rows-1)) return false;
		
		
		for (local j=1;j<(SizeX*SizeY);j++) if (INVENTORY[RealID+(j%SizeY)+(j/SizeY)*Cols]!=null&&INVENTORY[RealID+(j%SizeY)+(j/SizeY)*Cols]!=RealID) return false;
		
		local a=SizeX
		SizeX=SizeY
		SizeY=a
		//printl(RealID)
		
		for (local j=1;j<(SizeX*SizeY);j++) INVENTORY[RealID+(j%SizeY)+(j/SizeY)*Cols]=null;
		for (local j=1;j<(SizeX*SizeY);j++) INVENTORY[RealID+(j%SizeX)+(j/SizeX)*Cols]=RealID;
		
		
		Rotated=!Rotated
		return true
	}
	function Repair(amount)
	{
		Durability=min(Durability+amount,MaxDurability*1.25);
		if (CLIENT_DLL)
		{
			surface.PlaySound("weapons/repair.wav")
			NetMsg.Start("InventoryRepairFromClient")
			NetMsg.WriteShort(INVENTORY.find(this))
			NetMsg.WriteShort(amount)
			NetMsg.Send()
		}
		else
		{
			RemoveItem("item_wep_repair_kit");
		}
	}
	
	function UseItem()
	{
		printl("Using item - "+Name+", under ID "+INVENTORY.find(this))
		if (CLIENT_DLL)
		{
			if (UseAction()==true)
			{
				NetMsg.Start("InventoryUseFromClient")
				NetMsg.WriteShort(INVENTORY.find(this))
				NetMsg.Send()
				UseAction()
				//if (INVENTORY[INVENTORY.find(this)].QuickUseSlot!=null&&QUICK_USE_SLOTS[QuickUseSlot]!=null) QUICK_USE_SLOTS[QuickUseSlot]=null
			}
		}
		else
		{
			if (UseAction()==true)
			{
				NetMsg.Start("InventoryUseFromServer")
				NetMsg.WriteShort(INVENTORY.find(this))
				NetMsg.Send(player,true)
				
				//if (INVENTORY[INVENTORY.find(this)].QuickUseSlot!=null&&QUICK_USE_SLOTS[QuickUseSlot]!=null) QUICK_USE_SLOTS[QuickUseSlot]=null
				RemoveItem(INVENTORY[INVENTORY.find(this)].tech_name,1,INVENTORY.find(this))
			}
		}
	}
	
	function UnloadWeapon(ServerUnload=false)
	{
		local ItemEntry=LIST_ITEMS[tech_name]
		
		if (!("ammoitem" in ItemEntry))
		{
			printl("Tried unloading "+tech_name+", but item has no ammo type!")
			return
		}
		
		if (CLIENT_DLL&&(!ServerUnload))
		{
				NetMsg.Start("UnloadWeaponFromClient")
				NetMsg.WriteShort(INVENTORY.find(this))
				NetMsg.Send()
		}
		
		if (SERVER_DLL) 
		{
			if (aPlayer.DualWield[0]!=null&&aPlayer.DualWield[1]!=null)
			{
				if (aPlayer.DualWield[0]==WeaponInvID) GiveItem(ItemEntry.ammoitem,aPlayer.Weapon.clip,0)
				if (aPlayer.DualWield[1]==WeaponInvID) GiveItem(ItemEntry.ammoitem,aPlayer.Weapon.clip2,0)
			}
			else GiveItem(ItemEntry.ammoitem,aPlayer.Weapons[WeaponInvID].clip,0);
			player.EmitSound("BaseCombatCharacter.AmmoPickup")
			
			if (ServerUnload)
			{
				NetMsg.Start("UnloadWeaponFromServer")
				NetMsg.WriteShort(INVENTORY.find(this))
				NetMsg.Send(player,true)
			}
		}
		
		INVENTORY[INVENTORY.find(this)].Clip=0
		aPlayer.Weapons[WeaponInvID].clip=0
		if (aPlayer.DualWield[0]!=null&&aPlayer.DualWield[1]!=null)
		{
			if (aPlayer.DualWield[0]==WeaponInvID) aPlayer.Weapon.clip=0
			if (aPlayer.DualWield[1]==WeaponInvID) aPlayer.Weapon.clip2=0
		}
	}
	
	function SpawnDropped(CurVel,DragCount=-1)
	{
		if (DragCount==(-1)) DragCount=Count;
		
		if (DragCount==Count) DropFlag=true
		
		local ItemEntry=LIST_ITEMS[tech_name]
		
		local item_classname="prop_physics"
		
		local EntTable=
		{
			targetname="droppeditem"
			model=ItemEntry.model
			spawnflags=4
			vscripts="items/item.nut",
			ResponseContext="item:"+tech_name+",count:"+DragCount+",clip:"+Clip+",dur:"+(Durability.tofloat()/MaxDurability.tofloat())
		}
		
		if (SERVER_DLL) 
		{
			local DroppedItem=SpawnEntityFromTable(item_classname,EntTable)
			DroppedItem.GetScriptScope().Init(this)
			DroppedItem.SetOrigin(player.EyePosition()-Vector(0,0,8))
			DroppedItem.SetAngles(player.EyeAngles())
			DroppedItem.GetPhysicsObject().ApplyForceCenter(player.GetAutoaimVector(1)*DroppedItem.GetPhysicsObject().GetMass()*(CurVel+1)*2)
			//printl("VELOCITY "+CurVel)
			//printl(item_classname)

			//if ("ammoitem" in ItemEntry)
			//{
			//	RemoveItem(tech_name,Count,INVENTORY.find(this))
			//}
		}
		if (CLIENT_DLL)
		{
			NetMsg.Start("ItemDrop")
			NetMsg.WriteShort(INVENTORY.find(this))
			NetMsg.WriteShort(CurVel)
			NetMsg.WriteShort(DragCount)
			NetMsg.Send()

		}
		RemoveItem(tech_name,DragCount,INVENTORY.find(this),false)
	}
	
	function InitWeapon()
	{
		local ItemEntry=LIST_ITEMS[tech_name]
		
		if ("weapon" in ItemEntry&&(!this.SingleUse||this.SingleUse&&SW_PlayerHasItemCount(this.Name)<2))
		{
			local InvSlot=0
			if ("Weapons" in aPlayer)
			{
				InvSlot=aPlayer.Weapons.find(null)
			}
		
			Entities.FindByClassname(null,"weapon_custom_scripted1").GetOrCreatePrivateScriptScope().IncludeScript("weapons/"+tech_name)
			
			if (SW_PlayerHasItemCount(this.Name)>1&&this.Dual)
			{
				local dualslot=InvSlot
				while (dualslot==InvSlot&&aPlayer.Weapons[dualslot]!=null) dualslot++;
				local HasDual=false
				foreach (wep in aPlayer.Weapons) if (wep&&wep.Name==this.Dual) HasDual=true;
				
				if (!HasDual) Entities.FindByClassname(null,"weapon_custom_scripted1").GetOrCreatePrivateScriptScope().IncludeScript("weapons/"+this.Dual);
				//printl("TYPE IS "+this.Dual)
				//printl("Created "+aPlayer.Weapons[dualslot].Name+" for slot "+dualslot)			
			}
			
			printl("Created "+aPlayer.Weapons[InvSlot].Name+" for slot "+InvSlot)
			printl("clip of 0 = "+aPlayer.Weapons[0].clip)
			this.WeaponInvID=InvSlot
			if (WEAPON_SLOTS.find(null)!=null)
			{
				this.ChangeWeaponSlot(WEAPON_SLOTS.find(null))
				printl("Assigned "+aPlayer.Weapons[InvSlot].Name+" to WeaponSlot "+this.WeaponSlot)
			}
			
			aPlayer.Weapons[InvSlot].clip=this.Clip;
			
			printl("clip of 0 after = "+aPlayer.Weapons[0].clip)
			//printl("> "+InvSlot)
		}
		if ("weapon" in ItemEntry&&(this.SingleUse&&SW_PlayerHasItemCount(this.Name)>1))
		{
			printl("Received "+this.tech_name+" when we already had one.")
			
			local InvSlot=0
			for (InvSlot;InvSlot<aPlayer.Weapons.len();InvSlot++)
			{
				if (aPlayer.Weapons[InvSlot]&&aPlayer.Weapons[InvSlot].Name==this.tech_name)
					break;
			}
			this.WeaponInvID=InvSlot
			printl("Changed WeaponInvID to "+InvSlot+". which is "+aPlayer.Weapons[InvSlot].Name)
			
			local PlayerInvSlot=0
			local PlayerWeaponSelectionSlot=null
			foreach(slot,wep in WEAPON_SLOTS)
			{
				if (wep==InvSlot) {PlayerWeaponSelectionSlot=slot;break}
			}
			
			printl("Weapon is already located in inventory cell "+PlayerInvSlot+". which is bound to weapon slot "+PlayerWeaponSelectionSlot)
			
			if (PlayerWeaponSelectionSlot!=null)
			{
				this.ChangeWeaponSlot(PlayerWeaponSelectionSlot)
				printl("Assigned "+aPlayer.Weapons[InvSlot].Name+" to WeaponSlot "+this.WeaponSlot)
			}
		}
	}
	
}

local hv=Item("health_vial");
local hv2=Item("health_kit");
//ItemChest.INVENTORY[0]=clone hv;
//ItemChest.INVENTORY[1]=clone hv;
//ItemChest.INVENTORY[2]=clone hv2;
//ItemChest.INVENTORY[10]=(ROWS*COLS)+0
//ItemChest.INVENTORY[11]=(ROWS*COLS)+1
//ItemChest.INVENTORY[3]=(ROWS*COLS)+2
//ItemChest.INVENTORY[12]=(ROWS*COLS)+2
//ItemChest.INVENTORY[14]=(ROWS*COLS)+2



CONTAINERS.rawset("ItemChest",ItemChest)
CONTAINERS.rawset("SMGCrate",SMGCrate)
CONTAINERS.rawset("Trader",clone Trader)
CONTAINERS.rawset("Trader2",clone Trader2)
CONTAINERS.rawset("TutorialChest",clone TutorialChest)

::SpawnItem <- function (tech_name,count=1,Clip=0,Dur=1)
{
	if (SERVER_DLL) 
	{
		local ItemEntry=LIST_ITEMS[tech_name]

		count=clamp(count,1,ItemEntry.maxstack)
		
		local item_classname="prop_physics"
		
		local EntTable=
		{
			model=ItemEntry.model
			spawnflags=4
			vscripts="items/item.nut",
			ResponseContext="item:"+tech_name+",count:"+count+",clip:"+Clip+",dur:"+Dur
		}
	
	
		local DroppedItem=SpawnEntityFromTable(item_classname,EntTable)
		DroppedItem.GetScriptScope().Init(Item(tech_name,count,Clip))
		DroppedItem.SetOrigin(player.EyePosition()-Vector(0,0,8))
		DroppedItem.SetAngles(player.EyeAngles())
		DroppedItem.GetPhysicsObject().ApplyForceCenter(player.GetAutoaimVector(1)*DroppedItem.GetPhysicsObject().GetMass()*50)
		//printl("VELOCITY "+CurVel)
		//printl(item_classname)
		return DroppedItem
	}
	if (CLIENT_DLL)
	{
		NetMsg.Start("SpawnItem")
		NetMsg.WriteString(tech_name)
		NetMsg.WriteByte(count)
		NetMsg.WriteByte(Clip)
		NetMsg.WriteFloat(Dur)
		NetMsg.Send()
	}
}

::GiveItem <- function(name,count=1,clip=0,durability=1.0)
{
	
	local ItemEntry=LIST_ITEMS[name]
	local sizex=ItemEntry.sizex
	local sizey=ItemEntry.sizey
	local icon=ItemEntry.icon
	local maxstack=ItemEntry.maxstack
	
	
	
	
	local item=Item(name,count)
	local cell=(-1)
	local x=item.SizeX
	local y=item.SizeY
	local i=HasSpace(x,y)
	
	local item_name=name
	name=ItemEntry.name
	
	if (SERVER_DLL)
	{
		NetMsg.Start("GiveItemClient");
		NetMsg.WriteString(item_name)
		NetMsg.WriteShort(clamp(count,0,maxstack))
		NetMsg.WriteShort(clip)
		NetMsg.WriteFloat(durability)
		NetMsg.Send(player, true);
	}
	
	if (maxstack>1)
	{
		for (local i=0;i<INVENTORY.len();i++)
		{
			local cell=INVENTORY[i]
			if ("Name" in cell) if (cell.Name==name)
			{
				local Dif=clamp(count,0,maxstack-cell.Count) //how many to put in a cell with item already
				Dif=abs(Dif)
				INVENTORY[i].Count=INVENTORY[i].Count+Dif
				count-=Dif
				//printl("dif is "+Dif)
				//printl("count is "+count)
				//printl("after "+INVENTORY[i].Count)
			}
		}
	}
	item.Clip=clip
	item.Durability=(durability*item.MaxDurability).tointeger()
	
	if (count==0) return
	
	local CountExtra=clamp(count-maxstack,0,9999)
	
	count=clamp(count,0,maxstack)
	item.Count=count
	
	if (i!=false&&(i<COLS*ROWS))	//if we found free space for item, make sure this space actually belongs to player's inventory.
	{
		INVENTORY[i]=item
		for (local j=1;j<(x*y);j++) INVENTORY[i+(j%x)+(j/x)*COLS]=i;
		cell=i
	}
	else 
	{
		if (SERVER_DLL)
		{
			printl("No space for item! Dropping some to floor")
			SpawnItem(item_name,CountExtra+count,clip);
		}
		return;
	}
	item.InitWeapon()
	
	//printl(item.SizeX)

	if (CountExtra>0) GiveItem(item_name,CountExtra,0);
	return i
}.bindenv(this)

::CreateItemInInventory <- function(name,itemdata,i)
{
	if (itemdata.WeaponInvID==(255)) itemdata.WeaponInvID=null;
	if (itemdata.WeaponSlot==(255)) itemdata.WeaponSlot=null;
	//if (itemdata.QuickUseSlot==(255)) itemdata.QuickUseSlot=null;
	
	local ItemEntry=LIST_ITEMS[name]
	local sizex=itemdata.SizeX
	local sizey=itemdata.SizeY
	local icon=ItemEntry.icon
	local maxstack=ItemEntry.maxstack
	
	
	//print("test")
	
	local item=Item(name,itemdata.Count)
	
	local item_name=name
	name=ItemEntry.name
	
	if (SERVER_DLL)		// PROBLEM: NO ADJACENT ITEM CELLS. WEAPONS NOT INITTING PROPERLY.(do wepslots by changeweaponslot func to do sync)
	{
		Entities.First().SetContextThink("DELAYED_ITEM_CREATION"+i,function(...){
		NetMsg.Start("CreateItemInInventoryClient");
		NetMsg.WriteByte(ITEMNAME_TO_ID(item_name))
		NetMsg.WriteByte(itemdata.SizeX)	//itemdata goes here
		NetMsg.WriteByte(itemdata.SizeY)
		NetMsg.WriteBool(itemdata.Rotated)
		NetMsg.WriteByte(itemdata.Count)
		NetMsg.WriteByte(itemdata.Clip)
		NetMsg.WriteFloat(itemdata.Durability)
		NetMsg.WriteByte((itemdata.WeaponInvID==null) ? 255 : itemdata.WeaponInvID)	// Send as -1 if null.
		NetMsg.WriteByte((itemdata.WeaponSlot==null) ? 255 : itemdata.WeaponSlot) // Send as -1 if null.
		//NetMsg.WriteByte((itemdata.QuickUseSlot==null) ? 255 : itemdata.QuickUseSlot) // Send as -1 if null.
		NetMsg.WriteByte(i)
		printl("[INVENTORY] CURRENT NETMSG BUFFER "+NetMsg.GetNumBitsWritten()+" (max 251)")
		if (NetMsg.GetNumBitsWritten()>251) (printl("LIMIT EXCEEDEEEEED! WEEWOOO WEEWOO WEEWOO. THE MESSAGE WILL FAIL"))
		NetMsg.Send(player, true);}.bindenv(this),0.5)
	}
	//print("test2")
	
	foreach (k,v in itemdata) item[k]=v;
	INVENTORY[i]=item
	for (local j=1;j<(sizex*sizey);j++) INVENTORY[i+(j%sizex)+(j/sizex)*COLS]=i;
	
	if ("weapon" in ItemEntry&&(!item.SingleUse||item.SingleUse&&HasItemCount(item.Name)<2))
	{
		local FreeSlot=("Weapons" in aPlayer) ? aPlayer.Weapons.find(null) : 0;
		
		local InvSlot=item.WeaponInvID	//weapon id slot that we need to move our weapon to after init.
	
		Entities.FindByClassname(null,"weapon_custom_scripted1").GetOrCreatePrivateScriptScope().IncludeScript("weapons/"+item_name)
		
		if (HasItemCount(item.Name)>1&&item.Dual)
		{
			local dualslot=InvSlot
			while (dualslot==InvSlot&&aPlayer.Weapons[dualslot]!=null) dualslot++;
			local HasDual=false
			foreach (wep in aPlayer.Weapons) if (wep&&wep.Name==item.Dual) HasDual=true;
			
			if (!HasDual) Entities.FindByClassname(null,"weapon_custom_scripted1").GetOrCreatePrivateScriptScope().IncludeScript("weapons/"+item.Dual);
			//printl("TYPE IS "+item.Dual)
			//printl("Created "+aPlayer.Weapons[dualslot].Name+" for slot "+dualslot)			
		}
		
		if (FreeSlot!=InvSlot)
		{
			//printl("before")
			printl(aPlayer.Weapons[InvSlot])
			printl(aPlayer.Weapons[FreeSlot])
			local wepon=aPlayer.Weapons[FreeSlot]
			wepon.InvSlot=InvSlot
			aPlayer.Weapons[InvSlot]=wepon;
			aPlayer.Weapons[FreeSlot]=null;
			//printl("Moved slots around!")
			printl(InvSlot+" to "+FreeSlot)
			//printl("after")
			printl(aPlayer.Weapons[InvSlot])
			printl(aPlayer.Weapons[FreeSlot])
		}
		
		printl("Created "+aPlayer.Weapons[InvSlot].Name+" for slot "+InvSlot)
		
		
		
		/*
		
		Presumably no need in this since we already have WeaponSlot in itemdata and wepslots data loaded.
		
		if (WEAPON_SLOTS.find(null)!=null)
		{
			INVENTORY[i].ChangeWeaponSlot(WEAPON_SLOTS.find(null))
			printl("Assigned "+aPlayer.Weapons[InvSlot].Name+" to WeaponSlot "+INVENTORY[i].WeaponSlot)
		}
		*/
		
		aPlayer.Weapons[InvSlot].clip=INVENTORY[i].Clip;
		aPlayer.ActiveWeaponSlot=-1
		//aPlayer.Weapon=aPlayer.Weapons[SW_Player_LastInv]
	}
	if ("weapon" in ItemEntry&&(item.SingleUse&&HasItemCount(item.Name)>1))
	{
		//local FreeSlot=("Weapons" in aPlayer) ? aPlayer.Weapons.find(null) : 0;
		
		local InvSlot=item.WeaponInvID	//weapon id slot that we need to move our weapon to after init.
	
		//Entities.FindByClassname(null,"weapon_custom_scripted1").GetOrCreatePrivateScriptScope().IncludeScript("weapons/"+item_name)
		
		printl("Created "+aPlayer.Weapons[InvSlot].Name+" for slot "+InvSlot)
		
		
		printl("Received "+item.tech_name+" when we already had one.")
		
		//item.WeaponInvID=InvSlot
		printl("Loaded WeaponInvID "+InvSlot+". which is "+aPlayer.Weapons[InvSlot].Name)
		
		local PlayerInvSlot=0
		local PlayerWeaponSelectionSlot=null
		foreach(slot,wep in WEAPON_SLOTS)
		{
			if (wep==InvSlot) {PlayerWeaponSelectionSlot=slot;break}
		}
		
		printl("Weapon is already located in inventory cell "+PlayerInvSlot+". which is bound to weapon slot "+PlayerWeaponSelectionSlot)
		
		if (PlayerWeaponSelectionSlot!=null)
		{
			item.ChangeWeaponSlot(PlayerWeaponSelectionSlot)
			printl("Assigned "+aPlayer.Weapons[InvSlot].Name+" to WeaponSlot "+item.WeaponSlot)
		}
	}

}.bindenv(this)


::PlaceItem <- function(container,name,slot=0,count=1,clip=0,durpoints=(-1),rotated=false)	// UNUSED
{
	local ItemEntry=LIST_ITEMS[name]
	local sizex=ItemEntry.sizex
	local sizey=ItemEntry.sizey
	local icon=ItemEntry.icon
	local maxstack=ItemEntry.maxstack
	local Cont=CONTAINERS[container]
	
	while (slot<Cont.ROWS*Cont.COLS&&Cont.INVENTORY[slot]!=null) slot++;
	if (slot==Cont.ROWS*Cont.COLS)
	{
		printl("Tried to place "+name+" into "+container+", but no free space!")
		return
	}
	
	
	
	
	local item=Item(name,count)
	if (durpoints!=(-1)) item.Durability=durpoints
	
	local x=item.SizeX
	local y=item.SizeY
	local i=HasSpaceCont(Cont,x,y)
	
	local item_name=name
	name=ItemEntry.name
	
	if (rotated)
	{
		local bufer=x
		x=y
		y=bufer
		
		local bufer=item.SizeX
		item.SizeX=item.SizeY
		item.SizeY=bufer

		item.Rotated=true
	}
	
	
	if (SERVER_DLL)
	{
		Entities.First().SetContextThink("DelayedItemPlace"+slot+container, function(_) {
		NetMsg.Start("PlaceItemClient");
		NetMsg.WriteString(container)
		NetMsg.WriteByte(ITEMNAME_TO_ID(item_name))
		NetMsg.WriteByte(slot)
		NetMsg.WriteByte(clamp(count,0,maxstack))
		NetMsg.WriteByte(clip)
		NetMsg.WriteShort(durpoints)
		NetMsg.WriteBool(rotated)
		printl("[CONTAINERS] CURRENT NETMSG BUFFER "+NetMsg.GetNumBitsWritten()+" (max 251)")
		if (NetMsg.GetNumBitsWritten()>251) (printl("LIMIT EXCEEDEEEEED! WEEWOOO WEEWOO WEEWOO. THE MESSAGE WILL FAIL"))
		NetMsg.Send(player, true);
		}.bindenv(this),clamp(3-Time(),0,1))	//we place items on client with delay, because for funny reasons the clientside vscript initialises much later than servers. so this is necessary for when giving items when map starts.
	}
	
	item.Clip=clip

	item.Count=count

	Cont.INVENTORY[slot]=item
	for (local j=1;j<(x*y);j++) Cont.INVENTORY[slot+(j%x)+(j/x)*Cont.COLS]=ROWS*COLS+slot;
	
	//printl("placed "+item_name+" into container "+container+" in a slot "+slot)

}.bindenv(this)

function HasSpaceCont(container,x,y,i=0)
{
	local cells=0
	for (i=0;i<container.INVENTORY.len();i++)
	{
		if ((i%container.COLS)>(container.COLS-x)) continue
		if ((i/container.COLS)>(container.ROWS-y)) continue
		
		if (container.INVENTORY[i]==null)
		{
			cells=1
			for (local j=1;j<(x*y);j++) if (container.INVENTORY[i+(j%x)+(j/x)*container.COLS]==null) cells++;
		}
		if (cells==(x*y)) return i
	}
	return false
}

if (SERVER_DLL)
{

	::CreateContainer<-function(container,model=null,pos=null,ang=null)
	{
		local uniquename=UniqueString(container.Name)
		CONTAINERS.rawset(uniquename,clone container)
		printl(CONTAINERS[uniquename])
		
		local ContTable=
		{
			"model":model
			"targetname":container.Name
			"solid":6
			"SetCooldown":0.1
			"spawnflags":512
			"origin":pos.x+" "+pos.y+" "+pos.z
			"angles":ang.x+" "+ang.y+" "+ang.z
			//"OnPressed":"stamina_system:RunScriptCodeQuotable:ContainerMenu(''"+uniquename+"'')"
		}
		local cont=SpawnEntityFromTable("prop_interactable",ContTable)
		cont.GetOrCreatePrivateScriptScope().Open<-function(...){ContainerMenu(uniquename)}.bindenv(this)
		cont.ConnectOutput("OnPressed","Open")
		
		Entities.First().SetContextThink("ContainerSpawnDelayed",function(...){
		NetMsg.Start("CreateContainerClient");
		NetMsg.WriteString(container.Name)
		NetMsg.WriteShort(container.COLS)
		NetMsg.WriteShort(container.ROWS)
		NetMsg.WriteString(uniquename)
		NetMsg.Send(player, true);return}.bindenv(this),clamp(2.5-Time(),0,1.5))
	}.bindenv(this)

}

if (SERVER_DLL)
{

	//PlaceItem("ItemChest","health_kit")
	//PlaceItem("ItemChest","health_kit")
	//PlaceItem("ItemChest","health_kit",8)
	
	PlaceItem("Trader2","item_ammo_pistol",0,72)
	PlaceItem("Trader","weapon_pistol",0)
	PlaceItem("Trader","weapon_357",4)
	PlaceItem("Trader","weapon_colt",2)
	PlaceItem("Trader2","item_ammo_357",2,18)
	PlaceItem("Trader2","item_ammo_45",Trader.COLS*2,80)
	PlaceItem("Trader2","item_ammo_556",Trader.COLS*2+2,120)
	PlaceItem("Trader2","item_ammo_shotgun",Trader.COLS*4,20)
	PlaceItem("Trader","weapon_mp7",Trader.COLS*2)
	PlaceItem("Trader","weapon_m4a1",Trader.COLS*2+3)
	PlaceItem("Trader","weapon_vector",Trader.COLS*2+7)
	PlaceItem("Trader","weapon_shotgun",Trader.COLS*4+4)
	PlaceItem("Trader","weapon_smg45",Trader.COLS*2)
	PlaceItem("Trader","weapon_m590",Trader.COLS*4)
	PlaceItem("Trader","weapon_pipe",Trader.COLS*3+Trader.COLS-1)
	PlaceItem("Trader","weapon_frag",Trader.COLS*4+Trader.COLS-2)
	PlaceItem("Trader","weapon_flashbang",Trader.COLS*5+Trader.COLS-2)
	PlaceItem("Trader2","armor_weldhelmet",Trader.COLS*4+Trader.COLS-2)
	PlaceItem("Trader2","health_kit",Trader.COLS*2+Trader.COLS-2)
	PlaceItem("Trader2","health_vial",Trader.COLS-1)
	PlaceItem("Trader2","wine_a",Trader.COLS-2)
	PlaceItem("Trader2","wine_b",Trader.COLS*2-2)
	//CreateContainer(
	//{
	//	INVENTORY=array(8*3),
	//	Name="Footlocker",
	//	Shop=false,
	//	COLS=8,
	//	ROWS=3
	//},
	//"models/props_forest/footlocker01_closed.mdl",Vector(100,300,12.5),Vector(0,0,0))
	
	Convars.RegisterCommand( "create_container", function(_)
	{
		local trace=TraceLine(player.EyePosition(),player.EyePosition()+player.GetEyeForward()*1000,player)
		local pos=player.EyePosition()+player.GetEyeForward()*1000*trace+Vector(0,0,12.5)
	
		CreateContainer(
		{
			INVENTORY=array(8*3),
			Name="Footlocker",
			Shop=false,
			COLS=8,
			ROWS=3
		},
		"models/props_forest/footlocker01_closed.mdl",pos,Vector(0,player.GetAngles().y,0))
	}.bindenv(this), "", 0 );
	
	Convars.RegisterCommand( "print_inventory_sv", function(_)
	{
		foreach (i,s in INVENTORY)
		{
			if (i%COLS==0) printl("");
			if (s==null) {print(".");continue}
			if ((typeof s)=="instance") print(s.Name.slice(0,1))
			else print(s.tostring().slice(0,1));
		}
	}.bindenv(this), "", 0 );
	
	::SW_GetInventoryScore <- function()
	{
		local score = 0;
		
		// Считаем патроны
		local totalAmmo = 0;
		foreach (item in INVENTORY)
		{
			if (item == null || typeof item == "integer") continue;
			if (item.tech_name.find("ammo") == null) continue;
			totalAmmo += item.Count*(item.Cost/6.0);	//pistol ammo gives 1 point, shotgun and 357 ammo give more.
		}
		
		// Считаем хилки
		local totalHeals = 0;
		foreach (item in INVENTORY)
		{
			if (item == null || typeof item == "integer") continue;
			if (item.tech_name.find("health") == null) continue;
			totalHeals += item.Count*(item.Cost/60.0);	// health vial gives 1 point, health kit gives 2.5
		}
		
		// Считаем броню (сумма защиты)
		local totalArmor = 0;
		foreach (eq in EQUIPMENT)
		{
			if (eq == null) continue;
			if ("resist_bullet" in LIST_ITEMS[eq.tech_name])
				totalArmor += LIST_ITEMS[eq.tech_name].resist_bullet;
			
			if ("resist_melee" in LIST_ITEMS[eq.tech_name])
				totalArmor += LIST_ITEMS[eq.tech_name].resist_melee;
		}
		
		// Взвешенный скор
		score += totalAmmo * 0.3;
		score += totalHeals * 20;
		score += totalArmor * 3;
		
		return score;
	}
	
	::SW_GetInventoryMultiplier <- function()
	{
		local score = SW_GetInventoryScore();   // 0 … ~500+
		
		// 0 … 600 → 0.7 … 1.3
		local mult = 0.7 + clamp(score / 1200.0, 0.0, 0.6);
		
		return mult;
	}

}
//::PlaceItem

::RemoveItem<-function(name,count=1,id=INVENTORY.len()-1,Sync=true)
{
	
	local ItemEntry=LIST_ITEMS[name]
	local item_name=name
	
	
	if (SERVER_DLL&&Sync)
	{
		NetMsg.Start("RemoveItemClient");
		NetMsg.WriteString(name)
		NetMsg.WriteShort(count)
		NetMsg.WriteShort(id)
		NetMsg.Send(player, true);
	}
	name=ItemEntry.name
	
	local item=null
	
	for (local i=id;i>=0;i--)
	{
		if ("Name" in INVENTORY[i]) if (INVENTORY[i].Name==name) {item=i;break}
	}
	if (item==null) return false;
	
	local x=INVENTORY[item].SizeX
	local y=INVENTORY[item].SizeY
	
	local Cols=COLS
	if (item>=COLS*ROWS)
	{
		Cols=CONTAINERS[ActiveContainer].COLS
	}
	
	local Amount=SW_PlayerHasItemCount(INVENTORY[item].Name)
	
	// Absolutely no idea what causes this difference. im too dumb and exhausted to figure it out. this fixes it however.
	if (!Sync)
		Amount++;
	
	if (item<COLS*ROWS) if ("weapon" in ItemEntry&&(!INVENTORY[item].SingleUse||INVENTORY[item].SingleUse&&Amount<2))
	{
		local APlayer=Entities.FindByClassname(null,"weapon_custom_scripted1").GetOrCreatePrivateScriptScope().aPlayer
		
		local Weps=APlayer.Weapons
		
		local HasWeapon=("Weapon" in APlayer)
		
		Weps[INVENTORY[item].WeaponInvID]=null
		
		if (INVENTORY[item].WeaponSlot!=null)
		{
			WEAPON_SLOTS[INVENTORY[item].WeaponSlot]=null
		}
		

		if (HasWeapon&&APlayer.ActiveWeaponSlot==INVENTORY[item].WeaponInvID) {
			APlayer.rawdelete("Weapon");
			if (CLIENT_DLL) SW_HUDPlayerWeapon="";
			APlayer.Weapons[APlayer.ActiveWeaponSlot]=null
			APlayer.ActiveWeaponSlot=(-1)
			printl("removing current weapon!")
			if (SERVER_DLL) player.GetViewModel(0).SetModel("models/blackout.mdl");
		}
		if (aPlayer.DualWield[0]!=null&&aPlayer.DualWield[1]!=null&&aPlayer.DualWield.find(INVENTORY[item].WeaponInvID)!=null)
		{
			APlayer.rawdelete("Weapon");
			if (CLIENT_DLL) SW_HUDPlayerWeapon="";
			if (APlayer.ActiveWeaponSlot!=(-1)) APlayer.Weapons[APlayer.ActiveWeaponSlot]=null
			APlayer.ActiveWeaponSlot=(-1)
			printl("removing current weapon!")
			if (SERVER_DLL) player.GetViewModel(0).SetModel("models/blackout.mdl");		
		}
		

	}
	if (item<COLS*ROWS) if ("weapon" in ItemEntry&&(INVENTORY[item].SingleUse&&Amount>1))
	{
		// When removing single-use weapon, don't do anything if there's still at least one left
	}
	
	if (INVENTORY[item].Count<=count)
	{
		count-=INVENTORY[item].Count
		INVENTORY[item]=null
		for (local j=1;j<(x*y);j++) INVENTORY[item+(j%x)+(j/x)*Cols]=null;
	}
	else
	{
		INVENTORY[item].Count-=count;
		count=0
	}
	
	//if (CLIENT_DLL) printl("REMOVING ITEM FROM CLIENT SUCCESSFULLY")
	//if (SERVER_DLL) printl("REMOVING ITEM FROM SERVER SUCCESSFULLY")
	if (SERVER_DLL) if (count>0) RemoveItem(item_name,count,id,Sync)
	return true
}


if (CLIENT_DLL)
{

	surface.CreateFont( "WeaponSlots6",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Tahoma"    // Name of the font file
		"tall"            : 12       // Size of the text
		"weight"        : 500        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local WeaponSlotsFont=surface.GetFont( "WeaponSlots6", true )
	surface.CreateFont( "WeaponSlotsS",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Tahoma"    // Name of the font file
		"tall"            : 12       // Size of the text
		"weight"        : 500        // Amount of boldness to add
		"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local WeaponSlotsSFont=surface.GetFont( "WeaponSlotsS", true )

	surface.CreateFont( "InventoryDesc32",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Lucida Console"    // Name of the font file
		"tall"            : 6       // Size of the text
		"weight"        : 0        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local InventoryDescFont=surface.GetFont( "InventoryDesc32", true )
	
	surface.CreateFont( "InventoryTrait4",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "MxPlus HP 150 re."    // Name of the font file
		"tall"            : 8       // Size of the text
		"weight"        : 300        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local InventoryTraitFont=surface.GetFont( "InventoryTrait4", true )
	
	surface.CreateFont( "InventoryTraitSmall4",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "MxPlus HP 150 re."    // Name of the font file
		"tall"            : 6       // Size of the text
		"weight"        : 300        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local InventoryTraitSmallFont=surface.GetFont( "InventoryTraitSmall4", true )
	
	surface.CreateFont( "InventoryDescBlur3",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Lucida Console"    // Name of the font file
		"tall"            : 6       // Size of the text
		"weight"        : 0        // Amount of boldness to add
		"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : true           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local InventoryDescBlurFont=surface.GetFont( "InventoryDescBlur3", true )
	
	surface.CreateFont( "KeyHint5",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Tahoma"    // Name of the font file
		"tall"            : 6       // Size of the text
		"weight"        : 0        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"dropshadow"     : true           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local KeyHintFont=surface.GetFont( "KeyHint5", true )
	
	surface.CreateFont( "VerySmol",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 10        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );


	local ATLAS_TEXTURE=surface.ValidateTexture("vgui/inventory/item_atlas",true,false,false)
	local ARMOR_SLOTS_TEXTURE=surface.ValidateTexture("vgui/inventory/armor_slots",true,false,false)
	local ARMOR_SLOTS2_TEXTURE=surface.ValidateTexture("vgui/inventory/armor_slots2",true,false,false)
	local ATLAS_TEXTURE_ROTATED=surface.ValidateTexture("vgui/inventory/item_atlas_rotated",true,false,false)
	local ATLAS_SIZE=16.0

	function DrawOutlinedBox(b,w,t,x,y)
	{
		local border=b
		local wide=w
		local tall=t
		surface.DrawFilledRect( x, y,wide,border );
		surface.DrawFilledRect( x, y+border,border,tall-border );
		surface.DrawFilledRect( x+border, y+tall-border,wide-border,border );
		surface.DrawFilledRect( x+wide-border, y+border,border,tall-border*2 );
	}
	
	local Cell=YRES(30)
	
	local FRAME_WIDE=0
	local FRAME_X=0
	local FRAME_Y=0
	local FRAME_HEIGHT=0
	
	local CELLS_X=0
	local CELLS_Y=Cell*0.5
	
	local INFO_X=0
	local INFO_WIDE=0
	local INFO_HEIGHT=0
	local INFO_Y=Cell*0.5
	
	
	local C_FRAME_WIDE=Cell*10+8			//please reload these guys when opening container on client
	local C_FRAME_X=ScreenWidth()/2-C_FRAME_WIDE/2
	local C_FRAME_Y=YRES(64)
	local C_FRAME_HEIGHT=YRES(200)-Cell*1.5
	
	local C_CELLS_X=ScreenWidth()/2-C_FRAME_WIDE/2-Cell+YRES(2)
	local C_CELLS_Y=YRES(36)+Cell*0.5
	
	//local Image=surface.ValidateTexture("vgui/inventory/healthvial",true,false,false)
	
	::InvP <- null
	use_button <- null
	repair_button <- null
	unload_button <- null
	next_button <- null
	prev_button <- null

	cx<-XRES(240)
	cy<-YRES(-50)
	
	CurX<-XRES(320)
	CurY<-YRES(240)
	
	PrevCurX<-[XRES(320),XRES(320),XRES(320)]
	PrevCurY<-[YRES(240),YRES(240),YRES(240)]
	
	local CellBrdr=clamp(YRES(1)/2,1,100)
	
	local FocusX = 0
	local FocusY = 0
	local FocusEquipment = -1
	local ContainerFocus=false
	
	local Dropping=false
	
	
	
	local LastPress=-10
	
	
	local Drag=false
	local DragRotated=false
	local DragEquipment=false
	local DragExtra=false
	local DragCount=-1
	local DragID=(-1)
	local DragCurX=0
	local DragCurY=0
	local DragSizeX=1
	local DragSizeY=1
	
	local Selection=-1
	local SelectionEquipment=false

	local ItemOverlap=false;
	
	TitleMargin<-YRES(6)
	
	TitleFont<-surface.GetFont( "VerySmol", true )
	TitleFontS<-surface.GetFont( "VerySmolShadow", true )
	
	TitleHeight<-surface.GetFontTall(TitleFont)*1.75
	
	local EQUIPMENT_X=Cell*17
	local EQUIPMENT_Y=FRAME_Y-Cell*1.5
		
	local EQUIPMENT_POS=array(EQUIPMENT.len())
	
	function SwitchTab(newTab)
	{
		if (newTab == CURRENT_TAB) return
		if (newTab < 0 || newTab > 2) return

		SKILLS_Selected = null
		SKILLS_Unlocking = false
		QUEST_SELECTED = -1
		QUEST_SELECTED_TAB = 0

		Drag = false
		DragEquipment = false
		DragID = -1
		Selection = -1
		SelectionEquipment = false

		CURRENT_TAB = newTab
		surface.PlaySound("ui/tab_switch.wav")
	}
	
	function EqFocus()
	{
		if (ActiveContainer) return false;
		
		//printl(DragCurX)
		//printl(DragCurY)
		
		for (local i=0;i<EQUIPMENT.len();i++)
		{
			if (DragCurX>0) { if ((CurX-DragCurX+Cell/2>=EQUIPMENT_POS[i].x&&CurX-DragCurX+Cell/2<=EQUIPMENT_POS[i].x+Cell)&&(CurY-DragCurY+Cell/2>=EQUIPMENT_POS[i].y&&CurY-DragCurY+Cell/2<=EQUIPMENT_POS[i].y+Cell)) return i; }
			else if ((CurX>=EQUIPMENT_POS[i].x&&CurX<=EQUIPMENT_POS[i].x+Cell*2)&&(CurY>=EQUIPMENT_POS[i].y&&CurY<=EQUIPMENT_POS[i].y+Cell*2)) return i;
		}
		
		return false
	}

		
	function GetCellX(fx,InContainer=false)
	{
		if (EqFocus()!=false) return EQUIPMENT_POS[EqFocus()].x;
		//printl(fx)
		local Cols=COLS
		local Cells_X=CELLS_X
		if (InContainer) Cols=CONTAINERS[ActiveContainer].COLS
		if (InContainer) Cells_X=C_CELLS_X
		return RemapVal(fx,0,Cols,Cells_X+Cell,Cells_X+Cell*(Cols+1))
	}
	function GetCellY(fx,InContainer=false)
	{
		if (EqFocus()!=false) return EQUIPMENT_POS[EqFocus()].y;
		
		local Rows=ROWS
		local Cells_Y=CELLS_Y
		if (InContainer) Rows=CONTAINERS[ActiveContainer].ROWS
		if (InContainer) Cells_Y=C_CELLS_Y
		return RemapVal(fx,0,Rows,Cells_Y+Cell,Cells_Y+Cell*(Rows+1))
	}
	
	local GetCursor=2
	
	local OpenTime=-10
	
	local ControlsHints=0;
	
	local HintX=XRES(640)
	local HintY=YRES(480)
	local HintHeight=YRES(16)
	local HintGap=YRES(2)
	
	function DisplayHint(buttonx,buttony,text,key="")
	{
		if (CURRENT_TAB != TAB_INVENTORY) return;
		
		local TextWidth=YRES(90)
		local X=HintX-(HintHeight+HintGap+TextWidth+HintGap)
		local Y=HintY-(HintHeight+HintGap)*ControlsHints
		
		local Wide=(buttonx==0.5&&buttony==0.25)
		
		surface.SetColor(0,3,5,230)
		surface.DrawFilledRect(X,Y,XRES(640)-X-HintGap,HintHeight)
		surface.SetColor(255,255,255,255)
		
		surface.DrawTexturedSubRect(X,Y,X+HintHeight*(1+Wide.tointeger()),Y+HintHeight,buttonx,buttony,buttonx+0.25*(1+Wide.tointeger()),buttony+0.25)
		surface.DrawColoredText(KeyHintFont,X+HintHeight*(1+Wide.tointeger())+HintGap,Y+HintHeight/2.0-surface.GetFontTall(KeyHintFont)/2.0,255,255,255,255,text)
		surface.DrawColoredText(KeyHintFont,X+HintHeight*(1+Wide.tointeger())/2.0-surface.GetTextWidth(KeyHintFont,key)/2.0,Y+HintHeight/2.0-surface.GetFontTall(KeyHintFont)/2.0,25,185,255,255,key)
		ControlsHints++
	}
	
	function DisplayHintTwo(buttonx,buttony,button2x,button2y,text,key="",key2="")
	{
		if (CURRENT_TAB != TAB_INVENTORY) return;
		
		local TextWidth=YRES(90)
		local X=HintX-(HintHeight+HintGap+TextWidth+HintGap)
		local Y=HintY-(HintHeight+HintGap)*ControlsHints
		
		
		local Wide=(buttonx==0.5&&buttony==0.25)
		local Wide2=(button2x==0.5&&button2y==0.25)
		
		local S=HintHeight*(1.5+Wide.tointeger())
		
		surface.SetColor(0,3,5,230)
		surface.DrawFilledRect(X,Y,XRES(640)-X-HintGap,HintHeight)
		surface.SetColor(255,255,255,255)
		
		surface.DrawTexturedSubRect(X,Y,X+HintHeight*(1+Wide.tointeger()),Y+HintHeight,buttonx,buttony,buttonx+0.25*(1+Wide.tointeger()),buttony+0.25)
		surface.DrawTexturedSubRect(X+S,Y,S+X+HintHeight*(1+Wide2.tointeger()),Y+HintHeight,button2x,button2y,button2x+0.25*(1+Wide2.tointeger()),button2y+0.25)
		surface.DrawColoredText(KeyHintFont,S+X+HintHeight*(1+Wide2.tointeger())+HintGap,Y+HintHeight/2.0-surface.GetFontTall(5)/2.0,255,255,255,255,text)
		surface.DrawColoredText(KeyHintFont,X+HintHeight*(3+Wide.tointeger()*2)/2.0-surface.GetTextWidth(KeyHintFont,key)/2.0,Y+HintHeight/2.0-surface.GetFontTall(KeyHintFont)/2.0,255,255,255,255,"+")
		surface.DrawColoredText(KeyHintFont,X+HintHeight*(1+Wide.tointeger())/2.0-surface.GetTextWidth(KeyHintFont,key)/2.0,Y+HintHeight/2.0-surface.GetFontTall(KeyHintFont)/2.0,25,185,255,255,key)
		ControlsHints++
	}
	
	function GetItemCost(item,IsSell,Count=-1)
	{
		if (Count==-1) Count=item.Count
		local MainCost=(item.Cost*Count*((IsSell) ? item.SellMultiplier : 1)).tointeger()
		local AmmoCost=0
		local DurMod=RemapValClamped(item.Durability.tofloat()/item.MaxDurability.tofloat(),0.0,1.0,0.15,1.0)
		if ("ammoitem" in LIST_ITEMS[item.tech_name])
		{
			MainCost=(MainCost*DurMod).tointeger()
		}
		if ("ammoitem" in LIST_ITEMS[item.tech_name]&&item.Clip>0)
			AmmoCost=(LIST_ITEMS[LIST_ITEMS[item.tech_name].ammoitem].cost*item.Clip*((IsSell) ? 0.5 : 1)).tointeger()
		return MainCost+AmmoCost
	}
	
	function SetColorBasedOnItem(item)
	{
		if (item.tech_name.find("health")!=null) surface.SetColor( 14, 169, 14, 255 );
		else if ("Use" in LIST_ITEMS[item.tech_name]) surface.SetColor( 84, 168, 131, 255 );
		else if ("singleuse" in LIST_ITEMS[item.tech_name]) surface.SetColor( 181, 74, 28, 255 );
		else if (item.tech_name.find("ammo")!=null) surface.SetColor( 191, 143, 12, 255 );
		else if (item.tech_name.find("armor")!=null) surface.SetColor( 60, 124, 157, 255 );
		else if (item.tech_name.find("weapon")!=null) surface.SetColor( 70, 70, 70, 255 );
		else surface.SetColor( 0, 90, 190, 255 );
	}
	
	function GetColorBasedOnItem(item)
	{
		local c=[]
		
		if ("Use" in LIST_ITEMS[item.tech_name]) c=[ 84, 168, 131, 255 ];
		else if (item.tech_name.find("health")!=null) c=[ 14, 169, 14, 255 ];
		else if (item.tech_name.find("weapon")!=null) c=[ 70, 70, 70, 255 ];
		else if (item.tech_name.find("ammo")!=null) c=[ 191, 143, 12, 255 ];
		else if (item.tech_name.find("armor")!=null) c=[ 60, 124, 157, 255 ];
		else if ("singleuse" in LIST_ITEMS[item.tech_name]) c=[ 181, 74, 28, 255 ];
		else c=[0, 90, 190, 255];
		
		return c
	}
	
	function InvDraw()
	{
		
		local StatusFont=surface.GetFont( "StatusEffectName8", true )
		local StatusFont2=surface.GetFont( "StatusEffectThin12", true )
		local StatusFont3=surface.GetFont( "StatusEffectSmall61", true )
		local StatusFont4=surface.GetFont( "StatusEffectTiny55", true )
		
		local Border=YRES(140+3*sin(Time()))
		surface.SetColor( 15*0.8, 20*0.8, 25*0.8, 255 ); //5
		surface.DrawFilledRect( FRAME_X-CellBrdr*4, FRAME_Y,  FRAME_WIDE+CellBrdr*8, FRAME_HEIGHT );
		if (ActiveContainer) { surface.SetColor( 15*0.8, 20*0.8, 25*0.8, 255 ); surface.DrawFilledRect( C_FRAME_X-CellBrdr*4, C_FRAME_Y,  C_FRAME_WIDE+CellBrdr*8, C_FRAME_HEIGHT );}
		surface.SetColor( 18, 23, 28, 205 );
		
		for (local i=0;i<EQUIPMENT.len();i++)
		{
			if (ActiveContainer) break;
			
			EQUIPMENT_POS[i]=Vector(EQUIPMENT_X+Cell*(1), EQUIPMENT_Y+Cell*(i+1)*2.5)
		}

		local ItemInfoWidth=(FRAME_WIDE-(CELLS_X+Cell*(COLS+1)-FRAME_X)-CellBrdr*5)

		//surface.DrawFilledRectFade( CELLS_X+Cell*(COLS+1)+ItemInfoWidth/2, FRAME_Y, ItemInfoWidth/2, FRAME_HEIGHT,0,255,true );
		//if (ActiveContainer) surface.DrawFilledRectFade( C_FRAME_X+FRAME_WIDE/8*7, C_FRAME_Y, C_FRAME_WIDE/8, C_FRAME_HEIGHT,0,255,true );

		//surface.DrawFilledRectFade( CELLS_X+Cell*(COLS+1), FRAME_Y, ItemInfoWidth/2, FRAME_HEIGHT,255,0,true );
		//if (ActiveContainer) surface.DrawFilledRectFade( C_FRAME_X+C_FRAME_WIDE/8*6, C_FRAME_Y, C_FRAME_WIDE/8, C_FRAME_HEIGHT,255,0,true );
		
		surface.SetColor( 0, 0, 0, 250 );
		
		local OutlineBrdr=YRES(1)
		
		surface.SetColor( 0, 30, 40, 255 );
		DrawOutlinedBox(OutlineBrdr*2,FRAME_WIDE-OutlineBrdr*2, FRAME_HEIGHT-OutlineBrdr*2-TitleHeight/2, FRAME_X+OutlineBrdr, FRAME_Y+OutlineBrdr+TitleHeight/2)
		if (ActiveContainer) DrawOutlinedBox(OutlineBrdr*2,C_FRAME_WIDE-OutlineBrdr*2, C_FRAME_HEIGHT-OutlineBrdr*2-TitleHeight/2, C_FRAME_X+OutlineBrdr, C_FRAME_Y+OutlineBrdr+TitleHeight/2)
		
		surface.SetColor( 0, 80, 140, 255 );
		DrawOutlinedBox(OutlineBrdr,FRAME_WIDE, FRAME_HEIGHT-TitleHeight/2, FRAME_X, FRAME_Y+TitleHeight/2)
		if (ActiveContainer) DrawOutlinedBox(OutlineBrdr,C_FRAME_WIDE, C_FRAME_HEIGHT-TitleHeight/2, C_FRAME_X, C_FRAME_Y+TitleHeight/2)
		
		
		surface.SetColor( 0, 190, 255, 255 );
		DrawOutlinedBox(OutlineBrdr,FRAME_WIDE+2*OutlineBrdr, FRAME_HEIGHT+2*OutlineBrdr-TitleHeight/2, FRAME_X-OutlineBrdr, FRAME_Y-OutlineBrdr+TitleHeight/2)
		if (ActiveContainer) DrawOutlinedBox(OutlineBrdr,C_FRAME_WIDE+2*OutlineBrdr, C_FRAME_HEIGHT+2*OutlineBrdr-TitleHeight/2, C_FRAME_X-OutlineBrdr, C_FRAME_Y-OutlineBrdr+TitleHeight/2)
			
		//if (ActiveContainer) surface.DrawFilledRect(C_FRAME_X+C_FRAME_WIDE-YRES(16)+XRES(2), C_FRAME_Y-YRES(16)-XRES(2),YRES(16), YRES(16))
		surface.SetColor( 0, 30, 50, 255 );
		DrawOutlinedBox(OutlineBrdr,FRAME_WIDE+4*OutlineBrdr, FRAME_HEIGHT+4*OutlineBrdr-TitleHeight/2, FRAME_X-2*OutlineBrdr, FRAME_Y-2*OutlineBrdr+TitleHeight/2)
		if (ActiveContainer) DrawOutlinedBox(OutlineBrdr,C_FRAME_WIDE+4*OutlineBrdr, C_FRAME_HEIGHT+4*OutlineBrdr-TitleHeight/2, C_FRAME_X-2*OutlineBrdr, C_FRAME_Y-2*OutlineBrdr+TitleHeight/2)
			
		
		surface.SetColor( 15, 20, 25, 255 );
		surface.DrawFilledRect(FRAME_X+FRAME_WIDE-YRES(16)+YRES(2), FRAME_Y-YRES(2)+CellBrdr*2,YRES(16), YRES(16))
		surface.SetColor( 0, 190, 255, 255 );
		DrawOutlinedBox(OutlineBrdr,YRES(16),YRES(16), FRAME_X+FRAME_WIDE-YRES(16)+YRES(2),FRAME_Y-YRES(2)+CellBrdr*2)

		
		local TitleGap=0
		
		
		if (ContainerPages) foreach(i,Page in ContainerPages)
		{
			
			local TitleXGap=Cell*0.75+CellBrdr*2

			surface.SetColor( 0, 40, 80, 255 );
			
			if (ActiveContainer==Page)
			{
				surface.DrawFilledRect( C_FRAME_X+TitleGap+TitleXGap, C_FRAME_Y,  2*TitleMargin+surface.GetTextWidth(TitleFontS,CONTAINERS[Page].Name),TitleHeight );
				surface.DrawColoredText(TitleFont, C_FRAME_X+TitleMargin+TitleGap+TitleXGap, C_FRAME_Y-surface.GetFontTall(TitleFont)*0.5+TitleHeight/2, 25,225,255,255,CONTAINERS[Page].Name)
				surface.DrawColoredText(TitleFontS, C_FRAME_X+TitleMargin+TitleGap+TitleXGap, C_FRAME_Y-surface.GetFontTall(TitleFontS)*0.5+TitleHeight/2, 25,125,155,245+10*sin(Time()*2),CONTAINERS[Page].Name)
				
				surface.SetColor( 0, 80, 140, 255 );		
				DrawOutlinedBox(OutlineBrdr*2,2*TitleMargin+surface.GetTextWidth(TitleFontS,CONTAINERS[Page].Name),TitleHeight, C_FRAME_X+TitleXGap+TitleGap, C_FRAME_Y)
				surface.SetColor( 0, 190, 255, 255 );
				DrawOutlinedBox(OutlineBrdr,2*TitleMargin+surface.GetTextWidth(TitleFontS,CONTAINERS[Page].Name),TitleHeight, C_FRAME_X+TitleXGap+TitleGap, C_FRAME_Y)
			}
			else
			{
				surface.DrawFilledRect( C_FRAME_X+TitleGap+TitleXGap, C_FRAME_Y,  2*TitleMargin+surface.GetTextWidth(TitleFontS,CONTAINERS[Page].Name),TitleHeight );
				
				surface.DrawColoredText(TitleFont, C_FRAME_X+TitleMargin+TitleGap+TitleXGap, C_FRAME_Y-surface.GetFontTall(TitleFont)*0.5+TitleHeight/2, 2,25,25,195,CONTAINERS[Page].Name)
				surface.DrawColoredText(TitleFontS, C_FRAME_X+TitleMargin+TitleGap+TitleXGap, C_FRAME_Y-surface.GetFontTall(TitleFontS)*0.5+TitleHeight/2, 2,15,15,235+10*sin(Time()*2),CONTAINERS[Page].Name)
				
				surface.SetColor( 0, 40, 70, 255 );		
				DrawOutlinedBox(OutlineBrdr*2,2*TitleMargin+surface.GetTextWidth(TitleFontS,CONTAINERS[Page].Name),TitleHeight, C_FRAME_X+TitleXGap+TitleGap, C_FRAME_Y)
				surface.SetColor( 0, 90, 155, 255 );
				DrawOutlinedBox(OutlineBrdr,2*TitleMargin+surface.GetTextWidth(TitleFontS,CONTAINERS[Page].Name),TitleHeight, C_FRAME_X+TitleXGap+TitleGap, C_FRAME_Y)
			}
			
			TitleGap+=3*TitleMargin+surface.GetTextWidth(TitleFontS,CONTAINERS[Page].Name)
		}
		else
		{
			// === ВКЛАДКИ: Inventory / Quests / Skills ===
			local TitleXGap = Cell*0.75+CellBrdr*2
			local TabGap = 0
			
			local TabList = []
			
			if (ActiveContainer)
			{
				TabList.append({ name = CONTAINERS[ActiveContainer].Name, id = -1, x = C_FRAME_X, y = C_FRAME_Y })
			}
			else
			{
				TabList.append({ name = Localize.GetTokenAsUTF8("UI_INVENTORY"), id = TAB_INVENTORY, x = FRAME_X, y = FRAME_Y })
				TabList.append({ name = "Quests",              id = TAB_QUESTS,    x = FRAME_X, y = FRAME_Y })
				TabList.append({ name = "Skills",              id = TAB_SKILLS,    x = FRAME_X, y = FRAME_Y })
			}
			
			foreach (tab in TabList)
			{
				local isActive = (tab.id == CURRENT_TAB) || (tab.id == -1)
				local textW = surface.GetTextWidth(TitleFontS, tab.name)
				local TabX = tab.x + TitleXGap + TabGap
				local TabY = tab.y
				local TabW = 2*TitleMargin + textW
				local TabH = TitleHeight
				
				// Проверка наведения мыши
				local isHover = (CurX > TabX && CurX < TabX + TabW && CurY > TabY && CurY < TabY + TabH)
				
				// === ФОН ===
				if (isActive)
				{
					// Активная вкладка — ярко-синий фон
					surface.SetColor( 0, 45, 85, 255 )
				}
				else if (isHover)
				{
					// Наведение — слегка подсвеченный фон
					surface.SetColor( 0, 28, 50, 255 )
				}
				else
				{
					// Обычная неактивная — тёмный фон
					surface.SetColor( 0, 15, 25, 255 )
				}
				surface.DrawFilledRect( TabX, TabY, TabW, TabH )
				
				// === ТЕКСТ ===
				local ty = TabY - surface.GetFontTall(TitleFont)*0.5 + TabH/2
				
				if (isActive)
				{
					// Активная — ярко-голубой, с тенью
					surface.DrawColoredText(TitleFont,  TabX + TitleMargin, ty, 25, 225, 255, 255, tab.name)
					surface.DrawColoredText(TitleFontS, TabX + TitleMargin, ty, 25, 125, 155, 235, tab.name)
				}
				else if (isHover)
				{
					// Наведение — светло-голубой
					surface.DrawColoredText(TitleFont,  TabX + TitleMargin, ty, 120, 200, 240, 255, tab.name)
					surface.DrawColoredText(TitleFontS, TabX + TitleMargin, ty, 60, 110, 150, 235, tab.name)
				}
				else
				{
					// Обычная неактивная — приглушённый серо-голубой
					surface.DrawColoredText(TitleFont,  TabX + TitleMargin, ty, 60, 120, 160, 255, tab.name)
					surface.DrawColoredText(TitleFontS, TabX + TitleMargin, ty, 30, 60, 90, 235, tab.name)
				}
				
				// === РАМКИ ===
				if (isActive)
				{
					surface.SetColor( 0, 80, 140, 255 )
					DrawOutlinedBox(OutlineBrdr*2, TabW, TabH, TabX, TabY)
					surface.SetColor( 0, 190, 255, 255 )
					DrawOutlinedBox(OutlineBrdr, TabW, TabH, TabX, TabY)
				}
				else if (isHover)
				{
					surface.SetColor( 0, 60, 110, 255 )
					DrawOutlinedBox(OutlineBrdr*2, TabW, TabH, TabX, TabY)
					surface.SetColor( 0, 140, 200, 255 )
					DrawOutlinedBox(OutlineBrdr, TabW, TabH, TabX, TabY)
				}
				else
				{
					surface.SetColor( 0, 35, 60, 255 )
					DrawOutlinedBox(OutlineBrdr*2, TabW, TabH, TabX, TabY)
					surface.SetColor( 0, 70, 120, 255 )
					DrawOutlinedBox(OutlineBrdr, TabW, TabH, TabX, TabY)
				}
				
				TabGap += TabW + YRES(5)
			}
		}
		
		
		//FocusX = (RemapVal(CurX,CELLS_X+Cell,CELLS_X+Cell*7,0,6)+0.5).tointeger()
		//FocusY = (RemapVal(CurY,CELLS_Y+Cell,CELLS_Y+Cell*5,0,4)+0.5).tointeger()
		
		// ADD FocusContainer Bool for future focusslot check!
		
		
		/////////////////////////
		///   HINTS DISPLAY   ///
		/////////////////////////
		
		ControlsHints=1.5
		
		surface.SetColor(255,255,255,255)
		surface.SetTexture(surface.ValidateTexture("vgui/hud/gameinstructor_iconsheet2",true,false,false))
		if (Drag&&!DragEquipment)
		{
		
			DisplayHint(0.25,0,"Place")
			if (INVENTORY[DragID].Count>1)
			{
				DisplayHint(0.25,0.25,"Change Amount","0-9")
				DisplayHint(0,0.25,"Change Amount")
			}
		}
		else
		{
			local item=null
			
			if (FocusX+FocusY*COLS>=0&&FocusX+FocusY*COLS<ROWS*COLS&&INVENTORY[FocusX+FocusY*COLS]!=null) item=INVENTORY[FocusX+FocusY*COLS]
			DisplayHint(0.5,0.25,"(HOLD) Assign Weapons","ALT")
			if ((typeof item)=="integer") item=clone INVENTORY[item];
			if (item) DisplayHint(0,0,"Rotate")
			if (item) DisplayHint(0.25,0,"(HOLD) Drag")
			if (item&&item.Count>1) DisplayHintTwo(0.5,0.25,0.25,0,"(HOLD) Drag Half","CTRL","")
			if (item&&("weapon" in LIST_ITEMS[item.tech_name])&&input.IsButtonDown(ButtonCode.KEY_LALT)) DisplayHint(0.25,0.25,"Assign to Weapon Slot","0-6")
			//if (item&&("Use" in LIST_ITEMS[item.tech_name])&&input.IsButtonDown(ButtonCode.KEY_LALT)) DisplayHint(0.25,0.25,"Assign to Quick Slot","0-4")
				
			if (!SelectionEquipment&&Selection>=0&&item&&("Use" in LIST_ITEMS[item.tech_name])) DisplayHint(0.25,0.25,"Use Item","E")
		}
	
	
		if (!ActiveContainer)
		{
			surface.SetTexture(surface.ValidateTexture("vgui/health",true,false,false))
				
			surface.SetColor(5,195,255,15)
			
			local texture_w=(Cell*7.5)/0.836
			
			surface.DrawTexturedRect(EQUIPMENT_X+Cell*2,FRAME_Y+EQUIPMENT_Y-Cell*2.25,texture_w,texture_w)
		}
		
		
		for (local i=0;i<EQUIPMENT.len();i++)
		{
			if (ActiveContainer) break;
			
			local row=i
			local col=0
			
			EQUIPMENT_X=Cell*17
			EQUIPMENT_Y=FRAME_Y-Cell*1.75
			
			EQUIPMENT_POS[i]=Vector(EQUIPMENT_X+Cell*(col+1), EQUIPMENT_Y+Cell*(row+1)*2.75)
			
			local SlotFocus=(CurX>EQUIPMENT_POS[i].x&&CurX<EQUIPMENT_POS[i].x+2*Cell)&&(CurY>EQUIPMENT_POS[i].y&&CurY<EQUIPMENT_POS[i].y+2*Cell)
			
			surface.SetColor( 0, 10, 20, 255 );
			if (i>=ROWS*COLS) surface.SetColor( 0, 10, 20, 205 );
			if (!Drag&&SlotFocus&&EQUIPMENT[i]==null) surface.SetColor( 0, 30, 60, 155 );
			surface.DrawFilledRect( EQUIPMENT_X+Cell*(col+1), EQUIPMENT_Y+Cell*(row+1)*2.75,  Cell*2,Cell*2 );
			surface.SetColor( 0, 30, 50, 255 );
			if (!Drag&&SlotFocus) surface.SetColor( 40, 240, 120, 255 );
			DrawOutlinedBox(CellBrdr,Cell*2,Cell*2, EQUIPMENT_X+Cell*(col+1), EQUIPMENT_Y+Cell*(row+1)*2.75 );
			//if (INVENTORY[i]) surface.DrawColoredText(5, XRES(64)+Cell*(col+1)+Cell/2-surface.GetTextWidth(TitleFont,INVENTORY[i].tostring())/2, YRES(48)+Cell*(row+1)+Cell/2-surface.GetFontTall(TitleFont)/2, 25,225,255,115,INVENTORY[i].tostring())
				
			if (EQUIPMENT[i]&&!SlotFocus) surface.SetColor( 5, 100, 170, 255 );
			surface.DrawLine(EQUIPMENT_X+Cell*(col+1)+Cell*2,EQUIPMENT_Y+Cell*(row+1)*2.75+Cell,EQUIPMENT_X+Cell*(col+1)+Cell*2+YRES(30-10*i),EQUIPMENT_Y+Cell*(row+1)*2.75+Cell)
			surface.DrawLine(EQUIPMENT_X+Cell*(col+1)+Cell*2,EQUIPMENT_Y+Cell*(row+1)*2.75+Cell+1,EQUIPMENT_X+Cell*(col+1)+Cell*2+YRES(30-10*i),EQUIPMENT_Y+Cell*(row+1)*2.75+Cell+1)
			
		}
		
		
		FocusX = (RemapVal(CurX,CELLS_X+Cell/2+Cell,CELLS_X+Cell*(COLS+1.5),0,COLS)+0.5).tointeger()
		FocusY = (RemapVal(CurY,CELLS_Y+Cell*1.5,CELLS_Y+Cell*(ROWS+1)+Cell*0.5,0,ROWS)+0.5).tointeger()
		
		
		if (CurX<CELLS_X+Cell||CurX>CELLS_X+Cell*(COLS+1)) {FocusX=-5;FocusY=-5}
		if (CurY<CELLS_Y+Cell||CurY>CELLS_Y+Cell*(ROWS+1)) {FocusY=-5;FocusX=-5}
		
		if (EqFocus()!=false) 
		{
			FocusX=100;
			FocusY=100+EqFocus();
		}
		
		if (Drag)
		{
			FocusY = (RemapVal(CurY-DragCurY-Cell*0.75,CELLS_Y+Cell-Cell,CELLS_Y+Cell*(ROWS+1)-Cell*0.75,0,ROWS)+0.5).tointeger()+DragCurY/Cell
			FocusX = (RemapVal(CurX-DragCurX,CELLS_X+Cell,CELLS_X+Cell*(COLS+1),0,COLS)+0.5).tointeger()+DragCurX/Cell
			
			if (CurX-DragCurX+Cell/2<CELLS_X+Cell||CurX>CELLS_X+Cell*(COLS+1)) {FocusY=-5;FocusX=-5}
			if (CurY-DragCurY+Cell/2<CELLS_Y+Cell||CurY>CELLS_Y+Cell*(ROWS+1)) {FocusX=-5;FocusY=-5}	// always save OG focus
			
			if (EqFocus()!=false) 
			{
				FocusX=100;
				FocusY=100+EqFocus();
			}
			
		}
		
		if (Drag&&DragEquipment)
		{
			FocusY = (RemapVal(CurY-DragCurY,CELLS_Y+Cell,CELLS_Y+Cell*(ROWS+1),0,ROWS)+0.5).tointeger()+DragCurY/Cell
			FocusX = (RemapVal(CurX-DragCurX,CELLS_X+Cell,CELLS_X+Cell*(COLS+1),0,COLS)+0.5).tointeger()+DragCurX/Cell
			
			if (CurX-DragCurX<CELLS_X+Cell||CurX>CELLS_X+Cell*(COLS+1)) {FocusY=-5;FocusX=-5}
			if (CurY-DragCurY<CELLS_Y+Cell||CurY>CELLS_Y+Cell*(ROWS+1)) {FocusX=-5;FocusY=-5}	// always save OG focus
			
			if (EqFocus()!=false) 
			{
				FocusX=100;
				FocusY=100+EqFocus();
			}
			
		}
		
		ContainerFocus=false
		
		if ((ActiveContainer!=null)&&(!Drag)&&FocusX<0)
		{
			FocusX = (RemapVal(CurX,C_CELLS_X+Cell*1.5,C_CELLS_X+Cell*(CONTAINERS[ActiveContainer].COLS+1.5),0,CONTAINERS[ActiveContainer].COLS)+0.5).tointeger()
			FocusY = (RemapVal(CurY,C_CELLS_Y+Cell*1.5,C_CELLS_Y+Cell*(CONTAINERS[ActiveContainer].ROWS+1.5),0,CONTAINERS[ActiveContainer].ROWS)+0.5).tointeger()
			ContainerFocus=true
		
			if (CurX<C_CELLS_X+Cell||CurX>C_CELLS_X+Cell*(CONTAINERS[ActiveContainer].COLS+1)) {FocusX=-1;FocusY=-1}
			if (CurY<C_CELLS_Y+Cell||CurY>C_CELLS_Y+Cell*(CONTAINERS[ActiveContainer].ROWS+1)) {FocusY=-1;FocusX=-1}
		}	

		if ((ActiveContainer!=null)&&Drag&&FocusX<0)
		{
			FocusY = (RemapVal(CurY-DragCurY,C_CELLS_Y+Cell,C_CELLS_Y+Cell*(CONTAINERS[ActiveContainer].ROWS+1),0,CONTAINERS[ActiveContainer].ROWS)+0.5).tointeger()+DragCurY/Cell
			FocusX = (RemapVal(CurX-DragCurX,C_CELLS_X+Cell,C_CELLS_X+Cell*(CONTAINERS[ActiveContainer].COLS+1),0,CONTAINERS[ActiveContainer].COLS)+0.5).tointeger()+DragCurX/Cell
			ContainerFocus=true
			
			if (CurX-DragCurX+Cell<C_CELLS_X+Cell||CurX>C_CELLS_X+Cell*(CONTAINERS[ActiveContainer].COLS+1)) {FocusY=-1;FocusX=-1}
			if (CurY-DragCurY+Cell<C_CELLS_Y+Cell||CurY>C_CELLS_Y+Cell*(CONTAINERS[ActiveContainer].ROWS+1)+Cell/2) {FocusX=-1;FocusY=-1}	// always save OG focus
		}
		
		
		surface.SetColor( 0, 30, 50, 255 );
		DrawOutlinedBox(CellBrdr,COLS*Cell+CellBrdr*2,ROWS*Cell+CellBrdr*2, CELLS_X+Cell-CellBrdr, CELLS_Y+Cell-CellBrdr );
		if (ActiveContainer) DrawOutlinedBox(CellBrdr,CONTAINERS[ActiveContainer].COLS*Cell+CellBrdr*2,CONTAINERS[ActiveContainer].ROWS*Cell+CellBrdr*2, C_CELLS_X+Cell-CellBrdr, C_CELLS_Y+Cell-CellBrdr );
		
		for (local i=0;i<INVENTORY.len();i++)
		{
			local NoDraw=((ContainerFocus&&i<ROWS*COLS)||(!ContainerFocus&&i>=ROWS*COLS))
			
			local row=i/COLS
			local col=i%COLS
			local Cells_X=CELLS_X
			local Cells_Y=CELLS_Y	
			
			if (i>=(ROWS*COLS))
			{
				row=(i-ROWS*COLS)/CONTAINERS[ActiveContainer].COLS
				col=(i-ROWS*COLS)%CONTAINERS[ActiveContainer].COLS
				Cells_X=C_CELLS_X
				Cells_Y=C_CELLS_Y	
			}
			
			
			surface.SetColor( 0, 10, 20, 255 );
			if (i>=ROWS*COLS) surface.SetColor( 0, 10, 20, 205 );
			if (!NoDraw&&!Drag&&FocusX==col&&FocusY==row&&INVENTORY[i]==null) surface.SetColor( 0, 30, 60, 155 );
			surface.DrawFilledRect( Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),  Cell,Cell );
			
			
			surface.SetColor( 0, 30, 50, 50 );
			if (INVENTORY[i]==null) surface.DrawFilledRectFade( Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),  Cell,Cell,255,0,false );
			
			surface.SetColor( 0, 30, 50, 255 );
			if (INVENTORY[i]!=null) surface.SetColor( 0, 30, 50, 35 );
			if (!NoDraw&&!Drag&&FocusX==col&&FocusY==row&&INVENTORY[i]==null) surface.SetColor( 40, 240, 120, 255 );
			DrawOutlinedBox(CellBrdr,Cell,Cell, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
			//if (INVENTORY[i]) surface.DrawColoredText(5, XRES(64)+Cell*(col+1)+Cell/2-surface.GetTextWidth(TitleFont,INVENTORY[i].tostring())/2, YRES(48)+Cell*(row+1)+Cell/2-surface.GetFontTall(TitleFont)/2, 25,225,255,115,INVENTORY[i].tostring())
			
		}
		
		
		DrawToolTip<-function(){return}
		
		local SlotsShown=[]
		
		for (local i=0;i<INVENTORY.len();i++)
		{
			local row=i/COLS
			local col=i%COLS
			local Cells_X=CELLS_X
			local Cells_Y=CELLS_Y
			
			
			//if (INVENTORY[i]!=null)	DEBUG
			//{
			//	surface.DrawColoredText(1,Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),20,140,255,255,INVENTORY[i].tostring())
			//}
			
			if (i>=(ROWS*COLS))
			{
				row=i/CONTAINERS[ActiveContainer].COLS
				col=i%CONTAINERS[ActiveContainer].COLS
				Cells_X=C_CELLS_X
				Cells_Y=C_CELLS_Y	
			}
			
			if (INVENTORY[i]!=null)
			{
				surface.SetColor( 0, 90, 190, 255 );
				local item=INVENTORY[i]
				
				
				local ID=i
				
				local Original=true
				
				//if ((typeof item)=="float") INVENTORY[i]=INVENTORY[i].tointeger()
				//if ((typeof item)=="float") item=item.tointeger()
				
				//printl(typeof item)
				if ((typeof item)=="integer"&&INVENTORY[item]==null) {continue}
				if ((typeof item)=="integer") { ID=item; item=INVENTORY[item];Original=false }
				
				
				local ItemEntry=LIST_ITEMS[item.tech_name]

				
				row=ID/COLS
				col=ID%COLS
				
				if (i>=(ROWS*COLS))
				{
					row=(ID-COLS*ROWS)/CONTAINERS[ActiveContainer].COLS
					col=(ID-COLS*ROWS)%CONTAINERS[ActiveContainer].COLS
				}
				
				local FocusSlot=FocusX+FocusY*COLS	//must be real. combine OG focus, plus container focus.
				local CursorOutsideInv=(FocusSlot!=clamp(FocusX+FocusY*COLS,0,(COLS*ROWS-1)))
				
				
				if (ContainerFocus) FocusSlot=FocusX+FocusY*CONTAINERS[ActiveContainer].COLS+ROWS*COLS;
				local CursorOutsideCont=true
				if (ContainerFocus) CursorOutsideCont=(FocusSlot!=clamp(FocusX+FocusY*CONTAINERS[ActiveContainer].COLS+ROWS*COLS,ROWS*COLS,ROWS*COLS+(CONTAINERS[ActiveContainer].COLS*CONTAINERS[ActiveContainer].ROWS-1)));
				if (ContainerFocus&&FocusSlot>=(ROWS*COLS+(CONTAINERS[ActiveContainer].COLS*CONTAINERS[ActiveContainer].ROWS-1))) CursorOutsideInv=true;
				//if (FocusSlot!=clamp(FocusX+FocusY*COLS,0,(COLS*ROWS-1)))
				if (!Original) continue;
			
				//DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
				
				if ("Use" in LIST_ITEMS[item.tech_name]) surface.SetColor( 84, 168, 131, 255 );
				if (item.tech_name.find("health")!=null) surface.SetColor( 14, 169, 14, 255 );
				if (item.tech_name.find("weapon")!=null) surface.SetColor( 70, 70, 70, 255 );
				
				if (item.tech_name.find("ammo")!=null)
				{
					surface.SetColor( 191, 143, 12, 255 );
					if ("caliber" in LIST_ITEMS[item.tech_name]) surface.DrawColoredText(StatusFont4, Cells_X+Cell*(col+1)+YRES(3), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont4)-YRES(2), 191, 143, 12,255,LIST_ITEMS[item.tech_name].caliber)
				}
				if (item.tech_name.find("armor")!=null) 
				{
					surface.SetTexture(ARMOR_SLOTS2_TEXTURE)
					surface.SetColor( 0,193,255,65 );
					local i=item.armorslot
					surface.DrawTexturedSubRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1)+Cell*1.5,Cells_X+Cell*(col+1)+Cell*0.5,Cells_Y+Cell*(row+1)+Cell*2,0,i/4.0,1,i/4.0+0.25)
					surface.SetColor( 60, 124, 157, 255 );
				}
				if ("singleuse" in LIST_ITEMS[item.tech_name]) surface.SetColor( 181, 74, 28, 255 );
				
				local HoverMod=clamp((Time()-item.LastHover)*5,0,1)
				HoverMod=Bias(HoverMod,0.7)
				if (!item.Hovering) HoverMod=1-HoverMod
				
				//printl(HoverMod)
				
				surface.DrawFilledRect(Cells_X+Cell*(col+1),Cells_Y+Cell*(row+1)+Cell*item.SizeY-CellBrdr*2,Cell*item.SizeX,CellBrdr*2)
				
				surface.DrawFilledRectFade(Cells_X+Cell*(col+1),Cells_Y+Cell*(row+1)+Cell*item.SizeY/2.0+Cell*item.SizeY/2.0*(-HoverMod),CellBrdr*2,Cell*item.SizeY/2.0*(1+HoverMod),255*HoverMod,255,false)
				surface.DrawFilledRectFade(Cells_X+Cell*(col+1)+Cell*item.SizeX-CellBrdr*2,Cells_Y+Cell*(row+1)+Cell*item.SizeY/2.0+Cell*item.SizeY/2.0*(-HoverMod),CellBrdr*2,Cell*item.SizeY/2.0*(1+HoverMod),255*HoverMod,255,false)
				
				if (item.tech_name.find("weapon")!=null&&("ammoitem" in LIST_ITEMS[item.tech_name]))
				{
					// DURABILITY
					
					local Dur=item.Durability/(item.MaxDurability*1.0)
					
					local C=Vector(255,255,255)
					if (Dur>1)
					{
						C.x=clamp(255-255*(Dur-1)*4,0,255)
						C.y=clamp(255-78*(Dur-1)*4,0,255)
					}
					if (Dur<1) C.z=clamp(255*(Dur),0,255)
					if (Dur<0.5) C.y=clamp(255*(Dur*2),0,255)
					
					Dur=clamp(Dur,0,1)
					
					surface.SetColor( C.x.tointeger()/2,C.y.tointeger()/2,C.z.tointeger()/2, 255 );
					//surface.SetTexture(surface.ValidateTexture("vgui/inventory/gradient",true,false,false))
					//surface.DrawTexturedRect(Cells_X+Cell*(col+1),Cells_Y+Cell*(row+1),Cell*item.SizeX,Cell*item.SizeY)
					surface.DrawFilledRectFade(Cells_X+Cell*(col+1),Cells_Y+Cell*(row+1),Cell*item.SizeX,Cell*item.SizeY,7*HoverMod,7,false)
					
					surface.SetColor( C.x.tointeger()/2,C.y.tointeger()/2,C.z.tointeger()/2, Dur<0.03 ? 255*(0.5-Time()%2) : 255 );
					surface.DrawFilledRectFade(Cells_X+Cell*(col+1),Cells_Y+Cell*(row+1),Cell*item.SizeX,Cell*item.SizeY,7*HoverMod*(1-Dur),7*(1-Dur),false)
					surface.DrawFilledRectFade(Cells_X+Cell*(col+1),Cells_Y+Cell*(row+1),Cell*item.SizeX,Cell*item.SizeY,7*HoverMod*(1-Dur),7*(1-Dur),false)

				}
				else
					surface.DrawFilledRectFade(Cells_X+Cell*(col+1),Cells_Y+Cell*(row+1),Cell*item.SizeX,Cell*item.SizeY,7*HoverMod*((item.tech_name.find("weapon")!=null) ? 2 : 1),7*((item.tech_name.find("weapon")!=null) ? 2 : 1),false);
			
				SetColorBasedOnItem(item)
				
				HoverMod=clamp((Time()-item.LastHover-0.2)*5,0,1)
				HoverMod=Bias(HoverMod,0.7)
				if (!item.Hovering) HoverMod=1-clamp((Time()-item.LastHover+0.2)*5,0,1)
				surface.DrawFilledRectFade(Cells_X+Cell*(col+1),Cells_Y+Cell*(row+1),Cell*item.SizeX,CellBrdr*2,255*HoverMod,255*HoverMod,false)
				
				
				surface.SetColor( 0, 90, 190, 255 );
				
				if (CURRENT_TAB == TAB_INVENTORY&&!ContainerFocus&&!Drag&&!item.Hovering&&(FocusSlot<COLS*ROWS&&FocusSlot>=0&&((FocusSlot)==ID||INVENTORY[FocusSlot]==ID)))
				{
					item.LastHover=Time();
					item.Hovering=true
					surface.PlaySound("common/noise3.wav")
				}
				
				if (!ContainerFocus&&item.Hovering&&!(Selection==ID&&!SelectionEquipment)&&(FocusSlot>COLS*ROWS||FocusSlot<0||(FocusSlot)!=ID&&INVENTORY[FocusSlot]!=ID))
				{
					item.LastHover=Time();
					item.Hovering=false
				}
				
				if (CURRENT_TAB == TAB_INVENTORY&&!Drag&&ContainerFocus&&!item.Hovering&&(FocusSlot<(ROWS*COLS+(CONTAINERS[ActiveContainer].COLS*CONTAINERS[ActiveContainer].ROWS-1))&&FocusSlot>=ROWS*COLS&&((FocusSlot)==ID||INVENTORY[FocusSlot]==ID)))
				{
					item.LastHover=Time();
					item.Hovering=true
					surface.PlaySound("common/noise3.wav")
				}
				
				if (item.Hovering&&ContainerFocus&&!(Selection==ID&&!SelectionEquipment)&&(FocusSlot>(ROWS*COLS+(CONTAINERS[ActiveContainer].COLS*CONTAINERS[ActiveContainer].ROWS-1))||FocusSlot<ROWS*COLS||(FocusSlot)!=ID&&INVENTORY[FocusSlot]!=ID))
				{
					item.LastHover=Time();
					item.Hovering=false
				}
				
				
				
				local Dur=item.Durability/(item.MaxDurability*1.0)
				if (item.MaxDurability<200) Dur=1;
			
				if ((!CursorOutsideInv)||(!CursorOutsideCont))
				{
					if ((FocusSlot)==ID||INVENTORY[FocusSlot]==ID) {
						surface.SetColor( 0, 30, 60, 255 );
						//if (!Drag) surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cell*item.SizeX,Cell*item.SizeY)
						surface.SetColor( 70, 70, 20, 255 );
						
						//if (Selection==ID&&!SelectionEquipment) surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cell*item.SizeX,Cell*item.SizeY);
						
						surface.SetTexture(item.Rotated ? ATLAS_TEXTURE_ROTATED : ATLAS_TEXTURE)
						local IconX=item.Icon[0]/ATLAS_SIZE;
						local IconY=item.Icon[1]/ATLAS_SIZE;
						local IconF=IconY;
						if (item.Rotated) IconY=IconX;
						if (item.Rotated) IconX=1-IconF;
						
						surface.SetColor( 255,255,255,255 );
						if (Dur<0.03) surface.SetColor( 255,255-100*(Time()-Time().tointeger()),255-100*(Time()-Time().tointeger()),255 );
						if (DragID==ID&&!SelectionEquipment) surface.SetColor( 255,255,255,10 );
						local Difference=item.SizeX-item.SizeY
						if (!item.Rotated) surface.DrawTexturedSubRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cells_X+Cell*(col+1)+Cell*item.SizeX,Cells_Y+Cell*(row+1)+Cell*item.SizeY,IconX,IconY,IconX+item.SizeX/ATLAS_SIZE,IconY+item.SizeY/ATLAS_SIZE)
						else surface.DrawTexturedSubRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cells_X+Cell*(col+1)+Cell*item.SizeX,Cells_Y+Cell*(row+1)+Cell*item.SizeY,IconX-item.SizeX/ATLAS_SIZE,IconY,IconX,IconY+item.SizeY/ATLAS_SIZE);
						
						surface.SetColor( 40, 240, 120, 255 );
						
						//if (!Drag&&DragID!=ID) DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
						
						if (Selection==ID&&!SelectionEquipment) 
						{
							SetColorBasedOnItem(item)
							DrawOutlinedBox(CellBrdr*3,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
							
							surface.SetColor( 240, 240, 230, 255 );
							local cr=Cell*0.33
							local cw=CellBrdr*3
							//DrawOutlinedBox(CellBrdr*2,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),cw,cr)
							
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1)+Cell*item.SizeY-cw,cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1)+Cell*item.SizeY-cr,cw,cr)
							
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),cw,cr)
							
							surface.DrawFilledRect(Cells_X+Cell*(col+1)-cr+Cell*item.SizeX, Cells_Y+Cell*(row+1),cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1)-cw+Cell*item.SizeX, Cells_Y+Cell*(row+1),cw,cr)
							
							surface.DrawFilledRect(Cells_X+Cell*(col+1)-cr+Cell*item.SizeX, Cells_Y+Cell*(row+1)+Cell*item.SizeY-cw,cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1)-cw+Cell*item.SizeX, Cells_Y+Cell*(row+1)+Cell*item.SizeY-cr,cw,cr)
						}
							
						if (!Drag) DrawToolTip=function()
						{
							local C=GetColorBasedOnItem(item)
						
							surface.SetColor( C[0]*0.1,C[1]*0.1,C[2]*0.1, 250 );
							surface.DrawFilledRect(CurX+YRES(10)-6,CurY+YRES(10)-6,surface.GetTextWidth(TitleFont,item.Name)+12,surface.GetFontTall(TitleFont)+12)
							surface.SetColor( C[0]*0.5,C[1]*0.5,C[2]*0.5, 50 );
							DrawOutlinedBox(1,surface.GetTextWidth(TitleFont,item.Name)+12,surface.GetFontTall(TitleFont)+12,CurX+YRES(10)-6,CurY+YRES(10)-6)
							surface.SetColor( C[0]*0.75,C[1]*0.75,C[2]*0.75, 50 );
							DrawOutlinedBox(1,surface.GetTextWidth(TitleFont,item.Name)+10,surface.GetFontTall(TitleFont)+10,CurX+YRES(10)-5,CurY+YRES(10)-5)
							
							surface.SetColor( 40, 240, 120, 255 );
							
							surface.DrawColoredText(TitleFont, CurX+YRES(10)+YRES(1.5),CurY+YRES(10)+YRES(1.5), C[0]/4,C[1]/4,C[2]/4,245,item.Name)
							
							surface.DrawColoredText(TitleFont, CurX+YRES(10),CurY+YRES(10), clamp(C[0]+50,0,255),clamp(C[1]+50,0,255),clamp(C[2]+50,0,255),245,item.Name)
						}
					}
					else
					{
						//if (DragID!=ID||SelectionEquipment) DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
						surface.SetColor( 240, 240, 230, 235 );
						if (Selection==ID&&!SelectionEquipment) 
						{
							local cr=Cell*0.2
							local cw=CellBrdr*2
							//DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
							/*
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),cw,cr)
							
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1)+Cell*item.SizeY-cw,cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1)+Cell*item.SizeY-cr,cw,cr)
							
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),cw,cr)
							
							surface.DrawFilledRect(Cells_X+Cell*(col+1)-cr+Cell*item.SizeX, Cells_Y+Cell*(row+1),cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1)-cw+Cell*item.SizeX, Cells_Y+Cell*(row+1),cw,cr)
							
							surface.DrawFilledRect(Cells_X+Cell*(col+1)-cr+Cell*item.SizeX, Cells_Y+Cell*(row+1)+Cell*item.SizeY-cw,cr,cw)
							surface.DrawFilledRect(Cells_X+Cell*(col+1)-cw+Cell*item.SizeX, Cells_Y+Cell*(row+1)+Cell*item.SizeY-cr,cw,cr)
							*/
							
							SetColorBasedOnItem(item)
							DrawOutlinedBox(CellBrdr*3,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
							
						}
						surface.SetColor( 255,255,255,255 );
						if (DragID==ID&&(DragCount==(-1)||DragCount==item.Count)) surface.SetColor( 255,255,255,10 );
						local Difference=item.SizeX-item.SizeY
						//if (!item.Rotated) surface.DrawTexturedRectRotated(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cell*item.SizeX,Cell*item.SizeY,0)
						surface.SetTexture(item.Rotated ? ATLAS_TEXTURE_ROTATED : ATLAS_TEXTURE)
						local IconX=item.Icon[0]/ATLAS_SIZE;
						local IconY=item.Icon[1]/ATLAS_SIZE;
						local IconF=IconY;
						if (item.Rotated) IconY=IconX;
						if (item.Rotated) IconX=1-IconF;
						surface.SetColor( 255,255,255,255 );
						if (Dur<0.03) surface.SetColor( 255,255-100*(Time()-Time().tointeger()),255-100*(Time()-Time().tointeger()),255 );
						if (DragID==ID&&!SelectionEquipment) surface.SetColor( 255,255,255,10 );
						local Difference=item.SizeX-item.SizeY
						if (!item.Rotated) surface.DrawTexturedSubRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cells_X+Cell*(col+1)+Cell*item.SizeX,Cells_Y+Cell*(row+1)+Cell*item.SizeY,IconX,IconY,IconX+item.SizeX/ATLAS_SIZE,IconY+item.SizeY/ATLAS_SIZE)
						else surface.DrawTexturedSubRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cells_X+Cell*(col+1)+Cell*item.SizeX,Cells_Y+Cell*(row+1)+Cell*item.SizeY,IconX-item.SizeX/ATLAS_SIZE,IconY,IconX,IconY+item.SizeY/ATLAS_SIZE)
					}
				}
				else
				{
						//if (DragID!=ID||SelectionEquipment) DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
						surface.SetColor( 240, 240, 70, 255 );
						//if (Selection==ID&&!SelectionEquipment) DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1) );
						surface.SetColor( 255,255,255,255 );
						if (DragID==ID) surface.SetColor( 255,255,255,10 );
						local Difference=item.SizeX-item.SizeY
						surface.SetTexture(item.Rotated ? ATLAS_TEXTURE_ROTATED : ATLAS_TEXTURE)
						local IconX=item.Icon[0]/ATLAS_SIZE;
						local IconY=item.Icon[1]/ATLAS_SIZE;
						local IconF=IconY;
						if (item.Rotated) IconY=IconX;
						if (item.Rotated) IconX=1-IconF;
						surface.SetColor( 255,255,255,255 );
						if (Dur<0.03) surface.SetColor( 255,255-100*(Time()-Time().tointeger()),255-100*(Time()-Time().tointeger()),255 );
						if (DragID==ID&&!SelectionEquipment) surface.SetColor( 255,255,255,10 );
						local Difference=item.SizeX-item.SizeY
						if (!item.Rotated) surface.DrawTexturedSubRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cells_X+Cell*(col+1)+Cell*item.SizeX,Cells_Y+Cell*(row+1)+Cell*item.SizeY,IconX,IconY,IconX+item.SizeX/ATLAS_SIZE,IconY+item.SizeY/ATLAS_SIZE)
						else surface.DrawTexturedSubRect(Cells_X+Cell*(col+1), Cells_Y+Cell*(row+1),Cells_X+Cell*(col+1)+Cell*item.SizeX,Cells_Y+Cell*(row+1)+Cell*item.SizeY,IconX-item.SizeX/ATLAS_SIZE,IconY,IconX,IconY+item.SizeY/ATLAS_SIZE)
				}
					
				if (item.tech_name.find("weapon")!=null&&("ammoitem" in LIST_ITEMS[item.tech_name]))
				{
					// DURABILITY
					
					local Dur=item.Durability/(item.MaxDurability*1.0)
					
					local C=Vector(255,255,255)
					if (Dur>1)
					{
						C.x=clamp(255-255*(Dur-1)*4,0,255)
						C.y=clamp(255-78*(Dur-1)*4,0,255)
					}
					if (Dur<1) C.z=clamp(255*(Dur),0,255)
					if (Dur<0.5) C.y=clamp(255*(Dur*2),0,255)
					
					//Dur=clamp(Dur,0,1)
					
					surface.SetColor( C.x,C.y,C.z, 255 );
					surface.DrawFilledRectFade(Cells_X+Cell*(col+1)+CellBrdr*2,Cells_Y+Cell*(row+1)+Cell*item.SizeY-CellBrdr*4,((Cell*item.SizeX-CellBrdr*8)-Cell*0.5)*Dur,CellBrdr*2,255,0,true)
					surface.DrawColoredText(StatusFont4, Cells_X+Cell*(col+1)+CellBrdr*2, Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont4)-YRES(2), C.x,C.y,C.z,25,format("%.3i%%",Dur*100))
					surface.DrawColoredText(StatusFont4, Cells_X+Cell*(col+1)+CellBrdr*2, Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont4)-YRES(2), C.x,C.y,C.z,255,format("%3i%%",Dur*100))
				}
				
				if (item.Count>1) 
				{
					if (DragID!=ID)
					{
						local c=GetColorBasedOnItem(item)
						//surface.DrawColoredText(StatusFont, Cells_X+Cell*(col+1)+Cell*item.SizeX-surface.GetTextWidth(StatusFont,format("%.2i",item.Count))-YRES(2)-2, Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont)-2, c[0]/6,c[1]/6,c[2]/6, 255,format("%.2i",item.Count))
						surface.DrawColoredText(StatusFont, Cells_X+Cell*(col+1)+Cell*item.SizeX-surface.GetTextWidth(StatusFont,format("%.2i",item.Count))-YRES(3), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont), c[0],c[1],c[2], 55,format("%.2i",item.Count))
						surface.DrawColoredText(StatusFont, Cells_X+Cell*(col+1)+Cell*item.SizeX-surface.GetTextWidth(StatusFont,item.Count.tostring())-YRES(3), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont), c[0],c[1],c[2],255,item.Count.tostring())
					}
					else
					{
						local CountDisplay=item.Count-DragCount
						if (CountDisplay>item.Count) CountDisplay=0;
						if (CountDisplay>0)
						{
							//surface.DrawColoredText(TitleFontS, Cells_X+Cell*(col+1)+Cell*item.SizeX-surface.GetTextWidth(TitleFontS,item.Count.tostring()+" "), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(TitleFontS), 25,25,25,155,CountDisplay.tostring())
							//surface.DrawColoredText(TitleFont, Cells_X+Cell*(col+1)+Cell*item.SizeX-surface.GetTextWidth(TitleFont,item.Count.tostring()+" "), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(TitleFont), 25,225,255,195,CountDisplay.tostring())
						
							local c=GetColorBasedOnItem(item)
							//surface.DrawColoredText(StatusFont, Cells_X+Cell*(col+1)+Cell*item.SizeX-surface.GetTextWidth(StatusFont,format("%.2i",item.Count))-YRES(2)-2, Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont)-2, c[0]/6,c[1]/6,c[2]/6, 255,format("%.2i",item.Count))
							surface.DrawColoredText(StatusFont, Cells_X+Cell*(col+1)+Cell*item.SizeX-surface.GetTextWidth(StatusFont,format("%.2i",CountDisplay))-YRES(3), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont), c[0],c[1],c[2], 55,format("%.2i",CountDisplay))
							surface.DrawColoredText(StatusFont, Cells_X+Cell*(col+1)+Cell*item.SizeX-surface.GetTextWidth(StatusFont,CountDisplay.tostring())-YRES(3), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont), c[0],c[1],c[2],255,CountDisplay.tostring())
					
						}
					}
				}
				
				//if ("weapon" in ItemEntry&&input.IsButtonDown(ButtonCode.KEY_LALT)&&i<ROWS*COLS)
				if ("weapon" in ItemEntry&&i<ROWS*COLS)
				{
					local mod=1
					if (item.WeaponSlot) mod=(SlotsShown.find((item.WeaponSlot+1).tostring())==null) ? 1 : 0.05
					
					surface.SetColor( 250,250,250,155*mod );
					
					local font=WeaponSlotsFont
					local fontshadow=WeaponSlotsSFont
					
					
					surface.SetTexture(surface.ValidateTexture("vgui/inventory/triangle",true,false,false))
					local C=GetColorBasedOnItem(item)
					if (C[0]==70) 
						surface.SetColor(C[0]*0.4,C[1]*0.4,C[2]*0.4,255);
					else
						surface.SetColor(C[0]*0.7,C[1]*0.7,C[2]*0.7,255);
					
					
					local TriSize=Cell*0.5
					local TriGap=CellBrdr*4
					
					
					if (item.WeaponSlot!=null)
					{
						if (mod==1)
						{
							surface.DrawTexturedRect(Cells_X+Cell*(col+1)+Cell*item.SizeX-TriSize-TriGap,Cells_Y+Cell*(row+1)+Cell*item.SizeY-TriSize-TriGap,TriSize,TriSize)
							surface.DrawColoredText(StatusFont2, Cells_X+Cell*(col+1)+Cell*item.SizeX-YRES(9)-(surface.GetTextWidth(StatusFont2,"8")-surface.GetTextWidth(StatusFont2,(item.WeaponSlot+1).tostring())), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont2)*1.5+YRES(4), 235,235,235,195*mod,(item.WeaponSlot+1).tostring())
						}
						else
						{
							TriSize=Cell*0.25
							surface.DrawTexturedRect(Cells_X+Cell*(col+1)+Cell*item.SizeX-TriSize-TriGap,Cells_Y+Cell*(row+1)+Cell*item.SizeY-TriSize-TriGap,TriSize,TriSize)
							//surface.DrawColoredText(StatusFont4, Cells_X+Cell*(col+1)+Cell*item.SizeX-YRES(7)-(surface.GetTextWidth(StatusFont4,"8")-surface.GetTextWidth(StatusFont4,(item.WeaponSlot+1).tostring())), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(StatusFont4)*1.25, 235,235,235,195,(item.WeaponSlot+1).tostring())
						
						}
					}
					
					
					//surface.DrawFilledRect(Cells_X+Cell*(col+1)+Cell*item.SizeX-CellBrdr*4,Cells_Y+Cell*(row+1)+Cell*item.SizeY-Cell*0.33-CellBrdr*4,CellBrdr*2,Cell*0.33+CellBrdr)
					//surface.DrawFilledRect(Cells_X+Cell*(col+1)+Cell*item.SizeX-Cell*0.33-CellBrdr*4,Cells_Y+Cell*(row+1)+Cell*item.SizeY-CellBrdr*4,Cell*0.33+CellBrdr*2,CellBrdr*2)
					
					if (item.WeaponSlot) SlotsShown.append((item.WeaponSlot+1).tostring())
					
					//surface.DrawColoredText(font, Cells_X+Cell*(col+1)+YRES(5)+(surface.GetTextWidth(font,"8")-surface.GetTextWidth(font,(item.WeaponSlot+1).tostring())), Cells_Y+Cell*(row+1)-YRES(3), 255,225,255,195,(item.Clip).tostring())
					//surface.DrawOutlinedCircle(Cells_X+Cell*(col+1)+surface.GetTextWidth(font,"8")/2+YRES(5),Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(font)/2-YRES(3),surface.GetFontTall(font)/2,4)
				}
				
				if ("Use" in ItemEntry&&input.IsButtonDown(ButtonCode.KEY_LALT)&&i<ROWS*COLS)
				{
					surface.SetColor( 255,25,175,55 );
					local font=WeaponSlotsFont
					local fontshadow=WeaponSlotsSFont
					/*
					if (item.QuickUseSlot!=null)
					{
						surface.DrawColoredText(fontshadow, Cells_X+Cell*(col+1)+YRES(5)+(surface.GetTextWidth(font,"8")-surface.GetTextWidth(font,(item.QuickUseSlot+1).tostring())), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(font)-YRES(3), 255,25,125,55,(item.QuickUseSlot+1).tostring())
						surface.DrawColoredText(font, Cells_X+Cell*(col+1)+YRES(5)+(surface.GetTextWidth(font,"8")-surface.GetTextWidth(font,(item.QuickUseSlot+1).tostring())), Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(font)-YRES(3), 255,225,255,195,(item.QuickUseSlot+1).tostring())
					}
					*/
					//surface.DrawColoredText(font, Cells_X+Cell*(col+1)+YRES(5)+(surface.GetTextWidth(font,"8")-surface.GetTextWidth(font,(item.WeaponSlot+1).tostring())), Cells_Y+Cell*(row+1)-YRES(3), 255,225,255,195,(item.Clip).tostring())
					surface.DrawOutlinedCircle(Cells_X+Cell*(col+1)+surface.GetTextWidth(font,"8")/2+YRES(5),Cells_Y+Cell*(row+1)+Cell*item.SizeY-surface.GetFontTall(font)/2-YRES(3),surface.GetFontTall(font)/2,6)
				}
				
				//if (ActiveContainer && CONTAINERS[ActiveContainer].Shop) surface.DrawColoredText(31, Cells_X+Cell*(col+1)+4, Cells_Y+Cell*(row+1)+2, 5,5,5,245,"$"+GetItemCost(item,i<(ROWS*COLS)).tostring());
				//if (ActiveContainer && CONTAINERS[ActiveContainer].Shop) surface.DrawColoredText(31, Cells_X+Cell*(col+1)+2, Cells_Y+Cell*(row+1), 25,255,25,245,"$"+GetItemCost(item,i<(ROWS*COLS)).tostring());
				if (ActiveContainer && CONTAINERS[ActiveContainer].Shop) 
				{
					surface.SetTexture(surface.ValidateTexture("vgui/inventory/stats",true,false,false))
					surface.SetColor(255,255,255,255)
					
					local DamageIconSize=16
					if (YRES(18)>50)
						DamageIconSize=32;
					
					local CantBuy=((i>=ROWS*COLS)&&(PlayerMoney<(item.Cost*item.Count)))
					
					if (CantBuy) surface.SetColor(255,0,0,255);
					
					surface.DrawTexturedSubRect(Cells_X+Cell*(col+1)+4, Cells_Y+Cell*(row+1)+2,Cells_X+Cell*(col+1)+4+DamageIconSize, Cells_Y+Cell*(row+1)+2+DamageIconSize, 0.51,0.51,1.01,1.01)
					surface.SetColor(0,0,0,215)
					surface.DrawFilledRect(Cells_X+Cell*(col+1)+4+DamageIconSize+CellBrdr, Cells_Y+Cell*(row+1)+2,surface.GetTextWidth(StatusFont4,GetItemCost(item,i<(ROWS*COLS)).tostring())+DamageIconSize/2,DamageIconSize)
					
					surface.DrawColoredText(StatusFont4, Cells_X+Cell*(col+1)+DamageIconSize+CellBrdr*4+DamageIconSize/4, Cells_Y+Cell*(row+1)+CellBrdr*2+DamageIconSize/2-surface.GetFontTall(StatusFont4)/2, 255,CantBuy ? 0 : 255,0,255,GetItemCost(item,i<(ROWS*COLS)).tostring())

					surface.SetColor(255,255,0,255)
					if (CantBuy) surface.SetColor(255,0,0,255);
					surface.DrawOutlinedRect(Cells_X+Cell*(col+1)+4+DamageIconSize+CellBrdr, Cells_Y+Cell*(row+1)+2,surface.GetTextWidth(StatusFont4,GetItemCost(item,i<(ROWS*COLS)).tostring())+DamageIconSize/2,DamageIconSize,DamageIconSize/16)
					
				}
			}
		}
		
		
		for (local i=0;i<EQUIPMENT.len();i++)
		{
			if (ActiveContainer) break;
		
			local row=i/COLS
			local col=i%COLS
			local Cells_X=CELLS_X
			local Cells_Y=CELLS_Y	
			
			if (i>=(ROWS*COLS))
			{
				row=i/CONTAINERS[ActiveContainer].COLS
				col=i%CONTAINERS[ActiveContainer].COLS
				Cells_X=C_CELLS_X
				Cells_Y=C_CELLS_Y	
			}
			
			if (EQUIPMENT[i]!=null)
			{
				surface.SetColor( 0, 90, 190, 255 );
				local item=EQUIPMENT[i]
				
				local ID=i
				//printl(typeof item)
				
				row=ID/COLS
				col=ID%COLS
				
				local FocusSlot=EqFocus()
				
				local Eq_X=EQUIPMENT_POS[i].x
				local Eq_Y=EQUIPMENT_POS[i].y

				

				//if (FocusSlot!=clamp(FocusX+FocusY*COLS,0,(COLS*ROWS-1)))

					//printl(FocusSlot)
					//printl(ID)
				
					if ((FocusSlot)==ID) {
						surface.SetColor( 0, 30, 60, 255 );
						if (!Drag) surface.DrawFilledRect(Eq_X, Eq_Y,Cell*item.SizeX,Cell*item.SizeY)
						surface.SetColor( 70, 70, 20, 255 );
						if (Selection==ID&&SelectionEquipment) surface.DrawFilledRect(Eq_X, Eq_Y,Cell*item.SizeX,Cell*item.SizeY);
						
						surface.SetTexture(item.Rotated ? ATLAS_TEXTURE_ROTATED : ATLAS_TEXTURE)
						local IconX=item.Icon[0]/ATLAS_SIZE;
						local IconY=item.Icon[1]/ATLAS_SIZE;
						local IconF=IconY;
						if (item.Rotated) IconY=IconX;
						if (item.Rotated) IconX=1-IconF;
						surface.SetColor( 255,255,255,255 );
						if (DragID==ID) surface.SetColor( 255,255,255,10 );
						local Difference=item.SizeX-item.SizeY
						if (!item.Rotated) surface.DrawTexturedSubRect(Eq_X, Eq_Y,Eq_X+Cell*item.SizeX,Eq_Y+Cell*item.SizeY,IconX,IconY,IconX+item.SizeX/ATLAS_SIZE,IconY+item.SizeY/ATLAS_SIZE)
						else surface.DrawTexturedSubRect(Eq_X, Eq_Y,Eq_X+Cell*item.SizeX,Eq_Y+Cell*item.SizeY,IconX-item.SizeX/ATLAS_SIZE,IconY,IconX,IconY+item.SizeY/ATLAS_SIZE);
						
						surface.SetColor( 40, 240, 120, 255 );
						if (!Drag&&DragID!=ID) DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Eq_X, Eq_Y );
						surface.SetColor( 240, 240, 80, 255 );
						if (Selection==ID&&SelectionEquipment) DrawOutlinedBox(CellBrdr*3,Cell*item.SizeX,Cell*item.SizeY, Eq_X, Eq_Y );
						
							
						if (!Drag) DrawToolTip=function()
						{
						
							surface.SetColor( 0, 8, 16, 250 );
							surface.DrawFilledRect(CurX+YRES(8)-6,CurY+YRES(8)-6,surface.GetTextWidth(TitleFont,item.Name)+12,surface.GetFontTall(TitleFont)+12)
							surface.SetColor( 1,53,95, 50 );
							DrawOutlinedBox(1,surface.GetTextWidth(TitleFont,item.Name)+12,surface.GetFontTall(TitleFont)+12,CurX+YRES(8)-6,CurY+YRES(8)-6)
							surface.SetColor( 1,93,155, 50 );
							DrawOutlinedBox(1,surface.GetTextWidth(TitleFont,item.Name)+10,surface.GetFontTall(TitleFont)+10,CurX+YRES(8)-5,CurY+YRES(8)-5)
							
							surface.SetColor( 40, 240, 120, 255 );
							surface.DrawColoredText(TitleFont, CurX+YRES(8),CurY+YRES(8), 25,225,255,245,item.Name)
						}
					}
					else
					{
						if (DragID!=ID||!DragEquipment) DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Eq_X, Eq_Y );
						surface.SetColor( 240, 240, 70, 255 );
						if (Selection==ID&&SelectionEquipment&&SelectionEquipment) DrawOutlinedBox(CellBrdr,Cell*item.SizeX,Cell*item.SizeY, Eq_X, Eq_Y );
						surface.SetColor( 255,255,255,255 );
						if (DragID==ID&&(DragCount==(-1)||DragCount==item.Count)&&DragEquipment) surface.SetColor( 255,255,255,10 );
						local Difference=item.SizeX-item.SizeY
						//if (!item.Rotated) surface.DrawTexturedRectRotated(Eq_X, Eq_Y,Cell*item.SizeX,Cell*item.SizeY,0)
						surface.SetTexture(item.Rotated ? ATLAS_TEXTURE_ROTATED : ATLAS_TEXTURE)
						local IconX=item.Icon[0]/ATLAS_SIZE;
						local IconY=item.Icon[1]/ATLAS_SIZE;
						local IconF=IconY;
						if (item.Rotated) IconY=IconX;
						if (item.Rotated) IconX=1-IconF;
						surface.SetColor( 255,255,255,255 );
						if (DragID==ID&&DragEquipment) surface.SetColor( 255,255,255,10 );
						local Difference=item.SizeX-item.SizeY
						if (!item.Rotated) surface.DrawTexturedSubRect(Eq_X, Eq_Y,Eq_X+Cell*item.SizeX,Eq_Y+Cell*item.SizeY,IconX,IconY,IconX+item.SizeX/ATLAS_SIZE,IconY+item.SizeY/ATLAS_SIZE)
						else surface.DrawTexturedSubRect(Eq_X, Eq_Y,Eq_X+Cell*item.SizeX,Eq_Y+Cell*item.SizeY,IconX-item.SizeX/ATLAS_SIZE,IconY,IconX,IconY+item.SizeY/ATLAS_SIZE)
					}
					
				if ("Use" in LIST_ITEMS[item.tech_name]) surface.SetColor( 84, 168, 131, 255 );
				if (item.tech_name.find("health")!=null) surface.SetColor( 14, 169, 14, 255 );
				if (item.tech_name.find("weapon")!=null) surface.SetColor( 70, 70, 70, 255 );
				if (item.tech_name.find("ammo")!=null) surface.SetColor( 191, 143, 12, 255 );
				if (item.tech_name.find("armor")!=null) surface.SetColor( 60, 124, 157, 255 );
				if ("singleuse" in LIST_ITEMS[item.tech_name]) surface.SetColor( 181, 74, 28, 255 );
				
				surface.DrawFilledRect(Eq_X, Eq_Y+Cell*2-CellBrdr*2,Cell*item.SizeX,CellBrdr*2)
				
				surface.DrawFilledRectFade(Eq_X, Eq_Y+Cell,CellBrdr*2,Cell,0,255,false)
				surface.DrawFilledRectFade(Eq_X+Cell*2-CellBrdr*2,Eq_Y+Cell,CellBrdr*2,Cell,0,255,false)
				
				surface.DrawFilledRectFade(Eq_X, Eq_Y,Cell*item.SizeX,Cell*item.SizeY,0,7,false)
				
				surface.SetTexture(ARMOR_SLOTS2_TEXTURE)
				surface.SetColor( 0,193,255,65 );
				surface.DrawTexturedSubRect(Eq_X, Eq_Y+Cell*1.5,Eq_X+Cell*0.5,Eq_Y+Cell*2,0,i/4.0,1,i/4.0+0.25)
				

					
				if (item.Count>1) 
				{
					if (DragID!=ID)
					{
						surface.DrawColoredText(TitleFontS, Eq_X+Cell*item.SizeX-surface.GetTextWidth(TitleFontS,item.Count.tostring()+" "), Eq_Y+Cell*item.SizeY-surface.GetFontTall(TitleFontS), 25,25,25,255,item.Count.tostring())
						surface.DrawColoredText(TitleFont, Eq_X+Cell*item.SizeX-surface.GetTextWidth(TitleFont,item.Count.tostring()+" "), Eq_Y+Cell*item.SizeY-surface.GetFontTall(TitleFont), 25,225,255,255,item.Count.tostring())
					}
					else
					{
						local CountDisplay=item.Count-DragCount
						if (CountDisplay>item.Count) CountDisplay=0;
						if (CountDisplay>0)
						{
							surface.DrawColoredText(TitleFontS, Eq_X+Cell*item.SizeX-surface.GetTextWidth(TitleFontS,item.Count.tostring()+" "), Eq_Y+Cell*item.SizeY-surface.GetFontTall(TitleFontS), 25,25,25,155,CountDisplay.tostring())
							surface.DrawColoredText(TitleFont, Eq_X+Cell*item.SizeX-surface.GetTextWidth(TitleFont,item.Count.tostring()+" "), Eq_Y+Cell*item.SizeY-surface.GetFontTall(TitleFont), 25,225,255,195,CountDisplay.tostring())
						}
					}
				}
			}
			else
			{
				local Eq_X=EQUIPMENT_POS[i].x
				local Eq_Y=EQUIPMENT_POS[i].y
			
				surface.SetTexture(ARMOR_SLOTS_TEXTURE)
				surface.SetColor( 0,193,255,255 );
				if (EqFocus()==i) surface.SetColor( 90,255,100,255 );
				if (EqFocus()==i&&ItemOverlap) surface.SetColor( 255,91,91,255 );
				surface.DrawTexturedSubRect(Eq_X, Eq_Y,Eq_X+Cell*2,Eq_Y+Cell*2,0,i/4.0,1,i/4.0+0.25)
			}
		}
		
		
		DrawToolTip()
		
		local DESC_WIDE=ActiveContainer ? Cell*3.5 : Cell*5
		local DESC_X=INFO_X-YRES(2)
		local DescPadding=ActiveContainer ? YRES(32) : YRES(24)
		local TextPadding=YRES(4)
		
		local IMAGE_WIDE=ActiveContainer ? Cell*5 : Cell*4
		local IMAGE_X=ActiveContainer ? DESC_X+DescPadding/2 : DESC_X+DESC_WIDE+IMAGE_WIDE-Cell*1.25
		
		//local image_offset=ActiveContainer ? YRES(48) : YRES(24)
		local image_offset=ActiveContainer ? Cell*0.5 : 0
		
		surface.SetColor(3,3,3,245)
		//surface.DrawFilledRect(DESC_X+DescPadding/2,INFO_Y+DescPadding,DESC_WIDE-DescPadding+IMAGE_WIDE,INFO_HEIGHT-2*DescPadding)
		
		surface.SetTexture(surface.ValidateTexture("vgui/inventory/frame"+(ActiveContainer ? "_square" : ""),true,false,false))
			
		surface.SetColor(255,255,255,255)
		
		
		local texture_w=(Cell*12)/0.836
		
		if (ActiveContainer)
		{
			texture_w=(FRAME_WIDE-Cell*12)*1.25
			surface.DrawTexturedRect(INFO_X,INFO_Y+Cell*0.75,texture_w,texture_w)
		}
		else
		{
			surface.DrawTexturedRect(INFO_X,INFO_Y,texture_w,texture_w/2)
		}
		
		surface.SetColor(3,3,3,245)

		
		if (Selection>=0&&((INVENTORY[Selection]&&!SelectionEquipment)||(SelectionEquipment&&EQUIPMENT[Selection]))) 
		{
			
			local INFO_Y=INFO_Y+CellBrdr*6
			
			if (ActiveContainer) INFO_Y=INFO_Y+Cell*0.85;
		
			local item=SelectionEquipment ? EQUIPMENT[Selection] : INVENTORY[Selection]
		
			surface.SetTexture(surface.ValidateTexture("rendertarget_menu"+(ActiveContainer ? "_small" : ""),true,false,false))
			
			surface.SetColor(255-50*(ActiveContainer!=null).tointeger(),255-40*(ActiveContainer!=null).tointeger(),255,255-30*(ActiveContainer!=null).tointeger())
			surface.DrawTexturedRect(IMAGE_X+image_offset,INFO_Y+image_offset,IMAGE_WIDE,IMAGE_WIDE)
			
			
			local GapMod=ActiveContainer ? 0.70 : 0.45
		
			surface.DrawColoredText(TitleFontS, DESC_X+DESC_WIDE*GapMod+YRES(2)-surface.GetTextWidth(TitleFontS,item.Name)/2, INFO_Y+YRES(2), 5,5,5,255,item.Name)
			surface.DrawColoredText(TitleFontS, DESC_X+DESC_WIDE*GapMod-YRES(2)-surface.GetTextWidth(TitleFontS,item.Name)/2, INFO_Y-YRES(2), 5,5,5,255,item.Name)
			surface.DrawColoredText(TitleFont, DESC_X+DESC_WIDE*GapMod-surface.GetTextWidth(TitleFont,item.Name)/2, INFO_Y, 25,225,255,245,item.Name)
			
			local desctext=item.Desc+" "
			local textwrite=clamp((Time()-LastPress)/desctext.len()*150,0,1)


			local lines=[]
			
			
			lines=GetTextInLines(InventoryDescFont,DESC_WIDE*1.4,desctext,textwrite*desctext.len())
			local fullLines=GetTextInLines(InventoryDescFont,DESC_WIDE*1.4,desctext,desctext.len())
			
			for (local i=0;i<lines.len();i++) surface.DrawColoredText(InventoryDescBlurFont,DESC_X+DescPadding/2+TextPadding, INFO_Y+DescPadding+(i)*(YRES(2)+surface.GetFontTall(InventoryDescFont)), 2,15,35,255,fullLines[i]);
			for (local i=0;i<lines.len();i++) surface.DrawColoredText(InventoryDescFont,DESC_X+DescPadding/2+TextPadding+1, INFO_Y+DescPadding+(i)*(YRES(2)+surface.GetFontTall(InventoryDescFont))+1, 0,0,0,255,lines[i]);
			
			for (local i=0;i<fullLines.len();i++) 
			{
				surface.DrawColoredText(InventoryDescFont,DESC_X+DescPadding/2+TextPadding, INFO_Y+DescPadding+(i)*(YRES(2)+surface.GetFontTall(InventoryDescFont)), 25,225,255,255,lines[i]);
			}
			
			//local TraitLines=[]
			
			if ("traits" in LIST_ITEMS[item.tech_name])
			{
				
				local TraitFont=ActiveContainer ? InventoryTraitSmallFont : InventoryTraitFont
				
				local traittext=LIST_ITEMS[item.tech_name].traits+" "
				local fullLines=GetTextInLines(TraitFont,DESC_WIDE*1.4,traittext,textwrite*traittext.len())
				
				fullLines=GetTextInLines(TraitFont,DESC_WIDE*1.4,traittext,textwrite*traittext.len())
				//foreach (k,v in GetTextInLines(TraitFont,DESC_WIDE*1.4,traittext,traittext.len(),true)) printl("TEXT "+k+" "+v)
				local colors=GetColoredTextLines(GetTextInLines(TraitFont,DESC_WIDE*2.5,traittext,traittext.len(),true))
				//foreach (k,v in colors) printl(k+" "+v)
				
				local HeightMod=ActiveContainer ? 0.6 : 0.5
				
				for (local i=0;i<fullLines.len();i++) 
				{
					if (!(i.tostring() in colors))
						surface.DrawColoredText(TraitFont,DESC_X+DescPadding/2+TextPadding, INFO_Y+IMAGE_WIDE*HeightMod+DescPadding+(i)*(YRES(2)+surface.GetFontTall(TraitFont)), 25,225,255,255,fullLines[i]);
					else
						surface.DrawColoredText(TraitFont,DESC_X+DescPadding/2+TextPadding, INFO_Y+IMAGE_WIDE*HeightMod+DescPadding+(i)*(YRES(2)+surface.GetFontTall(TraitFont)), colors[i.tostring()].x,colors[i.tostring()].y,colors[i.tostring()].z,255,fullLines[i]);
				}
				
			}
			
			if (!SelectionEquipment)
			{
				local ItemEntry=LIST_ITEMS[INVENTORY[Selection].tech_name]
					
				
				if (ActiveContainer)
				{
					if ("ammoitem" in ItemEntry&&("caliber" in LIST_ITEMS[ItemEntry.ammoitem])) 
						surface.DrawColoredText(InventoryDescFont, IMAGE_X+Cell/2+IMAGE_WIDE-surface.GetTextWidth(InventoryDescFont,"Ammo type: "+LIST_ITEMS[ItemEntry.ammoitem].caliber+" "), INFO_Y+Cell/2+IMAGE_WIDE-surface.GetFontTall(InventoryDescFont)-YRES(2), 255,225,255,245,"Ammo type: "+LIST_ITEMS[ItemEntry.ammoitem].caliber)
					else if ("maxstack" in ItemEntry && ItemEntry.maxstack>1)
					{
						surface.DrawColoredText(InventoryDescFont, IMAGE_X+Cell/2+IMAGE_WIDE-surface.GetTextWidth(InventoryDescFont,"Max Stack: "+ItemEntry.maxstack+" "), INFO_Y+Cell/2+IMAGE_WIDE-surface.GetFontTall(InventoryDescFont)-YRES(2), 255,225,255,245,"Max Stack: "+ItemEntry.maxstack)
					}
				}
				else
				{
					if ("ammoitem" in ItemEntry&&("caliber" in LIST_ITEMS[ItemEntry.ammoitem])) 
						surface.DrawColoredText(InventoryDescFont, IMAGE_X-surface.GetTextWidth(InventoryDescFont,"Ammo type: "+LIST_ITEMS[ItemEntry.ammoitem].caliber+" "), INFO_Y+IMAGE_WIDE-surface.GetFontTall(InventoryDescFont)-YRES(2), 255,225,255,245,"Ammo type: "+LIST_ITEMS[ItemEntry.ammoitem].caliber)
					else if ("maxstack" in ItemEntry && ItemEntry.maxstack>1)
					{
						surface.DrawColoredText(InventoryDescFont, IMAGE_X-surface.GetTextWidth(InventoryDescFont,"Max Stack: "+ItemEntry.maxstack+" "), INFO_Y+IMAGE_WIDE-surface.GetFontTall(InventoryDescFont)-YRES(2), 255,225,255,245,"Max Stack: "+ItemEntry.maxstack)
					}
				}
			}
			//surface.SetColor(3,160,65,245)
			//DrawOutlinedBox(YRES(1),INFO_HEIGHT-2*DescPadding+YRES(1),INFO_HEIGHT-2*DescPadding,DESC_X+DESC_WIDE-DescPadding/2-YRES(1),INFO_Y+DescPadding)
		}
		else
		{
			surface.SetColor(0,60,90,35)
			
			local m=0.35
			
			if (ActiveContainer)
			{
				local INFO_Y=INFO_Y+Cell*0.75+CellBrdr*3
				local IMAGE_X=IMAGE_X-Cell*0.25
				
				//surface.DrawLine(IMAGE_X+image_offset,INFO_Y+YRES(2)+image_offset,IMAGE_X+image_offset+IMAGE_WIDE*m,INFO_Y+image_offset+YRES(2)+IMAGE_WIDE*m)
				//surface.DrawLine(IMAGE_X+image_offset,INFO_Y+YRES(2)+image_offset+IMAGE_WIDE,IMAGE_X+image_offset+IMAGE_WIDE*m,INFO_Y+image_offset+YRES(2)+IMAGE_WIDE-IMAGE_WIDE*m)
				//
				//surface.DrawLine(IMAGE_X+image_offset+IMAGE_WIDE,INFO_Y+YRES(2)+image_offset,IMAGE_X+image_offset+IMAGE_WIDE-IMAGE_WIDE*m,INFO_Y+image_offset+YRES(2)+IMAGE_WIDE*m)
				//surface.DrawLine(IMAGE_X+image_offset+IMAGE_WIDE,INFO_Y+YRES(2)+image_offset+IMAGE_WIDE,IMAGE_X+image_offset+IMAGE_WIDE-IMAGE_WIDE*m,INFO_Y+image_offset+YRES(2)+IMAGE_WIDE-IMAGE_WIDE*m)
				
				surface.DrawColoredText(InventoryDescFont,IMAGE_X+image_offset+IMAGE_WIDE/2-surface.GetTextWidth(InventoryDescFont,"No data available")/2, INFO_Y+image_offset+YRES(2)+IMAGE_WIDE/2-surface.GetFontTall(InventoryDescFont)/2, 15,112,155,35,"No data available");
			}
			else
			{
				surface.DrawLine(IMAGE_X+image_offset,INFO_Y+YRES(2)+image_offset,IMAGE_X+image_offset+IMAGE_WIDE*m,INFO_Y+image_offset+YRES(2)+IMAGE_WIDE*m)
				surface.DrawLine(IMAGE_X+image_offset,INFO_Y+YRES(2)+image_offset+IMAGE_WIDE,IMAGE_X+image_offset+IMAGE_WIDE*m,INFO_Y+image_offset+YRES(2)+IMAGE_WIDE-IMAGE_WIDE*m)
				
				surface.DrawLine(IMAGE_X+image_offset+IMAGE_WIDE,INFO_Y+YRES(2)+image_offset,IMAGE_X+image_offset+IMAGE_WIDE-IMAGE_WIDE*m,INFO_Y+image_offset+YRES(2)+IMAGE_WIDE*m)
				surface.DrawLine(IMAGE_X+image_offset+IMAGE_WIDE,INFO_Y+YRES(2)+image_offset+IMAGE_WIDE,IMAGE_X+image_offset+IMAGE_WIDE-IMAGE_WIDE*m,INFO_Y+image_offset+YRES(2)+IMAGE_WIDE-IMAGE_WIDE*m)
				
				surface.DrawColoredText(InventoryDescFont,IMAGE_X+IMAGE_WIDE/2-surface.GetTextWidth(InventoryDescFont,"No data available")/2, INFO_Y+YRES(2)+IMAGE_WIDE/2-surface.GetFontTall(InventoryDescFont)/2, 15,112,155,35,"No data available");
			}
		}
		
		surface.SetColor(3,60,105,245)
		//DrawOutlinedBox(YRES(1),DESC_WIDE-DescPadding+IMAGE_WIDE,INFO_HEIGHT-2*DescPadding,DESC_X+DescPadding/2,INFO_Y+DescPadding)
		
		if (!DragEquipment&&Drag&&INVENTORY[DragID])
		{
			
			InvP.SetCursor(15)
			local item=INVENTORY[DragID]
			surface.SetColor( 180, 240, 120, 255 );
			//DrawOutlinedBox(CellBrdr*2,Cell*DragSizeX,Cell*DragSizeY, CurX-DragCurX, CurY-DragCurY );
			
			//surface.DrawColoredText(TitleFont, CurX-DragCurX+Cell/2*DragSizeX-surface.GetTextWidth(TitleFont,INVENTORY[DragID].Name)/2, CurY-DragCurY+Cell/2*DragSizeY-surface.GetFontTall(TitleFont)/2, 25,225,255,245,INVENTORY[DragID].Name)
			surface.SetColor( 255,255,255, 255 );
			if (Dropping) surface.SetColor( 255,25,25, 255 );
			//if (Dropping&&(abs(CurY-ScreenHeight()/2)>=INVENTORY[DragID].SizeY*Cell+YRES(192)/2)) surface.DrawColoredText(TitleFont, CurX-DragCurX+Cell*DragSizeX, CurY-DragCurY+Cell*DragSizeY/2-surface.GetFontTall(TitleFont)/2, 255,35,35,245,"Drop")
			
			surface.SetTexture((item.Rotated!=DragRotated) ? ATLAS_TEXTURE_ROTATED : ATLAS_TEXTURE)
			local IconX=item.Icon[0]/ATLAS_SIZE;
			local IconY=item.Icon[1]/ATLAS_SIZE;
			local IconF=IconY;
			
			if (item.Rotated!=DragRotated) 
			{
				IconY=IconX;
				IconX=1-IconF;
			}
			local Difference=DragSizeX-DragSizeY
			if (!(item.Rotated!=DragRotated)) surface.DrawTexturedSubRect(CurX-DragCurX, CurY-DragCurY ,CurX-DragCurX+Cell*DragSizeX, CurY-DragCurY+Cell*DragSizeY, IconX,IconY,IconX+DragSizeX/ATLAS_SIZE,IconY+DragSizeY/ATLAS_SIZE)
			else surface.DrawTexturedSubRect(CurX-DragCurX, CurY-DragCurY ,CurX-DragCurX+Cell*DragSizeX, CurY-DragCurY+Cell*DragSizeY, IconX-DragSizeX/ATLAS_SIZE,IconY,IconX,IconY+DragSizeY/ATLAS_SIZE)
			//surface.DrawTexturedRectRotated(CurX-DragCurX, CurY-DragCurY,Cell*DragSizeX,Cell*DragSizeY,item.Rotated.tointeger()*90)
			surface.SetColor( 130, 240, 90, 255 );
			
			local Cols=COLS
			local Rows=ROWS
			if (ContainerFocus)
			{
				Cols=CONTAINERS[ActiveContainer].COLS
				Rows=CONTAINERS[ActiveContainer].ROWS
			}				
			
			
			if (!ContainerFocus) CanFit(DragSizeX,DragSizeY,FocusX-DragCurX/Cell+(FocusY-DragCurY/Cell)*COLS)
			if (ContainerFocus) CanFit(DragSizeX,DragSizeY,(ROWS*COLS)+FocusX-DragCurX/Cell+(FocusY-DragCurY/Cell)*CONTAINERS[ActiveContainer].COLS)
			//printl("drawing box"+Time())
			if (ItemOverlap) surface.SetColor( 255, 60, 60, 255 );
			
			if ((FocusX-DragCurX/Cell==clamp(FocusX-DragCurX/Cell,0,Cols-DragSizeX)&&FocusY-DragCurY/Cell==clamp(FocusY-DragCurY/Cell,0,Rows-DragSizeY))||(EqFocus()!=false))
			{
				DrawOutlinedBox(CellBrdr*2,Cell*DragSizeX,Cell*DragSizeY, GetCellX(FocusX-DragCurX/Cell,ContainerFocus), GetCellY(FocusY-DragCurY/Cell,ContainerFocus) );
				
				surface.DrawFilledRectFade(GetCellX(FocusX-DragCurX/Cell,ContainerFocus), GetCellY(FocusY-DragCurY/Cell,ContainerFocus),Cell*DragSizeX,Cell*DragSizeY,1,1,false)
			}
			
			if (DragCount!=(-1)) DragCount=clamp(DragCount,1,item.Count)			
		
			if (item.Count>1) 
			{
				local MovingCountText=DragCount.tostring()
				if (DragCount==(-1)) MovingCountText=item.Count.tostring()
					
				local MovingCount=MovingCountText.tointeger()
			
				if (!(Dropping&&DragID==INVENTORY.find(item)))
				{
					//surface.DrawColoredText(TitleFontS, CurX-DragCurX+Cell*DragSizeX-surface.GetTextWidth(TitleFontS,MovingCountText+" "), CurY-DragCurY+Cell*DragSizeY-surface.GetFontTall(TitleFontS), 25,25,25,255,MovingCountText)
					//surface.DrawColoredText(TitleFont, CurX-DragCurX+Cell*DragSizeX-surface.GetTextWidth(TitleFont,MovingCountText+" "), CurY-DragCurY+Cell*DragSizeY-surface.GetFontTall(TitleFont), 25+230*(MovingCountText!=item.Count.tostring()).tointeger(),225,255-235*(MovingCountText!=item.Count.tostring()).tointeger(),255,MovingCountText)
				
					local c=GetColorBasedOnItem(item)
				
					surface.DrawColoredText(StatusFont, CurX-DragCurX+Cell*DragSizeX-surface.GetTextWidth(StatusFont,format("%.2i",MovingCount))-YRES(3), CurY-DragCurY+Cell*DragSizeY-surface.GetFontTall(StatusFont), c[0],c[1],c[2], 55,format("%.2i",MovingCount))
					surface.DrawColoredText(StatusFont, CurX-DragCurX+Cell*DragSizeX-surface.GetTextWidth(StatusFont,MovingCount.tostring())-YRES(3), CurY-DragCurY+Cell*DragSizeY-surface.GetFontTall(StatusFont), c[0],c[1],c[2],255,MovingCount.tostring())
					
				}
				else
				{
					surface.DrawColoredText(TitleFontS, CurX-DragCurX+Cell*DragSizeX-surface.GetTextWidth(TitleFontS,MovingCountText+" "), CurY-DragCurY+Cell*DragSizeY-surface.GetFontTall(TitleFontS), 35,35,35,245,MovingCountText)
					surface.DrawColoredText(TitleFont, CurX-DragCurX+Cell*DragSizeX-surface.GetTextWidth(TitleFont,MovingCountText+" "), CurY-DragCurY+Cell*DragSizeY-surface.GetFontTall(TitleFont), 255,35,35,245,MovingCountText)
				}
			}
			
			if (ActiveContainer && CONTAINERS[ActiveContainer].Shop)
			{
				local IsTrader=(ActiveContainer && CONTAINERS[ActiveContainer].Shop)
				local ToTrader=(IsTrader&&(ContainerFocus&&DragID<(ROWS*COLS)))
				local FromTrader=(IsTrader&&(!ContainerFocus&&DragID>=(ROWS*COLS)))
				
				surface.SetTexture(surface.ValidateTexture("vgui/inventory/stats",true,false,false))
				surface.SetColor(255,255,255,255)
				local i=0;
				
				local DamageIconSize=16
				if (YRES(18)>50)
					DamageIconSize=32;
				
				local CantBuy=(DragID>=(ROWS*COLS)&&(PlayerMoney<(item.Cost*DragCount)))
				
				if (CantBuy) surface.SetColor(255,0,0,255);
				
				surface.DrawTexturedSubRect(CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2)+2,CurX-DragCurX+YRES(2)+DamageIconSize, CurY-DragCurY+YRES(2)+2+DamageIconSize, 0.51,0.51,1.01,1.01)
				surface.SetColor(0,0,0,215)
				surface.DrawFilledRect(CurX-DragCurX+YRES(2)+DamageIconSize+CellBrdr, CurY-DragCurY+YRES(2)+2,surface.GetTextWidth(StatusFont4,GetItemCost(item,i<(ROWS*COLS)).tostring())+DamageIconSize/2,DamageIconSize)
				
				surface.DrawColoredText(StatusFont4, CurX-DragCurX+DamageIconSize+CellBrdr*4+DamageIconSize/4, CurY-DragCurY+YRES(2)+CellBrdr*2+DamageIconSize/2-surface.GetFontTall(StatusFont4)/2, 255,CantBuy ? 0 : 255,0,255,GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring())
				surface.SetColor(255,255,0,255)
				if (CantBuy) surface.SetColor(255,0,0,255);
				surface.DrawOutlinedRect(CurX-DragCurX+YRES(2)+DamageIconSize+CellBrdr, CurY-DragCurY+YRES(2)+2,surface.GetTextWidth(StatusFont4,GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring())+DamageIconSize/2,DamageIconSize,DamageIconSize/16)
			
				if (ToTrader)
				{
					//surface.DrawColoredText(31, CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2), 5,60,5,245,"$"+GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring());
					//surface.DrawColoredText(31, CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2), 15,255,15,255,"$"+GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring());
				}
				else if (FromTrader)
				{
					if (PlayerMoney>=(item.Cost*DragCount))
					{
						//surface.DrawColoredText(31, CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2), 5,5,5,245,"$"+GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring());
						//surface.DrawColoredText(31, CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2), 25,255,25,245,"$"+GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring());
					}
					else
					{
						//surface.DrawColoredText(31, CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2), 5,5,5,245,"$"+GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring());
						//surface.DrawColoredText(31, CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2), 255,25,25,245,"$"+GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring());
					}
				}
				else
				{
					//surface.DrawColoredText(31, CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2), 5,5,5,245,"$"+GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring());
					//surface.DrawColoredText(31, CurX-DragCurX+YRES(2), CurY-DragCurY+YRES(2), 25,255,25,245,"$"+GetItemCost(item,DragID<(ROWS*COLS),DragCount).tostring().tostring());
				}
			}
				
			if (Dropping) surface.DrawColoredText(TitleFont, clamp(CurX-DragCurX+Cell/2*DragSizeX-surface.GetTextWidth(TitleFont,"Drop")/2,0,ScreenWidth()-surface.GetTextWidth(TitleFont,"Drop")), clamp(CurY-DragCurY+Cell*DragSizeY,0,ScreenHeight()-surface.GetFontTall(TitleFont)), 255,35,35,245,"Drop")
		}
		else if (Drag&&EQUIPMENT[DragID]&&DragEquipment)
		{
			
			InvP.SetCursor(15)
			local item=EQUIPMENT[DragID]
			surface.SetColor( 180, 240, 120, 255 );
			//DrawOutlinedBox(CellBrdr*2,Cell*DragSizeX,Cell*DragSizeY, CurX-DragCurX, CurY-DragCurY );
			
			//surface.DrawColoredText(TitleFont, CurX-DragCurX+Cell/2*DragSizeX-surface.GetTextWidth(TitleFont,INVENTORY[DragID].Name)/2, CurY-DragCurY+Cell/2*DragSizeY-surface.GetFontTall(TitleFont)/2, 25,225,255,245,INVENTORY[DragID].Name)
			surface.SetColor( 255,255,255, 255 );
			if (Dropping) surface.SetColor( 255,25,25, 255 );
			//if (Dropping&&(abs(CurY-ScreenHeight()/2)>=INVENTORY[DragID].SizeY*Cell+YRES(192)/2)) surface.DrawColoredText(TitleFont, CurX-DragCurX+Cell*DragSizeX, CurY-DragCurY+Cell*DragSizeY/2-surface.GetFontTall(TitleFont)/2, 255,35,35,245,"Drop")
			
			surface.SetTexture((item.Rotated!=DragRotated) ? ATLAS_TEXTURE_ROTATED : ATLAS_TEXTURE)
			local IconX=item.Icon[0]/ATLAS_SIZE;
			local IconY=item.Icon[1]/ATLAS_SIZE;
			local IconF=IconY;
			local Difference=DragSizeX-DragSizeY
			surface.DrawTexturedSubRect(CurX-DragCurX, CurY-DragCurY ,CurX-DragCurX+Cell*DragSizeX, CurY-DragCurY+Cell*DragSizeY, IconX,IconY,IconX+DragSizeX/ATLAS_SIZE,IconY+DragSizeY/ATLAS_SIZE)
			//surface.DrawTexturedRectRotated(CurX-DragCurX, CurY-DragCurY,Cell*DragSizeX,Cell*DragSizeY,item.Rotated.tointeger()*90)
			surface.SetColor( 180, 240, 120, 255 );
			
			local Cols=COLS
			local Rows=ROWS
			if (ContainerFocus)
			{
				Cols=CONTAINERS[ActiveContainer].COLS
				Rows=CONTAINERS[ActiveContainer].ROWS
			}				
			
			
			if (!ContainerFocus) CanFit(DragSizeX,DragSizeY,FocusX-DragCurX/Cell+(FocusY-DragCurY/Cell)*COLS)
			if (ContainerFocus) CanFit(DragSizeX,DragSizeY,(ROWS*COLS)+FocusX-DragCurX/Cell+(FocusY-DragCurY/Cell)*CONTAINERS[ActiveContainer].COLS)
			//printl("drawing box"+Time())
			if (ItemOverlap) surface.SetColor( 255, 120, 120, 255 );
			
			if ((FocusX-DragCurX/Cell==clamp(FocusX-DragCurX/Cell,0,Cols-DragSizeX)&&FocusY-DragCurY/Cell==clamp(FocusY-DragCurY/Cell,0,Rows-DragSizeY))||(EqFocus()!=false))
			{
				DrawOutlinedBox(CellBrdr*2,Cell*DragSizeX,Cell*DragSizeY, GetCellX(FocusX-DragCurX/Cell,ContainerFocus), GetCellY(FocusY-DragCurY/Cell,ContainerFocus) );
			}
			
			if (DragCount!=(-1)) DragCount=clamp(DragCount,1,item.Count)			
				
			if (Dropping) surface.DrawColoredText(TitleFont, clamp(CurX-DragCurX+Cell/2*DragSizeX-surface.GetTextWidth(TitleFont,"Drop")/2,0,ScreenWidth()-surface.GetTextWidth(TitleFont,"Drop")), clamp(CurY-DragCurY+Cell*DragSizeY,0,ScreenHeight()-surface.GetFontTall(TitleFont)), 255,35,35,245,"Drop")
		}
		else InvP.SetCursor(2);
		
		
		//surface.DrawColoredText(5, 0, 0,25,225,255,245,"X:"+RemapVal(CurX,0,ScreenWidth(),0,640)+" Y:"+RemapVal(CurY,0,ScreenHeight(),0,480))
		
		//surface.DrawColoredText(TitleFont, FRAME_X+OutlineBrdr*5+Cell*COLS,FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(TitleFontS), 25,255,25,245,"Money: $"+PlayerMoney)
		
		local HPWidthT=surface.GetTextWidth(StatusFont,"Money")/2
		local HPWidthN=surface.GetTextWidth(StatusFont,format("$%i",PlayerMoney))/2
		
		//surface.DrawColoredText(StatusFont, FRAME_X+2*Cell+Cell*COLS+2-HPWidthT, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*2.25+2,25/4,255/4,25/4,255,"Money")
		//surface.DrawColoredText(StatusFont, FRAME_X+2*Cell+Cell*COLS-HPWidthT, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*2.25, 25,255,25,255,"Money")

		//surface.DrawColoredText(StatusFont, FRAME_X+2*Cell+Cell*COLS+2-HPWidthN, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*1.25+2, 25/4,255/4,25/4,255,format("$%i",PlayerMoney))
		//surface.DrawColoredText(StatusFont, FRAME_X+2*Cell+Cell*COLS-HPWidthN, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*1.25, 25,255,25,255,format("$%i",PlayerMoney))
		
		
		//surface.DrawColoredText(StatusFont, FRAME_X+OutlineBrdr*12+Cell*COLS+2, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*1.5+2, 25/4,255/4,25/4,255,"Money: $"+PlayerMoney)
		//surface.DrawColoredText(StatusFont, FRAME_X+OutlineBrdr*12+Cell*COLS, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*1.5, 25,255,25,255,"Money: $"+PlayerMoney)
		
		//surface.DrawColoredText(TitleFont, FRAME_X+OutlineBrdr*5+Cell*COLS, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(TitleFontS)*4, 245,255,245,245,format("Health: %i/%i",player.GetHealth(),PlayerMaxHealth))
		
		surface.SetTexture(surface.ValidateTexture("vgui/inventory/stats",true,false,false))
		surface.SetColor(255,255,255,255)
		local i=0;
		
		local DamageIconSize=32
		if (YRES(18)>50)
			DamageIconSize=64;
		
		local ResistStartX=EQUIPMENT_X+Cell
		local ResistStartY=FRAME_Y+FRAME_HEIGHT-Cell*2.5
		
		if (ActiveContainer)
		{
			ResistStartY=FRAME_Y+FRAME_HEIGHT-Cell*0.9
		}
		
		local FieldWide=Cell*2.25-DamageIconSize-CellBrdr*3
		
		surface.DrawTexturedSubRect(ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr, ResistStartY+DamageIconSize*1.5*(i/2)+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2,ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr+DamageIconSize, ResistStartY+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2+DamageIconSize*1.5*(i/2)+DamageIconSize, -0.01,-0.01,0.51,0.51)
		surface.DrawOutlinedRect(ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr, ResistStartY+DamageIconSize*1.5*(i/2)+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2,DamageIconSize,DamageIconSize,DamageIconSize/16)
		
		surface.DrawOutlinedRect(ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr+DamageIconSize+CellBrdr*3, ResistStartY+DamageIconSize*1.5*(i/2)+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2,FieldWide,DamageIconSize,DamageIconSize/16)
		
		surface.DrawColoredText(StatusFont3, ResistStartX+DamageIconSize+CellBrdr+FieldWide/2-surface.GetTextWidth(StatusFont3,format("%3i/%3i",player.GetHealth(),PlayerMaxHealth))/2, ResistStartY+DamageIconSize/2-surface.GetFontTall(StatusFont2)/2, 90,90,90,255,format("%.3i/%.3i",player.GetHealth(),PlayerMaxHealth))
		surface.DrawColoredText(StatusFont3, ResistStartX+DamageIconSize+CellBrdr+FieldWide/2-surface.GetTextWidth(StatusFont3,format("%3i/%3i",player.GetHealth(),PlayerMaxHealth))/2, ResistStartY+DamageIconSize/2-surface.GetFontTall(StatusFont2)/2, 245,255,245,255,format("%3i/%3i",player.GetHealth(),PlayerMaxHealth))
		
		
		surface.SetColor(255,232,31,255)
		if (ActiveContainer)
		{
			ResistStartX=EQUIPMENT_X+Cell+FieldWide+DamageIconSize*2+CellBrdr*6
		}
		else
		{
			ResistStartY=FRAME_Y+FRAME_HEIGHT-Cell*2.5+DamageIconSize+CellBrdr*6
		}
		
		surface.DrawTexturedSubRect(ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr, ResistStartY+DamageIconSize*1.5*(i/2)+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2,ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr+DamageIconSize, ResistStartY+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2+DamageIconSize*1.5*(i/2)+DamageIconSize, 0.49,-0.01,1.01,0.51)
		surface.DrawOutlinedRect(ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr, ResistStartY+DamageIconSize*1.5*(i/2)+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2,DamageIconSize,DamageIconSize,DamageIconSize/16)
		
		surface.DrawOutlinedRect(ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr+DamageIconSize+CellBrdr*3, ResistStartY+DamageIconSize*1.5*(i/2)+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2,FieldWide,DamageIconSize,DamageIconSize/16)
		
		surface.DrawColoredText(StatusFont3, ResistStartX+DamageIconSize+CellBrdr+FieldWide/2-surface.GetTextWidth(StatusFont3,format("%7i",PlayerMoney))/2, ResistStartY+DamageIconSize/2-surface.GetFontTall(StatusFont2)/2, 255*0.2,232*0.2,31*0.2,255,format("%.7i",PlayerMoney))
		surface.DrawColoredText(StatusFont3, ResistStartX+DamageIconSize+CellBrdr+FieldWide/2-surface.GetTextWidth(StatusFont3,format("%7i",PlayerMoney))/2, ResistStartY+DamageIconSize/2-surface.GetFontTall(StatusFont2)/2, 255,232,31,255,format("%7i",PlayerMoney))
		
				// === ОПЫТ ИГРОКА (XP / LEVEL) ===
		if (!ActiveContainer)
		{
			// Расчёт уровня и прогресса
			local XPLevel = (1 + 0.07 * sqrt(PlayerExperience)).tointeger()
			local XPNeedLevel = pow((XPLevel * (1.0 / 0.07)), 2).tointeger()
			local XPPrevLevel = pow(((XPLevel - 1) * (1.0 / 0.07)), 2).tointeger()
			local XPNeedTotal = XPNeedLevel - XPPrevLevel
			local XPInLevel = (PlayerExperience - XPPrevLevel).tointeger()
			if (XPInLevel < 0) XPInLevel = 0
			if (XPNeedTotal < 1) XPNeedTotal = 1

			local XPProgress = clamp(XPInLevel.tofloat() / XPNeedTotal.tofloat(), 0.0, 1.0)

			// === РАЗМЕРЫ ===
			local RowH = DamageIconSize
			local IcoW = DamageIconSize
			local Gap = CellBrdr * 3
			local TotalW = (Cell + DamageIconSize) + FieldWide*2.15 + CellBrdr * 10
			local BarW = TotalW - IcoW - Gap

			local XPY = ResistStartY + RowH + CellBrdr * 6 + YRES(4)
			local XPX = ResistStartX - CellBrdr*2

			// =============================================
			// ПЛАШКА LVL
			// =============================================
			// Тёмно-синий фон
			surface.SetColor(8, 14, 22, 255)
			surface.DrawFilledRect(XPX, XPY, IcoW, RowH)

			// Внутренний градиент (сверху темнее)
			surface.SetColor(0, 0, 0, 80)
			surface.DrawFilledRectFade(XPX, XPY, IcoW, RowH * 0.5, 120, 0, false)

			// Внешняя белая рамка
			surface.SetColor(60, 200, 220, 120)
			surface.DrawOutlinedRect(XPX, XPY, IcoW, RowH, YRES(1))

			// Внутренняя тонкая бирюзовая рамка
			surface.SetColor(0, 0, 0, 120)
			surface.DrawOutlinedRect(XPX + YRES(1), XPY + YRES(1), IcoW - YRES(2), RowH - YRES(2), YRES(1))

			local lvlFont = StatusFont4
			local numFont = StatusFont3
			local lvlText = "LVL"
			local lvlNum = XPLevel.tostring()

			local lw1 = surface.GetTextWidth(lvlFont, lvlText)
			local lw2 = surface.GetTextWidth(numFont, lvlNum)
			local lh2 = surface.GetFontTall(numFont)

			// "LVL" — сверху, приглушённый серо-голубой
			surface.DrawColoredText(lvlFont, XPX + IcoW/2 - lw1/2 + YRES(1), XPY + YRES(2), 0, 0, 0, 200, lvlText)
			surface.DrawColoredText(lvlFont, XPX + IcoW/2 - lw1/2, XPY + YRES(1), 130, 180, 210, 255, lvlText)

			// Цифра уровня — снизу, бирюзовая с тенью
			local numX = XPX + IcoW/2 - lw2/2
			local numY = XPY + RowH - lh2 - YRES(1)
			surface.DrawColoredText(numFont, numX + YRES(1), numY + YRES(1), 0, 0, 0, 255, lvlNum)
			surface.DrawColoredText(numFont, numX, numY, 80, 240, 180, 255, lvlNum)

			// =============================================
			// ПОЛОСА XP
			// =============================================
			local BarX = XPX + IcoW + Gap
			local BarY = XPY
			local BarH = RowH

			// Тёмный фон полосы (тёмно-синий)
			surface.SetColor(6, 10, 18, 255)
			surface.DrawFilledRect(BarX, BarY, BarW, BarH)

			// Вертикальный градиент на фоне (темнее сверху и снизу, светлее в центре)
			surface.SetColor(20, 240, 70, 5)
			surface.DrawFilledRectFade(BarX, BarY, BarW, BarH * 0.5, 100, 0, false)
			surface.SetColor(20, 140, 230, 32)
			surface.DrawFilledRectFade(BarX, BarY + BarH * 0.5, BarW, BarH * 0.5, 0, 100, false)

			// Заполнение — тройной градиент
			local fillW = (BarW - YRES(4)) * XPProgress
			local fillX = BarX + YRES(2)
			local fillY = BarY + YRES(2)
			local fillH = BarH - YRES(4)

						// Слой 1 — тёмно-синий
			surface.SetColor(1, 11, 33, 255)
			surface.DrawFilledRect(fillX, fillY, fillW, fillH)

			// Слой 2 — бирюзовый градиент с лёгкой пульсацией
			local gradPulse = 0.85 + 0.15 * fabs(sin(Time() * 1.8))
			surface.SetColor(0, 255, 50, 200 * gradPulse)
			surface.DrawFilledRectFade(fillX, fillY, fillW, fillH, 0, 220, true)

			// Слой 3 — БЕГУЩИЙ БЛИК (медленно проезжает по заливке)
			local shinePeriod = 2.5                      // период прохода в секундах
			local shineT = (Time() % shinePeriod) / shinePeriod   // 0..1
			local shineCX = fillX + shineT * fillW       // центр блика
			local shineW2 = YRES(20)                     // полуширина

			local shStart = shineCX - shineW2
			local shEnd = shineCX + shineW2
			if (shStart < fillX) shStart = fillX
			if (shEnd > fillX + fillW) shEnd = fillX + fillW

			if (shStart < shEnd)
			{
				surface.SetColor(180, 255, 200, 45)
				surface.DrawFilledRectFade(shStart, fillY, (shEnd - shStart) * 0.5, fillH, 0, 60, true)
				surface.SetColor(180, 255, 200, 45)
				surface.DrawFilledRectFade(shStart + (shEnd - shStart) * 0.5, fillY, (shEnd - shStart) * 0.5, fillH, 60, 0, true)
			}

			// Слой 4 — светлый блик сверху (эффект "стекла")
			local glassPulse = 0.7 + 0.3 * fabs(sin(Time() * 1.5))
			surface.SetColor(10, 240, 25, 60 * glassPulse)
			surface.DrawFilledRectFade(fillX, fillY, fillW, fillH * 0.4, 120, 0, false)

			// Слой 5 — тёмный низ (эффект объёма)
			surface.SetColor(0, 10, 25, 120)
			surface.DrawFilledRectFade(fillX, fillY + fillH * 0.6, fillW, fillH * 0.4, 0, 120, false)

			// Слой 6 — очень лёгкое мерцание всей заливки
			local flick = 0.9 + 0.1 * sin(Time() * 5)
			surface.SetColor(20, 200, 60, 18 * flick)
			surface.DrawFilledRect(fillX, fillY, fillW, fillH)

			// Пульсирующая точка на конце заливки (усилена)
			if (XPProgress > 0.01)
			{
				local pulse = 0.5 + 0.5 * fabs(sin(Time() * 3))
				local pulse2 = 0.5 + 0.5 * fabs(sin(Time() * 3 + 1.5))

				// Узкая яркая полоса
				surface.SetColor(12, 250, 20, 60 * pulse)
				surface.DrawFilledRect(fillX + fillW - YRES(2), fillY - YRES(1), YRES(3), fillH + YRES(2))

				// Центральная белая искра
				surface.SetColor(255, 255, 255, 40 * pulse2)
				surface.DrawFilledRect(fillX + fillW - YRES(1), fillY + fillH * 0.3, YRES(1), fillH * 0.4)
			}

			// Пульсирующая точка на конце заливки
			if (XPProgress > 0.01)
			{
				local pulse = 0.5 + 0.5 * fabs(sin(Time() * 3))
				surface.SetColor(12, 250, 20, 180 * pulse)
				surface.DrawFilledRect(fillX + fillW - YRES(2), fillY - YRES(1), YRES(3), fillH + YRES(2))
				surface.SetColor(20, 255, 240, 100 * pulse)
				surface.DrawFilledRect(fillX + fillW - YRES(1), fillY - YRES(2), YRES(1), fillH + YRES(4))
			}

			// Внешняя белая рамка
			surface.SetColor(25, 225, 25, 85)
			surface.DrawOutlinedRect(BarX, BarY, BarW, BarH, YRES(1))

			// Внутренняя тонкая бирюзовая рамка
			surface.SetColor(6, 15, 20, 100)
			surface.DrawOutlinedRect(BarX + YRES(1), BarY + YRES(1), BarW - YRES(2), BarH - YRES(2), YRES(1))

			// =============================================
			// ТЕКСТ XP ВНУТРИ ПОЛОСЫ
			// =============================================
			local xpText = XPInLevel.tostring() + " / " + XPNeedTotal.tostring()
			local xpFont = StatusFont3
			local xpW = surface.GetTextWidth(xpFont, xpText)
			local xpH = surface.GetFontTall(xpFont)

			local xpTextX = BarX + BarW / 2 - xpW / 2
			local xpTextY = BarY + BarH / 2 - xpH / 2

			// Тень
			surface.DrawColoredText(xpFont, xpTextX + YRES(1), xpTextY + YRES(1), 0, 0, 0, 255, xpText)
			surface.DrawColoredText(xpFont, xpTextX - YRES(1), xpTextY - YRES(1), 0, 0, 0, 255, xpText)
			// Верхний светлый край
			surface.DrawColoredText(xpFont, xpTextX, xpTextY - YRES(1), 18, 2, 5, 250, xpText)
			// Основной текст
			surface.DrawColoredText(xpFont, xpTextX, xpTextY, 240, 250, 255, 255, xpText)
		}
		
		surface.SetColor(255,255,255,255)
			
			//local HPWidthT=surface.GetTextWidth(StatusFont,"Health")/2
			//local HPWidthN=surface.GetTextWidth(StatusFont,format("%i/%i",player.GetHealth(),PlayerMaxHealth))/2
			
			//surface.DrawColoredText(StatusFont, FRAME_X+2*Cell+Cell*COLS+2-HPWidthT, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*4.75+2, 245/4,255/4,245/4,255,"Health")
			//surface.DrawColoredText(StatusFont, FRAME_X+2*Cell+Cell*COLS-HPWidthT, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*4.75, 245,255,245,255,"Health")



			//surface.DrawColoredText(StatusFont, FRAME_X+2*Cell+Cell*COLS+2-HPWidthN, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*3.75+2, 245/4,255/4,245/4,255,format("%i/%i",player.GetHealth(),PlayerMaxHealth))
			//surface.DrawColoredText(StatusFont, FRAME_X+2*Cell+Cell*COLS-HPWidthN, FRAME_Y+FRAME_HEIGHT-OutlineBrdr*5-surface.GetFontTall(StatusFont)*3.75, 245,255,245,255,format("%i/%i",player.GetHealth(),PlayerMaxHealth))
		if (!ActiveContainer)
		{
			local Resists=[0,0,0,0]
			local ResistNames=["MELEE","BULLET","BLAST","ENERGY"]
			local ResistColors=[Vector(255,255,255),Vector(255,230,7),Vector(255,1,1),Vector(5,255,215)]
			
			// I think that enabling Point Sample on the texture makes Subrects behave a little weird. Setting Start Coordinates to 0 actually takes the second pixel and not the first, but this only applies to the start of the texture.
			// Hence we gotta use something like -0.01 instead of 0 here. Same crap happened with Mail textures and practically is also the case with status effects but i didn't fix those since it doesn't catch my eye.
			local ResistPos=[[-0.01,-0.01],[0.5,-0.01],[-0.01,0.5],[0.5,0.5]]
			
			local DamageTypeSize=2.0;
			
			foreach(armor in EQUIPMENT)
			{
				if (armor&&"resist_melee" in LIST_ITEMS[armor.tech_name]) Resists[0]+=LIST_ITEMS[armor.tech_name].resist_melee;
				if (armor&&"resist_bullet" in LIST_ITEMS[armor.tech_name]) Resists[1]+=LIST_ITEMS[armor.tech_name].resist_bullet;
				if (armor&&"resist_blast" in LIST_ITEMS[armor.tech_name]) Resists[2]+=LIST_ITEMS[armor.tech_name].resist_blast;
				if (armor&&"resist_energy" in LIST_ITEMS[armor.tech_name]) Resists[3]+=LIST_ITEMS[armor.tech_name].resist_energy;
			}
			
			local DamageIconSize=32
			if (YRES(18)>50)
				DamageIconSize=64;
			
			local ResistStartX=FRAME_X+Cell*(COLS+2.5)+Cell*1.75
			local ResistStartY=FRAME_Y+FRAME_HEIGHT-Cell*2.5
			
			foreach (i,Resist in Resists)
			{
				if (!Resist) continue;
				
				//surface.DrawFilledRect(ResistStartX+(Cell+DamageIconSize/2)*(i%2)-DamageIconSize-OutlineBrdr, ResistStartY+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2+DamageIconSize*1.5*(i/2),DamageIconSize,DamageIconSize)
				surface.SetTexture(surface.ValidateTexture("vgui/damage_types",true,false,false))
				surface.SetColor(255,255,255,255)
				surface.DrawTexturedSubRect(ResistStartX+(Cell+DamageIconSize)*(i%2)-DamageIconSize-OutlineBrdr, ResistStartY+(DamageIconSize+CellBrdr*6)*(i/2)+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2,ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr, ResistStartY+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2+(DamageIconSize+CellBrdr*6)*(i/2)+DamageIconSize, ResistPos[i][0],ResistPos[i][1],ResistPos[i][0]+0.51,ResistPos[i][1]+0.51)
				
				surface.DrawColoredText(StatusFont, ResistStartX+2+(Cell+DamageIconSize)*(i%2)+Cell/12, ResistStartY+2+(DamageIconSize+CellBrdr*6)*(i/2)+DamageIconSize/2-surface.GetFontTall(StatusFont)/2, ResistColors[i].x/4,ResistColors[i].y/4,ResistColors[i].z/4,255,format("%i%%",Resist))
				surface.DrawColoredText(StatusFont, ResistStartX+(Cell+DamageIconSize)*(i%2)+Cell/12, ResistStartY+(DamageIconSize+CellBrdr*6)*(i/2)+DamageIconSize/2-surface.GetFontTall(StatusFont)/2, ResistColors[i].x,ResistColors[i].y,ResistColors[i].z,255,format("%i%%",Resist))
				
			}
			foreach (i,Resist in Resists)
			{
				if (!Resist) continue;
				
				if (CurX>(ResistStartX+(Cell+DamageIconSize)*(i%2)-DamageIconSize-OutlineBrdr)&&CurX<(ResistStartX+(Cell+DamageIconSize)*(i%2)-OutlineBrdr))
				{
					if (CurY>(ResistStartY+DamageIconSize*1.5*(i/2)+surface.GetFontTall(StatusFont)*0.5-DamageIconSize/2)&&CurY<(ResistStartY+DamageIconSize*1.5*(i/2)+surface.GetFontTall(StatusFont)*0.5+DamageIconSize/2))
					{
						surface.SetColor(0,0,0,240)
						surface.DrawFilledRect(CurX+DamageIconSize/2,CurY+DamageIconSize/2,surface.GetTextWidth(StatusFont,format("%s RESISTANCE",ResistNames[i]))+DamageIconSize,surface.GetFontTall(StatusFont)+DamageIconSize)
						surface.DrawColoredText(StatusFont, CurX+DamageIconSize+2,CurY+DamageIconSize+2, ResistColors[i].x/4,ResistColors[i].y/4,ResistColors[i].z/4,255,format("%s RESISTANCE",ResistNames[i]))
						surface.DrawColoredText(StatusFont, CurX+DamageIconSize,CurY+DamageIconSize, ResistColors[i].x,ResistColors[i].y,ResistColors[i].z,255,format("%s RESISTANCE",ResistNames[i]))
					}
				}
			}
		}
			
		if (Selection>=0&&!Drag&&INVENTORY[Selection])
		{
			if (INVENTORY[Selection].UseAction!=null&&(!ActiveContainer)) 
			{
				use_button.SetEnabled(true)
				use_button.SetAlpha(255)
				use_button.SetCallback( "DoClick", function() {INVENTORY[Selection].UseItem();Selection=-1;SelectionEquipment=false}.bindenv(this) );
			}
			else
			{
				use_button.SetEnabled(false)
				use_button.SetAlpha(ActiveContainer ? 0 : 20)
				use_button.SetCallback( "DoClick", function (_) {} );
			}
		}
		else
		{
			use_button.SetEnabled(false)
			use_button.SetAlpha(ActiveContainer ? 0 : 20)
			use_button.SetCallback( "DoClick", function (_) {} );
		}
		
		if (Selection>=0&&!Drag&&INVENTORY[Selection]&&("ammoitem" in LIST_ITEMS[INVENTORY[Selection].tech_name]))
		{
			if (INVENTORY[Selection].Durability<INVENTORY[Selection].MaxDurability&&HasItemTech("item_wep_repair_kit")) 
			{
				repair_button.SetEnabled(true)
				repair_button.SetAlpha(255)
				repair_button.SetCallback( "DoClick", function() {INVENTORY[Selection].Repair(1000);Selection=-1;SelectionEquipment=false}.bindenv(this) );
			}
			else
			{
				repair_button.SetEnabled(false)
				repair_button.SetAlpha(ActiveContainer ? 0 : 20)
				repair_button.SetCallback( "DoClick", function (_) {} );
			}
		}
		else
		{
			repair_button.SetEnabled(false)
			repair_button.SetAlpha(ActiveContainer ? 0 : 20)
			repair_button.SetCallback( "DoClick", function (_) {} );
		}
		
		if (Selection>=0&&!Drag&&INVENTORY[Selection]&&!SelectionEquipment)
		{
			if (INVENTORY[Selection].Clip&&(!ActiveContainer)&&("ammoitem" in LIST_ITEMS[INVENTORY[Selection].tech_name])) 
			{
				unload_button.SetEnabled(true)
				unload_button.SetAlpha(255)
				unload_button.SetCallback( "DoClick", function() {INVENTORY[Selection].UnloadWeapon();}.bindenv(this) );
			}
			else
			{
				unload_button.SetEnabled(false)
				unload_button.SetAlpha(ActiveContainer ? 0 : 20)
				unload_button.SetCallback( "DoClick", function (_) {} );
			}
		}
		else
		{
			unload_button.SetEnabled(false)
			unload_button.SetAlpha(ActiveContainer ? 0 : 20)
			unload_button.SetCallback( "DoClick", function (_) {} );
		}
		
				// === ЕСЛИ АКТИВНА ВКЛАДКА QUESTS — РИСУЕМ МЕНЮ КВЕСТОВ ===
		if (CURRENT_TAB == TAB_QUESTS && !ActiveContainer)
		{
			DrawQuestsMenu(Cell, CurX, CurY, TitleFont, TitleFontS, StatusFont, StatusFont4, FRAME_X, FRAME_Y, FRAME_WIDE, FRAME_HEIGHT, TitleHeight)
			InvP.SetCursor(2)
			if (use_button && use_button.IsValid()) { use_button.SetEnabled(false); use_button.SetAlpha(0) }
			if (repair_button && repair_button.IsValid()) { repair_button.SetEnabled(false); repair_button.SetAlpha(0) }
			if (unload_button && unload_button.IsValid()) { unload_button.SetEnabled(false); unload_button.SetAlpha(0) }
			ControlsHints = 0
		}
		
		else if (CURRENT_TAB == TAB_SKILLS && !ActiveContainer)
		{
			SKILLS_HandleHover(CurX, CurY, Cell, FRAME_X, FRAME_Y, FRAME_WIDE, FRAME_HEIGHT, TitleHeight)
			SKILLS_DrawMenu(Cell, CurX, CurY, TitleFont, TitleFontS, StatusFont, StatusFont4, FRAME_X, FRAME_Y, FRAME_WIDE, FRAME_HEIGHT, TitleHeight)
			InvP.SetCursor(2)
			if (use_button && use_button.IsValid()) { use_button.SetEnabled(false); use_button.SetAlpha(0) }
			if (repair_button && repair_button.IsValid()) { repair_button.SetEnabled(false); repair_button.SetAlpha(0) }
			if (unload_button && unload_button.IsValid()) { unload_button.SetEnabled(false); unload_button.SetAlpha(0) }
			ControlsHints = 0
		}
			
		og<-cx+cy
		cx=CurX
		cy=CurY
		
		surface.SetColor( 250, 250, 15, 240 );

		
		//printl(player.GetActiveWeapon().GetPrimaryAmmoType()) pistol 3

		InvThink()
		
		InvP.SetSize(ScreenWidth(),ScreenHeight());
		
		local invAlpha=clamp((Time()-OpenTime)*4,0,1)
		invAlpha=Bias(invAlpha,0.7)
		
		if (!ContainerPages) InvP.SetSize(ScreenWidth()*invAlpha,ScreenHeight()*invAlpha);
		if (!ContainerPages) InvP.SetAlpha(255*invAlpha);
		//InvP.SetPos(0,FRAME_WIDE/1.7-clamp((Time()-OpenTime+0.5/3.0)*FRAME_WIDE*3/1.7,0,FRAME_WIDE/1.7))
		
		//printl(FocusY*COLS+FocusX)
	}
	
	local PrevCont=null
	
	
	if (SERVER_DLL) local PlayerMoneyBefore=PlayerMoney
	
	::OpenInventory<-function(Container=null)
	{
		//printl("opening inventory")
		PrevCont=ActiveContainer
		ActiveContainer=Container
		
		CURRENT_TAB = TAB_INVENTORY
		
		/*	UNUSED INVENTORY SIZE CHANGE BEHAVIOR
		COLS=8+(player.GetHealth()<99).tointeger()*4
		while (INVENTORY.len()<ROWS*COLS) INVENTORY.append(null)
		FRAME_X=XRES(64)-YRES(16)*(COLS-16)
		FRAME_WIDE=XRES(512)-YRES(32)*(16-COLS)
		CELLS_X=XRES(43)-YRES(16)*(COLS-16)
		*/
		
		if (!PrevCont&&ActiveContainer) PrevCont=ActiveContainer;
		
		if (ActiveContainer&&("Pages" in CONTAINERS[ActiveContainer])) {
			ContainerPages=CONTAINERS[ActiveContainer].Pages
		}
		else if (ContainerPages==null||(!(ContainerPages.find(ActiveContainer)!=null)))
			ContainerPages=null;
		
		//if (ActiveContainer) printl("ALSO OPENING CONTAINER "+ActiveContainer)
		if (ActiveContainer!=null&&INVENTORY.len()==(COLS*ROWS)) INVENTORY.extend(CONTAINERS[ActiveContainer].INVENTORY)
			
		OpenTime=Time()
		
		
		if ( InvP && InvP.IsValid() && (ContainerPages==null||(!(ContainerPages.find(ActiveContainer)!=null))))
		{
			Drag=false
			DragEquipment=false
			DragCurX=0
			DragCurY=0
			DragSizeX=0
			DragCount=-1
			DragSizeY=0
			DragID=(-1)
			Selection=-1
			SelectionEquipment=false
			surface.PlaySound("common/menu_off.wav")
			ItemOverlap=false
			
			if (ContainerPages==null||(!(ContainerPages.find(ActiveContainer)!=null)))
			{
				InvP.Destroy()
				InvP=null
			
				if (abs(PlayerMoney-PlayerMoneyBefore)>1000) surface.PlaySound("common/cash.wav");
				else if (abs(PlayerMoney-PlayerMoneyBefore)>1) surface.PlaySound("ambient/levels/labs/coinslot1.wav")
			}
			
			if (INVENTORY.len()>(COLS*ROWS)) CONTAINERS[PrevCont].INVENTORY=INVENTORY.slice(COLS*ROWS)	//do this on close. both sides
			if (INVENTORY.len()>(COLS*ROWS)) INVENTORY=INVENTORY.slice(0,COLS*ROWS)	//do this on close. both sides
			NetMsg.Start("InventoryClose")
			NetMsg.WriteBool(true)
			NetMsg.Send()
			
			return;
		}
		
		PlayerMoneyBefore=PlayerMoney
		
		if (Container==null) surface.PlaySound("common/menu_on.wav");;

		
		function DoClose(TrueClose=true)
		{
			Drag=false
			DragCurX=0
			DragCurY=0
			DragSizeX=0
			DragCount=-1
			DragSizeY=0
			DragID=(-1)
			Selection=-1
			SelectionEquipment=false
			DragEquipment=false
			ItemOverlap=false
			CURRENT_TAB = TAB_INVENTORY
			surface.PlaySound("common/menu_off.wav")
			
			
			if (TrueClose)
			{
				if (abs(PlayerMoney-PlayerMoneyBefore)>1000) surface.PlaySound("common/cash.wav");
				else if (abs(PlayerMoney-PlayerMoneyBefore)>1) surface.PlaySound("ambient/levels/labs/coinslot1.wav")
			
				InvP.Destroy()
				InvP=null
			}
			if (INVENTORY.len()>(COLS*ROWS)) CONTAINERS[ActiveContainer].INVENTORY=INVENTORY.slice(COLS*ROWS)	//do this on close. both sides
			if (INVENTORY.len()>(COLS*ROWS)) INVENTORY=INVENTORY.slice(0,COLS*ROWS)	//do this on close. both sides
			NetMsg.Start("InventoryClose")
			NetMsg.WriteBool(TrueClose)
			NetMsg.Send()
		}
		
		function InvThink()
		{
			SyncAllWeapons()
			if (CURRENT_TAB == TAB_SKILLS && !ActiveContainer)
				SKILLS_ClientThink()
			return 0.1
		}
		
		
		function DoClick(a)
		{
						// === КЛИК ПО ВКЛАДКАМ ===
			if (!ActiveContainer && InvP && InvP.IsValid()&&a==ButtonCode.MOUSE_LEFT)
			{
				local TitleXGap = Cell*0.75+CellBrdr*2
				local TabGap = 0
				local TabNames = [Localize.GetTokenAsUTF8("UI_INVENTORY"), "Quests", "Skills"]
				local TabIDs = [TAB_INVENTORY, TAB_QUESTS, TAB_SKILLS]
				
				local titleFontS = surface.GetFont("VerySmolShadow", true)
				
				for (local i = 0; i < 3; i++)
				{
					local textW = surface.GetTextWidth(titleFontS, TabNames[i])
					local TabX = FRAME_X + TitleXGap + TabGap
					local TabY = FRAME_Y
					local TabW = 2*TitleMargin + textW
					local TabH = TitleHeight
					
					if (CurX > TabX && CurX < TabX + TabW && CurY > TabY && CurY < TabY + TabH)
					{
						SwitchTab(TabIDs[i])
						return
					}
					
					TabGap += TabW + YRES(5)
				}
			}
			
			if (!ActiveContainer && CURRENT_TAB == TAB_SKILLS)
			{
				if (SKILLS_HandleClick(a)) return
			}
			
			// === КЛИК ПО КВЕСТУ ===
			if (!ActiveContainer && InvP && InvP.IsValid() && CURRENT_TAB == TAB_QUESTS)
			{
				HandleQuestClick(CurX, CurY, Cell, FRAME_X, FRAME_Y, FRAME_WIDE, FRAME_HEIGHT, TitleHeight)
				return
			}
			
			if (a==ButtonCode.MOUSE_RIGHT&&Drag)
			{
				printl("rotate drag")
				
				DragRotated=!DragRotated;
				
				local buf=DragCurX
				
				DragCurX=DragCurY
				DragCurY=buf
				
				buf=DragSizeX
				
				DragSizeX=DragSizeY
				DragSizeY=buf
				
				surface.PlaySound("common/menu1.wav")
				return;
			}
			
			Selection=(-1)
			SelectionEquipment=false
			local i=FocusY*COLS+FocusX
			//printl(i)
			
			
			if (ContainerFocus) i=(ROWS*COLS)+FocusY*CONTAINERS[ActiveContainer].COLS+FocusX
			if (FocusX<0) i=-1;
			if ((i>INVENTORY.len()-1||i<0)&&EqFocus()==false) return
			if (EqFocus()==false&&INVENTORY[i]!=null) 
			{
				if ((typeof INVENTORY[i])=="integer") i=INVENTORY[i];
				if (a==ButtonCode.MOUSE_RIGHT) {
					if (INVENTORY[i].Rotate()) 
					{
						surface.PlaySound("common/menu1.wav");
						NetMsg.Start("InventoryRotate")
						NetMsg.WriteShort(i)
						NetMsg.Send()
					}
					return
				}
				
				local Cols=COLS
				if (ContainerFocus) Cols=CONTAINERS[ActiveContainer].COLS
				
				//printl("pressed on "+INVENTORY[i].Name+" "+INVENTORY[i].SizeX*INVENTORY[i].SizeY)
				surface.PlaySound("common/select.wav")
				LastPress=Time()
				Selection=i
				
				NetMsg.Start("RT_ChangeModel")
				NetMsg.WriteString(INVENTORY[i].tech_name)
				NetMsg.WriteString(LIST_ITEMS[INVENTORY[i].tech_name].model)
				NetMsg.Send()
				
				Drag=true
				DragRotated=false;
				
				if (input.IsButtonDown(ButtonCode.KEY_LCONTROL)) DragCount=clamp(INVENTORY[i].Count/2,1,INVENTORY[i].Count);
				else DragCount=INVENTORY[i].Count;
				
				DragID=i
				DragCurX=CurX-GetCellX((i-(ROWS*COLS)*ContainerFocus.tointeger())%Cols,ContainerFocus)
				DragCurY=CurY-GetCellY((i-(ROWS*COLS)*ContainerFocus.tointeger())/Cols,ContainerFocus)+YRES(2)
				DragSizeX=INVENTORY[i].SizeX
				DragSizeY=INVENTORY[i].SizeY
				
			}
			if (EqFocus()!=false&&EQUIPMENT[EqFocus()]!=null) 
			{
				i=EqFocus()
				
				local Cols=COLS
				if (ContainerFocus) Cols=CONTAINERS[ActiveContainer].COLS
				
				printl("pressed on "+EQUIPMENT[i].Name)
				surface.PlaySound("common/select.wav")
				LastPress=Time()
				Selection=i
				SelectionEquipment=true
				NetMsg.Start("RT_ChangeModel")
				NetMsg.WriteString(EQUIPMENT[i].tech_name)
				NetMsg.WriteString(LIST_ITEMS[EQUIPMENT[i].tech_name].model)
				NetMsg.Send()
				
				Drag=true
				DragRotated=false
				DragEquipment=true
				
				DragCount=1
				
				DragID=i
				DragCurX=CurX-EQUIPMENT_POS[i].x
				DragCurY=CurY-EQUIPMENT_POS[i].y+YRES(2)
				DragSizeX=EQUIPMENT[i].SizeX
				DragSizeY=EQUIPMENT[i].SizeY
				
			}
			return
		}
		
		function DoRelease(a)
		{
			if (a==ButtonCode.MOUSE_RIGHT) return;
			
			if (!ActiveContainer && CURRENT_TAB == TAB_SKILLS)
			{
				if (SKILLS_HandleRelease(a)) return
			}
			
			
			
			if (CURRENT_TAB != TAB_INVENTORY) return;

			ItemOverlap=false;
			local DragOffsetX=DragCurX/Cell
			local DragOffsetY=DragCurY/Cell
			local i=(FocusY-DragOffsetY)*COLS+(FocusX-DragOffsetX)
			i=i.tointeger()
			
			local ToEquipment=false
			
			if (EqFocus()!=false) 
			{
				i=EqFocus()
				ToEquipment=true
			}
			
			if (ContainerFocus) i=(FocusY-DragOffsetY)*CONTAINERS[ActiveContainer].COLS+(FocusX-DragOffsetX);
			
			i=clamp(i,-1,INVENTORY.len()-1)
			
			//printl(i)
			
			local DragSuccess=false
			
			
			if ((!ContainerFocus)&&((i%COLS)>(COLS-DragSizeX))) i=DragID // do for both
			if ((!ContainerFocus)&&((i/COLS)>(ROWS-DragSizeY))) i=DragID
			
			if (ContainerFocus) 
			{
				if (((i-(ROWS*COLS))%CONTAINERS[ActiveContainer].COLS)>(CONTAINERS[ActiveContainer].COLS-DragSizeX)) i=DragID-(ROWS*COLS)
				if (((i-(ROWS*COLS))/CONTAINERS[ActiveContainer].COLS)>(CONTAINERS[ActiveContainer].ROWS-DragSizeY)) i=DragID-(ROWS*COLS)
			}
			

			//	ITEM DROP
			if (Drag&&(!DragEquipment)&&DragID!=(-1)&&INVENTORY[DragID]) if ((CurX>FRAME_X+FRAME_WIDE+YRES(16))||(CurX<FRAME_X-YRES(16))||(CurY>FRAME_Y+FRAME_HEIGHT+YRES(10))||(CurY<FRAME_Y))
			{
				if ((ActiveContainer==null)||((CurX>C_FRAME_X+C_FRAME_WIDE+YRES(16))||(CurX<C_FRAME_X-YRES(16))||(CurY>C_FRAME_Y+C_FRAME_HEIGHT+YRES(10))||(CurY<C_FRAME_Y)))
				{
					if (!(ActiveContainer && CONTAINERS[ActiveContainer].Shop)) 
					{
						printl("Dropped item "+DragID)
						
						surface.PlaySound("weapons/slam/throw.wav")
						
						Drag=false
						ItemOverlap=false
						DragEquipment=false
						DragRotated=false
						
						local AvgPrevCurX=(PrevCurX[0]+PrevCurX[1]+PrevCurX[2])/3.0
						local AvgPrevCurY=(PrevCurY[0]+PrevCurY[1]+PrevCurY[2])/3.0
						
						local curvel=sqrt((AvgPrevCurX-CurX)*(AvgPrevCurX-CurX)+(AvgPrevCurY-CurY)*(AvgPrevCurY-CurY))*1080.0/(ScreenHeight()*1.0)/FrameTime()/150
						
						printl("Velocity "+curvel)
						INVENTORY[DragID].SpawnDropped(curvel,DragCount)
						//RemoveItem(INVENTORY[DragID].tech_name,INVENTORY[DragID].Count,DragID);
						
						Selection=-1
						SelectionEquipment=false
						DragCurX=0
						DragCurY=0
						DragSizeX=0
						DragSizeY=0
						DragCount=-1
						DragID=(-1)
						Dropping=false
					}
					//return
				}
			}
				
			if (ContainerFocus) i+=(ROWS*COLS)
			if (ContainerFocus) i=i.tointeger()
			
			//printl(i)
			
			// ITEM MOVE
			if ((i!=(-1)||DragEquipment)||(EqFocus()!=false)) if (Drag&&DragID!=(-1)&&(INVENTORY[DragID]||EQUIPMENT[DragID]&&DragEquipment))
			{
				local IsFree=CanFit(DragSizeX,DragSizeY,i)
				
				if (DragRotated&&i==DragID) IsFree=true;
				
				local movingitem=DragEquipment ? EQUIPMENT[DragID] : INVENTORY[DragID]
				
				//printl("trying move!")
				
				local IsTrader=(ActiveContainer && CONTAINERS[ActiveContainer].Shop)
				local WithinTrader=(IsTrader&&(i>=(ROWS*COLS)&&DragID>=(ROWS*COLS)))
				local ToTrader=(IsTrader&&(i>=(ROWS*COLS)&&DragID<(ROWS*COLS)))
				local FromTrader=(IsTrader&&(i<(ROWS*COLS)&&DragID>=(ROWS*COLS)))
				local TraderGoods=(FromTrader&&Trader.INVENTORY[DragID-(ROWS*COLS)]==INVENTORY[DragID])||(FromTrader&&Trader2.INVENTORY[DragID-(ROWS*COLS)]==INVENTORY[DragID])
				local AllowDrag=true
				

				
				if (IsFree==true&&(!WithinTrader)||EqFocus()!=false)
				{
					local Cols=COLS
					if (DragID>=(ROWS*COLS)) Cols=CONTAINERS[ActiveContainer].COLS 
					
					
					

						
					if (DragCount==(-1)) DragCount=DragEquipment ? 1 : INVENTORY[DragID].Count
					
					local MaxDragCount=DragEquipment ? 1 : INVENTORY[DragID].Count
					if (!DragEquipment&&"Count" in INVENTORY[i]) MaxDragCount=clamp(MaxDragCount,0,INVENTORY[i].MaxStack-INVENTORY[i].Count)
					
					
					DragCount=clamp(DragCount,0,MaxDragCount)
					
					if (FromTrader&&PlayerMoney>=(INVENTORY[DragID].Cost*DragCount))
					{
						AddPlayerMoney(-GetItemCost(INVENTORY[DragID],false,DragCount))
					}
					else {if (FromTrader&&PlayerMoney<(INVENTORY[DragID].Cost*DragCount)) AllowDrag=false;}
					
					if (ToTrader) AddPlayerMoney(GetItemCost(INVENTORY[DragID],true,DragCount));
					
					if (DragCount==0) AllowDrag=false;
					
					if (DragCount==0&&DragRotated) 
					{
						if (INVENTORY[DragID].Rotate()) 
						{
							surface.PlaySound("common/menu1.wav");
							NetMsg.Start("InventoryRotate")
							NetMsg.WriteShort(DragID)
							NetMsg.Send()
						}
					}
					
					
					if (EqFocus()!=false&&EQUIPMENT[EqFocus()]!=null) AllowDrag=false;

					if (ToEquipment&&((!("armorslot" in movingitem))||(movingitem.armorslot!=EqFocus()))) AllowDrag=false;
					
					
		
				
					
					if (AllowDrag||(ToEquipment&&EQUIPMENT[EqFocus()]==null&&("armorslot" in movingitem)&&movingitem.armorslot==EqFocus()))
					{
						//printl(i)
						//printl(typeof i)
						
						if (!DragEquipment&&!DragExtra&&(!TraderGoods)&&DragCount==INVENTORY[DragID].Count&&!DragRotated) for (local j=1;j<(DragSizeX*DragSizeY);j++) INVENTORY[DragID+(j%DragSizeX)+(j/DragSizeX)*Cols]=null;
						if (!DragEquipment&&!DragExtra&&(!TraderGoods)&&DragCount==INVENTORY[DragID].Count&&DragRotated) for (local j=1;j<(DragSizeX*DragSizeY);j++) INVENTORY[DragID+(j%DragSizeY)+(j/DragSizeY)*Cols]=null;
						//printl(ToEquipment)
						if (!ToEquipment)
						{
							//moving to inventory
							if (!DragEquipment)
							{
							
								local a=clone INVENTORY[DragID]
								if (DragRotated) 
								{
									local buf=a.SizeX
									a.SizeX=a.SizeY
									a.SizeY=buf
									a.Rotated=!a.Rotated;
								}
								a.Count=DragCount
								if (INVENTORY[i]==null) INVENTORY[i]=a
								else INVENTORY[i].Count+=DragCount
								a=null
								
								if (!DragExtra&&(!TraderGoods)&&DragCount<INVENTORY[DragID].Count) INVENTORY[DragID].Count-=DragCount;
								else if (!TraderGoods&&DragCount==INVENTORY[DragID].Count) INVENTORY[DragID]=null;
								
							}
							else
							{
								local a=clone EQUIPMENT[DragID]
								INVENTORY[i]=a

								EQUIPMENT[DragID]=null;
								a=null
								//printl(DragSizeX*DragSizeY)
							}

							if (i>=(ROWS*COLS)) Cols=CONTAINERS[ActiveContainer].COLS; 
							else Cols=COLS;
							
							for (local j=1;j<(DragSizeX*DragSizeY);j++) INVENTORY[i+(j%DragSizeX)+(j/DragSizeX)*Cols]=i;

							if (DragID!=i) surface.PlaySound("common/deselect.wav")
							//player.GetActiveWeapon().EmitSound(INVENTORY[i].Sound)
						}
						else
						{
							//moving to equipment
							
							//for (local j=1;j<(DragSizeX*DragSizeY);j++) INVENTORY[DragID+(j%DragSizeX)+(j/DragSizeX)*Cols]=null;
							
							if (!DragEquipment)
							{
								if (INVENTORY[DragID].Rotated) INVENTORY[DragID].Rotate();
								
								EQUIPMENT[EqFocus()]=INVENTORY[DragID]
								INVENTORY[DragID]=null
								for (local j=1;j<(DragSizeX*DragSizeY);j++) INVENTORY[DragID+(j%DragSizeX)+(j/DragSizeX)*Cols]=null;
							}
							else
							{
								EQUIPMENT[EqFocus()]=EQUIPMENT[DragID]
								EQUIPMENT[DragID]=null
							}
							surface.PlaySound("items/armor_pickup_01.wav")
							//printl("EQUIPMENT ADDED!")
						}
						DragSuccess=true
						if (DragID!=i) Selection=-1;
					}
				}
			}
			if (Drag&&!DragSuccess&&DragID!=i) surface.PlaySound("common/menu3.wav");
			Drag=false
			ItemOverlap=false
			
			
			DragCurX=0
			DragCurY=0
			DragSizeX=0
			DragSizeY=0
			
			
			if (DragSuccess&&(!ToEquipment)&&!DragEquipment)
			{
				local Amount=SW_PlayerHasItemCount(INVENTORY[i].Name)
				local ItemEntry=LIST_ITEMS[INVENTORY[i].tech_name]
				if ("weapon" in ItemEntry)
				{
					if (i<(ROWS*COLS)&&DragID>=(ROWS*COLS)) // weapon from storage
					{	
						INVENTORY[i].InitWeapon()
						
					}
					if (i>=(ROWS*COLS)&&DragID<(ROWS*COLS)&&(!INVENTORY[i].SingleUse||INVENTORY[i].SingleUse&&Amount<=0)) // weapon to storage
					{
						local APlayer=Entities.FindByClassname(null,"weapon_custom_scripted1").GetOrCreatePrivateScriptScope().aPlayer
						local Weps=APlayer.Weapons
						local HasWeapon=("Weapon" in APlayer)
						
						if (INVENTORY[i].WeaponSlot!=null)
						{
							WEAPON_SLOTS[INVENTORY[i].WeaponSlot]=null
							INVENTORY[i].WeaponSlot=null
						}
						
						Weps[INVENTORY[i].WeaponInvID]=null
		

						if (HasWeapon&&APlayer.ActiveWeaponSlot==INVENTORY[i].WeaponInvID) {
							APlayer.rawdelete("Weapon");
							if (CLIENT_DLL) SW_HUDPlayerWeapon="";
							APlayer.Weapons[APlayer.ActiveWeaponSlot]=null
							APlayer.ActiveWeaponSlot=(-1)
							printl("removing current weapon!")
							if (SERVER_DLL) player.GetViewModel(0).SetModel("models/blackout.mdl");
						}
						if (aPlayer.DualWield[0]!=null&&aPlayer.DualWield[1]!=null&&aPlayer.DualWield.find(INVENTORY[i].WeaponInvID)!=null)
						{
							APlayer.rawdelete("Weapon");
							if (CLIENT_DLL) SW_HUDPlayerWeapon="";
							APlayer.Weapons[APlayer.ActiveWeaponSlot]=null
							APlayer.ActiveWeaponSlot=(-1)
							printl("removing current weapon!")
							if (SERVER_DLL) player.GetViewModel(0).SetModel("models/blackout.mdl");		
						}
						
					}
				}
				/*
				if (i<ROWS*COLS&&QUICK_USE_SLOTS.find(DragID)!=null)
				{
					QUICK_USE_SLOTS[QUICK_USE_SLOTS.find(DragID)]=i
				}
				if (i>=ROWS*COLS&&QUICK_USE_SLOTS.find(DragID)!=null)
				{
					INVENTORY[i].QuickUseSlot=null
					QUICK_USE_SLOTS[QUICK_USE_SLOTS.find(DragID)]=null
				}
				*/
				NetMsg.Start("InventoryMove")
				NetMsg.WriteShort(DragID)
				NetMsg.WriteBool(DragRotated)
				NetMsg.WriteShort(i)
				NetMsg.WriteShort(DragCount)
				NetMsg.Send()
			}
			if (DragSuccess&&(ToEquipment)&&(!DragEquipment))
			{
				NetMsg.Start("InventoryEquip")
				NetMsg.WriteShort(DragID)
				NetMsg.WriteShort(i)
				NetMsg.Send()
			}
			if (DragSuccess&&(ToEquipment)&&(DragEquipment))
			{
				NetMsg.Start("InventoryMoveEquip")
				NetMsg.WriteShort(DragID)
				NetMsg.WriteShort(i)
				NetMsg.Send()
			}
			if (DragSuccess&&DragEquipment&&(!ToEquipment))
			{
				NetMsg.Start("InventoryUnEquip")
				NetMsg.WriteShort(DragID)
				NetMsg.WriteShort(i)
				NetMsg.Send()
			}
			DragEquipment=false
			DragID=(-1)
			DragRotated=false
			DragCount=-1
			return
		}
		
		function DoScroll(a)
		{
			if (Drag&&!DragEquipment)
			{
				local LastCount=DragCount
				if (DragCount==(-1)) 
				{
					DragCount=INVENTORY[DragID].Count;
				}
				if (a==1) DragCount++;
				if (a==-1) DragCount--;
				
				if (DragCount<1) DragCount=INVENTORY[DragID].Count;
				if (DragCount>INVENTORY[DragID].Count) DragCount=1
				
				if (DragCount!=LastCount) surface.PlaySound("common/menu1.wav");
				
			}
		}
		
		function DoKeyPress(a)
		{
			// Q и E — переключение вкладок влево/вправо (если не активен drag)
			if (!Drag && InvP && InvP.IsValid())
			{
				if (a == ButtonCode.KEY_Q)
				{
					local prevTab = CURRENT_TAB - 1
					if (prevTab < 0) prevTab = 2
					SwitchTab(prevTab)
					return
				}
				if (a == ButtonCode.KEY_E && CURRENT_TAB != TAB_INVENTORY)
				{
					local nextTab = (CURRENT_TAB + 1) % 3
					SwitchTab(nextTab)
					return
				}
			}
			
			switch(a)
			{
				case input.StringToButtonCode(input.LookupBinding("inventory")):OpenInventory();return;
				case input.StringToButtonCode(input.LookupBinding("+use")):if (ActiveContainer) {OpenInventory();return};
			}
			
			local LastCount=DragCount
			if (a<=10&&Drag)
			{
				if (DragCount==INVENTORY[DragID].Count&&a>1)	// if dragcount is max and we press any num key except for 0.
					DragCount=a-1;
				else
				{
					DragCount=clamp((DragCount.tostring()+(a-1).tostring()).tointeger(),1,INVENTORY[DragID].Count)
				}
			}
			//printl(INVENTORY[FocusX+FocusY*COLS])
			if (FocusX+FocusY*COLS>=0&&a<=7&&(!Drag)&&input.IsButtonDown(ButtonCode.KEY_LALT)&&INVENTORY[FocusX+FocusY*COLS]!=null)
			{
				local wep=INVENTORY[FocusX+FocusY*COLS]

				if ((typeof INVENTORY[FocusX+FocusY*COLS])=="integer") wep=INVENTORY[wep]
				
				local AllowAssign=true
				if (!("weapon" in LIST_ITEMS[wep.tech_name])) AllowAssign=false;
				
				if (AllowAssign)
				{
					if (a==1||(a-2)==wep.WeaponSlot)
					{
						wep.ChangeWeaponSlot(null);
					}
					else
					{
						foreach(item in INVENTORY)
						{
							if (item&&wep!=item&&(typeof item)!="integer"&&item.WeaponSlot==(a-2)) {item.ChangeWeaponSlot(null);break}
						}
						
						wep.ChangeWeaponSlot(a-2);
					}
				}
			}
			
			/*
			if (FocusX+FocusY*COLS>=0&&a<=5&&(!Drag)&&input.IsButtonDown(ButtonCode.KEY_LALT)&&INVENTORY[FocusX+FocusY*COLS]!=null)
			{
				local item=INVENTORY[FocusX+FocusY*COLS]

				if ((typeof item)=="integer") item=INVENTORY[item]
				
				local AllowAssign=true
				if (!("Use" in LIST_ITEMS[item.tech_name])) AllowAssign=false;
				
				if (AllowAssign)
				{
					if (a==1||(a-2)==item.QuickUseSlot)
					{
						item.ChangeQuickUseSlot(null);
					}
					else
					{
						foreach(obj in INVENTORY)
						{
							if (obj&&item!=obj&&(typeof obj)!="integer"&&obj.QuickUseSlot==(a-2)) {obj.ChangeQuickUseSlot(null);break}
						}
						
						item.ChangeQuickUseSlot(a-2);
					}
				}
			}
			*/
			if (!Drag&&Selection>=0)
			{
				local item=INVENTORY[Selection]

				if ((typeof item)=="integer") item=INVENTORY[item]
				
				
				local AllowUse=true
				if (!item||(!("Use" in LIST_ITEMS[item.tech_name]))) AllowUse=false;
				
				if (AllowUse)
				{
					if (a==ButtonCode.KEY_E)
					{
						Selection=-1;
						SelectionEquipment=false
						surface.PlaySound("ui/buttonrollover.wav")
						item.UseItem()
					}
				}
				
				if (unload_button.IsEnabled())
				{
					if (a==ButtonCode.KEY_U)
					{
						item.UnloadWeapon()
					}
				}
			}
			
			if (DragCount!=LastCount) surface.PlaySound("common/menu1.wav");
		}
		
		function Cursor(x,y)
		{	
			PrevCurX.append(CurX)
			PrevCurY.append(CurY)
			PrevCurX.remove(0)
			PrevCurY.remove(0)
			CurX=x
			CurY=y
			//Selected=null
		}
		
		local resX=ScreenWidth()
		
		printl("opening inventory")
		
		local InvRecreated=false
		
		if (!InvP||(!InvP.IsValid()))
		{
			InvP = vgui.CreatePanel("Panel", vgui.GetClientDLLRootPanel(), "InventoryScreen")
			InvP.MakeReadyForUse()
			InvP.SetVisible(true)
			InvP.SetPos(XRES(0), YRES(0))
			InvP.SetSize(XRES(640),YRES(480))
			InvP.SetPaintEnabled(true)
			InvP.SetFgColor( 0, 0, 0, 0 )
			InvP.SetBgColor( 0, 0, 0, 0 )
			InvP.SetCursor(2)
			InvP.SetZPos(222)
			InvP.MakePopup()
			InvRecreated=true
		}
		InvP.SetKeyBoardInputEnabled(true)
		InvP.SetCallback( "OnKeyCodePressed", DoKeyPress.bindenv(this) );
		InvP.SetCallback( "OnMousePressed", DoClick.bindenv(this) );
		InvP.SetCallback( "OnMouseReleased", DoRelease.bindenv(this) );
		//InvP.SetCallback( "OnKeyCodeReleased", DoClick.bindenv(this) );
		//InvP.SetCallback( "OnKeyCodeReleased", DoRelease.bindenv(this) );
		InvP.SetCallback( "OnCursorMoved", Cursor.bindenv(this) );
		InvP.SetCallback( "OnMouseWheeled", DoScroll.bindenv(this) );
		
		
		
		local close_button = null
		if (InvRecreated) 
		{
			close_button = vgui.CreatePanel( "Button", InvP, "CloseButton" );
			close_button.SetBgColor( 200, 20, 20, 255 );
			close_button.SetPaintEnabled( true );
			close_button.SetPaintBorderEnabled( false );
			close_button.SetVisible(true);
			close_button.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
			close_button.SetPos( FRAME_X+FRAME_WIDE-YRES(16)+YRES(2), FRAME_Y-YRES(16)-YRES(2)+YRES(16) );
			close_button.SetSize(YRES(16), YRES(16) );
			close_button.SetCallback( "DoClick", DoClose.bindenv(this) );
			close_button.SetText( "r" );
			close_button.SetContentAlignment( Alignment.center );
		}
		
		
		if (next_button&&next_button.IsValid())
		{
			next_button.Destroy()
			next_button = null
		}
		if (prev_button&&prev_button.IsValid())
		{
			prev_button.Destroy()
			prev_button = null
		}
		
		if (ContainerPages)
		{
		
			if ((ContainerPages.len()-1)>ContainerPages.find(ActiveContainer))
			{
				next_button = vgui.CreatePanel( "Button", InvP, "NextButton" );
				next_button.SetBgColor( 200, 20, 20, 255 );
				next_button.SetPaintBackgroundEnabled( true );
				next_button.SetPaintBorderEnabled( true );
				next_button.SetVisible(true);
				next_button.SetFont( surface.GetFont( "PCasd", true ) );
				next_button.SetPos( C_FRAME_X+C_FRAME_WIDE+YRES(2), C_FRAME_Y+C_FRAME_HEIGHT-YRES(16)-YRES(2) );
				next_button.SetSize(YRES(40), YRES(16) );
				next_button.SetCallback( "DoClick", function(){
					local i=ContainerPages.find(ActiveContainer)+1
				
					if (i==ContainerPages.len())
						i=0;
						
					DoClose(false)
					NetMsg.Start("ContainerOpen")
					NetMsg.WriteString(ContainerPages[i])
					NetMsg.Send()
					InvP.SetSize(ScreenWidth(),ScreenHeight());
				}.bindenv(this) );
				
				next_button.SetCallback( "PaintBackground", function(){
				local distmod=1-clamp(Vector(abs(CurX-(next_button.GetXPos()+YRES(20))),abs(CurY-(next_button.GetYPos()+YRES(8)))).Length(),0,YRES(120)).tofloat()/YRES(120)
					surface.SetColor( 0, 18*distmod, 30*distmod, 255 );
					surface.DrawFilledRect(0,0,YRES(40), YRES(16))
					surface.SetColor( 0, 18*4, 30*4, 255 );
					surface.DrawFilledRectFade(YRES(30),0,YRES(10), YRES(16),0,155*distmod,true)
				}.bindenv(this) );
				
				next_button.SetText( "NEXT PAGE >" );
				next_button.SetContentAlignment( Alignment.center );
			
			}
			
			/////////////////////////////////////////////////
			
			if (ContainerPages.find(ActiveContainer)>0)
			{
				
				prev_button = vgui.CreatePanel( "Button", InvP, "PrevButton" );
				prev_button.SetBgColor( 200, 20, 20, 255 );
				prev_button.SetPaintBackgroundEnabled( true );
				prev_button.SetPaintBorderEnabled( true );
				prev_button.SetVisible(true);
				prev_button.SetFont( surface.GetFont( "PCasd", true ) );
				prev_button.SetPos( C_FRAME_X-YRES(40)-YRES(2), C_FRAME_Y+C_FRAME_HEIGHT-YRES(16)-YRES(2) );
				prev_button.SetSize(YRES(40), YRES(16) );
				prev_button.SetCallback( "DoClick", function(){
					local i=ContainerPages.find(ActiveContainer)-1
				
					if (i<0)
						i=ContainerPages.len()-1;
						
					DoClose(false)
					NetMsg.Start("ContainerOpen")
					NetMsg.WriteString(ContainerPages[i])
					NetMsg.Send()
					InvP.SetSize(ScreenWidth(),ScreenHeight());
				}.bindenv(this) );
				
				prev_button.SetCallback( "PaintBackground", function(){
				
					local distmod=1-clamp(Vector(abs(CurX-(prev_button.GetXPos()+YRES(20))),abs(CurY-(prev_button.GetYPos()+YRES(8)))).Length(),0,YRES(120)).tofloat()/YRES(120)
					surface.SetColor( 0, 18*distmod, 30*distmod, 255 );
					surface.DrawFilledRect(0,0,YRES(40), YRES(16))
					surface.SetColor( 0, 18*4, 30*4, 255 );
					surface.DrawFilledRectFade(0,0,YRES(10), YRES(16),155*distmod,0,true)
				}.bindenv(this) );
				
				prev_button.SetText( "< PREV PAGE" );
				prev_button.SetContentAlignment( Alignment.center );
			
			}
		}
		
		local ButtonsX=YRES(32)
		local ButtonsY=(-Cell)-YRES(4)

		if (InvRecreated) use_button = vgui.CreatePanel( "Button", InvP, "UseButton" );
		use_button.MakeReadyForUse();
		use_button.SetPaintEnabled( true );
		use_button.SetPaintBackgroundEnabled( true );
		use_button.SetPaintBackgroundType( 1 );
		use_button.SetPaintBorderEnabled( true );
		use_button.SetPos( INFO_X+INFO_WIDE+ButtonsX, INFO_Y+INFO_HEIGHT+ButtonsY  );
		use_button.SetBgColor( 220,3,6,255 );
		use_button.SetDepressedSound("ui/buttonrollover.wav");
		use_button.SetSize( YRES(32), YRES(10));
		use_button.SetText("Use (E)")
		use_button.SetMouseInputEnabled(true);
		
		if (InvRecreated) repair_button = vgui.CreatePanel( "Button", InvP, "UseButton" );
		repair_button.MakeReadyForUse();
		repair_button.SetPaintEnabled( true );
		repair_button.SetPaintBackgroundEnabled( true );
		repair_button.SetPaintBackgroundType( 1 );
		repair_button.SetPaintBorderEnabled( true );
		repair_button.SetPos( INFO_X+INFO_WIDE+ButtonsX+YRES(80), INFO_Y+INFO_HEIGHT+ButtonsY  );
		repair_button.SetBgColor( 220,3,6,255 );
		repair_button.SetDepressedSound("ui/buttonrollover.wav");
		repair_button.SetSize( YRES(32), YRES(10));
		repair_button.SetText("Repair")
		repair_button.SetMouseInputEnabled(true);
		
		if (InvRecreated) unload_button = vgui.CreatePanel( "Button", InvP, "UnloadButton" );
		unload_button.MakeReadyForUse();
		unload_button.SetPaintEnabled( true );
		unload_button.SetPaintBackgroundEnabled( true );
		unload_button.SetPaintBackgroundType( 1 );
		unload_button.SetPaintBorderEnabled( true );
		unload_button.SetPos( INFO_X+INFO_WIDE+ButtonsX+YRES(40), INFO_Y+INFO_HEIGHT+ButtonsY  );
		unload_button.SetBgColor( 220,3,6,255 );
		unload_button.SetDepressedSound("ui/buttonrollover.wav");
		unload_button.SetSize( YRES(32), YRES(10));
		unload_button.SetText("Unload (U)")
		unload_button.SetMouseInputEnabled(true);
		
		InvP.SetCallback("PerformLayout", function() {
			
			// Outlining (or rather Inlining for what it actually is) is basically YRES(4)
			
			Cell=YRES(30)
			
			FRAME_WIDE=Cell*(COLS)+Cell*7
			FRAME_X=ScreenWidth()/2-FRAME_WIDE/2
			FRAME_Y=YRES(90)//-YRES(150)
			FRAME_HEIGHT=Cell*6+(Cell*12*0.3762)+Cell*2
			
			CELLS_X=FRAME_X-YRES(6)
			CELLS_Y=FRAME_Y+Cell+YRES(3)+Cell*0.5//+YRES(150)
			
			
			if (ActiveContainer) 
			{
			
				C_FRAME_WIDE=Cell*CONTAINERS[ActiveContainer].COLS+Cell;
				C_FRAME_X=ScreenWidth()/2-C_FRAME_WIDE/2
				C_FRAME_Y=Cell*0.5
				C_FRAME_HEIGHT=Cell*(CONTAINERS[ActiveContainer].ROWS)+Cell*1.5
				
				C_CELLS_X=C_FRAME_X-Cell/2
				C_CELLS_Y=C_FRAME_Y
				
				FRAME_HEIGHT=Cell*6+Cell*1.5
				FRAME_Y=YRES(250)
				
				CELLS_Y=FRAME_Y
				CELLS_X=FRAME_X-Cell*0.5
				
				INFO_Y=CELLS_Y
				INFO_X=CELLS_X+Cell*COLS+Cell
				INFO_WIDE=FRAME_WIDE-Cell*12
				INFO_HEIGHT=Cell*ROWS
			}
			else
			{
				FRAME_Y=YRES(90)
				FRAME_HEIGHT=Cell*6+(Cell*12*0.3762)+Cell*1.5
				CELLS_Y=FRAME_Y-Cell*2+INFO_HEIGHT+Cell*0.5
				CELLS_X=FRAME_X-Cell*0.5
				
				INFO_Y=FRAME_Y+Cell*0.5+Cell*0.5
				INFO_X=FRAME_X+Cell*0.5
				INFO_WIDE=Cell*COLS
				INFO_HEIGHT=INFO_WIDE/2
			}
			
			close_button.SetPos( FRAME_X+FRAME_WIDE-YRES(16)+YRES(2), FRAME_Y-YRES(2)+CellBrdr*2 );
			close_button.SetSize(YRES(16), YRES(16) );
			
			local DESC_WIDE=ActiveContainer ? Cell*3.5 : Cell*5
			local DESC_X=INFO_X-YRES(2)
			local DescPadding=ActiveContainer ? YRES(32) : YRES(24)
			local TextPadding=YRES(4)
			
			use_button.SetPos( INFO_X+DescPadding/2+YRES(2)+ButtonsX, INFO_Y+INFO_HEIGHT-DescPadding+ButtonsY+YRES(2)  );
			use_button.SetSize( YRES(32), YRES(10));
			
			repair_button.SetPos( INFO_X+DescPadding/2+YRES(2)+ButtonsX+YRES(80), INFO_Y+INFO_HEIGHT-DescPadding+ButtonsY+YRES(2)  );
			repair_button.SetSize( YRES(32), YRES(10));
			
			unload_button.SetPos( INFO_X+DescPadding/2+YRES(2)+ButtonsX+YRES(40), INFO_Y+INFO_HEIGHT-DescPadding+ButtonsY+YRES(2)  );
			unload_button.SetSize( YRES(32), YRES(10));
			
			if (next_button&&next_button.IsValid())
				next_button.SetPos( C_FRAME_X+C_FRAME_WIDE+YRES(4), C_FRAME_Y+C_FRAME_HEIGHT-YRES(16)-YRES(2) );
			if (prev_button&&prev_button.IsValid())
				prev_button.SetPos( C_FRAME_X-YRES(40)-YRES(4), C_FRAME_Y+C_FRAME_HEIGHT-YRES(16)-YRES(2) );
			
		}.bindenv(this));
		
		//InvP.SetPaintBackgroundEnabled(true)
		//InvP.SetPaintBackgroundType(2)
		InvP.SetCallback( "Paint", InvDraw.bindenv(this) )
		if (!ContainerPages) InvP.SetSize(1,1);
	}.bindenv(this)
	
	NetMsg.Receive("OpenInventory", function() {
		SyncAllWeapons()
		OpenInventory()
	}.bindenv(this))
	
	NetMsg.Receive("OpenContainer", function() {
		SyncAllWeapons()
		OpenInventory(NetMsg.ReadString())
	}.bindenv(this))
	
	function HasSpace(x,y,i=0)
	{
		local cells=0
		for (i=0;i<INVENTORY.len();i++)
		{
			if ((i%COLS)>(COLS-x)) continue
			if ((i/COLS)>(ROWS-y)) continue
			
			if (INVENTORY[i]==null)
			{
				cells=1
				for (local j=1;j<(x*y);j++) if (INVENTORY[i+(j%x)+(j/x)*COLS]==null) cells++;
			}
			if (cells==(x*y)) return i
		}
		return false
	}
	
	function HasSpaceCont(container,x,y,i=0)
	{
		local cells=0
		for (i=0;i<container.INVENTORY.len();i++)
		{
			if ((i%container.COLS)>(container.COLS-x)) continue
			if ((i/container.COLS)>(container.ROWS-y)) continue
			
			if (container.INVENTORY[i]==null)
			{
				cells=1
				for (local j=1;j<(x*y);j++) if (container.INVENTORY[i+(j%x)+(j/x)*container.COLS]==null) cells++;
			}
			if (cells==(x*y)) return i
		}
		return false
	}
	
	function CanFit(x,y,i)
	{
		//printl(DragCurX)
		local movingItem=DragEquipment ? EQUIPMENT[DragID] : INVENTORY[DragID]
		if (EqFocus()!=false&&(EQUIPMENT[EqFocus()]!=null||movingItem.armorslot!=EqFocus())) ItemOverlap=true;
		if (EqFocus()!=false) return (EQUIPMENT[EqFocus()]==null);
		ItemOverlap=false;
		local cells=0
		local DetectedIDs=[]
		
		//printl(i)
		
		local Cols=COLS
		local Rows=ROWS
		
		local InContainer=false
		
		if (i>=(ROWS*COLS)&&!DragEquipment)
		{
			Cols=CONTAINERS[ActiveContainer].COLS
			Rows=CONTAINERS[ActiveContainer].ROWS
			InContainer=true
		}
		
		if ((CurX>FRAME_X+FRAME_WIDE+YRES(16))||(CurX<FRAME_X-YRES(16))||(CurY>FRAME_Y+FRAME_HEIGHT+YRES(10))||(CurY<FRAME_Y)) //	CALCULATE FOR BOTH or just inventory when no container
		{
			if ((ActiveContainer==null)||((CurX>C_FRAME_X+C_FRAME_WIDE+YRES(16))||(CurX<C_FRAME_X-YRES(16))||(CurY>C_FRAME_Y+C_FRAME_HEIGHT+YRES(10))||(CurY<C_FRAME_Y)))
			{
				Dropping=true
				return false
			}
			else Dropping=false;
		}
		else Dropping=false;
		
		if (((i-(ROWS*COLS))%Cols)>(Cols-x)) return false
		if (((i-(ROWS*COLS))/Cols)>(Rows-y))  return false
		
		if (i<0) return false
		//if (i>=INVENTORY.len()) {printl("cant move this item here!");return false}
		
		if (i>=INVENTORY.len()) return false;
		
		if (INVENTORY[i]==null||(INVENTORY[i]==DragID&&!DragEquipment)||(INVENTORY[i]==INVENTORY[DragID]&&!DragEquipment))
		{
			for (local j=0;j<(x*y);j++) 
			{
				if ((i+(j%x)+(j/x)*Cols)>=INVENTORY.len()) return false;
				if (InContainer==((i+(j%x)+(j/x)*Cols)<(ROWS*COLS))) return false;	// return false when main slot in container with adjacent being in inventory, or vice versa.
				if (INVENTORY[i+(j%x)+(j/x)*Cols]==null||INVENTORY[i+(j%x)+(j/x)*Cols]==DragID||INVENTORY[i+(j%x)+(j/x)*Cols]==INVENTORY[DragID]) cells++;
			}
		}
		
		local Stackable=false
		local SameItemName=false
		local OnTopOfSameSize=false
		local NotFullStack=false
		local SameItemCount=0
		for (local j=0;j<(x*y);j++) 
		{
			local Obstructor=INVENTORY[i+(j%x)+(j/x)*Cols];
			if ((typeof Obstructor)=="integer") Obstructor=INVENTORY[Obstructor];
			if (Obstructor!=null&&Obstructor!=INVENTORY[DragID]) SameItemCount++;
		}
		if ( SameItemCount == (x*y) ) OnTopOfSameSize=true;
		if ("Name" in INVENTORY[i]&&INVENTORY[i].Name==INVENTORY[DragID].Name) SameItemName=true;
		
		if (SameItemName&&OnTopOfSameSize)
		{
			if ("MaxStack" in INVENTORY[i]&&INVENTORY[i].Count<INVENTORY[i].MaxStack) NotFullStack=true;
		}
		
		Stackable=(SameItemName&&OnTopOfSameSize&&NotFullStack)
		
		if (Stackable) return true

		for (local j=0;j<(x*y);j++) 
		{
			local Obstructor=INVENTORY[i+(j%x)+(j/x)*Cols];	// make sure that any possible integer gets replaced with the item table itself.
			if ((typeof Obstructor)=="integer") Obstructor=INVENTORY[Obstructor];
			//printl(Obstructor)
			if (DetectedIDs.find(Obstructor)==null&&Obstructor!=null&&Obstructor!=INVENTORY[DragID]) DetectedIDs.append(Obstructor);
		}
		
		//printl("s: "+OnTopOfSameSize)
		//printl("n: "+SameItemName)
		
		if (cells==(x*y)) return true
		//printl("ITEMS OVERLAPPING "+DetectedIDs.len())
		if (DetectedIDs.len()>0) ItemOverlap=true;
		if (DetectedIDs.len()==1) return INVENTORY.find(DetectedIDs[0]);
		
		return false
	}
	
	NetMsg.Receive("GiveItemClient", function() {
		GiveItem(NetMsg.ReadString(),NetMsg.ReadShort(),NetMsg.ReadShort(),NetMsg.ReadFloat())
		return
	}.bindenv(this))
	
	NetMsg.Receive("AddQuestItem", function() {
		local id=NetMsg.ReadShort()
		local item=NetMsg.ReadString()
		QUICK_USE_SLOTS[id]=item
		if (item=="") QUICK_USE_SLOTS[id]=null;
		else
		{
			QuickUseStatus=1.5
			LastQuickUsePressed<-Time()
			LastQuickUseItem<-id
		}
		return
	}.bindenv(this))
	
	NetMsg.Receive("CreateItemInInventoryClient", function() {
		CreateItemInInventory(ID_TO_ITEMNAME(NetMsg.ReadByte()),
		{
			SizeX=NetMsg.ReadByte()
			SizeY=NetMsg.ReadByte()
			Rotated=NetMsg.ReadBool()
			Count=NetMsg.ReadByte()
			Clip=NetMsg.ReadByte()
			Durability=NetMsg.ReadFloat()
			DropFlag=false
			WeaponInvID=NetMsg.ReadByte()
			WeaponSlot=NetMsg.ReadByte()
			//QuickUseSlot=NetMsg.ReadByte()
		},NetMsg.ReadByte())
		return
	}.bindenv(this))
	
	NetMsg.Receive("PlaceItemClient", function() {
		//printl("got a message!")
		PlaceItem(NetMsg.ReadString(),ID_TO_ITEMNAME(NetMsg.ReadByte()),NetMsg.ReadByte(),NetMsg.ReadByte(),NetMsg.ReadByte(),NetMsg.ReadShort(),NetMsg.ReadBool())
		return
	}.bindenv(this))
	
	NetMsg.Receive("ChangeDurabilityOnClient", function() {
		INVENTORY[NetMsg.ReadShort()].Durability=NetMsg.ReadShort();
		return
	}.bindenv(this))
	
	NetMsg.Receive("PlaceEquipmentOnClient", function() {
		EQUIPMENT[NetMsg.ReadShort()]=Item(NetMsg.ReadString(),1,1)
		return
	}.bindenv(this))
	
	NetMsg.Receive("CreateContainerClient", function() {
		local contname=NetMsg.ReadString()
		local cols=NetMsg.ReadShort()
		local rows=NetMsg.ReadShort()
		local uniquename=NetMsg.ReadString()
		CONTAINERS.rawset(uniquename,{INVENTORY=array(cols*rows),COLS=cols,ROWS=rows,Name=contname,Shop=false})
		return
	}.bindenv(this))
	
	NetMsg.Receive("WEAPON_SLOT_CHANGE_TO_CLIENT", function()
	{
		local i=NetMsg.ReadShort()
		local Slot=NetMsg.ReadShort()
		WEAPON_SLOTS[i]=Slot
		printl("mapping wep slot "+i+" to weapon with id "+Slot)
	}.bindenv(this))
	/*
	NetMsg.Receive("QUICK_USE_SLOTS_CHANGE_TO_CLIENT", function()
	{
		local i=NetMsg.ReadShort()
		local Slot=NetMsg.ReadShort()
		QUICK_USE_SLOTS[i]=Slot
		
	}.bindenv(this))
	*/
	
	NetMsg.Receive("RemoveItemClient", function() {
		RemoveItem(NetMsg.ReadString(),NetMsg.ReadShort(),NetMsg.ReadShort())
		return
	}.bindenv(this))
	
	NetMsg.Receive("InventoryUseFromServer", function()
	{
		local i=NetMsg.ReadShort()
		INVENTORY[i].UseAction()
		//if (INVENTORY[i].QuickUseSlot!=null&&QUICK_USE_SLOTS[INVENTORY[i].QuickUseSlot]!=null) QUICK_USE_SLOTS[INVENTORY[i].QuickUseSlot]=null
	}.bindenv(this))
	
	NetMsg.Receive("UseItemOnClient", function()
	{
		local itemname=NetMsg.ReadString()
		Item(itemname,1).UseAction()
	}.bindenv(this))
	
	NetMsg.Receive("UnloadWeaponFromServer", function( )
	{
		local i=NetMsg.ReadShort()
		INVENTORY[i].UnloadWeapon(true)
	}.bindenv(this))
	
	
}

function HasItem(name)
{
	foreach (i,cell in INVENTORY)
	{
		if (i>=(ROWS*COLS)) continue;
		if ("Name" in cell) if (cell.Name==name&&cell.DropFlag==false) return true
	}
	return false
}
function ContainerHasItem(container,name)
{
	foreach (i,cell in CONTAINERS[container].INVENTORY)
	{
		if (i>=(CONTAINERS[container].ROWS*CONTAINERS[container].COLS)) continue;
		if (cell&&("Name" in cell)) if (cell.Name==name&&cell.DropFlag==false) return true
	}
	return false
}

function HasItemTech(name)
{
	foreach (i,cell in INVENTORY)
	{
		if (i>=(ROWS*COLS)) continue;
		if ("Name" in cell) if (cell.tech_name==name&&cell.DropFlag==false) return true
	}
	return false
}

::PlayerHasItem<-HasItemTech;

function HasItemCount(name)
{
	local count=0
	foreach (i,cell in INVENTORY)
	{
		if (i>=(ROWS*COLS)) continue;
		if ("Name" in cell) if (cell.Name==name&&cell.DropFlag==false) count+=cell.Count;
	}
	return count
}

::SW_PlayerHasItemCount<-HasItemCount;

::PlayerCanShootAmmo<-function(ammoitem)
{
	foreach (item in INVENTORY)
	{
		if (item&&((typeof item)!="integer")&&("ammoitem" in LIST_ITEMS[item.tech_name]))
		{
			if (ammoitem==LIST_ITEMS[item.tech_name].ammoitem) return true;
		}
	}
	local ent=null
	while (ent=Entities.FindByName(ent,"droppeditem"))
	{
		if (ent.GetContext("item").find("weapon")!=null&&("ammoitem" in LIST_ITEMS[ent.GetContext("item")]))
		{
			if (ammoitem==LIST_ITEMS[ent.GetContext("item")].ammoitem) return true;
		}
	}
	
	return false
}

::CountAllPlayerAmmo<-function()
{
	local ammo=0
	foreach (itemname,v in LIST_ITEMS)
	{
		if (itemname.find("ammo")!=null&&SW_PlayerHasItemCount(v.name)!=0&&PlayerCanShootAmmo(itemname)) ammo+=SW_PlayerHasItemCount(v.name);
		
	}
	foreach (item in INVENTORY)
	{
		if (item&&((typeof item)!="integer")&&("ammoitem" in LIST_ITEMS[item.tech_name])&&item.Clip>0) ammo+=item.Clip;
	}
	local ent=null
	while (ent=Entities.FindByName(ent,"droppeditem"))
	{
		if (ent.GetContext("item").find("ammo")!=null&&PlayerCanShootAmmo(ent.GetContext("item")))
		{
			ammo+=ent.GetContext("count").tointeger()
			continue
		}
		
		if (ent.GetContext("item").find("weapon")==null||!("ammoitem" in LIST_ITEMS[ent.GetContext("item")])) continue;
		
		local clip=ent.GetContext("clip")
		if (clip.len()>0) 
		{
			clip=clip.tointeger()
			ammo+=clip
		}
	}
	
	//printl("///////////////////////////////")
	//printl("TOTAL PLAYER'S AMMO IS - "+ammo)
	//printl("///////////////////////////////")
	return ammo
}

::GetPlayerMercyItem<-function()
{
	local mercyitem="weapon_pistol"
	
	foreach (item in INVENTORY)
	{
		if (item&&((typeof item)!="integer")&&("ammoitem" in LIST_ITEMS[item.tech_name]))
		{
			mercyitem=LIST_ITEMS[item.tech_name].ammoitem
			break
		}
	}
	local ent=null
	while (ent=Entities.FindByName(ent,"droppeditem"))
	{
		if (ent.GetContext("item").find("weapon")!=null&&("ammoitem" in LIST_ITEMS[ent.GetContext("item")]))
		{
			mercyitem=LIST_ITEMS[ent.GetContext("item")].ammoitem
			break
		}
	}
	return mercyitem
}

::InputSpawnMercyItemAtEntity<-function()
{
	local item=GetPlayerMercyItem()
	local location=GetNamedEnt(parameter).GetOrigin()
	
	if (CountAllPlayerAmmo()==0)
	{
		local item=SpawnItem(item,(LIST_ITEMS[item].maxstack/4).tointeger(),(item=="weapon_pistol") ? 18 : 0)
		item.SetOrigin(location)
		item.GetPhysicsObject().Sleep()
		item.GetPhysicsObject().Wake()
		item.SetName("droppeditem")
	}
}

function SyncAllWeapons()
{
	//SyncWeapon("weapon_crowbar")
	//SyncWeapon("weapon_pistol")
	//SyncWeapon("weapon_357")
	//SyncWeapon("weapon_shotgun")
}

function SyncWeapon(weapon_name)
{
	local weapon=LIST_ITEMS[weapon_name]
	
	if (SERVER_DLL) 
	{
		if (player.GetHealth()<=1) return
		foreach (cell in INVENTORY)
		{
			//if (!player.FindWeapon(weapon_name,0)) if ("Name" in cell) if (cell.Name==weapon.name&&cell.DropFlag==false) GiveSilent(weapon_name,["0"])
		}
		if (player.FindWeapon(weapon_name,0)) if (!HasItem(weapon.name)) GiveItem(weapon_name);
	}
	if ("ammoitem" in weapon) SyncAmmo(weapon.ammoitem)
}

function SyncAmmo(ammo_name)
{
	local ammo_item=LIST_ITEMS[ammo_name]
	
	local Ammo=player.GetAmmoCount(ammo_item.ammotype)
	local InvAmmo=0
	
	local maxstack=ammo_item.maxstack
	
	foreach (cell in INVENTORY)
	{
		if ("Name" in cell) if (cell.Name==ammo_item.name) InvAmmo=InvAmmo+cell.Count;
	}

	local Dif=Ammo-InvAmmo;
	
	if (Dif>0)
	{
		GiveItem(ammo_name,Dif)
	}
	if (Dif<0)
	{
		RemoveItem(ammo_name,abs(Dif))
	}
	
	local FreeCells=-1
	foreach (Cell in INVENTORY) if (!Cell) FreeCells++;
	local ExtraAmmo=maxstack-(InvAmmo%maxstack)
	if (ExtraAmmo==maxstack) ExtraAmmo=0
	
	Convars.SetInt(ammo_item.ammoconvar,InvAmmo+ExtraAmmo+FreeCells*maxstack)
}

if (SERVER_DLL)
{
	
	function InventoryMenu()
	{
		if (!player.IsAlive()) return;
	
		SyncAllWeapons()
		/*	UNUSED INVENTORY SIZE CHANGE BEHAVIOR
		COLS=8+(player.GetHealth()<99).tointeger()*4
		while (INVENTORY.len()<ROWS*COLS) INVENTORY.append(null)
		*/
		NetMsg.Start("OpenInventory");
		NetMsg.Send(player, true);
	}
	
	function ContainerMenu(container)
	{
		SyncAllWeapons()
		ActiveContainer=container
		if (ActiveContainer!=null&&INVENTORY.len()==(COLS*ROWS)) INVENTORY.extend(CONTAINERS[ActiveContainer].INVENTORY)
		NetMsg.Start("OpenContainer");
		NetMsg.WriteString(container)
		NetMsg.Send(player, true);
	}
	
	Convars.RegisterCommand( "inventory", function(_)
	{
		InventoryMenu()
		//SendToConsole("play ui/hint")
	}.bindenv(this), "", FCVAR_CLIENTDLL );
	
	NetMsg.Receive("InventoryMove", function( player )
	{
		local DragID=NetMsg.ReadShort()
		local DragRotated=NetMsg.ReadBool()
		local i=NetMsg.ReadShort()
		local DragCount=NetMsg.ReadShort()
		local DragSizeX=INVENTORY[DragID].SizeX
		local DragSizeY=INVENTORY[DragID].SizeY
		
		
		local IsTrader=(ActiveContainer && CONTAINERS[ActiveContainer].Shop)
		local WithinTrader=(IsTrader&&(i>=(ROWS*COLS)&&DragID>=(ROWS*COLS)))
		local ToTrader=(IsTrader&&(i>=(ROWS*COLS)&&DragID<(ROWS*COLS)))
		local FromTrader=(IsTrader&&(i<(ROWS*COLS)&&DragID>=(ROWS*COLS)))
		local TraderGoods=(FromTrader&&Trader.INVENTORY[DragID-(ROWS*COLS)]==INVENTORY[DragID])||(FromTrader&&Trader2.INVENTORY[DragID-(ROWS*COLS)]==INVENTORY[DragID])
		
		/*
		if (i<ROWS*COLS&&QUICK_USE_SLOTS.find(DragID)!=null)
		{
			QUICK_USE_SLOTS[QUICK_USE_SLOTS.find(DragID)]=i
		}
		if (i>=ROWS*COLS&&QUICK_USE_SLOTS.find(DragID)!=null)
		{
			INVENTORY[DragID].QuickUseSlot=null
			QUICK_USE_SLOTS[QUICK_USE_SLOTS.find(DragID)]=null
		}
		*/
		
		local Cols=COLS
		if (DragID>=(ROWS*COLS)) Cols=CONTAINERS[ActiveContainer].COLS
		
		if (!TraderGoods&&DragCount==INVENTORY[DragID].Count) for (local j=1;j<(DragSizeX*DragSizeY);j++) INVENTORY[DragID+(j%DragSizeX)+(j/DragSizeX)*Cols]=null;
		
		if (DragRotated)
		{	
			local buf=DragSizeX
			printl("swapping dragsizes")
			
			DragSizeX=DragSizeY
			DragSizeY=buf
		}
		
		local a=clone INVENTORY[DragID]
		if (DragRotated) 
		{
			local buf=a.SizeX
			a.SizeX=a.SizeY
			a.SizeY=buf
			a.Rotated=!a.Rotated;
		}
		a.Count=DragCount
		if (INVENTORY[i]==null) INVENTORY[i]=a
		else INVENTORY[i].Count+=DragCount
		a=null
		
		if (!TraderGoods&&DragCount<INVENTORY[DragID].Count) INVENTORY[DragID].Count-=DragCount;
		else if (!TraderGoods&&DragCount==INVENTORY[DragID].Count) INVENTORY[DragID]=null;
		
		if (i>=(ROWS*COLS)) Cols=CONTAINERS[ActiveContainer].COLS;
		else Cols=COLS;
		for (local j=1;j<(DragSizeX*DragSizeY);j++) INVENTORY[i+(j%DragSizeX)+(j/DragSizeX)*Cols]=i;
		
		printl(DragSizeX)
		printl(DragSizeY)
		
		local Amount=SW_PlayerHasItemCount(INVENTORY[i].Name)
		
		local ItemEntry=LIST_ITEMS[INVENTORY[i].tech_name]
		if ("weapon" in ItemEntry)
		{
			if (i<(ROWS*COLS)&&DragID>=(ROWS*COLS)) // weapon from storage
			{	
				INVENTORY[i].InitWeapon()
			}
			if (i>=(ROWS*COLS)&&DragID<(ROWS*COLS)&&(!INVENTORY[i].SingleUse||INVENTORY[i].SingleUse&&Amount<=0)) // weapon to storage
			{
				local APlayer=Entities.FindByClassname(null,"weapon_custom_scripted1").GetOrCreatePrivateScriptScope().aPlayer
				local Weps=APlayer.Weapons
				local HasWeapon=("Weapon" in APlayer)
				
				if (INVENTORY[i].WeaponSlot!=null)
				{
					WEAPON_SLOTS[INVENTORY[i].WeaponSlot]=null
					INVENTORY[i].WeaponSlot=null
				}
				
				Weps[INVENTORY[i].WeaponInvID]=null

				if (HasWeapon&&APlayer.ActiveWeaponSlot==INVENTORY[i].WeaponInvID) {
					APlayer.rawdelete("Weapon");
					if (CLIENT_DLL) SW_HUDPlayerWeapon="";
					APlayer.Weapons[APlayer.ActiveWeaponSlot]=null
					APlayer.ActiveWeaponSlot=(-1)
					printl("removing current weapon!")
					if (SERVER_DLL) player.GetViewModel(0).SetModel("models/blackout.mdl");
				}
				if (aPlayer.DualWield[0]!=null&&aPlayer.DualWield[1]!=null&&aPlayer.DualWield.find(INVENTORY[i].WeaponInvID)!=null)
				{
					APlayer.rawdelete("Weapon");
					if (CLIENT_DLL) SW_HUDPlayerWeapon="";
					APlayer.Weapons[APlayer.ActiveWeaponSlot]=null
					APlayer.ActiveWeaponSlot=(-1)
					printl("removing current weapon!")
					if (SERVER_DLL) player.GetViewModel(0).SetModel("models/blackout.mdl");		
				}
			}
		}
		
		
		
		
	}.bindenv(this))
	
	NetMsg.Receive("WeaponSlotChanged", function( player )
	{
		local itemslot=NetMsg.ReadShort()
		local Slot=NetMsg.ReadShort()
		
		if (Slot<0) Slot=null;
		
		local wep=INVENTORY[itemslot]

		if ((typeof wep)=="integer") wep=INVENTORY[wep]
		
		if (!("tech_name" in wep)) return;
		if (!("weapon" in LIST_ITEMS[wep.tech_name])) return;
		
		//printl(wep.WeaponSlot+" - "+Slot)
		
		if (wep.WeaponSlot!=Slot) player.EmitSound("Player.WeaponSelectionMoveSlot");
		
		wep.ChangeWeaponSlot(Slot)
		
	}.bindenv(this))

	/*
	NetMsg.Receive("QuickUseSlotChanged", function( player )
	{
		local itemslot=NetMsg.ReadShort()
		local Slot=NetMsg.ReadShort()
		
		if (Slot<0) Slot=null;
		
		local item=INVENTORY[itemslot]

		if ((typeof item)=="integer") item=INVENTORY[item]
		
		if (!("tech_name" in item)) return;
		if (!("Use" in LIST_ITEMS[item.tech_name])) return;
		
		//printl(item.WeaponSlot+" - "+Slot)
		
		//if (item.QuickUseSlot!=Slot) player.EmitSound("Player.WeaponSelectionMoveSlot");
		
		item.ChangeQuickUseSlot(Slot)
		
	}.bindenv(this))
	*/
	
	NetMsg.Receive("InventoryEquip", function( player )
	{
		local DragID=NetMsg.ReadShort()
		local i=NetMsg.ReadShort()
		local DragSizeX=INVENTORY[DragID].SizeX
		local DragSizeY=INVENTORY[DragID].SizeY
		
		local Cols=COLS
		if (DragID>=(ROWS*COLS)) Cols=CONTAINERS[ActiveContainer].COLS
		
		for (local j=1;j<(DragSizeX*DragSizeY);j++) INVENTORY[DragID+(j%DragSizeX)+(j/DragSizeX)*Cols]=null;

		EQUIPMENT[i]=INVENTORY[DragID]
		//else INVENTORY[i].Count+=DragCount
		//a=null
		
		INVENTORY[DragID]=null;
	}.bindenv(this))
	NetMsg.Receive("InventoryMoveEquip", function( player )
	{
		local DragID=NetMsg.ReadShort()
		local i=NetMsg.ReadShort()
		local DragSizeX=EQUIPMENT[DragID].SizeX
		local DragSizeY=EQUIPMENT[DragID].SizeY

		EQUIPMENT[i]=EQUIPMENT[DragID]
		//else INVENTORY[i].Count+=DragCount
		//a=null
		
		EQUIPMENT[DragID]=null;
	}.bindenv(this))
	NetMsg.Receive("InventoryUnEquip", function( player )
	{
		local DragID=NetMsg.ReadShort()
		local i=NetMsg.ReadShort()
		local DragSizeX=EQUIPMENT[DragID].SizeX
		local DragSizeY=EQUIPMENT[DragID].SizeY
		
		local Cols=COLS
		if (DragID>=(ROWS*COLS)) Cols=CONTAINERS[ActiveContainer].COLS
		
		INVENTORY[i]=EQUIPMENT[DragID]
		//else INVENTORY[i].Count+=DragCount
		//a=null
		
		EQUIPMENT[DragID]=null;
	}.bindenv(this))
	
	NetMsg.Receive("InventoryClose", function( player )
	{
		if (INVENTORY.len()>(COLS*ROWS)) CONTAINERS[ActiveContainer].INVENTORY=INVENTORY.slice(COLS*ROWS)	//do this on close. both sides
		if (INVENTORY.len()>(COLS*ROWS)) INVENTORY=INVENTORY.slice(0,COLS*ROWS)	//do this on close. both sides
		
		local TrueClose=NetMsg.ReadBool()
		
		if (TrueClose)
		{
			EntFire(ActiveContainer,"ChangeVariable","m_flCooldownTime 1")
			
			if (ActiveContainer && CONTAINERS[ActiveContainer].Shop) 
			{
				NetMsg.Start("ContinueDialogue");
				NetMsg.Send(player, true);
			}
		}
	}.bindenv(this))
	
	NetMsg.Receive("ContainerOpen", function( player )
	{
		ContainerMenu(NetMsg.ReadString())
	}.bindenv(this))
	
	
	NetMsg.Receive("InventoryRotate", function( player )
	{
		local i=NetMsg.ReadShort()
		INVENTORY[i].Rotate()
		
	}.bindenv(this))
	
	NetMsg.Receive("InventoryUseFromClient", function( player )
	{
		local i=NetMsg.ReadShort()
		INVENTORY[i].UseAction()
		//if (INVENTORY[i].QuickUseSlot!=null&&QUICK_USE_SLOTS[INVENTORY[i].QuickUseSlot]!=null) QUICK_USE_SLOTS[INVENTORY[i].QuickUseSlot]=null
		RemoveItem(INVENTORY[i].tech_name,1,i)
	}.bindenv(this))
	
	NetMsg.Receive("InventoryRepairFromClient", function( player )
	{
		local i=NetMsg.ReadShort()
		INVENTORY[i].Repair(NetMsg.ReadShort())
	}.bindenv(this))
	
	NetMsg.Receive("UnloadWeaponFromClient", function( player )
	{
		local i=NetMsg.ReadShort()
		INVENTORY[i].UnloadWeapon()
	}.bindenv(this))
	
	NetMsg.Receive("ItemDrop", function( player )
	{
		local i=NetMsg.ReadShort()
		INVENTORY[i].SpawnDropped(NetMsg.ReadShort(),NetMsg.ReadShort())
	}.bindenv(this))
	
	NetMsg.Receive("SpawnItem", function( player )
	{
		SpawnItem(NetMsg.ReadString(),NetMsg.ReadByte(),NetMsg.ReadByte(),NetMsg.ReadFloat())
	}.bindenv(this))
	
	/*
	function UpdateCell(i)
	{
		local item=INVENTORY[i]
		NetMsg.Start("UpdateCell");
		NetMsg.WriteInt(i)
		WriteTable(container)
		NetMsg.Send(player, true);
	}
	*/
	
	
	function HasSpace(x,y,tech_name=null,count=null)
	{
		local cells=0
		for (local i=0;i<INVENTORY.len();i++)
		{
			if ((i%COLS)>(COLS-x)) continue
			if ((i/COLS)>(ROWS-y))  continue
			cells=0
			
			if (INVENTORY[i]==null)
			{
				for (local j=0;j<(x*y);j++) if (INVENTORY[i+(j%x)+(j/x)*COLS]==null) cells++;
			}
			if (cells==(x*y)) return i
		}
		
		if (tech_name&&LIST_ITEMS[tech_name].maxstack>1)
		{
			for (local i=0;i<INVENTORY.len();i++)
			{
				local cell=INVENTORY[i]
				if ("Name" in cell) if (cell.Name==LIST_ITEMS[tech_name].name)
				{
					local Dif=clamp(count,0,LIST_ITEMS[tech_name].maxstack-cell.Count) //how many to put in a cell with item already
					Dif=abs(Dif)
					count-=Dif
					//printl("dif is "+Dif)
					//printl("count is "+count)
					//printl("after "+INVENTORY[i].Count)
				}
			}
			if (count<=0) return 0;
		}
		
		return false
	}
	
	Entities.First().SetContextThink("testis",function(_)
	{

	}.bindenv(this),1)
	/*
	Entities.First().SetContextThink("testis2",function(_)
	{
		local wep=null
		while (wep=Entities.FindByClassname(wep,"weapon_pistol"))
		{
			if (Time()<3&&wep.GetSpawnFlags()&2&&!(wep.GetSpawnFlags()&128)) {wep.AddSpawnFlags(128)}
			if (wep.GetSpawnFlags()&128) continue
			
			if (HasSpace(2,2)==false) wep.AddSpawnFlags(2);
			else wep.RemoveSpawnFlags(2);
		}
		
		while (wep=Entities.FindByClassname(wep,"weapon_crowbar"))
		{
			if (Time()<3&&wep.GetSpawnFlags()&2&&!(wep.GetSpawnFlags()&128)) {wep.AddSpawnFlags(128)}
			if (wep.GetSpawnFlags()&128) continue
			
			if (HasSpace(1,3)==false) wep.AddSpawnFlags(2);
			else wep.RemoveSpawnFlags(2);
		}
		
		SyncAllWeapons()
		printl("")
		for (local i=0;i<INVENTORY.len();i++)
		{
			if (i%10==0) printl("")
			local s=""
			if (INVENTORY[i]==null) s+="0"
			else s+="1"
			print(s)

		}
		printl("")
		
		return 0
	}.bindenv(this),1)
	*/
}