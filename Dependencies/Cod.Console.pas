unit Cod.Console;

{$MODE DELPHI}

interface

uses
  SysUtils,
  crt,
  Cod.Types,
  Classes,
  Math,
  Cod.ArrayHelpers,
  Types;

  type
    // Types
    TConsoleColor = (Black, Blue, Green, Cyan, Red, Magenta, Brown, LightGray,
      DarkGray, LightBlue, LightGreen, LightCyan, LightRed, LightMagenta,
      Yellow, White);

    { TKeyData }
    TKeyData = record
      Sequence: TIntArray;

      function Match(Value: TByteSet): boolean;

      function Base: integer;
      function SeqLength: integer;
      function System: boolean;

      function ToString: string;
    end;

    type
    { TConsole }
    TConsole = class
    private
      class function GetCurPos: TPoint; static;
      class procedure SetCurPos(const Value: TPoint); static;
      class function GetCursorVisible: boolean; static;
      class procedure SetCursorVisible(const Value: boolean); static;
      class procedure SetLinePosition(AValue: integer); static;
      class procedure WriteConsole(const Value: string); static;
      class procedure SetTextColor(const Value: TConsoleColor); static;
      class procedure SetBgColor(const Value: TConsoleColor); static;
      class procedure OverWriteConsole(const Value: string); static;
      class procedure WriteLnConsole(const Value: string); static;

    public
      class function Handle: THandle;

      // Console Settings
      class property CursorVisible: boolean read GetCursorVisible write SetCursorVisible;
      class property CursorPos: TPoint read GetCurPos write SetCurPos;
      class property LineMove: integer write SetLinePosition;

      // Style
      class property TextColor: TConsoleColor write SetTextColor;
      class property BgColor: TConsoleColor write SetBgColor;

      class procedure ResetStyle;

      // Console write
      class property Write: string write WriteConsole;
      class property WriteLn: string write WriteLnConsole;
      class property OverWrite: string write OverWriteConsole;

      // Console Size
      class function GetWidth: integer;
      class function GetHeight: integer;

      class function GetConsoleRect: TRect;

      // CRT
      class procedure ClearScreen; // clear with bgcolor
      class procedure ClearLine;
      class procedure ClearRect(Rect: TRect);

      class procedure ResetScreen;

      // Utils
      class procedure ResetPosition;
      class procedure GoToLineBegin;
      class procedure WriteTitleLine(Title: string; Filler: char = '=');
      class function SpacesOfLength(Length: integer): string;

      class function WaitUntillKeyPressed: TKeyData;
      class function KeyPressed: boolean;
      class function GetPressedKey: char;
      class function GetKeyData: TKeyData;

      // Other
      class function GetRec: TTextRec;
    end;

implementation

{ TKeyData }

function TKeyData.Match(Value: TByteSet): boolean;
var
  I: integer;
begin
  Result := true;
  for I := 0 to High(Sequence) do
    if not (Sequence[I] in Value) then
      Exit(false);
end;

function TKeyData.Base: integer;
begin
  Result := Sequence[0];
end;

function TKeyData.SeqLength: integer;
begin
  Result := Length(Sequence);
end;

function TKeyData.System: boolean;
begin
  Result := Length(Sequence) > 1;
end;

function TKeyData.ToString: string;
var
  I: integer;
begin
  Result := '';

  if Length(Sequence) = 0 then
    Exit;

  if not System then
    Result := Format('%S(%D)', [string(char(Sequence[0])), Sequence[0]])
  else
    for I := 0 to High(Sequence) do
      Result := Result + Format('(%D)', [Sequence[I]]);

  Result := Result + Format(', System: %S', [booleantostring(System)]);
end;

{ TConsole }

class procedure TConsole.ClearRect(Rect: TRect);
var
  Y: integer;
begin
  for Y := Rect.Top to Rect.Bottom do
    begin
      CursorPos := Point(Rect.Left, Y);
      Write := SpacesOfLength(Rect.Width);
    end;
end;

class procedure TConsole.ResetScreen;
begin
  ResetStyle;
  ClearScreen;
end;

class procedure TConsole.ResetPosition;
begin
  CursorPos := Point(1, 1);
end;

class procedure TConsole.WriteTitleLine(Title: string; Filler: char);
var
  L,
  W,
  E,
  I: integer;

  S: string;
begin
  W := GetWidth;
  L := Length(Title);
  E := W - L;

  S := '';

  for I := 1 to E div 2 + E mod 2 do
    S := S + Filler;

  S := S + Title;

  for I := 1 to E div 2 do
    S := S + Filler;

  Write := S;
end;

class function TConsole.SpacesOfLength(Length: integer): string;
var
  I: integer;
begin
  Result := '';
  for I := 1 to Length do
    Result := Result + ' ';
end;

class procedure TConsole.ClearLine;
begin
  ClrEol;
end;

class function TConsole.GetCurPos: TPoint;
begin
  Result := Point(WhereX, WhereY);
end;

class function TConsole.GetHeight: integer;
begin
  Result := ScreenHeight;
end;

class function TConsole.GetRec: TTextRec;
begin
  Result :=  TTextRec(Output);
end;

class function TConsole.GetWidth: integer;
begin
  Result := ScreenWidth;
end;

class function TConsole.GetConsoleRect: TRect;
begin
  Result := Rect(0, 0, GetWidth, GetHeight);
end;

class procedure TConsole.ClearScreen;
begin
  ClrScr;
end;

class procedure TConsole.GoToLineBegin;
begin
  CursorPos := Point(0, CursorPos.Y);
end;

class function TConsole.Handle: THandle;
begin
  Result := GetRec.Handle;
end;

class procedure TConsole.OverWriteConsole(const Value: string);
begin
  GoToLineBegin;
  System.Write(Value);
end;

class procedure TConsole.ResetStyle;
begin
  BgColor:=TConsoleColor.Black;
  TextColor := TConsoleColor.White;
end;

class procedure TConsole.SetBgColor(const Value: TConsoleColor);
begin
  TextBackground(Integer(Value));
end;

class procedure TConsole.SetCurPos(const Value: TPoint);
begin
  GotoXY(Value.X, Value.Y);
end;

class function TConsole.GetCursorVisible: boolean;
begin
  Result := false;
end;

class procedure TConsole.SetCursorVisible(const Value: boolean);
begin
  if Value then
    cursoron
  else
    cursoroff;
end;

class procedure TConsole.SetLinePosition(AValue: integer); static;
begin
  GotoXY(1, AValue); // 0 is ignored, so 1 is begining of line
end;

class procedure TConsole.SetTextColor(const Value: TConsoleColor);
begin
  crt.TextColor(integer(Value));
end;

class function TConsole.WaitUntillKeyPressed: TKeyData;
begin
  Result := GetKeyData;
end;

class function TConsole.KeyPressed: boolean;
begin
  Result := crt.KeyPressed;
end;

class function TConsole.GetPressedKey: char;
begin
  Result := ReadKey;
end;

class function TConsole.GetKeyData: TKeyData;
begin
  Result.Sequence := [];
  repeat
    Result.Sequence.AddValue( integer(ReadKey) );
  until not KeyPressed;
end;

class procedure TConsole.WriteConsole(const Value: string);
begin
  System.Write(Value);
end;

class procedure TConsole.WriteLnConsole(const Value: string);
begin
  System.WriteLn(Value);
end;

end.
