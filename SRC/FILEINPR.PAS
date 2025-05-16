unit fileinpr;

interface

uses mystrings, strings, universe, modem, comm_tp4, syscons,
     player, monster, item, room, fund, ifun, screen, crt, err2;

const {$I defines.inc}

procedure interpret_init (filename : string; integflag : boolean);
function interpret (namestr : string; universe : UniversePtr; towho : PlayerPtr) : boolean;

function get_libdir : pchar; (* a hack to provide the library dir to players *)


implementation

type
    unittype = (aroom, amonster, aplayer, aitem, void);
    itemenvrec = record
                        case typ : unittype of
                        aroom : (renv : RoomPtr);
                        amonster : (menv : MonsterPtr);
                        aplayer : (penv : PlayerPtr);
                  end;

var
   buf,
   argbuf,
   filename,
   argstr,
   lineerr,
   linestr,
   libdir,
   current_name : pchar;
   funtab       : FunDaemon;
   u            : UniversePtr;
   unitt,
   last_unitt   : unittype;
   long_made,
   made,
   verb_set,
   setup,
   integrated,
   internal     : boolean;
   who          : PlayerPtr;
   logfile      : text;
   globrmptr    : RoomPtr;
   globmnptr    : MonsterPtr;
   globitmptr   : ItemPtr;
   itmenvrec    : ItemEnvRec;


procedure init;
begin
     unitt:= void;
     last_unitt:= void;
     long_made:= false;
     made:= false;
     internal:= false;
     verb_set:= false;
     globrmptr:= nil;
     globmnptr:= nil;
     globitmptr:= nil;
     long_made:= false;
end;

procedure interpret_init (filename : string; integflag : boolean);
begin
     error_init (filename);
     who:= nil;
     setup:= false;
     StrPCopy (lineerr, 'main: ');
     StrPCopy (libdir, '.');
     integrated:= integflag;
end;

function get_libdir : pchar;
begin
     get_libdir:= libdir;
end;

procedure memerr;
begin
     error (lineerr, 0, who);
     error ('out of memory^', 0, who);
end;

function interpret (namestr : string; universe : UniversePtr; towho : PlayerPtr) : boolean;
var device : text;
    stri,
    tstri  : string;
    i,
    complen,
    line   : word;
    found  : boolean;
begin
     u:= universe;
     who:= towho;
     line:= 0;
     interpret:= false;
     if not ((namestr[2] = ':') or (namestr[1] = '\')) then
        namestr:= concat (StrPas (libdir), '\', namestr);
     {$I-}
     assign (device, namestr);
     reset (device);
     StrPCopy (filename, namestr);
     if not internal then
          if (who = nil) then
                StrPCopy (lineerr, 'I') else StrMove (lineerr, who^.retrieve_strvar ('short'), 9);
     if IOResult > 0 then
     begin
          error (lineerr, 0, who);
          error (' could not open file ', 0, who);
          error (filename, 0, who);
          if internal then error (' (skipping)^', 0, who) else error (' (read aborted)^', 0, who);
          exit;
     end;
     {$I+}
     while not eof (device) do
     begin
          i:= 0;
          found:= false;
          inc (line);

          StrPCopy (lineerr, '');
          StrCat (lineerr, filename);
          StrCat (lineerr, '(');
          str (line, tstri);
          StrPCopy (linestr, tstri);
          StrCat (lineerr, linestr);
          StrCat (lineerr, '): ');

          readln (device, stri);
          if (MAXLEN <= 255) and (stri[0] > chr (MAXLEN - 1)) then
          begin
               error (lineerr,0, who);
               error ('line too long (skipping)^',0, who);
               continue;
          end;

          StrPCopy (buf, stri);
          if (buf[0] = #35) or (buf[0] = #0) then continue;
          skip_spaces (buf);

          if verb_set and (StrLIComp (buf, 'endverb', 7) <> 0) then
          begin
               case unitt of
               aroom: if not (globrmptr^.verbtab.add_to_verb (buf)) then
                      begin
                           memerr;
                           exit;
                      end;
               amonster: if not (globmnptr^.verbtab.add_to_verb (buf)) then
                         begin
                              memerr;
                              exit;
                         end;
               aitem: if not (globitmptr^.verbtab.add_to_verb (buf)) then
                      begin
                           memerr;
                           exit;
                      end;
               aplayer: if not (who = nil) then
                           if not (who^.verbtab.add_to_verb (buf)) then
                           begin
                                memerr;
                                exit;
                           end;
               end;
               continue;
          end;

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
               error (lineerr, 0, who);
               error ('syntax error (read aborted)^',0, who);
               close (device);
               if not internal then init;
               exit;
          end;
     end;

     if made then
     case unitt of
     aroom: begin
                 if not ((globrmptr^.set_strvar ('filename', filename)) and
                         (u^.rd^.insert (@globrmptr^))) then
                 begin
                      memerr;
                      if not internal then init;
                      exit;
                 end;
                 globrmptr:= nil;
            end;
     amonster: begin
                    if not ((globmnptr^.set_strvar ('filename', filename)) and
                            (u^.md^.insert (@globmnptr^))) then
                    begin
                         memerr;
                         if not internal then init;
                         exit;
                    end;
                    globmnptr:= nil;
               end;
     aitem: begin
                  if not (globitmptr^.set_strvar ('filename', filename)) then
                  begin
                       memerr;
                       if not internal then init;
                       exit;
                  end;
                  case itmenvrec.typ of
                  aroom: if not (itmenvrec.renv^.inv.insert (@globitmptr^)) then
                         begin
                              memerr;
                              if not internal then init;
                              exit;
                         end;
                  amonster: if not (itmenvrec.menv^.inv.insert (@globitmptr^)) then
                            begin
                                 memerr;
                                 if not internal then init;
                                 exit;
                            end;
                  aplayer: if not (itmenvrec.penv^.inv.insert (@globitmptr^)) then
                           begin
                                memerr;
                                if not internal then init;
                                exit;
                           end;
                  void: ;
                  else begin
                            error (lineerr, 0, who);
                            error ('lost environment (unit not added)',0, who);
                            if not internal then init;
                            exit;
                       end;
                  end;
                  globitmptr:= nil;
             end;
     end;
     if not internal then init;
     internal:= false;
     close (device);
     interpret:= true;
end;

function void_unit : boolean;
begin
     if (unitt = void) then
     begin
          error (lineerr, 0, who);
          error ('unit unknown (skipping)^',0, who);
          void_unit:= true;
          exit;
     end;
     void_unit:= false;
end;

function not_made : boolean;
begin
     if not made then
     begin
          error (lineerr, 0, who);
          error ('unit not initialized with name (skipping)^',0, who);
          not_made:= true;
     end;
     not_made:= false;
end;

procedure do_clear; far;
var i, j, bg, fg, code : integer;
    fgstr, bgstr : string;
begin
     i:= 0;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          fgstr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     fgstr[0]:= chr (j - 1);
     if (argstr[i] = #0) then
     begin
          error (lineerr, 0, who);
          error ('too few arguments to cls (skipping)^', 0, who);
          exit;
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
     val (fgstr, fg, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('foreground argument is not a valid number (skipping)^', 0, who);
          exit;
     end;
     val (bgstr, bg, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('background argument is not a valid number (skipping)^',0, who);
          exit;
     end;
     textcolor (fg);
     textbackground (bg);
     for i:= 1 to 80 do
        for j:= 1 to 25 do
        begin
             gotoxy (i, j);
             write (#176);
        end;
end;

procedure do_cursor; far;
var i, j: word;
    fstr: string;
begin
  i:= 0;
  j:= 1;
  while (argstr[i] = #32) do inc(i);
  if (argstr[i] = #0) then
  begin
    error (lineerr, 0, who);
    error ('missing argument to cursor (skipping)^', 0, who);
    exit;
  end;
  while not ((argstr[i] = #32) or (argstr[i] = #0)) do
  begin
    fstr[j]:= argstr[i];
    inc (j);
    inc (i);
  end;
  fstr[0]:= chr (j - 1);
  case fstr[2] of
  'n': cursor_on;
  'f': cursor_off;
  end;
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
          error (lineerr, 0, who);
          error ('too few arguments (window aborted)^',0, who);
          exit;
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
          error (lineerr, 0, who);
          error ('too few arguments (window aborted)^',0, who);
          exit;
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
          error (lineerr, 0, who);
          error ('too few arguments (window aborted)^',0, who);
          exit;
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
          error (lineerr, 0, who);
          error ('too few arguments (window aborted)^',0, who);
          exit;
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
     if (argstr[i] = #0) then
     begin
          error (lineerr, 0, who);
          error ('too few arguments (window aborted)^',0, who);
          exit;
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          flipstr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     flipstr[0]:= chr (j - 1);
     val (txstr, tx, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 1 (top-x) is not a numeric value (window aborted)^',0, who);
          exit;
     end;
     val (tystr, ty, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 2 (top-y) is not a numeric value (window aborted)^',0, who);
          exit;
     end;
     val (bxstr, bx, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 3 (bot-x) is not a numeric value (window aborted)^',0, who);
          exit;
     end;
     val (bystr, by, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 4 (bot-y) is not a numeric value (window aborted)^',0, who);
          exit;
     end;
     val (bgstr, bg, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 5 (backgr-col) is not a numeric value (window aborted)^',0, who);
          exit;
     end;
     if ((flipstr[1] = 'f') or (flipstr[1] = 'F')) then
     begin
          flip:= true;
          if ((flipstr[2] = 'u') or (flipstr[2] = 'U')) then
          begin
               update:= true;
               if ((flipstr[3] = 's') or (flipstr[3] = 'S')) then
               begin
                    syscons_init (tx, ty, bx, by, bg, true, true);
                    exit;
               end;
          end
          else
              if ((flipstr[2] = 's') or (flipstr[2] = 'S')) then
              begin
                   syscons_init (tx, ty, bx, by, bg, true, false);
                   exit;
              end;
     end
     else
          if ((flipstr[1] = 's') or (flipstr[1] = 'S')) then
          begin
               syscons_init (tx, ty, bx, by, bg, false, false);
               exit;
          end;
     if not (u^.pd^.screen_logon (tx, ty, bx, by, bg, flip, update)) then
     begin
          error (lineerr, 0, who);
          error ('out of memory^', 0, who);
     end
end;

procedure do_com; far;
var i, j,
    port, baud, data, parity, stop : byte;
    code : integer;
    baudrate : word;
    portstr, baudstr, datastr, paritystr, stopstr, viastr : string;
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
          error (lineerr, 0, who);
          error ('too few arguments (com aborted)^',0, who);
          exit;
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
          error (lineerr, 0, who);
          error ('too few arguments (com aborted)^',0, who);
          exit;
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
          error (lineerr, 0, who);
          error ('too few arguments (com aborted)^', 0, who);
          exit;
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
          error (lineerr, 0, who);
          error ('too few arguments (com aborted)^',0, who);
          exit;
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
     if (argstr[i] = #0) then
     begin
          error (lineerr, 0, who);
          error ('too few arguments (com aborted)^',0, who);
          exit;
     end;
     j:= 1;
     while (argstr[i] = #32) do inc(i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          viastr[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     viastr[0]:= chr (j - 1);

     val (portstr, port, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 1 (port) is not a numeric value (com aborted)^',0, who);
          exit;
     end;
     val (baudstr, baudrate, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 2 (baudrate) is not a numeric value (com aborted)^',0, who);
          exit;
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
          error (lineerr, 0, who);
          error ('invalid baudrate (com aborted)^',0, who);
          exit;
     end;
     case paritystr[1] of
     'n','N': parity:= 0;
     'e','E': parity:= 3;
     'o','O': parity:= 1;
     else
         begin
              error (lineerr, 0, who);
              error ('invalid parity (com aborted)^',0, who);
              exit;
         end;
     end;
     val (datastr, data, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 4 (databits) is not a numeric value (com aborted)^',0, who);
          exit;
     end;
     if (data < 5) or (data > 8) then
     begin
          error (lineerr, 0, who);
          error ('invalid number of databits (com aborted)^',0, who);
          exit;
     end;
    val (stopstr, stop, code);
     if (code <> 0) then
     begin
          error (lineerr, 0, who);
          error ('argument 5 (stopbits) is not a numeric value (com aborted)^',0, who);
          exit;
     end;
     if (stop < 1) or (stop > 2) then
     begin
          error (lineerr, 0, who);
          error ('invalid number of stopbits (com aborted)^',0, who);
          exit;
     end;
     if ((viastr[1] = 'm') or (viastr[1] = 'M')) then register_modem (port);
     SetupCOMPort (port, baud, data, parity, stop);
     InstallInt (port);
end;

procedure set_dir; far;
var savedir, newlibdir : string;
begin
     getdir (0, savedir);
     {$I-}
     chdir (StrPas (libdir));
     chdir (StrPas (argstr));
     if (IOResult <> 0) then
     begin
          error (lineerr, 0, who);
          error ('invalid directory change ',0, who);
          error (argstr, 0, who);
          error ('^',0, who);
     end
     else
     begin
          getdir (0, newlibdir);
          if not (libdir = nil) then freemem (libdir, StrLen (libdir) + 1);
          if (maxavail < ord (newlibdir[0]) + 1) then
          begin
               error (lineerr, 0, who);
               error (': out of memory^', 0, who);
               exit;
          end;
          getmem (libdir, ord (newlibdir[0]) + 1);
          StrPCopy (libdir, newlibdir);
     end;
     {$I+}
     chdir (savedir);
end;

procedure do_load; far;
var save_filename,
    save_current_name : string [255];
    save_unitt        : unittype;
    save_long_made,
    save_made,
    save_internal,
    save_verbset      : boolean;
begin
     if not (unitt = aitem) then
     begin
          save_filename:= StrPas (filename);
          save_unitt:= unitt;
          save_made:= made;
          save_long_made:= long_made;
          save_current_name:= StrPas (current_name);
          save_internal:= internal;
          save_verbset:= verb_set;
          if not ((unitt = void) or made) then
          begin
               error (lineerr, 0, who);
               error ('cannot read without having named this environment (skipping)^',0, who);
               exit;
          end;

          last_unitt:= unitt;
          unitt:= void;
          made:= false;
          long_made:= false;
          internal:= true;
          verb_set:= false;

          interpret (StrPas (argstr), u, who);

          verb_set:= save_verbset;
          internal:= save_internal;
          StrPCopy (current_name, save_current_name);
          last_unitt:= save_unitt;
          long_made:= save_long_made;
          made:= save_made;
          unitt:= save_unitt;
          StrPCopy (filename, save_filename);
     end
     else
     begin
          error (lineerr, 0, who);
          error ('cannot read, item does not have an inventory (skipping)^',0, who);
     end;
end;

procedure set_unit; far;
begin
     if not (unitt = void) then
     begin
          error (lineerr, 0, who);
          error ('unit already set (skipping)^',0, who);
          exit;
     end;
     if (StrLIComp (argstr, 'r', 1) = 0) then
     begin
          if (last_unitt = void) or (not integrated) then
             unitt:= aroom
          else
          begin
               error (lineerr, 0, who);
               error ('cannot define a room within another unit (unit not set)^',0, who);
          end;
          exit;
     end;
     if (StrLIComp (argstr, 'm', 1) = 0) then
     begin
          if (last_unitt = aroom) or (not integrated) then
             unitt:= amonster
          else
          begin
               if not ((who = nil) or (who^.env = nil)) then
               begin
                    globrmptr:= who^.env;
                    unitt:= amonster;
               end
               else
               begin
                    error (lineerr, 0, who);
                    error ('monster can only be defined within a room (unit not set)^',0, who);
               end;
          end;
          exit;
     end;
     if (StrLIComp (argstr, 'i', 1) = 0) then
     begin
          if (last_unitt = aroom) or (last_unitt = amonster) or
             (last_unitt = aplayer) or (not (who = nil)) or (not integrated) then
             unitt:= aitem
          else
          begin
               error (lineerr, 0, who);
               error ('item can only be defined within a room, monster or player (unit not set)^',0, who);
          end;
          exit;
     end;
     if (StrLIComp (argstr, 'p', 1) = 0) then
     begin
          unitt:= aplayer;
          made:= true;
          exit;
     end;
     error (lineerr, 0, who);
     error ('invalid unit (skipping)^',0, who);
end;

procedure set_name; far;
var mnptr  : MonsterPtr;
    rmptr  : RoomPtr;
    itmptr : ItemPtr;
begin
     if void_unit then exit;
     if made then
     begin
          error (lineerr, 0, who);
          error ('name already set (skipping)^',0, who);
          exit;
     end;
     if (unitt = aroom) then
     begin
          if (maxavail < sizeof (RoomObject)) then
          begin
               memerr;
               exit;
          end;
          getmem (rmptr, sizeof (RoomObject));
          rmptr^.init;
          if not (rmptr^.set_strvar ('short', argstr)) then
          begin
               memerr;
               exit;
          end;
          globrmptr:= rmptr;
     end;
     if (unitt = amonster) then
     begin
          if (globrmptr = nil) and integrated then
          begin
               error (lineerr, 0, who);
               error ('could not locate the environment (name not set)^',0, who);
               exit;
          end;
          if (maxavail < sizeof (MonsterObject)) then
          begin
               memerr;
               exit;
          end;
          getmem (mnptr, sizeof (MonsterObject));
          mnptr^.init;
          if not (mnptr^.set_strvar ('short', argstr)) then
          begin
               memerr;
               exit;
          end;
          if integrated then
             mnptr^.env:= globrmptr
          else
              mnptr^.env:= nil;
          globmnptr:= mnptr;
     end;
     if (unitt = aitem) then
     begin
          if (not integrated) then
             itmenvrec.typ:= void
          else
              if ((globrmptr = nil) and (globmnptr = nil) and (who = nil)) then
              begin
                   error (lineerr, 0, who);
                   error ('could not locate the environment (name not set)^',0, who);
                   exit;
              end;
          if not (who = nil) then
          begin
               itmenvrec.typ:= aplayer;
               itmenvrec.penv:= who
          end;
          if not (globrmptr = nil) then
          begin
               itmenvrec.typ:= aroom;
               itmenvrec.renv:= globrmptr
          end;
          if not (globmnptr = nil) then
          begin
               itmenvrec.typ:= amonster;
               itmenvrec.menv:= globmnptr;
          end;
          if (maxavail < sizeof (ItemObject)) then
          begin
               memerr;
               exit;
          end;
          getmem (itmptr, sizeof (ItemObject));
          itmptr^.init;
          if not (itmptr^.set_strvar ('short', argstr)) then
          begin
               memerr;
               exit;
          end;
          globitmptr:= itmptr;
     end;
     StrMove (current_name, argstr, StrLen (argstr) + 1);
     made:= true;
end;

procedure set_long; far;
var rmptr : RoomPtr;
    mnptr : MonsterPtr;
begin
     if void_unit then exit;
     if not_made then exit;
     if (unitt = aroom) then
     begin
          if (not long_made) then
          begin
               if not (globrmptr^.long.make (argstr)) then
               begin
                    memerr;
                    exit;
               end;
               long_made:= true;
          end
          else
              if not (globrmptr^.long.add (argstr)) then
              begin
                   memerr;
                   exit;
              end;
          exit;
     end;
     if (unitt = amonster) then
     begin
          if (not long_made) then
          begin
               if not (globmnptr^.long.make (argstr)) then
               begin
                    memerr;
                    exit;
               end;
               long_made:= true;
          end
          else
              if not (globmnptr^.long.add (argstr)) then
              begin
                   memerr;
                   exit;
              end;
          exit;
      end;
      if (unitt = aitem) then
      begin
            if (not long_made) then
            begin
                 if not (globitmptr^.long.make (argstr)) then
                 begin
                      memerr;
                      exit;
                 end;
                 long_made:= true;
            end
            else
                if not (globitmptr^.long.add (argstr)) then
                begin
                     memerr;
                     exit;
                end;
            exit;
      end;
      if (unitt = aplayer) then
      begin
           if (who = nil) then exit;
           if (not long_made) then
           begin
                if not (who^.long.make (argstr)) then
                begin
                     memerr;
                     exit;
                end;
                long_made:= true;
           end
           else
               if not (who^.long.add (argstr)) then
               begin
                    memerr;
                    exit;
               end;
      end;
end;

procedure set_str; far;
var i, j : word;
begin
     if void_unit then exit;
     if not_made then exit;
     i:= 0;
     j:= 0;
     while (argstr[i] = #32) do inc (i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          argbuf[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     argbuf[j]:= #0;
     argstr:= shift_str (argstr);
     case unitt of
     aroom: if not (globrmptr^.set_strvar (argbuf, argstr)) then memerr;
     amonster: if not (globmnptr^.set_strvar (argbuf, argstr)) then memerr;
     aitem: if not (globitmptr^.set_strvar (argbuf, argstr)) then memerr;
     aplayer: if not (who = nil) then
                  if not (who^.set_strvar (argbuf, argstr)) then memerr;
     end;
end;

procedure set_int; far;
var i, j : integer;
begin
     if void_unit then exit;
     if not_made then exit;
     i:= 0;
     j:= 0;
     while (argstr[i] = #32) do inc (i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          argbuf[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     argbuf[j]:= #0;
     argstr:= shift_str (argstr);
     val (StrPas (argstr), i, j);
     if (j <> 0) then
     begin
          error (lineerr, 0, who);
          error ('integer value expected^',0, who);
          exit;
     end;
     case unitt of
     aroom: if not (globrmptr^.set_intvar (argbuf, i)) then memerr;
     amonster: if not (globmnptr^.set_intvar (argbuf, i)) then memerr;
     aitem: if not (globitmptr^.set_intvar (argbuf, i)) then memerr;
     aplayer: if not (who = nil) then
                 if not (who^.set_intvar (argbuf, i)) then memerr;
     end;
end;

procedure set_exit; far;
var i : word;
    argbuf2 : pchar;
begin
     if void_unit then exit;
     if not_made then exit;
     if not (unitt = aroom) then
     begin
          error (lineerr, 0, who);
          error ('this unit can not have exits (skipping)^',0, who);
          exit;
     end;
     skip_spaces (argstr);

     StrCopy (argbuf, argstr);
     i:= 0;
     while (argbuf[i] <> #0) and (argbuf[i] <> #32) do inc(i);
     argbuf[i]:= #0;

     argstr:= shift_str (argstr);

     if not (globrmptr^.verbtab.create_verb (argbuf)) then begin memerr; exit; end;

     if (globrmptr^.retrieve_strvar ('exits') = nil) then
     begin
          if not (globrmptr^.set_strvar ('exits', argbuf)) then
             begin memerr; exit; end;
     end
     else
     begin
          i:= StrLen (globrmptr^.retrieve_strvar ('exits')) + StrLen (argbuf) + 5;
          if (maxavail < i) then
             begin memerr; exit; end;
          getmem (argbuf2, i);
          StrCopy (argbuf2, globrmptr^.retrieve_strvar ('exits'));
          StrCat (argbuf2, ', ');
          StrCat (argbuf2, argbuf);

          if not (globrmptr^.set_strvar ('exits', argbuf2)) then
             begin memerr; exit; end;

          freemem (argbuf2, i);

     end;

     StrPCopy (argbuf, 'internal goto ');
     if ((argstr[1] = ':') or (argstr[0] = '\')) then
          StrCat (argbuf, argstr)
     else
     begin
          StrCat (argbuf, libdir);
          StrCat (argbuf, '\');
          StrCat (argbuf, argstr);
     end;

     if not (globrmptr^.verbtab.add_to_verb (argbuf)) then begin memerr; exit; end;

end;

procedure create_verb; far;
begin
     if void_unit then exit;
     if not_made then exit;
     if verb_set then
     begin
          error (lineerr, 0, who);
          error ('endverb expected before creating new one (skipping)^', 0, who);
          exit;
     end;
     case unitt of
     aroom: if not (globrmptr^.verbtab.create_verb (argstr)) then
            begin
                 memerr;
                 exit;
            end;
     amonster: if not (globmnptr^.verbtab.create_verb (argstr)) then
               begin
                    memerr;
                    exit;
               end;
     aitem: if not (globitmptr^.verbtab.create_verb (argstr)) then
            begin
                 memerr;
                 exit;
            end;
     aplayer: if not (who = nil) then
                  if not (who^.verbtab.create_verb (argstr)) then
                  begin
                       memerr;
                       exit;
                  end;
     end;
     verb_set:= true;
end;

procedure end_verb; far;
begin
     if not verb_set then
     begin
          error (lineerr, 0, who);
          error ('verb not created (skipping)^', 0, who);
          exit;
     end;
     verb_set:= false;
end;

procedure do_write; far;
begin
     if not (who = nil) then who^.console.cwrite (argstr);
end;

procedure do_pause; far;
var i, j, code : integer;
begin
     val (argstr, i, code);
     if (code <> 0) then
     begin
          repeat until keypressed;
          readkey;
     end
     else
          for code:= 1 to i do for j:= 1 to 10000 do;
end;

begin
     who:= nil;
     setup:= false;
     filename:= nil;
     libdir:= nil;
     if (maxavail < (MAXLEN * 5) + 12) then error ('file_interpreter: out of memory', 1, nil);
     getmem (buf, MAXLEN);
     getmem (current_name, MAXLEN);
     getmem (argbuf, MAXLEN);
     getmem (lineerr, MAXLEN);
     getmem (filename, MAXLEN);
     getmem (linestr, 10);
     getmem (libdir, 2);
     StrPCopy (lineerr, 'main: ');
     StrPCopy (libdir, '.');
     init;
     funtab.init;
     funtab.insert ('cls',do_clear);
     funtab.insert ('cursor', do_cursor);
     funtab.insert ('window',do_window);
     funtab.insert ('com',do_com);
     funtab.insert ('dir',set_dir);
     funtab.insert ('load',do_load);
     funtab.insert ('unit',set_unit);
     funtab.insert ('name',set_name);
     funtab.insert ('long',set_long);
     funtab.insert ('str',set_str);
     funtab.insert ('int',set_int);
     funtab.insert ('exit',set_exit);
     funtab.insert ('verb',create_verb);
     funtab.insert ('endverb',end_verb);
     funtab.insert ('write',do_write);
     funtab.insert ('pause',do_pause);
end.
