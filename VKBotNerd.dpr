program VKBotNerd;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  VK.Bot,
  VK.Types,
  VK.Bot.Utils,
  HGM.IpInfo in '..\IPInfo_API\HGM.IpInfo.pas',
  HGM.IPPing in '..\Ping\HGM.IPPing.pas',
  OWM.API in '..\OWM_API\OWM.API.pas',
  OWM.Classes in '..\OWM_API\OWM.Classes.pas',
  Bot.IpInfo in 'Bot.IpInfo.pas',
  Bot.OWM in 'Bot.OWM.pas',
  Bot.Welcome in 'Bot.Welcome.pas',
  Bot.Ping in 'Bot.Ping.pas',
  Bot.GameShoot in 'Bot.GameShoot.pas';

begin
  with TVkBotChat.GetInstance(192458090, '892add820fa363f2db8e9d8fc80eaeb7880177233515368da7dd95f3092bc8596786e5d4eaee7b0f96ae2') do
  try
    AddMessageListener([TVkPeerType.Chat], TWelcomeListener.Welcome);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TIpInfoListener.GetIpInfo);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TOWMListener.GetCurrentWeather);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TPingListener.Ping);
    AddMessageListener([TVkPeerType.User, TVkPeerType.Chat], TPingListener.HostToIp);
    AddMessageListener([TVkPeerType.Chat], TGameShootListener.Proc);
    AddMessageListener([TVkPeerType.Chat], TWelcomeListener.Ended);

    if Init and Run then
      Console.Run(
        procedure(const Command: string; var Quit: Boolean)
        begin
          Quit := Command.Equals('exit');
        end);
  finally
    Free;
    Readln;
  end;
end.

