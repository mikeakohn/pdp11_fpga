// PDP-11 FPGA Core
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2025 by Michael Kohn

module pdp11
(
  output [7:0] leds,
  output [3:0] column,
  input raw_clk,
  output ioport_0,
  output ioport_1,
  output ioport_2,
  output ioport_3,
  input  button_reset,
  input  button_halt,
  input  button_program_select,
  input  button_0,
  output spi_clk,
  output spi_mosi,
  input  spi_miso
);

// iceFUN 8x4 LEDs used for debugging.
reg [7:0] leds_value;
reg [3:0] column_value;

assign leds = leds_value;
assign column = column_value;

// Memory bus (ROM, RAM, peripherals).
reg  [15:0] mem_address    = 0;
reg  [15:0] mem_write      = 0;
reg  [1:0]  mem_write_mask = 0;
wire [15:0] mem_read;

reg mem_bus_enable   = 0;
reg mem_write_enable = 0;

// Clock.
reg [21:0] count = 0;
reg [5:0]  state = 0;
reg [5:0]  next_state = 0;
reg [2:0]  clock_div;
reg [14:0] delay_loop;
wire clk;
assign clk = clock_div[0];

// Registers.
//parameter SR = 2;
parameter SP = 6;
parameter PC = 7;

reg  [15:0] registers [7:0];
wire [15:0] pc;
wire [15:0] sp;

// FIXME: ?
reg  [15:0] ea;

reg [7:0] psw;

// FIXME: Allows only vectors from 0x0000 to 0x00ff. Is this okay?
reg [7:0] vector_address;

assign pc = { registers[PC][15:1], 1'b0 };
assign sp = registers[SP];

reg [7:0] new_pc;
reg [7:0] new_ps;

// Flags.
parameter FLAG_C = 0;
parameter FLAG_V = 1;
parameter FLAG_Z = 2;
parameter FLAG_N = 3;
parameter FLAG_T = 4;

wire flag_c;
wire flag_n;
wire flag_z;
wire flag_v;
wire flag_t;
wire [2:0] flag_i;

assign flag_c = psw[FLAG_C];
assign flag_v = psw[FLAG_V];
assign flag_z = psw[FLAG_Z];
assign flag_n = psw[FLAG_N];
assign flag_t = psw[FLAG_T];
assign flag_i = psw[7:5];

// Instruction
reg [15:0] instruction;

wire [2:0] instr_type;
wire [2:0] instr_subtype;
wire [2:0] branch_op;
wire [2:0] alu_op_1;
wire [2:0] alu_op_2;

assign instr_type    = instruction[14:12];
assign instr_subtype = instruction[11:9];
assign alu_op_1      = instruction[8:6];
assign alu_op_2      = instruction[14:12];
assign branch_op     = instruction[10:8];

wire [2:0] src_mod;
wire [2:0] src_reg;
wire [2:0] dst_mod;
wire [2:0] dst_reg;

assign src_mod = instruction[11:9];
assign src_reg = instruction[8:6];
assign dst_mod = instruction[5:3];
assign dst_reg = instruction[2:0];

wire [2:0] sob_reg;
assign sob_reg = instruction[8:6];

reg bw;
reg wb;

wire signed [8:0] branch_offset;
wire signed [15:0] branch_address;

assign branch_offset = { instruction[7:0], 1'b0 };
assign branch_address = $signed(pc) + branch_offset;

//wire is_double;
//assign is_double = instr_type != 3'b000 && instr_type != 3'b111;

reg is_src;

reg [15:0] source;
reg [15:0] temp;
reg [16:0] result;

// Load / Store.
reg [2:0] ea_reg;
reg [2:0] ea_mod;

// Lower 6 its of the instruction.
wire [5:0] opcode;
assign opcode = instruction[5:0];

reg reti_state;

// Debug.
//reg [7:0] debug_0 = 0;
//reg [7:0] debug_1 = 0;
//reg [7:0] debug_2 = 0;
//reg [7:0] debug_3 = 0;

parameter STATE_RESET             = 0;
parameter STATE_DELAY_LOOP        = 1;
parameter STATE_FETCH_VECTOR_0    = 2;
parameter STATE_FETCH_VECTOR_1    = 3;
parameter STATE_FETCH_OP_0        = 4;
parameter STATE_FETCH_OP_1        = 5;
parameter STATE_START_DECODE      = 6;

parameter STATE_DATA_START        = 7;
parameter STATE_FETCH_OFFSET_0    = 8;
parameter STATE_FETCH_OFFSET_1    = 9;
parameter STATE_FETCH_FROM_EA_0   = 10;
parameter STATE_FETCH_FROM_EA_1   = 11;
parameter STATE_FETCH_INDIRECT_0  = 12;
parameter STATE_FETCH_INDIRECT_1  = 13;
parameter STATE_FETCH_DATA_0      = 14;
parameter STATE_FETCH_DATA_1      = 15;
parameter STATE_DATA_END          = 16;

parameter STATE_ALU_SINGLE_000    = 17;
parameter STATE_ALU_SINGLE_101    = 18;
parameter STATE_ALU_SINGLE_110    = 19;
parameter STATE_ALU_TWO           = 20;
parameter STATE_ALU_EIS           = 21;

parameter STATE_EXECUTE_SOB_0     = 22;
parameter STATE_EXECUTE_SOB_1     = 23;

parameter STATE_POP_0             = 24;
parameter STATE_POP_1             = 25;

parameter STATE_WB_SINGLE_0       = 26;

parameter STATE_DATA_STORE_0      = 27;
parameter STATE_DATA_STORE_1      = 28;

parameter STATE_BRANCH            = 29;

parameter STATE_RETI_0            = 30;
parameter STATE_RETI_1            = 31;

parameter STATE_MARK_0            = 32;
parameter STATE_MARK_1            = 33;

parameter STATE_JSR               = 34;

parameter STATE_PUSH_0            = 35;
parameter STATE_PUSH_1            = 36;

parameter STATE_WAIT              = 53;
parameter STATE_TRAP_0            = 54;
parameter STATE_TRAP_1            = 55;
parameter STATE_TRAP_2            = 56;
parameter STATE_TRAP_3            = 57;
parameter STATE_TRAP_4            = 58;
parameter STATE_TRAP_5            = 59;
parameter STATE_TRAP_6            = 60;
parameter STATE_TRAP_7            = 61;
parameter STATE_ERROR             = 62;
parameter STATE_HALTED            = 63;

parameter OP_BRANCH_BR   = 3'b001;
parameter OP_BRANCH_BNE  = 3'b010;
parameter OP_BRANCH_BEQ  = 3'b011;
parameter OP_BRANCH_BGE  = 3'b100;
parameter OP_BRANCH_BLT  = 3'b101;
parameter OP_BRANCH_BGT  = 3'b110;
parameter OP_BRANCH_BLE  = 3'b111;

parameter OP_BRANCH_BPL  = 3'b000;
parameter OP_BRANCH_BMI  = 3'b001;
parameter OP_BRANCH_BHI  = 3'b010;
parameter OP_BRANCH_BLOS = 3'b011;
parameter OP_BRANCH_BVC  = 3'b100;
parameter OP_BRANCH_BVS  = 3'b101;
parameter OP_BRANCH_BCC  = 3'b110;
parameter OP_BRANCH_BCS  = 3'b111;

parameter OP_MOV = 3'b001;
parameter OP_CMP = 3'b010;
parameter OP_BIT = 3'b011;
parameter OP_BIC = 3'b100;
parameter OP_BIS = 3'b101;
parameter OP_ADD = 3'b110;
parameter OP_SUB = 3'b110;

parameter OP_CLR = 3'b000;
parameter OP_COM = 3'b001;
parameter OP_INC = 3'b010;
parameter OP_DEC = 3'b011;
parameter OP_NEG = 3'b100;
parameter OP_ADC = 3'b101;
parameter OP_SBC = 3'b110;
parameter OP_TST = 3'b111;

parameter OP_ROR = 3'b000;
parameter OP_ROL = 3'b001;
parameter OP_ASR = 3'b010;
parameter OP_ASL = 3'b011;

// FIXME: What to do here.
parameter OP_MARK = 3'b100;
parameter OP_MTPS = 3'b100;
parameter OP_MFPI = 3'b101;
parameter OP_MFPD = 3'b101;
parameter OP_MTPI = 3'b110;
parameter OP_MTPD = 3'b110;
parameter OP_SXT  = 3'b111;
parameter OP_MFPS = 3'b111;

// This block is simply a clock divider for the raw_clk.
always @(posedge raw_clk) begin
  count <= count + 1;
  clock_div <= clock_div + 1;
end

// Debug: This block simply drives the 8x4 LEDs.
always @(posedge raw_clk) begin
  case (count[9:7])
    3'b000: begin column_value <= 4'b0111; leds_value <= ~registers[3][7:0]; end
    3'b010: begin column_value <= 4'b1011; leds_value <= ~registers[3][15:8]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~ea[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~ea[15:8]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~result[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~result[15:8]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~temp[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~temp[15:8]; end
    3'b100: begin column_value <= 4'b1101; leds_value <= ~registers[PC]; end
    3'b110: begin column_value <= 4'b1110; leds_value <= ~state; end
    default: begin column_value <= 4'b1111; leds_value <= 8'hff; end
  endcase
end

// This block is the main CPU instruction execute state machine.
always @(posedge clk) begin
  if (!button_reset)
    state <= STATE_RESET;
  else if (!button_halt)
    state <= STATE_HALTED;
  else
    case (state)
      STATE_RESET:
        begin
          mem_address      <= 0;
          mem_write_enable <= 0;
          mem_write        <= 0;
          vector_address   <= 0;
          delay_loop <= 12000;
          state <= STATE_DELAY_LOOP;
          reti_state <= 0;
        end
      STATE_DELAY_LOOP:
        begin
          // This is probably not needed. The chip starts up fine without it.
          if (delay_loop == 0) begin
            state <= STATE_FETCH_VECTOR_0;
          end else begin
            delay_loop <= delay_loop - 1;
          end
        end
      STATE_FETCH_VECTOR_0:
        begin
          mem_bus_enable <= 1;
          mem_address    <= vector_address;
          state <= STATE_FETCH_VECTOR_1;
        end
      STATE_FETCH_VECTOR_1:
        begin
          mem_bus_enable <= 0;

          if (vector_address[0] == 0) begin
            registers[PC] <= { mem_read[15:1], 1'b0 };
            state <= STATE_FETCH_VECTOR_0;
          end else begin
            psw <= mem_read[15:0];
            state <= STATE_FETCH_OP_0;
          end

          vector_address <= vector_address + 1;
        end
      STATE_FETCH_OP_0:
        begin
          is_src <= 0;
          bw     <= 0;
          wb     <= 1;
          mem_bus_enable <= 1;
          mem_address    <= pc;
          registers[PC] <= registers[PC] + 2;
          state <= STATE_FETCH_OP_1;
        end
      STATE_FETCH_OP_1:
        begin
          mem_bus_enable <= 0;
          instruction    <= mem_read;
          state <= STATE_START_DECODE;
        end
      STATE_START_DECODE:
        begin
          case (instr_type)
            3'b000:
              begin
                if (instruction[11] == 1'b1) begin
                  if (instruction[10:9] == 2'b00) begin
                    // jsr, emt, trap
                    if (instruction[15] == 1'b0) begin
                      next_state <= STATE_JSR;
                      state <= STATE_DATA_START;
                    end else begin
                      new_pc <= instruction[8] == 0 ? 8'o30 : 8'o34;
                      new_ps <= instruction[8] == 0 ? 8'o32 : 8'o36;
                      state <= STATE_TRAP_0;
                    end
                  end else begin
                    // OP_SINGLE
                    bw <= instruction[15];

                    case (instr_subtype)
                      3'b101:  next_state <= STATE_ALU_SINGLE_101;
                      3'b110:  next_state <= STATE_ALU_SINGLE_110;
                      default: state <= STATE_ERROR;
                    endcase

                    if (instruction[11:6] == 6'b110100 && instruction[15] == 0)
                      begin
                        // mark, mtps.
                        temp  <= registers[SP];
                        state <= STATE_ALU_SINGLE_110;
                      end
                    else
                      state <= STATE_DATA_START;
                  end
                end else begin
                  if (instruction[10:8] == 3'b000)
                    case (instruction[7:6])
                      2'b00:
                        case (instruction[2:0])
                          3'b000:
                            // halt.
                            state <= STATE_HALTED;
                          3'b001:
                            // wait.
                            state <= STATE_WAIT;
                          3'b010:
                            // rti.
                            state <= STATE_RETI_0;
                          3'b011:
                            begin
                              // bpt.
                              new_pc <= 8'o14;
                              new_ps <= 8'o16;
                              state <= STATE_TRAP_0;
                            end
                          3'b100:
                            begin
                              // iot.
                              new_pc <= 8'o20;
                              new_ps <= 8'o22;
                              state <= STATE_TRAP_0;
                            end
                          3'b101:
                            // reset.
                            state <= STATE_RESET;
                          3'b110:
                            // rtt.
                            state <= STATE_RETI_0;
                        endcase
/*
                      2'b01:
                        begin
                          // jmp 01. swab 11.
                          next_state <= STATE_ALU_SINGLE_000;
                          state <= STATE_DATA_START;
                        end
*/
                      2'b10:
                        // status set / clear c,s (alias nop) / rts.
                        if (instruction[5] == 1'b1) begin
                          if (instruction[4] == 0)
                            psw <= psw[3:0] & ~instruction[3:0];
                          else
                            psw <= psw[3:0] | instruction[3:0];

                          state <= STATE_FETCH_OP_0;
                        end else begin
                          registers[PC] <= registers[dst_reg];
                          ea_reg <= dst_reg;
                          ea_mod <= 0;
                          state <= STATE_POP_0;
                        end
                      default:
                        begin
                          // jmp 01. swab 11.
                          next_state <= STATE_ALU_SINGLE_000;
                          state <= STATE_DATA_START;
                        end
                    endcase
                  else
                    // OP_BRANCH
                    state <= STATE_BRANCH;
                end
              end
            3'b111:
              begin
                if (instr_subtype == 3'b111) begin
                  temp <= registers[sob_reg] - 1;
                  state <= STATE_EXECUTE_SOB_0;
                end else begin
                  // mul, div, ash, ashc, xor.
                  next_state <= STATE_ALU_EIS;
                  state <= STATE_DATA_START;
                end
              end
            default:
              begin
                // OP_DOUBLE (Two operand ALU).
                is_src <= 1;
                next_state <= STATE_ALU_TWO;

                bw <= ~(instr_type == 3'b110 || instruction[15] == 1'b0);
                wb <= ~(instr_type == 3'b010 || instr_type == 3'b011);;
                state <= STATE_DATA_START;
              end
          endcase
        end
      STATE_DATA_START:
        begin
          // Based on addressing mode, the next few states will calculate
          // the effective address (ea) and grab the next word of data to
          // be processed into a source or temp register.
          ea_reg = is_src ? src_reg : dst_reg;
          ea_mod = is_src ? src_mod : dst_mod;

          temp <= registers[ea_reg] - (ea_mod[2:1] == 2'b10 ? 2 : 0);

          // Addressing modes 001 to 111 use the register as the address.
          // Modes 010 and 011 (Rn)+, @(Rn)+ increment the register.
          // Modes 100 and 101 -(Rn), @-(Rn) decrement the register.
          if (ea_mod[2:1] == 2'b01)
            registers[ea_reg] <= registers[ea_reg] + (bw == 1'b0 ? 2 : 1);
          else if (ea_mod[2:1] == 2'b10)
            registers[ea_reg] <= registers[ea_reg] - (bw == 1'b0 ? 2 : 1);

          if (ea_mod == 3'b000) begin
            mem_address <= 0;
            state <= STATE_DATA_END;
          end else begin
            if (ea_mod[2:1] == 2'b11)
              state <= STATE_FETCH_OFFSET_0;
            else
              state <= STATE_FETCH_FROM_EA_0;
          end
        end
      STATE_FETCH_OFFSET_0:
        begin
          // This is x(Rn) or @x(Rn).
          mem_bus_enable <= 1;
          mem_address <= registers[PC];
          registers[PC] <= registers[PC] + 2;
          state <= STATE_FETCH_OFFSET_1;
        end
      STATE_FETCH_OFFSET_1:
        begin
          mem_bus_enable <= 0;
          temp <= $signed(registers[ea_reg]) + $signed(mem_read);
          state <= STATE_FETCH_FROM_EA_0;
        end
      STATE_FETCH_FROM_EA_0:
        begin
          mem_bus_enable <= 1;
          mem_address <= temp;
          state <= STATE_FETCH_FROM_EA_1;
        end
      STATE_FETCH_FROM_EA_1:
        begin
          mem_bus_enable <= 0;
          temp <= mem_read;

          if (ea_mod == 3'b011 || ea_mod == 3'b101 || ea_mod == 3'b111 )
            state <= STATE_FETCH_INDIRECT_0;
          else
            state <= STATE_DATA_END;
        end
      STATE_FETCH_INDIRECT_0:
        begin
          mem_bus_enable <= 1;
          mem_address <= temp;
          state <= STATE_FETCH_INDIRECT_1;
        end
      STATE_FETCH_INDIRECT_1:
        begin
          mem_bus_enable <= 0;
          temp <= mem_read;
          state <= STATE_DATA_END;
        end
      STATE_FETCH_DATA_0:
        begin
          mem_bus_enable <= 1;
          mem_address <= temp;
          state <= STATE_FETCH_DATA_1;
        end
      STATE_FETCH_DATA_1:
        begin
            mem_bus_enable <= 0;

/*
            if (bw == 1) begin
              case (temp[0])
                0: temp <= { 8'h00, mem_read[7:0]  };
                1: temp <= { 8'h00, mem_read[15:8] };
              endcase
            end else begin
              temp <= mem_read;
            end
*/

            temp <= mem_read;

            state <= STATE_DATA_END;
        end
      STATE_DATA_END:
        begin
          if (is_src) begin
            is_src <= 0;

            if (bw == 1)
              if (mem_address[0] == 0)
                source <= { 8'h00, temp[7:0] };
              else
                source <= { 8'h00, temp[15:8] };
            else
              source <= temp;

            state <= STATE_DATA_START;
          end else begin
            if (bw == 1)
              if (mem_address[0] == 0)
                temp <= { 8'h00, temp[7:0] };
              else
                temp <= { 8'h00, temp[15:8] };

            ea <= mem_address;
            state <= next_state;
          end
        end
      STATE_ALU_SINGLE_000:
        begin
          if (instruction[7:6] == 2'b01) begin
            // jmp.
            registers[PC] <= ea;
            state <= STATE_FETCH_OP_0;
          end else begin
            // swab.
            result <= { temp[7:0], temp[15:8] };
            state <= STATE_WB_SINGLE_0;
          end
        end
      STATE_ALU_SINGLE_101:
        begin
          case (alu_op_1)
            OP_CLR: result <= 0;
            OP_COM: result <= ~temp;
            OP_INC: result <= temp + 1;
            OP_DEC: result <= temp - 1;
            OP_NEG: result <= -temp;
            OP_ADC: result <= temp + flag_c;
            OP_SBC: result <= temp - flag_c;
            OP_TST: result <= temp;
          endcase

          wb <= alu_op_1 != OP_TST;
          state <= STATE_WB_SINGLE_0;
        end
      STATE_ALU_SINGLE_110:
        begin
          if (alu_op_1[2] == 0) begin
            // OP_ROR = 3'b000;
            // OP_ROL = 3'b001;
            // OP_ASR = 3'b010;
            // OP_ASL = 3'b011;
            case (alu_op_1[1:0])
              2'b00:
                if (bw == 0)
                  result <= { temp[0], flag_c, temp[15:1] };
                else
                  result <= { temp[0], flag_c, temp[7:1] };
              2'b01:
                if (bw == 0)
                  result <= { temp[15:0], flag_c };
                else
                  result <= { temp[7:0], flag_c };
              2'b10:
                if (bw == 0)
                  begin
                    result[15:0] <= $signed(temp) >> 1;
                    result[16]   <= temp[0];
                  end
                else
                  begin
                    result[7:0]  <= $signed(temp[7:0]) >> 1;
                    result[8]    <= temp[0];
                    result[15:9] <= 0;
                  end
              2'b11:
                result <= temp << 1;
            endcase

            state <= STATE_WB_SINGLE_0;
          end else begin
            // OP_MARK = 3'b100;
            // OP_MTPS = 3'b100;
            // OP_MFPI = 3'b101;
            // OP_MFPD = 3'b101;
            // OP_MTPI = 3'b110;
            // OP_MTPD = 3'b110;
            // OP_SXT  = 3'b111;
            // OP_MFPS = 3'b111;
            bw <= 0;

            case (alu_op_1[1:0])
              2'b00:
                if (instruction[15] == 0) begin
                  // mark.
                  registers[SP] <= temp + { instruction[5:0], 0 };
                  state <= STATE_MARK_0;
                end else begin
                  // mtps.
                  psw <= temp;
                  state <= STATE_FETCH_OP_0;
                end
              2'b01:
                // mfpi.
                // mfpd.
                state <= STATE_PUSH_0;
              2'b10:
                // mtpi.
                // mtpd.
                state <= STATE_POP_0;
              2'b11:
                if (instruction[15] == 0) begin
                  // sxt.
                  if (flag_n)
                    result <= { 1'b0, 16'hffff };
                  else
                    result <= 0;

                  state <= STATE_WB_SINGLE_0;
                end else begin
                  // mfps.
                  result <= psw;
                  state <= STATE_WB_SINGLE_0;
                end
            endcase
          end
        end
      STATE_ALU_TWO:
        begin
          case (instr_type)
            OP_MOV: result <= source;
            OP_CMP: result <= temp - source;
            OP_BIT: result <= temp & source;
            OP_BIC: result <= temp & ~source;
            OP_BIS: result <= temp | source;
            OP_ADD:
              begin
                // add     0  110
                // sub     1  110
                if (instruction[15] == 1'b0)
                  result <= temp + source;
                else
                  result <= temp - source;
              end
          endcase

          //if (instr_type == OP_CMP || instr_type == OP_BIT) wb <= 0;

          state <= STATE_WB_SINGLE_0;
        end
      STATE_ALU_EIS:
        begin
          case (instr_subtype)
            //3'b000: // mul
            //3'b001: // div
            //3'b010: // ash
            //3'b011: // ashc
            3'b100: result <= temp ^ registers[src_reg];
          endcase

          state <= STATE_WB_SINGLE_0;
        end
      STATE_EXECUTE_SOB_0:
        begin
          //temp = registers[sob_reg] - 1;
          registers[sob_reg] <= temp;

          state <= STATE_EXECUTE_SOB_1;
        end
      STATE_EXECUTE_SOB_1:
        begin
          if (temp != 0) begin
            registers[PC] <= registers[PC] - { instruction[5:0], 1'b0 };
          end

          state <= STATE_FETCH_OP_0;
        end
      STATE_POP_0:
        begin
          mem_bus_enable <= 1;
          mem_address    <= registers[SP];
          state <= STATE_POP_1;
        end
      STATE_POP_1:
        begin
          mem_bus_enable <= 0;
          result <= mem_read;
          registers[SP] <= mem_address + 2;
          state <= STATE_WB_SINGLE_0;
        end
      STATE_WB_SINGLE_0:
        begin
          psw[FLAG_V] <= 0;

          if (bw == 0) begin
            psw[FLAG_C] <= result[16];
            psw[FLAG_N] <= result[15];
            psw[FLAG_Z] <= result[15:0] == 0;
          end else begin
            psw[FLAG_C] <= result[8];
            psw[FLAG_N] <= result[7];
            psw[FLAG_Z] <= result[7:0] == 0;
          end

          if (wb == 0) begin
            state <= STATE_FETCH_OP_0;
          end else begin
            if (ea_mod == 0) begin
              if (bw == 0)
                registers[ea_reg] <= result;
              else
                registers[ea_reg] <= { 8'b0, result[7:0] };

              state <= STATE_FETCH_OP_0;
            end else begin
              state <= STATE_DATA_STORE_0;
            end
          end
        end
      STATE_DATA_STORE_0:
        begin
          if (bw == 1)  begin
            case (mem_address[0])
              0:
                begin
                  mem_write      <= { 8'h00, result[7:0] };
                  mem_write_mask <= 2'b10;
                end
              1:
                begin
                  mem_write      <= { result[7:0], 8'h00 };
                  mem_write_mask <= 2'b01;
                end
            endcase
          end else begin
            mem_write      <= result;
            mem_write_mask <= 2'b00;
          end

          // NOTE: Is it bad to assume mem_address is already set to the ea?
          //mem_address <= ea;
          mem_write_enable <= 1;
          mem_bus_enable   <= 1;
          state <= STATE_DATA_STORE_1;
        end
      STATE_DATA_STORE_1:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;
          state <= STATE_FETCH_OP_0;
        end
      STATE_BRANCH:
        begin
          if (instruction[15] == 1'b0)
            case (branch_op)
              OP_BRANCH_BR:
                registers[PC] <= branch_address;
              OP_BRANCH_BNE:
                if (!flag_z) registers[PC] <= branch_address;
              OP_BRANCH_BEQ:
                if (flag_z)  registers[PC] <= branch_address;
              OP_BRANCH_BGE:
                if (!(flag_n ^ flag_v)) registers[PC] <= branch_address;
              OP_BRANCH_BLT:
                if ((flag_n ^ flag_v) == 1)
                  registers[PC] <= branch_address;
              OP_BRANCH_BGT:
                if ((flag_z | (flag_n ^ flag_v)) == 0)
                  registers[PC] <= branch_address;
              OP_BRANCH_BLE:
                if ((flag_z | (flag_n ^ flag_v)) == 1)
                  registers[PC] <= branch_address;
            endcase
          else
            case (branch_op)
              OP_BRANCH_BPL:
                if (!flag_n) registers[PC] <= branch_address;
              OP_BRANCH_BMI:
                if (flag_n)  registers[PC] <= branch_address;
              OP_BRANCH_BHI:
                if (!flag_c && !flag_z) registers[PC] <= branch_address;
              OP_BRANCH_BLOS:
                if (flag_c || flag_z) registers[PC] <= branch_address;
              OP_BRANCH_BVC:
                if (!flag_v) registers[PC] <= branch_address;
              OP_BRANCH_BVS:
                if (flag_v)  registers[PC] <= branch_address;
              OP_BRANCH_BCC:
                if (!flag_c) registers[PC] <= branch_address;
              OP_BRANCH_BCS:
                if (flag_c)  registers[PC] <= branch_address;
            endcase

          state <= STATE_FETCH_OP_0;
        end
      STATE_RETI_0:
        begin
          mem_bus_enable <= 1;
          mem_address    <= registers[SP];
          registers[SP]  <= registers[SP] + 2;
          state <= STATE_RETI_1;
        end
      STATE_RETI_1:
        begin
          mem_bus_enable <= 0;
          reti_state <= reti_state ^ 1;

          if (reti_state == 0) begin
            registers[PC] <= { mem_read[15:1], 1'b0 };
            state <= STATE_RETI_0;
          end else begin
            psw <= mem_read;
            state <= STATE_FETCH_OP_0;
          end
        end
      STATE_MARK_0:
        begin
          mem_bus_enable  <= 1;
          mem_address     <= registers[SP];

          registers[PC] <= registers[5];
          registers[SP] <= registers[SP] + 2;

          state <= STATE_MARK_1;
        end
      STATE_MARK_1:
        begin
          mem_bus_enable  <= 0;
          registers[5] <= mem_read;

          state <= STATE_FETCH_OP_0;
        end
      STATE_JSR:
        begin
          registers[src_reg] <= pc;
          temp <= registers[src_reg];
          registers[PC] <= ea;
          state <= STATE_PUSH_0;
        end
      STATE_PUSH_0:
        begin
          mem_bus_enable   <= 1;
          mem_address      <= registers[SP] -2;
          mem_write_enable <= 1;
          mem_write        <= temp;

          state <= STATE_PUSH_1;
        end
      STATE_PUSH_1:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;
          registers[SP] <= registers[SP] - 2;
          state <= STATE_FETCH_OP_0;
        end
      STATE_WAIT:
        begin
          state <= STATE_WAIT;
        end
      STATE_TRAP_0:
        begin
          // push psw
          mem_write        <= psw;
          mem_address      <= registers[SP] - 2;
          mem_write_enable <= 1;
          mem_bus_enable   <= 1;
          state <= STATE_TRAP_1;
        end
      STATE_TRAP_1:
        begin
          temp <= registers[SP];
          mem_bus_enable   <= 0;
          //mem_write_enable <= 0;
          state <= STATE_TRAP_2;
        end
      STATE_TRAP_2:
        begin
          // push pc
          mem_write        <= result;
          mem_address      <= registers[SP] - 4;
          mem_write_enable <= 1;
          mem_bus_enable   <= 1;
          state <= STATE_TRAP_3;
        end
      STATE_TRAP_3:
        begin
          registers[SP] <= temp - 4;
          mem_write_enable <= 0;
          mem_bus_enable   <= 0;
          state <= STATE_TRAP_4;
        end
      STATE_TRAP_4:
        begin
          // Load pc from vector.
          mem_address    <= new_pc;
          mem_bus_enable <= 1;
          state <= STATE_TRAP_5;
        end
      STATE_TRAP_5:
        begin
          registers[PC]  <= mem_read;
          mem_bus_enable <= 0;
          state <= STATE_TRAP_6;
        end
      STATE_TRAP_6:
        begin
          // Load psw from vector.
          mem_address    <= new_ps;
          mem_bus_enable <= 1;
          state <= STATE_TRAP_7;
        end
      STATE_TRAP_7:
        begin
          psw            <= mem_read;
          mem_bus_enable <= 0;
          state <= STATE_FETCH_OP_0;
        end
      STATE_ERROR:
        begin
          state <= STATE_ERROR;
        end
      STATE_HALTED:
        begin
          state <= STATE_HALTED;
        end
    endcase
end

memory_bus memory_bus_0(
  .address      (mem_address),
  .data_in      (mem_write),
  .write_mask   (mem_write_mask),
  .data_out     (mem_read),
  //.debug        (mem_debug),
  //.data_ready   (mem_data_ready),
  .bus_enable   (mem_bus_enable),
  .write_enable (mem_write_enable),
  .clk          (clk),
  .raw_clk      (raw_clk),
  .ioport_0     (ioport_0),
  .ioport_1     (ioport_1),
  .ioport_2     (ioport_2),
  .ioport_3     (ioport_3),
  .button_0     (button_0),
  .reset        (~button_reset),
  .spi_clk      (spi_clk),
  .spi_mosi     (spi_mosi),
  .spi_miso     (spi_miso)
);

endmodule

