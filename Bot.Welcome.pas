unit Bot.Welcome;

interface

uses
  System.SysUtils, System.Classes, VK.Bot, VK.Entity.Message,
  VK.Entity.ClientInfo;

type
  TGeneralListener = class
    class var
      CensorWords: TStringList;
    class function Welcome(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function Mute(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function Ended(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function Censor(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class procedure Init;
    class function CheckForCensor(Value: string; var FindWord: string): Boolean;
  end;

implementation

uses
  VK.Types, VK.Bot.Utils, HGM.SQLang, System.IOUtils, Bot.DB, VK.Entity.ScreenName;

{ TGeneralListener }

class procedure TGeneralListener.Init;
begin
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
end;

class function TGeneralListener.Mute(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
  Item: TVkScreenNameType;
  UserId: Integer;
begin
  Result := False;
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
end;

class function TGeneralListener.Welcome(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Id: Integer;
  Query: string;
begin
  Result := False;
  Id := DB.GetTableValue('SELECT id FROM users WHERE chat_id = ? AND user_id = ?', [Message.PeerId, Message.FromId]);
  if Id < 0 then
    DB.ExecSQL('INSERT INTO users (chat_id, user_id, date) VALUES (?, ?, ?)', [Message.PeerId, Message.FromId, Now])
  else
    DB.ExecSQL('UPDATE users SET chat_id = ?, user_id = ?, date = ? WHERE id = ?', [Message.PeerId, Message.FromId, Now, Id]);
  //
  case Message.Action.&Type of
    TVkMessageActionType.ChatInviteUser:
      Bot.API.Messages.SendToPeer(Message.PeerId, 'Welcum');
    TVkMessageActionType.ChatKickUser:
      Bot.API.Messages.SendToPeer(Message.PeerId, 'Bye bye, loser');
  end;
  if MessagePatternValue(Message.Text, ['������'], Query) and Query.IsEmpty then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, '�?');
  end;
  if MessagePatternValue(Message.Text, ['/�������', '������ �������'], Query) then
  begin
    Result := True;
    Bot.API.Messages.SendToPeer(Message.PeerId,
      '/������� - ������ ������'#13#10 +
      '/ip {ip-�����} - �������� ������ �� IP'#13#10 +
      '/������ {�����} - �������� ���������� � ������'#13#10 +
      '/host {��� �����} - ������ IP �� ����� �����'#13#10 +
      '/ping {��� ����� ��� ip} - ������������'#13#10 +
      '/��� ������� - ��� �������'#13#10 +
      '/speak hide {�����}, /����� ����� {�����}, /speak {�����}, /����� {�����} - �������� �����'#13#10 +
      '/joke, /������� - ���������� ����� ������� (�����)'#13#10 +
      '/balaboba {�����}, ������ �������� {�����}, /��� {�����} - �������� �������'#13#10 +
      '/��� ���������, ������ ��� ��������� - �������� ������� �� ��������� ���������'
      );
  end;
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
  Str: string;
begin
  Result := False;
  if CheckForCensor(Message.Text.ToLowerInvariant, Str) then
    Bot.API.Messages.SendToPeer(Message.PeerId, '����� ��� ����, ��? � ������, ��� ����� "' + Str + '" - ���.');
end;

class function TGeneralListener.Ended(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['������'], Query) and (not Query.IsEmpty) then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, '��� �����');
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

