unit taskd;

interface

uses task, err, syscons, stringd, player, room, item, monster, universe;

type
    TaskInfoPtr = ^TaskInfoRec;
    TaskInfoRec = record
                        obj : TaskPtr;
                        next : TaskInfoPtr;
                  end;

    TaskDaemon = object
                       size : word;
                       head, current : TaskInfoPtr;

                       constructor init;

                       function insert (verbs : StringDPtr; who : PlayerPtr;
                                        stri : pchar; fore : boolean;
                                        rmptr : RoomPtr; itmptr : ItemPtr;
                                        mnptr : MonsterPtr; u : UniversePtr) : boolean;
                       procedure delete;
                       procedure retrieve (var tptr : TaskPtr);
                       procedure update (tptr : TaskPtr);
                       function  find_first : boolean;
                       function  find_next : Boolean;
                       function  empty : Boolean;

                       destructor destruct;
                   end;

    TaskDPtr = ^TaskDaemon;


implementation

constructor TaskDaemon.init;
begin
     current:= nil;
     head:= nil;
     size:= 0;
end;

function TaskDaemon.insert (verbs : StringDPtr; who : PlayerPtr;
                            stri : pchar; fore : boolean;
                            rmptr : RoomPtr; itmptr : ItemPtr;
                            mnptr : MonsterPtr; u : UniversePtr) : boolean;
var  ptr : TaskInfoPtr;
     if_depth, while_depth: word;
begin
     insert:= false;
     if (maxavail < sizeof (TaskInfoRec)) then
     begin
         error ('taskd.insert: out of memory^',0);
         exit;
     end;
     getmem (ptr, sizeof (TaskInfoRec));
     getmem (ptr^.obj, sizeof (TaskObject));
     ptr^.obj^.init (verbs^.retrieve_line);
     ptr^.obj^.playptr:= who;
     ptr^.obj^.current:= verbs;
     ptr^.obj^.argstr:= stri;
     ptr^.obj^.run:= true;
     ptr^.obj^.foreground:= fore;
     ptr^.obj^.rmptr:= nil;
     ptr^.obj^.mnptr:= nil;
     ptr^.obj^.itmptr:= nil;
     if not (rmptr = nil) then u^.rd^.retrieve (ptr^.obj^.rmptr);
     if not (mnptr = nil) then u^.md^.retrieve (ptr^.obj^.mnptr);
     if not (itmptr = nil) then
        if (u = nil) then
           who^.inv.retrieve (ptr^.obj^.itmptr)
        else
           who^.env^.inv.retrieve (ptr^.obj^.itmptr);
     ptr^.obj^.if_depth:= 0;
     ptr^.obj^.while_depth:= 0;
     for if_depth:= 1 to MAXDEPTH do ptr^.obj^.if_set[if_depth]:= false;
     for while_depth:= 1 to MAXDEPTH do ptr^.obj^.start_while[while_depth]:= nil;

     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     insert:= true;
end;

procedure TaskDaemon.delete;
var  ptr : TaskInfoPtr;
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
     freemem (current^.obj, sizeof (TaskObject));
     freemem (current, sizeof (TaskInfoRec));
     current:= head;
     dec (size);
end;

procedure TaskDaemon.retrieve (var tptr : TaskPtr);
begin
     tptr:= current^.obj;
end;

procedure TaskDaemon.update (tptr : TaskPtr);
begin
     current^.obj:= tptr;
end;

function TaskDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function TaskDaemon.find_next : Boolean;
begin
     if ((current^.next = nil) or (current = nil)) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function TaskDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

destructor TaskDaemon.destruct;
begin
     find_first;
     while not empty do delete;
end;

end.
