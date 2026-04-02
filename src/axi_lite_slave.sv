`timescale 1ns / 1ps
module axi_lite_slave #(
parameter ADDR_WIDTH=32,
parameter DATA_WIDTH=32
)
(
input logic ACLK,
input logic ARESETn,
// read address declarations
input logic[ADDR_WIDTH-1:0] ARADDR,
input logic ARVALID,
output logic ARREADY,
//read the data declarations
output logic[DATA_WIDTH-1:0] RDATA,
output logic[1:0] RRESP,
output logic RVALID,
input logic RREADY,
//write address declarations
input logic[ADDR_WIDTH-1:0] AWADDR,
input logic AWVALID,
output logic AWREADY,
//write data declaration
input logic[DATA_WIDTH-1:0] WDATA,
input logic WVALID,
output logic WREADY,
//write response declaration
output logic[1:0] BRESP,
output logic BVALID,
input logic BREADY
);

logic [DATA_WIDTH-1:0] regfile [0:3];

typedef enum logic[0:0]{
READ_IDLE,
READ_DATA
} read_state_t;
read_state_t read_state,read_state_next;

typedef enum logic[1:0]{
WRITE_IDLE,
WRITE_EXEC,
WRITE_RESP
} write_state_t;
write_state_t write_state,write_state_next;

logic[ADDR_WIDTH-1:0] read_addr;
logic[ADDR_WIDTH-1:0] write_addr;
logic[DATA_WIDTH-1:0] write_data;
logic addr_received;
logic data_received;


    // Decode register index (word aligned)
    wire [1:0] read_index  = read_addr[3:2];
    wire [1:0] write_index = write_addr[3:2];


always_ff@(posedge ACLK or negedge ARESETn)
begin
if(!ARESETn)
begin
read_state<=READ_IDLE;
write_state<=WRITE_IDLE;
addr_received<=1'b0;
data_received<=1'b0;

            regfile[0] <= '0;
            regfile[1] <= '0;
            regfile[2] <= '0;
            regfile[3] <= '0;
            end
else begin
read_state<=read_state_next;
write_state<= write_state_next;

if(ARVALID && ARREADY)
read_addr <= ARADDR;

if(AWVALID && AWREADY) begin 
write_addr <= AWADDR;
addr_received<=1'b1;
end

if(WVALID && WREADY) 
begin
write_data<=WDATA;
data_received<=1'b1;
end
 if (write_state == WRITE_EXEC)
                regfile[write_index] <= write_data;

if(write_state==WRITE_RESP && BVALID && BREADY)
begin
addr_received <= 1'b0;
data_received <= 1'b0;
end
end
end
always_comb begin
ARREADY =1'b0;
RVALID=1'b0;
RDATA='0;
RRESP=2'b00;

read_state_next=read_state;
 case (read_state)
        READ_IDLE: begin
            ARREADY = 1'b1;
            if (ARVALID)
                read_state_next = READ_DATA;
        end

       READ_DATA: begin
                RVALID = 1'b1;
                RDATA  = regfile[read_index];
                if (RREADY)
                    read_state_next = READ_IDLE;
        end
    endcase
end
always_comb begin
    // defaults
    AWREADY = 1'b0;
    WREADY  = 1'b0;
    BVALID  = 1'b0;
    BRESP   = 2'b00; // OKAY

    write_state_next = write_state;

    case (write_state)
        WRITE_IDLE: begin
            AWREADY = 1'b1;
            WREADY  = 1'b1;
            if (addr_received && data_received)
                write_state_next = WRITE_EXEC;
        end

        WRITE_EXEC: begin
            write_state_next = WRITE_RESP;
        end

        WRITE_RESP: begin
            BVALID = 1'b1;
            if (BREADY)
                write_state_next = WRITE_IDLE;
        end
    endcase
end
endmodule
