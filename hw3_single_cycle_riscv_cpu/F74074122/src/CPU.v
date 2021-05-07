module CPU(
    input             clk,
    input             rst,
    input      [31:0] data_out,//data_out represents the data send from DM
    input      [31:0] instr_out,//represents the instruction send from IM .
    output reg        instr_read,//instr_read represents the signal whether the instruction should be read in IM.
    output reg        data_read,//data_read represents the signal whether the data should be read in DM.
    output reg [31:0] instr_addr,//instr_addr represents the instruction address in IM.
    output reg [31:0] data_addr,//data_addr represents the data address in DM.
    output reg [3:0]  data_write,//data_write has four signal , and every signal represents the byte of the data whether should be wrote in DM.
    output reg [31:0] data_in//data_in represents the data which will be wrote into DM . sw
);
wire [2:0]funct3;
wire [6:0]funct7;
wire [5:0]rd,rs1,rs2;
wire signed [11:0]imm_i,imm_s;
wire signed [12:0]imm_b;
wire signed [19:0]imm_u;
wire signed [20:0]imm_j;
wire [6:0]opcode;
integer i;
//r-type
assign opcode = instr_out[6:0];
assign rd = instr_out[11:7];
assign funct3 = instr_out[14:12];
assign rs1 = instr_out[19:15];
assign rs2 = instr_out[24:20];
assign funct7 = instr_out[31:25];

assign imm_i = $signed(instr_out[31:20]);
assign imm_s = $signed({instr_out[31:25],instr_out[11:7]});
assign imm_b = $signed({instr_out[31],instr_out[7],instr_out[30:25],instr_out[11:8],1'b0});
assign imm_u = $signed(instr_out[31:12]);
assign imm_j = $signed({instr_out[31], instr_out[19:12], instr_out[20], instr_out[30:21], 1'b0});


reg signed [31:0]singextend;
reg signed [31:0]registers[0:31];
reg [5:0]rd_record;
reg [2:0]data_lw;

always@(negedge clk)
begin
  if(rst)
  begin
    instr_addr = 32'h0;
    data_read = 0;
    data_write = 0;
    instr_read = 1;
  end
  else
  begin
  registers[0] = 0;
  data_write = 0;
    if(data_read)//read data (lw)
    begin
      case(data_lw)
      3'b000://lw
        registers[rd_record] = $signed(data_out); 
      3'b001://lb
      begin
        registers[rd_record] = $unsigned(data_out[7:0]);
        for(i = 31; i >7; i = i - 1)
        begin
          registers[rd_record][i] = data_out[7];
        end
      end
      3'b010://lh
      begin
        registers[rd_record] = $unsigned(data_out[15:0]);
        for(i = 31; i >15; i = i - 1)
        begin
          registers[rd_record][i] = data_out[15];
        end
      end
      3'b011://lbu
        registers[rd_record] = $unsigned(data_out[7:0]);
      default://lhu
        registers[rd_record] = $unsigned(data_out[15:0]);
      endcase
      data_read = 0;
    end
    if(opcode == 7'b0110011)//opcode R-type
    begin
      case(funct7)//func7
        7'b0000000:
        begin
    case(funct3)//func3
            3'b000://ADD
            begin
              registers[rd] = registers[rs1] + registers[rs2];
            end
            3'b001://SLL
            begin
              registers[rd] = $unsigned(registers[rs1])<<$unsigned(registers[rs2][4:0]);
            end
      3'b010://SLT
      begin
        registers[rd] = (registers[rs1]<registers[rs2])?1:0;
      end
      3'b011://SLTU
      begin
        registers[rd] = ($unsigned(registers[rs1])<$unsigned(registers[rs2]))?1:0;
      end
      3'b100://XOR
      begin
        registers[rd] = registers[rs1]^registers[rs2];
      end
      3'b101://SRL
      begin
        registers[rd] = registers[rs1] >> registers[rs2][4:0];
      end
      3'b110://OR
      begin
        registers[rd] = registers[rs1]|registers[rs2];
      end
      3'b111://AND
      begin
        registers[rd] = registers[rs1]&registers[rs2];
      end
          endcase
        end
        default:
        begin
          case(funct3)//func3
      3'b000://SUB
      begin
        registers[rd] = registers[rs1] - registers[rs2];
      end
      default://SRA
      begin
        registers[rd] = $signed(registers[rs1])>>> registers[rs2][4:0];
      end
    endcase
        end
      endcase
      instr_addr = instr_addr + 4;//PC = PC + 4
    end//opcode R-type end
    else if(opcode == 7'b0000011)//opcode I-type'0000011'
    begin
      case(funct3)//func3
        3'b000://LB
        begin
      data_addr = registers[rs1] + imm_i;
        data_read = 1;
    data_lw = 1;
        end
        3'b001://LH
        begin
      data_addr = registers[rs1] + imm_i;
        data_read = 1;
    data_lw = 2;
        end
        3'b010://LW
        begin
      data_addr = registers[rs1] + imm_i;
        data_read = 1;
    data_lw = 0;
        end
        3'b100://LBU
        begin
      data_addr = registers[rs1] + imm_i;
        data_read = 1;
    data_lw = 3;
        end
        default://LHU
        begin
      data_addr = registers[rs1] + imm_i;
        data_read = 1;
    data_lw = 4;
        end
      endcase//func3 end
      rd_record = rd;
      instr_addr = instr_addr + 4;
    end//opcode I-type'0000011' end
    else if(opcode == 7'b0010011)//opcode I-type'0010011'
    begin
      singextend = $signed(imm_i);
      case(funct3)//func3
        3'b000://ADDI
        begin
          registers[rd] = registers[rs1] + singextend;
        end
        3'b001://SLLI
        begin
          registers[rd] = $unsigned(registers[rs1]) << $unsigned(singextend[4:0]);
        end
        3'b010://SLTI
        begin
          registers[rd] = (registers[rs1]<singextend)?1:0;
        end
        3'b011://SLTIU
        begin
          registers[rd] = ($unsigned(registers[rs1])<$unsigned(singextend))?1:0;
        end
        3'b100://XORI
        begin
          registers[rd] = registers[rs1] ^ singextend;
        end
        3'b101://SRLI or SRAI
        begin
          if(imm_i[11:5] == 7'b0000000)//SRLI
    begin
      registers[rd] = $unsigned(registers[rs1]) >> $unsigned(singextend[4:0]);
    end
    else if(imm_i[11:5] == 7'b0100000)//SRAI
    begin
      registers[rd] = registers[rs1] >>> $unsigned(singextend[4:0]);
    end
        end
        3'b110://ORI
        begin
          registers[rd] = registers[rs1] | singextend;
        end
        3'b111://ANDI
        begin
          registers[rd] = registers[rs1] & singextend;
        end
      endcase//func3 end
      instr_addr = instr_addr + 4;
    end//opcode I-type'0010011' end
    else if(opcode == 7'b1100111)//opcode I-type'1100111'
    begin
      //JALR
      singextend = registers[rs1];
      registers[rd] = instr_addr + 4;
      instr_addr = singextend + imm_i;
    end//opcode I-type'1100111' end
    else if(instr_out[6:0] == 7'b0100011)//opcode S-type
    begin
        data_addr = registers[rs1] + imm_s;
      case(funct3)//func3
        3'b000://SB
        begin
          //data_addr = registers[rs1] + imm_s;
          case(data_addr[1:0])
          2'b00:
          begin
            data_write = 4'b0001;
            data_in = registers[rs2];
          end
          2'b01:
          begin
            data_write = 4'b0010;
            data_in = registers[rs2] << 8;
          end
          2'b10:
          begin
            data_write = 4'b0100;
            data_in = registers[rs2] << 16;
          end
          2'b11:
          begin
            data_write = 4'b1000;
            data_in = registers[rs2] << 24;
          end
          endcase
        end
        3'b001://SH
        begin
          case(data_addr[1:0])
          2'b00:
          begin
            data_write = 4'b0011;
            data_in = registers[rs2];
          end
          2'b01:
          begin
            data_write = 4'b0110;
            data_in = registers[rs2] << 8;
          end
          2'b10:
          begin
            data_write = 4'b1100;
            data_in = registers[rs2] << 16;
          end
          2'b11:
          begin
            data_write = 4'b1000;
            data_in = registers[rs2] << 24;
          end
          endcase
        end
        default://SW
        begin
          data_write = 4'b1111;
          data_in = registers[rs2];
        end
      endcase//func3 end
      instr_addr = instr_addr + 4;
    end//opcode S-type end
    else if(instr_out[6:0]==7'b1100011)//opcode B-type
    begin
      case(funct3)//func3
        3'b000://BEQ
        begin
    instr_addr = (registers[rs1]==registers[rs2])?($signed(instr_addr)+imm_b):(instr_addr+4);
        end
        3'b001://BNE
        begin
    instr_addr = (registers[rs1]!=registers[rs2])?($signed(instr_addr)+imm_b):(instr_addr+4);
        end
        3'b100://BLT
        begin
    instr_addr = (registers[rs1]<registers[rs2])?($signed(instr_addr)+imm_b):(instr_addr+4);
        end
        3'b101://BGE
        begin
    instr_addr = (registers[rs1]>=registers[rs2])?($signed(instr_addr)+imm_b):(instr_addr+4);
        end
        3'b110://BLTU
        begin
    instr_addr = ($unsigned(registers[rs1])<$unsigned(registers[rs2]))?($signed(instr_addr)+imm_b):(instr_addr+4);
        end
        default://BGEU
        begin
    instr_addr = ($unsigned(registers[rs1])>=$unsigned(registers[rs2]))?($signed(instr_addr)+imm_b):(instr_addr+4);
        end
      endcase//func3 end
    end//opcode B-type end
    else if(opcode == 7'b0010111)//opcode U-tpe'0010111'
    begin
      //AUIPC
      registers[rd][31:12] = imm_u;
      for(i = 0;i<12;i=i+1)
        registers[rd][i] = 0;
      registers[rd] = registers[rd] + instr_addr;
      instr_addr = instr_addr + 4;
    end//opcode U-type'0010111' end
    else if(opcode == 7'b0110111)//opcode U-type'0110111'
    begin
      //LUI
      registers[rd] = imm_u;
      registers[rd] = registers[rd] << 12;
      instr_addr = instr_addr + 4;
    end//opcode U-type'0110111' end
    else if(opcode == 7'b1101111)//opcode J-type
    begin
      //JAL
      registers[rd] = instr_addr + 4;
      instr_addr = instr_addr + imm_j;
    end//opcode J-type end
  end//else end
end
endmodule

