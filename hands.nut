
local m_hHands;

if ( SERVER_DLL )
{
	local function AnimThink( player )
	{
		return
		//m_hHands.StudioFrameAdvance();
		//m_hHands.FollowEntity(Entities.FindByName(null,"viewmodel"),true)
		//return 0.0;
	}

	local function PlaySwingAnimation( player )
	{
		if ( m_hHands && m_hHands.IsValid() )
			m_hHands.Destroy();

		m_hHands = Entities.CreateByClassname("prop_dynamic");
		m_hHands.SetModel("models/weapons/v_spade.mdl");
		m_hHands.FollowEntity(player.GetViewModel(0),true)
		m_hHands.SetName("sw_hands")
		m_hHands.SetModelScale(1,0)
		m_hHands.SetSequence( 1 );
		m_hHands.AddEffects( 16+1 );
		m_hHands.ResetSequenceInfo();
		m_hHands.AcceptInput("setviewhideflags","188",m_hHands,m_hHands)
		printl(player.GetViewModel(1).GetFollowedEntity())
		
		//if (Convars.GetFloat("host_timescale")<1) m_hHands.SetPlaybackRate( 1.3 );
		//if (Convars.GetFloat("host_timescale")<1) m_hHands.SetCycle( 0.10 );

		player.SetContextThink( "MeleeAttack.Anim", AnimThink, 0.0 );

		NetMsg.Start("MeleeAttack.Anim");
			m_hHands.SetTransmitState( 8 );
			NetMsg.WriteEntity( m_hHands );
		NetMsg.Send( player, true );
	}

	local function DoAttack( player )
	{
		player.SetContextThink( "PlaySwingAnimation", PlaySwingAnimation, 0 );
	}

	NetMsg.Receive( "MeleeAttack", DoAttack );
}

if ( CLIENT_DLL )
{
	local function AnimThink(_)
	{
		if ( m_hHands.IsValid() )
		{
			local origin = MainViewOrigin()

			local angles = MainViewAngles();

			m_hHands.SetLocalOrigin( origin );
			
			m_hHands.SetLocalAngles( angles );

			return 0.0;
		}

		m_hHands = null;

		return -1;
	}
	/*
	NetMsg.Receive( "MeleeAttack.Anim", function()
	{
		m_hHands = NetMsg.ReadEntity();
		//m_hHands.FollowEntity(Entities.FindByName(null,"viewmodel"),true)
		m_hHands.AddEffects( 16+1 );
		Entities.First().SetContextThink( "MeleeAttack.Anim", AnimThink, 0.0 );
	} );
	local function Attack()
	{
		NetMsg.Start( "MeleeAttack" );
		return NetMsg.Send();
	}

	Convars.RegisterCommand( "+attack3", function(...)
	{
		Attack();
		return true;
	}, "", 0 );
	*/
}
