ADDER - Position Adder [x2]
===============================
The position adder block has an output which is the sum of the position inputs

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
INPA            In          Position input A
INPB            In          Position input B
INPC            In          Position input C
INPD            In          Position input D
SCALE           W   UInt32  | Scale divisor after add
                            | 0 = /1
                            | 1 = /2
                            | 2 = /4
OUT             Out         Position output
=============== === ======= ===================================================



Adding inputs
-----------------
The output is the sum of the inputs

.. sequence_plot::
   :block: adder
   :title: Adding inputs

Scaling
-----------------
The scale factor is a bit shift and is applied after the sum.

.. sequence_plot::
   :block: adder
   :title: Scaling