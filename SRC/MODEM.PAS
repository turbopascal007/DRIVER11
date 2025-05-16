unit modem;

interface

uses comm_tp4, err;

procedure register_modem (port : byte);
function via_modem (port : byte) : boolean;


implementation

var
   i : byte;
   modemline : array [1..MaxPorts] of boolean;

procedure register_modem (port : byte);
begin
     if (port > 0) and (port <= MaxPorts) then
        modemline[port]:= true
     else
         error ('modem.register_modem: invalid portnumber^',0);
end;

function via_modem (port : byte) : boolean;
begin
     via_modem:= modemline[port];
end;

begin
     for i:= 1 to MaxPorts do modemline[i]:= false;
end.
