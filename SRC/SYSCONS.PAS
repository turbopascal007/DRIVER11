unit syscons;

interface

uses console, err, strings;

procedure syscons_init (tx, ty, bx, by, bg : word; flip, update : boolean);
procedure sysmsg (msg : pchar);
procedure sys_status (count : word);
procedure get_syscons_coord (var tx, ty, bx, by : word);
procedure syscons_redraw;
procedure syscons_done;

implementation

var
   sconsole : ConsoleObject;
   init : boolean;
   tempptr,
   tempptr2 : pchar;

procedure syscons_init (tx, ty, bx, by, bg : word; flip, update: boolean);
begin
     if not init then
        sconsole.init_on_screen (tx, ty, bx, by, bg, flip, update, 'system');
     init:= true;
end;

procedure sysmsg (msg : pchar);
begin
     if init then sconsole.cwrite (msg);
end;

procedure sys_status (count : word);
var tempstr : string;
begin
     if not init then exit;

     StrPCopy (tempptr2, 'cpu: ');
     str (count, tempstr);
     StrPCopy (tempptr, tempstr);
     StrCat (tempptr2, tempptr);
     StrCat (tempptr2, '  mem: ');
     str (maxavail, tempstr);
     StrPCopy (tempptr, tempstr);
     StrCat (tempptr2, tempptr);

     sconsole.init2 (tempptr2);
end;

procedure get_syscons_coord (var tx, ty, bx, by : word);
begin
     tx:= sconsole.topx - 1;
     ty:= sconsole.topy - 1;
     bx:= sconsole.botx + 1;
     by:= sconsole.boty + 1;
end;

procedure syscons_redraw;
begin
     sconsole.redraw_screen;
end;

procedure syscons_done;
begin
     init:= false;
end;

begin
     init:= false;
     if (maxavail < 150) then error ('syscons: out of memory', 1);
     getmem (tempptr, 50);
     getmem (tempptr2, 100);
end.
