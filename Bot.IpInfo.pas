unit Bot.IpInfo;

interface

uses
  System.SysUtils, HGM.IpInfo, VK.Bot, VK.Entity.Message, VK.Entity.ClientInfo;

type
  TIpInfoListener = class
    class var
      IpInfo: TIpInfo;
    class function GetIpInfo(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
  end;

implementation

uses
  VK.Bot.Utils, System.Classes;

{ TIpInfoListener }

function DetailsToString(Details: TIpDetails): string;
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
    AddField('IP: ', Details.IP);
    AddField('City: ', Details.City);
    AddField('Country: ', Details.Country);
    AddField('Hostname: ', Details.Hostname);
    AddField('Loc: ', Details.Loc);
    AddField('Org: ', Details.Org);
    AddField('Postal: ', Details.Postal);
    AddField('Readme: ', Details.Readme);
    AddField('Region: ', Details.Region);
    AddField('Timezone: ', Details.Timezone);
    Result := Text.Text;
  finally
    Text.Free;
  end;
end;

class function TIpInfoListener.GetIpInfo(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  IP: string;
  Details: TIpDetails;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['/ip ', 'зануда ip '], IP) then
  begin
    if Assigned(IpInfo) and IpInfo.GetDetails(Details, IP) then
    try
      Bot.API.Messages.New.PeerId(Message.PeerId).ReplyTo(Message.Id).Message(DetailsToString(Details)).Send.Free;
      Result := True;
    finally
      Details.Free;
    end;
    if not Result then
      Bot.API.Messages.New.PeerId(Message.PeerId).ReplyTo(Message.Id).Message('Ќе удалось получить данные об IP').Send.Free;
  end;
end;

initialization
  TIpInfoListener.IpInfo := TIpInfo.Create('f6d3b0cfcff745');

finalization
  if Assigned(TIpInfoListener.IpInfo) then
    TIpInfoListener.IpInfo.Free;

end.

