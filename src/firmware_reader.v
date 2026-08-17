`timescale 1ns / 1ps
// =============================================================================
// firmware_reader.v
// Doc firmware tu ROM theo thu tu dia chi 0 den FIRMWARE_SIZE-1.
// Giao tiep ROM theo co che mem_req / mem_rvalid.
// =============================================================================
module firmware_reader #(
    parameter integer FIRMWARE_SIZE = 16,
    parameter integer ADDR_WIDTH    = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,

    output reg                   mem_req,
    output reg  [ADDR_WIDTH-1:0] mem_addr,
    input  wire [7:0]            mem_rdata,
    input  wire                  mem_rvalid,

    output reg  [7:0]            data_out,
    output reg                   data_valid,
    output reg                   data_last
);

    localparam [ADDR_WIDTH-1:0] LAST_ADDR = FIRMWARE_SIZE - 1;

    reg [ADDR_WIDTH-1:0] addr_reg;
    reg                  request_pending;
    reg                  busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_req         <= 1'b0;
            mem_addr        <= {ADDR_WIDTH{1'b0}};
            data_out        <= 8'h00;
            data_valid      <= 1'b0;
            data_last       <= 1'b0;
            addr_reg        <= {ADDR_WIDTH{1'b0}};
            request_pending <= 1'b0;
            busy            <= 1'b0;
        end
        else begin
            // Cac tin hieu dang xung mac dinh ve 0 moi chu ky.
            mem_req    <= 1'b0;
            data_valid <= 1'b0;
            data_last  <= 1'b0;

            if (start && !busy) begin
                addr_reg        <= {ADDR_WIDTH{1'b0}};
                mem_addr        <= {ADDR_WIDTH{1'b0}};
                request_pending <= 1'b0;
                busy            <= 1'b1;
            end
            else if (busy) begin
                // Chi phat yeu cau moi khi yeu cau truoc da duoc phan hoi.
                if (!request_pending) begin
                    mem_req         <= 1'b1;
                    mem_addr        <= addr_reg;
                    request_pending <= 1'b1;
                end

                // Nhan du lieu tu ROM va chuyen sang CRC engine.
                if (request_pending && mem_rvalid) begin
                    data_out        <= mem_rdata;
                    data_valid      <= 1'b1;
                    request_pending <= 1'b0;

                    if (addr_reg == LAST_ADDR) begin
                        data_last <= 1'b1;
                        busy      <= 1'b0;
                    end
                    else begin
                        addr_reg <= addr_reg + 1'b1;
                    end
                end
            end
        end
    end

endmodule
