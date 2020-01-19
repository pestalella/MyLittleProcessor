`ifndef REGFILE_MON_SV
`define REGFILE_MON_SV

class regfile_mon;
    virtual regfile_if vif;
    mailbox mon2scb;

    function new (virtual regfile_if.rf_mon vif, mailbox mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run;
        forever begin
            @(posedge vif.clk or posedge vif.reset) begin
                if (vif.reset) begin
                    $display("RF_MONITOR [%0dns]: Reset triggered", $time);
                end else begin
                    if (vif.wr_enable) begin
                        $display("RF_MONITOR [%0dns]: Write to register r%0d, value %02h", $time, vif.wr_addr, vif.wr_data);
                    end
                end
            end
        end
    endtask
endclass

`endif