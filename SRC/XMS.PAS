unit xms;

interface

uses xmslib;

procedure xms_init;


implementation

var
  version,
  memory   : word;

procedure xms_init;
begin
  if (XMS_Setup) then
  begin
    version:= XMS_GetVersion (true);
    if (XMSResult = xmsrOk) then
    begin
      memory:= XMS_MemAvail;
      if (XMSResult = xmsrOk) then
        write ('+ ', memory, '000 bytes XMS[', hi (version), '.', lo (version), '] ');
    end;
  end;
end;

end.
