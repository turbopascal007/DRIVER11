unit itemd;

interface

uses item, syscons, err;

type
    ContentsPtr = ^ContentsRec;

    ItemDaemon = object
                         size : word;
                         head, current : ContentsPtr;

                         constructor init;

                         function  insert (obptr : ItemPtr) : boolean;
                         procedure delete (dest : boolean);
                         procedure retrieve (var obptr : ItemPtr);
                         procedure update (obptr : ItemPtr);
                         function  find_first : boolean;
                         function  find_next : Boolean;
                         function  empty : Boolean;

                         function  add (str : pchar) : boolean;

                         destructor destruct;
                   end;

    ItemDPtr = ^ItemDaemon;

    Contentsrec = record
                        obj : ItemPtr;
                        next : ContentsPtr;
                  end;

implementation

constructor ItemDaemon.init;
begin
     current:= nil;
     head:= nil;
     size:= 0;
end;

function ItemDaemon.insert (obptr : ItemPtr): boolean;
var  ptr : ContentsPtr;
begin
     insert:= false;
     if (maxavail < sizeof (ContentsRec)) then
     begin
          error ('itemd.insert: out of memory^',0);
          exit;
     end;
     getmem (ptr, sizeof (ContentsRec));
     ptr^.obj:= obptr;
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     insert:= true;
     sysmsg ('itemd: inserted itemobject^');
end;

procedure ItemDaemon.delete (dest : boolean);
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
     if dest then
     begin
          current^.obj^.destruct;
          freemem (current^.obj, sizeof (ItemObject));
     end;
     freemem (current, sizeof (ContentsRec));
     current:= head;
     dec (size);
     sysmsg ('itemd: deleted itemobject^');
end;

procedure ItemDaemon.retrieve (var obptr : ItemPtr);
begin
     obptr:= current^.obj;
end;

procedure ItemDaemon.update (obptr : ItemPtr);
begin
     current^.obj:= obptr;
end;

function ItemDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function ItemDaemon.find_next : Boolean;
begin
     if ((current^.next = nil) or (current = nil)) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function ItemDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

function ItemDaemon.add (str : pchar) : boolean;
var TempPtr : ^ItemObject;
begin
     add:= false;
     TempPtr := nil;
     if (maxavail < sizeof (ItemObject)) then
     begin
          error ('itemd.add: out of memory^',0);
          exit;
     end;
     getmem (TempPtr, sizeof (ItemObject));
     TempPtr^.init;
     if not (TempPtr^.set_strvar ('short', str)) then
     begin
          error ('itemd.add: out of memory^',0);
          exit;
     end;
     insert (TempPtr);
     add:= true;
     sysmsg ('itemd: attached short ');
     sysmsg (str);
     sysmsg (' to itemobject^');
end;

destructor ItemDaemon.destruct;
begin
     find_first;
     while not empty do delete (true);
end;

end.
