# Run the fine-delay LVDSOUT test

1. Plug two LVDSOUT pins to an oscilloscope and use the rising edge of LVDSOUT1
   as trigger.

2. Enable CLOCK1, set its period to the minimum (0.016 µs) and use it as input
   for both LVDSOUT1 and LVDSOUT2.

   ```{image} ../images/finedelay_test_layout.png
   :alt: Fine-delay test layout
   ```

3. Set oct delay and fine delay to 0 on both LVDSOUTs.

4. For LVDSOUT2, set oct delay from 1 to 7 and verify on the oscilloscope that
   you see delays from 1 ns to 7 ns respectively, then set oct delay back to 0.

5. Read the initial one-nanosecond delay of LVDSOUT2 as a reference for testing
   fine delay.

   1. Set fine delay to half the initial 1 ns and verify on the oscilloscope
      that the delay is around 500 ps.

   2. Set fine delay to a quarter of the initial 1 ns and verify that the delay
      is around 250 ps.

   3. Repeat halving until you reach the limit of your oscilloscope.

6. Run the [finedelay-sweep.py script](https://raw.githubusercontent.com/PandABlocks/PandABlocks.github.io/refs/heads/main/scripts/finedelay-sweep.py)
   that sweeps all fine delay values for each oct delay value and observe how
   LVDSOUT2 is delayed very smoothly.
