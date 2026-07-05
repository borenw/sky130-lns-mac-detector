// Leading-one detector + one fraction bit  (K=1 log2 converter front end).
// Parameterised width N so the same module serves the 5-bit inputs and the
// 11-bit Vth.  Combinational.
//   is_zero = 1                         when v == 0   (log2 undefined)
//   e       = floor(log2 v)             integer part
//   frac    = mantissa bit below the leading one  (the single K=1 helper bit)
// The K=1 log value is  L = 2*e + frac = {e, frac}  in half-log2 units.
`default_nettype none
module lod #(
    parameter N = 5
) (
    input  wire [N-1:0]            v,
    output reg  [$clog2(N)-1:0]    e,
    output reg                     frac,
    output reg                     is_zero
);
    integer i;
    reg found;
    always @* begin
        e       = {($clog2(N)){1'b0}};
        frac    = 1'b0;
        is_zero = 1'b1;
        found   = 1'b0;
        // priority scan from MSB: first set bit is the leading one
        for (i = N-1; i >= 0; i = i - 1) begin
            if (!found && v[i]) begin
                found   = 1'b1;
                is_zero = 1'b0;
                e       = i[$clog2(N)-1:0];
                frac    = (i > 0) ? v[(i > 0) ? (i-1) : 0] : 1'b0;
            end
        end
    end
endmodule
`default_nettype wire
