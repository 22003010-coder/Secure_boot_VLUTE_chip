`timescale 1ns / 1ps
// =============================================================================
// boot_controller.v
// Bo dieu khien trung tam cua he thong Secure Boot.
// - Dong bo start_boot va phat hien canh len.
// - Dieu khien firmware_reader, crc32_engine va crc_comparator.
// - Chi nha reset SoC khi CRC trung khop.
// =============================================================================
module boot_controller (
    input  wire clk,
    input  wire rst_n,
    input  wire start_boot,
    input  wire crc_done,
    input  wire compare_done,
    input  wire crc_match,

    output reg  reader_start,
    output reg  crc_start,
    output reg  compare_start,
    output reg  soc_reset_n,
    output wire boot_active,
    output wire boot_done
);

    localparam [1:0] ST_IDLE         = 2'd0;
    localparam [1:0] ST_WAIT_CRC     = 2'd1;
    localparam [1:0] ST_WAIT_COMPARE = 2'd2;
    localparam [1:0] ST_DONE         = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    // Hai tang dong bo cho tin hieu bat dong bo start_boot.
    (* ASYNC_REG = "TRUE" *) reg start_meta;
    (* ASYNC_REG = "TRUE" *) reg start_sync;
    reg start_sync_d;
    wire start_pulse;

    assign start_pulse = start_sync & ~start_sync_d;
    assign boot_active = (state == ST_WAIT_CRC) || (state == ST_WAIT_COMPARE);
    assign boot_done   = (state == ST_DONE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_meta   <= 1'b0;
            start_sync   <= 1'b0;
            start_sync_d <= 1'b0;
        end
        else begin
            start_meta   <= start_boot;
            start_sync   <= start_meta;
            start_sync_d <= start_sync;
        end
    end

    // Thanh ghi trang thai.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

    // Logic chuyen trang thai.
    always @(*) begin
        next_state = state;

        case (state)
            ST_IDLE: begin
                if (start_pulse)
                    next_state = ST_WAIT_CRC;
            end

            ST_WAIT_CRC: begin
                if (crc_done)
                    next_state = ST_WAIT_COMPARE;
            end

            ST_WAIT_COMPARE: begin
                if (compare_done)
                    next_state = ST_DONE;
            end

            ST_DONE: begin
                next_state = ST_DONE;
            end

            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // Cac xung dieu khien chi keo dai mot chu ky clock.
    always @(*) begin
        reader_start  = 1'b0;
        crc_start     = 1'b0;
        compare_start = 1'b0;

        if ((state == ST_IDLE) && start_pulse) begin
            reader_start = 1'b1;
            crc_start    = 1'b1;
        end

        if ((state == ST_WAIT_CRC) && crc_done)
            compare_start = 1'b1;
    end

    // Ngõ ra reset SoC duoc dang ky de tranh glitch.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            soc_reset_n <= 1'b0;
        end
        else begin
            if ((state == ST_WAIT_COMPARE) && compare_done)
                soc_reset_n <= crc_match;
            else if (state != ST_DONE)
                soc_reset_n <= 1'b0;
        end
    end

endmodule
