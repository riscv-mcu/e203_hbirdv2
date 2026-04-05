// File: rtl/perips/apb_led.v
// APB-controlled single LED peripheral

module apb_led(
    input  wire        clk,      // system clock
    input  wire        rst_n,    // active-low reset
    input  wire [31:0] paddr,    // APB address
    input  wire [31:0] pwdata,   // APB write data
    input  wire        psel,     // APB select
    input  wire        penable,  // APB enable
    input  wire        pwrite,   // APB write flag
    output reg  [31:0] prdata,   // APB read data
    output reg         led       // LED output
);

    // APB write: only write when selected, enabled, and writing
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            led <= 1'b0;  // LED off at reset
        else if(psel && penable && pwrite)
            led <= pwdata[0]; // Use bit 0 of write data
    end

    // APB read: return LED status in bit 0
    always @(*) begin
        prdata = 32'b0;
        if(psel && !pwrite) prdata[0] = led;
    end

endmodule