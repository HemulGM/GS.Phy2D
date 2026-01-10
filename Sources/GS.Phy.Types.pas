unit GS.Phy.Types;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  GS.Phy.Vec2;

const
  PHY_FLAG_FIXED     = 1;
  PHY_FLAG_COLLIDABLE = 2;

type
  // Particule : record compact, pas de classe
  TPhyParticle = record
    Pos: TVec2;        // Position actuelle
    OldPos: TVec2;     // Position precedente (Verlet)
    Accel: TVec2;      // Acceleration accumulee
    Radius: Single;    // Rayon de collision
    InvMass: Single;   // 1/masse (0 = fixe)
    Restitution: Single; // Elasticite (0-1)
    Flags: Byte;       // PHY_FLAG_*
  end;
  PPhyParticle = ^TPhyParticle;

  // Contrainte distance entre 2 particules
  TPhyConstraint = record
    P1, P2: Integer;   // Indices des particules
    RestLength: Single;
    Stiffness: Single; // 0-1
  end;
  PPhyConstraint = ^TPhyConstraint;

  // Box statique (mur)
  TPhyBox = record
    MinX, MinY, MaxX, MaxY: Single;
    Restitution: Single;
  end;
  PPhyBox = ^TPhyBox;

function CreateParticle(X, Y, Radius: Single; Fixed: Boolean = False; Mass: Single = 1.0; Restitution: Single = 0.5): TPhyParticle;
function CreateBox(X, Y, Width, Height: Single; Restitution: Single = 0.3): TPhyBox;

implementation

function CreateParticle(X, Y, Radius: Single; Fixed: Boolean; Mass: Single; Restitution: Single): TPhyParticle;
begin
  Result.Pos := Vec2(X, Y);
  Result.OldPos := Vec2(X, Y);
  Result.Accel := Vec2(0, 0);
  Result.Radius := Radius;
  if Fixed or (Mass <= 0) then
    Result.InvMass := 0
  else
    Result.InvMass := 1.0 / Mass;
  Result.Restitution := Restitution;
  Result.Flags := PHY_FLAG_COLLIDABLE;
  if Fixed then
    Result.Flags := Result.Flags or PHY_FLAG_FIXED;
end;

function CreateBox(X, Y, Width, Height: Single; Restitution: Single): TPhyBox;
begin
  Result.MinX := X - Width * 0.5;
  Result.MaxX := X + Width * 0.5;
  Result.MinY := Y - Height * 0.5;
  Result.MaxY := Y + Height * 0.5;
  Result.Restitution := Restitution;
end;

end.
