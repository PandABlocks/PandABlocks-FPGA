Pulse
=====

This is a one-shot pulse generator with width and delay control

Pulse stretching
----------------

.. plot::

    from block_plot import make_block_plot    
    make_block_plot("pulse", "Pulse stretching with no delay")

.. plot::

    from block_plot import make_block_plot        
    make_block_plot("pulse", "Pulse delay with no stretch")

.. plot::

    from block_plot import make_block_plot        
    make_block_plot("pulse", "Pulse delay and stretch")

.. plot::

    from block_plot import make_block_plot        
    make_block_plot("pulse", "Pulse train stretched and delayed")

    
    
.. plot::

    from block_plot import make_block_plot        
    make_block_plot("pulse", "Stretched and delayed pulses too close together")

