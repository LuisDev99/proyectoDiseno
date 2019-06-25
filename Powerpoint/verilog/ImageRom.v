module ImageRom(
    input [15:0] address,
    output reg [3:0] data
);
parameter SIZE = 60000;//15000 ;
reg [3:0] rom_content[0:(SIZE-1)];

always @ (address)
	data = rom_content[address];

initial begin
	$readmemh("/home/luis/Downloads/Powerpoint/Powerpoint/verilog/final.mif", rom_content, 0, (SIZE-1));
end
endmodule
