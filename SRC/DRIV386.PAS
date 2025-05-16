program main;

uses universe, fileinpr, tasker, comports, keyboard, mouse, screen, syscons, err, crt, xms;

var
   u: UniversePtr;
   cmd: String[1];
   init_file,
   init_file2: string[20];

begin
     init_file:= 'driver.ini';
     writeln ('Game Driver System 1.09b  (c) 1993-1995  Prinssoft Corp.  All rights reserved.');
     writeln ('Protected mode version 0.9b  (c) 1995  Prinssoft Corp.  All rights reserved.');
     writeln ('Memory: ', memavail, ' bytes available');

     repeat
       writeln ('Ok.');
       write ('>');
       readln (cmd);
       case cmd[1] of
         'q': break;
         'm': begin
                writeln ('Memory: ', memavail, ' bytes available');
              end;
         'i': begin
                write ('New initfile [',init_file,']: ');
                readln (init_file2);
                if not (ord (init_file2[0]) = 0) then init_file:= init_file2;
              end;
         'b': begin
                save_screen;

                if (ParamCount > 0) then error_init     (ParamStr (1))
                                     else error_init     ('runtime.err');

                if (ParamCount > 1) then interpret_init (ParamStr (2), true)
                                     else interpret_init ('interpre.err', true);

                if (maxavail < sizeof (UniverseObject)) then
                    error ('driver: out of memory allocating universe', 1);

                getmem (u, sizeof (UniverseObject));
                u^.init;

                if not interpret (init_file, u, nil) then continue;

                keyboard_init (u);
                mouse_init;

                repeat
                  handle_com_events (u);

                  handle_key_events (u);

                  handle_mouse_events (u);

                  run_tasks (u);
                until u^.run = false;

                u^.destruct;
                freemem (u, sizeof (UniverseObject));
                window (1, 1, 80, 25);
                textbackground (0);
                textcolor (7);
                mouse_done;
                syscons_done;
                restore_screen;
                cursor_on;
              end;
         else writeln ('[b]oot   [m]emory   [i]nitfile   [q]uit');
       end;
     until false;

     writeln ('Goodbye.');
end.
