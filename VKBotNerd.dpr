program VKBotNerd;

{$APPTYPE CONSOLE}

uses
  {$REGION USES}
  System.SysUtils, VK.Bot, VK.Types, VK.Bot.Utils,
  HGM.IpInfo in '..\IPInfo_API\HGM.IpInfo.pas',
  HGM.IPPing in '..\Ping\HGM.IPPing.pas',
  OWM.API in '..\OWM_API\OWM.API.pas',
  OWM.Classes in '..\OWM_API\OWM.Classes.pas',
  Bot.IpInfo in 'Bot.IpInfo.pas',
  Bot.OWM in 'Bot.OWM.pas',
  Bot.Welcome in 'Bot.Welcome.pas',
  Bot.Ping in 'Bot.Ping.pas',
  Bot.GameShoot in 'Bot.GameShoot.pas',
  HGM.SQLang in '..\SQLite\HGM.SQLang.pas',
  HGM.SQLite in '..\SQLite\HGM.SQLite.pas',
  HGM.SQLite.Wrapper in '..\SQLite\HGM.SQLite.Wrapper.pas',
  Bot.DB in 'Bot.DB.pas',
  Bot.Voice in 'Bot.Voice.pas',
  SpeechLib_TLB in 'SpeechLib_TLB.pas',
  bass in '..\#Fork\Bass\delphi\bass.pas',
  bassenc in '..\#Fork\Bass\delphi\bassenc.pas',
  Bot.YBalaboba in 'Bot.YBalaboba.pas',
  Bot.RandomNoise in 'Bot.RandomNoise.pas';
  {$ENDREGION}

begin
  ReportMemoryLeaksOnShutdown := True;
  TDB.Init;
  TGeneralListener.Init;
  with TVkBotChat.GetInstance(192458090, {$INCLUDE BOT_TOKEN.key}) do
  try
    SkipOtherBotMessages := False;
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TGeneralListener.Welcome);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TGeneralListener.CountMessages);
    //AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TGeneralListener.Censor);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TGeneralListener.Sticker);
    //AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TGeneralListener.Mute);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TIpInfoListener.GetIpInfo);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TOWMListener.GetCurrentWeather);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TPingListener.Ping);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TPingListener.HostToIp);
    AddMessageListener([{                }TVkPeerType.Chat], TGameShootListener.Proc);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TVoiceListener.Proc);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TVoiceListener.Anekdot);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TBalabobaListener.SayForLast);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TBalabobaListener.Say);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TRandomNoiseListener.Proc);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TGeneralListener.SaveLastMessage);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TGeneralListener.Ended);

    if Init and Run then
      Console.Run(
        procedure(const Command: string; var Quit: Boolean)
        begin
          Quit := Command.Equals('exit');
        end);
  finally
    TDB.UnInit;
    Free;
  end;
end.

