// Design 1 -- baseline exact multiplier spike detector.
//   spike = (A*B + C*D) > Vth        (exact integer math, the reference)
// Registered inputs and registered output -> 2-cycle latency.
`default_nettype none
module mult_detector #(
    parameter WIDTH = 12,     // input width  (0..4095)
    parameter VW    = 25      // Vth width    (0..33554431, covers max S=33538050)
) (
    input  wire             clk,
    input  wire [WIDTH-1:0] A, B, C, D,
    input  wire [VW-1:0]    Vth,
    output reg              spike
);
    // ---- registered inputs ----
    reg [WIDTH-1:0] Ar, Br, Cr, Dr;
    reg [VW-1:0]    Vr;
    always @(posedge clk) begin
        Ar <= A; Br <= B; Cr <= C; Dr <= D; Vr <= Vth;
    end

    // ---- exact datapath ----
    wire [2*WIDTH-1:0] p1 = Ar * Br;          // A*B
    wire [2*WIDTH-1:0] p2 = Cr * Dr;          // C*D
    wire [2*WIDTH:0]   S  = p1 + p2;          // A*B + C*D  (11 bits)
    wire               spike_c = (S > Vr);

    // ---- registered output ----
    always @(posedge clk) spike <= spike_c;
endmodule
`default_nettype wire
