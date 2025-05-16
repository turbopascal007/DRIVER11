unit console;

interface

uses crt, comm_tp4, strings, err;

const {$I defines.inc}

type
    devenumtype = (screen, disk, com, client);

    ConsoleObject = object
                          device                        : text;
                          devtype                       : devenumtype;
                          topx, topy, botx, boty, bgcol : word;
                          x, y, wx, wy, titx            : word;
                          port                          : byte;
                          lock_read                     : boolean;
                          flipwindow                    : boolean;
                          flip_update                   : boolean;
                          readstr                       : pchar;
                          readbuf                       : pchar;
                          id                            : pchar;
                          scrn                          : pchar;
                          owner                         : pchar;

                          constructor init_on_screen (tx, ty, bx, by, bg : word; flip, update : boolean; name : pchar);
                          constructor init_on_disk (filename : string);
                          constructor init_on_com (po : byte);
                          constructor init_on_client (name : pchar; po : byte);

                          procedure init2 (name : pchar);
                          procedure redraw_title;
                          procedure redraw_screen;

                          procedure cwrite (str : pchar);
                          procedure cwriteln (str : pchar);

                          function receive (ch : char;
                                            var cmd : pchar) : Boolean;

                          function query_devtype : string;

                          procedure set_owner (name : pchar);
                          procedure clear_buf;

                          destructor destruct;
                    end;

implementation

procedure ConsoleObject.init2 (name : pchar);
begin
     set_owner (name);
     if (devtype = screen) then redraw_title;
end;

procedure ConsoleObject.redraw_title;
var i : integer;
begin
     window (1, 1, 80, 25);
     textcolor (7);
     textbackground (bgcol);
     gotoxy (topx - 1, topy - 1);
     write (chr (218));
     for i:= topx to botx do write (chr (196));
     write (chr (191));
     if (botx - topx > StrLen (owner) + 2) then
     begin
          gotoxy (titx, topy - 1);
          write (' ',owner,' ');
     end;
end;

procedure ConsoleObject.redraw_screen;
var i, j, width : integer;
begin
     if not (devtype = screen) then exit;
     redraw_title;
     width:= botx - topx + 1;
     if not flipwindow then
         for i:= topy to boty do
         begin
              gotoxy (topx - 1, i);
              write (chr (179));
              for j:= topx to botx do write (chr (32));
              write (chr (179));
         end
     else
         for i:= topy to boty do
         begin
              gotoxy (topx - 1, i);
              write (chr (179));
              for j:= topx to botx do
                write (scrn[(i - topy) * width + (j - topx + 1)]);
              write (chr (179));
         end;
     gotoxy (topx - 1, boty + 1);
     write (chr (192));
     for i:= topx to botx do write (chr (196));
     write (chr (217));
     if flipwindow and (not flip_update) then
          for i:= (boty - topy) downto 0 do
              for j:= (botx - topx) + 1 downto 1 do
                  if not (scrn[i * width + j] = ' ') then
                  begin
                       case scrn[i * width + j] of
                       '>': begin
                                 wx:= j + 1;
                                 wy:= i + 1;
                            end;
                       ':': begin
                                 wx:= j + 2;
                                 wy:= i + 1;
                            end;
                       else
                           begin
                                wx:= 1;
                                wy:= i + 2;
                           end;
                       end;
                       exit;
                  end;
end;

constructor ConsoleObject.init_on_screen (tx, ty, bx, by, bg : word; flip, update : boolean; name : pchar);
begin
     if (tx < 1) or (tx > 80) or (bx < 1) or (bx > 80) or (bx <= tx + 3) or
        (ty < 1) or (ty > 24) or (by < 1) or (by > 24) or (by <= ty + 1) then
     begin
          error ('console.init_on_screen: window has invalid dimensions^', 0);
          exit;
     end;
     assign (device, '');
     rewrite (device);
     if not (maxavail > MAXLEN*2 + 5) then
     begin
          error ('console.init_on_screen: out of memory^', 0);
          close (device);
          exit;
     end;
     getmem (readstr, MAXLEN);
     getmem (readbuf, MAXLEN);
     getmem (id, 5);
     readstr[0]:= #0;
     readbuf[0]:= #0;
     lock_read:= true;
     flip_update:= update;
     devtype  := screen;
     owner := nil;
     StrPCopy (id, 'scrn');
     topx     := tx+1;
     topy     := ty+1;
     botx     := bx-1;
     boty     := by-1;
     bgcol    := bg;
     x        := topx;
     y        := topy;
     wx       := 1;
     wy       := 1;
     scrn     := nil;
     set_owner (name);
     if flip then
     begin
          if (maxavail < ((botx-topx+1)*(boty-topy+1) + 1)) then
          begin
               error ('console.init_on_screen: out of memory^', 0);
               close (device);
               exit;
          end;
          getmem (scrn, (botx-topx+1)*(boty-topy+1) + 1);
          clear_buf;
     end;
     flipwindow:= false;
     redraw_screen;
     flipwindow:= flip;
end;

constructor ConsoleObject.init_on_disk (filename : string);
begin
     devtype := disk;
     if not (maxavail > MAXLEN*2 + 5) then
     begin
          error ('console.init_on_disk: out of memory^', 0);
          exit;
     end;
     getmem (readstr, MAXLEN);
     getmem (readbuf, MAXLEN);
     getmem (id, 5);
     readstr[0]:= #0;
     readbuf[0]:= #0;
     lock_read:= true;
     owner:= nil;
     scrn:= nil;
     StrPCopy (id, 'disk');
     {$I-}
     assign (device, filename);
     rewrite (device);
     if IOResult > 0 then
     begin
          error ('console.init_on_disk: could not create file ', 0);
          StrPCopy (readbuf, filename);
          error (readbuf, 0);
          error ('^', 0);
          exit;
     end;
     {$I+}
end;

constructor ConsoleObject.init_on_com (po : byte);
begin
     devtype:= com;
     if (maxavail < MAXLEN*2 + 5) then
     begin
          error ('console.init_on_com: out of memory^', 0);
          exit;
     end;
     getmem (readstr, MAXLEN);
     getmem (readbuf, MAXLEN);
     getmem (id, 5);
     readstr[0]:= #0;
     readbuf[0]:= #0;
     lock_read:= false;
     owner:= nil;
     scrn:= nil;
     StrPCopy (id, 'com');
     id[3]:= chr (po + 48);
     id[4]:= #0;
     port:= po;

end;

constructor ConsoleObject.init_on_client (name : pchar; po : byte);
begin
     devtype:= client;
     if (maxavail < MAXLEN*2 + 5) then
     begin
          error ('console.init_on_client: out of memory^', 0);
          exit;
     end;
     getmem (readstr, MAXLEN);
     getmem (readbuf, MAXLEN);
     getmem (id, 5);
     readstr[0]:= #0;
     readbuf[0]:= #0;
     lock_read:= false;
     owner:= nil;
     scrn:= nil;
     StrPCopy (id, 'cln');
     id[3]:= chr (po + 48);
     id[4]:= #0;
     port:= po;

     set_owner (name);
end;

procedure ConsoleObject.cwrite (str : pchar);
var i, j : word;
    written : boolean;
begin
     case devtype of
     screen:
     begin
          if flipwindow then
          begin
               i:= 0;
               while (i < StrLen (str)) do
               begin
                    if (str[i] = '^') then
                    begin
                         inc (y);
                         x:= topx;
                         if (y > boty) then
                         begin
                              dec (y);
                              for j:= (botx-topx+2) to
                                      (boty-topy+1)*(botx-topx+1) do
                                  scrn[j - (botx-topx+1)]:= scrn[j];
                              for j:= (boty-topy)*(botx-topx+1)+1 to
                                      (boty-topy+1)*(botx-topx+1) do
                                  scrn[j]:= ' ';
                         end;
                    end
                    else
                    begin
                         if (str[i] = '~') then
                            scrn[(y-topy)*(botx-topx+1)+(x-topx+1)]:= ' '
                         else
                            scrn[(y-topy)*(botx-topx+1)+(x-topx+1)]:= str[i];
                         inc (x);
                         if (x > botx) then
                         begin
                              inc (y);
                              x:= topx;
                              if (y > boty) then
                              begin
                                   dec (y);
                                   for j:= (botx-topx+2) to
                                           (boty-topy+1)*(botx-topx+1) do
                                       scrn[j - (botx-topx+1)]:= scrn[j];
                                   for j:= (boty-topy)*(botx-topx+1)+1 to
                                           (boty-topy+1)*(botx-topx+1) do
                                       scrn[j]:= ' ';
                              end;
                         end;
                    end;
                    inc (i);
                end;
           end;
           if not flip_update then
           begin
                if flipwindow and lock_read then exit;
                window (topx, topy, botx, boty);
                textbackground (bgcol);
                gotoxy (wx, wy);

                i:= 0;
                while (i < StrLen (str)) do
                begin
                     if (str[i] = '^') then
                        writeln
                     else
                         if (str[i] = '~') then
                            write (' ')
                         else
                             write (str[i]);
                     inc (i);
                end;

                wx:= wherex;
                wy:= wherey;
           end
           else
           begin
                redraw_screen;
                gotoxy (x, y);
           end;
     end;
     disk:
     begin
          i:= 0;
          while (i < StrLen (str)) do
          begin
               if (str[i] = '^') then
                  writeln (device)
               else
                   if (str[i] = '~') then
                      write (device, ' ')
                   else
                       write (device, str[i]);
               flush (device);
               inc (i);
          end;
     end;
     com:
     begin
          gotoxy (wherex, wherey);
          write (chr (254));
          gotoxy (wherex - 1, wherey);
          i:= 0;
          while (i < StrLen (str)) do
          begin
               if (str[i] = '^') then
               begin
                  IWriteCOM (port, #13);
                  IWriteCOM (port, #10);
               end
               else
                   if (str[i] = '~') then
                      IWriteCOM (port, ' ')
                   else
                       IWriteCOM (port, str[i]);
               inc (i);
          end;
          write (' ');
          gotoxy (wherex - 1, wherey);
     end;
     client:
     begin
          gotoxy (wherex, wherey);
          write (chr (254));
          gotoxy (wherex - 1, wherey);
          i:= 0;
          IWriteCOM (port, #01);
          while (i < StrLen (owner)) do
          begin
               IWriteCOM (port, owner[i]);
               inc (i);
          end;
          IWriteCOM (port, #02);
          i:= 0;
          while (i < StrLen (str)) do
          begin
               IWriteCOM (port, str[i]);
               inc (i);
          end;
          IWriteCOM (port, #03);
          write (' ');
          gotoxy (wherex - 1, wherey);
     end;
     end;
end;

procedure ConsoleObject.cwriteln (str : pchar);
begin
     cwrite (str);
     cwrite ('^');
end;

function ConsoleObject.receive (ch : char ; var cmd : pchar) : Boolean;
var i : integer;
begin
     receive:= false;
     case ch of
          chr (13):
          begin
               StrMove (readstr, readbuf, StrLen (readbuf) + 1);
               cmd:= readstr;
               readbuf[0]:= #0;
               cwrite ('^');
               receive:= true;
          end;
          chr (8):
          begin
              i:= StrLen (readbuf);
              if (i > 0) then
              begin
                   readbuf[i - 1]:= #0;
                   if not (devtype = screen) then cwrite (chr (8)) else
                   begin
                        dec (wx);
                        dec (x);
                        if (flip_update and (x < topx)) or
                           ((not flip_update) and (wx < 1)) then
                        begin
                             if (wy > 1) then dec (wy);
                             if (y > 1) then dec (y);
                             wx:= botx - topx + 1;
                             x:= botx;
                        end;
                        cwrite (' ');
                        dec (wx);
                        dec (x);
                        if (flip_update and (x < topx)) or
                           ((not flip_update) and (wx < 1)) then
                        begin
                             if (wy > 1) then dec (wy);
                             if (y > 1) then dec (y);
                             wx:= botx - topx + 1;
                             x:= botx;
                        end;
                        cwrite ('');
                   end;
              end;
          end;
          else
          begin
               i:= StrLen (readbuf);
               if (i < MAXLEN - 1) then
               begin
                    readbuf[i]:= ch;
                    readbuf[i+1]:= #0;
                    cwrite (@readbuf[i]);
               end;
          end;
     end;
end;

function ConsoleObject.query_devtype : string;
begin
     case devtype of
     screen: query_devtype:= 'scr';
     disk  : query_devtype:= 'dsk';
     com   : query_devtype:= 'com';
     client: query_devtype:= 'cli';
     end;
end;

procedure ConsoleObject.set_owner (name : pchar);
begin
     if not (owner = nil) then freemem (owner, StrLen (owner) + 1);
     if (maxavail < StrLen (name) + 1) then
     begin
          error ('console.set_owner: out of memory^',0);
          exit;
     end;
     getmem (owner, StrLen (name) + 1);
     StrMove (owner, name, StrLen (name) + 1);
     titx:= topx + ((botx - topx) div 2) - (StrLen (owner) div 2) - 1;
end;

procedure ConsoleObject.clear_buf;
var i : word;
begin
     if not (scrn = nil) then
        for i:= 1 to (botx-topx+1)*(boty-topy+1) do scrn[i]:= ' ';
     x:= topx;
     y:= topy;
     wx:= 1;
     wy:= 1;
end;

destructor ConsoleObject.destruct;
begin
     if (devtype = screen) and flipwindow then freemem (scrn, (botx-topx+1)*(boty-topy+1) + 1);
     if not (owner = nil) then freemem (owner, StrLen (owner) + 1);
     freemem (readstr, MAXLEN);
     freemem (readbuf, MAXLEN);
     freemem (id, 5);
     if devtype = disk then close (device);
end;

end.
