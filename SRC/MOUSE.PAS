unit mouse;

interface

uses mouselib, crt, universe, player, switcher, parser, syscons, err;

procedure mouse_init;
procedure handle_mouse_events (u : UniversePtr);
procedure mouse_done;

implementation

var
   released : boolean;
 
procedure mouse_init;
begin
  showmousecursor;
  released:= true;
end;

procedure mouse_done;
begin
  hidemousecursor;
end;

function mousepress (var row, col : integer) : boolean;
begin
    if (getbutton (leftbutton) = buttondown) then
    begin
         row:= (getmousey div 8) + 1;
         col:= (getmousex div 8) + 1;
         mousepress:= true;
         released:= false;
    end
    else mousepress:= false;
end;

procedure handle_mouse_events (u : UniversePtr);
var row, col : integer;
    playptr  : PlayerPtr;
    found    : boolean;
    tx, ty,
    bx, by   : word;
begin
     if not (mouse_present) then exit;
     found:= false;
     if (not released) and (getbutton (leftbutton) = buttonup) then
        released:= true;
     if (released) and (mousepress (row, col)) then
     begin
          if (u^.pd^.find_first) then
          repeat
                u^.pd^.retrieve (playptr);
                if (((row = playptr^.console.topy - 1) or
                     (row = playptr^.console.boty + 1)) and
                    ((col >= playptr^.console.topx - 1) and
                     (col <= playptr^.console.botx + 1))) or
                   (((col = playptr^.console.topx - 1) or
                     (col = playptr^.console.botx + 1)) and
                    ((row >= playptr^.console.topy - 1) and
                     (row <= playptr^.console.boty + 1))) then
                begin
                     set_ob (u, playptr);
                     found:= true;
                     break;
                end;
          until not u^.pd^.find_next;
          if not found then
          begin
               get_syscons_coord (tx, ty, bx, by);
               if (((row = ty) or (row = by)) and
                   ((col >= tx) and (col <= bx))) or
                  (((col = tx) or (col = bx)) and
                   ((row >= ty) and (row <= by))) then
                  syscons_redraw;
          end;
     end;
end;     

end.     
