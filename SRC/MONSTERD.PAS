unit monsterd;

interface

uses monster, syscons, roomd, err;

type
    ContentsPtr = ^ContentsRec;

    MonsterDaemon = object
                         size : word;
                         head, current : ContentsPtr;
                         activeobj : MonsterPtr;

                         constructor init;

                         function insert (obptr : MonsterPtr) : boolean;
                         procedure delete;
                         procedure retrieve (var obptr : MonsterPtr);
                         procedure update (obptr : MonsterPtr);
                         function  find_first : boolean;
                         function  find_next : Boolean;
                         function  empty : Boolean;

                         function  clone (str : pchar) : boolean;

                         destructor destruct;
                   end;

	MonsterDPtr = ^MonsterDaemon;

    Contentsrec = record
                        obj : MonsterPtr;
                        next : ContentsPtr;
                  end;

implementation

constructor MonsterDaemon.init;
begin
     current:= nil;
     head:= nil;
     size:= 0;
     activeobj:= nil;
end;

function MonsterDaemon.insert (obptr : MonsterPtr) : boolean;
var  ptr : ContentsPtr;
begin
     insert:= false;
     if (maxavail < sizeof (ContentsRec)) then
     begin
          error ('monsterd.insert: out of memory^',0);
          exit;
     end;
     getmem (ptr, sizeof (ContentsRec));
     ptr^.obj:= obptr;
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     insert:= true;
     sysmsg ('monsterd: inserted monsterobject^');
end;

procedure MonsterDaemon.delete;
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
     freemem (current^.obj, sizeof (MonsterObject));
     freemem (current, sizeof (ContentsRec));
     current:= head;
     dec (size);
     sysmsg ('monsterd: deleted monsterobject^');
end;

procedure MonsterDaemon.retrieve (var obptr : MonsterPtr);
begin
     obptr:= current^.obj;
end;

procedure MonsterDaemon.update (obptr : MonsterPtr);
begin
     current^.obj:= obptr;
end;

function MonsterDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function MonsterDaemon.find_next : Boolean;
begin
     if ((current^.next = nil) or (current = nil)) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function MonsterDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

destructor MonsterDaemon.destruct;
begin
     find_first;
     while not empty do delete;
end;

function MonsterDaemon.clone (str : pchar) : boolean;
var TempObj : MonsterPtr;
begin
     clone:= false;
     if (maxavail < sizeof (MonsterObject)) then
     begin
          error ('monsterd.clone: out of memory^',0);
          exit;
     end;
     getmem (TempObj, sizeof (MonsterObject));
     TempObj^.init;
     if not (TempObj^.set_strvar ('short', str)) then
     begin
          error ('monsterd.clone: out of memory^', 0);
          exit;
     end;
     insert (TempObj);
     clone:= true;
     sysmsg ('monsterd: attached short ');
     sysmsg (str);
     sysmsg (' to monsterobject^');
end;

end.
