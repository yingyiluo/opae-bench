//
// Copyright (c) 2017, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

`include "cci_mpf_if.vh"
`include "csr_mgr.vh"
`include "afu_json_info.vh"


module app_afu
   (
    input  logic clk,

    // Connection toward the host.  Reset comes in here.
    cci_mpf_if.to_fiu fiu,

    // CSR connections
    app_csrs.app csrs,

    // MPF tracks outstanding requests.  These will be true as long as
    // reads or unacknowledged writes are still in flight.
    input  logic c0NotEmpty,
    input  logic c1NotEmpty
    );

    // Local reset to reduce fan-out
    logic reset = 1'b1;
    always @(posedge clk)
    begin
        reset <= fiu.reset;
    end


    // ====================================================================
    //
    //  CSRs (simple connections to the external CSR management engine)
    //
    // ====================================================================

    always_comb
    begin
        // The AFU ID is a unique ID for a given program.  Here we generated
        // one with the "uuidgen" program and stored it in the AFU's JSON file.
        // ASE and synthesis setup scripts automatically invoke afu_json_mgr
        // to extract the UUID into afu_json_info.vh.
        csrs.afu_id = `AFU_ACCEL_UUID;

        // Default
        for (int i = 0; i < NUM_APP_CSRS; i = i + 1)
        begin
            csrs.cpu_rd_csrs[i].data = 64'(0);
        end
    end


    //
    // Consume configuration CSR writes
    //

    // We use CSR 0 to set the memory address.
    logic is_mem_addr_csr_write;
    assign is_mem_addr_csr_write = csrs.cpu_wr_csrs[0].en;

    // Memory address to which this AFU will write.
    t_ccip_clAddr mem_addr;

    always_ff @(posedge clk)
    begin
        if (is_mem_addr_csr_write)
        begin
            mem_addr <= t_ccip_clAddr'(csrs.cpu_wr_csrs[0].data);
        end
    end
   
    logic start = 1'b0;
    logic done = 1'b0;
	
    logic[31:0] x_dout = 32'h000000;
    logic[5:0] x_rd_addr = 6'b000000;
    logic[31:0] y_dout = 32'h000000;
    logic[5:0] y_rd_addr = 6'b000000;
    logic[31:0] z_din = 32'h0000000;
    logic[31:0] z_dout = 32'h000000;
    logic[5:0] z_rd_addr = 6'b000000;
    logic[5:0] z_wr_addr = 6'b000000;
    logic z_wr_en = 1'h0;

    Neural_top Neural_top_inst(
        .clock(clk),
	.reset(reset),
	.start(start),
	.done(done),
	.z_rd_addr(z_rd_addr),
	.z_dout(z_dout)
    );

//    always_ff @(posedge clk)
//    begin
//        if(reset)
//        begin
//            start = 1'b0;
//        end
//        start = 1'b1;
//    end

    // =========================================================================
    //
    //   Main AFU logic
    //
    // =========================================================================

    //
    // States in our simple example.
    //
    typedef enum logic [1:0]
    {
        STATE_IDLE,
        STATE_RUN,
        STATE_FINISH
    }
    t_state;

    t_state state;

    //
    // State machine
    //
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            state <= STATE_IDLE;
            start <= 1'b0;
        end
        else
        begin
          case(state)

            // Trigger the AFU when mem_addr is set above.  (When the CPU
            // tells us the address to which the FPGA should write a message.)
            STATE_IDLE:
            begin
                if (is_mem_addr_csr_write)
                begin
                    z_rd_addr <= 6'b0;
                    start <= 1'b1;
                    state <= STATE_RUN;
                    $display("AFU running...");
                end
            end

            // The AFU completes its task by writing a single line.  When
            // the line is written return to idle.  The write will happen
            // as long as the request channel is not full.
            STATE_RUN:
            begin
		z_rd_addr <= z_rd_addr + 6'b1;
		$display("z_dout: 0x%x, z_rd_addr: 0x%x", z_dout, z_rd_addr);
                if(done == 1'b1)
                begin
                    state <= STATE_FINISH;
                end
            end
   
            STATE_FINISH:
            begin
                if(!fiu.c1TxAlmFull)
                begin
                    state <= STATE_IDLE;
                    $display("AFU done..., out: 0x%x", z_dout);
                    $display("ccip data: 0x%x", t_ccip_clData'(z_dout));
                end
            end
          endcase
        end
    end

    // Write data back to indicate program finsih
    // Construct a memory write request header.  For this AFU it is always
    // the same, since we write to only one address.
    t_cci_mpf_c1_ReqMemHdr wr_hdr;
    assign wr_hdr = cci_mpf_c1_genReqHdr(eREQ_WRLINE_I,
                                         mem_addr,
                                         t_cci_mdata'(0),
                                         cci_mpf_defaultReqHdrParams());

    assign fiu.c1Tx.data = t_ccip_clData'({z_dout, 64'h1});

    // Control logic for memory writes
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            fiu.c1Tx.valid <= 1'b0;
        end
        else
        begin
            // Request the write as long as the channel isn't full.
            fiu.c1Tx.valid <= ((state == STATE_FINISH) && ! fiu.c1TxAlmFull);
        end

        fiu.c1Tx.hdr <= wr_hdr;
    end


    //
    // This AFU never makes a read request or handles MMIO reads.
    //
    assign fiu.c0Tx.valid = 1'b0;
    assign fiu.c2Tx.mmioRdValid = 1'b0;

endmodule // app_afu

