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
  VK.Types, VK.Bot.Utils, VK.Entity.Keyboard, System.StrUtils;

{ TGameShootListener }

class function TGameShootListener.Proc(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query, Keys: string;
  Keyboard: TVkKeyboardConstruct;
begin
  Result := False;
  Keyboard := TVkKeyboard.Construct;
  try
    Keyboard.InlineKeys(True);
    with Keyboard.AddLine do
    begin
      AddButton(TVkKeyboardButtonConstruct.CreateText('Выстрелить', ButtonPayload('game_shoot'), TVkKeyboardButtonColor.Negative));
      AddButton(TVkKeyboardButtonConstruct.CreateText('Я сыкло', ButtonPayload('game_shoot_lose'), TVkKeyboardButtonColor.Secondary));
    end;
    Keys := Keyboard.ToJsonString;
  finally
    Keyboard.Free;
  end;
  if Assigned(Message.PayloadButton) then
  begin
    case IndexStr(Message.PayloadButton.Button, ['game_shoot', 'game_shoot_lose']) of
      0:
        begin
          //Bot.API.Messages.DeleteInChat(Message.PeerId, Message.ConversationMessageId, True);
          if Random(6) = 2 then
            Query := '😵🔫 У нас натурал!' + #13#10 +
              'Может быть на том свете тебе повезёт больше. Покойся с миром.'
          else
            Query := '😨🔫 Вот это смельчак! Ты остался геем после нажатия на курок!' + #13#10 +
              'Больше так не рискуй. Подумай о маме и папе!';
        end;
      1:
        Query := 'У нас тут лузер 🤪';
    else
      Query := '';
    end;

    if not Query.IsEmpty then
    begin
      Bot.API.Messages.New.PeerId(Message.PeerId).Message(Query).Keyboard(Keys).Send.Free;
      Exit(True);
    end;
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

