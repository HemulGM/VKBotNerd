unit Bot.Ping;

interface

uses
  System.SysUtils, HGM.IPPing, VK.Bot, VK.Entity.Message, VK.Entity.ClientInfo;

type
  TPingListener = class
    class function Ping(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
    class function HostToIp(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
  end;

implementation

uses
  VK.Bot.Utils, System.Classes;

{ TPingListener }

class function TPingListener.HostToIp(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query, IP: string;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['/host ', '������ host '], Query) then
  begin
    Result := True;
    if HostNameToIP(Query, IP) then
      Bot.API.Messages.SendToPeer(Message.PeerId, Query + ': ' + IP)
    else
      Bot.API.Messages.SendToPeer(Message.PeerId, '�� ������� ��������� ������');
  end;
end;

class function TPingListener.Ping(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  i: Integer;
  Query: string;
  Time: Cardinal;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['/ping ', '������ ping '], Query) then
  begin
    Result := True;
    for i := 1 to 4 do
    begin
      if PingHost(Query, Time, 2000) then
        Bot.API.Messages.SendToPeer(Message.PeerId, '����� �� ' + Query + ': ����� ����=32 �����=' + Time.ToString + '��')
      else
        Bot.API.Messages.SendToPeer(Message.PeerId, '�� ������� ��������� ������')
    end;
  end;
end;

end.

