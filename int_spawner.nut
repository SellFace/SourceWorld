
local Intruders=20;
if (Convars.GetInt("developer")==1) Intruders=2;

EntFire("int_counter","SetMaxValueNoFire",Intruders,0)

function InputTrigger()
{
	if (Intruders==1) EntFire("int_timer","kill","",0.2)
	if (Intruders<=0) return; 
	local Num=AINetwork.NumNodes()
	local Pos=Vector(4999,4999,4999)
	local fails=0
	while (((Pos-player.GetOrigin()).Length()>800||(Pos-player.GetOrigin()).Length()<72)&&fails<20) {Pos=AINetwork.GetNodePosition(RandomInt(0,Num-1));fails++}
	if (player.GetHealth()>50) EntFire("npc_combine_s","RemoveSpawnFlags",8,0);
	else EntFire("npc_combine_s","AddSpawnFlags",8,0); // so that they only drop health vials if player needs them, kinda like how they work in vanilla, but more merciful.
	Intruders--
	
	
	if ((Intruders%5)==0) {EntFire("int_maker1","ForceSpawnAtPosition",Pos.x+" "+Pos.y+" "+Pos.z,0);return}
	if ((Intruders%8)==0) {EntFire("int_maker2","ForceSpawnAtPosition",Pos.x+" "+Pos.y+" "+Pos.z,0);return}
	else {EntFire("int_maker","ForceSpawnAtPosition",Pos.x+" "+Pos.y+" "+Pos.z,0);return}
}