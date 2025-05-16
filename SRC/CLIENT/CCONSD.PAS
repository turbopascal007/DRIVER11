unit cconsd;

interface

uses cconsole;

type
    ContentsPtr = ^ContentsRec;
    ContentsRec = record
                    cons : ConsolePtr;
                    next : ContentsPtr;
                 end;

    ConsoleDaemon = object
                       head, current : ContentsPtr;
                       size : word;

                       constructor init;

                       procedure insert (obptr : ConsolePtr);
                       procedure delete;

                       procedure retrieve (var obptr : ConsolePtr);

                       procedure add (tx, ty, bx, by, bg : word; flip, update : boolean; name : pchar);

                       function find_first : boolean;
                       function find_next : boolean;
                       function empty : boolean;

                       destructor destruct;
                 end;

    ConsoleDPtr = ^ConsoleDaemon;

implementation

constructor ConsoleDaemon.init;
begin
     head:= nil;
     current:= nil;
end;

procedure ConsoleDaemon.insert (obptr : ConsolePtr);
var ptr : ContentsPtr;
begin
     getmem (ptr, sizeof (ContentsRec));
     ptr^.cons:= obptr;
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
end;

procedure ConsoleDaemon.delete;
var  ptr : ContentsPtr;
begin
     if (size < 1) then exit;
     if not (current = head) then
     begin
          ptr:= head;
          while not (ptr^.next = current) do
                ptr:= ptr^.next;
          ptr^.next:=current^.next;
     end
     else
         head:= head^.next;
     current^.cons^.destruct;
     freemem (current^.cons, sizeof (ConsoleObject));
     freemem (current, sizeof (ContentsRec));
     current:= head;
     dec (size);
end;

procedure ConsoleDaemon.retrieve (var obptr : ConsolePtr);
begin
     obptr:= current^.cons;
end;

procedure ConsoleDaemon.add (tx, ty, bx, by, bg : word; flip, update : boolean; name : pchar);
var TempObj : ConsolePtr;
begin
     getmem (TempObj, sizeof (ConsoleObject));
     TempObj^.init (tx, ty, bx, by, bg, flip, update, name);
     TempObj^.cwrite ('What is your name: ');
     insert (TempObj);
end;

function ConsoleDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function ConsoleDaemon.find_next : Boolean;
begin
     if (current^.next = nil) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function ConsoleDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

destructor ConsoleDaemon.destruct;
var TempObj : ConsolePtr;
begin
     find_first;
     while not empty do
     begin
          retrieve (TempObj);
          TempObj^.cwriteln ('Gamedriver shouts: shutting down immediately!');
          delete;
     end;
end;

end.

