unit fund;

interface

uses err, syscons;

type
    proc = procedure;

    FunPtr = ^FunRec;

    FunRec = record
                   cmdname : pchar;
                   fun     : proc;
                   next    : FunPtr;
              end;

    FunDaemon = object
                       head, current : FunPtr;
                       size : word;

                       constructor init;

                       function  insert (str : pchar; ref : proc) : boolean;
                       procedure delete;

                       function retrieve_cmdname : pchar;
                       procedure retrieve_fun (fun : proc);
                       procedure exec_cmd;

                       function find_first : boolean;
                       function find_next : boolean;
                       function empty : boolean;

                       destructor destruct;
                 end;

implementation

constructor FunDaemon.init;
begin
     head:= nil;
     current:= nil;
end;

function FunDaemon.insert (str : pchar; ref : proc) : boolean;
var ptr : FunPtr;
begin
     insert:= false;
     if (maxavail < sizeof (FunRec)) then
     begin
          error ('fund.insert: out of memory^',0);
          exit;
     end;
     getmem (ptr, sizeof (FunRec));
     ptr^.cmdname:= str;
     ptr^.fun:= ref;
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     insert:= true;
     sysmsg ('fund: added function ');
     sysmsg (str);
     sysmsg ('^');
end;

procedure FunDaemon.delete;
var  ptr : FunPtr;
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
     freemem (current, sizeof (FunRec));
     current:= head;
     dec (size);
     sysmsg ('fund: deleted function^');
end;

function FunDaemon.retrieve_cmdname : pchar;
begin
     retrieve_cmdname:= current^.cmdname;
end;

procedure FunDaemon.retrieve_fun (fun : proc);
begin
     fun:= current^.fun;
end;

procedure FunDaemon.exec_cmd;
begin
     current^.fun;
end;

function FunDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function FunDaemon.find_next : Boolean;
begin
     if (current^.next = nil) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function FunDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

destructor FunDaemon.destruct;
begin
end;

end.
