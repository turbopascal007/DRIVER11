program client;

uses comm_tp4, crt, cfilinpr, cconsd, cdriver;

var
   ch : char;
   port : byte;
   consd : ConsoleDPtr;

begin
     getmem (consd, sizeof (ConsoleDaemon));
     consd^.init;
     port:= c_interpret ('client.ini', consd);
     if (port = 0) then
     begin
          writeln ('COM port not set up..');
          exit;
     end;
     repeat
           DisAbleInts;
           if (InTail [port] <> InHead [port]) then
           begin
                ch:= chr (InBuffer [port, Inhead [port]]);
                Inhead [port]:= (Inhead [port] + 1) MOD (MaxInSize + 1);
                write (ch);
           end;
           EnAbleInts;
           if (keypressed) then
           begin
                ch:= readkey;
                if (ch = #27) then
                    enter_client_mode (port, consd)
                else
                    IWriteCOM (port, ch);
           end;
     until false;
end.
