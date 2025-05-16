unit playerd;

interface

uses player, roomd, syscons, err;

type
    ContentsPtr = ^ContentsRec;

    PlayerDaemon = object
                         size : word;
                         head, current : ContentsPtr;

                         constructor init;

                         function  insert (obptr : PlayerPtr) : boolean;
                         procedure delete;
                         procedure retrieve (var obptr : PlayerPtr);
                         procedure update (obptr : PlayerPtr);
                         function  find_first : boolean;
                         function  find_next : Boolean;
                         function  empty : Boolean;

                         function  screen_logon (tx, ty, bx, by, bg : word; flip, flip_update : boolean) : boolean;
                         function  com_logon (port : byte) : boolean;

                         procedure shut_ob  (str : pchar);

                         destructor destruct;
                   end;

	PlayerDPtr = ^PlayerDaemon;

    Contentsrec = record
                        obj : PlayerPtr;
                        next : ContentsPtr;
                  end;

implementation

constructor PlayerDaemon.init;
begin
     current:= nil;
     head:= nil;
     size:= 0;
end;

function PlayerDaemon.insert (obptr : PlayerPtr) : boolean;
var  ptr : ContentsPtr;
begin
     insert:= false;
     if (maxavail < sizeof (ContentsRec)) then
     begin
          error ('playerd.insert: out of memory^',0);
          exit;
     end;
     getmem (ptr, sizeof (ContentsRec));
     ptr^.obj:= obptr;
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     insert:= true;
     sysmsg ('playerd: inserted playerobject^');
end;

procedure PlayerDaemon.delete;
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
     freemem (current^.obj, sizeof (PlayerObject));
     freemem (current, sizeof (ContentsRec));
     current:= head;
     dec (size);
     sysmsg ('playerd: deleted playerobject^');
end;

procedure PlayerDaemon.retrieve (var obptr : PlayerPtr);
begin
     obptr:= current^.obj;
end;

procedure PlayerDaemon.update (obptr : PlayerPtr);
begin
     current^.obj:= obptr;
end;

function PlayerDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function PlayerDaemon.find_next : Boolean;
begin
     if ((current^.next = nil) or (current = nil)) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function PlayerDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

destructor PlayerDaemon.destruct;
var TempObj : PlayerPtr;
begin
     find_first;
     while not empty do
     begin
          retrieve (TempObj);
          TempObj^.console.cwriteln ('Gamedriver shouts: shutting down immediately!');
          delete;
     end;
end;

function PlayerDaemon.screen_logon (tx, ty, bx, by, bg:word; flip, flip_update : boolean) : boolean;
var TempObj : PlayerPtr;
begin
    screen_logon:= false;
    if (maxavail < sizeof (PlayerObject)) then
    begin
         error ('playerd.screen_logon: out of memory^',0);
         exit;
    end;
    getmem (TempObj, sizeof (PlayerObject));
    TempObj^.init;
    TempObj^.console.init_on_screen (tx, ty, bx, by, bg, flip, flip_update, 'Logon');
    TempObj^.console.cwrite ('What is your name: ');
    insert (TempObj);
    screen_logon:= true;
    sysmsg ('playerd: attached playerobject to [scr]^');
end;

function PlayerDaemon.com_logon (port : byte) : boolean;
var TempObj : PlayerPtr;
begin
     com_logon:= false;
     if (maxavail < sizeof (PlayerObject)) then
     begin
          error ('playerd.com_logon: out of memory^',0);
          exit;
     end;
     getmem (TempObj, sizeof (PlayerObject));
     TempObj^.init;
     TempObj^.console.init_on_com (port);
     TempObj^.console.cwrite ('What is your name: ');
     insert (TempObj);
     com_logon:= true;
     sysmsg ('playerd: attached playerobject to [com]^');
end;

procedure PlayerDaemon.shut_ob (str : pchar);
var TempObj : PlayerPtr;
begin
    retrieve (TempObj);
    TempObj^.console.cwriteln (str);
    delete;
end;

end.
