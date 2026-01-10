unit GS.Phy.Vec2;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

type
  TVec2 = record
    X, Y: Single;
  end;
  PVec2 = ^TVec2;

function Vec2(X, Y: Single): TVec2; inline;
function Vec2Add(const A, B: TVec2): TVec2; inline;
function Vec2Sub(const A, B: TVec2): TVec2; inline;
function Vec2Mul(const V: TVec2; S: Single): TVec2; inline;
function Vec2Dot(const A, B: TVec2): Single; inline;
function Vec2LengthSq(const V: TVec2): Single; inline;
function Vec2Length(const V: TVec2): Single; inline;
function Vec2Normalize(const V: TVec2): TVec2; inline;
function Vec2Dist(const A, B: TVec2): Single; inline;
function Vec2DistSq(const A, B: TVec2): Single; inline;

implementation

function Vec2(X, Y: Single): TVec2;
begin
  Result.X := X;
  Result.Y := Y;
end;

function Vec2Add(const A, B: TVec2): TVec2;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

function Vec2Sub(const A, B: TVec2): TVec2;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

function Vec2Mul(const V: TVec2; S: Single): TVec2;
begin
  Result.X := V.X * S;
  Result.Y := V.Y * S;
end;

function Vec2Dot(const A, B: TVec2): Single;
begin
  Result := A.X * B.X + A.Y * B.Y;
end;

function Vec2LengthSq(const V: TVec2): Single;
begin
  Result := V.X * V.X + V.Y * V.Y;
end;

function Vec2Length(const V: TVec2): Single;
begin
  Result := Sqrt(V.X * V.X + V.Y * V.Y);
end;

function Vec2Normalize(const V: TVec2): TVec2;
var
  Len: Single;
begin
  Len := Vec2Length(V);
  if Len > 0.0001 then
  begin
    Result.X := V.X / Len;
    Result.Y := V.Y / Len;
  end
  else
  begin
    Result.X := 0;
    Result.Y := 0;
  end;
end;

function Vec2Dist(const A, B: TVec2): Single;
begin
  Result := Sqrt(Sqr(B.X - A.X) + Sqr(B.Y - A.Y));
end;

function Vec2DistSq(const A, B: TVec2): Single;
begin
  Result := Sqr(B.X - A.X) + Sqr(B.Y - A.Y);
end;

end.
