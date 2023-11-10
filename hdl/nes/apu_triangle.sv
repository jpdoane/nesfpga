`timescale 1ns/1ps

module apu_triangle
    (
    input  logic clk, rst,
    input qtrframe, halfframe,
    input en,
    input  logic [4:0] apu_addr,
    input  logic [7:0] data_in,
    input  logic apu_wr,
    output logic active,
    output logic [3:0] sample
    );


    logic [7:0] reg4008, reg400a, reg400b;
    logic reg4008wr, reg400awr, reg400bwr;

    always_ff @(posedge clk) begin
        reg4008wr <= 0;
        reg400awr <= 0;
        reg400bwr <= 0;
        if(rst) begin
            reg4008 <= 0;
            reg400a <= 0;
            reg400b <= 0;
        end else begin
            if(apu_wr) begin
                case(apu_addr)
                    5'h8: begin
                        reg4008 <= data_in;
                        reg4008wr <= 1;
                        end
                    5'ha: begin
                        reg400a <= data_in;
                        reg400awr <= 1;
                        end
                    5'hb: begin
                        reg400b <= data_in;
                        reg400bwr <= 1;
                        end
                    default: begin end
                endcase
            end
        end
    end

wire [10:0] timer_len = {reg400b[2:0], reg400a};
wire [4:0] length = reg400b[7:3];
wire length_halt = reg4008[7];

wire [6:0] linear_counter_reload = reg4008[6:0];
wire linear_ctrl_flag = reg4008[7];
logic linear_counter_reload_flag;
logic [6:0] linear_cnt;
wire linear_active = linear_cnt != 0;
always_ff @(posedge clk) begin
    if (rst) begin
        linear_counter_reload_flag <= 0;
        linear_cnt <= 0;
    end else begin
        if(reg400bwr) linear_counter_reload_flag <= 1;

        // When the frame counter generates a linear counter clock, the following actions occur in order:
        if(qtrframe) begin
            // If the linear counter reload flag is set, the linear counter is reloaded with the counter reload value, otherwise if the linear counter is non-zero, it is decremented.
            if(linear_counter_reload_flag || reg400bwr) linear_cnt <= linear_counter_reload;
            else if(linear_active) linear_cnt <= linear_cnt - 1;

            //If the control flag is clear, the linear counter reload flag is cleared.
            if(!linear_ctrl_flag) linear_counter_reload_flag <= 0;
        end
    end
end

// length counter  (coarse note duration)
apu_length u_apu_length(
    .clk       (clk       ),
    .rst       (rst       ),
    .halfframe (halfframe ),
    .en        (en        ),
    .halt      (length_halt      ),
    .update    (reg400bwr),
    .len       (length       ),
    .active    (active      )
);

wire active_both = active && linear_active;

// timer  (note pitch)
logic sync;
apu_divider #( .DEPTH(11) )u_apu_divider(
    .clk    (clk    ),
    .rst    (rst    ),
    .en     (active_both     ),
    .period (timer_len ),
    .reload (reg400bwr ),
    .sync   (sync   )
);

logic [3:0] count;
logic up;
always_ff @(posedge clk) begin
    if(rst) begin
        count <= 4'hf;
        up <= 0;
    end else begin

        count <= count;
        up <= up;

        if(active_both && sync) begin
            if (up) begin
                if (&count) up <= 0; // count == 15, ramp back down
                else count <= count + 1;
            end else begin
                if (|count) count <= count - 1;
                else up <= 1;  // count == 0, ramp back up
            end
        end
    end
end

assign sample = count;

endmodule