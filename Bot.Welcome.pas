unit Bot.Welcome;

interface

uses
  System.SysUtils, VK.Bot, VK.Entity.Message, VK.Entity.ClientInfo;

type
  TWelcomeListener = class
    class function Welcome(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
    class function Ended(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
  end;

implementation

uses
  VK.Types, VK.Bot.Utils;

{ TWelcomeListener }

class function TWelcomeListener.Welcome(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
begin
  Result := False;
  case Message.Action.&Type of
    TVkMessageActionType.ChatInviteUser:
      Bot.API.Messages.SendToPeer(Message.PeerId, 'Welcome');
    TVkMessageActionType.ChatKickUser:
      Bot.API.Messages.SendToPeer(Message.PeerId, 'Bye bye, loser');
  end;
  if MessagePatternValue(Message.Text, ['Зануда'], Query) and Query.IsEmpty then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, 'А?');
    Exit(True);
  end;
  if MessagePatternValue(Message.Text, ['/команды', 'зануда команды'], Query) then
  begin
    Result := True;
    Bot.API.Messages.SendToPeer(Message.PeerId,
      '/команды - Список команд'#13#10 +
      '/ip {ip-адрес} - Получить данные об IP'#13#10 +
      '/погода {город} - Получить информацию о погоде'#13#10 +
      '/host {имя хоста} - Узнать IP по имени хоста'#13#10 +
      '/ping {имя хоста или ip} - Пропинговать'#13#10
      );
  end;
end;

class function TWelcomeListener.Ended(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['Зануда'], Query) and (not Query.IsEmpty) then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, 'Сам такой');
    Exit(True);
  end;
end;

end.

