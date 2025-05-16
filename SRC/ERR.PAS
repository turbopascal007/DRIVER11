unit err;

interface

uses dos;

procedure error_init (filename : string);
procedure error (str :  pchar; flag : word);


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

procedure error (str : pchar; flag : word);
var i : integer;
begin
     append (logfile);
     i:=0;
     while not (str[i] = #0) do
     begin
          if str[i] = '^' then
              writeln (logfile)
          else
              write (logfile, str[i]);
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
