unit stringd;

interface

uses strings, err;

type
    StringPtr = ^StringRec;
    StringRec = record
                    line : pchar;
                    next : StringPtr;
              end;

    StringDaemon = object
                       head, current : StringPtr;
                       size : word;

                       constructor init;

                       function  make (str : pchar) : boolean;
                       function  add (str : pchar) :  boolean;
                       function retrieve_line : pchar;

                       function find_first : boolean;
                       function find_next : boolean;
                       function empty : boolean;

                       destructor destruct;
                  end;

    StringDPtr = ^StringDaemon;

implementation

constructor StringDaemon.init;
begin
     head:= nil;
     current:= nil;
     size:= 0;
end;

function StringDaemon.make (str : pchar) : boolean;
var ptr : StringPtr;
begin
     make:= false;
     if (maxavail < sizeof (StringRec) + StrLen (str) + 1) then
     begin
          error ('stringd.make: out of memory^',0);
          exit;
     end;

     getmem (ptr, sizeof (StringRec));
     getmem (ptr^.line, StrLen (str) + 1);

     StrMove (ptr^.line, str, StrLen (str) + 1);
     ptr^.next:= nil;
     head:= ptr;
     inc (size);
     make:= true;
end;

function StringDaemon.add (str : pchar) : boolean;
var ptr : StringPtr;
begin
     add:= false;
     current:= head;
     while not (current^.next = nil) do
           current:= current^.next;
     if (maxavail < sizeof (StringRec) + StrLen (str) + 1) then
     begin
          error ('stringd.make: out of memory^',0);
          exit;
     end;

     getmem (ptr, sizeof (StringRec));
     getmem (ptr^.line, StrLen (str) + 1);

     StrMove (ptr^.line, str, StrLen (str) + 1);
     ptr^.next:= nil;
     current^.next:= ptr;
     inc (size);
     add:= true;
end;


function StringDaemon.retrieve_line : pchar;
begin
     retrieve_line:= current^.line;
end;

function StringDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function StringDaemon.find_next : Boolean;
begin
     if ((current^.next = nil) or (current = nil)) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function StringDaemon.empty : Boolean;
begin
     empty:= (head = nil);
end;

destructor StringDaemon.destruct;
begin
     current:= head;
     while not (current = nil) do
     begin
          freemem (current^.line, StrLen (current^.line) + 1);
          head:= current^.next;
          freemem (current, sizeof (StringRec));
          current:= head;
     end;
end;

end.
