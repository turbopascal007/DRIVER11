program load;

uses universe, fileinpr, dos;

var
    u       : UniverseObject;
    logfile : text;
    str     : string;

begin
     writeln ('World File Loader 1.0  (c) 1993 Prinssoft Corp.  All rights reserved.');
     writeln ;

     u.init;
     if (ParamCount = 0) then begin writeln ('Pardon me, load what file?'); halt(0); end;
     if (ParamCount > 1) then interpret_init (ParamStr (2), false)
                         else interpret_init ('loadexe.err', false);

     interpret (ParamStr (1), @u, nil);

     writeln ('-- allocated objects:');
     if (ParamCount > 2) then assign (logfile, ParamStr (3))
                         else assign (logfile, 'loadexe.log');
     reset (logfile);
     if eof (logfile) then writeln ('none') else
     repeat
          readln (logfile, str);
          writeln (str);
     until eof (logfile);
end.

