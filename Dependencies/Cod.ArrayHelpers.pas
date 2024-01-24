{***********************************************************}
{                  Codruts Variabile Helpers                }
{                                                           }
{                        version 0.2                        }
{                           ALPHA                           }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{                   -- WORK IN PROGRESS --                  }
{***********************************************************}

{$SCOPEDENUMS ON}
{$mode Delphi}

unit Cod.ArrayHelpers;

interface
  uses
  SysUtils, Classes;

  type
    // TArray generic types
    //TIntArray = TArray<string>;
    TStringArrayHelper = record helper for TStringArray
    public
      function AddValue(Value: string): integer;
      procedure Insert(Index: integer; Value: string);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: string): integer;
      procedure SetToLength(ALength: integer);
    end;

    TIntArray = TArray<integer>;
    TIntegerArrayHelper = record helper for TIntArray
    public
      function AddValue(Value: integer): integer;
      procedure Insert(Index: integer; Value: integer);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: integer): integer;
      procedure SetToLength(ALength: integer);
    end;

    TRealArray = TArray<real>;
    TRealArrayHelper = record helper for TRealArray
    public
      function AddValue(Value: real): integer;
      procedure Insert(Index: integer; Value: real);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: real): integer;
      procedure SetToLength(ALength: integer);
    end;

    TBoolArray = TArray<boolean>;
    TBoolArrayHelper = record helper for TBoolArray
    public
      function AddValue(Value: boolean): integer;
      procedure Insert(Index: integer; Value: boolean);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: boolean): integer;  // pretty useless, but can find if a value exists
      procedure SetToLength(ALength: integer);
    end;

  // Utils
  function MakeIntArray(Items: array of integer): TIntArray;

implementation

function MakeIntArray(Items: array of integer): TIntArray;
var
  I: integer;
begin
  SetLength(Result, Length(Items));
  for I := 0 to High(Items) do
    Result[I] := Items[I];
end;

// TArray Generic Helpers

function TStringArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

function TIntegerArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

function TRealArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

procedure TStringArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

procedure TIntegerArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

procedure TRealArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

function TStringArrayHelper.AddValue(Value: string): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

function TIntegerArrayHelper.AddValue(Value: integer): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

function TRealArrayHelper.AddValue(Value: real): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

procedure TStringArrayHelper.Insert(Index: integer; Value: string);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TIntegerArrayHelper.Insert(Index: integer; Value: integer);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TRealArrayHelper.Insert(Index: integer; Value: real);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TStringArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

procedure TIntegerArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

procedure TRealArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

function TStringArrayHelper.Find(Value: string): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

function TIntegerArrayHelper.Find(Value: integer): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

function TRealArrayHelper.Find(Value: real): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

{ TBoolArrayHelper }

function TBoolArrayHelper.AddValue(Value: boolean): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

function TBoolArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

procedure TBoolArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

function TBoolArrayHelper.Find(Value: boolean): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

procedure TBoolArrayHelper.Insert(Index: integer; Value: boolean);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TBoolArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

end.
