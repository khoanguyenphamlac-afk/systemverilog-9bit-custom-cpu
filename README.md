# Thiết kế RTL: Bộ vi xử lý 9-bit đa chu kỳ

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-9--bit-success.svg)
![Design Pattern](https://img.shields.io/badge/Design-Multi--Cycle-orange.svg)

## Giới thiệu chung
Dự án này là thiết kế phần cứng ở mức RTL cho lõi CPU 9-bit đa chu kỳ (multi-cycle) bằng ngôn ngữ SystemVerilog. Thiết kế dựa trên tập lệnh gần giống với Intel 4004. Hệ thống bao gồm khối điều khiển FSM, 8 thanh ghi (R7 dùng làm thanh ghi đếm chương trình - Program Counter), RAM 128 từ (word), khối ALU có cờ Zero và cổng I/O ánh xạ bộ nhớ (memory-mapped) để điều khiển đèn LED. CPU hỗ trợ 7 lệnh cơ bản.

---

## Mục lục
1. [Cấu trúc hệ thống](#cấu-trúc-hệ-thống)
2. [Chu trình lệnh và FSM](#chu-trình-lệnh-và-fsm)
3. [Đường dữ liệu (Datapath) và ALU](#đường-dữ-liệu-datapath-và-alu)
4.[Tập lệnh (ISA)](#tập-lệnh-isa)
5. [Phân chia Bộ nhớ và I/O](#phân-chia-bộ-nhớ-và-io)
6. [Sơ đồ RTL](#sơ-đồ-rtl)
7. [Mô phỏng và Biểu đồ xung](#mô-phỏng-và-biểu-đồ-xung)
8. [Cấu trúc Module](#cấu-trúc-module)
9. [Hướng dẫn Chạy thử nghiệm](#hướng-dẫn-chạy-thử-nghiệm)

---

## Cấu trúc hệ thống

Module cao nhất (Top module) `mcu_system` dùng để nối lõi CPU, RAM và các thiết bị bên ngoài.

![Sơ đồ kiến trúc mức Top](docs/top_module.png)
*(Thêm đường dẫn ảnh sơ đồ khối mcu_system tại đây)*

### Thông số kỹ thuật
* **Bus dữ liệu (Data Bus):** 9 bit.
* **Bus địa chỉ (Address Bus):** 9 bit.
* **Thanh ghi:** 8 thanh ghi chung (`R0` - `R7`). `R7` dùng làm thanh ghi đếm chương trình (PC).
* **Bộ nhớ:** RAM 128 từ (word), tổ chức theo mô hình von Neumann.

---

## Chu trình lệnh và FSM

Khối điều khiển dùng Máy trạng thái hữu hạn (FSM) để thực hiện các bước: Lấy lệnh (Fetch) - Giải mã (Decode) - Thực thi (Execute) - Lưu kết quả (Store). Mỗi lệnh cần chạy qua nhiều chu kỳ xung nhịp nhằm đảm bảo đủ thời gian để RAM đọc và ghi dữ liệu.

![Sơ đồ trạng thái FSM](docs/images/fsm_state_diagram.png)
*(Thêm đường dẫn ảnh sơ đồ trạng thái FSM tại đây)*

### Các trạng thái hoạt động:
1. **Lấy lệnh (`T0`, `T0_Wait`):** Đưa địa chỉ từ PC (`R7`) ra Bus địa chỉ. Đọc dữ liệu từ RAM vào Thanh ghi lệnh (IR). Tăng PC thêm 1.
2. **Giải mã (`T1`):** Dịch mã lệnh (Opcode) 3-bit. Mở đường cho dữ liệu từ thanh ghi đi vào bus bên trong và đặt mức logic cho Bus địa chỉ với các lệnh cần dùng bộ nhớ.
3. **Thực thi (`T2`, `T2_Wait`):** ALU tính toán (với lệnh `add`, `sub`) hoặc hệ thống chờ lấy dữ liệu từ RAM (với lệnh `ld`, `movi`).
4. **Lưu kết quả (`T3`):** Ghi kết quả tính toán vào thanh ghi nhận hoặc xuất dữ liệu ra RAM/cổng I/O (`st`).
5. **Tiếp theo (`T4`):** Bật cờ `Done`, đưa địa chỉ lệnh tiếp theo ra bus và quay lại `T0`.

---

## Đường dữ liệu (Datapath) và ALU

Thiết kế đường dữ liệu dùng một bộ chọn kênh (multiplexer) làm trung tâm để dẫn hướng dữ liệu giữa các khối.

![Sơ đồ Datapath](docs/images/cpu_datapath.png)
*(Thêm đường dẫn ảnh sơ đồ datapath tại đây)*

* **ALU:** Tạo ra từ các bộ cộng toàn phần (full-adder), làm phép cộng và phép trừ bù 2.
* **Cờ Zero:** Dùng cổng NOR để kiểm tra xem kết quả đầu ra của ALU có bằng 0 hay không, sau đó lưu vào flip-flop `ALUz`. Cờ này dùng cho lệnh nhảy `mvnz`.

---

## Tập lệnh (ISA)

Cấu trúc lệnh 9-bit nằm trong Thanh ghi lệnh (`IR[8:0]`):
* **`IR[8:6]`**: Mã lệnh (Opcode) 3-bit.
* **`IR[5:3]`**: Vị trí Thanh ghi X (`Rx` - Nơi nhận kết quả / Toán hạng 1).
* **`IR[2:0]`**: Vị trí Thanh ghi Y (`Ry` - Toán hạng 2).

| Opcode | Lệnh | Mô tả | RTL |
| :---: | :--- | :--- | :--- |
| `000` | **`mv Rx, Ry`** | Sao chép dữ liệu | `Rx ← Ry` |
| `001` | **`movi Rx`**| Lấy hằng số từ bộ nhớ | `Rx ← Memory[PC]; PC ← PC + 1` |
| `010` | **`add Rx, Ry`** | Cộng | `Rx ← Rx + Ry` |
| `011` | **`sub Rx, Ry`** | Trừ | `Rx ← Rx - Ry` |
| `100` | **`ld Rx, Ry`** | Đọc bộ nhớ | `Rx ← Memory[Ry]` |
| `101` | **`st Rx, Ry`** | Ghi bộ nhớ | `Memory[Ry] ← Rx` |
| `110` | **`mvnz Rx, Ry`**| Nhảy bước nếu khác 0 | `Nếu (Z == 0) thì Rx ← Ry` |

---

## Phân chia Bộ nhớ và I/O

Top module dùng phương pháp ánh xạ I/O vào bộ nhớ (Memory-Mapped I/O). Phần cứng chia không gian bộ nhớ thành các vùng như sau:

| Vùng địa chỉ (Nhị phân) | Địa chỉ (Thập phân) | Thiết bị | Mô tả |
| :--- | :--- | :--- | :--- |
| `00xxxxxxx` | `0` - `127` | **RAM** | Bộ nhớ chính (chứa cả Lệnh và Dữ liệu). |
| `100000000` | `256` | **LED** | Thanh ghi ngoại vi 9-bit. |

Để đưa dữ liệu ra đèn LED, dùng lệnh `st` (ghi) với địa chỉ nhận là `256`. Mạch logic sẽ tự chuyển tín hiệu ghi đến module `ledreg9bit` thay vì đẩy vào RAM.

---

## Sơ đồ RTL

Các sơ đồ này dùng để kiểm tra lại kết quả sau khi phần mềm dịch (synthesis) mã nguồn SystemVerilog ra logic phần cứng.

![Sơ đồ RTL mức Top](docs/images/rtl_viewer_top.png)
*(Thêm đường dẫn ảnh RTL schematic mức top tại đây)*

![Sơ đồ RTL khối FSM](docs/images/rtl_viewer_fsm.png)
*(Thêm đường dẫn ảnh RTL khối FSM tại đây)*

---

## Mô phỏng và Biểu đồ xung

Hoạt động của vi xử lý được kiểm tra bằng testbench ở mức RTL.

![Biểu đồ xung](docs/images/simulation_waveform.png)
*(Thêm đường dẫn ảnh biểu đồ xung tại đây)*

Các tín hiệu chính cần xem trên biểu đồ:
* Bước chuyển trạng thái `Tstep_Q` từ `T0` đến `T4`.
* Trạng thái tín hiệu `Done` ở cuối chu trình lệnh (`T4`).
* Sự thay đổi giá trị của `BusWires` và thanh ghi PC.

---

## Cấu trúc Module

* `mcu_system` (Mức cao nhất)
  * `processor` (Lõi CPU)
    * `control_unit` (FSM và Giải mã lệnh)
    * `alu` (Phép toán số học)
    * `pc_logic` (Tính và nạp giá trị PC)
    * `register` (Các thanh ghi R0-R7, A, G, IR, PC)
    * `bus_multiplexer` (Bộ chọn đường dẫn Bus)
  * `RAM` (Bộ nhớ lệnh và dữ liệu)
  * `ledreg9bit` (Thanh ghi I/O)

---

## Hướng dẫn Chạy thử nghiệm

1. Tải mã nguồn:
   ```bash
   git clone https://github.com/Tên-Của-Bạn/systemverilog-9bit-cpu.git
