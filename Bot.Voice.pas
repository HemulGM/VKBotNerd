unit Bot.Voice;

interface

uses
  System.SysUtils, VK.Bot, VK.Entity.Message, VK.Entity.ClientInfo,
  SpeechLib_TLB;

type
  TVoiceListener = class
  private
    class var
      FVoice: TSpVoice;
    class function TextToAudioFile(var FN: string; Text: string): Boolean; static;
    class function SendVoice(Bot: TVkBot; PeerId: Integer; const Text: string): Boolean; static;
  public
    class function Proc(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
    class function Anekdot(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
  end;

var
  FNA: Integer = 0;

implementation

uses
  VK.Types, VK.Bot.Utils, VK.Entity.Keyboard, System.StrUtils,
  VK.Entity.Doc.Save, Winapi.ActiveX, System.IOUtils, Winapi.Windows,
  HGM.Common.Download, System.JSON;

{ TVoiceListener }

function CreateRandomAudioFile: string;
begin
  repeat
    Inc(FNA);
    Result := TPath.Combine(TPath.GetLibraryPath, 'audio_cache\audio_text_' + GetTickCount.ToString + '_' + FNA.ToString + '.wav');
  until not FileExists(Result);
  FileClose(FileCreate(Result));
end;

class function TVoiceListener.TextToAudioFile(var FN: string; Text: string): Boolean;
var
  Tokens: ISpeechObjectTokens;
  FS: TSpFileStream;
  AF: TSpAudioFormat;
begin
  CoInitialize(nil);
  try
    Tokens := FVoice.GetVoices('', '');
    FVoice.Voice := Tokens.Item(2);
    FS := TSpFileStream.Create(nil);
    AF := TSpAudioFormat.Create(nil);
    try
      AF.type_ := SAFT48kHz8BitMono;
      FS.Format := AF.DefaultInterface;
      FN := CreateRandomAudioFile;
      FS.Open(FN, SSFMCreateForWrite, False);
      FVoice.AudioOutputStream := FS.DefaultInterface;
      FVoice.Speak(Text, SVSFDefault);
      FS.Close;
    finally
      FS.Free;
      AF.Free;
    end;
    Result := FileExists(FN);
  except
    Result := False;
  end;
  CoUninitialize;
end;

class function TVoiceListener.Anekdot(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
  Json: TJSONObject;
  i: Integer;
begin
  Result := False;
  if not MessagePatternValue(Message.Text, ['/joke', '/анекдот'], Query) then
    Exit;
  for i := 1 to 10 do
  try
    if Result then
      Break;
    if TDownload.GetText('http://rzhunemogu.ru/RandJSON.aspx?CType=1', Query) then
    begin
      try
        Json := TJSONObject(TJSONObject.ParseJSONValue(Query));
      except
        Continue;
      end;
      try
        Query := Json.GetValue('content', '');
        if (Query.Length < 170) and (not Query.IsEmpty) then
        begin
          SendVoice(Bot, Message.PeerId, Query);
          Result := True;
        end;
      finally
        Json.Free;
      end;
    end;
  except
  end;
end;

class function TVoiceListener.SendVoice(Bot: TVkBot; PeerId: Integer; const Text: string): Boolean;
var
  FN: string;
  Doc: TVkDocSaved;
begin
  Result := False;
  if TextToAudioFile(FN, Text) then
  begin
    if Bot.API.Docs.SaveAudioMessage(Doc, FN, ExtractFileName(FN), '', PeerId) then
    begin
      try
        Bot.API.Messages.SendToPeer(PeerId, '', [Doc.AudioMessage.ToAttachment]);
        Result := True;
      finally
        Doc.Free;
      end;
    end;
    TFile.Delete(FN);
  end;
end;

class function TVoiceListener.Proc(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
var
  Query: string;
  Del: Boolean;
begin
  Result := False;
  Del := False;
  if not MessagePatternValue(Message.Text, ['/speak hide ', '/скажи молча '], Query) then
  begin
    if not MessagePatternValue(Message.Text, ['/speak ', '/скажи '], Query) then
      Exit;
  end
  else
    Del := True;
  if Query.Length > 157 then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, 'Слишком длинный текст');
    Exit(True);
  end;
  if Query.IsEmpty then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, 'Издеваешься?!');
    Exit(True);
  end;
  if SendVoice(Bot, Message.PeerId, Query) and Del then
    Bot.API.Messages.DeleteInChat(Message.PeerId, Message.ConversationMessageId, True);
end;

initialization
  Randomize;
  try
    TVoiceListener.FVoice := TSpVoice.Create(nil);
  except
  end;

finalization
  if Assigned(TVoiceListener.FVoice) then
    TVoiceListener.FVoice.Free;

end.

