`timescale 1ns / 1ps

//`include "constants_pkg.sv"

import constants_pkg::*;

interface exec_unit_if(input bit clk);
    logic rd_en;
    logic [MEMORY_ADDRESS_BITS-1:0] rd_addr;
    logic [MEMORY_DATA_BITS-1:0] rd_data;
    logic wr_en;
    logic [MEMORY_ADDRESS_BITS-1:0] wr_addr;
    logic [MEMORY_DATA_BITS-1:0] wr_data;
    logic int_req;
    logic int_ack;

    modport memory(
        input rd_data,
        output rd_addr,
        output rd_en,
        output wr_addr,
        output wr_data,
        output wr_en);
endinterface

interface exec_unit_pc_if(
    input logic clk,
    input logic [MEMORY_ADDRESS_BITS-1:0] pc,
    input logic [31:0] timestamp_counter);
endinterface

typedef enum {
    OBS_DRIVER,
    OBS_MONITOR
} ObsOrigin;

class eu_observation;
    ObsOrigin org;
    int int_time;
    logic [MEMORY_ADDRESS_BITS-1:0] pc;
    bit [31:0] timestamp_counter;
endclass

class driver_command;
    rand int int_time;
    constraint c_int_time {
        int_time >= 10;
        int_time <= 20;
    };
endclass

typedef enum {
    DRV_IDLE,
    DRV_INT_REQUESTED,
    DRV_INT_INPROGRESS
} DriverState;

class tb_eu_driver;
    virtual exec_unit_if vif;
    event drv_done;
    mailbox drv_mbox;
    mailbox scb_mbox;
    int cycle_count;
    int next_int_time;
    DriverState state;

    task run();
        $display("[@%0t [tb_eu_driver] Starting...", $time);
        cycle_count = 0;
        next_int_time = 0;
        state = DRV_IDLE;
        vif.int_req <= 0;

        forever begin
            @(posedge vif.clk);
            cycle_count++;
            // $display("[tb_eu_driver] [@ %d] next_int_time:%d state: %s",
            //     cycle_count, next_int_time, state.name);
            case (state)
                DRV_IDLE: begin
                    driver_command cmd;
                    eu_observation transaction = new;

                    drv_mbox.get(cmd);
                    next_int_time = cycle_count + cmd.int_time;

                    transaction.org = OBS_DRIVER;
                    transaction.int_time = next_int_time;
                    scb_mbox.put(transaction);

                    state = DRV_INT_REQUESTED;
                end
                DRV_INT_REQUESTED: begin
                    if (next_int_time <= cycle_count) begin
                        $display("[@%h]INT_REQ set", cycle_count);
                        vif.int_req <= 1;
                        state = DRV_INT_INPROGRESS;
                    end
                end
                DRV_INT_INPROGRESS: begin
                    if (next_int_time + 5 < cycle_count) begin
                        // We've waited 5 cycles, time to clear the interrupt line
                        $display("[@%h]INT_REQ cleared", cycle_count);
                        vif.int_req <= 0;
                        state = DRV_IDLE;
                        @(posedge vif.clk) begin
                            -> drv_done;
                        end
                    end
                end
            endcase
        end
    endtask
endclass

class tb_eu_monitor;
    virtual exec_unit_if eu_vif;
    virtual exec_unit_pc_if eu_pc_vif;
    mailbox scb_mbox;  // connect mon -> scb

    task run();
        $display("T=%0t [Monitor] Starting.", $time);

        forever begin
            @(posedge eu_vif.clk) begin
                eu_observation transaction = new;
                transaction.org = OBS_MONITOR;
                transaction.pc = eu_pc_vif.pc;
                transaction.timestamp_counter = eu_pc_vif.timestamp_counter;
                scb_mbox.put(transaction);
            end
        end
    endtask
endclass

class tb_eu_scoreboard;
    mailbox scb_mbox;
    bit [31:0] latest_tsc;
    int expected_isr_enter_time;
    int expected_pc_after_isr;

    task run();
        latest_tsc = 0;
        forever begin
            eu_observation transaction;
            scb_mbox.get(transaction);
            case (transaction.org)
//                latest_tsc = transaction.timestamp_counter;

                OBS_MONITOR: begin
                    $display("T=%0t [Scoreboard] observed pc=%h tsc=%h",
                        $time,
                        transaction.pc,
                        transaction.timestamp_counter);
                end
                OBS_DRIVER: begin
                    $display("T=%0t [Scoreboard] observed int req @%h", $time, transaction.int_time);
                end
            endcase
        end
    endtask

endclass

class tb_eu_generator;
    event drv_done;
    mailbox drv_mbox;
    task run();
        driver_command cmd;
        int cnt = 5;
        // while (cnt > 0) begin
        //     cmd = new;
        //     if (cmd.randomize()) begin
        //         $display("New interrupt request @ %d", cmd.int_time);
        //         drv_mbox.put(cmd);
        //     end else begin
        //         $display("[tb_eu_generator::run()] Interrupt time randomization failed");
        //         $finish;
        //     end
        //     cnt--;
        // end
        -> drv_done;
    endtask
endclass

class eu_env;
    tb_eu_driver d0;
    tb_eu_monitor m0;
    tb_eu_generator g0;
    tb_eu_scoreboard s0;

    mailbox drv_mbox;  // connect gen -> drv
    mailbox scb_mbox;  // connect mon -> scb
    event drv_done;
    virtual exec_unit_if eu_vif;
    virtual exec_unit_pc_if eu_pc_vif;

    function new();
        d0 = new;
        m0 = new;
        g0 = new;
        s0 = new;

        drv_mbox = new();
        scb_mbox = new();

        d0.drv_mbox = drv_mbox;
        d0.scb_mbox = scb_mbox;
        g0.drv_mbox = drv_mbox;
        m0.scb_mbox = scb_mbox;
        s0.scb_mbox = scb_mbox;

        d0.drv_done = drv_done;
        g0.drv_done = drv_done;
    endfunction;

    virtual task run();
        d0.vif = eu_vif;
        m0.eu_vif = eu_vif;
        m0.eu_pc_vif = eu_pc_vif;

        fork
            d0.run();
            m0.run();
            g0.run();
            s0.run();
        join_any
    endtask

endclass

class eu_test;
    eu_env e0;

    function new();
        e0 = new;
    endfunction

    task run();
        e0.run();
    endtask
endclass


module tb_eu();

logic clk;
always begin
    #5 clk = ~clk;
end

logic reset_n;

logic [MEMORY_ADDRESS_BITS-1:0] wr_ram_addr;
logic [MEMORY_DATA_BITS-1:0] wr_ram_data;

exec_unit_if eu_if(clk);

exec_unit #(.DATA_BITS(8)) dut(
    .clk(clk),
    .reset_n(reset_n),

    .rd_ram_en(eu_if.rd_en),
    .rd_ram_addr(eu_if.rd_addr),
    .rd_ram_data(eu_if.rd_data),

    .wr_ram_en(eu_if.wr_en),
    .wr_ram_addr(eu_if.wr_addr),
    .wr_ram_data(eu_if.wr_data),
    .int_req(eu_if.int_req),
    .int_ack(eu_if.int_ack)
);

ram #(.ADDR_BITS(MEMORY_ADDRESS_BITS),
      .DATA_BITS(8),
      .memory_file("pwm.mem"))
memory(
    .clk(clk),
    .rd_en(eu_if.rd_en),
    .rd_addr(eu_if.rd_addr),
    .rd_data(eu_if.rd_data),

    .wr_en(eu_if.wr_en),
    .wr_addr(eu_if.wr_addr),
    .wr_data(eu_if.wr_data)
);

// rom #(.ADDR_BITS(MEMORY_ADDRESS_BITS),
//       .DATA_BITS(8),
//       .memory_file("pwm.mem"))
//     memory(.rd_en(eu_if.rd_en),
//            .rd_addr(eu_if.rd_addr),
//            .rd_data(eu_if.rd_data));


bind dut exec_unit_pc_if pc_if(
    .clk(clk),
    .pc(pc),
    .timestamp_counter(timestamp_counter)
);

eu_test t0;

initial begin
    // Initialize memory
    memory.memory['hff00] = {NOP, 4'b0};
    memory.memory['hff01] = 8'b0;
    memory.memory['hff02] = {RETI, 4'b0};
    memory.memory['hff03] = 8'b0;

    clk <= 0;
    reset_n <= 0;
    repeat (2) begin
        @(posedge clk);
    end
    eu_if.int_req <= 0;
    reset_n <= 1;

    t0 = new;
    t0.e0.eu_vif = eu_if;
    t0.e0.eu_pc_vif = dut.pc_if;
    t0.run();

    #40000 $finish;
end


endmodule
