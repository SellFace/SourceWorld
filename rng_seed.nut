local seed=null
local initial_seed=null
local seed_value=rand()*rand()*2
//local seed_value=38360668
const a=75
const b=74
const m=65537
if (SERVER_DLL) {
if (Globals.GetIndex("RNGSeed")==-1)
{
	seed=Globals.AddGlobal("RNGSeed",GetMapName(),1);
	Globals.SetCounter(seed,seed_value)
}
else {seed=Globals.GetIndex("RNGSeed")}
if (Globals.GetIndex("InitialRNGSeed")==-1) {initial_seed=Globals.AddGlobal("InitialRNGSeed",GetMapName(),1)}
else 
{
	initial_seed=Globals.GetIndex("InitialRNGSeed")
	SendToConsole("cl_discord_override 1")
	SendToConsole("cl_discord_state In Mapgen")
	SendToConsole("cl_discord_details Seed: "+format("%X",Globals.GetCounter(initial_seed)).tostring())
	SendToConsole("cl_discord_update")
	printl("      set rpc seed to "+format("%X",Globals.GetCounter(initial_seed)).tostring()+"  "+Globals.GetCounter(initial_seed))
}
local rn=Globals.GetCounter(seed)
}
if (CLIENT_DLL) local rn=0


::SW_PLAYTHROUGH_SEED<-(-1);
::SW_PLAYTHROUGH_RNG<-(-1);

function PrintNW(text)
{
	local c=CLIENT_DLL ? Vector(255,255,110) : Vector(110,255,255)
	printc(c.x,c.y,c.z,"---"+"\n")
	printc(c.x,c.y,c.z,text+"\n")
	printc(c.x,c.y,c.z,"---"+"\n")
}

function SetPlaythroughSeed(value)
{
	SW_PLAYTHROUGH_SEED=value;
	SW_PLAYTHROUGH_RNG=value;
	
	PrintNW(format("Seed changed to %i",value))
	
	if (SERVER_DLL)
	{
		printl("SENDING SEED TO CLIENT! "+value)
		Entities.First().SetContextThink("SWSEED",function(_) {
		NetMsg.Start("SetSWSeedOnClient")
		NetMsg.WriteShort(value);
		NetMsg.Send(player,true)}.bindenv(this),1)
	}
}

NetMsg.Receive("SetSWSeedOnClient",function(...) {
	local value=NetMsg.ReadShort()
	printl("RECEIVING SEED ON CLIENT! "+value)
	SetPlaythroughSeed(value)
}.bindenv(this))

::SWRandInt<-function(na=0 , nb=0)
{
	local result = null
	SW_PLAYTHROUGH_RNG = (a*SW_PLAYTHROUGH_RNG+b)%m
	SW_PLAYTHROUGH_RNG=abs(SW_PLAYTHROUGH_RNG)
	result = (SW_PLAYTHROUGH_RNG%(abs(na-nb)+1))+na
	return result
}

function SetRNGSeed(value)
{
	if (SERVER_DLL) {Globals.SetCounter(initial_seed,value)}
	if (SERVER_DLL) {Globals.SetCounter(seed,value)}
}
function GetRNGSeed()
{
	if (SERVER_DLL) return Globals.GetCounter(Globals.GetIndex("InitialRNGSeed"))
}

local RandNumber = function()
{
	if (SERVER_DLL) rn=Globals.GetCounter(seed)
	local result = null
	rn = (a*rn+b)%m
	rn=abs(rn)
	if (SERVER_DLL) Globals.SetCounter(seed,rn)
	return rn
}
function RandInt(na=0 , nb=0)
{
	if (SERVER_DLL) rn=Globals.GetCounter(seed)
	local result = null
	rn = (a*rn+b)%m
	rn=abs(rn)
	result = (rn%(abs(na-nb)+1))+na
	if (SERVER_DLL) Globals.SetCounter(seed,rn)
	return result
}

function RandNormalInt(n=0 , d=0,debug=false)
{
	local rn1=fabs(RandFloat(0 , 1))
	local rn2=fabs(RandFloat(0 , 1))
	local rn3=fabs(RandFloat(0 , 1))
	if (debug)
	{
	printl("RANDOMNESS WITH NORMAL DISTRIBUTION RUNNING")
	printl("3 RANDOM VALUES GO AS "+rn1+" "+rn2+" "+rn3)
	printl("SUM "+(rn1+rn2+rn3))
	printl("Remapped to fit these bounds("+n+","+d+") we get"+RemapVal((rn1+rn2+rn3),0,3,n,d))
	printl("Rounding the end value "+(RemapVal((rn1+rn2+rn3),0,3,n,d)+0.5).tointeger())
	}
	return (RemapVal((rn1+rn2+rn3),0,3,n,d)+0.5).tointeger()
}

function RandomBrightColor()
{
	local br=RandInt(1,3)
	local zr=RandInt(1,3)
	local bluecomp=0
	while (zr==br) {zr=RandInt(1,3)}
	local color=[0,0,0]
	color[br-1]=255
	color[zr-1]=0
	if (br==3) {bluecomp=160}
	for (local i=0;i<3;i++)
	{
		if (i!=(br-1)&&i!=(br-1)) {color[i]=RandInt(bluecomp,255)}
	}
	return Vector(color[0],color[1],color[2])
}

function RandFloat(na=0 , nb=0)
{
	na*=100;nb*=100
	if (SERVER_DLL) rn=Globals.GetCounter(seed)
	local result = null
	rn = (a*rn+b)%m
	result = (rn%(fabs(na-nb)+1))+na
	result=result/100
	if (SERVER_DLL) Globals.SetCounter(seed,rn)
	return result.tofloat()
}