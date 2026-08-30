# Định nghĩa Clock
create_clock -name clk -period 10.0 [get_ports {clk}]

# Thiết lập Delay cho toàn bộ chân Input và Output (Tránh truy vấn port rỗng)
set_input_delay 2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]

# Loại trừ các chân không cần ràng buộc Timing chặt chẽ
set_false_path -from [get_ports {rst_n}]
set_false_path -from [get_ports {ena}]
