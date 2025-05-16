unit verbd;

interface

uses stringd, syscons, err;

type
    VerbPtr = ^VerbRec;

    VerbRec = record
                    verb : StringDPtr;
                    next : VerbPtr;
              end;

    VerbDaemon = object
                       head, current : VerbPtr;
                       size          : word;

                       constructor init;

                       function  create_verb (str : pchar) : boolean;
                       function  add_to_verb (str : pchar) : boolean;
                       procedure delete;

                       function find_first : boolean;
                       function find_next : boolean;
                       function empty : boolean;

                       destructor destruct;
                 end;

implementation

constructor VerbDaemon.init;
begin
     head:= nil;
     current:= nil;
end;

function VerbDaemon.create_verb (str : pchar) : boolean;
var ptr : VerbPtr;
begin
     create_verb:= false;
     if (maxavail < sizeof (VerbRec) + sizeof (StringDaemon)) then
     begin
          error ('verbd.create_verb: out of memory^',0);
          exit;
     end;
     getmem (ptr, sizeof (VerbRec));
     getmem (ptr^.verb, sizeof (StringDaemon));
     ptr^.verb^.init;
     if not (ptr^.verb^.make (str)) then exit;
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     create_verb:= true;
     sysmsg ('verbd: created verb ');
     sysmsg (str);
     sysmsg ('^');
end;

function VerbDaemon.add_to_verb (str : pchar) : boolean;
begin
     add_to_verb:= current^.verb^.add (str);
end;

procedure VerbDaemon.delete;
var  ptr : VerbPtr;
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
     current^.verb^.destruct;
     freemem (current^.verb, sizeof (StringDaemon));
     freemem (current, sizeof (VerbRec));
     current:= head;
     dec (size);
     sysmsg ('verbd: deleted verb^');
end;

function VerbDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function VerbDaemon.find_next : Boolean;
begin
     if (current^.next = nil) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function VerbDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

destructor VerbDaemon.destruct;
begin
     find_first;
     while not empty do delete;
end;

end.
