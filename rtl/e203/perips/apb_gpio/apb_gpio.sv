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

`define REG_PADDIR      4'b0000 //BASEADDR+0x00
`define REG_PADIN       4'b0001 //BASEADDR+0x04
`define REG_PADOUT      4'b0010 //BASEADDR+0x08
`define REG_INTEN       4'b0011 //BASEADDR+0x0C
`define REG_INTTYPE0    4'b0100 //BASEADDR+0x10
`define REG_INTTYPE1    4'b0101 //BASEADDR+0x14
`define REG_INTSTATUS   4'b0110 //BASEADDR+0x18
`define REG_IOFCFG      4'b0111 //BASEADDR+0x1C

`define REG_PADCFG0     4'b1000 //BASEADDR+0x20
`define REG_PADCFG1     4'b1001 //BASEADDR+0x24
`define REG_PADCFG2     4'b1010 //BASEADDR+0x28
`define REG_PADCFG3     4'b1011 //BASEADDR+0x2C
`define REG_PADCFG4     4'b1100 //BASEADDR+0x30
`define REG_PADCFG5     4'b1101 //BASEADDR+0x34
`define REG_PADCFG6     4'b1110 //BASEADDR+0x38
`define REG_PADCFG7     4'b1111 //BASEADDR+0x3C

module apb_gpio
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

    input  logic               [31:0] gpio_in,
    output logic               [31:0] gpio_in_sync,
    output logic               [31:0] gpio_out,
    output logic               [31:0] gpio_dir,
    output logic      [31:0]    [5:0] gpio_padcfg,
    output logic               [31:0] gpio_iof,
    output logic                      interrupt
);

    logic [31:0] r_gpio_inten;
    logic [31:0] r_gpio_inttype0;
    logic [31:0] r_gpio_inttype1;
    logic [31:0] r_gpio_out;
    logic [31:0] r_gpio_dir;
    logic [31:0] r_gpio_sync0;
    logic [31:0] r_gpio_sync1;
    logic [31:0] r_gpio_in;
    logic [31:0] r_iofcfg;
    logic [31:0] s_gpio_rise;
    logic [31:0] s_gpio_fall;
    logic [31:0] s_is_int_rise;
    logic [31:0] s_is_int_fall;
    logic [31:0] s_is_int_lev0;
    logic [31:0] s_is_int_lev1;
    logic [31:0] s_is_int_all;
    logic        s_rise_int;

    logic  [3:0] s_apb_addr;

    logic [31:0] r_status;

    assign s_apb_addr = PADDR[5:2];

    assign gpio_in_sync = r_gpio_sync1;

    assign s_gpio_rise = r_gpio_sync1 & ~r_gpio_in; //foreach input check if rising edge
    assign s_gpio_fall = ~r_gpio_sync1 & r_gpio_in; //foreach input check if falling edge

    assign s_is_int_rise =  r_gpio_inttype1 & ~r_gpio_inttype0 & s_gpio_rise; // inttype 01 rise
    assign s_is_int_fall =  r_gpio_inttype1 &  r_gpio_inttype0 & s_gpio_fall; // inttype 00 fall
    assign s_is_int_lev0 = ~r_gpio_inttype1 &  r_gpio_inttype0 & ~r_gpio_in;  // inttype 10 level 0
    assign s_is_int_lev1 = ~r_gpio_inttype1 & ~r_gpio_inttype0 &  r_gpio_in;  // inttype 11 level 1

    //check if bit if interrupt is enable and if interrupt specified by inttype occurred
    assign s_is_int_all  = r_gpio_inten & (s_is_int_rise | s_is_int_fall | s_is_int_lev0 | s_is_int_lev1);

    //is any bit enabled and specified interrupt happened?
    assign s_rise_int = |s_is_int_all;

    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            interrupt <= 1'b0;
            r_status  <=  'h0;
        end
        else
            if (!interrupt && s_rise_int ) //rise interrupt if not already rise
            begin
                interrupt <= 1'b1;
                r_status  <= s_is_int_all;
            end
            else if (interrupt && PSEL && PENABLE && !PWRITE && (s_apb_addr == `REG_INTSTATUS)) //clears int if status is read
                 begin
                    interrupt <= 1'b0;
                    r_status  <=  'h0;
                 end
    end

    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            r_gpio_sync0    <= 'h0;
            r_gpio_sync1    <= 'h0;
            r_gpio_in       <= 'h0;
        end
        else 
        begin
            r_gpio_sync0    <= gpio_in;      //first 2 sync for metastability resolving
            r_gpio_sync1    <= r_gpio_sync0;
            r_gpio_in       <= r_gpio_sync1; //last reg used for edge detection
        end
    end //always

    always_ff @(posedge HCLK, negedge HRESETn) 
    begin
        if(~HRESETn) 
        begin
            r_gpio_inten    <=  '0;
            r_gpio_inttype0 <=  '0;
            r_gpio_inttype1 <=  '0;
            r_gpio_out      <=  '0;
            r_gpio_dir      <=  '0;
            r_iofcfg        <=  '0;
            for (int i=0;i<32;i++)
                gpio_padcfg[i]  <=  6'b000010; // DS=high, PE=disabled
        end
        else
        begin
            if (PSEL && PENABLE && PWRITE)
            begin
                case (s_apb_addr)
                `REG_PADDIR:
                    r_gpio_dir      <= PWDATA;
                `REG_PADOUT:
                    r_gpio_out      <= PWDATA;
                `REG_INTEN:
                    r_gpio_inten    <= PWDATA;
                `REG_INTTYPE0:
                    r_gpio_inttype0 <= PWDATA;
                `REG_INTTYPE1:
                    r_gpio_inttype1 <= PWDATA;
                `REG_IOFCFG:
                    r_iofcfg        <= PWDATA;
                `REG_PADCFG0:
                begin
                    gpio_padcfg[0]  <= PWDATA[5:0]  ;
                    gpio_padcfg[1]  <= PWDATA[13:8] ;
                    gpio_padcfg[2]  <= PWDATA[21:16];
                    gpio_padcfg[3]  <= PWDATA[29:24];
                end
                `REG_PADCFG1:
                begin
                    gpio_padcfg[4]  <= PWDATA[5:0]  ;
                    gpio_padcfg[5]  <= PWDATA[13:8] ;
                    gpio_padcfg[6]  <= PWDATA[21:16];
                    gpio_padcfg[7]  <= PWDATA[29:24];
                end
                `REG_PADCFG2:
                begin
                    gpio_padcfg[8]  <= PWDATA[5:0]  ;
                    gpio_padcfg[9]  <= PWDATA[13:8] ;
                    gpio_padcfg[10] <= PWDATA[21:16];
                    gpio_padcfg[11] <= PWDATA[29:24];
                end
                `REG_PADCFG3:
                begin
                    gpio_padcfg[12] <= PWDATA[5:0]  ;
                    gpio_padcfg[13] <= PWDATA[13:8] ;
                    gpio_padcfg[14] <= PWDATA[21:16];
                    gpio_padcfg[15] <= PWDATA[29:24];
                end
                `REG_PADCFG4:
                begin
                    gpio_padcfg[16] <= PWDATA[5:0]  ;
                    gpio_padcfg[17] <= PWDATA[13:8] ;
                    gpio_padcfg[18] <= PWDATA[21:16];
                    gpio_padcfg[19] <= PWDATA[29:24];
                end
                `REG_PADCFG5:
                begin
                    gpio_padcfg[20] <= PWDATA[5:0]  ;
                    gpio_padcfg[21] <= PWDATA[13:8] ;
                    gpio_padcfg[22] <= PWDATA[21:16];
                    gpio_padcfg[23] <= PWDATA[29:24];
                end
                `REG_PADCFG6:
                begin
                    gpio_padcfg[24] <= PWDATA[5:0]  ;
                    gpio_padcfg[25] <= PWDATA[13:8] ;
                    gpio_padcfg[26] <= PWDATA[21:16];
                    gpio_padcfg[27] <= PWDATA[29:24];
                end
                `REG_PADCFG7:
                begin
                    gpio_padcfg[28]  <= PWDATA[5:0]  ;
                    gpio_padcfg[29]  <= PWDATA[13:8] ;
                    gpio_padcfg[30]  <= PWDATA[21:16];
                    gpio_padcfg[31]  <= PWDATA[29:24];
                end
                endcase
            end
        end
    end //always

    always_comb
    begin
        case (s_apb_addr)
        `REG_PADDIR:
            PRDATA = r_gpio_dir;
        `REG_PADIN:
            PRDATA = r_gpio_in;
        `REG_PADOUT:
            PRDATA = r_gpio_out;
        `REG_INTEN:
            PRDATA = r_gpio_inten;
        `REG_INTTYPE0:
            PRDATA = r_gpio_inttype0;
        `REG_INTTYPE1:
            PRDATA = r_gpio_inttype1;
        `REG_INTSTATUS:
            PRDATA = r_status;
        `REG_IOFCFG:
            PRDATA = r_iofcfg;
        `REG_PADCFG0:
            PRDATA = {2'b00,gpio_padcfg[3],2'b00,gpio_padcfg[2],2'b00,gpio_padcfg[1],2'b00,gpio_padcfg[0]};
        `REG_PADCFG1:
            PRDATA = {2'b00,gpio_padcfg[7],2'b00,gpio_padcfg[6],2'b00,gpio_padcfg[5],2'b00,gpio_padcfg[4]};
        `REG_PADCFG2:
            PRDATA = {2'b00,gpio_padcfg[11],2'b00,gpio_padcfg[10],2'b00,gpio_padcfg[9],2'b00,gpio_padcfg[8]};
        `REG_PADCFG3:
            PRDATA = {2'b00,gpio_padcfg[15],2'b00,gpio_padcfg[14],2'b00,gpio_padcfg[13],2'b00,gpio_padcfg[12]};
        `REG_PADCFG4:
            PRDATA = {2'b00,gpio_padcfg[19],2'b00,gpio_padcfg[18],2'b00,gpio_padcfg[17],2'b00,gpio_padcfg[16]};
        `REG_PADCFG5:
            PRDATA = {2'b00,gpio_padcfg[23],2'b00,gpio_padcfg[22],2'b00,gpio_padcfg[21],2'b00,gpio_padcfg[20]};
        `REG_PADCFG6:
            PRDATA = {2'b00,gpio_padcfg[27],2'b00,gpio_padcfg[26],2'b00,gpio_padcfg[25],2'b00,gpio_padcfg[24]};
        `REG_PADCFG7:
            PRDATA = {2'b00,gpio_padcfg[31],2'b00,gpio_padcfg[30],2'b00,gpio_padcfg[29],2'b00,gpio_padcfg[28]};
        default:
            PRDATA = 'h0;
        endcase
    end

    assign gpio_iof = r_iofcfg;

    assign gpio_out = r_gpio_out;
    assign gpio_dir = r_gpio_dir;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

endmodule

