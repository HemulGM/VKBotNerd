unit Bot.YBalaboba;

interface

uses
  System.SysUtils, OWM.API, VK.Bot, VK.Entity.Message, VK.Entity.ClientInfo;

type
  TBalabobaListener = class
  private
    class function SendBla(Bot: TVkBot; PeerId: Integer; const Text: string): Boolean;
  public
    class function Say(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function SayForLast(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
  end;

implementation

uses
  VK.Bot.Utils, VK.Types, System.Classes, System.Net.URLClient, System.NetConsts,
  System.Net.HttpClient, System.JSON, Bot.DB;

{ TBalabobaListener }

class function TBalabobaListener.Say(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['/balaboba ', 'зануда балабоба ', '/бла '], Query) then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, 'Сочиняю...');
    {$WARNINGS OFF}
    Result := SendBla(Bot, Message.PeerId, UTF8EncodeToShortString(Query));
    {$WARNINGS ON}
    if not Result then
      Bot.API.Messages.SendToPeer(Message.PeerId, 'Не удалось выполнить запрос');
  end;
end;

class function TBalabobaListener.SayForLast(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['/бла последнее', 'зануда бла последнее'], Query) then
  begin
    Query := DB.GetStrValue(Message.PeerId, 0, 'last_message', '');
    if not Query.IsEmpty then
    begin
      Bot.API.Messages.SendToPeer(Message.PeerId, 'Сочиняю...');
      Result := SendBla(Bot, Message.PeerId, Query);
      if not Result then
        Bot.API.Messages.SendToPeer(Message.PeerId, 'Не удалось выполнить запрос');
    end;
  end;
end;

class function TBalabobaListener.SendBla(Bot: TVkBot; PeerId: Integer; const Text: string): Boolean;
var
  Query: string;
  Client: THTTPClient;
  Stream, Response: TStringStream;
  JSON: TJSONObject;
begin
  Result := False;
  Client := THTTPClient.Create;
  Client.ContentType := 'application/json';
  Client.AcceptCharSet := 'utf-8';
  Stream := TStringStream.Create;
  Response := TStringStream.Create;
  try
    {$WARNINGS OFF}
    Stream.WriteString('{"query":"' + Text + '","intro":0,"filter":1}');
    Stream.Position := 0;
    if Client.Post('https://zeapi.yandex.net/lab/api/yalm/text3', Stream, Response).StatusCode = 200 then
    try
      JSON := TJSONObject(TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)));
      Query := JSON.GetValue('query', '') + JSON.GetValue('text', '');
      if not Query.IsEmpty then
      begin
        Bot.API.Messages.New.PeerId(PeerId).Message(Query).Send.Free;
        Result := True;
      end;
    except
      on E: Exception do
        Console.AddLine('TBalabobaListener.SendBla: ' + E.Message, RED);
    end;
    {$WARNINGS ON}
  finally
    Response.Free;
    Stream.Free;
    Client.Free;
  end;
end;

end.

