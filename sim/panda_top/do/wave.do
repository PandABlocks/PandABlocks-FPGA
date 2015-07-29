view wave

add wave -group "UUT" -radix hexadecimal \
    "sim:/panda_top_tb/uut/*"

add wave -group "PS" -radix hexadecimal \
    "sim:/panda_top_tb/uut/panda_ps_i/*"

add wave -group "CSR IF" -radix hexadecimal \
    "sim:/panda_top_tb/uut/panda_csr_if_inst/*"

add wave -group "ENCIN_TOP" -radix hexadecimal \
    "sim:/panda_top_tb/uut/ENCIN_INST/*"

add wave -group "ENCIN" -radix hexadecimal \
    "sim:/panda_top_tb/uut/ENCIN_INST/INENC_GEN(0)/panda_encin_inst/*"

add wave -group "QDEC" -radix hexadecimal \
    "sim:/panda_top_tb/uut/ENCIN_INST/INENC_GEN(0)/panda_encin_inst/panda_quadin/panda_qdec_inst/*"

add wave -group "ENCOUT_TOP" -radix hexadecimal \
    "sim:/panda_top_tb/uut/ENCOUT_INST/*"

add wave -group "ENCOUT" -radix hexadecimal \
    "sim:/panda_top_tb/uut/ENCOUT_INST/ENCOUT_GEN(0)/panda_encout_inst/*"

add wave -group "INCROUT" -radix hexadecimal \
    "sim:/panda_top_tb/uut/ENCOUT_INST/ENCOUT_GEN(0)/panda_encout_inst/panda_quadout_inst/*"

add wave -group "DAUGTHER HW MODEL" \
    "sim:/panda_top_tb/daughter_card_model_inst/*"

add wave -group "INCR ENC MODEL" \
    "sim:/panda_top_tb/incr_encoder_model_inst/*"

add wave -Radix Unsigned -group "SEQ(0)" \
sim:/panda_top_tb/uut/SEQ_INST/SEQUENCER_GEN(0)/panda_sequencer_inst/*

