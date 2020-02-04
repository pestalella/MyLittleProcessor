`ifndef REGFILE_SB_SV
`define REGFILE_SB_SV

`include "constants_pkg.sv"
`include "regfile_trans.sv"
`include "register_inspection_if.sv"


class regfile_sb;
    mailbox #(regfile_trans) drv2scb;
    mailbox mon2scb;
    virtual register_inspection_if vif;

    const int num_regs = 1 << REGISTER_ADDRESS_BITS;
    bit [REGISTER_DATA_BITS-1:0] register_values[1 << REGISTER_ADDRESS_BITS];

    bit alu_zero;
    bit [7:0] jump_dest;


    function new(mailbox #(regfile_trans) drv2scb, mailbox mon2scb, virtual register_inspection_if vif);
        this.drv2scb = drv2scb;
        this.mon2scb = mon2scb;
        this.vif = vif;

        this.alu_zero = 0;
        this.jump_dest = 0;

        for (int i = 0; i < num_regs; i++) begin
            register_values[i] = 'hEE;
        end

    endfunction

    task stop;
        $display("[%0dns] RF_SB TEST FINISHED", $time);
    endtask

    task receive_expected_instruction;
        regfile_trans trans;
        bit [7:0] arith_result;

        forever begin
            drv2scb.get(trans);

            case (trans.action)
                regfile_trans::RESET: begin
                    $display("[%0dns] RF_SB Expecting a reset", $time);
                    for (int i = 0; i < num_regs; i++) begin
                        register_values[i] = '0;
                    end
                end
                regfile_trans::WRITE: begin
                    $display("[%0dns] RF_SB Expect write to register r%0d, value %02h", $time,
                        trans.dest_reg, trans.value);

                    register_values[trans.dest_reg] = trans.value;
                end
                regfile_trans::ADD: begin
                    $display("[%0dns] RF_SB Expect add result write to register r%0d, value %02h", $time,
                        trans.dest_reg,
                        register_values[trans.a_reg] + register_values[trans.b_reg]);
                    arith_result =  register_values[trans.a_reg] + register_values[trans.b_reg];
                    this.alu_zero = (arith_result == '0);
                    register_values[trans.dest_reg] = arith_result;
                end
                regfile_trans::SUB: begin
                    $display("[%0dns] RF_SB Expect sub result write to register r%0d, value %02h", $time,
                        trans.dest_reg,
                        register_values[trans.a_reg] - register_values[trans.b_reg]);

                    arith_result =  register_values[trans.a_reg] - register_values[trans.b_reg];
                    this.alu_zero = (arith_result == '0);
                    register_values[trans.dest_reg] = arith_result;
                end
                regfile_trans::NOP: begin
                    $display("[%0dns] RF_SB Expect no changes to register file", $time);
                end
                regfile_trans::JUMP: begin
                    if (this.alu_zero) begin
                        this.jump_dest = trans.next_instr_address;
                        $display("[%0dns] RF_SB Expect jump not taken. Next PC should be @%02h",
                            $time, this.jump_dest);
                    end else begin
                        this.jump_dest = trans.jump_dest;
                        $display("[%0dns] RF_SB Expect a jump to @%02h", $time, this.jump_dest);
                    end
                end
                regfile_trans::CHECK_JUMP: begin
                    $display("[%0dns] Checking jump behavior:", $time);
                    if (this.jump_dest != trans.jump_dest)
                        $fatal(2, "[%0dns]     Wrong PC after JNZ instruction. PC:@%02h Expected:@%02h",
                            $time, trans.jump_dest, this.jump_dest);
                    else
                        $display("[%0dns]     Correct jump behavior", $time);
                end
            endcase
        end
    endtask

    function bit transactions_equal(regfile_trans t1, regfile_trans t2);
        transactions_equal = t1.action == t2.action &&
                             t1.dest_reg == t2.dest_reg &&
                             t1.a_reg == t2.a_reg &&
                             t1.b_reg == t2.b_reg &&
                             t1.value == t2.value;
    endfunction

    function void check_register_values();
        $display("  Actual: r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
            vif.r0, vif.r1, vif.r2, vif.r3, vif.r4, vif.r5, vif.r6, vif.r7);

        if ((register_values[0] != vif.r0) ||
            (register_values[1] != vif.r1) ||
            (register_values[2] != vif.r2) ||
            (register_values[3] != vif.r3) ||
            (register_values[4] != vif.r4) ||
            (register_values[5] != vif.r5) ||
            (register_values[6] != vif.r6) ||
            (register_values[7] != vif.r7)) begin

            $display("Expected: r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
                register_values[0], register_values[1], register_values[2],
                register_values[3], register_values[4], register_values[5],
                register_values[6], register_values[7]);
            $fatal(2, "REGISTER MISMATCH");
        end
    endfunction

    task receive_rf_transactions;
        regfile_trans trans;
        forever begin
            mon2scb.get(trans);
            case (trans.action)
                regfile_trans::RESET: begin
                    $display("[%0dns] RF_SB Reset. All registers set to 0x00", $time);
                end
                regfile_trans::WRITE: begin
                    $display("[%0dns] RF_SB Write to register r%0d, value %02h", $time, trans.dest_reg, trans.value);
                end
                regfile_trans::ADD: begin
                    $display("[%0dns] RF_SB Write addition to register r%0d =  r%0d+r%0d (%02h)", $time, trans.dest_reg,
                        trans.a_reg, trans.b_reg, register_values[trans.a_reg] + register_values[trans.b_reg]);
                end
                regfile_trans::SUB: begin
                    $display("[%0dns] RF_SB Write subtraction to register r%0d =  r%0d-r%0d (%02h)", $time, trans.dest_reg,
                        trans.a_reg, trans.b_reg, register_values[trans.a_reg] - register_values[trans.b_reg]);
                end
                regfile_trans::NOP: begin
                    $display("[%0dns] RF_SB NOP", $time);
//                        register_values[3] = 'hFF;
                end
            endcase
            @(posedge vif.clk)
                check_register_values();
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