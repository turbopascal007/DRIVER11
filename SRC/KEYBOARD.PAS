unit keyboard;

interface

uses switcher, parser, clientio, universe, player, logon, screen, crt;

procedure keyboard_init (u : UniversePtr);
procedure handle_key_events (u : UniversePtr);


implementation

procedure keyboard_init (u : UniversePtr);
begin
     switch_ob (u);
end;

procedure handle_key_events (u : UniversePtr);
var ch : char;
    cmd : pchar;
    ActiveObj : PlayerPtr;
begin
     if (keypressed) then
     begin
          ch:= readkey;
          if (ch = chr (0)) then
          begin
               ch:= readkey;
               case ord (ch) of
               94 : begin
                      u^.run:= false;
                    end;           (* ctrl-f1  program abort *)
               59 : switch_ob (u); (* f1      switch *)
               end;
          end
          else
          begin
               get_ob (ActiveObj);
               if (not (ActiveObj = nil)) and
                  (ActiveObj^.console.receive (ch, cmd)) then
               begin
                    case (ActiveObj^.status) of
                    0..1: log_on (ActiveObj, cmd, u);
                    2: parse_command (ActiveObj, cmd, u);
                    3: client_command (ActiveObj, cmd, u);
                    end;
               end;
          end;
     end;
end;

end.
