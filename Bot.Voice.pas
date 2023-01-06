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
    class function ConvertToOgg(var Target: string; DeleteSource: Boolean): Boolean; static;
    class function Proc(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
    class function Anekdot(Bot: TVkBot; GroupId: Integer; Message: TVkMessage; ClientInfo: TVkClientInfo): Boolean;
  end;

var
  FNA: Integer = 0;

implementation

uses
  VK.Types, VK.Bot.Utils, VK.Entity.Keyboard, System.StrUtils,
  VK.Entity.Doc.Save, Winapi.ActiveX, System.IOUtils, Winapi.Windows,
  HGM.Common.Download, System.JSON, bass, bassenc;

{ TVoiceListener }

class function TVoiceListener.ConvertToOgg(var Target: string; DeleteSource: Boolean): Boolean;
var
  Stream: HSTREAM;
  Encode: HENCODE;
  Cmd, Old: string;
  Bytes: TByteArray;
begin
  Result := False;
  Old := Target;
  Stream := BASS_StreamCreateFile(False, PAnsiChar(AnsiString(Old)), 0, 0, BASS_STREAM_DECODE);
  if Stream <> 0 then
  begin
    Target := StringReplace(Old, '.wav', '.ogg', [rfIgnoreCase, rfReplaceAll]);
    Target := StringReplace(Target, '.mp3', '.ogg', [rfIgnoreCase, rfReplaceAll]);
    FileClose(FileCreate(Target));
    Cmd := TPath.Combine(TPath.GetLibraryPath, 'oggenc2.exe') + ' -o "' + Target + '" -';
    Encode := BASS_Encode_Start(Stream, PAnsiChar(AnsiString(Cmd)), BASS_ENCODE_AUTOFREE, nil, nil);
    while (BASS_ChannelIsActive(Stream) <> BASS_ACTIVE_STOPPED) and (BASS_Encode_IsActive(Encode) <> BASS_ACTIVE_STOPPED) do
    begin
      BASS_ChannelGetData(Stream, @Bytes, SizeOf(Bytes));
      Result := True;
    end;

    BASS_StreamFree(Stream);
    if Result then
    begin
      if DeleteSource then
        TFile.Delete(Old);
    end
    else
      Target := Old;
  end;
end;

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
  FS: TSpFileStream;
  AF: TSpAudioFormat;
begin
  CoInitialize(nil);
  try
    FS := TSpFileStream.Create(nil);
    AF := TSpAudioFormat.Create(nil);
    try
      AF.type_ := SAFT48kHz8BitMono;
      FS.Format := AF.DefaultInterface;
      FN := CreateRandomAudioFile;
      FS.Open(FN, SSFMCreateForWrite, False);
      FVoice.AudioOutputStream := FS.DefaultInterface;
      FVoice.Speak(StringReplace(Text, #13#10, ' ', [rfReplaceAll]), SVSFDefault);
      FS.Close;
    finally
      FS.Free;
      AF.Free;
    end;
    Result := FileExists(FN) and ConvertToOgg(FN, True);
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
        Json := TJSONObject.ParseJSONValue(Query) as TJSONObject;
      except
        Continue;
      end;
      if Assigned(Json) then
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
const
  Limit = 1000;
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
  if Query.Length > Limit then
  begin
    Bot.API.Messages.SendToPeer(Message.PeerId, 'Слишком длинный текст. Можно максимум ' + Limit.ToString + ', а у тебя ' + Query.Length.ToString);
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

var
  Tokens: ISpeechObjectTokens;

initialization
  Randomize;
  try
    Console.AddText('Voice initializate...');
    TVoiceListener.FVoice := TSpVoice.Create(nil);
    Tokens := TVoiceListener.FVoice.GetVoices('', '');
    Console.AddLine(Tokens.Item(0).GetDescription(LOCALE_USER_DEFAULT), GREEN);
    TVoiceListener.FVoice.Voice := Tokens.Item(0);
  except
  end;
  Console.Addtext('Bass initializate...');
  if BASS_Init(-1, 44100, 0, 0, nil) then
    Console.AddLine('Ok', GREEN)
  else
    Console.AddLine('Fail', RED);

finalization
  if Assigned(TVoiceListener.FVoice) then
    TVoiceListener.FVoice.Free;

end.

