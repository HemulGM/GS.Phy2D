{
GS.Phy2D - open source 2D physics engine
2026, Vincent Gsell

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

Created by Vincent Gsell [https://github.com/VincentGsell]
}

//History
//20260111 - Created. Dynamic OBB object (Oriented Bounding Box with rotation).

unit GS.Phy.OBB;
{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

// Compiler optimizations
{$O+}  // Optimizations enabled
{$R-}  // Range checking disabled
{$Q-}  // Overflow checking disabled

interface

uses
  GS.Phy.Vec2;

const
  PHY_FLAG_FIXED      = 1;
  PHY_FLAG_COLLIDABLE = 2;

type
  // Dynamic OBB: oriented bounding box with rotation
  TPhyOBB = record
    PosX, PosY: Single;         // Center position
    OldPosX, OldPosY: Single;   // Previous position (Verlet)
    AccelX, AccelY: Single;     // Accumulated acceleration
    Angle: Single;              // Rotation angle (radians)
    OldAngle: Single;           // Previous angle (Verlet for rotation)
    AngularAccel: Single;       // Angular acceleration
    HalfW, HalfH: Single;       // Half-extents
    InvMass: Single;            // 1/mass (0 = fixed)
    InvInertia: Single;         // 1/moment of inertia (0 = fixed rotation)
    Restitution: Single;
    Flags: Byte;
  end;
  PPhyOBB = ^TPhyOBB;

  // SoA layout for cache-friendly access
  TOBBSoA = record
    PosX: array of Single;
    PosY: array of Single;
    OldPosX: array of Single;
    OldPosY: array of Single;
    AccelX: array of Single;
    AccelY: array of Single;
    Angle: array of Single;
    OldAngle: array of Single;
    AngularAccel: array of Single;
    HalfW: array of Single;
    HalfH: array of Single;
    InvMass: array of Single;
    InvInertia: array of Single;
    Restitution: array of Single;
    Flags: array of Byte;
  end;

// Get OBB corner points (rotated)
procedure GetOBBCorners(PosX, PosY, HalfW, HalfH, Angle: Single;
  out C0X, C0Y, C1X, C1Y, C2X, C2Y, C3X, C3Y: Single); inline;

// Get OBB axes (normalized edge directions)
procedure GetOBBAxes(Angle: Single; out Ax0X, Ax0Y, Ax1X, Ax1Y: Single); inline;

// Project OBB onto axis, return min/max
procedure ProjectOBB(PosX, PosY, HalfW, HalfH, Angle: Single;
  AxisX, AxisY: Single; out ProjMin, ProjMax: Single);

// Project circle onto axis
procedure ProjectCircle(CX, CY, Radius: Single;
  AxisX, AxisY: Single; out ProjMin, ProjMax: Single); inline;

// Check if two projections overlap
function ProjectionsOverlap(Min1, Max1, Min2, Max2: Single; out Overlap: Single): Boolean; inline;

implementation

procedure GetOBBCorners(PosX, PosY, HalfW, HalfH, Angle: Single;
  out C0X, C0Y, C1X, C1Y, C2X, C2Y, C3X, C3Y: Single);
var
  CosA, SinA: Single;
  WCos, WSin, HCos, HSin: Single;
begin
  CosA := Cos(Angle);
  SinA := Sin(Angle);

  WCos := HalfW * CosA;
  WSin := HalfW * SinA;
  HCos := HalfH * CosA;
  HSin := HalfH * SinA;

  // Corner 0: -HalfW, -HalfH
  C0X := PosX - WCos + HSin;
  C0Y := PosY - WSin - HCos;

  // Corner 1: +HalfW, -HalfH
  C1X := PosX + WCos + HSin;
  C1Y := PosY + WSin - HCos;

  // Corner 2: +HalfW, +HalfH
  C2X := PosX + WCos - HSin;
  C2Y := PosY + WSin + HCos;

  // Corner 3: -HalfW, +HalfH
  C3X := PosX - WCos - HSin;
  C3Y := PosY - WSin + HCos;
end;

procedure GetOBBAxes(Angle: Single; out Ax0X, Ax0Y, Ax1X, Ax1Y: Single);
var
  CosA, SinA: Single;
begin
  CosA := Cos(Angle);
  SinA := Sin(Angle);

  // Axis 0: along width (X axis rotated)
  Ax0X := CosA;
  Ax0Y := SinA;

  // Axis 1: along height (Y axis rotated, perpendicular to Axis 0)
  Ax1X := -SinA;
  Ax1Y := CosA;
end;

procedure ProjectOBB(PosX, PosY, HalfW, HalfH, Angle: Single;
  AxisX, AxisY: Single; out ProjMin, ProjMax: Single);
var
  C0X, C0Y, C1X, C1Y, C2X, C2Y, C3X, C3Y: Single;
  P0, P1, P2, P3: Single;
begin
  GetOBBCorners(PosX, PosY, HalfW, HalfH, Angle, C0X, C0Y, C1X, C1Y, C2X, C2Y, C3X, C3Y);

  // Project each corner onto axis
  P0 := C0X * AxisX + C0Y * AxisY;
  P1 := C1X * AxisX + C1Y * AxisY;
  P2 := C2X * AxisX + C2Y * AxisY;
  P3 := C3X * AxisX + C3Y * AxisY;

  // Find min/max
  ProjMin := P0;
  ProjMax := P0;

  if P1 < ProjMin then ProjMin := P1;
  if P1 > ProjMax then ProjMax := P1;
  if P2 < ProjMin then ProjMin := P2;
  if P2 > ProjMax then ProjMax := P2;
  if P3 < ProjMin then ProjMin := P3;
  if P3 > ProjMax then ProjMax := P3;
end;

procedure ProjectCircle(CX, CY, Radius: Single;
  AxisX, AxisY: Single; out ProjMin, ProjMax: Single);
var
  Center: Single;
begin
  Center := CX * AxisX + CY * AxisY;
  ProjMin := Center - Radius;
  ProjMax := Center + Radius;
end;

function ProjectionsOverlap(Min1, Max1, Min2, Max2: Single; out Overlap: Single): Boolean;
begin
  if (Max1 < Min2) or (Max2 < Min1) then
  begin
    Overlap := 0;
    Result := False;
  end
  else
  begin
    // Overlap = min of the two possible overlaps
    if Max1 - Min2 < Max2 - Min1 then
      Overlap := Max1 - Min2
    else
      Overlap := Max2 - Min1;
    Result := True;
  end;
end;

end.
