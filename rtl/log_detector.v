// Design 2 -- log / LNS spike detector, K=1 (no multipliers).
//   x = log2(A)+log2(B),  y = log2(C)+log2(D)      (K=1 converters)
//   s = max(x,y) + F(|x-y|)                          (LNS add)
//   spike = s > log2(Vth)                            (same K=1 converter on Vth)
// Same port list and same 2-cycle registered-I/O latency as mult_detector.
// Values carried in half-log2 units: L(v) = 2*floor(log2 v)+frac = {e,frac}.
`default_nettype none
module log_detector #(
    parameter WIDTH = 5,
    parameter K     = 1,      // fraction bits (this build: 1)
    parameter VW    = 11
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

    // ---- K=1 log converters (LOD + 1 fraction bit) ----
    wire [$clog2(WIDTH)-1:0] eA, eB, eC, eD;
    wire                     fA, fB, fC, fD, zA, zB, zC, zD;
    lod #(.N(WIDTH)) LA (.v(Ar), .e(eA), .frac(fA), .is_zero(zA));
    lod #(.N(WIDTH)) LB (.v(Br), .e(eB), .frac(fB), .is_zero(zB));
    lod #(.N(WIDTH)) LC (.v(Cr), .e(eC), .frac(fC), .is_zero(zC));
    lod #(.N(WIDTH)) LD (.v(Dr), .e(eD), .frac(fD), .is_zero(zD));

    wire [$clog2(VW)-1:0]    eV;
    wire                     fV, zV;
    lod #(.N(VW)) LV (.v(Vr), .e(eV), .frac(fV), .is_zero(zV));

    // L(v) = 2*e + frac = {e, frac}  (half-log2 units), zero-extended to 6 bits
    wire [5:0] La = {eA, fA};
    wire [5:0] Lb = {eB, fB};
    wire [5:0] Lc = {eC, fC};
    wire [5:0] Ld = {eD, fD};
    wire [5:0] Lv = {eV, fV};

    wire [5:0] X  = La + Lb;          // log2(A)+log2(B)
    wire [5:0] Y  = Lc + Ld;          // log2(C)+log2(D)
    wire       zx = zA | zB;          // A*B == 0
    wire       zy = zC | zD;          // C*D == 0

    // ---- LNS add: s = max(X,Y) + F(|X-Y|) ----
    wire [6:0] s;
    wire       s_zero;
    lns_add #(.LW(6)) ADD (.X(X), .Y(Y), .zx(zx), .zy(zy), .s(s), .s_zero(s_zero));

    // ---- log-domain comparison: spike = s > log2(Vth) ----
    reg spike_c;
    always @* begin
        if (zV)          spike_c = s_zero ? 1'b0 : 1'b1;   // Vth==0 -> spike=(S>0)
        else if (s_zero) spike_c = 1'b0;                   // S==0, Vth>0
        else             spike_c = (s > Lv) ? 1'b1 : 1'b0;
    end

    // ---- registered output ----
    always @(posedge clk) spike <= spike_c;
endmodule
`default_nettype wire
