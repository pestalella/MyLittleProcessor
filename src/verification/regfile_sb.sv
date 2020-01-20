`ifndef REGFILE_SB_SV
`define REGFILE_SB_SV

`include "constants_pkg.sv"
`include "regfile_trans.sv"

class regfile_sb;
    mailbox mon2scb;

    const int num_regs = 1 << REGISTER_ADDRESS_BITS;
    bit [REGISTER_DATA_BITS-1:0] register_values[1 << REGISTER_ADDRESS_BITS];

    function new(mailbox mon2scb);
        this.mon2scb = mon2scb;

        for (int i = 0; i < num_regs; i++) begin
            register_values[i] = 'hEE;
        end

    endfunction

    task run;
        regfile_trans trans;
        forever begin
            mon2scb.get(trans);

            case (trans.action)
                regfile_trans::RESET: begin
                    $display("RF_SB [%0dns] Reset. All registers set to 0x00", $time);
                    for (int i = 0; i < num_regs; i++) begin
                        register_values[i] = '0;
                    end
                end
                regfile_trans::WRITE: begin
                    $display("RF_SB [%0dns] Write to register r%0d, value %02h", $time, trans.register, trans.value);
                    register_values[trans.register] = trans.value;
                end
            endcase
        end
    endtask
endclass

`endif