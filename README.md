# systemverilog-9bit-custom-cpu
processor bao gồm bus dữ liệu và bus địa chỉ 9-bit, 8 thanh ghi đa dụng với R7 là Program Counter, với ALU hỗ trợ tính toán số nguyên đơn giản và rẽ nhánh có điều kiện.
Instruction cycle theo chu trình nạp - giải mã - thực thi - lưu trữ đa xung nhịp, được quản lý thông qua máy trạng thái . Bên cạnh đó, hệ thống tích hợp bộ nhớ RAM 128 từ và khả năng giao tiếp với thiết bị ngoại vi bằng kỹ thuật memory-mapped I/O để xuất tín hiệu ra mảng LED.
