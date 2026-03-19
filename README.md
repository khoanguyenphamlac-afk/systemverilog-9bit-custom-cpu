# Thiết kế RTL: Bộ vi xử lý 9-bit đa chu kỳ

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-9--bit-success.svg)
![Design Pattern](https://img.shields.io/badge/Design-Multi--Cycle-orange.svg)

## Giới thiệu chung
Dự án này là thiết kế phần cứng ở mức RTL cho lõi CPU 9-bit đa chu kỳ bằng ngôn ngữ SystemVerilog. Thiết kế dựa trên tập lệnh giống với Intel 4004, hệ thống bao gồm khối điều khiển FSM, 8 thanh ghi với thanh ghi R7 dùng để đếm chương trình - Program Counter), RAM 128 từ (word), khối ALU có cờ Zero và cổng I/O ánh xạ bộ nhớ memory-mapped để điều khiển đèn LED. CPU hỗ trợ 7 lệnh cơ bản.

---

## Mục lục
1. [Cấu trúc hệ thống](#cấu-trúc-hệ-thống)
2. [Chu trình lệnh và FSM](#chu-trình-lệnh-và-fsm)
3. [Đường dữ liệu (Datapath) và ALU](#đường-dữ-liệu-datapath-và-alu)
4. [Tập lệnh (ISA)](#tập-lệnh-isa)
5. [Phân chia Bộ nhớ và I/O](#phân-chia-bộ-nhớ-và-io)
6. [Sơ đồ RTL](#sơ-đồ-rtl)
7. [Mô phỏng và Biểu đồ xung](#mô-phỏng-và-biểu-đồ-xung)
8. [Cấu trúc Module](#cấu-trúc-module)
9. [Thông tin thêm và lời cám ơn](#thông-tin-thêm)

---

## Cấu trúc hệ thống

Module cao nhất `mcu_system` đóng vai trò kết nối CPU  với RAM và ngoại vi (`ledreg9bit`). 



<img width="800" height="239" alt="top_module" src="https://github.com/user-attachments/assets/b1787f6d-a3c9-4aa7-9143-72b5c62e9c33" />

<img width="427" height="278" alt="Ảnh chụp màn hình 2026-03-18 162504" src="https://github.com/user-attachments/assets/848af935-ea16-4684-bd22-96cf900c6b48" />


* **Bus dữ liệu vào/ra (DIN/DOUT):** 9 bit.
* **Bus địa chỉ (ADDR):** 9 bit. CPU xuất địa chỉ ra bus này để chọn nơi đọc/ghi.
* **Tín hiệu điều khiển:** Dùng cờ `W_Main` (viết) để ra lệnh ghi dữ liệu. Khối giải mã địa chỉ sẽ tự động quyết định đẩy dữ liệu vào RAM hay vào đèn LED dựa trên giá trị của bus địa chỉ (xem phần Phân chia Bộ nhớ).


---

## Chu trình lệnh và FSM

Khối điều khiển (`control_unit`) dùng Finite State Machine gồm 7 trạng thái. Điểm đặc biệt của thiết kế này là các trạng thái chờ được chèn vào để xử lý độ trễ của RAM, đảm bảo CPU đọc đúng dữ liệu.


<img width="355" height="245" alt="Ảnh chụp màn hình 2026-03-20 011422" src="https://github.com/user-attachments/assets/e312746a-e10e-46e0-964c-babe1cc68894" />


<img width="621" height="259" alt="cách_hoạt_động_tập_lệnh" src="https://github.com/user-attachments/assets/9b1c0fcb-61f2-462c-a664-2df43db648ac" />



Các trạng thái hoạt động thực tế trong mã nguồn:
1. **`T0` (Đặt địa chỉ):** Đưa địa chỉ lệnh tiếp theo ra RAM. Chờ tín hiệu địa chỉ ổn định.
2. **`T0_Wait` (Lấy lệnh):** RAM đã xuất dữ liệu. CPU lưu mã lệnh vào thanh ghi IR và tăng PC (`R7`) thêm 1.
3. **`T1` (Giải mã):** Dịch mã lệnh 3-bit (`IR[8:6]`). Chuẩn bị các đường truyền dữ liệu, ví dụ như mở đường cho R0 xuất dữ liệu ra bus.
4. **`T2` (Thực thi / Đặt địa chỉ bộ nhớ):** ALU thực hiện cộng/trừ. Nếu là lệnh đọc/ghi bộ nhớ (`ld`, `movi`), CPU xuất địa chỉ ra RAM.
5. **`T2_Wait` (Chờ RAM):** Dùng riêng cho lệnh `ld` và `movi` để chờ RAM đẩy dữ liệu ra bus. Các lệnh khác bỏ qua bước này.
6. **`T3` (Lưu kết quả):** Ghi kết quả từ ALU vào thanh ghi, hoặc chốt tín hiệu `W` để ghi dữ liệu vào RAM (`st`).
7. **`T4` (Tiếp theo):** Bật cờ `Done` báo hiệu xong lệnh, đẩy địa chỉ lệnh mới ra bus và quay về `T0`.

---

## Đường dữ liệu (Datapath) và ALU

Thiết kế đường dữ liệu dùng một bộ chọn kênh làm trung tâm để dẫn hướng dữ liệu giữa các khối.

<img width="743" height="386" alt="Ảnh chụp màn hình 2026-03-20 011808" src="https://github.com/user-attachments/assets/b957f601-beea-48fe-8c8d-c1d2013c3ba9" />

<img width="511" height="401" alt="Ảnh chụp màn hình 2026-03-20 011845" src="https://github.com/user-attachments/assets/d678f6cb-9ad0-43b8-ba00-a29995e25f34" />


<img width="430" height="359" alt="Ảnh chụp màn hình 2026-03-18 162448" src="https://github.com/user-attachments/assets/26e25c3a-ef7b-4f8b-b538-a5c51867e1cc" />

Đường dữ liệu quản lý cách các bit di chuyển giữa các thanh ghi và ALU bên trong lõi CPU.

* **Bộ chọn đường dẫn (Bus Multiplexer):** Sử dụng các lệnh `if-else` mức logic tổ hợp để chọn đúng 1 nguồn dữ liệu duy nhất (từ R0-R7, kết quả ALU, hoặc dữ liệu từ RAM) đẩy ra bus chung (`BusWires`).
* **Tính toán PC (`pc_logic`):** Thanh ghi R7 có một mạch tính riêng. Mạch này quyết định: một là cộng PC thêm 1 (khi đọc xong 1 lệnh), hai là nhận thẳng giá trị mới từ Bus (khi thực hiện lệnh nhảy).
* **Khối ALU (`alu`):** 
  * Được ghép nối tiếp từ 9 bộ cộng toàn phần (Full Adder). 
  * Phép trừ được thực hiện bằng phương pháp **bù 2**: Lấy đảo bit của toán hạng B (dùng cổng XOR với tín hiệu `AddSub`) và cộng thêm 1 (đưa tín hiệu `AddSub` vào `Cin`).
  * **Cờ Zero:** Dùng cổng NOR thu thập toàn bộ 9 bit kết quả đầu ra. Nếu tất cả đều bằng 0, cờ Zero bật lên 1 và được lưu vào flip-flop `ALUz` để dùng cho lệnh nhảy.

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

Hệ thống dùng phương pháp ánh xạ ngoại vi vào bộ nhớ. Khối `mcu_system` đọc bit thứ 7 và thứ 8 của Bus địa chỉ (`ADDR_Bus[8:7]`) để chuyển hướng dữ liệu thay vì cần thêm chân điều khiển riêng:



<img width="682" height="214" alt="Ảnh chụp màn hình 2026-03-20 012113" src="https://github.com/user-attachments/assets/d18e9a8a-2a7d-49cd-9540-9d8de1c77266" />



| Bit 8 | Bit 7 | Địa chỉ (Nhị phân) | Thiết bị nhận | Giải thích logic điều khiển |
| :---: | :---: | :--- | :--- | :--- |
| `0` | `0` | `00xxxxxxx` (0 - 127) | **RAM 128-word** | Cờ `Mem_Wr_En` bật khi `W_Main=1`, bit 8=0, bit 7=0. RAM nhận dữ liệu lệnh và biến. |
| `1` | `0` | `100000000` (256) | **Đèn LED** | Cờ `LED_En` bật khi `W_Main=1`, bit 8=1, bit 7=0. Mạch chặn lệnh ghi vào RAM và đẩy thẳng ra module đèn LED. |


Để đưa dữ liệu ra đèn LED, dùng lệnh `st` (ghi) với địa chỉ nhận là `256`. Mạch logic sẽ tự chuyển tín hiệu ghi đến module `ledreg9bit` thay vì đẩy vào RAM.

---



## Mô phỏng và Biểu đồ xung

Hoạt động của vi xử lý được kiểm tra bằng dữ liệu lưu trong bộ nhớ RAM 128 byte, test các chức năng của các tập lệnh

```
-- Memory Initialization File for 9-bit Processor
-- Depth: 128 words
-- Width: 9 bits

DEPTH = 128;
WIDTH = 9;
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;

CONTENT
BEGIN


00 : 000; -- NOP / Start

--Khởi động thanh ghi 
01 : 040; -- movi r0, #0x001
02 : 001; -- immediate for r0
03 : 048; -- movi r1, #0x002
04 : 002; -- immediate for r1
05 : 050; -- movi r2, #0x003
06 : 003; -- immediate for r2
07 : 058; -- movi r3, #0x004
08 : 004; -- immediate for r3
09 : 060; -- movi r4, #0x005
0A : 005; -- immediate for r4
0B : 068; -- movi r5, #0x006
0C : 006; -- immediate for r5
0D : 070; -- movi r6, #0x007
0E : 007; -- immediate for r6

-- Test bộ cộng 
0F : 0AC; -- add r4, r5 

-- Test load và store
10 : 058; -- movi r3, #0
11 : 000; -- immediate for r3
12 : 01E; -- mv r3, r6
13 : 048; -- movi r1, #64 (Decimal 100)
14 : 064; -- imm for r1
15 : 159; -- st r3, [r1] (Store to address 100)
16 : 129; -- ld r5, [r1]

-- Vòng lặp, rẽ nhánh
17 : 050; -- movi r2, 0x03
18 : 003; -- imm 0x03
19 : 037; -- mv r6, r7
1A : 0AD; -- add r5, r5
1B : 0D0; -- sub r2, r0
1C : 1BE; -- mvnz r7, r6

-- Test cộng lần 2 (số cao hơn)
1D : 060; -- movi r4, 0x4D
1E : 04D; -- imm
1F : 068; -- movi r5, 0x39
20 : 039; -- imm
21 : 0AC; -- add r5, r4 

-- Test hiển thị led
22 : 040; -- movi R0, 0x155
23 : 155; -- imm
24 : 048; -- movi R1, 0x00
25 : 000; -- imm
26 : 081; -- add R0, R1 

27 : 060; -- movi R4, 0x100 (LED Address)
28 : 100; -- imm: 

29 : 144; -- st R0, [R4] (Stores R0 result to LEDs)


--các địa chỉ còn lại trên RAM = 0
[2A..7F] : 000;

END;
```

<img width="542" height="419" alt="Ảnh chụp màn hình 2026-03-20 014040" src="https://github.com/user-attachments/assets/5bfebd70-1a94-49c8-bcb3-cf0429ff4ad8" />

<img width="535" height="423" alt="Ảnh chụp màn hình 2026-03-20 014117" src="https://github.com/user-attachments/assets/29959f1e-d2a5-41a0-8588-fc9b8c3661e2" />

<img width="903" height="192" alt="Ảnh chụp màn hình 2026-03-20 014134" src="https://github.com/user-attachments/assets/6ff5d0de-9130-42d1-9be1-b132708acede" />

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
## Thông tin thêm 
Dự án này là một bài tập thực hành thuộc chương trình học trên lớp, được thực hiện nhằm mục đích áp dụng các kiến thức lý thuyết về vi xử lý và thiết kế mạch số vào thực tế. 

Trong quá trình làm bài, mình rất biết ơn vì đã nhận được sự hướng dẫn trực tiếp từ các giảng viên để hiểu rõ hơn về luồng hoạt động của hệ thống. Đồng thời, mình cũng xin cảm ơn các bạn cùng lớp là những người đã dành thời gian thảo luận và hỗ trợ mình debug ở những đoạn code phức tạp. Những góp ý từ bên ngoài này đã giúp mình hoàn thiện thiết kế tốt hơn rất nhiều.

Bên cạnh đó, dự án có sử dụng các công cụ AI ở một chừng mực nhất định. AI chỉ đóng vai trò hỗ trợ phụ, chủ yếu dùng để trình bày file tài liệu README này, căn chỉnh định dạng và giải thích một vài lỗi cú pháp cơ bản. 

Cuối cùng, mình cũng muốn xin cám ơn những ai đã đọc hết dự án vì đã dành thời gian ra tìm hiểu và được mình chia sẻ đề tài này.
