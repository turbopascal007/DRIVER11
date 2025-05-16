unit cswitch;

interface

uses cconsd, cconsole;

procedure get_cons (var obptr : ConsolePtr);
procedure switch_cons (d : ConsoleDPtr);

implementation

var
   ActiveObj : ConsolePtr;

procedure get_cons (var obptr : ConsolePtr);
begin
     obptr:= ActiveObj;
end;

procedure switch_cons (d : ConsoleDPtr);
var TempObj : ConsolePtr;
    found   : boolean;
begin
     found:= false;
     if (d^.size = 0) then
     begin
          ActiveObj:= nil;
          exit;
     end;
     if (d^.find_first) then
     repeat                       (* deactivate the current active object *)
           d^.retrieve (TempObj);
           if (TempObj^.lock_read = false) then
           begin
                found:= true;
                TempObj^.lock_read:= true;
                break;
           end;
     until not d^.find_next;
     if not d^.find_next then d^.find_first;
     repeat                       (* now search the next object *)
           d^.retrieve (TempObj);
           if (TempObj^.lock_read = true) then
           begin
                TempObj^.lock_read:= false;
                TempObj^.cwrite ('');
                ActiveObj:= TempObj;
                if ActiveObj^.flipwindow then
                   ActiveObj^.redraw_screen;
                ActiveObj^.cwrite ('');
                exit;
           end;
     until not d^.find_next;
     ActiveObj:= nil;
end;

end.
