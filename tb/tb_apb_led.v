module tb_apb_led;

    reg clk = 0;
    reg rst_n = 0;
    reg [31:0] paddr;
    reg [31:0] pwdata;
    reg psel;
    reg penable;
    reg pwrite;
    wire [31:0] prdata;
    wire led;

    // Instantiate the LED module
    apb_led uut (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr),
        .pwdata(pwdata),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .prdata(prdata),
        .led(led)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        // Dump signals to VCD for GTKWave
    $dumpfile("apb_led.vcd"); 
    $dumpvars(0, tb_apb_led);

        // Reset
        rst_n = 0; psel=0; penable=0; pwrite=0; pwdata=0; paddr=0;
        #20;
        rst_n = 1;

        // Write 1 to LED
        paddr = 32'h4000_0000;  // address for LED
        pwdata = 32'h1;
        psel = 1; penable = 1; pwrite = 1;
        #10;
        psel = 0; penable = 0; pwrite = 0;

        // Wait and write 0 to LED
        #10;
        paddr = 32'h4000_0000;
        pwdata = 32'h0;
        psel = 1; penable = 1; pwrite = 1;
        #10;
        psel = 0; penable = 0; pwrite = 0;

        // Finish simulation
        #20;
        $finish;
    end

endmodule