# DRIVER11
Multi User Dungeon Driver for DOS

SOURCES TO THE DRIVER
---------------------

1. How to build the driver?

    In src directory:
        MAKE       - Make the real mode driver
        MAKED      - Make the real mode driver with debug info

        MAKEP      - Make the protected mode driver
        MAKEPD     - Make the protected mode driver with debug info

        MAKEALL    - Make the real mode driver and the client, and all utils


1.1 How to build the client?

    In src\client directory:
        MAKE       - Make the real mode client
        MAKED      - Make the real mode client with debug info


2. Where to get the additional units???

    You need two additional units, mouselib and comm_tp4.
    I cannot provide them, as they are shareware and want acknowledgements.

    ftp://garbo.uwasa.fi/pc/turbopa[s||7]/mouslib8.zip
    ftp://garbo.uwasa.fi/pc/turbopa[s||7]/comm_tp5.zip
    ftp://garbo.uwasa.fi/pc/turbopa[s||7]/xmslbr202.zip


2.1 I cannot get them..

    Well, excluding the mouse is simple, ( de-use mouse.pas and remove
    ( init_mouse and handle_mouse_events ) call ) in driver[386].pas.
    Now the mouse is gone.

    Excluding the comm unit requires removal of the uses of comm_tp4
    in ( file_inpr.pas and driver[386].pas ) and removal of the call
    handle_com_events in driver[386].pas. Now your serial port handling
    routines are gone as well.

    P.S. If you could not understand these sentences, you will probably
         not be able to change the code anyway ;)


3. Speeding up

    A notable speedup can be accomplished by running the Peephole
    Optimizer on all units. (This is not due to inefficient coding :)
    It is available as:              ^^^

    ftp://garbo.uwasa.fi/pc/turbopa7/spo120.zip


