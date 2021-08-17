unit Bot.RandomNoise;

interface

uses
  System.SysUtils, OWM.API, VK.Bot, VK.Entity.Message, VK.Entity.ClientInfo;

type
  TRandomNoiseListener = class
  public
    class function Proc(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean; static;
    class function SendDoc(Bot: TVkBot; PeerId: Integer; const FN: string): Boolean; static;
  end;

implementation

uses
  VK.Bot.Utils, VK.Types, System.Classes, System.Net.URLClient, System.NetConsts,
  System.Net.HttpClient, System.JSON, Bot.DB, Bot.Voice, VK.Entity.Doc.Save,
  System.IOUtils, Winapi.Windows;

{ TRandomNoiseListener }

function CreateRandomAudioFile: string;
begin
  repeat
    Inc(FNA);
    Result := TPath.Combine(TPath.GetLibraryPath, 'audio_cache\audio_text_' + GetTickCount.ToString + '_' + FNA.ToString + '.mp3');
  until not FileExists(Result);
  FileClose(FileCreate(Result));
end;

class function TRandomNoiseListener.SendDoc(Bot: TVkBot; PeerId: Integer; const FN: string): Boolean;
var
  Doc: TVkDocSaved;
begin
  Result := False;
  if Bot.API.Docs.SaveAudioMessage(Doc, FN, ExtractFileName(FN), '', PeerId) then
  begin
    try
      Bot.API.Messages.SendToPeer(PeerId, '', [Doc.AudioMessage.ToAttachment]);
      Result := True;
    finally
      Doc.Free;
    end;
  end;
end;

class function TRandomNoiseListener.Proc(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query, FN: string;
  Client: THTTPClient;
  Response: TStringStream;
  FL: TFileStream;
  i: Integer;
begin
  Result := False;
  if MessagePatternValue(Message.Text, ['/звук ', 'зануда звук '], Query) and (not Query.IsEmpty) then
  begin
    Client := THTTPClient.Create;
    Client.AcceptCharSet := 'utf-8';
    Response := TStringStream.Create;
    try
      if Client.Get('https://noisefx.ru/?s=' + Query, Response).StatusCode = 200 then
      try            
        {$WARNINGS OFF}
        Query := UTF8ToString(Response.DataString);   
        {$WARNINGS ON}
        if not Query.IsEmpty then
        begin
          i := Query.IndexOf('.mp3'); //<a href="/noise_base/05/02490.mp3" style="display: none;">02490</a>
          if i > 0 then
          begin
            Query := Query.Substring(0, i + 4);
            for i := Query.Length downto 1 do
              if Query[i] = '"' then
              begin
                Query := Query.Substring(i, 100);
                Result := True;
                Break;
              end;
            if Result then
            begin
              Query := 'https://noisefx.ru' + Query;
              FN := CreateRandomAudioFile;
              FL := TFileStream.Create(FN, fmCreate);
              try
                try
                  Bot.API.Messages.SendToPeer(Message.PeerId, 'Ща погодь...');
                  Result := Client.Get(Query, FL).StatusCode = 200;
                except
                  Result := False;
                end;
                if Result then
                begin
                  FL.Free;
                  FL := nil;
                  Result := False;
                  Query := FN;
                  if FileExists(Query) and TVoiceListener.ConvertToOgg(Query, False) then
                  begin
                    Result := SendDoc(Bot, Message.PeerId, Query);
                  end;
                end;
              finally
                if Assigned(FL) then
                  FL.Free;
                if TFIle.Exists(FN) then
                  TFile.Delete(FN);
              end;
            end;
          end;
          if not Result then
            Bot.API.Messages.SendToPeer(Message.PeerId, 'Не нашёл ни чё');
        end;
      except
        on E: Exception do
        begin
          Console.AddLine('TRandomNoiseListener.Proc: ' + E.Message, RED);
          Bot.API.Messages.SendToPeer(Message.PeerId, 'Не получилось найти. Разрабу скажи. Ошибка какая-то. Я хз');
          Result := False;
        end;
      end;
    finally
      Response.Free;
      Client.Free;
    end;
  end;
end;

end.

