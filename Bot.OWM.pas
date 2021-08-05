unit Bot.OWM;

interface

uses
  System.SysUtils, OWM.API, VK.Bot, VK.Entity.Message, VK.Entity.ClientInfo;

type
  TOWMListener = class
    class var
      OWM: TOWMAPI;
    class function GetCurrentWeather(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
  end;

implementation

uses
  VK.Bot.Utils, OWM.Classes, System.Classes;

{ TOWMListener }

function WeatherToString(Weather: TOWMCurrent): string;
var
  Text: TStringList;

  procedure AddField(Caption: string; Value: string);
  begin
    if Value.IsEmpty then
      Exit;
    Text.Add(Caption + Value);
  end;

begin
  Text := TStringList.Create;
  try
    AddField('Name: ', Weather.Name);
    AddField('Base: ', Weather.Base);
    AddField('Wind.Deg: ', Weather.Wind.Deg.ToString);
    AddField('Wind.Gust: ', Weather.Wind.Gust.ToString);
    AddField('Wind.Speed: ', Weather.Wind.Speed.ToString);
    AddField('Cod: ', Weather.Cod.ToString);
    AddField('Temp: ', Weather.Main.Temp.ToString + ' C');
    AddField('Country: ', Weather.Sys.Country);
    AddField('Humidity: ', Weather.Main.Humidity.ToString);
    AddField('Pressure: ', Weather.Main.Pressure.ToString);
    Result := Text.Text;
  finally
    Text.Free;
  end;
end;

class function TOWMListener.GetCurrentWeather(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
  Weather: TOWMCurrent;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['/погода ', 'зануда погода '], Query) then
  begin
    if Assigned(OWM) and OWM.Current(Weather, Query, TOWMUnit.Metric) then
    try
      Bot.API.Messages.New.PeerId(Message.PeerId).ReplyTo(Message.Id).Message(WeatherToString(Weather)).Send.Free;
      Result := True;
    finally
      Weather.Free;
    end;
    if not Result then
      Bot.API.Messages.New.PeerId(Message.PeerId).ReplyTo(Message.Id).Message('Не удалось получить данные о погоде').Send.Free;
  end;
end;

initialization
  TOWMListener.OWM := TOWMAPI.Create(nil, '36994c7b370d2e4c0753e34696105d7c');

finalization
  if Assigned(TOWMListener.OWM) then
    TOWMListener.OWM.Free;

end.

