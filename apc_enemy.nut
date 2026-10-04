
local Health=5000

function OnTakeDamage(info)
{
	Health-=info.GetDamage()
	
	if (Health<=0)
	{
		EntFireByHandle(self,"destroy","",0.1)
	}
	else 
	{
		info.SetDamage(info.GetDamage()*0.05);
		info.SetDamageType(DMG_BLAST)
		
		self.PrecacheSoundScript("SW.Armor_Hit")
		self.EmitSound("SW.Armor_Hit")
		self.EmitSound("SW.Armor_Hit")
	}
}

function Think()
{
	if ((self.GetAngles().z>90)||(self.GetAngles().z<(-90)))
	{
		// Overturned
		EntFireByHandle(self,"Destroy","",0.01)
		return 0.1
	}

	if (((Time())%8)<0.5)
	{
		EntFire("apc_driver","gotopathcorner",player.GetVehicleEntity().GetName(),0.01);
	}
	
	if ((Time().tointeger())%5<1)
		NetProps.SetPropFloat(self,"m_flRocketTime",Time()-1);
	else
		NetProps.SetPropFloat(self,"m_flRocketTime",Time()+10);

	return 0.3
}

Hooks.Add(this,"OnTakeDamage",OnTakeDamage.bindenv(this),"OnTakeDamage");