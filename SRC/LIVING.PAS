unit living;

interface

uses basicobj, room, itemd;

type
    proc = procedure (attacker, attacked : pchar);

    LivingObject   = object (BasicObject)
                            attacked : pchar;
                            inv      : ItemDaemon;
                            env      : RoomPtr;
                            do_fight : proc;

                            constructor init;

                            procedure heart_beat;

                            procedure start_fight (action : proc; who : pchar);
                            procedure stop_fight;

                            function add_money (value : integer) : boolean;
                            function add_exp (value : integer) : boolean;
                            function add_hp (value : integer) : boolean;

                            function reward_exp : word;

                            destructor destruct;
                     end;

    LivingPtr = ^LivingObject;

implementation

constructor LivingObject.init;
begin
     inherited init;
     inv.init;
     attacked:= nil;
     env:= nil;
     set_intvar ('fight', 0);
     set_intvar ('money', 0);
     set_intvar ('exp', 0);
     set_intvar ('hp', 0);
     set_intvar ('maxhp', 0);
end;


procedure LivingObject.heart_beat;
begin
     if (retrieve_intvar ('fight') > 0) then
        do_fight (retrieve_strvar ('short'), attacked);

     if ((retrieve_intvar ('hp') < retrieve_intvar ('maxhp')) and 
         (random (5) = 1)) then 
        set_intvar ('hp', retrieve_intvar ('hp') + 1);
end;

procedure LivingObject.start_fight (action : proc; who : pchar);
begin
     do_fight:= action;
     set_intvar ('fight', 1);
     attacked:= who;
end;

procedure LivingObject.stop_fight;
begin
     set_intvar ('fight', 0);
end;

function Livingobject.add_money (value : integer) : boolean;
var money : integer;
begin
     add_money:= true;
     money:= retrieve_intvar ('money');
     money:= money + value;
     if (money < 0) then
     begin
          money:= 0;
          add_money:= false;
     end;
     set_intvar ('money', money);
end;

function LivingObject.add_hp (value : integer) : boolean;
var hp, maxhp : integer;
begin
     add_hp:= true;
     hp:= retrieve_intvar ('hp');
     maxhp:= retrieve_intvar ('maxhp');
     hp:= hp + value;
     if (hp > maxhp) then hp:= maxhp;
     if (hp < 0) then
     begin
          hp:= 0;
          add_hp:= false;
     end;
     set_intvar ('hp',hp);
end;

function LivingObject.add_exp (value : integer) : boolean;
var exp : integer;
begin
     add_exp:= true;
     exp:= retrieve_intvar ('exp');
     exp:= exp + value;
     if (exp < 0) then
     begin
          exp:= 0;
          add_exp:= false;
     end;
     set_intvar ('exp',exp);
end;

function LivingObject.reward_exp : word;
begin
     reward_exp:= retrieve_intvar ('exp') div 3;
end;

destructor LivingObject.destruct;
begin
     inv.destruct;
     inherited destruct;
end;

end.
