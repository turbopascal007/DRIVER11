unit ccomport;

interface

uses comm_tp4, crt;

procedure send_str (port : byte; str : pchar);
function get_next_ch (port : byte; var ch : char): boolean;
function wait_for (port : byte; str : string; ticks : word) : boolean;
procedure hand_shake (port : byte);


implementation

procedure send_str (port : byte; str : pchar);
var i : word;
begin
     i:= 0;
     while not (str[i] = #0) do
     begin
          if (str[i] = '^') then
          begin
             IWriteCOM (port, #13);
          end
          else
              if (str[i] = '~') then
                 IWriteCOM (port, ' ')
              else
                  IWriteCOM (port, str[i]);
          inc (i);
     end;
end;

function get_next_ch (port : byte; var ch : char): boolean;
begin
     get_next_ch:= false;
     DisAbleInts;
     if (InTail [port] <> InHead [port]) then
     begin
          ch:= chr (InBuffer [port, Inhead [port]]);
          get_next_ch:= true;
          Inhead [port]:= (Inhead [port] + 1) MOD (MaxInSize + 1);
     end;
     EnAbleInts;
end;

function wait_for (port : byte; str : string; ticks : word) : boolean;
var i, ok, count : word;
    ch : char;
    bufstr : string;
begin
     ok:= 0;
     count:= 0;
     wait_for:= false;
     repeat
           if (get_next_ch (port, ch)) then
           begin
                ok:= 0;
                for i:= 2 to ord (str[0]) do bufstr[i-1]:= bufstr[i];
                bufstr[ ord (str[0]) ]:= ch;
                for i:= 1 to ord (str[0]) do
                   if (bufstr[i] = str[i]) then inc (ok);
           end;
           if keypressed and (readkey = #27) then exit;
           inc (count);
           if (count > ticks) then exit;
     until (ok >= ord (str[0]));
     wait_for:= true;
end;

procedure hand_shake (port : byte);
begin
     write ('Searching for driver... ');
     while not (wait_for (port, 'cess code:', 1500)) do send_str (port, 'client^');
     writeln ('found');
     while not (wait_for (port, 'driver:hello', 1500)) do send_str (port, 'client^');
     writeln ('setting up...');
end;

end.
