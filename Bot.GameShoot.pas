unit Bot.GameShoot;

interface

uses
  System.SysUtils, VK.Bot, VK.Entity.Message, VK.Entity.ClientInfo;

type
  TGameShootListener = class
    class function Proc(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
  end;

implementation

uses
  VK.Types, VK.Bot.Utils;

{ TGameShootListener }

class function TGameShootListener.Proc(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query, Keys: string;
begin
  Result := False;
  Keys := '' +
    '{' +
    '  "one_time":false, ' +
    '  "inline":true, ' +
    '  "buttons":' +
    '      [ ' +
    '        [ ' +
    '          { "action": ' +
    '             { "type": "text", ' +
    '               "payload": "{\"button\": \"game_shoot\"}", ' +
    '               "label": "Выстрелить" ' +
    '             }, ' +
    '            "color":"negative"' +
    '          }' +
    '        ]' +
    '      ]' +
    '}';
  if not Message.Payload.IsEmpty then
  begin
    if Message.Payload = '{"button":"game_shoot"}' then
      if Random(10) in [1, 5] then
        Query := '😵🔫 У нас натурал!' + #13#10 +
          'Может быть на том свете тебе повезёт больше. Покойся с миром.'
      else
        Query := '😨🔫 Вот это смельчак! Ты остался геем после нажатия на курок!' + #13#10 +
          'Больше так не рискуй. Подумай о маме и папе!';
    Bot.API.Messages.New.PeerId(Message.PeerId).Message(Query).Keyboard(Keys).Send.Free;
  end;
  if MessageIncludeAll(Message.Text, ['зануда', 'гей', 'рулетка']) then
  begin
    Bot.API.Messages.New.PeerId(Message.PeerId).Message('Кто тут у нас натурал?').Keyboard(Keys).Send.Free;
    Exit(True);
  end;
end;

initialization
  Randomize;

end.

