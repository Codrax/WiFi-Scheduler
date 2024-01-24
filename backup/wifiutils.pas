unit WiFiUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient;

function Request(URL:string; ARequest: string = ''): string;

  // WiFi
  procedure ToggleWifi(Enable: boolean);
  procedure LoadWifi;

  // Login
  procedure BeginLogin;
  procedure DoLogin;

  // Data
  function GetLoadData(AProp: string): string;

  // Auth
  procedure parseAuthRlt(AuthCode: string);
  function orgAuthPwd(Password: string): string;
  function SecurityEncode(F, D, K: string): string;
  function encodeURL(OriginalString: string): string;

  procedure Auth(Value: string);

  // Constant Builder
  function GET_DATA: string;
  function GET_LOGIN: string;
  function SET_SETTING: string;
  function GET_SETTING: string;

const
  // IDs
  NETWORK_5_ID = '53';
  NETWORK_24_ID = '33';

  DEF_DATA = '?code=2&asyn=1';

  DEF_LOGIN = '?code=7&asyn=0&id=%S';
  DEF_SET_SETTING = '?code=1&asyn=0&id=%S';
  DEF_GET_SETTING = '?code=2&asyn=0&id=%S';

var
  DOMAIN: string;

  PASSWORD: string;

  // Auth
  authInfo: array[1..4] of string;

  LoginURL: string;
  SessionID: string;

  WifiID: string = NETWORK_5_ID;

  LoggedIn: boolean = false;

  LoadedData: TStringArray;


implementation

function Request(URL: string; ARequest: string): string;
var
  HTTP: TFPHttpClient;
  RequestStream: TStringStream;
  ResponseStream: TStringStream;
begin
  // Create HTTP and SSLIOHandler components
  HTTP := TFPHttpClient.Create(nil);

  // Request
  RequestStream := TStringStream.Create(ARequest);
  ResponseStream := TStringStream.Create('');
  try
    // Set headers
    //HTTP.HTTPOptions := HTTP.HTTPOptions + [hoNoProtocolErrorException, hoWantProtocolErrorContent];

    // Send POST
    HTTP.RequestBody := RequestStream;
    HTTP.Post(URL, ResponseStream);

    Result := ResponseStream.DataString;
  finally
    // Free
    HTTP.Free;
    RequestStream.Free;
  end;
end;

procedure ToggleWifi(Enable: boolean);
var
  URL, Data: string;
begin
  Data := 'id ' + WifiID + #$A#$D'bEnable ';
  if Enable then
    Data := ConCat(Data, '1')
  else
    Data := ConCat(Data, '0');

  URL := Format(SET_SETTING, [sessionID]);

  Data := Request(URL, Data);
end;

procedure LoadWifi;
var
  URL, Data: string;
begin
  URL := Format(GET_SETTING, [sessionID]);

  Data := 'id ' + WifiID;
  Data := Request(URL, Data);

  LoadedData := Data.Replace(#$D, '').Split([#$A]);
end;

procedure BeginLogin;
var
  Data: string;
  PassEncode: string;
begin
  // Temp Code
  Data := Request( GET_DATA );

  // Get Auth Info
  parseAuthRlt(Data);

  // Auth
  PassEncode := orgAuthPwd( PASSWORD );
  Auth( PassEncode );
end;

procedure DoLogin;
var
  Data: string;
begin
  Data := Request(LoginURL);

  // Logged In
  LoggedIn := Copy(Data, 1, 5) <> '00007';
end;

function GetLoadData(AProp: string): string;
var
  Prop: string;
  Value: string;
  S: TStringArray;
  I: integer;
begin
  Result := '';
  for i := 0 to High(LoadedData) do
    begin
      S := LoadedData[i].Split([' ']);
      if Length(S) < 2 then
        Continue;
      Prop := S[0];
      Value := S[1];

      if Prop = AProp then
        Exit(StringReplace(Value, '%20', ' ', [rfReplaceAll]));
    end;
end;

procedure parseAuthRlt(AuthCode: string);
var
  UTHCode: TStringArray;
begin
  UTHCode := AuthCode.Replace(#$D, '').Split([#$A]);

  authInfo[1] := UTHCode[1];
  authInfo[2] := UTHCode[2];
  authInfo[3] := UTHCode[3];
  authInfo[4] := UTHCode[4];
end;

function orgAuthPwd(Password: string): string;
const
  B = 'RDpbLfCPsJZ7fiv';
  A = 'yLwVl0zKqws7LgKPRQ84Mdt708T1qQ3Ha7xv3H7NyU84p21BriUWBU43odz3iP4rBL3cD02KZciXTysVXiV8ngg6vL48rPJyAUw0HurW20xqxv9aYb4M9wK1Ae0wlro510qXeU07kV57fQMc8L6aLgMLwygtc0F10a0Dg70TOoouyFhdysuRMO51yY5ZlOZZLEal1h0t9YQW0Ko7oBwmCAHoic4HYbUyVeU3sfQ1xtXcPcf1aT303wAQhv66qzW';
begin
  Result := securityEncode(Password, B, A);
end;

function SecurityEncode(F, D, K: string): string;
var
  h, e, c, j: integer;
  l, i: integer;
  g: integer;
begin
  Result := '';
  l := 187;
  i := 187;

  e := f.length;
  c := d.length;
  j := K.length;
  if e > c then
    h := e
  else
    h := c;

  for g := 0 to h-1 do
    begin
      l := 187;
      i := 187;
      if (g >= e) then
        i := Ord(d[g+1])
      else
        begin
          if (g >= c) then
            l := Ord(f[g+1])
          else
            begin
              l := Ord(f[g+1]);
              i := Ord(d[g+1]);
            end;
        end;

      Result := Result + K[(l xor i) mod j + 1];
    end;
end;

function encodeURL(OriginalString: string): string;
begin
     Result := OriginalString;
end;

procedure Auth(Value: string);
var
  Session: string;
begin
  // Session
  Session := SecurityEncode(authInfo[3], Value, authInfo[4]);
  SessionID := encodeURL(Session);

  // Format
  LoginURL := Format(GET_LOGIN, [sessionID]);

  // Login
  DoLogin;
end;

function GET_DATA: string;
begin
  Result := Domain + DEF_DATA;
end;

function GET_LOGIN: string;
begin
  Result := Domain + DEF_LOGIN;
end;

function SET_SETTING: string;
begin
  Result := Domain + DEF_SET_SETTING;
end;

function GET_SETTING: string;
begin
  Result := Domain + DEF_GET_SETTING;
end;

end.

