# 💻 Vi xử lý 9-bit Đa chu kỳ Tùy chỉnh (Thiết kế RTL)

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-9--bit-success.svg)
![Design Pattern](https://img.shields.io/badge/Design-Multi--Cycle-orange.svg)

## 📌 Tổng quan dự án
Repository này chứa toàn bộ mã nguồn RTL (Register-Transfer Level) của một **Vi xử lý 9-bit đa chu kỳ (multi-cycle)** được thiết kế bằng **SystemVerilog**. Được xây dựng hoàn toàn từ đầu, dự án này minh họa các khái niệm cốt lõi của kiến trúc máy tính, bao gồm điều khiển bằng Máy trạng thái (FSM), Kiến trúc tập lệnh tùy chỉnh (ISA), Tổ chức bộ nhớ von Neumann, và Kỹ thuật Ánh xạ bộ nhớ (Memory-Mapped I/O).

Vi xử lý này sở hữu datapath gồm 8 thanh ghi, một Khối tính toán số học logic (ALU) chuyên dụng, một chu trình thực thi đa xung nhịp, và các thiết bị ngoại vi phần cứng (mảng LED 9-bit) được điều khiển thông qua các địa chỉ bộ nhớ cụ thể.

---

## 📑 Mục lục
1. [Kiến trúc Hệ thống](#-kiến-trúc-hệ-thống)
2. [Chu trình lệnh và FSM](#-chu-trình-lệnh--khối-điều-khiển-fsm)
3. [Datapath & ALU](#-datapath--alu)
4. [Kiến trúc Tập lệnh (ISA)](#-kiến-trúc-tập-lệnh-isa)
5. [Bản đồ Bộ nhớ & I/O](#-bản-đồ-bộ-nhớ--io)
6. [Sơ đồ khối RTL](#-sơ-đồ-khối-rtl)
7. [Mô phỏng & Giản đồ xung (Waveforms)](#-mô-phỏng--giản-đồ-xung-waveforms)
8. [Cấu trúc phân cấp Module](#-cấu-trúc-phân-cấp-module)
9. [Hướng dẫn Chạy / Tổng hợp (Synthesize)](#-hướng-dẫn-chạy--tổng-hợp-synthesize)

---

## 🏛️ Kiến trúc Hệ thống

Hệ thống ở mức cao nhất (`mcu_system`) đóng vai trò như một bo mạch chủ (motherboard), kết nối Lõi CPU, Bộ nhớ chính (RAM) và các Thiết bị ngoại vi (LED).

![Top Level System Architecture](docs/images/top_level_architecture.png)
> *<!-- 📸 THÊM ẢNH TẠI ĐÂY: Sơ đồ khối minh họa mcu_system, Lõi CPU, RAM và đầu ra LED tương tác với nhau qua bus dữ liệu và bus địa chỉ 9-bit. -->*

### Thông số Kỹ thuật Chính:
* **Độ rộng Bus dữ liệu (Data Bus):** 9 bit
* **Độ rộng Bus địa chỉ (Address Bus):** 9 bit
* **Thanh ghi (Registers):** 8 thanh ghi đa dụng (`R0` - `R7`). *Lưu ý: `R7` được nối cứng để đóng vai trò làm Bộ đếm chương trình (Program Counter - PC).*
* **Bộ nhớ (Memory):** RAM nội 128-word (Theo kiến trúc von Neumann, dùng chung cho cả Lệnh và Dữ liệu).

---

## 🔄 Chu trình lệnh & Khối điều khiển (FSM)

Khối điều khiển được quản lý bởi một Máy trạng thái hữu hạn (FSM) đa trạng thái, điều phối luồng thực thi nghiêm ngặt: **Nạp (Fetch) - Giải mã (Decode) - Thực thi (Execute) - Lưu trữ (Store)**. Vì đây là vi xử lý đa chu kỳ, mỗi lệnh cần nhiều chu kỳ xung nhịp (clock cycles) để hoàn thành, giúp các thao tác đọc/ghi bộ nhớ ổn định và tối ưu việc tái sử dụng phần cứng (như ALU).

![FSM State Diagram](docs/images/fsm_state_diagram.png)
> *<!-- 📸 THÊM ẢNH TẠI ĐÂY: Biểu đồ chuyển trạng thái FSM hiển thị các bước T0 -> T0_Wait -> T1 -> T2 -> T3 -> T4 dựa trên từng loại lệnh. -->*

### Các Trạng thái Thực thi:
1. **Nạp lệnh - Fetch (`T0`, `T0_Wait`):** PC (`R7`) được đẩy lên Address Bus. Hệ thống chờ RAM xuất lệnh, sau đó lệnh này được chốt (latch) vào Thanh ghi lệnh (IR). PC tự động tăng thêm 1.
2. **Giải mã - Decode (`T1`):** Mã lệnh (Opcode) 3-bit được giải mã. Các toán hạng được chuẩn bị (ví dụ: đưa giá trị thanh ghi vào các bus nội bộ của ALU). Address Bus được cấu hình cho các thao tác bộ nhớ.
3. **Thực thi - Execute (`T2`, `T2_Wait`):** ALU thực hiện tính toán số học (`add`, `sub`), hoặc hệ thống chờ dữ liệu được tải về từ RAM (`ld`, `movi`).
4. **Ghi lại / Lưu trữ - Write-Back / Store (`T3`):** Kết quả từ ALU được đưa ngược lại thanh ghi đích, hoặc dữ liệu được ghi vĩnh viễn vào RAM/Thiết bị ngoại vi (`st`).
5. **Chu kỳ tiếp theo (`T4`):** Tín hiệu `Done` được bật, địa chỉ lệnh tiếp theo được xuất ra bus, và chu trình quay trở lại `T0`.

---

## 🛤️ Datapath & ALU

Datapath hoạt động dựa trên một bộ dồn kênh (bus multiplexer) trung tâm giúp định tuyến dữ liệu giữa các thanh ghi, ALU và bộ nhớ ngoài.

![CPU Datapath](docs/images/cpu_datapath.png)
> *<!-- 📸 THÊM ẢNH TẠI ĐÂY: Sơ đồ minh họa Tập thanh ghi, các thanh ghi đệm A & G, ALU và Bus multiplexer trung tâm. -->*

* **Thiết kế ALU:** Được xây dựng từ các khối bộ cộng toàn phần (full-adder) tùy chỉnh. Hỗ trợ phép cộng và phép trừ (sử dụng bù 2).
* **Logic Cờ Zero (Zero Flag):** Một mảng cổng NOR tổ hợp phát hiện khi đầu ra ALU bằng chính xác 0, sau đó chốt vào flip-flop `ALUz`. Tính năng này được lệnh `mvnz` sử dụng cho các thao tác rẽ nhánh có điều kiện (ví dụ: vòng lặp `while`).

---

## 📜 Kiến trúc Tập lệnh (ISA)

CPU sử dụng định dạng lệnh 9-bit tùy chỉnh. 9 bit của Thanh ghi lệnh (`IR[8:0]`) được chia như sau:
* **`IR[8:6]`**: Opcode 3-bit (Loại lệnh)
* **`IR[5:3]`**: Index 3-bit của Thanh ghi X (`Rx` - Đích đến / Toán hạng 1)
* **`IR[2:0]`**: Index 3-bit của Thanh ghi Y (`Ry` - Toán hạng 2)

| Opcode | Lệnh (Mnemonic) | Mô tả Hoạt động | Logic RTL |
| :---: | :--- | :--- | :--- |
| `000` | **`mv Rx, Ry`** | Chuyển dữ liệu giữa các thanh ghi | `Rx ← Ry` |
| `001` | **`movi Rx`**| Chuyển hằng số (Byte tiếp theo trong Mem) | `Rx ← Memory[PC]; PC ← PC + 1` |
| `010` | **`add Rx, Ry`** | Phép cộng | `Rx ← Rx + Ry` |
| `011` | **`sub Rx, Ry`** | Phép trừ | `Rx ← Rx - Ry` |
| `100` | **`ld Rx, Ry`** | Tải từ bộ nhớ (Địa chỉ lưu ở Ry) | `Rx ← Memory[Ry]` |
| `101` | **`st Rx, Ry`** | Lưu Rx vào bộ nhớ (Địa chỉ lưu ở Ry) | `Memory[Ry] ← Rx` |
| `110` | **`mvnz Rx, Ry`**| Chuyển nếu khác 0 (Rẽ nhánh) | `Nếu (Z == 0) thì Rx ← Ry` |

---

## 🗺️ Bản đồ Bộ nhớ & I/O

Logic giải mã địa chỉ phần cứng được tích hợp trực tiếp vào module top (`mcu_system`) để phân tách RAM vật lý khỏi các thiết bị I/O bằng kỹ thuật **Memory-Mapped I/O**.

| Dải địa chỉ (Nhị phân) | Địa chỉ (Thập phân) | Thiết bị Đích | Mô tả |
| :--- | :--- | :--- | :--- |
| `00xxxxxxx` | `0` - `127` | **RAM** | Bộ nhớ chính 128-word (Lưu Dữ liệu & Lệnh) |
| `100000000` | `256` | **Đầu ra LED** | Thanh ghi LED 9-bit được ánh xạ bộ nhớ |

**Điều khiển Thiết bị Phần cứng:** Để xuất dữ liệu ra mảng LED thực tế, lập trình viên chỉ cần nạp số `256` vào một thanh ghi bất kỳ và sử dụng lệnh `st` (store). Module top-level sẽ can thiệp vào tín hiệu `W_Main` và định tuyến luồng dữ liệu sang module `ledreg9bit` thay vì ghi vào RAM.

---

## 🔌 Sơ đồ khối RTL

Dưới đây là các sơ đồ khối RTL (Register-Transfer Level) được tạo ra trong quá trình tổng hợp (synthesis), dùng để xác minh việc ánh xạ logic phần cứng.

![Top Level RTL Viewer](docs/images/rtl_viewer_top.png)
> *<!-- 📸 THÊM ẢNH TẠI ĐÂY: Ảnh chụp màn hình RTL schematic của Top-level từ Quartus/Vivado. -->*

![Control Unit RTL Viewer](docs/images/rtl_viewer_fsm.png)
> *<!-- 📸 THÊM ẢNH TẠI ĐÂY: Ảnh chụp màn hình RTL mapping của khối điều khiển FSM. -->*

---

## 📈 Mô phỏng & Giản đồ xung (Waveforms)

Thiết kế đã được kiểm chứng bằng testbench để mô phỏng các chu kỳ xung nhịp, quá trình nạp lệnh và các phép toán ALU.

![Simulation Waveforms](docs/images/simulation_waveform.png)
> *<!-- 📸 THÊM ẢNH TẠI ĐÂY: Ảnh chụp màn hình từ ModelSim / QuestaSim / Vivado Simulator. -->*

**Các điểm đáng chú ý trên Giản đồ xung:**
* Quá trình khởi tạo tín hiệu `Clock` và `Resetn`.
* Quan sát `Tstep_Q` chuyển đổi qua các trạng thái FSM (`T0` -> `T1` -> `T2` -> `T3` -> `T4`).
* Tín hiệu `Done` nhảy lên mức cao tại trạng thái `T4`, cho biết lệnh đã thực thi xong và `PC` được cập nhật.
* `BusWires` phản ánh quá trình định tuyến dữ liệu chính xác giữa các thanh ghi và bộ nhớ.

---

## 📂 Cấu trúc phân cấp Module

* `mcu_system` *(Module cao nhất)*
  * `processor` *(Lõi CPU)*
    * `control_unit` *(FSM, Bộ giải mã lệnh)*
    * `alu` *(Logic toán học tổ hợp xây dựng từ các full-adder)*
    * `pc_logic` *(Định tuyến Program Counter)*
    * `register` *(Mảng D-Flip-Flop cho R0-R7, A, G, IR, PC)*
    * `bus_multiplexer` *(Định tuyến dữ liệu)*
  * `RAM` *(Khối bộ nhớ)*
  * `ledreg9bit` *(Thanh ghi đầu ra ánh xạ bộ nhớ)*

---

## 🚀 Hướng dẫn Chạy / Tổng hợp (Synthesize)

1. Clone repository về máy:
   ```bash
   git clone https://github.com/Tên-Của-Bạn/systemverilog-9bit-cpu.git
