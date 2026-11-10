library ieee;
use ieee.std_logic_1164.all;
-- use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

package cascaded_consts is
    -- Global
    constant ERR_CLIPPED_LIM : natural := 131070;

    -- Position
    -- constant K_INT : natural := 10 + 1; -- Includes signed
    -- constant K_FRAC : natural := 7;
    -- constant K_INT : natural := 3 + 1; -- Includes signed
    -- constant K_FRAC : natural := 14;
    constant K_INT : natural := 10 + 1; -- Includes signed
    constant K_FRAC : natural := 21;
    constant P_ERR_INT : natural := 24 + 1; -- Includes signed
    constant ID_ERR_INT : natural := 17 + 1; -- Includes signed
    constant FF_SETPOINT_SIZE : natural := 24 + 1; -- Includes signed
    constant CLIPPED_ERR_INT : natural := 17 + 1; -- Includes signed
    constant I_ACCUM_BUFFER : natural := 8;
    -- constant D_INVDT_INT : natural := 15 + 1; -- Includes signed
    -- constant D_INVDT_FRAC : natural := 16;
    constant D_DT_SIZE : natural := 24 + 1; -- Includes signed

    constant DT_INT : natural := 0 + 1; -- Includes signed
    constant DT_FRAC : natural := 21; -- 5e-6 @ 10% error

    constant P_MUL_SIZE : natural := P_ERR_INT + K_INT + K_FRAC;
    constant P_SCALED_SIZE : natural := P_MUL_SIZE + DT_FRAC - K_FRAC;

    constant I_MUL_FRAC_SIZE : natural := K_INT + DT_INT + K_FRAC + DT_FRAC;
    constant I_MUL_ERR_SIZE : natural := I_MUL_FRAC_SIZE + ID_ERR_INT;
    constant I_SCALED_FRAC_SIZE : natural := K_INT + DT_INT + ID_ERR_INT + DT_FRAC; --11+1+18.21
    constant I_SCALED_SIZE : natural := I_ACCUM_BUFFER + I_SCALED_FRAC_SIZE; --30+8.21

    constant D_MUL_SIZE : natural := K_INT + D_DT_SIZE + K_FRAC;
    -- constant D_MUL_SIZE : natural := K_INT + D_INVDT_INT + K_FRAC + D_INVDT_FRAC;
    constant D_MUL_ERR_SIZE : natural := D_MUL_SIZE + P_ERR_INT;
    -- constant D_MUL_ERR_SIZE : natural := D_MUL_SIZE + P_ERR_INT;
    constant D_SCALED_SIZE : natural := D_MUL_ERR_SIZE + DT_FRAC - K_FRAC;
    -- constant D_SCALED_SIZE : natural := D_MUL_ERR_SIZE - D_INVDT_FRAC;

    constant FF_MUL_SIZE : natural := FF_SETPOINT_SIZE + K_INT + K_FRAC;
    constant FF_SCALED_SIZE : natural := FF_MUL_SIZE + DT_FRAC - K_FRAC;

    constant SUM_OVERFLOW_SIZE : natural := 4;
    constant SUM_SCALED_SIZE : natural := D_SCALED_SIZE + SUM_OVERFLOW_SIZE + 7;

    -- Velocity

end package cascaded_consts;

-- K_INT + D_DT_SIZE + K_FRAC + ID_ERR_INT + DT_FRAC - K_FRAC
-- 4 + 25 + 14 + 18 + 21 - 14 = 68

-- 11 + 25 + 7 + 18 + 21 - 7 = 75




-- [KP_I]
-- type: param scalar
-- scale: 0.00006103515625
-- description: position proportional constant.

-- [KI_I]
-- type: param scalar
-- scale: 0.00006103515625
-- description: position integral constant.

-- [KD_I]
-- type: param scalar
-- scale: 0.00006103515625
-- description: position derivative constant.

-- [KFF_I]
-- type: param scalar
-- scale: 0.00006103515625
-- description: position feedforward constant.