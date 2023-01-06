unit Bot.Welcome;

interface

uses
  System.SysUtils, System.Classes, VK.Bot, VK.Entity.Message, VK.Entity.Media,
  VK.Entity.ClientInfo;

type
  TGeneralListener = class
    const
      Bot_ID = '[club192458090|@botnerd]';
      HelpText = '/команды - Список команд'#13#10 +
'/ip {ip-адрес} - Получить данные об IP'#13#10 +
'/погода {город} - Получить информацию о погоде'#13#10 +
'/host {имя хоста} - Узнать IP по имени хоста'#13#10 +
'/ping {имя хоста или ip} - Пропинговать'#13#10 +
'/гей рулетка - Гей рулетка'#13#10 +
'/speak hide {текст}, /скажи молча {текст}, /speak {текст}, /скажи {текст} - Озвучить текст'#13#10 +
'/joke, /анекдот - Рассказать тупой анекдот (голос)'#13#10 +
'/balaboba {текст}, зануда балабоба {текст}, /бла {текст} - Сочинить историю'#13#10 +
'/бла последнее, зануда бла последнее - Сочинить историю на последнее сообщение'#13#10 +
'/звук {текст} - Найти случайную звуковую дорожку по тексту';
    class var
      CensorWords: TStringList;
    class function Welcome(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function Mute(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function Ended(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function Censor(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function CountMessages(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function SaveLastMessage(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class procedure Init;
    class function CheckForCensor(Value: string; var FindWord: string): Boolean;
    class function Sticker(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
  private
    class procedure SendAskHelp(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo); static;
  end;

implementation

uses
  VK.Types, VK.Bot.Utils, HGM.SQLang, System.IOUtils, Bot.DB,
  VK.Entity.ScreenName, VK.Entity.Keyboard, System.StrUtils, VK.Entity.Sticker;

{ TGeneralListener }

class procedure TGeneralListener.Init;
begin
  Console.AddText('GeneralListener initializate...');
  with SQL.CreateTable('users') do
  try
    AddField('id', ftInteger, True, True);
    AddField('chat_id', ftInteger);
    AddField('user_id', ftInteger);
    AddField('date', ftDateTime);
    DB.ExecSQL(GetSQL);
  finally
    EndCreate;
  end;
  Console.AddLine('Ok', GREEN);
end;

class function TGeneralListener.Mute(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
  Item: TVkScreenNameType;
  UserId: Integer;
begin
  Result := False;
  try
    if MessagePatternValue(Message.Text, ['/mute '], Query) and (not Query.IsEmpty) then
    begin
      if Query.StartsWith('[') then
        if Bot.API.Utils.ResolveScreenName(Item, ParseUserAlias(Query).UserId) then
        try
          UserId := Item.ObjectId;
          Bot.API.Messages.SendToPeer(Message.PeerId, 'Mute: ' + UserId.ToString + ', you is admin = ' + TVkBotChat(Bot).IsAdmin(Message.PeerId, Message.FromId).ToString);
        finally
          Item.Free;
        end;
    end;
  except
  end;
end;

class function TGeneralListener.SaveLastMessage(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
begin
  Result := False;
  try
    if PeerIdIsUser(Message.FromId) then
      DB.SetValue(Message.PeerId, 0, 'last_message', Message.Text);
  except
  end;
end;

class function TGeneralListener.CountMessages(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
begin
  Result := False;
  try
    if PeerIdIsUser(Message.FromId) then
    begin
      DB.IncValue(Message.PeerId, Message.FromId, 'count');
      DB.SetValue(Message.PeerId, Message.FromId, 'last_message_date', Now);
    end;
  except
    //
  end;
end;

class function TGeneralListener.Welcome(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Id: Integer;
  Query: string;
begin
  Result := False;
  try
    Id := DB.GetTableValue('SELECT id FROM users WHERE chat_id = ? AND user_id = ?', [Message.PeerId, Message.FromId]);
    if Id < 0 then
      DB.ExecSQL('INSERT INTO users (chat_id, user_id, date) VALUES (?, ?, ?)', [Message.PeerId, Message.FromId, Now])
    else
      DB.ExecSQL('UPDATE users SET chat_id = ?, user_id = ?, date = ? WHERE id = ?', [Message.PeerId, Message.FromId, Now, Id]);
    //
    if Assigned(Message.Action) then
      case Message.Action.&Type of
        TVkMessageActionType.ChatInviteUser:
          Bot.API.Messages.SendToPeer(Message.PeerId, 'Welcum');
        TVkMessageActionType.ChatKickUser:
          Bot.API.Messages.SendToPeer(Message.PeerId, 'Bye bye, loser');
      end;
    if MessagePatternValue(Message.Text, ['Зануда', Bot_ID], Query) and Query.IsEmpty then
    begin
      Bot.API.Messages.SendToPeer(Message.PeerId, 'А?');
    end;
    if MessagePatternValue(Message.Text, ['/команды', 'зануда команды'], Query) then
    begin
      Result := True;
      Bot.API.Messages.SendToPeer(Message.PeerId, HelpText);
    end;
    if Assigned(Message.PayloadButton) then
    begin
      case IndexStr(Message.PayloadButton.Button, ['ask_help_yes', 'ask_help_no']) of
        0:
          begin
            if Random(6) = 2 then
              Query := 'Ну, кароче...' + #13#10 +
                HelpText
            else
              Query := 'Вот, болван, ' + #13#10 +
                HelpText;
          end;
        1:
          if Random(6) = 2 then
            Query := 'Пидора ответ'
          else
            Query := 'Тогда не упоминай моё имя в суе!';
      else
        Query := '';
      end;

      if not Query.IsEmpty then
      begin
        Bot.API.Messages.New.PeerId(Message.PeerId).Message(Query).Send;
        Exit(True);
      end;
    end
    else if MessagePatternValue(Message.Text, [Bot_ID], Query) and not Query.IsEmpty then
    begin
      SendAskHelp(Bot, GroupId, Message, ClassInfo);
      Exit(True);
    end;
  except
  end;
end;

class procedure TGeneralListener.SendAskHelp(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo);
var
  Keys: string;
  Keyboard: TVkKeyboardConstruct;
begin
  Keyboard := TVkKeyboard.Construct;
  try
    Keyboard.InlineKeys(True);
    with Keyboard.AddLine do
    begin
      AddButton(TVkKeyboardButtonConstruct.CreateText('Да', ButtonPayload('ask_help_yes'), TVkKeyboardButtonColor.Positive));
      AddButton(TVkKeyboardButtonConstruct.CreateText('Нет', ButtonPayload('ask_help_no'), TVkKeyboardButtonColor.Secondary));
    end;
    Keys := Keyboard.ToJsonString;
  finally
    Keyboard.Free;
  end;
  Bot.API.Messages.New.PeerId(Message.PeerId).Message('Ты че, не знаешь че спросить?').Keyboard(Keys).Send;
end;

class function TGeneralListener.CheckForCensor(Value: string; var FindWord: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  FindWord := '';
  for i := 0 to CensorWords.Count - 1 do
    if Value.Contains(CensorWords[i]) then
    begin
      FindWord := CensorWords[i];
      Exit(True);
    end;
end;

class function TGeneralListener.Censor(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  i: Integer;
  Str, Txt: string;
  Strs: TArrayOfString;
begin
  Result := False;
  if CheckForCensor(Message.Text.ToLowerInvariant, Str) then
  begin
    Strs := [
      'Давай без мата, ок? Я считаю, что слово "%s" - мат.',
      'Может без мата, а? Это "%s" ж - мат. Вроде как.',
      'Слушай, может ты завалишь варежку? Матерится он тут.',
      'МАТА НЕ НАДА. НЕ НАДА МАТА.',
      'Фу, бля, матершинник.'];
    i := Random(Length(Strs));
    Txt := Format(Strs[i], [Str]);
    TDB.IncValue(Message.PeerId, Message.FromId, 'censor');
    if Random(10) in [2, 5, 7] then
      Txt := Txt + #13#10 + 'У тебя уже ' + TDB.GetIntValue(Message.PeerId, Message.FromId, 'censor', 1).ToString + ' мат.';
    Bot.API.Messages.SendToPeer(Message.PeerId, Txt);
  end;
end;

class function TGeneralListener.Sticker(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Sticker: TVkSticker;
begin
  Result := False;
  if Message.Attachments.GetByType(TVkAttachmentType.Sticker, Sticker) then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, Sticker.StickerId.ToString);
  end;
end;

class function TGeneralListener.Ended(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['зануда '], Query) and (not Query.IsEmpty) then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, 'Сам ' + Query);
    Exit(True);
  end;
end;

initialization
  TGeneralListener.CensorWords := TStringList.Create;
  try
    if TFile.Exists('censor.txt') then
      TGeneralListener.CensorWords.LoadFromFile('censor.txt', TEncoding.UTF8);
  except
  end;

finalization
  TGeneralListener.CensorWords.Free;

end.

