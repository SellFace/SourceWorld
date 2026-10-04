lockTime <- 0.0
lockRevert <- false
lockRate <- 0.05

function OnBind()
{
    if (lockTime < Time())
    {
        local scale = self.GetVarFloat(1)

        printl("VScriptProxy: Scale is " + scale)
        printl("VScriptProxy: Material is " + self.GetVarString(2))

        if (!lockRevert)
        {
            scale += lockRate

            if (scale >= 3.0)
            {
                lockTime = (Time() + 2.0)
                lockRate = RandomFloat(0.01,0.075)
                lockRevert = true
            }
        }
        else
        {
            scale -= lockRate

            if (scale <= 0.5)
            {
                lockTime = (Time() + 2.0)
                lockRate = RandomFloat(0.01,0.075)
                lockRevert = false
            }
        }

        self.SetVarFloat(1, scale)
		local rng=(Time()%4).tointeger()
		switch(rng)
		{
        case 0:self.SetVarString(2, "Metal");break;
        case 1:self.SetVarString(2, "Dirt");break;
        case 2:self.SetVarString(2, "Wood");break;
        case 3:self.SetVarString(2, "Concrete");break;
		}
    }
}