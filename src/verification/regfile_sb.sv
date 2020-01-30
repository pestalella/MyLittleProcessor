`ifndef REGFILE_SB_SV
`define REGFILE_SB_SV

`include "constants_pkg.sv"
`include "regfile_trans.sv"
`include "register_inspection_if.sv"


class regfile_sb;
    mailbox drv2scb;
    mailbox mon2scb;
    virtual register_inspection_if vif;
    regfile_trans expected_trans;


    const int num_regs = 1 << REGISTER_ADDRESS_BITS;
    bit [REGISTER_DATA_BITS-1:0] register_values[1 << REGISTER_ADDRESS_BITS];

    function new(mailbox drv2scb, mailbox mon2scb, virtual register_inspection_if vif);
        this.drv2scb = drv2scb;
        this.mon2scb = mon2scb;
        this.vif = vif;

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
                regfile_trans::NOP: begin
                    $display("RF_SB [%0dns] Expect no changes to register file", $time);
                end
            endcase
        end
    endtask

    function bit transactions_equal(regfile_trans t1, regfile_trans t2);
        transactions_equal = t1.action == t2.action &&
                             t1.register == t2.register &&
                             t1.value == t2.value;
    endfunction

    function void check_register_values();
        if ((register_values[0] != vif.r0) ||
            (register_values[1] != vif.r1) ||
            (register_values[2] != vif.r2) ||
            (register_values[3] != vif.r3) ||
            (register_values[4] != vif.r4) ||
            (register_values[5] != vif.r5) ||
            (register_values[6] != vif.r6) ||
            (register_values[7] != vif.r7)) begin

            $display("REGISTER MISMATCH");
            $display("Expected: r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
                register_values[0], register_values[1], register_values[2],
                register_values[3], register_values[4], register_values[5],
                register_values[6], register_values[7]);
            $fatal(2, "  Actual: r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
                vif.r0, vif.r1, vif.r2, vif.r3, vif.r4, vif.r5, vif.r6, vif.r7);
        end
    endfunction

    task receive_rf_transactions;
        regfile_trans trans;
        forever begin
            mon2scb.get(trans);

            if (!transactions_equal(trans, expected_trans)) begin
                $error("RF_SB [%0dns] Transaction mismatch. Expected (action:%s reg:%0d val:%02h)  Register file received (action:%s reg:%0d val:%02h)",
                    $time, expected_trans.action.name, expected_trans.register, expected_trans.value, trans.action.name, trans.register, trans.value);
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
                    regfile_trans::NOP: begin
                        $display("RF_SB [%0dns] NOP", $time);
//                        register_values[3] = 'hFF;
                    end
                endcase
                @(posedge vif.clk)
                    check_register_values();
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