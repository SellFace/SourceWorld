if (CLIENT_DLL) return
local music = Entities.FindByName(null, "SW_MUSIC");
local music2 = Entities.FindByName(null, "SW_MUSIC2");
if (music!=null) return

// The price for not using WAV format for looped music, ladies and gents. Manually writing all durations because the engine can't read duration of mp3s correctly. 
::SW_MUS<-{}
::SW_MUS.DurTable<-{
	hordeslayer_01=5.6411
	hordeslayer_02=5.6411
	hl2_song1=60
	surface_tension=107
	lines_in_the_sand=96
	black_market=92
	reconciliation=88
	moog=268.8
	odell=64.7
	chirkashnitsa=68
	dialouge=103
	shinjuku=135
	kagome=146
	aboveground=164
	domain=69
	geist=176
	naraku=180
	untitled_27=241
	untitled_106=241
	untitled_5=108
	lobby=144
	pluto=135
	devil_dance=130
	ginza=210
	lobbycombat=172
	district=268.8
	district_unrest=268.8
	bar=88
	costello=169.5
	boss=110
	vlvx_song19b=240
	credits=300
	portal=54.8
	portal2=128
	covenant_terror=180
	opening=165
	the_library=180
	aftermath=150
	hecu_takeover=100
	morphine=90
	abandoned_facility=170
	malfunction=180
	stars=135
	drums=160
	the_ring=200
	disturbed_and_powerful=110
	acid_breakbeat_death_jam=95
	methods=140
	mayhem=200
	combat3=87
	welcome_to_bm=145
	sector_c=66
	overdrive=172
	abra=149
	"3rdorder":98
	"4thorder":125
	shagain=56
	gunshopcombat=90
	claustrophobia=150
}

local combat_mus=[
"disturbed_and_powerful",
"acid_breakbeat_death_jam",
"methods",
"mayhem",
"combat3",
"overdrive"
"abra"
]

function IsSameSong(a,b)
{
	if (a==b) return true;
	return false
}

::SW_MUS.GetDuration <- function (song)
{
	if (!(song in SW_MUS.DurTable)) return 60
	return SW_MUS.DurTable[song]
}.bindenv(this)

Channel<-0;
IsPlaying<-false
LastSong<-"null"
	
if (music==null)
{
	printf("Music Manager not found. Spawning...");
	local S = {
	targetname = "SW_MUSIC",
	origin = [0, 0, 0]
	spawnflags=17
	soundflags=128
	message="common/null.mp3"
	health=10
	}
	local S2 = {
	targetname = "SW_MUSIC2",
	origin = [0, 0, 0]
	spawnflags=17
	soundflags=128
	message="common/null.mp3"
	health=10
	}
	
	
	music = SpawnEntityFromTable("ambient_generic",S);
	if (music2==null) music2 = SpawnEntityFromTable("ambient_generic",S2);
}
EntFire("musica","Kill")

::SW_MUS.Play <- function (song)
{
	local Duration=SW_MUS.DurTable[song]
	Channel=1;
	Entities.First().PrecacheSoundScript("*#music/"+song+".mp3")
	//printl(music+" plays "+song+" "+Duration)
	music.__KeyValueFromString("message","*#music/"+song+".mp3")
	EntFireByHandle(music,"PlaySound","",0.0001)
	IsPlaying=true;
	LastSong=song;
	Entities.First().SetContextThink("SW_MUS_END",function (...) {IsPlaying=false}.bindenv(this),Duration)
	
}.bindenv(this)

::SW_MUS.Stop <- function ()
{
	EntFireByHandle(music,"StopSound","",0.0001)
	EntFireByHandle(music2,"StopSound","",0.0001)
	IsPlaying=false;
	Entities.First().SetContextThink("SW_MUS_LOOP",function (...) {return}.bindenv(this),0)
}.bindenv(this)

::SW_MUS.Reset <- function ()
{
	EntFireByHandle(music,"StopSound","",0.0001)
	EntFireByHandle(music2,"StopSound","",0.0001)
	Channel<-0;
	IsPlaying<-false
	LastSong<-"null"
}.bindenv(this)

QueueSize<-0;


::SW_MUS.PlaySmooth <- function (song,delay=1)
{
	if (IsPlaying&&IsSameSong(song,LastSong)) return;
	
	if (QueueSize>0)
	{
		Entities.First().SetContextThink("SW_MUS_QUEUE_PLAY_"+QueueSize,function (...) {SW_MUS.PlaySmooth(song,delay);return;}.bindenv(this),0.8*QueueSize)
		return;
	}
	
	QueueSize++;
	Entities.First().SetContextThink("SW_MUS_QUEUE"+QueueSize,function (...) {QueueSize=clamp(QueueSize-1,0,16)}.bindenv(this),0.8)
	
	
	local Duration=SW_MUS.GetDuration(song)
	if (Channel==2) {local m=music;music=music2;music2=m}
	Channel=2;
	Entities.First().PrecacheSoundScript("*#music/"+song+".mp3")
	printl(music+" plays "+song+" "+Duration)
	music2.__KeyValueFromString("message","*#music/"+song+".mp3")
	music2.AcceptInput("Volume","0",null,null)
	pitch<-Convars.GetFloat("host_pitchscale")
	Convars.SetFloat("host_pitchscale",1.001)
	if (IsPlaying&&(!IsSameSong(song,LastSong))) music.AcceptInput("Volume","8",null,null)
	if (IsPlaying&&(!IsSameSong(song,LastSong))) EntFireByHandle(music,"FadeOut",delay.tostring(),0.0001);
	EntFireByHandle(music2,"FadeIn",delay.tostring(),0.0001);
	Entities.First().SetContextThink("Pitchscaler",function (...){Convars.SetFloat("host_pitchscale",1.001);return 0},0)//doesnt fucking work, slowmo still slows down music
	Entities.First().SetContextThink("PitchscalerBack",function (...){Convars.SetFloat("host_pitchscale",pitch);Entities.First().SetContextThink("Pitchscaler",function (...){return},0)}.bindenv(this),0.2)
	IsPlaying=true;
	LastSong=song;
	Entities.First().SetContextThink("SW_MUS_END",function (...) {IsPlaying=false}.bindenv(this),Duration)
}.bindenv(this)

::SW_MUS.PlayLoop <- function (song)
{
	local Duration=SW_MUS.DurTable[song]
	SW_MUS.Play(song)
	Entities.First().SetContextThink("SW_MUS_LOOP",function (...) {SW_MUS.Play(song);return Duration},Duration)
	//Entities.First().SetContextThink("SW_MUS_LOOP2",function (...) {music.AcceptInput("Volume",""+RandomInt(0,10),null,null);return 0.1},0.1)
}.bindenv(this)


::InputChangeAmbient<-function()
{
	SW_AMBIENT=parameter
}.bindenv(this)

::InputSetMusicOverride<-function()
{
	SW_MUSIC_OVERRIDE=parameter
}.bindenv(this)

::InputStopMusicOverride<-function()
{
	SW_MUSIC_OVERRIDE=""
}.bindenv(this)


