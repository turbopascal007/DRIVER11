unit err2;

interface

uses player, dos;

procedure error_init (filename : string);
procedure error (str : pchar; flag: word; who : PlayerPtr);


implementation

var
   logfile : text;
   logfilename : string;

procedure error_init (filename : string);
begin
     {$I-}
     assign (logfile, filename);
     rewrite (logfile);
     if (IOResult > 0) then
     begin
          writeln ('I could not open file ', filename);
          halt (0);
     end;
     {$I+}
     logfilename:= filename;
end;

procedure error (str : pchar; flag : word; who : PlayerPtr);
var i : integer;
begin
     if not (who = nil) then who^.console.cwrite (str);
     append (logfile);
     i:=0;
     while not (str[i] = #0) do
     begin
          if str[i] = '^' then
          begin
               writeln (logfile);
               if (who = nil) then writeln;
          end
          else
          begin
               write (logfile, str[i]);
               if (who = nil) then write (str[i]);
          end;
          inc (i);
     end;
     flush (logfile);
     if (flag = 1) then
     begin
          writeln (logfile, ' (fatal)');
          close (logfile);
          writeln ('***FATAL ERROR: system halted  (cause dumped to ',logfilename,')');
          halt (1);
     end;
     close (logfile);
end;

end.
