unit switcher;

interface

uses universe, player;

procedure get_ob (var ob : PlayerPtr);
procedure set_ob (u : UniversePtr; ob : PlayerPtr);
procedure switch_ob (u : UniversePtr);

implementation

var 
   ActiveObj : PlayerPtr;

procedure get_ob (var ob : PlayerPtr);
begin
     ob:= ActiveObj;
end;
   
procedure set_ob (u : UniversePtr; ob : PlayerPtr);
var TempObj : PlayerPtr;
    found   : boolean;
begin
     found:= false;
     if (ob = nil) then
     begin
          ActiveObj:= nil;
          exit;
     end;
     if (u^.pd^.find_first) then
     repeat                       (* deactivate the current active object *)
           u^.pd^.retrieve (TempObj);
           if (TempObj^.console.query_devtype = 'scr') and
              (TempObj^.console.lock_read = false) then
           begin
                found:= true;
                TempObj^.console.lock_read:= true;
                break;
           end;
     until not u^.pd^.find_next;
     ActiveObj:= ob;
     ActiveObj^.console.lock_read:= false;
     ActiveObj^.console.cwrite ('');
     if ActiveObj^.console.flipwindow then
        ActiveObj^.console.redraw_screen;
     ActiveObj^.console.cwrite ('');
end;

procedure switch_ob (u : UniversePtr);
var TempObj : PlayerPtr;
    found   : boolean;
begin
     found:= false;
     if (u^.pd^.size = 0) then
     begin
          ActiveObj:= nil;
          exit;
     end;
     if (u^.pd^.find_first) then
     repeat                       (* deactivate the current active object *)
           u^.pd^.retrieve (TempObj);
           if (TempObj^.console.query_devtype = 'scr') and
              (TempObj^.console.lock_read = false) then
           begin
                found:= true;
                TempObj^.console.lock_read:= true;
                break;
           end;
     until not u^.pd^.find_next;
     if not u^.pd^.find_next then u^.pd^.find_first;
     repeat                       (* now search the next object *)
           u^.pd^.retrieve (TempObj);
           if (TempObj^.console.query_devtype = 'scr') and
              (TempObj^.console.lock_read = true) then
           begin
                TempObj^.console.lock_read:= false;
                TempObj^.console.cwrite ('');
                ActiveObj:= TempObj;
                if ActiveObj^.console.flipwindow then
                   ActiveObj^.console.redraw_screen;
                ActiveObj^.console.cwrite ('');
                exit;
           end;
     until not u^.pd^.find_next;
     ActiveObj:= nil;
end;

end.
