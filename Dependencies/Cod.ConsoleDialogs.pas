unit Cod.ConsoleDialogs;

interface

{$SCOPEDENUMS ON}

uses
  SysUtils,
  Cod.Types,
  Classes,
  Math,
  Cod.ArrayHelpers,
  Cod.Console,
  Types;


  type
    { TDialogColorsEx }
    TDialogColors = record
      Background: TConsoleColor;
      Content: TConsoleColor;
      Border: TConsoleColor;
      Title: TConsoleColor;
      Text: TConsoleColor;
      Button: TConsoleColor;
      ButtonHighlight: TConsoleColor;
      ButtonHighlightText: TConsoleColor;
      ButtonText: TConsoleColor;
      TextboxFill: TConsoleColor;
      Textbox: TConsoleColor;
    end;

  const
    DefaultDialogColors: TDialogColors = (
      Background: TConsoleColor.Magenta;
      Content: TConsoleColor.LightGray;
      Border: TConsoleColor.LightGray;
      Title: TConsoleColor.Black;
      Text: TConsoleColor.Black;
      Button: TConsoleColor.DarkGray;
      ButtonHighlight: TConsoleColor.LightBlue;
      ButtonHighlightText: TConsoleColor.White;
      ButtonText: TConsoleColor.Cyan;
      TextboxFill: TConsoleColor.DarkGray;
      Textbox: TConsoleColor.Black;
    );

  type
    TKeyHandled = (False, True, Exit);

    { TConDialog }
    TConDialog = class
    private
      const
      MAX_WIDTH = 80;

      PERC_WIDTH = 0.8;
      PERC_HEIGHT = 0.9;

      MARGIN_BORDER = 1;

      var
      Index: integer; // button index
      LimitWidth: boolean; // Limit width to MAX_WIDTH (default: true)

      Btns: TStringArray; // formatted buttons
      BtnsPos: array  of TPoint;
      Lns: TStringArray; // formatted text lines
      Titl: string; // formatted title

      ContentCutoff: boolean;

      // Temp
      TmpBtnLines: integer;

      // Internal
      function Margin: integer;

      function HandleKey(Key: TKeyData): TKeyHandled; virtual;

      // Auto-window
      procedure AWCalculateWidth;
      procedure AWCalculateHeight;
      procedure AWCenter;

      procedure AWShrinkHeight;

      // Calc
      procedure CalcButtons; virtual;
      procedure CalcTitle;
      procedure CalcText;

      procedure CalcAll;

      // Prepare
      procedure CalcButtonLines;

      procedure CalcPrep;

      // Size
      function CalcClientHeight: integer; virtual; // This is not Client.Height, as It calculates based on the controls inside
      procedure WindowSized; virtual; // After all size modifications were made

      // Draw
      procedure ClearDialog;

      procedure ClearContainer;
      procedure DrawBase;
      procedure DrawTitle;
      procedure DrawText;
      procedure DrawButtons;

      procedure SelectDefault; virtual;
      procedure FocusActive; virtual;

      procedure DrawDialog; virtual;
      procedure DrawFocusable; virtual;
      procedure DrawStatic; virtual;

      procedure DrawAll;

      // Focus
      function FocusRange: TSize; virtual;

      // Button
      procedure ExecDialog; virtual;

    public
      var
      // Properties
      Title: string;
      Text: string;
      Buttons: TStringArray;
      Colors: TDialogColors;

      Container: TRect; // The parent rect of the window
      Window: TRect;
      ClientMargin: integer;

      DefaultIndex: integer; // Default focus index
      ButtonSidesLeft: string;
      ButtonSidesRight: string;

      AutoWindow: boolean; { Automatically calculate best window size and position }
      AutoContainer: boolean; { Get container rect automatically }
      AutoClearContainer: boolean; { Fill parent rect with solid color }

      // Dynamic
      function Client: TRect;

      // Exec
      { Execute is virtual, and declared in upper classes }

      // Constructors
      constructor Create;
      destructor Destroy; override;
    end;

  { TConsoleDialog }
  TConsoleDialog = class(TConDialog)
  public
    function Execute: integer;
  end;

  { TConsoleListDialog }
  TConsoleListDialog = class(TConDialog)
  private
    procedure CalcButtons; override;
    procedure FocusActive; override;
    function HandleKey(Key: TKeyData): TKeyHandled; override;

  public
    function Execute: integer;

    constructor Create;
  end;

  { TConsoleInput }
  TConsoleInput = class(TConDialog)
  private
    TextIndex: integer;
    CutoffPoint: integer;

    function HandleKey(Key: TKeyData): TKeyHandled; override;
    procedure FocusActive; override;
    function CursorView: integer;

    // Size
    function CalcClientHeight: integer; override;

    function GetEditPos: integer;

    // Draw
    procedure DrawEdit;

    procedure DrawFocusable; override;

    // Focus
    function FocusRange: TSize; override;

  public
    TextValue: string;
    CanCancel: boolean;

    function Execute: boolean;

    constructor Create;
  end;

  { TQuickDialog }
  TQuickDialog = class
  public
    class procedure Message(ATitle, AText: string);
    class procedure Message(AText: string); overload;
    class function Dialog(ATitle, AText: string; AButtons: TStringArray; ADefaultIndex: integer = 0): integer;
    class function Picker(ATitle, AText: string; AButtons: TStringArray; ADefaultIndex: integer = 0): integer;
    class function Input(ATitle, AText: string; var Value: string; ACanCancel: boolean = true): boolean;
    class function InputBox(ATitle, AText: string; Default: string): string;
  end;

implementation

{ TConsoleListDialog }

procedure TConsoleListDialog.CalcButtons;
var
  I: integer;
  Expected: integer;
  Space: integer;
  S: string;
begin
  Expected := Client.Width;

  Btns := [];
  for I := 0 to High(Buttons) do
    begin
      S := ButtonSidesLeft + Buttons[I] + ButtonSidesRight;
      Space := Expected - Length(S);
      S := S + TConsole.SpacesOfLength(Space div 2 + Space mod 2) + TConsole.SpacesOfLength(Space div 2);

      Btns.AddValue(S);
    end;
end;

procedure TConsoleListDialog.FocusActive;
begin
  inherited FocusActive;
  TConsole.CursorPos := Point(TConsole.CursorPos.X-1, 0);
end;

function TConsoleListDialog.HandleKey(Key: TKeyData): TKeyHandled;
begin
  if Key.SeqLength = 2 then
    case Key.Sequence[1] of
      72: Key.Sequence[1] := 75;
      80: Key.Sequence[1] := 77;
    end;

  Result:=inherited HandleKey(Key);
end;

function TConsoleListDialog.Execute: integer;
begin
  ExecDialog;

  Result := Index;
end;

constructor TConsoleListDialog.Create;
begin
  inherited Create;

  ButtonSidesLeft := ' -->  ';
  ButtonSidesRight := ' ';
end;

{ TConsoleInput }

function TConsoleInput.HandleKey(Key: TKeyData): TKeyHandled;
var
  S: string;
begin
  Result := TKeyHandled.True;

  // Focus
  if Key.Base = 9 then
    begin
      if Index = -1 then
        Index := abs(CanCancel.ToInteger)
      else
        Index := -1;

      DrawFocusable;
      FocusActive;

      Exit;
    end;

  // Buttons
  if Index <> -1 then begin
    Result := inherited HandleKey(Key);

    Exit;
  end;

  // Key
  case Key.SeqLength of
    1: case Key.Base of
      13: begin
        if CanCancel then
          Index := 1;

        Result := TKeyHandled.Exit;
        Exit;
      end;

      27: begin
        if CanCancel then
          Index := 0;

        Result := TKeyHandled.Exit;
        Exit;
      end;

      0..7, 9..12, 14..26: ;

      8: if TextIndex > 0 then begin
        TextValue := TextValue.Remove(TextIndex-1, 1);
        Dec(TextIndex);
      end;

      else begin
        TextValue := TextValue.Insert(TextIndex, char(Key.Base));
        Inc(TextIndex);
      end;
    end;

    2: case Key.Sequence[1] of
      75: TextIndex := Max(TextIndex-1, 0);
      77: TextIndex := Min(TextIndex+1, High(TextValue));
      70: TextIndex := Length(TextValue)-1;

      71: begin
        TextIndex:=0;
      end;
    end;

    3: begin
      if Key.Match([70, 91, 27]) then
        TextIndex:=Length(TextValue);
    end
  end;

  // Positioning
  if CursorView >= Client.Width then
    Inc(Cutoffpoint, CursorView - Client.Width+1);

  if CursorView <= 0 then
    Dec(Cutoffpoint, abs(CursorView)+1);

  Cutoffpoint := EnsureRange(Cutoffpoint, 0, Client.Width);

  // Draw
  DrawEdit;
  FocusActive;
end;

procedure TConsoleInput.FocusActive;
begin
  if Index <> -1 then
    inherited FocusActive
  else
    TConsole.CursorPos := Point(Client.Left + CursorView, GetEditPos);
end;

function TConsoleInput.CursorView: integer;
begin
  Result := TextIndex-CutoffPoint;
end;

function TConsoleInput.CalcClientHeight: integer;
begin
  Result := inherited + 3 { space, edit box, extra space };
end;

function TConsoleInput.GetEditPos: integer;
begin
  Result := Client.Bottom - TmpBtnLines*2 - 1;
end;

procedure TConsoleInput.DrawEdit;
var
  EditPos: integer;
  Txt: string;
begin
  // Pos
  EditPos := GetEditPos;

  // Draw
  with TConsole do
    begin
      TextColor := Colors.Textbox;
      BgColor := Colors.TextboxFill;

      // Fill
      CursorPos := Point(Client.Left, EditPos);
      Write := SpacesOfLength(Client.Width);

      // Text
      CursorPos := Point(Client.Left, EditPos);
      Txt := Copy(TextValue, CutoffPoint+1, Client.Width);
      Write := Txt;
    end;
end;

procedure TConsoleInput.DrawFocusable;
begin
  inherited DrawFocusable;
  DrawEdit;
end;

function TConsoleInput.FocusRange: TSize;
begin
  // X - lower, Y - higher
  Result.cx:=-1; // Edit
  Result.cy:=High(Btns);
end;

function TConsoleInput.Execute: boolean;
begin
  if CanCancel then
    Buttons := ['CANCEL', 'OKAY']
  else
    Buttons := ['OKAY'];

  DefaultIndex:=-1;

  ExecDialog;
  Result := (Index = 1) or not CanCancel;;
end;

constructor TConsoleInput.Create;
begin
  inherited Create;
  TextIndex := 0;
  CutoffPoint := 0;
  TextValue := '';
end;

{ TConsoleDialog }

function TConsoleDialog.Execute: integer;
begin
  ExecDialog;

  Result := Index;
end;

{ TQuickDialog }

class procedure TQuickDialog.Message(ATitle, AText: string);
begin
  Dialog(ATitle, AText, ['OKAY']);
end;

class procedure TQuickDialog.Message(AText: string);
begin
  Message('Message', AText);
end;

class function TQuickDialog.Dialog(ATitle, AText: string;
  AButtons: TStringArray; ADefaultIndex: integer): integer;
var
  D: TConsoleDialog;
begin
  D := TConsoleDialog.Create;

  with D do
    try
      Title := ATitle;
      Text := AText;
      Buttons := AButtons;
      DefaultIndex := ADefaultIndex;

      Result := Execute;
    finally
      Free;
    end;
end;

class function TQuickDialog.Picker(ATitle, AText: string;
  AButtons: TStringArray; ADefaultIndex: integer): integer;
var
  D: TConsoleListDialog;
begin
  D := TConsoleListDialog.Create;

  with D do
    try
      Title := ATitle;
      Text := AText;
      Buttons := AButtons;
      DefaultIndex := ADefaultIndex;

      Result := Execute;
    finally
      Free;
    end;
end;

class function TQuickDialog.Input(ATitle, AText: string; var Value: string;
  ACanCancel: boolean): boolean;
var
  D: TConsoleInput;
begin
  D := TConsoleInput.Create;

  with D do
    try
      Title := ATitle;
      Text := AText;
      CanCancel := ACanCancel;

      TextValue:=Value;

      Result := Execute;

      if Result then
        Value := TextValue;
    finally
      Free;
    end;
end;

class function TQuickDialog.InputBox(ATitle, AText: string; Default: string
  ): string;
begin
  Result := Default;
  Input(ATitle, AText, Result, false);
end;


{ TConDialog }
function TConDialog.Margin: integer;
begin
  Result := MARGIN_BORDER{border} + ClientMargin;
end;

function TConDialog.HandleKey(Key: TKeyData): TKeyHandled;
begin
  Result := TKeyHandled.True;
  case Key.SeqLength of
    1: case Key.Base of
      13, 27, 32, 113: Result := TKeyHandled.Exit;
    end;

    2: case Key.Sequence[1] of
      75: begin
        Index := Max(Index-1, FocusRange.cx);

        DrawFocusable;
        FocusActive;
      end;

      77: begin
        Index := Min(Index+1, FocusRange.cy);

        DrawFocusable;
        FocusActive;
      end;

      else Result := TKeyHandled.False;
    end;
  end;
end;

procedure TConDialog.AWCalculateWidth;
begin
  Window.Width:= trunc(Container.Width* PERC_WIDTH);

  // Limit
  if LimitWidth then
    Window.Width := Min(Window.Width, MAX_WIDTH);
end;

procedure TConDialog.AWCalculateHeight;
begin
  Window.Height:= trunc(Container.Height* PERC_HEIGHT);
end;

procedure TConDialog.AWCenter;
begin
  Window.Offset((Container.Width - Window.Width) div 2 - Window.Left+1,
               (Container.Height - Window.Height) div 2 - Window.Top+1);
end;

procedure TConDialog.AWShrinkHeight;
var
  UsedHeight: integer;
begin
  UsedHeight := CalcClientHeight;

  if UsedHeight < Client.Height then
    Window.Height:=UsedHeight + 2 * MARGIN_BORDER + 2* ClientMargin;
end;

procedure TConDialog.CalcButtons;
var
  I: integer;
begin
  Btns := [];
  for I := 0 to High(Buttons) do
    Btns.AddValue( ButtonSidesLeft + Buttons[I] + ButtonSidesRight );
end;

procedure TConDialog.CalcTitle;
var
  MaxTitle: integer;
begin
  Titl := Title;

  // Limit
  MaxTitle := Client.Width - (MARGIN_BORDER * 4 + ClientMargin * 2);
  if Length(Titl) > MaxTitle then
    begin
      Titl := Copy(Titl, 1, MaxTitle-3) + '...';

      ContentCutoff := true;
    end;
end;

procedure TConDialog.CalcText;
var
  AText: string;
  AIndex: integer;

  P, Position: integer;
  StrP: ^string;
  AClient: TRect;
  TextMax: integer;
begin
  AClient := Client;
  AText := Text;
  Lns := [];
  while AText <> '' do begin
    // Index
    AIndex := Length(Lns);
    SetLength(Lns, AIndex+1);

    // Pointer
    StrP := @Lns[AIndex];

    // Position
    Position  := Pos(#13, AText);

    // Copy
    if (Position <= AClient.Width) and (Position <> 0) then
      begin
        StrP^ := Copy(AText, 1, Position-1);
        AText := Copy(AText, Position+1, Length(AText));
      end
    else
      begin
        StrP^ := Copy(AText, 1, AClient.Width);
        AText := Copy(AText, AClient.Width, Length(AText));
      end;
  end;

  // Limit
  TextMax := Client.Height - (CalcClientHeight-Length(Lns));
  if Length(Lns) > TextMax then
    begin
      SetLength(Lns, TextMax);

      P := High(Lns);
      Lns[P] := Copy(Lns[P], 1, Length(Lns[P])-3) + '...';

      // Cutoff
      ContentCutoff := true;
    end;
end;

procedure TConDialog.CalcAll;
begin
  ContentCutoff := false;

  CalcButtons;
  CalcTitle;

  CalcPrep; // get lines nr

  CalcText;
end;

procedure TConDialog.CalcButtonLines;
var
  X: integer;
  I: integer;
  AClient: TRect;

procedure AddPos;
var
  P: integer;
begin
  P := Length(BtnsPos);
  SetLength(BtnsPos, P+1);

  BtnsPos[P] := Point(X, TmpBtnLines);
end;
begin
  X := 0;
  AClient:= Client ;
  TmpBtnLines := 1;
  BtnsPos := [];

  for I := 0 to High(Btns) do
    begin
      // Add
      AddPos;

      // Next
      Inc( X, Length(Btns[I]));

      // Spacing
      if I <> High(Btns) then
        Inc(X);

      // Next button
      if I < High(Btns) then
        if X + Length(Btns[I+1]) > Client.Width then
          begin
            X := 0;
            Inc(TmpBtnLines);
          end;
    end;
end;

procedure TConDialog.CalcPrep;
begin
  CalcButtonLines;
end;

function TConDialog.CalcClientHeight: integer;
begin
  Result := 0;

  Inc(Result, TmpBtnLines * 2); {button + margin}
  Inc(Result, Length(Lns)); {lines}
end;

procedure TConDialog.WindowSized;
var
  I: integer;
  O: integer;
begin
  // Offset buttons
  if (TmpBtnLines = 1) and (Length(Btns) > 0) then
    begin
      O := (Client.Width - (BtnsPos[High(BtnsPos)].X + Length(Btns[High(Btns)]))) div 2;
      for I := 0 to High(BtnsPos) do
        BtnsPos[I].Offset(O, 0);
    end;
end;

procedure TConDialog.ClearDialog;
begin
  with TConsole do
    begin
      ResetStyle;

      ClearRect(Container);
    end;
end;

procedure TConDialog.ClearContainer;
begin
  with TConsole do
    begin
      BgColor:=Colors.Background;
      ClearRect(Container);
    end;
end;

procedure TConDialog.DrawBase;
var
  I, J: integer;
  S: string;
  H, W: integer;
begin
  with TConsole do
    begin
      // Fill
      H := Window.Height;
      for I := 1 to H do begin
        CursorPos := Point(Window.Left, Window.Top-1+I);;

        BgColor:=Colors.Content;
        TextColor:=Colors.Border;
        W := Window.Width;
        for J := 1 to W do
          begin
            if (I = 1) or (I = H) then
              S := '='
            else
            if (J = 1) or (J = W) then
              S := '|'
            else
              S := ' ';

            Write := S;
          end;
      end;
    end;
end;

procedure TConDialog.DrawTitle;
begin
  with TConsole do
    begin
      CursorPos := Point(Window.CenterPoint.X - (Length(Title) + 4) div 2,
        Window.Top);

      BgColor:=Colors.Content;
      TextColor := Colors.Title;

      Write := '| ' + Title + ' |';
    end;
end;

procedure TConDialog.DrawText;
var
  AClient: TRect;
  I: integer;
begin
  AClient := Client;

  with TConsole do
    begin
      TextColor:=Colors.Text;
      for I := 0 to High(Lns) do
        begin
          CursorPos := Point(AClient.Left, AClient.Top + I);

          Write := Lns[I];
        end;
    end;
end;

procedure TConDialog.DrawButtons;
var
  I: integer;
  AClient: TRect;
begin
  AClient := Client;

  for I := 0 to High(Btns) do
    with TConsole do
      begin
        CursorPos := Point(AClient.Left + BtnsPos[I].X, AClient.Bottom-TmpBtnLines*2 + (BtnsPos[I].Y-1)*2 + 1);

        // Color
        if I = Index then begin
          BgColor := Colors.ButtonHighlight;
          TextColor := Colors.ButtonHighlightText;
        end else begin
          BgColor:=Colors.Button;
          TextColor := Colors.ButtonText;
        end;

        // Draw
        Write := Btns[I];
      end;
end;

procedure TConDialog.SelectDefault;
begin
  Index := DefaultIndex;
  DrawFocusable;
  FocusActive;
end;

procedure TConDialog.FocusActive;
begin
  if Index <> -1 then
    TConsole.CursorPos := Point(Client.Left + BtnsPos[Index].X+1, Client.Bottom-TmpBtnLines*2 + (BtnsPos[Index].Y-1)*2 + 1);
end;

procedure TConDialog.DrawDialog;
begin
  if AutoClearContainer then
    ClearContainer;

  DrawBase;
  DrawTitle;
end;

procedure TConDialog.DrawFocusable;
begin
  DrawButtons;
end;

procedure TConDialog.DrawStatic;
begin
  DrawText;
end;

procedure TConDialog.DrawAll;
begin
  // Dialog
  DrawDialog;

  // Items
  DrawStatic;
  DrawFocusable;
end;

function TConDialog.FocusRange: TSize;
begin
  // X - lower, Y - higher
  Result.cx:=0;
  Result.cy:=High(Btns);
end;

procedure TConDialog.ExecDialog;
var
  I: integer;
begin
  // Container
  if AutoContainer then
    Container := TConsole.GetConsoleRect;

  // Sizing
  if AutoWindow then begin
    Window := Rect(1, 1, 2, 2);

    AWCalculateWidth;
    AWCalculateHeight;

    // Try sizings
    CalcAll;

    if ContentCutoff and LimitWidth then
      begin
        LimitWidth := false;
        AWCalculateWidth;

        CalcAll;
      end;

    // Prep
    CalcPrep;

    // Shrink
    AWShrinkHeight;

    // Sizing done
    WindowSized;

    // Center
    AWCenter;
  end
    else
  begin
    // Prep
    CalcPrep;
    WindowSized;

    // Presized
    CalcAll;
  end;

  // Draw
  DrawAll;

  // Index
  SelectDefault;

  // Wait
  while true do
    if TConsole.KeyPressed then
      case HandleKey( TConsole.GetKeyData ) of
        TKeyHandled.Exit: Break;
      end;


  with TConsole do begin
    CursorPos := Point(1, 1); Write := I.ToString + '    ';
    end;

  // Clear
  if AutoClearContainer then
    ClearDialog;
end;

function TConDialog.Client: TRect;
var
  M: integer;
begin
  M := Margin;
  Result := Window;
  Result.Inflate(-M, -M);
end;

constructor TConDialog.Create;
begin
  Title := 'Dialog';
  Colors := DefaultDialogColors;

  ButtonSidesLeft := '<';
  ButtonSidesRight := '>';

  DefaultIndex := 0;
  ClientMargin:=1;

  AutoWindow := true;
  LimitWidth := true;
  AutoContainer := true;
  AutoClearContainer := true;
end;

destructor TConDialog.Destroy;
begin
  inherited Destroy;
end;

end.
