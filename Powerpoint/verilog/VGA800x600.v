`include "VGADefines.vh"

module clockDivider(
    input clk,
    output one_hz_clk
);

    reg [27:0] counter;
    reg nuestroClock;


    always @(posedge clk /*or posedge rst*/) begin

        /*if(rst == 1'b1) begin
            counter <= 0;
            nuestroClock <= 0;
        end else begin*/

            counter <= counter + 1;
            if(counter == 100000000/2) // <- Should be compare to frequency
            begin
                counter <= 0;
                nuestroClock <= ~nuestroClock;		
            end
	
        //end
    end

    assign one_hz_clk = nuestroClock;


endmodule

module VGA800x600(
    input reset,
    input clk,
    input /*[1:0]*/nextIMG /* verilator public */,
    input previousIMG,
    output[2:0] red,
    output[2:0] green,
    output[1:0] blue,
    output hsync,
    output vsync
);
    
    reg [2:0]position; ///CONTROLADOR DE LA POSICIONES DE LAS IMAGENES
    reg [10:0] hcount /*verilator public*/;
    reg [10:0] vcount /*verilator public*/;
    reg hsync_buf;
    reg vsync_buf;
    reg[(`COLOR_BITS-1):0] rgb;

    reg [15:0] address;
    reg[15:0] addressP;
    wire [3:0] img_pixel;

    wire _reset;
    wire statesClock; //1 second clock to manage states
    wire vga_clk; //clock fpga
    assign _reset=reset;
    assign hsync = hsync_buf;
    assign vsync = vsync_buf;

    ImageRom rom(.address(addressP),.data(img_pixel));
    clockDivider stateDividerClock(clk, statesClock);
    
    assign {red,green,blue}={rgb[7:5],rgb[4:2],rgb[1:0]};


    /* MAQUINA DE ESTADO */

    parameter img1 = 2'd0;
    parameter img2 = 2'd1;
    parameter img3 = 2'd2;
    parameter img4 = 2'd3;

    reg [1:0] currentState /*verilator public*/;
    reg [1:0] nextState /*verilator public*/;

    always @(posedge statesClock /* reduced 1 second clock here */) begin
        if(reset)
            currentState <= img1;
        else
            currentState <= nextState;
    end

    always @(posedge vga_clk/*statesClock*/ /*reduced clock by 1 second para que no cambie de imagenes rapido */ ) begin

        case (currentState)

            img1: begin
                if(nextIMG)
                    nextState = img2;
                else if (previousIMG) 
                    nextState = img4;
                else
                    nextState = img1;
            end

            img2: begin
                if(nextIMG)
                    nextState = img3;
                else if (previousIMG)
                    nextState = img1;
                else
                    nextState = img2;
            end

            img3: begin
                if(nextIMG)
                    nextState = img4;
                else if (previousIMG)
                    nextState = img2;
                else
                    nextState = img3;
            end

            img4: begin
                if(nextIMG)
                    nextState = img1;
                else if (previousIMG)
                    nextState = img3;
                else
                    nextState = img4;
            end

            default: nextState = 2'bx;
        endcase

    end

    always @(posedge vga_clk /*statesClock*/ /*reduced clock 1 sec*/ ) begin

        
        case (currentState)

            img1: position = 3'd0;
            img2: position = 3'd1;
            img3: position = 3'd2;
            img4: position = 3'd3;
            default: position = 3'd0;
        endcase
    end
    

    DCM_SP #(.CLKFX_DIVIDE(5), .CLKFX_MULTIPLY(2), .CLKIN_PERIOD(10))
    vga_clock_dcm (.CLKIN(clk), .CLKFX(vga_clk), .CLKFB(0), .PSEN(0), .RST(0));
    
    always @ (posedge /*clk*/ vga_clk )begin ///activar clock fpga
        if (address >= `IMAGEN_PIXELS) begin
            address <= 16'd0;
        end
        if (_reset)
        begin
            hcount <= 11'h0;
            vcount <= 11'h0;
            vsync_buf <= 1'b0;
            hsync_buf <= 1'b0;
            address<=16'd0;
        end
        else begin
            if (hcount == `VGA_HLIMIT) begin
                hcount <= 0;
                
                if (vcount == `VGA_VLIMIT)
                    vcount <= 0;
                else
                    vcount <= vcount + 11'd1;
            end
            else
                hcount <= hcount + 11'd1;
                 
            if ((vcount >= `VGA_VSYNC_PULSE_START) && (vcount < `VGA_VSYNC_PULSE_END))
                vsync_buf <= 1;//0 //Vertical sync pulse (positive pulse)
            else
                vsync_buf <= 0;
                
            if ((hcount >= `VGA_HSYNC_PULSE_START) && (hcount < `VGA_HSYNC_PULSE_END))
                hsync_buf <= 1;//0 //Horizontal sync pulse (positive pulse)
            else
                hsync_buf <= 0;


            if ((hcount < `VGA_WIDTH) && (vcount < `VGA_HEIGHT))begin
                if(hcount>`POSITION_H && hcount<=(`POSITION_H+`IMAGE_WIDTH))begin

                    if(vcount>`POSITION_V && vcount<=(`POSITION_V+`IMAGE_HEIGHT))begin
                        address<=address+16'd1;
                        if(position==3'd0)begin
                           addressP<=(address+(16'd0*16'd15000));

                        end else if(position==3'd1)begin
                            addressP<=(address+(16'd1*16'd15000));

                        end else if(position==3'd2)begin
                            addressP<=(address+(16'd2*16'd15000));

                        end else if(position==3'd3)begin
                            addressP<=(address+(16'd3*16'd15000));
                        end 

                        /*if(hcount>(`POSITION_H) && hcount<=(`POSITION_H+`IMAGE_WIDTH+300) && (vcount == (`POSITION_V) || vcount == (`POSITION_V+`IMAGE_HEIGHT)))
				            rgb <= {3'b111, 3'b000, 2'b00};
			            else if ( (hcount == `POSITION_H || hcount == (`POSITION_H+`IMAGE_WIDTH+300)) && vcount >= `POSITION_V && vcount <= `POSITION_V+`IMAGE_HEIGHT)
				            rgb <= {3'b111, 3'b000, 2'b00};
			            else*/

                        rgb<={ {3{img_pixel[2]}}, {3{img_pixel[1]}}, {2{img_pixel[0]}} };
                    end else begin
                        rgb<=8'hff;
                    end

                end else 
                    rgb<=8'hff;

            end else begin
                rgb <=8'hff;
            end
        end
    end
 
endmodule