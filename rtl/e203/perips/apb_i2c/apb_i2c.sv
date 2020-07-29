// Copyright 2017 ETH Zurich and University of Bologna.
// -- Adaptable modifications made for hbirdv2 SoC. -- 
// Copyright 2020 Nuclei System Technology, Inc.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "i2c_master_defines.sv"

`define I2C_REG_CLK_PRESCALER 3'b000 //BASEADDR+0x00
`define I2C_REG_CTRL          3'b001 //BASEADDR+0x04
`define I2C_REG_RX            3'b010 //BASEADDR+0x08
`define I2C_REG_STATUS        3'b011 //BASEADDR+0x0C
`define I2C_REG_TX            3'b100 //BASEADDR+0x10
`define I2C_REG_CMD           3'b101 //BASEADDR+0x14

module apb_i2c
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,
    output logic                      interrupt_o,
    input  logic                      scl_pad_i,
    output logic                      scl_pad_o,
    output logic                      scl_padoen_o,
    input  logic                      sda_pad_i,
    output logic                      sda_pad_o,
    output logic                      sda_padoen_o
);

    //
    // variable declarations
    //

    logic  [3:0] s_apb_addr;

    // registers
    reg  [15:0] r_pre; // clock prescale register
    reg  [ 7:0] r_ctrl;  // control register
    reg  [ 7:0] r_tx;  // transmit register
    wire [ 7:0] s_rx;  // receive register
    reg  [ 7:0] r_cmd;   // command register
    wire [ 7:0] s_status;   // status register

    // done signal: command completed, clear command register
    wire s_done;

    // core enable signal
    wire s_core_en;
    wire s_ien;

    // status register signals
    wire s_irxack;
    reg  rxack;       // received aknowledge from slave
    reg  tip;         // transfer in progress
    reg  irq_flag;    // interrupt pending flag
    wire i2c_busy;    // bus busy (start signal detected)
    wire i2c_al;      // i2c bus arbitration lost
    reg  al;          // status register arbitration lost bit

    //
    // module body
    //

    assign s_apb_addr = PADDR[5:2];

    always_ff @ (posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            r_pre  <= 'h0;
            r_ctrl <= 'h0;
            r_tx   <= 'h0;
            r_cmd  <= 'h0;
        end
        else if (PSEL && PENABLE && PWRITE)
             begin
                if (s_done | i2c_al)
                      r_cmd[7:4] <= 4'h0;          // clear command bits when done
                                                   // or when aribitration lost
                r_cmd[2:1] <= 2'b0;                 // reserved bits
                r_cmd[0]   <= 1'b0;                 // clear IRQ_ACK bit
                case (s_apb_addr)
                    `I2C_REG_CLK_PRESCALER:
                        r_pre <= PWDATA[15:0];
                    `I2C_REG_CTRL:
                        r_ctrl <= PWDATA[7:0];
                    `I2C_REG_TX:
                        r_tx <= PWDATA[7:0];
                    `I2C_REG_CMD:
                    begin
                        if(s_core_en)
                            r_cmd <= PWDATA[7:0];
                    end
                endcase
            end
            else
            begin
                if (s_done | i2c_al)
                    r_cmd[7:4] <= 4'h0;           // clear command bits when done
                                                  // or when aribitration lost
                r_cmd[2:1] <= 2'b0;               // reserved bits
                r_cmd[0]   <= 1'b0;               // clear IRQ_ACK bit
            end
    end //always

    always_comb
    begin
        case (s_apb_addr)
            `I2C_REG_CLK_PRESCALER:
                PRDATA = {16'h0,r_pre};
            `I2C_REG_CTRL:
                PRDATA = {24'h0,r_ctrl};
            `I2C_REG_RX:
                PRDATA = {24'h0,s_rx};
            `I2C_REG_STATUS: 
                PRDATA = {24'h0,s_status};
            `I2C_REG_TX:    
                PRDATA = {24'h0,r_tx};
            `I2C_REG_CMD:
                PRDATA = {24'h0,r_cmd};
            default:
                PRDATA = 'h0;
        endcase
    end

    // decode command register
    wire sta  = r_cmd[7];
    wire sto  = r_cmd[6];
    wire rd   = r_cmd[5];
    wire wr   = r_cmd[4];
    wire ack  = r_cmd[3];
    wire iack = r_cmd[0];

    // decode control register
    assign s_core_en = r_ctrl[7];
    assign s_ien     = r_ctrl[6];

    // hookup byte controller block
    i2c_master_byte_ctrl byte_controller 
    (
            .clk      ( HCLK         ),
            .nReset   ( HRESETn      ),
            .ena      ( s_core_en    ),
            .clk_cnt  ( r_pre        ),
            .start    ( sta          ),
            .stop     ( sto          ),
            .read     ( rd           ),
            .write    ( wr           ),
            .ack_in   ( ack          ),
            .din      ( r_tx         ),
            .cmd_ack  ( s_done       ),
            .ack_out  ( s_irxack     ),
            .dout     ( s_rx         ),
            .i2c_busy ( i2c_busy     ),
            .i2c_al   ( i2c_al       ),
            .scl_i    ( scl_pad_i    ),
            .scl_o    ( scl_pad_o    ),
            .scl_oen  ( scl_padoen_o ),
            .sda_i    ( sda_pad_i    ),
            .sda_o    ( sda_pad_o    ),
            .sda_oen  ( sda_padoen_o )
    );

    // status register block + interrupt request signal
    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
        begin
            al       <= 1'b0;
            rxack    <= 1'b0;
            tip      <= 1'b0;
            irq_flag <= 1'b0;
        end
        else
        begin
            al       <= i2c_al | (al & ~sta);
            rxack    <= s_irxack;
            tip      <= (rd | wr);
            irq_flag <= (s_done | i2c_al | irq_flag) & ~iack; // interrupt request flag is always generated
        end
    end

    // generate interrupt request signals
    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
            interrupt_o <= 1'b0;
        else
            interrupt_o <= irq_flag && s_ien; // interrupt signal is only generated when IEN (interrupt enable bit is set)
    end
 
    // assign status register bits
    assign s_status[7]   = rxack;
    assign s_status[6]   = i2c_busy;
    assign s_status[5]   = al;
    assign s_status[4:2] = 3'h0; // reserved
    assign s_status[1]   = tip;
    assign s_status[0]   = irq_flag;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

endmodule
