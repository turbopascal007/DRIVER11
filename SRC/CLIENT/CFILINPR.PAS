unit cfilinpr;

interface

uses cfund, comm_tp4, cconsd, strings, crt;

function c_interpret (filename : string; d : ConsoleDPtr) : byte;


implementation

var
   consd: ConsoleDPtr;
   port : byte;
   funtab : FunDaemon;
   argstr : pchar;
   buf    : pchar;

function c_interpret (filename : string; d : ConsoleDPtr) : byte;
var
   device : text;
   i, complen : word;
   found : boolean;
   stri : string;
begin
     consd:= d;
     {$I-}
     assign (device, filename);
     reset (device);
     if (IOResult > 0) then
     begin
          writeln ('Could not open client.ini!');
          halt (0);
     end;
     {$I+}
     while not eof (device) do
     begin
          i:= 0;
          found:= false;
          readln (device, stri);
          if (stri[0] > chr (254)) then
          begin
               writeln ('Invalid data in client.ini!');
               halt (0);
          end;
          StrPCopy (buf, stri);

          if (buf[0] = #35) or (buf[0] = #0) then continue;

          while not ((buf[i] = #0) or (buf[i] = #32)) do inc (i);
          if not (buf[i] = #0) then argstr:= @buf[i+1] else argstr:= @buf[StrLen (buf) + 1];

          if (funtab.find_first) then
          repeat
                if (StrLen (funtab.retrieve_cmdname) > i) then
                    complen:= StrLen (funtab.retrieve_cmdname)
                else
                    complen:= i - 1;

                if (StrLIComp (buf, funtab.retrieve_cmdname, complen) = 0) then
                begin
                     found:= true;
                     funtab.exec_cmd;
                end;
          until (not funtab.find_next) or found;

          if not found then
          begin
               writeln ('Syntax error in client.ini!');
               halt (0);
          end;
     end;

     c_interpret:= port;
     if (port = 0) then
     begin
          writeln ('COM port not set up!');
          halt (0);
     end;
     writeln ('Client 1.0  (c) 1994  Prinssoft Corp.  All rights reserved.');
     writeln;
end;

procedure do_com; far;
var i, j,
    p, baud, data, parity, stop : byte;
    code : integer;
    baudrate : word;
    portstr, baudstr, datastr, paritystr, stopstr : string;
begin
     i:= 0;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          portstr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     portstr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          writeln ('com: too few arguments');
          halt (0);
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          baudstr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     baudstr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          writeln ('com: too few arguments');
          halt (0);
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          paritystr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     paritystr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          writeln ('com: too few arguments');
          halt (0);
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          datastr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     datastr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          writeln ('com: too few arguments');
          halt (0);
     end;
      j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          stopstr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     stopstr[0]:= chr (j - 1);

     val (portstr, p, code);
     if (code <> 0) then
     begin
          writeln ('com: argument 1 (port) is not a numeric value');
          halt (0);
     end;
     val (baudstr, baudrate, code);
     if (code <> 0) then
     begin
          writeln ('com: argument 2 (baudrate) is not a numeric value');
          halt (0);
     end;
     baud:= 10;
     if (baudrate = 110) then baud:= 0;
     if (baudrate = 150) then baud:= 1;
     if (baudrate = 300) then baud:= 2;
     if (baudrate = 600) then baud:= 3;
     if (baudrate = 1200) then baud:= 4;
     if (baudrate = 2400) then baud:= 5;
     if (baudrate = 4800) then baud:= 6;
     if (baudrate = 9600) then baud:= 7;
     if (baudrate = 19200) then baud:= 8;
     if (baudrate = 38400) then baud:= 9;
     if (baud = 10) then
     begin
          writeln ('com: invalid baudrate');
          halt (0);
     end;
     case paritystr[1] of
     'n','N': parity:= 0;
     'e','E': parity:= 3;
     'o','O': parity:= 1;
     else
         begin
              writeln ('com: invalid parity');
              halt (0);
         end;
     end;
     val (datastr, data, code);
     if (code <> 0) then
     begin
          writeln ('com: argument 4 (databits) is not a numeric value');
          halt (0);
     end;
     if (data < 5) or (data > 8) then
     begin
          writeln ('com: invalid number of databits');
          halt (0);
     end;
    val (stopstr, stop, code);
     if (code <> 0) then
     begin
          writeln ('com: argument 5 (stopbits) is not a numeric value');
          halt (0);
     end;
     if (stop < 1) or (stop > 2) then
     begin
          writeln ('com: invalid number of stopbits');
          halt (0);
     end;
     port:= p;
     SetupCOMPort (port, baud, data, parity, stop);
     InstallInt (port);
end;

procedure do_window; far;
var i, j,
    tx, ty, bx, by, bg, code : word;
    txstr, tystr, bxstr, bystr, bgstr, flipstr : string;
    flip, update : boolean;
begin
     flip:= false;
     update:= false;
     i:= 0;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          txstr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     txstr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          writeln ('window: too few arguments');
          halt (0);
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          tystr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     tystr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          writeln ('window: too few arguments');
          halt (0);
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          bxstr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     bxstr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          writeln ('window: too few arguments');
          halt (0);
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          bystr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     bystr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          writeln ('window: too few arguments');
          halt (0);
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          bgstr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     bgstr[0]:= chr (j - 1);
     val (txstr, tx, code);
     if (code <> 0) then
     begin
          writeln ('window: argument 1 (top-x) is not a numeric value');
          halt (0);
     end;
     val (tystr, ty, code);
     if (code <> 0) then
     begin
          writeln ('window: argument 2 (top-y) is not a numeric value');
          halt (0);
     end;
     val (bxstr, bx, code);
     if (code <> 0) then
     begin
          writeln ('window: argument 3 (bot-x) is not a numeric value');
          halt (0);
     end;
     val (bystr, by, code);
     if (code <> 0) then
     begin
          writeln ('window: argument 4 (bot-y) is not a numeric value');
          halt (0);
     end;
     val (bgstr, bg, code);
     if (code <> 0) then
     begin
          writeln ('window: argument 5 (backgr-col) is not a numeric value');
          halt (0);
     end;
     consd^.add (tx, ty, bx, by, bg, true, false, 'Logon');
end;

begin
     port:= 0;
     getmem (argstr, 255);
     getmem (buf, 255);
     funtab.init;
     funtab.insert ('com',do_com);
     funtab.insert ('window',do_window);
end.
