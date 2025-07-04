//Thrown monsters for monster fatalities.

Class ThrowedZman : Actor
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 24;
		Fastspeed 32;
		Damage 60;
		+MISSILE;
		Scale 1.0;
		+FORCEXYBILLBOARD;
		+THRUACTORS;
		-NOGRAVITY;
		+NOEXTREMEDEATH;
		Gravity 0.4;
		DamageType "Kick";
		Decal "BrutalBloodSuper";
	}
	
	States
	{
		Spawn:
			X721 A 2;
			TNT1 A 0 A_ChangeFlag("THRUACTORS", 0);
		Fly:
			X721 BCDEFGH 2;
			Loop;
		
		Death:
			TNT1 AAAAAA 0 A_SpawnItem("MuchBlood2");
			TNT1 A 0 A_SpawnItem("DeadZombieman1");
			TNT1 A 3;
			Stop;
	}
}

class ThrowedZombieMan2 : ThrowedZMan
{
	Default
	{
		+NOGRAVITY;
		Damage 20;
	}
}

class ThrowedSergeantPiece : ThrowedZombieMan2
{
	Default
	{
		Damage 10;
	}
	
	States
	{
		Spawn:
			SP2X HIJK 5;
			Loop;
		Death:
			TNT1 A 0 A_SpawnItem("MeatDeath");
			TNT1 A 5;
			Stop;
	}
}

//Imps

class ThrowedImp : Actor
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 24;
		Fastspeed 32;
		Damage 60;
		+MISSILE;
		Scale 1.0;
		+FORCEXYBILLBOARD;
		+THRUACTORS;
		-NOGRAVITY;
		Gravity 0.4;
		DamageType "Kick";
		Decal "BrutalBloodSuper";
		+NOEXTREMEDEATH;
	}
	
	States
	{
		Spawn:
			X723 A 2;
			TNT1 A 0 A_ChangeFlag("THRUACTORS", 0);
			X723 BCDEFGH 2;
			Loop;
		
		Death:
			TNT1 AAAAAA 0 A_SpawnItem("MuchBlood2");
			TNT1 A 0 A_SpawnItem("DeadImp1");
			TNT1 A 3;
			Stop;
	}
}

class ThrowedImp2: ThrowedImp
{
	Default
	{
		+NOGRAVITY;
		Damage 20;
	}
}	

class ThrowedSavageImp : Actor
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 24;	
		Fastspeed 32;	
		Damage 60;
		+MISSILE;	
		Scale 1.0;	
		+FORCEXYBILLBOARD;
		+THRUACTORS;
		-NOGRAVITY;
		Gravity 0.4;	
		DamageType "Kick";	
		Decal "BrutalBloodSuper";
		+NOEXTREMEDEATH;
	}
	
	States	
	{
		Spawn:	
			5D11 B 4;
			TNT1 A 0 A_ChangeFlag("THRUACTORS", 0);
			TNT1 A 0 A_ChangeFLag("NODROPOFF", 0);
			TNT1 A 0 A_ChangeFLag("SLIDESONWALLS", 0);
			TNT1 A 0 A_FaceTarget;
		Fly:	
			5D11 B 4 A_CustomMissile ("Brutal_LiquidBlood3", 15, 0, random (0, 360), 2, random (0, 40));
			TNT1 A 0 A_JumpIf((MomY == 0), "TakeASit");
			5D11 B 4 A_CustomMissile ("Brutal_LiquidBlood3", 15, 0, random (0, 360), 2, random (0, 40));
			TNT1 A 0 A_JumpIf((MomY == 0), "TakeASit");
			loop;

		Death:
			5D11 D 4 A_CustomMissile ("Brutal_LiquidBlood3", 15, 0, random (0, 360), 2, random (0, 40));
			TNT1 A 0 A_JumpIf((MomY == 0), "TakeASit");
			TNT1 A 0 A_SpawnItem ("GrowingBloodPool");
			TNT1 A 0 A_SpawnItem ("DeadSavageImp1");
			Stop;


		Takeasit:	
			TNT1 AAAAAA 0 A_SpawnItem("MuchBlood2");
			TNT1 A 0 A_FaceTarget();	
			TNT1 A 0 A_PlaySound("BODYF",6);
			TNT1 A 0 A_SpawnItem("GrowingBloodPool");
			TNT1 A 0 A_SpawnItemEx("DeadSavageImp_Slumped", 10);
			Stop;	
	}	
}