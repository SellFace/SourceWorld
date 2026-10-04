//VecCheckToss( this, this->EyePosition(), vecTarget, -1, 1.0, Vector(-4,-4,-4), Vector(4,4,4) );

const TOSS_HEIGHT_MAX=300

function VecCheckToss( thrower, vecSpot1, vecSpot2, flHeightMaxRatio, flGravityAdj, vecMins, vecMaxs )
{
	local tr=null
	local vecMidPoint=null;	// halfway point between Spot1 and Spot2
	local vecApex=null;	// highest point 
	local vecScale=null;
	local vecTossVel=Vector();
	local vecTemp=null;
	local flGravity = 600 * flGravityAdj;

	if (vecSpot2.z - vecSpot1.z > 500)
	{
		// to high, fail
		return false
	}
	
	if ((vecSpot2 - vecSpot1).Length() < 250)
	{
		// to close, fail
		return false
	}
	

	//Vector forward, right;
	//AngleVectors( pEntity->GetLocalAngles(), &forward, &right, NULL );

	// calculate the midpoint and apex of the 'triangle'
	// UNDONE: normalize any Z position differences between spot1 and spot2 so that triangle is always RIGHT
	// get a rough idea of how high it can be thrown
	
	local vecMidPoint = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5;
	//UTIL_TraceLine(vecMidPoint, vecMidPoint + Vector(0,0,TOSS_HEIGHT_MAX), MASK_SOLID_BRUSHONLY, pFilter, &tr);
	
	tr=TraceLineComplex(vecMidPoint, vecMidPoint + Vector(0,0,TOSS_HEIGHT_MAX),Entities.First(),MASK_SOLID_BRUSHONLY,0)
	
	vecMidPoint = tr.StartPos()+(tr.EndPos()-tr.StartPos())*tr.Fraction();

	if( tr.Fraction() != 1.0 )
	{
		// (subtract 32 so the object doesn't hit the ceiling)
		vecMidPoint.z -= 32;
	}

	
	if (flHeightMaxRatio != -1)
	{
		// But don't throw so high that it looks silly. Maximize the height of the
		// throw above the highest of the two endpoints to a ratio of the throw length.
		local flHeightMax = flHeightMaxRatio * (vecSpot2 - vecSpot1).Length();
		local flHighestEndZ = max(vecSpot1.z, vecSpot2.z);
		if ((vecMidPoint.z - flHighestEndZ) > flHeightMax)
		{
			vecMidPoint.z = flHighestEndZ + flHeightMax;
		}
	}

	if (vecMidPoint.z < vecSpot1.z || vecMidPoint.z < vecSpot2.z)
	{
		// Not enough space, fail
		return false
	}

	// How high should the object travel to reach the apex
	local distance1 = (vecMidPoint.z - vecSpot1.z);
	local distance2 = (vecMidPoint.z - vecSpot2.z);

	// How long will it take for the object to travel this distance
	local time1 = sqrt( distance1 / (0.5 * flGravity) );
	local time2 = sqrt( distance2 / (0.5 * flGravity) );

	if (time1 < 0.1)
	{
		// too close
		return false
	}

	// how hard to throw sideways to get there in time.
	vecTossVel = (vecSpot2 - vecSpot1) / (time1 + time2);

	// how hard upwards to reach the apex at the right time.
	vecTossVel.z = flGravity * time1;

	// find the apex
	vecApex  = vecSpot1 + vecTossVel * time1;
	vecApex.z = vecMidPoint.z;

	// JAY: Repro behavior from HL1 -- toss check went through gratings
	//UTIL_TraceLine(vecSpot1, vecApex, (MASK_SOLID&(~CONTENTS_GRATE)), pFilter, &tr);
	
	tr=TraceLineComplex(vecSpot1, vecApex,Entities.First(),(MASK_SOLID&(~CONTENTS_GRATE)),0)
	
	if (tr.Fraction() != 1.0)
	{
		// fail!
		return false
	}

	// UNDONE: either ignore NPCs or change it to not care if we hit our enemy
	
	/*
	UTIL_TraceLine(vecSpot2, vecApex, (MASK_SOLID_BRUSHONLY&(~CONTENTS_GRATE)), pFilter, &tr); 
	if (tr.fraction != 1.0)
	{
		// fail!
		return vec3_origin;
	}
	*/

	if ( vecMins && vecMaxs )
	{
		// Check to ensure the entity's hull can travel the first half of the grenade throw
		//UTIL_TraceHull( vecSpot1, vecApex, *vecMins, *vecMaxs, (MASK_SOLID&(~CONTENTS_GRATE)), pFilter, &tr);

		tr = TraceHullComplex(vecSpot1, vecApex, vecMins, vecMaxs, thrower, MASK_SHOT, 0)
		
		if ( tr.Fraction() < 1.0 )
			return false
	}

	return vecTossVel;
}