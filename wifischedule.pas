program wifischedule;

{$mode objfpc}{$H+}
{$scopedenums on}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, Types, WiFiUtils, IniFiles, Cod.Console, Math, DateUtils,
  Cod.ArrayHelpers, Cod.Types, Cod.ConsoleDialogs, crt
  { you can add units after this };

type
  TWorkMode = (Editing, Updating);
  TWifiSel = (None, Ghz50, Ghz24, Both);
  TWifiStat = (Enabled, Disabled, Mismatch);

  TOnPickColor = procedure(var Text: string);

const
  CAT_SETTINGS = 'Config';

var
   I: integer;
   Param: string;

   // Mode
   Mode: TWorkMode;

   // Router
   ConnectSuccess: boolean;
   RetryCount: integer;
   Attempt: integer;
   SleepTime: integer;

   // Changes
   CurrentStatus: TWifiStat;
   NewStatus: boolean;

   // File
   NetConfig: string = 'wificonfig.ini';
   Selection: TWifiSel;
   Hours: array[0..6, 0..23] of boolean;

   // Text
   CAPTION_ON: string = 'ON';
   CAPTION_OFF: string = 'OFF';

  // Editor
  EdWidth, EdHeight: integer;
  ReservedList: integer; // Day of week label
  AllocSpace: integer; // X
  LineSpacing: integer; // Y
  HasFooter: boolean;
  FootFileName: boolean;
  ExtendedHeader: boolean;
  ListStart: integer;
  ExtSpacing: boolean;
  SchedLine: boolean;
  Key: TKeyData;
  Position: TPoint;

procedure OpenHelpDialog;
begin
  TQuickDialog.Message('Help with Scheduler', 'This applications helps you schedule network tasks.'#13#13
    + 'Use the arrow keys to navigate the scheduler.'#13'Use the commands written on the footer to change settings.'#13'Press ENTER/SPACE to toggle.'#13#13
    + 'Supported parameters:'#13
    + '-u --update -> Update the WiFi state based on the schedule'#13
    + '-f --report-file <file> -> Specify a custom report file'#13
    + '-r --retry <count> -> Enter the times to retry login. 1 every minute (Default: 0)'#13
    + '-s --sleep - Enter sleep time in seconds inbetween each retry. (Default 60s)'#13
    + '--about - Get application version and credits'#13
    + '--help - Shows the help information you are currently viewing'#13
    +#13+'Copyright 2023 Petculescu Codrut');
end;

procedure OpenAboutDialog;
begin
    TQuickDialog.Message('About WiFi Scheduler', 'This application toggles the WiFi state of the router based on a schedule.'#13#13
    + 'Version 1.2.0'#13
    + 'Made by: Petculescu Codrut'#13
    + 'Website: www.codrutsoft.com'#13
    + 'Programmed In: Lazarus, Pascal');
end;

function GetNowStatus: boolean;
var
  H, D: integer;
begin
  H := HourOf(Now); // Aleady index

  D := DayOfTheWeek(Now);
  Dec(D); // To Index

  // Get
  Result := Hours[D, H];
end;

procedure ProgramError(AText: string);
var
  AColors: TDialogColors;
  D: TConsoleDialog;
begin
  AColors := DefaultDialogColors;
  AColors.Background:=TConsoleColor.Red;
  AColors.Button:=TConsoleColor.LightGray;
  AColors.ButtonText:=TConsoleColor.White;

  D := TConsoleDialog.Create;

  with D do
    try
      Title := 'Error';
      Text := AText;
      Buttons := ['OKAY', 'HALT'];
      DefaultIndex := 0;
      Colors := AColors;

      if Execute = 1 then
      Halt;
    finally
      Free;
    end;
end;

function TranslateSelection: string;
begin
  case Selection of
    TWifiSel.Ghz24: Result := '2.4Ghz';
    TWifiSel.Ghz50: Result := '5Ghz';
    TWifiSel.Both: Result := 'Both';
    else Result := 'None';
  end;
end;

procedure LoadSchedule;
var
  D, H: integer;
  Cat: string;
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(NetConfig);
  with IniFile do
    try
      // Settings
      Selection := TWifiSel(ReadInteger(CAT_SETTINGS, 'WiFi Frequencies', integer(Selection)));
      Domain := ReadString(CAT_SETTINGS, 'Domain', Domain);
      Password := ReadString(CAT_SETTINGS, 'Password', Password);

      // Schedule
      for D := 0 to 6 do
        begin
          Cat := 'Day ' + D.ToString;

          for H := 0 to 23 do
            Hours[D, H] := ReadBool(Cat, H.ToString, false);
        end;

    finally
      Free;
    end;
end;

procedure SaveSchedule;
var
  D, H: integer;
  Cat: string;
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(NetConfig);
  with IniFile do
    try
      // Settings
      WriteInteger(CAT_SETTINGS, 'WiFi Frequencies', integer(Selection));
      WriteString(CAT_SETTINGS, 'Domain', Domain);
      WriteString(CAT_SETTINGS, 'Password', Password);

      // Schedule
      for D := 0 to 6 do
        begin
          Cat := 'Day ' + D.ToString;

          for H := 0 to 23 do
            WriteBool(Cat, H.ToString, Hours[D, H]);
        end;

    finally
      Free;
    end;
end;

function GenerateList(Day: integer): TStringArray;
var
  I: integer;
begin
  Result := [];

  for I := 0 to 23 do
    if Hours[Day][I] then
      Result.AddValue(CAPTION_ON)
    else
      Result.AddValue(CAPTION_OFF);
end;

procedure DrawLineData(Items: TStringArray; Background: TConsoleColor; Foreground: TConsoleColor; FillLine: boolean; OnPickColor: TOnPickColor = nil);
var
  Text: string;
begin
  if Length(Items) <> 24 then
    Exit;

  TConsole.BgColor:=Background;
  TConsole.TextColor:=Foreground;

  if FillLine then
    TConsole.Write := TConsole.SpacesOfLength(ReservedList-1)
  else
    TConsole.CursorPos := Point(ReservedList, 0);

  for I := 0 to High(Items) do
    begin
      Text := Items[I];

      if Length(Text) > AllocSpace then
        Text := Copy(Text, 1, AllocSpace);

       if Length(Items[I]) < AllocSpace then
         Text := Text;

       if Assigned(OnPickColor) then
         OnPickColor(Text);
       TConsole.Write := Text;

       // Reset
       TConsole.TextColor:=Foreground;
       TConsole.BgColor:=Background;

       // Space
       TConsole.Write := TConsole.SpacesOfLength(AllocSpace-Length(Text))
    end;

  TConsole.Write:=TConsole.SpacesOfLength(EdWidth - TConsole.CursorPos.X);
end;

procedure DrawHeader;
var
  Hours: TStringArray;
  I: integer;
begin
  TConsole.CursorPos := Point(1, 1);
  TConsole.BgColor:=TConsoleColor.Brown;
  TConsole.TextColor:=TConsoleColor.Black;

  // Sched
  if ExtendedHeader then
    TConsole.WriteTitleLine('');
  TConsole.WriteTitleLine(' SCHEDULE MANAGER ');
  if ExtendedHeader then
    TConsole.WriteTitleLine('');

  TConsole.ResetStyle;
  if ExtSpacing then
    TConsole.WriteLn:='';
  if SchedLine then
    TConsole.WriteLn:='Your WiFi schedule:';

  // Days
  TConsole.BgColor:=TConsoleColor.Green;
  TConsole.TextColor:=TConsoleColor.Black;

  Hours := [];
  for I := 0 to 23 do
    Hours.AddValue(I.ToString);
  DrawLineData(Hours, TConsoleColor.Green, TConsoleColor.White, true);

  // Data
  ListStart := TConsole.CursorPos.Y+1;
end;


function DayToString(Day: integer): string;
begin
  case Day of
    0: Exit('MONDAY');
    1: Exit('TUESDAY');
    2: Exit('WENSDAY');
    3: Exit('THURSDAY');
    4: Exit('FRIDAY');
    5: Exit('SATURDAY');
    6: Exit('SUNDAY');
    else Exit('Unknown');
  end;
end;

procedure DrawFooter;
var
  Text: string;
  FootH: integer;
begin
  if not HasFooter then
    Exit;

  FootH := 3;
  if FootFileName then
    Inc(FootH);

  TConsole.CursorPos := Point(1, EdHeight-FootH);
  TConsole.BgColor:=TConsoleColor.LightGray;
  TConsole.TextColor:=TConsoleColor.Black;

  TConsole.ClearLine;
  TConsole.CursorPos := Point(1, EdHeight-FootH+1);
  TConsole.WriteTitleLine(Format('[Q] Quit, [F] File, [E] Edit, [Arrows] Navigate, [ ] Toggle, [H] Help', [TranslateSelection]), ' ');

  // End
  TConsole.BgColor:=TConsoleColor.DarkGray;
  TConsole.CursorPos := Point(1, EdHeight-FootH+2);
  Text := Format('Day: %S, Hour: %D, Last choice: %S, Now: %S', [DayToString(Position.Y), Position.X, Key.ToString.Replace(#13, 'Enter'), booleantostring(GetNowStatus)]);
  TConsole.Write:= Text + TConsole.SpacesOfLength(EdWidth - Length(Text));

  if FootFileName then begin
    TConsole.CursorPos := Point(1, EdHeight-FootH+3);
    Text := Format('File: %S', [NetConfig]);
    TConsole.Write:= Text + TConsole.SpacesOfLength(EdWidth - Length(Text));
  end;
end;

procedure DrawDays;
var
  I: integer;
begin
  TConsole.BgColor:=TConsoleColor.LightCyan;
  TConsole.TextColor:=TConsoleColor.Black;

  for I := ListStart to ListStart + 6 * (LineSpacing+1) do
    begin
       TConsole.LineMove:=I;

       TConsole.Write := '     ';
    end;

  for I := 0 to 6 do
    begin
       TConsole.LineMove:=ListStart + I * (LineSpacing+1);

       TConsole.Write := ' ' + Copy(DayToString(I), 1, 3) + ' ';
    end;
end;

procedure PickColorTable(var Text: string);
begin
  if Copy(Text, 1, 3) = CAPTION_OFF then
    begin
      TConsole.BgColor:=TConsoleColor.Red;
      TConsole.TextColor:=TConsoleColor.LightCyan;
    end;
end;

procedure DrawTable;
var
  I: integer;
begin
  for I := 0 to 6 do
    begin
       TConsole.LineMove:=ListStart + I * (LineSpacing+1);

       DrawLineData(GenerateList(I), TConsoleColor.DarkGray, TConsoleColor.Black, false, @PickColorTable);
    end;

  DrawDays;
end;

procedure DrawAll;
begin
  TConsole.ResetScreen;

  DrawHeader;
  DrawFooter;

  DrawTable;
end;

procedure CalculateData;
var
  Space: integer;
begin
  EdWidth := TConsole.GetWidth;
  EdHeight := TConsole.GetHeight;
  Space := EdHeight;


  { VERY SMOL }
  if (EdWidth < 55) or (EdHeight < 9) then
    ProgramError('The screen size is very small and the application may not render properly. Please resize your terminal');

  { SIZING }
  if EdWidth < 80 then
    begin
      CAPTION_ON := 'O';
      CAPTION_OFF := 'X';
    end;

  { WIDTH }
  ReservedList := 7;
  AllocSpace := (EdWidth-ReservedList) div 24;

  { HEIGHT }
  // Header
  Dec(Space, 3); // Header

  // Min Table (7 days)
  Dec(Space, 7);

  // Footer (1 blank)
  HasFooter := Space > 2;
  if HasFooter then
    Dec(Space, 3);

  FootFileName := Space > 0;
  if FootFileName then
    Dec(Space);

  // Schedule Line
  SchedLine := Space > 0;
  if SchedLine then
    Dec(Space, 1);

  // Header Space
  ExtSpacing := Space > 0;
  if ExtSpacing then
    Dec(Space, 1);

  // Header big
  ExtendedHeader := Space >= 2;
  if ExtendedHeader then
    Dec(Space, 2);

  // Spacing
  LineSpacing := Min((Space-1) div 7, 3);

  // Make usable at least
  if (LineSpacing = 0) and (ExtSpacing or ExtendedHeader) then
    begin
      if (LineSpacing <> (Space) div 7) and ExtSpacing then
        begin
          ExtSpacing := false;
          LineSpacing := 1;
        end
      else
        if (LineSpacing <> (Space+1) div 7) and ExtendedHeader then
          begin
            ExtendedHeader := false;
            Linespacing := 1;
          end
      else
        if (LineSpacing <> (Space+2) div 7) and ExtSpacing and ExtendedHeader then
          begin
            ExtSpacing := false;
            ExtendedHeader := false;
            LineSpacing := 1;
          end;
    end;
end;

procedure SetItemPosition;
begin
  TConsole.CursorPos := Point(ReservedList + Position.X * AllocSpace,
    ListStart + Position.Y * (1+LineSpacing) + abs((Position.Y=-1).ToInteger));
end;

procedure OpenEditor;
var
   I, F: integer;
   B: boolean;

   S: string;
label CloseApp;
begin
  CalculateData;
  DrawAll;

  // Positon
  Position := Point(0, 0);
  SetItemPosition;

  repeat
    if TConsole.KeyPressed then begin
      // Get
      Key := TConsole.WaitUntillKeyPressed;

      // Action
      case Key.SeqLength of
        1: case Key.Base of
          // Toggle
          13, 32: begin
            if Position.Y = -1 then begin
              B := Hours[0, Position.X] <> true;

              for I := 0 to 6 do
                Hours[I, Position.X] := B;
            end else begin
             if Hours[Position.Y, Position.X] then
               Hours[Position.Y, Position.X] := false
             else
               Hours[Position.Y, Position.X] := true;
             end;

            // Draw
            DrawTable;
          end;

          // File
          Ord('f'), Ord('F'): begin
            case TQuickDialog.Picker('File', 'Pick a option', ['Open...', 'Save', 'Save as...', 'Exit', 'Cancel'], 4) of
              0: begin
                S := NetConfig;
                if TQuickDialog.Input('Open...', 'Please type a file name to open to', S) then
                  if fileexists(S) then begin
                    NetConfig := S;
                    LoadSchedule;
                  end
                else
                  ProgramError('That file does not exist');
              end;
              1: SaveSchedule;
              2: begin
                if TQuickDialog.Input('Save as...', 'Please type a file name to save to', NetConfig) then
                  SaveSchedule;
              end;
              3: goto CloseApp;
            end;
            DrawAll;
          end;

          // Manager
          Ord('e'), Ord('E'): begin
            repeat
              I := TQuickDialog.Picker('Edit file', 'What would you like to edit?', [Format('Router Domain (Current: %S)', [DOMAIN]), 'Change password', Format('WiFI Frequency (Current: %S)', [TranslateSelection]), 'Return to scheduler'], 3);
              case I of
                0: begin
                  S := DOMAIN;

                  if TQuickDialog.Input('Edit router domain', 'Enter the new router domain (eg. 192.168.1.104)', DOMAIN) then
                    if Pos('http', DOMAIN) = 0 then
                      Domain := 'http://' + DOMAIN;
                end;
                1: begin
                  S := '';
                  if TQuickDialog.Input('New Password', 'Enter the new router password', S) then
                    PASSWORD := S;
                end;

                2: begin
                  F := TQuickDialog.Dialog('WiFi selection', 'Please choose which of the two wifi networks to toggle.', ['5 Ghz', '2.4Ghz', 'Both', 'Cancel'], 3);
                  if F <> 3 then
                    Selection := TWifiSel(F+1);
                end;
              end;
            until I = 3;
            DrawAll;
          end;

          // Utils
          Ord('q'), Ord('Q'), 27: CloseApp: case TQuickDialog.Dialog('Quit?', 'Are you sure you want to quit the program?', ['Save & Exit', 'Exit', 'Cancel'], 2) of
            0: begin
              SaveSchedule;

              TConsole.ResetScreen;
              Break;
            end;
            1: begin
              TConsole.ResetScreen;
              Break;
            end;
            2: begin
              DrawAll;
              SetItemPosition;
            end;
          end;

          // Help
          Ord('h'), Ord('H'), Ord('a'), Ord('A'): begin
            case TQuickDialog.Picker('Help', 'Pick a option', ['About WiFi Schedule Manager', 'Help information', 'Status', 'Cancel'], 3) of
              0: OpenAboutDialog;
              1: OpenHelpDialog;
              2: TQuickDialog.Message('IDK', 'IDK. I just don'#39't know.');
            end;
            DrawAll;
          end;
        end;

        2: case Key.Sequence[1] of
          75, 77, 72, 80: begin
             case Key.Sequence[1] of
               75: Dec(Position.X);
               77: Inc(Position.X);
               72: Dec(Position.Y);
               80: Inc(Position.Y);
             end;
             Position.Y := EnsureRange(Position.Y, -1, 6);
             Position.X := EnsureRange(Position.X, 0, 23);

             SetItemPosition;
          end;
        end;
      end;

      // Option
      DrawFooter;
      SetItemPosition;
    end;
  until false;

  // Done
  TConsole.ResetScreen;

  TConsole.WriteLn:='[EXIT] Finalised editing with WiFi scheduler.';
end;

function StatusToEnabled(S: TWifiStat): string;
begin
  case S of
    TWifiStat.Disabled: Exit('disabled');
    TWifiStat.Enabled: Exit('enabled');
    TWifiStat.Mismatch: Exit('mixed');
    else Exit('unknown');
  end;
end;

function BooleanToEnabled(B: boolean): string;
begin
  if B then
    Exit('enabled')
  else
    Exit('disabled');
end;

procedure WriteError(Error: string);
begin
  TextColor(7);
  TextBackground(4);
  Write('ERROR:');
  TextBackground(0);

  TextColor(4);
  Write(' ');
  WriteLn(Error);
  TextColor(7);
end;

procedure WriteLnCl(Text: string; TxtColor: byte = 7; BgColor: byte = 0);
begin
  TextColor(TxtColor);
  TextBackground(BgColor);

  Write(Text);

  TextBackground(0);
  TextColor(7);

  WriteLn('');
end;

procedure SetWifiState;
begin
  WriteLn('Setting WiFi status...');

  // Request
  case Selection of
    TWIfiSel.Ghz24: begin
      WriteLn('Writing 2.4Ghz...');
      WifiID := NETWORK_24_ID;

      ToggleWifi(NewStatus);
    end;

    TWIfiSel.Ghz50: begin
      WriteLn('Writing 5.0Ghz...');
      WifiID := NETWORK_5_ID;

      ToggleWifi(NewStatus);
    end;

    TWIfiSel.Both: begin
      WriteLn('Writing 2.4Ghz...');
      WifiID := NETWORK_24_ID;
      ToggleWifi(NewStatus);

      WriteLn('Writing 5.0Ghz...');
      WifiID := NETWORK_5_ID;
      ToggleWifi(NewStatus);
    end;
  end;

  WriteLn('Successfully wrote wifi status');
  WriteLn( Format('WiFi status for "%S" is now "%S"', [TranslateSelection, BooleanToEnabled(NewStatus)]) );
end;

procedure GetWifiState;
var
  First, Second: boolean;
begin
  WriteLn('Loading WiFi status...');

  // Request
  case Selection of
    TWifiSel.Ghz24: begin
      WriteLn('Reading 2.4Ghz...');
      WifiID := NETWORK_24_ID;
      LoadWifi;

      if GetLoadData('bEnable') = '1' then
        CurrentStatus := TWifiStat.Enabled
      else
        CurrentStatus := TWifiStat.Disabled;
    end;

    TWifiSel.Ghz50: begin
      WriteLn('Reading 5.0Ghz...');
      WifiID := NETWORK_5_ID;
      LoadWifi;

      if GetLoadData('bEnable') = '1' then
        CurrentStatus := TWifiStat.Enabled
      else
        CurrentStatus := TWifiStat.Disabled;
    end;

    TWifiSel.Both: begin
      WriteLn('Reading 2.4Ghz...');
      WifiID := NETWORK_24_ID;
      LoadWifi;

      First := GetLoadData('bEnable') = '1';

      WriteLn('Reading 5.0Ghz...');
      WifiID := NETWORK_5_ID;
      LoadWifi;

      Second := GetLoadData('bEnable') = '1';

      if First <> Second then
        CurrentStatus := TWifiStat.Mismatch
      else
        if First then
          CurrentStatus := TWifiStat.Enabled
        else
          CurrentStatus := TWifiStat.Disabled;
    end;
  end;

  // Analise
  WriteLn('Successfully read wifi status');
  WriteLn( Format('WiFi status for "%S" is "%S"', [TranslateSelection, StatusToEnabled(CurrentStatus)]) );
end;

procedure DoMinuteSleep;
const
  Multiplier = 5;
var
  I: integer;
begin
  for i := 0 to SleepTime*Multiplier do
    begin
      // Re-write every second
      if I mod Multiplier = 0 then
        begin
          // Output
          WriteLnCl(Format('Sleeping for %D/%Ds', [I div Multiplier, SleepTime]), 0, 14);

          if I <> SleepTime*Multiplier then
            TConsole.CursorPos := Point(1, WhereY-1);
        end;

      // Check Key
      if KeyPressed and CharInSet(ReadKey, ['c', 'q']) then
        begin
          WriteLnCl('Canceling wait. Final retry', 0, 14);

          RetryCount := 0;
          Attempt := -1;

          Exit;
        end;

      // Sleep
      Sleep(1000 div Multiplier);
    end;
end;

label LoginCommand;
var
  SkipNext: boolean;
begin
  Selection := TWifiSel.Ghz50;
  Mode := TWorkMode.Editing;
  RetryCount := 0;
  Attempt := 0;
  SleepTime := 60;

  for I := 1 to ParamCount do
    begin
      if SkipNext then
        begin
          SkipNext := false;
          Continue;
        end;
      Param := ParamStr(I);

      if (Param = '-u') or (Param = '--update') then
        begin
          Mode := TWorkMode.Updating;
        end
      else
      if (Param = '-f') or (Param = '--report-file') then
        begin
          NetConfig := ParamStr(I+1);
          SkipNext := true;
        end
      else

      if (Param = '-r') or (Param = '--retry') then
        begin
          try
            RetryCount := ParamStr(I+1).ToInteger;
            SkipNext := true;
          except
            WriteError('Invalid retry count!');
            Exit;
          end;
        end
      else
      if (Param = '-s') or (Param = '--sleep') then
        begin
          try
            SleepTime := ParamStr(I+1).ToInteger;
            SkipNext := true;
          except
            WriteError('Invalid sleep time!');
            Exit;
          end;
        end
      else

      if (Param = '--about') then
        begin
          OpenAboutDialog;
          TConsole.ResetScreen;
          Exit;
        end
      else

      if (Param = '--help') then
        begin
          OpenHelpDialog;
          TConsole.ResetScreen;
          Exit;
        end
      else

        // Unknown parameter
        begin
          WriteLn(Format('Unknown parameter "%S". Use --help for a list of all valid parameters', [Param]));
          Exit;
        end;
      end;

  // Read Schedule
  LoadSchedule;

  // Not found
  case Mode of
    TWorkMode.Editing: begin
      OpenEditor;
      Exit;
    end;

    else begin
        // Check exists
        if not fileexists(NetConfig) then
          begin
            ProgramError('The configuration file does not exist. It will be created the next time you edit the schedule.');
            Exit;
          end;

      LoginCommand:

      WriteLn('Logging in...');
      try
        BeginLogin();
        ConnectSuccess := true;
      except
        ConnectSuccess := false;
      end;

      // Check Connect Success
      if not ConnectSuccess then
        begin
          WriteError('Could not connect to router. The IP may be invalid, or you may not have a network connection.');

        if RetryCount > 0 then
          begin
            if Attempt = 0 then
              WriteLn(Format('As the login has failed, we will retry this %D times once every minute.', [RetryCount]));

              if Attempt < RetryCount then
                begin
                  // Sleep
                  DoMinuteSleep;

                  WriteLn('');
                  if Attempt < 0 then
                    WriteLnCl('Final attempt', 7, 1)
                  else
                    WriteLnCl(Format('Attempt %D/%D', [Attempt+1, RetryCount]), 7, 1);

                  // Inc and run
                  Inc(Attempt);
                  GoTo LoginCommand;
                end
            else
              begin
                WriteLn('');
                WriteError('All retries were exausted. The request could not be sent.');
                Exit;
              end;
          end
        else
          Exit;
        end;

      // Check Loggin
      if not LoggedIn then
      begin
        WriteLn('Error! Authentication failed!');
        Exit;
      end;

      WriteLn('Done!');
      WriteLn('');

      // Work
      GetWifiState;

      NewStatus := GetNowStatus;
      if (CurrentStatus = TWifiStat.Mismatch) or ((CurrentStatus = TWifiStat.Enabled) <> NewStatus) then
        begin
          WriteLn('');
          SetWifiState;
        end;
    end;
  end;
end.

