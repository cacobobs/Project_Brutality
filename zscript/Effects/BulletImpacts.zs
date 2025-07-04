Class PB_BaseBulletImpact : BulletPuff abstract
{
	Default
	{
		+NOEXTREMEDEATH;
		+THRUACTORS;
		+NOCLIP;
		Decal "ConcreteWithGlow";
		+DONTSPLASH;
		//+NOTIMEFREEZE;
		-EXPLODEONWATER;
		Scale 1.0;
        Alpha 1.0;
		Renderstyle "Translucent";
		PB_BaseBulletImpact.NoDistantImpact false;
		+NOGRAVITY;
		+NOINTERACTION;
		+NOBLOCKMAP;
		//+NOSECTOR;
		+ROLLSPRITE;
		+FORCEDECAL;
		-NODECAL;
		+ALLOWTHRUFLAGS;
		+ALLOWPARTICLES;
		+PUFFONACTORS;
		-RANDOMIZE;
	}

	uint8 hitWhat;
	float wallNormal, reflectAngle;
	float distfromplayer;

	bool noDistant, smallCal;
	property NoDistantImpact: noDistant;

	const DISTANT_THRESHOLD = 1024 ** 2;

    transient SecPlane refPlane;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		// ricochet detection formula: AbsAngle(angle, wallnormal)

		distfromplayer = Distance2DSquared(players[consoleplayer].mo);
		
		reflectAngle = (wallNormal * 2) - angle;

		if(!noDistant)
			HitFeedback();

        if(hitWhat > 1)
        {
            vector3 pNorm;
            if(hitWhat == 2)
                pNorm = floorSector.floorplane.normal;
            else
                pNorm = ceilingSector.ceilingplane.normal;
                
            pitch = asin(-pNorm.Z);
            angle = atan2(pNorm.y, pNorm.x);
		}
	}
	
	void HitFeedback()
	{
		FSpawnParticleParams MAINPUF;
		string f = String.Format("%c", int("A") + random[jtbs](0,7));
		MAINPUF.Texture = TexMan.CheckForTexture("IPF2"..f..0);
		MAINPUF.Style = STYLE_ADD;
		MAINPUF.Color1 = "FFFFFF";
		MAINPUF.Flags = SPF_FULLBRIGHT|SPF_ROLL;
		MAINPUF.StartRoll = random[jtbs](0,360);
		MAINPUF.StartAlpha = 1.0;
		MAINPUF.FadeStep = 0;
		MAINPUF.Size = random[jtbs](10,32) * (Distance3D(players[consoleplayer].mo) / 500.f);
		MAINPUF.SizeStep = random[jtbs](2,4);
		MAINPUF.Lifetime = 4; 
		MAINPUF.Pos = pos;
		Level.SpawnParticle(MAINPUF);
	}
}

Class PB_BulletImpact : PB_BaseBulletImpact
{
	color color1, color2, color3;
	// puff, debris and big smoke
	property PuffColors: color1, color2, color3;
	
	Default
	{
		PB_BulletImpact.PuffColors "FFFFFF", "FFFFFF", "C9C9C9";
		+FLATSPRITE;
		Scale 0.4;
		Alpha 0.5;
		RenderStyle "Stencil";
	}
	
	states
	{
		Spawn:
		Puff:
			TNT1 A 0 NoDelay {
				A_StartSound("bulletimpact", pitch: frandom(0.9, 1.1));

                if(distfromplayer < DISTANT_THRESHOLD)
                {
                    if(!smallCal)
                    {
						SpawnMainPuff2();
						// SpawnPuffSmoke();
                    	//LinetracerSmoke(hitWhat);
                    }

                    SpawnDust();

                    if(randompick[jtbs](0, 0, 1))
					{
                    	A_StartSound("ricochet/hit");
					}
					SpawnMainPuff3();
					SpawnMainPuff3();

					/*int cloudCount = randompick(0, 0, 0, 0, 0, 0, 1, 2, 3);
					for(int i = 0; i < cloudCount; i++)
						SpawnMainPuffSecondary();*/
                }
				SpawnMainPuff();
                SpawnPuffSmoke();
				
				if(smallCal) 
					scale *= 0.5;
				
				SetShade(color3);
				A_Stop();
				if(hitWhat == 1)
					angle = wallNormal;

				Pitch += 90;
				
				roll = random(0, 360);
			}
        FlatPuff:
			XS19 ABCDEFGHIJKLMNOP 1;
        	Stop;
		Melee:
			TNT1 AAA 0 SpawnPuffSmoke();//A_SpawnProjectile ("OldschoolRocketSmokeTrail2", 0, 0, random (0, 360), 2, random (0, 360));
			stop;
	}
	
	//anything that doesnt need to be an actor, is now not an actor
	void SpawnMainPuff()
	{
		FSpawnParticleParams PUFSPRK;
		PUFSPRK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");
		PUFSPRK.Color1 = color1;
		PUFSPRK.Style = STYLE_TRANSLUCENT;
		PUFSPRK.Flags = SPF_ROLL | SPF_REPLACE;
		vector3 vls = (0.7, frandom[jtbs](-0.5,0.5), frandom[jtbs](-0.5,0.5));
		if(hitWhat == 1)
		{
			vls = (RotateVector((vls.x, vls.y), wallNormal), vls.z);
		}
		else
		{
			vls = (vls.z, vls.y, vls.x);
		}
		PUFSPRK.Vel = (0, 0, 0);
		PUFSPRK.Startroll = random[jtbs](0, 359);
		PUFSPRK.RollVel = frandom[jtbs](-3, 3);
		PUFSPRK.StartAlpha = smallCal ? 0.6 : 0.4;
		PUFSPRK.Size = random[jtbs](25, 35);
		PUFSPRK.SizeStep = 1;
		PUFSPRK.Lifetime = random[jtbs](35,105); 
		PUFSPRK.RollAcc = -PUFSPRK.RollVel / double(PUFSPRK.Lifetime);
		PUFSPRK.accel = (-vls / double(PUFSPRK.Lifetime)) + (0, 0, frandom(-0.05, -0.1));
			
		PUFSPRK.FadeStep = -1;
		PUFSPRK.Pos = pos + vls * (PUFSPRK.Size * 0.3);
		Level.SpawnParticle(PUFSPRK);
	}

	void SpawnMainPuff3()
	{
		FSpawnParticleParams PUFSPRK;
		PUFSPRK.Texture = TexMan.CheckForTexture("XS13"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");
		PUFSPRK.Color1 = color3;
		PUFSPRK.Style = STYLE_TRANSLUCENT;
		PUFSPRK.Flags = SPF_ROLL | SPF_REPLACE;
		PUFSPRK.Size = smallCal ? random[jtbs](15,30) : random[jtbs](40, 50);
		vector3 vls = (frandom[jtbs](1, PUFSPRK.Size * 0.2), frandom[jtbs](-24,24), frandom[jtbs](-24,24));
		if(hitWhat == 1)
		{
			vls = (RotateVector((vls.x, vls.y), wallNormal), vls.z);
		}
		else
		{
			vls = (vls.z, vls.y, vls.x);
		}
		PUFSPRK.Vel = (frandom(0, 0), frandom(-1, 1), frandom(0, 1));
		PUFSPRK.Startroll = random[jtbs](0, 359);
		PUFSPRK.RollVel = frandom[jtbs](-3, 3);
		PUFSPRK.StartAlpha = smallCal ? 0.25 : 0.4;
		PUFSPRK.SizeStep = 1;
		PUFSPRK.Lifetime = random[jtbs](15,55); 
		PUFSPRK.RollAcc = -PUFSPRK.RollVel / double(PUFSPRK.Lifetime);
		PUFSPRK.accel = (0, 0, -0.05);
			
		PUFSPRK.FadeStep = -1;
		PUFSPRK.Pos = pos + vls;
		Level.SpawnParticle(PUFSPRK);
	}

	void SpawnMainPuff2()
	{
		FSpawnParticleParams PUFSPRK;
		double angOfs = frandom(0, 359);
		for(int i = 0; i < 3; i++)
		{
			PUFSPRK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");
			PUFSPRK.Color1 = color2;
			PUFSPRK.Style = STYLE_TRANSLUCENT;
			PUFSPRK.Flags = SPF_ROLL | SPF_REPLACE;
			PUFSPRK.Size = 16;
			vector3 vls = (PUFSPRK.Size * 0.3, RotateVector((8, 8), angOfs + 120 * (1 + i)));
			if(hitWhat == 1)
			{
				vls = (RotateVector((vls.x, vls.y), wallNormal), vls.z);
			}
			else
			{
				vls = (vls.z, vls.y, vls.x);
			}
			PUFSPRK.Vel = (0, 0, 0);
			PUFSPRK.Startroll = random[jtbs](0, 359);
			PUFSPRK.StartAlpha = 0.5;
			PUFSPRK.SizeStep = 2;
			PUFSPRK.Lifetime = random[jtbs](15,70); 
			PUFSPRK.accel = (0, 0,-0.05);
				
			PUFSPRK.FadeStep = -1;
			PUFSPRK.Pos = pos + vls;
			Level.SpawnParticle(PUFSPRK);
		}
	}
	
	void SpawnMainPuffSecondary()
	{
		FSpawnParticleParams PUFSPRK;
		PUFSPRK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");
		PUFSPRK.Color1 = randompick[jtbs](0, 1) ? color3 : color2;
		PUFSPRK.Style = STYLE_TRANSLUCENT;
		PUFSPRK.Flags = SPF_ROLL | SPF_REPLACE;
		
		PUFSPRK.Startroll = random[jtbs](0, 359);
		PUFSPRK.RollVel = frandom[jtbs](-2, 2);
		PUFSPRK.StartAlpha = frandom(0.2, 0.45);
		PUFSPRK.Size = random[jtbs](26, 100);
		PUFSPRK.SizeStep = 2;
		PUFSPRK.Lifetime = random[jtbs](250, 450); 
		PUFSPRK.RollAcc = -PUFSPRK.RollVel / double(PUFSPRK.Lifetime);

		vector3 vls = (PUFSPRK.Size * 0.35, frandom(-30, 30), frandom(-30, 30));

		if(hitWhat == 1)
		{
			vls = (RotateVector((vls.x, vls.y), wallNormal), vls.z);
		}
		else
		{
			vls = (vls.z, vls.y, vls.x);
		}
		
		if(hitWhat == 3)
			vls.z *= -1;
		
		PUFSPRK.Vel = vls.Unit() * 0.2;
		
		PUFSPRK.accel = (-PUFSPRK.Vel / double(PUFSPRK.Lifetime)) + (0, 0, -0.01);
		//if(CeilingPic == SkyFlatNum)
		//	PUFSPRK.accel += (-0.01, 0.02, 0.01);
			
		PUFSPRK.FadeStep = -1;
		PUFSPRK.Pos = pos + vls;
		Level.SpawnParticle(PUFSPRK);
	}
	
	void SpawnDust()
	{
		int sparkcount = random[jtbs](6,20);
		for(int i = 0; i < sparkcount; i++)
		{
			FSpawnParticleParams PUFSPRK;
			string f = String.Format("%c", int("A") + random[jtbs](0,3));
			PUFSPRK.Texture = TexMan.CheckForTexture("DUST"..f..0);
			PUFSPRK.Color1 = color2;
			PUFSPRK.Style = STYLE_TRANSLUCENT;
			PUFSPRK.Flags = SPF_ROLL;
			vector3 vls;
			if(hitWhat == 1)
				vls = (RotateVector(((frandom[jtbs](1, 6)), frandom[jtbs](-5,5)), wallNormal), frandom[jtbs](-5,5));
			else
				vls = (random[jtbs](-5,5),random[jtbs](-5,5),random[jtbs](-1,9));

			PUFSPRK.Vel = vls;
			PUFSPRK.accel = (0,0,frandom[jtbs](-1.75,-0.75));
			PUFSPRK.Startroll = randompick[jtbs](0,90,180,270,360);
			PUFSPRK.RollVel = 0;
			PUFSPRK.StartAlpha = 1.0;
			PUFSPRK.FadeStep = 0.075;
			PUFSPRK.Size = random[jtbs](4,6);
			PUFSPRK.SizeStep = 0;
			PUFSPRK.Lifetime = random[jtbs](12,18); 
			if(hitWhat == 1)
				PUFSPRK.Pos = pos + (RotateVector((frandom[jtbs](0, 6), frandom[jtbs](-5,5)), wallNormal), frandom[jtbs](-5,5));
			else
				PUFSPRK.Pos = pos + (frandom[jtbs](-5,5), frandom[jtbs](-5,5), frandom[jtbs](0,6));
				
			Level.SpawnParticle(PUFSPRK);
		}
	}

	void SpawnPuffSmoke()
	{
		double mag = !smallCal ? frandom[jtbs](3, 4) : 2;
		vector2 vvels = (frandom[jtbs](-1, 1), frandom[jtbs](-1, 1));
		int count = !smallCal ? 4 : 2;

		for(int i = 0; i < count; i++) {
			FSpawnParticleParams PUFSMK;
			PUFSMK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");//("SMK2A0"); //SMk3G0
			PUFSMK.Style = STYLE_TRANSLUCENT;
			PUFSMK.Color1 = color2;
			vector3 vls, accl, posOfs;
			vls = (mag * (i * 0.5), vvels);
			
			int ofsimpact = !smallCal ? 10 : 2;
			PUFSMK.Size = 10 * (1+((count - i) * 0.3));
			if(hitWhat == 1)
			{
				vls = (RotateVector(vls.xy, wallNormal), vls.z);
			
				accl = -(vls.xy * 0.07, 0.1);
				posofs = (RotateVector((ofsimpact+(pufsmk.size * (i / float(count))), vvels.x * (i / 3.0)), wallNormal), vvels.y * (i / 3.0));
			} 
			else if(hitWhat > 1)
			{
                vls = (vls.y, vls.z, vls.x);
                
                accl = -(0, 0, (0.3 * i));
                posOfs = (vvels * (i * 0.3), ofsimpact+(i*2));

				if(hitWhat == 3)
                {
					vls.z *= -1;
					posOfs.z *= -1;
                    accl.z *= -1;
                }
			}
			else
			{
				vls = (frandom[jtbs](-1,1), frandom[jtbs](-1,1), 0);
				accl = -(vls.xy * 0.07, (0.1 * i));
			}
			PUFSMK.vel = vls * (i / double(count));
			PUFSMK.accel = accl;
			if(CeilingPic == SkyFlatNum)
				PUFSMK.accel += (-0.05, 0.1, 0.05);
				
			PUFSMK.Flags = SPF_ROLL;
			PUFSMK.StartRoll = random[jtbs](0,360);
			PUFSMK.RollVel = random[jtbs](-4,4);
			PUFSMK.StartAlpha = 0.6;
			PUFSMK.FadeStep = -1;
			PUFSMK.SizeStep = random[jtbs](1,5);
			PUFSMK.Lifetime = 13; 
			PUFSMK.Pos = pos + posOfs;
			Level.SpawnParticle(PUFSMK);
		}
	}

	// "rubble"
	void LinetracerSmoke(int dq = 1)
	{
		FLineTraceData lt;
		vector2 ofs = RotateVector((2, 0), wallNormal);
		
		if(dq == 1)
			LineTrace(wallNormal + 87, 60, random(0, 360), TRF_ABSOFFSET, offsetforward: ofs.x, ofs.y, lt);
		else if(dq == 2)
			LineTrace(random(0, 360), 60, -3, TRF_ABSOFFSET, offsetforward: ofs.x, ofs.y, lt);
		else if(dq == 2)
			LineTrace(random(0, 360), 60, 3, TRF_ABSOFFSET, offsetforward: ofs.x, ofs.y, lt);

		if(lt.HitType == TRACE_HitNone)
			return;
		
		FSpawnParticleParams PUFSMK;
		PUFSMK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");//("SMK2A0"); //SMk3G0
		PUFSMK.Style = STYLE_TRANSLUCENT;
		PUFSMK.Color1 = "c9c9c9";
		PUFSMK.Flags = SPF_ROLL;
		PUFSMK.Vel = (frandom(-1, 1), frandom(-1, 1), frandom(-1, 1));
		PUFSMK.accel = (0, 0, 0);
		if(CeilingPic == SkyFlatNum)
			PUFSMK.accel += (-0.05, 0.1, 0.05);
		PUFSMK.Startroll = random[jtbs](0, 359);
		PUFSMK.RollVel = frandom[jtbs](1, 2);
		PUFSMK.StartAlpha = 0.6;
		PUFSMK.FadeStep = -1;
		PUFSMK.Size = random[jtbs](60,80);
		PUFSMK.SizeStep = 4;
		PUFSMK.Lifetime = random[jtbs](6,15); 
		PUFSMK.Pos = lt.HitLocation;
		Level.SpawnParticle(PUFSMK);
	}
}

Class PB_BulletImpactWood : PB_BaseBulletImpact
{
	Default
	{
		Decal "WoodBullethole";
	}
	
	states
	{
		Spawn:
		Puff:
			TNT1 A 0 NoDelay {
				A_StartSound("bulletimpact/wood", pitch: frandom(0.9, 1.1));
                if(random(0, 100) < 25) A_StartSound("ricochet/hit");

                if(distfromplayer < DISTANT_THRESHOLD)
                {
                    SpawnSplinters();
                    SpawnPuffSmoke();
                }
				SpawnMainPuff();
			}
            //TNT1 A 2 Light("BulletPuffLight");
            Stop;
		Melee:
			TNT1 AAA 0 SpawnPuffSmoke();//A_SpawnProjectile ("OldschoolRocketSmokeTrail2", 0, 0, random (0, 360), 2, random (0, 360));
			stop;
	}
	
	//anything that doesnt need to be an actor, is now not an actor
	void SpawnMainPuff()
	{
		FSpawnParticleParams PUFSPRK;
		PUFSPRK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");
		PUFSPRK.Color1 = "40291a";
		PUFSPRK.Style = STYLE_TRANSLUCENT;
		PUFSPRK.Flags = SPF_ROLL;
		vector3 vls;
		if(hitWhat == 1)
		{
			vls = (RotateVector((1, 0), wallNormal), 0);
		}
		else
		{
			vls = (0,0,0.5);
		}
		PUFSPRK.Vel = vls;
		PUFSPRK.accel = (0,0,frandom[jtbs](-0.1, 0.1));
		if(CeilingPic == SkyFlatNum)
			PUFSPRK.accel += (-0.05, 0.1, 0.05);

		PUFSPRK.Startroll = random[jtbs](0, 359);
		PUFSPRK.RollVel = frandom[jtbs](1, 2);
		PUFSPRK.StartAlpha = 0.7;
		PUFSPRK.FadeStep = -1;
		PUFSPRK.Size = random[jtbs](40,45);
		PUFSPRK.SizeStep = 0.5;
		PUFSPRK.Lifetime = random[jtbs](24,35); 
		PUFSPRK.Pos = pos;
		Level.SpawnParticle(PUFSPRK);
	}
	
	void SpawnSplinters()
	{
		int sparkcount = random[jtbs](8,10);
		for(int i = 0; i < sparkcount; i++)
		{
			FSpawnParticleParams PUFSPRK;
			string f = String.Format("%c", int("A") + random[jtbs](0,3));
			PUFSPRK.Texture = TexMan.CheckForTexture("WOOD"..f..0);
			PUFSPRK.Color1 = "FFFFFF";
			PUFSPRK.Style = STYLE_TRANSLUCENT;
			PUFSPRK.Flags = SPF_ROLL;
			vector3 vls;
			if(hitWhat == 1)
			{
				vls = (RotateVector(((frandom[jtbs](1, 3) * (i * 0.5)), frandom[jtbs](-2,2)), wallNormal), frandom[jtbs](-2,2));
			}
			else
			{
				vls = (random[jtbs](-5,5),random[jtbs](-5,5),random[jtbs](-2,9));
			}
			PUFSPRK.Vel = vls;
			PUFSPRK.accel = (0,0,-0.5);
			PUFSPRK.Startroll = random[jtbs](0, 359);
			PUFSPRK.RollVel = 2;
			PUFSPRK.StartAlpha = 1.0;
			PUFSPRK.FadeStep = 0.075;
			PUFSPRK.Size = random[jtbs](4,6);
			PUFSPRK.SizeStep = 0;
			PUFSPRK.Lifetime = random[jtbs](12,18); 
			PUFSPRK.Pos = pos;
			Level.SpawnParticle(PUFSPRK);
		}
	}

	void SpawnPuffSmoke(int dq = 1)
	{
		for(int i = 0; i < 3; i++) {
			FSpawnParticleParams PUFSMK;
			PUFSMK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");//("SMK2A0"); //SMk3G0
			PUFSMK.Style = STYLE_TRANSLUCENT;
			PUFSMK.Color1 = "40291a";
			vector3 vls, accl;
			if(hitWhat == 1)
			{
				vls = (RotateVector(((frandom[jtbs](0, 6) * (i * 0.5)), frandom[jtbs](-1,1)), wallNormal), frandom[jtbs](-3,2));
				accl = -(vls.xy * 0.07, (0.1 * i));
			} 
			else if(hitWhat >= 2)
			{
				vls.xy = (frandom[jtbs](-2,2), frandom[jtbs](-2,2));
				vls.z = 4 * (i * 0.5);
                accl = -(0, 0, (0.3 * i));

				if(hitWhat == 3)
                {
					vls.z *= -1;
                    accl.z *= -1;
                }
			}
			else
			{
				vls = (frandom[jtbs](-1,1), frandom[jtbs](-1,1), 0);
				accl = -(vls.xy * 0.07, (0.1 * i));
			}
			PUFSMK.vel = vls;
			PUFSMK.accel = accl;
			if(CeilingPic == SkyFlatNum)
				PUFSMK.accel += (-0.05, 0.1, 0.05);

			PUFSMK.Flags = SPF_ROLL;
			PUFSMK.StartRoll = random[jtbs](0,360);
			PUFSMK.RollVel = random[jtbs](-4,4);
			PUFSMK.StartAlpha = 1.0;
			PUFSMK.FadeStep = 0.1;
			PUFSMK.Size = random[jtbs](28,32);
			PUFSMK.SizeStep = random[jtbs](1,3);
			PUFSMK.Lifetime = 10; 
			vector2 posofs = RotateVector((5, 0), wallNormal);
			PUFSMK.Pos = vec3Offset(posofs.x, posofs.y, 0);
			Level.SpawnParticle(PUFSMK);
		}
	}
}

Class PB_BulletImpactMetal : PB_BaseBulletImpact
{
	Default {
		Decal "MetalWithGlow";
		PB_BaseBulletImpact.NoDistantImpact true;
	}
	states
	{
		Spawn:
			TNT1 A 0 NoDelay {
				Angle = wallNormal;
				
				for(int i = 0; i < 4; i++)
					A_SpawnProjectile("SparkX", 0, 0, random (-25, 25), CMF_AIMDIRECTION  , pitch+random (-25, 25));
					
				A_SpawnProjectile("HitSpark", 0, 0, random (-25, 25), CMF_AIMDIRECTION  , pitch+random (-25, 25));
				A_SpawnProjectile("HitSpark22", 0, 0, frandom (-45, 45), CMF_AIMDIRECTION  , pitch+frandom(-45, 45));
				A_SpawnProjectile("HitSpark23", 0, 0, frandom (-180, 180), CMF_AIMDIRECTION  , pitch+frandom(-180, 180));
			}
		Puff:
			TNT1 A 0 {
                A_StartSound("bulletimpact/metal/a", pitch: frandom(0.9, 1.1));
                if(random(0, 100) < 25) A_StartSound("ricochet/hit");

                if(distfromplayer < DISTANT_THRESHOLD)
                {
                    SpawnPuffSpark();
                    SpawnPuffShrapnel();
					
					//for(int i = 0; i < 3; i++)
						SpawnPuffSmoke();
                }
				SpawnMainPuff();
			}
			TNT1 A 2 Light("BulletPuffLight");
			stop;
		Melee:
			TNT1 AAA 0 SpawnPuffSmoke();//A_SpawnProjectile ("OldschoolRocketSmokeTrail2", 0, 0, random (0, 360), 2, random (0, 360));
			stop;
	}
	
	//anything that doesnt need to be an actor, is now not an actor
	void SpawnMainPuff()
	{
		FSpawnParticleParams MAINPUF;
		string f = String.Format("%c", int("A") + random[jtbs](0,7));
		MAINPUF.Texture = TexMan.CheckForTexture("IPF2"..f..0);
		MAINPUF.Style = STYLE_ADD;
		MAINPUF.Color1 = "FFFFFF";
		MAINPUF.Flags = SPF_FULLBRIGHT|SPF_ROLL;
		MAINPUF.StartRoll = random[jtbs](0,360);
		MAINPUF.StartAlpha = 1.0;
		MAINPUF.FadeStep = 0;
		MAINPUF.Size = random[jtbs](25,28);
		MAINPUF.SizeStep = random[jtbs](2,4);
		MAINPUF.Lifetime = 4; 
		MAINPUF.Pos = pos;
		Level.SpawnParticle(MAINPUF);
	}

    void SpawnPuffSpark()
	{
        int sparkcount = random[jtbs](3,5);
        for(int i = 0; i < sparkcount; i++)
        {
            FSpawnParticleParams PUFSPRK;
            PUFSPRK.Texture = TexMan.CheckForTexture("SPKOA0");
            PUFSPRK.Color1 = "FFFFFF";
            PUFSPRK.Style = STYLE_Add;
            PUFSPRK.Flags = SPF_ROLL|SPF_FULLBRIGHT;
            vector3 vls;
			if(hitWhat == 1)
			{
				vls = (RotateVector(((frandom[jtbs](2, 7) * (i * 0.5)), frandom[jtbs](-6,6)), wallNormal), frandom[jtbs](-2,2));
			}
			else
			{
				vls = (random[jtbs](-5,5),random[jtbs](-5,5),random[jtbs](-2,9));
			}
            PUFSPRK.Vel = vls;
            PUFSPRK.accel = (-(vls.xy * 0.075),-0.2) + (frandom[jtbs](-0.25, 0.25), frandom[jtbs](-0.25,0.25), frandom[jtbs](-0.2,0.1));
            PUFSPRK.Startroll = random[jtbs](0,359);
            PUFSPRK.RollVel = 0;
            PUFSPRK.StartAlpha = 1.0;
            PUFSPRK.FadeStep = 0.075;
            PUFSPRK.Size = random[jtbs](6,8);
            PUFSPRK.SizeStep = -0.5;
            PUFSPRK.Lifetime = random[jtbs](12,18); 
            PUFSPRK.Pos = pos;
            Level.SpawnParticle(PUFSPRK);
        }
	}

    void SpawnPuffShrapnel()
	{
        if(randompick[jtbs](0, 0, 0, 0, 1))
            return;

        FSpawnParticleParams PUFSHRP;
        string f = String.Format("%c", int("A") + random[jtbs](0,7));
        PUFSHRP.Texture = TexMan.CheckForTexture("JNK3"..f..0);
        PUFSHRP.Color1 = "FFFFFF";
        PUFSHRP.Style = STYLE_TRANSLUCENT;
        PUFSHRP.Flags = SPF_ROLL;
        vector3 vls;
        if(hitWhat == 1)
        {
            vls = (RotateVector(((frandom[jtbs](5, 7)), frandom[jtbs](-4,4)), wallNormal), frandom[jtbs](-4,4));
        }
        else
        {
            vls = (random[jtbs](-5,5),random[jtbs](-5,5),random[jtbs](-2,9));
        }
        PUFSHRP.Vel = vls;
        PUFSHRP.accel = (-(vls.xy * 0.05),-1);
        PUFSHRP.Startroll = random[jtbs](0, 359);
        PUFSHRP.RollVel = 1.5;
        PUFSHRP.StartAlpha = 1.0;
        PUFSHRP.FadeStep = -1;
        PUFSHRP.Size = random[jtbs](4,8);
        PUFSHRP.SizeStep = 0;
        PUFSHRP.Lifetime = 24; 
        PUFSHRP.Pos = pos;
        Level.SpawnParticle(PUFSHRP);
	}
	
	void SpawnPuffSmoke()
	{
		double mag = frandom[jtbs](4, 5);
		vector2 vvels = (frandom[jtbs](-1, 1), frandom[jtbs](-1, 1));
		int count = !smallCal ? 4 : 2;

		for(int i = 0; i < count; i++) {
			FSpawnParticleParams PUFSMK;
			PUFSMK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");//("SMK2A0"); //SMk3G0
			PUFSMK.Style = STYLE_TRANSLUCENT;
			PUFSMK.Color1 = "6e6e6e";
			vector3 vls, accl, posOfs;
			vls = (mag * (i * 0.5), vvels);
			
			int ofsimpact = !smallCal ? 10 : 2;
			if(hitWhat == 1)
			{
				vls = (RotateVector(vls.xy, wallNormal), vls.z);
			
				accl = -(vls.xy * 0.07, 0.1);
				posofs = (RotateVector((ofsimpact+(i*2), vvels.x * (i / 3.0)), wallNormal), vvels.y * (i / 3.0));
			} 
			else if(hitWhat > 1)
			{
				vls = (vls.y, vls.z, vls.x);
				
				accl = -(0, 0, (0.3 * i));
				posOfs = (vvels * (i * 0.3), ofsimpact+(i*2));

				if(hitWhat == 3)
				{
					vls.z *= -1;
					posOfs.z *= -1;
					accl.z *= -1;
				}
			}
			else
			{
				vls = (frandom[jtbs](-1,1), frandom[jtbs](-1,1), 0);
				accl = -(vls.xy * 0.07, (0.1 * i));
			}
			PUFSMK.vel = vls * (i / double(count));
			PUFSMK.accel = accl;
			if(CeilingPic == SkyFlatNum)
				PUFSMK.accel += (-0.05, 0.1, 0.05);
				
			PUFSMK.Flags = SPF_ROLL;
			PUFSMK.StartRoll = random[jtbs](0,360);
			PUFSMK.RollVel = random[jtbs](-4,4);
			PUFSMK.StartAlpha = 0.6;
			PUFSMK.FadeStep = -1;
			PUFSMK.Size = 12 * ((1 + i * 0.3) * 2);
			PUFSMK.SizeStep = random[jtbs](1,3);
			PUFSMK.Lifetime = 13; 
			PUFSMK.Pos = pos + posOfs;
			Level.SpawnParticle(PUFSMK);
		}
	}
}

Class PB_BulletImpactSheetMetal : PB_BulletImpactMetal
{
	states
	{
        Spawn:
		Puff:
			TNT1 A 0 NoDelay {
                A_StartSound("bulletimpact/metal/b", pitch: frandom(0.9, 1.1));
                if(random(0, 100) < 25) A_StartSound("ricochet/hit");

                if(distfromplayer < DISTANT_THRESHOLD)
                {
                    SpawnPuffSpark();
                    SpawnPuffShrapnel();
					
                    //for(int i = 0; i < 3; i++)
						SpawnPuffSmoke();
                }
				SpawnMainPuff();
			}
			TNT1 A 2 Light("BulletPuffLight");
			stop;
	}
}

Class PB_BulletImpactDirt : PB_BaseBulletImpact
{
	Default
	{
		Renderstyle "Shaded";
		StencilColor "865627";
		Alpha 1.0;
	}
	
	states
	{
		Spawn:
		Puff:
			TNT1 A 0 NoDelay {
				A_StartSound("bulletimpact/wood", pitch: frandom(0.9, 1.1));
                if(random(0, 100) < 25) A_StartSound("ricochet/hit");

                if(distfromplayer < DISTANT_THRESHOLD)
                {
                    SpawnSplinters();
                    SpawnPuffSmoke();
                }
				SpawnMainPuff();
			}
            //DCHR ABCDEFGHIJKMNOP 1;
            Stop;
		Melee:
			TNT1 AAA 0 SpawnPuffSmoke();//A_SpawnProjectile ("OldschoolRocketSmokeTrail2", 0, 0, random (0, 360), 2, random (0, 360));
			stop;
	}
	
	//anything that doesnt need to be an actor, is now not an actor
	void SpawnMainPuff()
	{
		FSpawnParticleParams PUFSPRK;
		PUFSPRK.Texture = TexMan.CheckForTexture("DIRPC0");
		PUFSPRK.Color1 = "FFFFFF";
		PUFSPRK.Style = STYLE_TRANSLUCENT;
		PUFSPRK.Flags = SPF_ROLL;
		vector3 vls;
		if(hitWhat == 1)
		{
			vls = (RotateVector((4, 0), wallNormal), 0);
		}
		else
		{
			vls = (0,0,2);
		}
		PUFSPRK.Vel = vls;
		PUFSPRK.accel = (0,0,frandom[jtbs](-0.1, 0.1));
		if(CeilingPic == SkyFlatNum)
			PUFSPRK.accel += (-0.05, 0.1, 0.05);

		PUFSPRK.Startroll = random[jtbs](0, 359);
		PUFSPRK.RollVel = 5;
		PUFSPRK.StartAlpha = 1.0;
		PUFSPRK.FadeStep = -1;
		PUFSPRK.Size = random[jtbs](30,75);
		PUFSPRK.SizeStep = 6;
		PUFSPRK.Lifetime = random[jtbs](4,7); 
		PUFSPRK.Pos = pos;
		Level.SpawnParticle(PUFSPRK);
	}
	
	void SpawnSplinters()
	{
		int sparkcount = random[jtbs](8,10);
		for(int i = 0; i < sparkcount; i++)
		{
			FSpawnParticleParams PUFSPRK;
			string f = String.Format("%c", int("A") + random[jtbs](0,3));
			PUFSPRK.Texture = TexMan.CheckForTexture("DUST"..f..0);
			PUFSPRK.Color1 = "865627";
			PUFSPRK.Style = STYLE_TRANSLUCENT;
			PUFSPRK.Flags = SPF_ROLL;
			vector3 vls;
			if(hitWhat == 1)
			{
				vls = (RotateVector(((frandom[jtbs](1, 3) * (i * 0.5)), frandom[jtbs](-2,2)), wallNormal), frandom[jtbs](-2,2));
			}
			else
			{
				vls = (random[jtbs](-5,5),random[jtbs](-5,5),random[jtbs](-2,9));
			}
			PUFSPRK.Vel = vls;
			PUFSPRK.accel = (0,0,-2);
			PUFSPRK.Startroll = random[jtbs](0, 359);
			PUFSPRK.RollVel = 2;
			PUFSPRK.StartAlpha = 1.0;
			PUFSPRK.FadeStep = 0.075;
			PUFSPRK.Size = random[jtbs](4,6);
			PUFSPRK.SizeStep = 0;
			PUFSPRK.Lifetime = random[jtbs](12,18); 
			PUFSPRK.Pos = pos;
			Level.SpawnParticle(PUFSPRK);
		}
	}

	void SpawnPuffSmoke(int dq = 1)
	{
		for(int i = 0; i < 3; i++) {
			FSpawnParticleParams PUFSMK;
			PUFSMK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");//("SMK2A0"); //SMk3G0
			PUFSMK.Style = STYLE_TRANSLUCENT;
			PUFSMK.Color1 = "865627";
			vector3 vls, accl;
			if(hitWhat == 1)
			{
				vls = (RotateVector(((frandom[jtbs](5, 7) * (i * 0.5)), frandom[jtbs](-1,1)), wallNormal), frandom[jtbs](-3,2));
				accl = -(vls.xy * 0.07, 0);
			} 
			else if(hitWhat >= 2)
			{
				vls.xy = (frandom[jtbs](-2,2), frandom[jtbs](-2,2));
				vls.z = 7 * (i * 0.5);
                accl = -(0, 0, (0.3 * i));

				if(hitWhat == 3)
                {
					vls.z *= -1;
                    accl.z *= -1;
                }
			}
			else
			{
				vls = (frandom[jtbs](-1,1), frandom[jtbs](-1,1), 0);
				accl = -(vls.xy * 0.07, (0.1 * i));
			}
			PUFSMK.vel = vls;
			PUFSMK.accel = accl;
			if(CeilingPic == SkyFlatNum)
				PUFSMK.accel += (-0.05, 0.1, 0.05);
			PUFSMK.Flags = SPF_ROLL;
			PUFSMK.StartRoll = random[jtbs](0,360);
			PUFSMK.RollVel = random[jtbs](-4,4);
			PUFSMK.StartAlpha = 1.0;
			PUFSMK.FadeStep = -1;
			PUFSMK.Size = random[jtbs](28,32);
			PUFSMK.SizeStep = 3;
			PUFSMK.Lifetime = 10; 
			vector2 posofs = RotateVector((5, 0), angle);
			PUFSMK.Pos = vec3Offset(posofs.x, posofs.y, 0);
			Level.SpawnParticle(PUFSMK);
		}
	}
}

Class PB_BulletImpactBrownRock : PB_BulletImpact
{
	Default
	{
		PB_BulletImpact.PuffColors "533f2f", "6b4727", "7b634f";
	}
}

Class PB_BulletImpactWater : PB_BaseBulletImpact
{
	color waterColor;
    property WaterColor: waterColor;

    Default
    {
        PB_BulletImpactWater.WaterColor "FFFFFF";
        PB_BaseBulletImpact.NoDistantImpact true;
    }

    states
	{
		Spawn:
		Puff:
			TNT1 A 0 NoDelay {
				A_StartSound("bulletimpact/water", pitch: frandom(0.9, 1.1));
                if(random(0, 100) < 25) A_StartSound("ricochet/hit");

                if(distfromplayer < DISTANT_THRESHOLD)
                {
                    SpawnDust();
                    SpawnPuffSmoke();
                }
				SpawnMainPuff();
			}
            Stop;
		Melee:
			TNT1 AAA 0 SpawnPuffSmoke();//A_SpawnProjectile ("OldschoolRocketSmokeTrail2", 0, 0, random (0, 360), 2, random (0, 360));
			stop;
	}
	
	//anything that doesnt need to be an actor, is now not an actor
	void SpawnMainPuff()
	{
		FSpawnParticleParams PUFSPRK;
		PUFSPRK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");
		PUFSPRK.Color1 = waterColor;
		PUFSPRK.Style = STYLE_ADD;
		PUFSPRK.Flags = SPF_ROLL;
		vector3 vls;
		if(hitWhat == 1)
		{
			vls = (RotateVector((2, 0), wallNormal), 0);
		}
		else
		{
			vls = (0,0,4);
		}
		PUFSPRK.Vel = vls;
		PUFSPRK.accel = (0,0,frandom[jtbs](-0.1, 0.1));
		PUFSPRK.Startroll = random[jtbs](0, 359);
		PUFSPRK.RollVel = frandom[jtbs](1, 2);
		PUFSPRK.StartAlpha = 0.7;
		PUFSPRK.FadeStep = -1;
		PUFSPRK.Size = random[jtbs](10,30);
		PUFSPRK.SizeStep = 6;
		PUFSPRK.Lifetime = random[jtbs](6,8); 
		PUFSPRK.Pos = pos;
		Level.SpawnParticle(PUFSPRK);
	}
	
	void SpawnDust()
	{
		int sparkcount = random[jtbs](7,9);
		for(int i = 0; i < sparkcount; i++)
		{
			FSpawnParticleParams PUFSPRK;
			string f = String.Format("%c", int("A") + random[jtbs](0,3));
			PUFSPRK.Texture = TexMan.CheckForTexture("LIQU"..f..0);
			PUFSPRK.Color1 = waterColor;
			PUFSPRK.Style = STYLE_ADD;
			PUFSPRK.Flags = SPF_ROLL;
			vector3 vls;
			if(hitWhat == 1)
			{
				vls = (RotateVector(((frandom[jtbs](3, 4) * (i * 0.5)), frandom[jtbs](-5,5)), wallNormal), frandom[jtbs](-2,3));
			}
			else
			{
				vls = (random[jtbs](-5,5),random[jtbs](-5,5),random[jtbs](2,9));
			}
			PUFSPRK.Vel = vls;
			PUFSPRK.accel = (0,0,frandom[jtbs](-1.75,-0.75));
			PUFSPRK.Startroll = randompick[jtbs](0,90,180,270,360);
			PUFSPRK.RollVel = 0;
			PUFSPRK.StartAlpha = 1.0;
			PUFSPRK.FadeStep = 0.075;
			PUFSPRK.Size = random[jtbs](4,6);
			PUFSPRK.SizeStep = 3;
			PUFSPRK.Lifetime = random[jtbs](12,18); 
			PUFSPRK.Pos = pos + (RotateVector((frandom[jtbs](-5, 5), frandom[jtbs](-5, 5)), wallNormal), frandom[jtbs](-3,3));
			Level.SpawnParticle(PUFSPRK);
		}
	}

	void SpawnPuffSmoke(int dq = 1)
	{
		for(int i = 0; i < 4; i++) {
			FSpawnParticleParams PUFSMK;
			PUFSMK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");//("SMK2A0"); //SMk3G0
			PUFSMK.Style = STYLE_ADD;
			PUFSMK.Color1 = waterColor;
			vector3 vls, accl;
			if(hitWhat == 1)
			{
				vls = (RotateVector((0, frandom[jtbs](-5,5)), wallNormal), frandom[jtbs](-5,5));
				accl = -(vls.xy * 0.07, (0.1 * i));
			} 
			else if(hitWhat >= 2)
			{
				vls.xy = (frandom[jtbs](-2,2), frandom[jtbs](-2,2));
				vls.z = 4 * (i * 0.5);
                accl = -(0, 0, (0.3 * i));

				if(hitWhat == 3)
                {
					vls.z *= -1;
                    accl.z *= -1;
                }
			}
			else
			{
				vls = (frandom[jtbs](-5,5), frandom[jtbs](-5,5), 0);
				accl = -(vls.xy * 0.07, (0.1 * i));
			}
			PUFSMK.vel = vls;
			PUFSMK.accel = accl;
			PUFSMK.Flags = SPF_ROLL;
			PUFSMK.StartRoll = random[jtbs](0,360);
			PUFSMK.RollVel = random[jtbs](-4,4);
			PUFSMK.StartAlpha = 0.8;
			PUFSMK.FadeStep = -1;
			PUFSMK.Size = random[jtbs](28,32);
			PUFSMK.SizeStep = 5;
			PUFSMK.Lifetime = 10; 
			vector2 posofs = RotateVector((frandom[jtbs](-10, 10), frandom[jtbs](-10, 10)), angle);
			PUFSMK.Pos = vec3Offset(posofs.x, posofs.y, 0);
			Level.SpawnParticle(PUFSMK);
		}
	}
}

class PB_BulletImpactBlood : PB_BulletImpactWater
{
    Default {
        PB_BulletImpactWater.WaterColor "FF0000";
    }
}

class PB_BulletImpactSlime : PB_BulletImpactWater
{
    Default {
        PB_BulletImpactWater.WaterColor "533f1f";
    }
}

class PB_BulletImpactNukage : PB_BulletImpactWater
{
    Default {
        PB_BulletImpactWater.WaterColor "3f832f";
    }
}

Class PB_NoBloodPuff : PB_BaseBulletImpact
{
	states
	{
		Spawn:
		Puff:
			TNT1 A 0 NoDelay {
				A_StartSound("bulletimpact", pitch: frandom(0.9, 1.1));

                if(distfromplayer < DISTANT_THRESHOLD)
                {
                	SpawnMainPuff();
                    SpawnMainPuff();
            	}
            	
				SpawnMainPuff();
			}
        	Stop;
		Melee:
			TNT1 A 0;
			stop;
	}
	
	//anything that doesnt need to be an actor, is now not an actor
	void SpawnMainPuff()
	{
		FSpawnParticleParams PUFSPRK;
		PUFSPRK.Texture = TexMan.CheckForTexture("X103"..String.Format("%c", 97 + random[jtbs](0, 25)).."0");
		PUFSPRK.Color1 = "FFFFFF";
		PUFSPRK.Style = STYLE_TRANSLUCENT;
		PUFSPRK.Flags = SPF_ROLL | SPF_REPLACE;
		vector3 vls = (frandom[jtbs](-1.0, 1.0), frandom[jtbs](-1.0, 1.0), frandom[jtbs](-1.0, 1.0));
		PUFSPRK.Vel = vls;
		PUFSPRK.Startroll = random[jtbs](0, 359);
		PUFSPRK.RollVel = frandom[jtbs](-10, 10);
		PUFSPRK.StartAlpha = 0.6;
		PUFSPRK.Size = random[jtbs](20,30);
		PUFSPRK.SizeStep = 1;
		PUFSPRK.Lifetime = random[jtbs](25,35); 
		PUFSPRK.RollAcc = 0;
		
		PUFSPRK.accel = (0, 0,-0.05) - (vls * (1.0 / double(PUFSPRK.Lifetime)));
		if(CeilingPic == SkyFlatNum)
			PUFSPRK.accel += (-0.05, 0.1, 0.05);
			
		PUFSPRK.FadeStep = -1;
		PUFSPRK.Pos = pos;
		Level.SpawnParticle(PUFSPRK);
	}
}