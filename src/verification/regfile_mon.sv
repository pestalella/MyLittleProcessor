`ifndef REGFILE_MON_SV
`define REGFILE_MON_SV

`include "regfile_trans.sv"
`include "regfile_if.sv"

class regfile_mon;
    virtual regfile_if vif;
    mailbox mon2scb;

    function new (virtual regfile_if.rf_mon vif, mailbox mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task capture_resets;
        regfile_trans trans;
        forever begin
            @(posedge vif.reset) begin
                $display("RF_MONITOR [%0dns]: Reset triggered", $time);
                trans = new();
                trans.action = regfile_trans::RESET;
                mon2scb.put(trans);
            end
        end
    endtask

    task capture_writes;
        regfile_trans trans;
        forever begin
            @(posedge vif.wr_enable) begin
                $display("RF_MONITOR [%0dns]: Write to register r%0d, value %02h", $time, vif.wr_addr, vif.wr_data);
                trans = new();
                trans.action = regfile_trans::WRITE;
                trans.register = vif.wr_addr;
                trans.value = vif.wr_data;
                mon2scb.put(trans);
            end
        end
    endtask

    task run;
        fork
            capture_resets();
            capture_writes();
        join_any
    endtask
endclass

`endif