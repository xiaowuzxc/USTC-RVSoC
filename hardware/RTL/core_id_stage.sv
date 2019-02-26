module core_id_stage(
    input  logic [31:0]  i_instr,
    input  logic [31:0]  i_pc,
    output logic [ 4:0]  o_rs1_addr, o_rs2_addr,
    output logic o_rs1_en, o_rs2_en,
    output logic o_jal,  o_jalr, o_branch_may, 
    output logic o_nextpc2reg, o_alures2reg, o_memory2reg,
    output logic o_mem_write,
    output logic [31:0]  o_pc_plus_imm, o_imm,
    output logic [4:0]   o_dst_reg_addr,
    output logic [6:0]   o_opcode, o_funct7,
    output logic [2:0]   o_funct3,
    output logic [31:0]  o_next_pc
);

logic [31:0] instr;

enum {UKNOWN_TYPE, R_TYPE, I_TYPE, IZ_TYPE, S_TYPE, B_TYPE, U_TYPE, J_TYPE} instr_type;
            
localparam  OPCODE_JAL           = 7'b1101111,   // rd=pc+4,            pc= pc+imm*2,
            OPCODE_JALR          = 7'b1100111,   // rd=pc+4,            pc= rs1+imm
            OPCODE_BXXX          = 7'b1100011,   // conditional branch, pc= pc+imm*2,
            OPCODE_LUI           = 7'b0110111,   // rd = imm;
            OPCODE_ALI           = 7'b0010011,   // arithmetic and logical I-TYPE, rd=alu_res
            OPCODE_ALR           = 7'b0110011,   // arithmetic and logical R-TYPE, rd=alu_res
            OPCODE_LOAD          = 7'b0000011,   // load
            OPCODE_STORE         = 7'b0100011;   // store

assign instr = i_instr;
assign o_next_pc = i_pc + 4;
assign o_pc_plus_imm = i_pc + o_imm;
assign {o_funct7, o_rs2_addr, o_rs1_addr, o_funct3, o_dst_reg_addr, o_opcode} = instr;

assign o_jal             = (o_opcode == OPCODE_JAL  );
assign o_jalr            = (o_opcode == OPCODE_JALR );
assign o_branch_may      = (o_opcode == OPCODE_BXXX );
assign o_nextpc2reg      = (o_opcode == OPCODE_JAL || o_opcode == OPCODE_JALR );
assign o_alures2reg      = (o_opcode == OPCODE_LUI || o_opcode == OPCODE_ALI || o_opcode == OPCODE_ALR);
assign o_memory2reg      = (o_opcode == OPCODE_LOAD );
assign o_mem_write       = (o_opcode == OPCODE_STORE);

// calculate instruction type
always_comb
    case(o_opcode)
        OPCODE_JAL  : instr_type <= J_TYPE;
        OPCODE_JALR : instr_type <= I_TYPE;
        OPCODE_BXXX : instr_type <= B_TYPE;
        OPCODE_LUI  : instr_type <= U_TYPE;
        OPCODE_ALI  : instr_type <= (o_funct3==3'b011) ? IZ_TYPE : I_TYPE;
        OPCODE_ALR  : instr_type <= R_TYPE;
        OPCODE_LOAD : instr_type <= I_TYPE;
        OPCODE_STORE: instr_type <= S_TYPE;
        default     : instr_type <= UKNOWN_TYPE;
    endcase
    
always_comb
    case(instr_type)
        I_TYPE : o_imm <= {{20{instr[31]}} , instr[31:20]};
        IZ_TYPE: o_imm <= { 20'h0          , instr[31:20]};
        S_TYPE : o_imm <= {{20{instr[31]}} , instr[31:25], instr[11:7]};
        B_TYPE : o_imm <= {{20{instr[31]}} , instr[7], instr[30:25], instr[11:8], 1'b0};
        U_TYPE : o_imm <= { instr[31:12]   , 12'h0 };
        J_TYPE : o_imm <= {{12{instr[31]}} , instr[19:12], instr[20], instr[30:21], 1'b0};
        default: o_imm <= 0;
    endcase
    
always_comb
    case(instr_type)
        R_TYPE : {o_rs2_en, o_rs1_en} <= 2'b11;
        I_TYPE : {o_rs2_en, o_rs1_en} <= 2'b01;
        IZ_TYPE: {o_rs2_en, o_rs1_en} <= 2'b01;
        S_TYPE : {o_rs2_en, o_rs1_en} <= 2'b11;
        B_TYPE : {o_rs2_en, o_rs1_en} <= 2'b11;
        U_TYPE : {o_rs2_en, o_rs1_en} <= 2'b00;
        J_TYPE : {o_rs2_en, o_rs1_en} <= 2'b00;
        default: {o_rs2_en, o_rs1_en} <= 2'b00;
    endcase

endmodule