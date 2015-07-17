view wave

add wave -group "UUT" -radix hexadecimal \
    sim:/panda_top_tb/uut/*

add wave -group "PS" -radix hexadecimal \
    sim:/panda_top_tb/uut/panda_ps_i/*

add wave -group "CSR IF" -radix hexadecimal \
    sim:/panda_top_tb/uut/panda_csr_if_inst/*

add wave -group "ENCIN" -radix hexadecimal \
    sim:/panda_top_tb/uut/ENCIN_INST/*

add wave -group "ENCOUT" -radix hexadecimal \
    sim:/panda_top_tb/uut/ENCOUT_INST/*

add wave -group "ENC MODEL" \
    sim:/panda_top_tb/daughter_card_model_inst/*

