unit Bot.DB;

interface

uses
  HGM.SQLite, HGM.SQLang;

type
  TDB = class(TSQLiteDatabase)
  private
    class function GetConfig(const Field: string; const Section: Integer; const Key: string): TSQLiteTable; static;
    class procedure SetConfig(const Field: string; const Section: Integer; const Key: string; const Value: Integer); overload;
    class procedure SetConfig(const Field: string; const Section: Integer; const Key: string; const Value: string); overload;
    class procedure SetConfig(const Field: string; const Section: Integer; const Key: string; const Value: Boolean); overload;
  public
    constructor Create; reintroduce;
    class procedure Init;
    class procedure UnInit;
    class function GetStrValue(const Section: Integer; const Key, Default: string): string;
    class function GetIntValue(const Section: Integer; const Key: string; Default: Integer): Integer;
    class function GetBoolValue(const Section: Integer; const Key: string; Default: Boolean): Boolean;
    class procedure SetValue(const Section: Integer; Key, Value: string); overload;
    class procedure SetValue(const Section: Integer; Key: string; Value: integer); overload;
    class procedure SetValue(const Section: Integer; Key: string; Value: Boolean); overload;
  end;

var
  DB: TDB = nil;

implementation

{ TDB }

constructor TDB.Create;
begin
  inherited Create('data.db');
  with SQL.CreateTable('config') do
  try
    AddField('section', ftInteger);
    AddField('key', ftString);
    AddField('intValue', ftInteger);
    AddField('strValue', ftString);
    AddField('boolValue', ftBoolean);
    ExecSQL(GetSQL);
  finally
    EndCreate;
  end;
end;

class function TDB.GetConfig(const Field: string; const Section: Integer; const Key: string): TSQLiteTable;
begin
  with SQL.Select('config', Field) do
  try
    WhereFieldEqual('section', '?');
    WhereFieldEqual('key', '?');
    Limit := 1;
    Result := DB.Query(GetSQL, [Section, Key]);
  finally
    EndCreate;
  end;
end;

class procedure TDB.SetConfig(const Field: string; const Section: Integer; const Key: string; const Value: integer);
var
  Id: Integer;
begin
  Id := DB.GetTableValue('SELECT COUNT(*) FROM config WHERE section = ? AND key = ?', [Section, Key]);
  if Id <= 0 then
    DB.ExecSQL('INSERT INTO config (section, key, ' + Field + ') VALUES (?, ?, ?)', [Section, Key, Value])
  else
    DB.ExecSQL('UPDATE config SET ' + Field + ' = ? WHERE section = ? AND key = ?', [Value, Section, Key]);
end;

class procedure TDB.SetConfig(const Field: string; const Section: Integer; const Key: string; const Value: Boolean);
var
  Id: Integer;
begin
  Id := DB.GetTableValue('SELECT COUNT(*) FROM config WHERE section = ? AND key = ?', [Section, Key]);
  if Id <= 0 then
    DB.ExecSQL('INSERT INTO config (section, key, ' + Field + ') VALUES (?, ?, ?)', [Section, Key, Value])
  else
    DB.ExecSQL('UPDATE config SET ' + Field + ' = ? WHERE section = ? AND key = ?', [Value, Section, Key]);
end;

class procedure TDB.SetConfig(const Field: string; const Section: Integer; const Key, Value: string);
var
  Id: Integer;
begin
  Id := DB.GetTableValue('SELECT COUNT(*) FROM config WHERE section = ? AND key = ?', [Section, Key]);
  if Id <= 0 then
    DB.ExecSQL('INSERT INTO config (section, key, ' + Field + ') VALUES (?, ?, ?)', [Section, Key, Value])
  else
    DB.ExecSQL('UPDATE config SET ' + Field + ' = ? WHERE section = ? AND key = ?', [Value, Section, Key]);
end;

class function TDB.GetBoolValue(const Section: Integer; const Key: string; Default: Boolean): Boolean;
var
  Table: TSQLiteTable;
begin
  Table := GetConfig('boolValue', Section, Key);
  try
    if not Table.EoF then
      Result := Table.FieldAsBoolean(0)
    else
      Result := Default;
  finally
    Table.Free;
  end;
end;

class function TDB.GetIntValue(const Section: Integer; const Key: string; Default: Integer): Integer;
var
  Table: TSQLiteTable;
begin
  Table := GetConfig('intValue', Section, Key);
  try
    if not Table.EoF then
      Result := Table.FieldAsInteger(0)
    else
      Result := Default;
  finally
    Table.Free;
  end;
end;

class function TDB.GetStrValue(const Section: Integer; const Key, Default: string): string;
var
  Table: TSQLiteTable;
begin
  Table := GetConfig('strValue', Section, Key);
  try
    if not Table.EoF then
      Result := Table.FieldAsString(0)
    else
      Result := Default;
  finally
    Table.Free;
  end;
end;

class procedure TDB.Init;
begin
  if not Assigned(DB) then
    DB := TDB.Create;
end;

class procedure TDB.SetValue(const Section: Integer; Key: string; Value: Boolean);
begin
  SetConfig('boolValue', Section, Key, Value);
end;

class procedure TDB.SetValue(const Section: Integer; Key: string; Value: integer);
begin
  SetConfig('intValue', Section, Key, Value);
end;

class procedure TDB.SetValue(const Section: Integer; Key, Value: string);
begin
  SetConfig('strValue', Section, Key, Value);
end;

class procedure TDB.UnInit;
begin
  if Assigned(DB) then
    DB.Free;
end;

end.

