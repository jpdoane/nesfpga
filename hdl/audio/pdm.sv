
module pdm
#( parameter DEPTH = 8
)
(
  input logic clk,   
  input logic rst,
  input logic en,
  input logic [DEPTH-1:0] sample,
  output logic pdm
);

logic [DEPTH-1:0] sample_r;
logic [DEPTH-1:0] error;
logic signed [DEPTH:0] delta;
assign delta = error - sample_r;

wire _pdm = delta[DEPTH];

always_ff @(posedge clk) begin
    if (rst) begin
        error <= 0;
        sample_r <= 0;
    end else begin
        sample_r <= sample;
        // if delta>=0, error = delta
        // if delta<0, error = MAX + delta
        error <= delta[DEPTH-1:0] - delta[DEPTH];
    end
end

assign pdm = en ? _pdm : 0;

endmodule
