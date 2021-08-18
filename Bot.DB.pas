unit Bot.DB;

interface

uses
  HGM.SQLite, HGM.SQLang;

type
  TDB = class(TSQLiteDatabase)
  private
    class function GetConfig(Field: string; PeerId, UserId: Integer; Key: string): TSQLiteTable; static; inline;
    class procedure SetConfig(Field: string; PeerId, UserId: Integer; Key: string; Value: Integer); overload; inline;
    class procedure SetConfig(Field: string; PeerId, UserId: Integer; Key: string; Value: string); overload; inline;
    class procedure SetConfig(Field: string; PeerId, UserId: Integer; Key: string; Value: Boolean); overload; inline;
    class procedure SetConfig(Field: string; PeerId, UserId: Integer; Key: string; Value: Double); overload; inline;
  public
    constructor Create; reintroduce;
    class procedure Init;
    class procedure UnInit;
    class function GetStrValue(PeerId, UserId: Integer; Key: string; Default: string): string;
    class function GetIntValue(PeerId, UserId: Integer; Key: string; Default: Integer): Integer;
    class function GetBoolValue(PeerId, UserId: Integer; Key: string; Default: Boolean): Boolean;
    class function GetFloatValue(PeerId, UserId: Integer; Key: string; Default: Double): Double;
    class procedure SetValue(PeerId, UserId: Integer; Key: string; Value: string); overload;
    class procedure SetValue(PeerId, UserId: Integer; Key: string; Value: integer); overload;
    class procedure IncValue(PeerId, UserId: Integer; Key: string; Value: Integer = 1); overload;
    class procedure SetValue(PeerId, UserId: Integer; Key: string; Value: Boolean); overload;
    class procedure SetValue(PeerId, UserId: Integer; Key: string; Value: Double); overload;
  end;

var
  DB: TDB = nil;

implementation

uses
  VK.Bot.Utils;

{ TDB }

constructor TDB.Create;
begin
  inherited Create('data.db');
  with SQL.CreateTable('peers_data') do
  try
    AddField('peer_id', ftInteger);
    AddField('user_id', ftInteger);
    AddField('key', ftString);
    AddField('intValue', ftInteger);
    AddField('strValue', ftString);
    AddField('boolValue', ftBoolean);
    AddField('floatValue', ftFloat);
    ExecSQL(GetSQL);
  finally
    EndCreate;
  end;
end;

class procedure TDB.SetConfig(Field: string; PeerId, UserId: Integer; Key: string; Value: Double);
begin
  if DB.GetTableValue('SELECT COUNT(*) FROM peers_data WHERE peer_id = ? AND user_id = ? AND key = ?', [PeerId, UserId, Key]) <= 0 then
    DB.ExecSQL('INSERT INTO peers_data (peer_id, user_id, key, ' + Field + ') VALUES (?, ?, ?, ?)', [PeerId, UserId, Key, Value])
  else
    DB.ExecSQL('UPDATE peers_data SET ' + Field + ' = ? WHERE peer_id = ? AND user_id = ? AND key = ?', [Value, PeerId, UserId, Key]);
end;

class procedure TDB.SetConfig(Field: string; PeerId, UserId: Integer; Key: string; Value: integer);
begin
  if DB.GetTableValue('SELECT COUNT(*) FROM peers_data WHERE peer_id = ? AND user_id = ? AND key = ?', [PeerId, UserId, Key]) <= 0 then
    DB.ExecSQL('INSERT INTO peers_data (peer_id, user_id, key, ' + Field + ') VALUES (?, ?, ?, ?)', [PeerId, UserId, Key, Value])
  else
    DB.ExecSQL('UPDATE peers_data SET ' + Field + ' = ? WHERE peer_id = ? AND user_id = ? AND key = ?', [Value, PeerId, UserId, Key]);
end;

class procedure TDB.SetConfig(Field: string; PeerId, UserId: Integer; Key: string; Value: Boolean);
begin
  if DB.GetTableValue('SELECT COUNT(*) FROM peers_data WHERE peer_id = ? AND user_id = ? AND key = ?', [PeerId, UserId, Key]) <= 0 then
    DB.ExecSQL('INSERT INTO peers_data (peer_id, user_id, key, ' + Field + ') VALUES (?, ?, ?, ?)', [PeerId, UserId, Key, Value])
  else
    DB.ExecSQL('UPDATE peers_data SET ' + Field + ' = ? WHERE peer_id = ? AND user_id = ? AND key = ?', [Value, PeerId, UserId, Key]);
end;

class procedure TDB.SetConfig(Field: string; PeerId, UserId: Integer; Key: string; Value: string);
begin
  if DB.GetTableValue('SELECT COUNT(*) FROM peers_data WHERE peer_id = ? AND user_id = ? AND key = ?', [PeerId, UserId, Key]) <= 0 then
    DB.ExecSQL('INSERT INTO peers_data (peer_id, user_id, key, ' + Field + ') VALUES (?, ?, ?, ?)', [PeerId, UserId, Key, Value])
  else
    DB.ExecSQL('UPDATE peers_data SET ' + Field + ' = ? WHERE peer_id = ? AND user_id = ? AND key = ?', [Value, PeerId, UserId, Key]);
end;

class function TDB.GetConfig(Field: string; PeerId, UserId: Integer; Key: string): TSQLiteTable;
begin
  with SQL.Select('peers_data', Field) do
  try
    WhereFieldEqual('peer_id', '?');
    WhereFieldEqual('user_id', '?');
    WhereFieldEqual('key', '?');
    Limit := 1;
    Result := DB.Query(GetSQL, [PeerId, UserId, Key]);
  finally
    EndCreate;
  end;
end;

class function TDB.GetFloatValue(PeerId, UserId: Integer; Key: string; Default: Double): Double;
var
  Table: TSQLiteTable;
begin
  Table := GetConfig('floatValue', PeerId, UserId, Key);
  try
    if not Table.EoF then
      Result := Table.FieldAsDouble(0)
    else
      Result := Default;
  finally
    Table.Free;
  end;
end;

class function TDB.GetBoolValue(PeerId, UserId: Integer; Key: string; Default: Boolean): Boolean;
var
  Table: TSQLiteTable;
begin
  Table := GetConfig('boolValue', PeerId, UserId, Key);
  try
    if not Table.EoF then
      Result := Table.FieldAsBoolean(0)
    else
      Result := Default;
  finally
    Table.Free;
  end;
end;

class function TDB.GetIntValue(PeerId, UserId: Integer; Key: string; Default: Integer): Integer;
var
  Table: TSQLiteTable;
begin
  Table := GetConfig('intValue', PeerId, UserId, Key);
  try
    if not Table.EoF then
      Result := Table.FieldAsInteger(0)
    else
      Result := Default;
  finally
    Table.Free;
  end;
end;

class function TDB.GetStrValue(PeerId, UserId: Integer; Key: string; Default: string): string;
var
  Table: TSQLiteTable;
begin
  Table := GetConfig('strValue', PeerId, UserId, Key);
  try
    if not Table.EoF then
      Result := Table.FieldAsString(0)
    else
      Result := Default;
  finally
    Table.Free;
  end;
end;

class procedure TDB.IncValue(PeerId, UserId: Integer; Key: string; Value: Integer);
begin
  if DB.GetTableValue('SELECT COUNT(*) FROM peers_data WHERE peer_id = ? AND user_id = ? AND key = ?', [PeerId, UserId, Key]) <= 0 then
    DB.ExecSQL('INSERT INTO peers_data (peer_id, user_id, key, intValue) VALUES (?, ?, ?, ?)', [PeerId, UserId, Key, Value])
  else
    DB.ExecSQL('UPDATE peers_data SET intValue = intValue + ? WHERE peer_id = ? AND user_id = ? AND key = ?', [Value, PeerId, UserId, Key]);
end;

class procedure TDB.Init;
begin
  Console.AddText('Database initializate...');
  if not Assigned(DB) then
    DB := TDB.Create;
  Console.AddLine('Ok', GREEN);
end;

class procedure TDB.SetValue(PeerId, UserId: Integer; Key: string; Value: Double);
begin
  SetConfig('floatValue', PeerId, UserId, Key, Value);
end;

class procedure TDB.SetValue(PeerId, UserId: Integer; Key: string; Value: Boolean);
begin
  SetConfig('boolValue', PeerId, UserId, Key, Value);
end;

class procedure TDB.SetValue(PeerId, UserId: Integer; Key: string; Value: integer);
begin
  SetConfig('intValue', PeerId, UserId, Key, Value);
end;

class procedure TDB.SetValue(PeerId, UserId: Integer; Key: string; Value: string);
begin
  SetConfig('strValue', PeerId, UserId, Key, Value);
end;

class procedure TDB.UnInit;
begin
  if Assigned(DB) then
    DB.Free;
end;

end.

