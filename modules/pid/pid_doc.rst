PID - PID controller
========================



The PID block is an implementation of the classical proportional/integral/derivative controller.
Its gains are intended as in 
`parallel form <https://en.wikipedia.org/wiki/PID_controller#Standard_versus_parallel_(ideal)_form>`_ 


The controller has protection features like:


    - anti-integral windup 

    - possibility to take the derivative of the process variable instead of the error


This is a discrete time implementation, with external sampling frequency in range [1Hz,1MHz]. The internal clock resampler frequency is reset by the ENABLE signal, so it's recommended to use the same signal for the ENABLE of the CLOCK block that generates the sampling frequency.

Inputs can be inverted, for ease of implementation. Full scale is meant to be +/- 1 in the scaled PandaBlocks representation (or signed 32-bit int if raw representation is preferred). Internal calculations in 64 bit.








Fields
-----------------------------------------------------



.. block_fields:: modules/pid/pid.block.ini


