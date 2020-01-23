`ifndef REGFILE_SB_SV
`define REGFILE_SB_SV

`include "constants_pkg.sv"
`include "regfile_trans.sv"

class regfile_sb;
    mailbox drv2scb;
    mailbox mon2scb;
    regfile_trans expected_trans;

    const int num_regs = 1 << REGISTER_ADDRESS_BITS;
    bit [REGISTER_DATA_BITS-1:0] register_values[1 << REGISTER_ADDRESS_BITS];

    function new(mailbox drv2scb, mailbox mon2scb);
        this.drv2scb = drv2scb;
        this.mon2scb = mon2scb;
//        this.expected_trans = new();

        for (int i = 0; i < num_regs; i++) begin
            register_values[i] = 'hEE;
        end

    endfunction

    task stop;
        $display("RF_SB [%0dns] TEST FINISHED", $time);
    endtask

    task receive_expected_instruction;
        forever begin
            drv2scb.get(expected_trans);

            case (expected_trans.action)
                regfile_trans::RESET: begin
                    $display("RF_SB [%0dns] Expecting a reset", $time);
                end
                regfile_trans::WRITE: begin
                    $display("RF_SB [%0dns] Write to register r%0d, value %02h", $time, expected_trans.register, expected_trans.value);
                end
            endcase
        end
    endtask

    function bit transactions_equal(regfile_trans t1, regfile_trans t2);
        transactions_equal = t1.action == t2.action &&
                             t1.register == t2.register &&
                             t1.value == t2.value;
    endfunction

    task receive_rf_transactions;
        regfile_trans trans;
        forever begin
            mon2scb.get(trans);

            if (!transactions_equal(trans, expected_trans)) begin
                $error("RF_SB [%0dns] Transaction mismatch. Expected (write reg:%0d val:%02h)  Register file received (write reg:%0d val:%02h)",
                    $time, expected_trans.register, expected_trans.value, trans.register, trans.value);
            end else begin
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
        end
    endtask : receive_rf_transactions

    task run;
        fork
            receive_expected_instruction();
            receive_rf_transactions();
        join_any
    endtask : run
endclass

`endif