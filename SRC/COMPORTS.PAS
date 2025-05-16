unit comports;

interface

uses comm_tp4, modem, universe, player, console, parser, clientio, logon, err;

procedure handle_com_events (u : UniversePtr);


implementation

var
   i : byte;


procedure handle_com_events (u : UniversePtr);
var playptr : PlayerPtr;
    found   : boolean;
    ch      : char;
    cmd     : pchar;
begin
     found:= false;
     for i:= 1 to MaxPorts do
     begin
          if IntInstalled [i] then
          begin
               u^.pd^.find_first;
               repeat
                     u^.pd^.retrieve (playptr);
                     if (playptr^.console.devtype = com) and
                        (playptr^.console.port = i) then
                     begin
                          DisableInts;
                          if (InTail [i] <> InHead [i]) then
                          begin
                               ch := chr (InBuffer [i, InHead [i]]);
                               InHead [i]:= (InHead [i] + 1) MOD (MaxInSize + 1);
                               if (playptr^.console.receive (ch, cmd)) then
                               begin
                                    case (playptr^.status) of
                                    0..1: log_on (playptr, cmd, u);
                                    2: parse_command (playptr, cmd, u);
                                    3: client_command (playptr, cmd, u);
                                    end;
                               end;
                          end;
                          EnableInts;
                          found:= true;
                     end;
               until (not u^.pd^.find_next) or found;

               if ((via_modem (i)) and (cd [i])) or (not found) then
                    if not (u^.pd^.com_logon (i)) then
                       error ('comports: out of memory registering player^', 0);
          end;
     end;
end;

end.
