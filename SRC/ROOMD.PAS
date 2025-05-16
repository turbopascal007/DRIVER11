unit roomd;

interface

uses room, strings, syscons, err;

type

    ContentsPtr = ^ContentsRec;
    ContentsRec = record
                         obj  : RoomPtr;
                         next : ContentsPtr;
                  end;

    RoomDaemon = object
                         size : word;
                         head, current : ContentsPtr;

                         constructor init;

                         function  insert (obptr : RoomPtr) : boolean;
                         procedure delete;
                         procedure retrieve (var obptr : RoomPtr);
                         procedure update (obptr : RoomPtr);
                         function  find_first : boolean;
                         function  find_next : Boolean;
                         function  empty : Boolean;

                         function load (str : pchar) : boolean;

                         destructor destruct;
                   end;

	RoomDPtr = ^RoomDaemon;

implementation

constructor RoomDaemon.init;
begin
     current:= nil;
     head:= nil;
     size:= 0;
end;

function RoomDaemon.insert (obptr : RoomPtr) : boolean;
var  ptr : ContentsPtr;
begin
     insert:= false;
     if (maxavail < sizeof (ContentsRec)) then
     begin
         error ('roomd.insert: out of memory^',0);
         exit;
     end;
     getmem (ptr, sizeof (ContentsRec));
     ptr^.obj:= obptr;
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     insert:= true;
     sysmsg ('roomd: inserted roomobject^');
end;

procedure RoomDaemon.delete;
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
     current^.obj^.destruct;
     freemem (current^.obj, sizeof (RoomObject));
     freemem (current, sizeof (ContentsRec));
     current:= head;
     dec (size);
     sysmsg ('roomd: deleted roomobject^');
end;

procedure RoomDaemon.retrieve (var obptr : RoomPtr);
begin
     obptr:= current^.obj;
end;

procedure RoomDaemon.update (obptr : RoomPtr);
begin
     current^.obj:= obptr;
end;

function RoomDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function RoomDaemon.find_next : Boolean;
begin
     if ((current^.next = nil) or (current = nil)) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function RoomDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

destructor RoomDaemon.destruct;
begin
     find_first;
     while not empty do delete;
end;

function RoomDaemon.load (str : pchar) : boolean;
var TempObj : RoomPtr;
begin
     load:= false;
     if (maxavail < sizeof (RoomObject)) then
     begin
          error ('roomd.load: out of memory^',0);
          exit;
     end;
     getmem (TempObj, sizeof (RoomObject));
     TempObj^.init;
     if not (TempObj^.set_strvar ('short', str)) then
     begin
          error ('roomd.load: out of memory^',0);
          exit;
     end;
     insert (TempObj);
     load:= true;
     sysmsg ('roomd: attached short ');
     sysmsg (str);
     sysmsg (' to roomobject^');
end;

end.
