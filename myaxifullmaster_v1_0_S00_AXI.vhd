
--------------------------------------------------
-- Register mapping
--------------------------------------------------
--
-- reg 0 (partial R/W)
--   15-00:16 : Number of data items per frame
--   31-16:16 : Max number of data items per frame (read-only)
--
-- reg 1 (partial R/W)
--   15-00:16 : Number of neurons in first stage
--   31-16:16 : Max number of neurons in first stage (read-only)
--
-- reg 2 (partial R/W)
--   15-00:16 : Number of neurons in second stage
--   31-16:16 : Max number of neurons in second stage (read-only)
--
-- reg 3 (partial R/W)
--   03-00:4  : What the PC is sending
--              0000 = nothing
--              0001 = frame data
--              0010 = config for level 1
--              0100 = config for recoding 1-2
--              1000 = config for level 2
--      08:1  : clear all (not written to register)
--      09:1  : Read master AXI busy state
--
-- reg 4 (unused) : sortie de la première FIFO
-- reg 5 (unused) : sortie de la deuxième FIFO
--
-- reg 6 (R/W)
--   31-00:32 : Number of NN output values to write back to DDR
--
-- reg 7 (unused) : sortie de la troisième FIFO
-- reg 8 (unused) : sortie de la quatrième FIFO
-- reg 9 (unused)
--
-- reg 10 (R/W)
--   31-00:32 : Address for DDR read
--
-- reg 11 (R/W)
--   31-00:32 : Address for DDR write
--
-- reg 12 (R/W)
--   31-00:32 : Number of bursts for DDR Read. Start on write.
--
-- reg 13 (R/W)
--   31-00:32 : Number of bursts for DDR write. Start on write.
--
-- reg 14 (read only)
--   07-00:8  : count of fifo between level 1 and recoding 1-2
--   15-08:8  : count of fifo between recoding 1-2 and level 2
--   23-16:8  : count of fifo after level 2
--
-- reg 15 (read only)
--   31-16:16 : fifo rdy/ack signals, in and out: 12 signals
--
--------------------------------------------------
-- Protocol description
--------------------------------------------------
--
-- One weight per DDR word
-- One data per DDR word


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myaxifullmaster_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
	);
	port (
		-- Users to add ports here

		mymaster_addr_inw : out std_logic_vector(31 downto 0);
		mymaster_addr_inr : out std_logic_vector(31 downto 0);

		mymaster_burstnb_inw : out std_logic_vector(31 downto 0);
		mymaster_burstnb_inr : out std_logic_vector(31 downto 0);

		mymaster_startw : out std_logic;
		mymaster_startr : out std_logic;
		mymaster_busyw  : in std_logic;
		mymaster_busyr  : in std_logic;
		mymaster_sensor : in std_logic_vector(31 downto 0);  -- For various debug signals

		mymaster_fifor_data : in std_logic_vector(31 downto 0);
		mymaster_fifor_en   : in std_logic;
		mymaster_fifor_cnt  : out std_logic_vector(15 downto 0);

		mymaster_fifow_data : out std_logic_vector(31 downto 0);
		mymaster_fifow_en   : in std_logic;
		mymaster_fifow_cnt  : out std_logic_vector(15 downto 0);

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
		--   privilege and security level of the transaction, and whether
		--   the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
		--   valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
		--   to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave)
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
		--   valid data. There is one write strobe bit for each eight
		--   bits of the write data bus.
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
		--   and security level of the transaction, and whether the
		--   transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
		--   is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
		--   ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end myaxifullmaster_v1_0_S00_AXI;

architecture arch_imp of myaxifullmaster_v1_0_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready : std_logic;
	signal axi_wready  : std_logic;
	signal axi_bresp   : std_logic_vector(1 downto 0);
	signal axi_bvalid  : std_logic;
	signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready : std_logic;
	signal axi_rdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp   : std_logic_vector(1 downto 0);
	signal axi_rvalid  : std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 3;

	------------------------------------------------
	-- Some signals to make reset last longer
	--------------------------------------------------

	constant RESET_DURATION : natural := 64;
	signal reset_counter : unsigned(15 downto 0) := (others => '0');
	signal reset_reg : std_logic := '0';

	------------------------------------------------
	-- Signals for user logic register space
	--------------------------------------------------

	-- Number of Slave Registers 16
	signal slv_reg0 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg1 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg2 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg3 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg4 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg5 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg6 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg7 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg8 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg9 :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg10 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg11 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg12 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg13 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg14 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal slv_reg15 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal slv_reg_rdaddr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	signal slv_reg_wraddr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	signal slv_reg_rddata : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_wrdata : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_wstrb  : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);

	----------------------------------------------------
	-- Definitions for the neural network
	----------------------------------------------------

	constant LAYER1_WDATA   : natural := 32;
	constant LAYER1_WWEIGHT : natural := 16;
	constant LAYER1_WACCU   : natural := 32;
	constant LAYER1_FSIZE   : natural := 784;
	--constant LAYER1_FSIZE   : natural := 64;
	constant LAYER1_NBNEU   : natural := 100;
	--constant LAYER1_NBNEU   : natural := 4;

	constant RECODE_WDATA   : natural := LAYER1_WACCU;
	constant RECODE_WWEIGHT : natural := 16;
	constant RECODE_WOUT    : natural := 32;
	constant RECODE_FSIZE   : natural := LAYER1_NBNEU;

	constant LAYER2_WDATA   : natural := RECODE_WOUT;
	constant LAYER2_WWEIGHT : natural := 16;
	constant LAYER2_WACCU   : natural := 32;
	constant LAYER2_FSIZE   : natural := LAYER1_NBNEU;
	-- constant LAYER2_NBNEU   : natural := 3;
	constant LAYER2_NBNEU   : natural := 10;

	signal req_start_recv : std_logic := '0';
	signal req_start_send : std_logic := '0';

	signal items_per_frame : unsigned(15 downto 0) := (others => '0');

	constant CST_RECV_FRAME        : std_logic_vector(3 downto 0) := "0001";
	constant CST_RECV_CFG_LEVEL1   : std_logic_vector(3 downto 0) := "0010";
	constant CST_RECV_CFG_RECODE12 : std_logic_vector(3 downto 0) := "0100";
	constant CST_RECV_CFG_LEVEL2   : std_logic_vector(3 downto 0) := "1000";
	signal cur_recv : std_logic_vector(3 downto 0) := CST_RECV_FRAME;

	signal recv_frame : std_logic := '0';
	signal recv_cfgl1 : std_logic := '0';
	signal recv_cfgr1 : std_logic := '0';
	signal recv_cfgl2 : std_logic := '0';

	-- Signals to control obtaining output values and sending them over PCIe
	signal out_cur_nb, out_cur_nb_n      : unsigned(31 downto 0) := (others => '0');  -- Number of values obtained
	signal out_want_nb                   : unsigned(31 downto 0) := (others => '0');  -- Number of values to send
	signal out_getres, out_getres_n      : std_logic := '0';
	signal out_gotall, out_gotall_n      : std_logic := '0';

	constant DDRFIFOS_DEPTH : natural := 64;
	constant FIFOS_CNTW     : natural := 8;

	----------------------------------------------------
	-- Components
	----------------------------------------------------

	-- The circular buffer / FIFO component
	component circbuf_fast is
		generic (
			DATAW : natural := 32;
			DEPTH : natural := 64;
			CNTW  : natural := 8
		);
		port (
			reset         : in  std_logic;
			clk           : in  std_logic;
			fifo_in_data  : in  std_logic_vector(DATAW-1 downto 0);
			fifo_in_rdy   : out std_logic;
			fifo_in_ack   : in  std_logic;
			fifo_in_cnt   : out std_logic_vector(CNTW-1 downto 0);
			fifo_out_data : out std_logic_vector(DATAW-1 downto 0);
			fifo_out_rdy  : out std_logic;
			fifo_out_ack  : in  std_logic;
			fifo_out_cnt  : out std_logic_vector(CNTW-1 downto 0)
		);
	end component;

	-- Then component for one layel of the NN
	component nnlayer is
		generic (
			-- Parameters for the neurons
			WDATA   : natural := 16;
			WWEIGHT : natural := 16;
			WACCU   : natural := 48;
			-- Parameters for frame and number of neurons
			FSIZE   : natural := 1000;
			NBNEU   : natural := 1000
		);
		port (
			clk            : in  std_logic;
			clear          : in  std_logic;
			-- Ports for Write Enable
			write_mode     : in  std_logic;
			write_data     : in  std_logic_vector(WDATA-1 downto 0);
			write_enable   : in  std_logic;
			write_ready    : out std_logic;
			-- The user-specified frame size and number of neurons
			user_fsize     : in  std_logic_vector(15 downto 0);
			user_nbneu     : in  std_logic_vector(15 downto 0);
			-- Data input, 2 bits
			data_in        : in  std_logic_vector(WDATA-1 downto 0);
			data_in_valid  : in  std_logic;
			data_in_ready  : out std_logic;
			-- Scan chain to extract values
			data_out       : out std_logic_vector(WACCU-1 downto 0);
			data_out_valid : out std_logic;
			-- Indicate to the parent component that we are reaching the end of the current frame
			end_of_frame   : out std_logic;
			-- The output data enters a FIFO. This indicates the available room.
			out_fifo_room  : in  std_logic_vector(15 downto 0)
		);
	end component;

	-- The component to recode neuron outputs
	component recode is
		generic(
			WDATA : natural;
			WWEIGHT : natural;
			WOUT  : natural;
			FSIZE : natural
		);
		port(
			clk             : in  std_logic;
			-- Ports for address control
			addr_clear      : in  std_logic;
			-- Ports for Write into memory
			write_mode      : in  std_logic;
			write_data      : in  std_logic_vector(WDATA - 1 downto 0);
			write_enable    : in  std_logic;
			write_ready     : out std_logic;
			-- The user-specified number of neurons
			user_nbneu      : in  std_logic_vector(15 downto 0);
			-- Data input
			data_in         : in  std_logic_vector(WDATA-1 downto 0);
			data_in_valid   : in  std_logic;
			data_in_ready   : out std_logic;
			-- Data output
			data_out        : out std_logic_vector(WOUT-1 downto 0);
			data_out_valid  : out std_logic;
			-- The output data enters a FIFO. This indicates the available room.
			out_fifo_room   : in  std_logic_vector(15 downto 0)
		);
	end component;

	-- Signals to connect the instantiated FIFO for data read from DDR
	signal inst_rdbuf_clear    : std_logic := '0';
	signal inst_rdbuf_in_data  : std_logic_vector(31 downto 0);
	signal inst_rdbuf_in_rdy   : std_logic := '0';
	signal inst_rdbuf_in_ack   : std_logic := '0';
	signal inst_rdbuf_in_cnt   : std_logic_vector(FIFOS_CNTW-1 downto 0);
	signal inst_rdbuf_out_data : std_logic_vector(31 downto 0);
	signal inst_rdbuf_out_rdy  : std_logic := '0';
	signal inst_rdbuf_out_ack  : std_logic := '0';
	signal inst_rdbuf_out_cnt  : std_logic_vector(FIFOS_CNTW-1 downto 0);

	-- Signals to instantiate level 1
	signal inst_layer1_clear          : std_logic;
	signal inst_layer1_write_mode     : std_logic;
	signal inst_layer1_write_data     : std_logic_vector(LAYER1_WDATA-1 downto 0);
	signal inst_layer1_write_enable   : std_logic;
	signal inst_layer1_write_ready    : std_logic;
	signal inst_layer1_user_fsize     : std_logic_vector(15 downto 0);
	signal inst_layer1_user_nbneu     : std_logic_vector(15 downto 0);
	signal inst_layer1_data_in        : std_logic_vector(LAYER1_WDATA-1 downto 0);
	signal inst_layer1_data_in_valid  : std_logic;
	signal inst_layer1_data_in_ready  : std_logic;
	signal inst_layer1_data_out       : std_logic_vector(LAYER1_WACCU-1 downto 0);
	signal inst_layer1_data_out_valid : std_logic;
	signal inst_layer1_end_of_frame   : std_logic;
	signal inst_layer1_out_fifo_room  : std_logic_vector(15 downto 0);

	-- Signals to instantiate FIFO between level 1 and recode
	signal inst_fifo_1r_clear    : std_logic := '0';
	signal inst_fifo_1r_in_data  : std_logic_vector(LAYER1_WACCU-1 downto 0);
	signal inst_fifo_1r_in_rdy   : std_logic := '0';
	signal inst_fifo_1r_in_ack   : std_logic := '0';
	signal inst_fifo_1r_in_cnt   : std_logic_vector(FIFOS_CNTW-1 downto 0);
	signal inst_fifo_1r_out_data : std_logic_vector(LAYER1_WACCU-1 downto 0);
	signal inst_fifo_1r_out_rdy  : std_logic := '0';
	signal inst_fifo_1r_out_ack  : std_logic := '0';
	signal inst_fifo_1r_out_cnt  : std_logic_vector(FIFOS_CNTW-1 downto 0);

	-- Signals to instantiate recoding between levels 1 and 2
	signal inst_recode_addr_clear      : std_logic;
	signal inst_recode_write_mode      : std_logic;
	signal inst_recode_write_data      : std_logic_vector(LAYER1_WACCU - 1 downto 0);
	signal inst_recode_write_enable    : std_logic;
	signal inst_recode_write_ready     : std_logic;
	signal inst_recode_user_nbneu      : std_logic_vector(15 downto 0);
	signal inst_recode_data_in         : std_logic_vector(RECODE_WDATA-1 downto 0);
	signal inst_recode_data_in_valid   : std_logic;
	signal inst_recode_data_in_ready   : std_logic;
	signal inst_recode_data_out        : std_logic_vector(RECODE_WOUT-1 downto 0);
	signal inst_recode_data_out_valid  : std_logic;
	signal inst_recode_out_fifo_room   : std_logic_vector(15 downto 0);

	-- Signals to instantiate FIFO between recode and level 2
	signal inst_fifo_r2_clear    : std_logic := '0';
	signal inst_fifo_r2_in_data  : std_logic_vector(RECODE_WOUT-1 downto 0);
	signal inst_fifo_r2_in_rdy   : std_logic := '0';
	signal inst_fifo_r2_in_ack   : std_logic := '0';
	signal inst_fifo_r2_in_cnt   : std_logic_vector(FIFOS_CNTW-1 downto 0);
	signal inst_fifo_r2_out_data : std_logic_vector(RECODE_WOUT-1 downto 0);
	signal inst_fifo_r2_out_rdy  : std_logic := '0';
	signal inst_fifo_r2_out_ack  : std_logic := '0';
	signal inst_fifo_r2_out_cnt  : std_logic_vector(FIFOS_CNTW-1 downto 0);

	-- Signals to instantiate level 2
	signal inst_layer2_clear          : std_logic;
	signal inst_layer2_write_mode     : std_logic;
	signal inst_layer2_write_data     : std_logic_vector(LAYER2_WDATA-1 downto 0);
	signal inst_layer2_write_enable   : std_logic;
	signal inst_layer2_write_ready    : std_logic;
	signal inst_layer2_user_fsize     : std_logic_vector(15 downto 0);
	signal inst_layer2_user_nbneu     : std_logic_vector(15 downto 0);
	signal inst_layer2_data_in        : std_logic_vector(LAYER2_WDATA-1 downto 0);
	signal inst_layer2_data_in_valid  : std_logic;
	signal inst_layer2_data_in_ready  : std_logic;
	signal inst_layer2_data_out       : std_logic_vector(LAYER2_WACCU-1 downto 0);
	signal inst_layer2_data_out_valid : std_logic;
	signal inst_layer2_end_of_frame   : std_logic;
	signal inst_layer2_out_fifo_room  : std_logic_vector(15 downto 0);

	-- Signals to instantiate FIFO between level 2 and output
	signal inst_fifo_2o_clear    : std_logic := '0';
	signal inst_fifo_2o_in_data  : std_logic_vector(LAYER2_WACCU-1 downto 0);
	signal inst_fifo_2o_in_rdy   : std_logic := '0';
	signal inst_fifo_2o_in_ack   : std_logic := '0';
	signal inst_fifo_2o_in_cnt   : std_logic_vector(FIFOS_CNTW-1 downto 0);
	signal inst_fifo_2o_out_data : std_logic_vector(LAYER2_WACCU-1 downto 0);
	signal inst_fifo_2o_out_rdy  : std_logic := '0';
	signal inst_fifo_2o_out_ack  : std_logic := '0';
	signal inst_fifo_2o_out_cnt  : std_logic_vector(FIFOS_CNTW-1 downto 0);

	-- Signals to connect the instantiated FIFO for data read from DDR
	signal inst_wrbuf_clear    : std_logic := '0';
	signal inst_wrbuf_in_data  : std_logic_vector(31 downto 0);
	signal inst_wrbuf_in_rdy   : std_logic := '0';
	signal inst_wrbuf_in_ack   : std_logic := '0';
	signal inst_wrbuf_in_cnt   : std_logic_vector(FIFOS_CNTW-1 downto 0);
	signal inst_wrbuf_out_data : std_logic_vector(31 downto 0);
	signal inst_wrbuf_out_rdy  : std_logic := '0';
	signal inst_wrbuf_out_ack  : std_logic := '0';
	signal inst_wrbuf_out_cnt  : std_logic_vector(FIFOS_CNTW-1 downto 0);

begin

	----------------------------------
	-- AXI functionality
	----------------------------------

	-- I/O Connections assignments

	S_AXI_AWREADY <= axi_awready;
	S_AXI_WREADY  <= axi_wready;
	S_AXI_BRESP   <= axi_bresp;
	S_AXI_BVALID  <= axi_bvalid;
	S_AXI_ARREADY <= axi_arready;
	S_AXI_RDATA   <= axi_rdata;
	S_AXI_RRESP   <= axi_rresp;
	S_AXI_RVALID  <= axi_rvalid;

	-- State machine for AXI Write operations
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_wready  <= '0';
				axi_awready <= '0';
				axi_awaddr  <= (others => '0');
			else

				-- Implement axi_wready generation
				-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both S_AXI_AWVALID and S_AXI_WVALID are asserted. 

				if axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' then
					-- Slave is ready to accept write data when there is a valid write address and write data on the write address and data bus.
					-- This design expects no outstanding transactions.
					axi_wready <= '1';
				else
					axi_wready <= '0';
				end if;

				-- Implement axi_awready generation
				-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both S_AXI_AWVALID and S_AXI_WVALID are asserted.

				if axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' then
					-- Slave is ready to accept write address when there is a valid write address and write data on the write address and data bus.
					-- This design expects no outstanding transactions.
					axi_awready <= '1';
					-- Write Address latching
					axi_awaddr <= S_AXI_AWADDR;
				else
					axi_awready <= '0';
				end if;

			end if;
		end if;
	end process;

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
	-- Write strobes are used to select byte enables of slave registers while writing.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	-- State machine for AXI Write operations
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				slv_reg_wren <= '0';
			else

				-- Note: Buffering these signals is optional. It improves routing.
				slv_reg_wren   <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID;
				slv_reg_wraddr <= axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
				slv_reg_wrdata <= S_AXI_WDATA;
				slv_reg_wstrb  <= S_AXI_WSTRB;

			end if;
		end if;
	end process;

	-- State machine for AXI Write response
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_bvalid  <= '0';
				axi_bresp   <= "00"; --need to work more on the responses
			else

				-- The write response and response valid signals are asserted by the slave
				-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
				-- This marks the acceptance of address and indicates the status of write transaction.
				if axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0' then
					axi_bvalid <= '1';
					axi_bresp  <= "00";
				end if;

				-- Check if bready is asserted while bvalid is high
				-- (there is a possibility that bready is always asserted high)
				if S_AXI_BREADY = '1' and axi_bvalid = '1' then   
					axi_bvalid <= '0';                              
				end if;

			end if;
		end if;
	end process;

	-- State machine for AXI Read operation
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_arready <= '0';
				axi_araddr  <= (others => '0');
				axi_rvalid  <= '0';
				axi_rresp   <= "00";
				axi_rdata   <= (others => '0');
			else

				-- Get the read address
				-- axi_arready is asserted for one S_AXI_ACLK clock cycle when S_AXI_ARVALID is asserted.
				-- The read address is also latched when S_AXI_ARVALID is asserted.

				if axi_arready = '0' and S_AXI_ARVALID = '1' then
					-- Indicates that the slave has accepted the valid read address
					axi_arready <= '1';
					-- Read Address latching
					axi_araddr  <= S_AXI_ARADDR;
				else
					axi_arready <= '0';
				end if;

				-- Send the read data
				-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both S_AXI_ARVALID and axi_arready are asserted.
				-- The slave registers data are available on the axi_rdata bus at this instance.
				-- The assertion of axi_rvalid marks the validity of read data on the bus and axi_rresp indicates the status of read transaction.

				if axi_arready = '1' then
					axi_rdata <= slv_reg_rddata;
				end if;

				if axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0' then
					-- Valid read data is available at the read data bus
					axi_rvalid <= '1';
					axi_rresp  <= "00"; -- 'OKAY' response
				end if;

				if (axi_rvalid = '1' and S_AXI_RREADY = '1') then
					-- Read data is accepted by the master
					axi_rvalid <= '0';
				end if;

			end if;  -- S_AXI_ARESETN = '1'
		end if;  -- rising_edge(S_AXI_ACLK)
	end process;

	-- Alias signals to be used by the user design
	slv_reg_rden   <= axi_arready;
	slv_reg_rdaddr <= axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);


	----------------------------------
	-- Main design functionality
	----------------------------------

	-- Alias signals

	cur_recv <= slv_reg3(3 downto 0);

	recv_frame <= cur_recv(0);
	recv_cfgl1 <= cur_recv(1);
	recv_cfgr1 <= cur_recv(2);
	recv_cfgl2 <= cur_recv(3);

	out_want_nb <= unsigned(slv_reg6);

	-- Main sequential process: write to config registers, implement all synchronous registers
	process (S_AXI_ACLK)
		variable tmpvar_slv_reg         : std_logic_vector(31 downto 0) := (others => '0');
		variable tmpvar_slv_reg_mask_we : std_logic_vector(31 downto 0) := (others => '0');
	begin
		if rising_edge(S_AXI_ACLK) then

			-- Hold reset active for a certain duration
			if reset_counter > 0 then
				reset_counter <= reset_counter - 1;
				reset_reg <= '1';
			else
				reset_reg <= '0';
			end if;
			-- Generate reset
			if S_AXI_ARESETN = '0' then
				reset_counter <= to_unsigned(RESET_DURATION, reset_counter'length);
				reset_reg <= '1';
			end if;

			-- Default/reset assignments
			req_start_recv <= '0';
			req_start_send <= '0';

			-- Buffers for output registers
			out_cur_nb <= out_cur_nb_n;
			out_getres <= out_getres_n;
			out_gotall <= out_gotall_n;

			if reset_reg = '1' then

				slv_reg0  <= (others => '0');
				slv_reg1  <= (others => '0');
				slv_reg2  <= (others => '0');
				slv_reg3  <= (others => '0');
				slv_reg4  <= (others => '0');
				slv_reg5  <= (others => '0');
				slv_reg6  <= (others => '0');
				slv_reg7  <= (others => '0');
				slv_reg8  <= (others => '0');
				slv_reg9  <= (others => '0');
				slv_reg10 <= (others => '0');
				slv_reg11 <= (others => '0');
				slv_reg12 <= (others => '0');
				slv_reg13 <= (others => '0');
				slv_reg14 <= (others => '0');
				slv_reg15 <= (others => '0');

				slv_reg0(15 downto 0)  <= std_logic_vector(to_unsigned(LAYER1_FSIZE, 16));
				slv_reg0(31 downto 16) <= std_logic_vector(to_unsigned(LAYER1_FSIZE, 16));

				slv_reg1(15 downto 0)  <= std_logic_vector(to_unsigned(LAYER1_NBNEU, 16));
				slv_reg1(31 downto 16) <= std_logic_vector(to_unsigned(LAYER1_NBNEU, 16));

				slv_reg2(15 downto 0)  <= std_logic_vector(to_unsigned(LAYER2_NBNEU, 16));
				slv_reg2(31 downto 16) <= std_logic_vector(to_unsigned(LAYER2_NBNEU, 16));

				slv_reg3(3 downto 0)   <= CST_RECV_FRAME;

			else

				-- Write to register
				if slv_reg_wren = '1' then
					case slv_reg_wraddr is

						when b"0000" =>
							-- Slave register 0
							-- Frame size. Only some bits are writable.
							tmpvar_slv_reg_mask_we := x"0000FFFF";
							tmpvar_slv_reg := (slv_reg_wrdata and tmpvar_slv_reg_mask_we) or (slv_reg0 and not tmpvar_slv_reg_mask_we);

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg0(byte_index*8+7 downto byte_index*8) <= tmpvar_slv_reg(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"0001" =>
							-- Slave register 1
							-- Number of neurons in first stage. Only some bits are writable.
							tmpvar_slv_reg_mask_we := x"0000FFFF";
							tmpvar_slv_reg := (slv_reg_wrdata and tmpvar_slv_reg_mask_we) or (slv_reg1 and not tmpvar_slv_reg_mask_we);

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg1(byte_index*8+7 downto byte_index*8) <= tmpvar_slv_reg(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"0010" =>
							-- Slave register 2
							-- Number of neurons in second stage. Only some bits are writable.
							tmpvar_slv_reg_mask_we := x"0000FFFF";
							tmpvar_slv_reg := (slv_reg_wrdata and tmpvar_slv_reg_mask_we) or (slv_reg2 and not tmpvar_slv_reg_mask_we);

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg2(byte_index*8+7 downto byte_index*8) <= tmpvar_slv_reg(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"0011" =>
							-- Slave register 3
							-- Misc status & control flags. Only some bits are writable.
							tmpvar_slv_reg_mask_we := x"000000FF";
							tmpvar_slv_reg := (slv_reg_wrdata and tmpvar_slv_reg_mask_we) or (slv_reg3 and not tmpvar_slv_reg_mask_we);

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg3(byte_index*8+7 downto byte_index*8) <= tmpvar_slv_reg(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

							-- Detect the clear requests
							if slv_reg_wrdata(8) = '1' then
								reset_counter <= to_unsigned(RESET_DURATION, reset_counter'length);
								reset_reg <= '1';
							end if;

						when b"0100" =>
							-- Slave register 4

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg4(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"0101" =>
							-- Slave register 5

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg5(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"0110" =>
							-- Slave register 6
							-- Write the number of values the PC wants to read

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg6(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"0111" =>
							-- Slave register 7

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg7(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"1000" =>
							-- Slave register 8

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg8(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"1001" =>
							-- Slave register 9

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg9(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"1010" =>
							-- Slave register 10

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg10(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"1011" =>
							-- Slave register 11

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg11(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"1100" =>
							-- Slave register 12

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg12(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

							-- Start reading data from DDR, 1-clock pulse
							req_start_recv <= '1';

						when b"1101" =>
							-- Slave register 13

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg13(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

							-- Start writing data to DDR, 1-clock pulse
							req_start_send <= '1';

						when b"1110" =>
							-- Slave register 14

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg14(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when b"1111" =>
							-- Slave register 15

							-- Respective byte enables are asserted as per write strobes
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
								if ( slv_reg_wstrb(byte_index) = '1' ) then
									slv_reg15(byte_index*8+7 downto byte_index*8) <= slv_reg_wrdata(byte_index*8+7 downto byte_index*8);
								end if;
							end loop;

						when others =>

					end case;  -- Address
				end if;  -- Write enable

			end if;  -- Not reset
		end if;  -- Clock
	end process;

	-- Combinatorial process - Control signals for output values
	process (
		reset_reg,
		req_start_send,
		out_cur_nb, out_want_nb, out_getres, out_gotall,
		inst_fifo_2o_out_rdy, inst_wrbuf_in_rdy
	)
	begin

		-- Default values
		out_cur_nb_n <= out_cur_nb;
		out_getres_n <= out_getres;
		out_gotall_n <= out_gotall;

		inst_fifo_2o_out_ack <= '0';
		inst_wrbuf_in_ack    <= '0';

		-- Handle reset and when functionality is disabled
		if reset_reg = '1' then
			out_cur_nb_n <= (others => '0');
			out_getres_n <= '0';
			out_gotall_n <= '0';
		else

			if (req_start_send = '1') and (out_want_nb > 0) then
				out_getres_n <= '1';
			end if;

			-- Fill the Write FIFO with data from the NN level 2
			if out_getres = '1' then
				inst_fifo_2o_out_ack <= inst_wrbuf_in_rdy;
				inst_wrbuf_in_ack    <= inst_fifo_2o_out_rdy;
				if (inst_wrbuf_in_rdy = '1') and (inst_fifo_2o_out_rdy = '1') then
					out_cur_nb_n <= out_cur_nb + 1;
				end if;
				-- Intentionally simplifying the test expression
				if out_cur_nb = out_want_nb then
					out_getres_n <= '0';
					out_gotall_n <= '1';
				end if;
			end if;

			-- Fill the Write FIFO with junk data
			if out_gotall = '1' then
				inst_wrbuf_in_ack <= '1';
			end if;

		end if;

	end process;

	-- Combinatorial process - Read register, it's a big MUX
	process(
		reset_reg,
		-- The address of the register to read
		slv_reg_rdaddr,
		-- The register contents
		slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6, slv_reg7,
		slv_reg8, slv_reg9, slv_reg10, slv_reg11, slv_reg12, slv_reg13, slv_reg14, slv_reg15,
		-- Pipeline sensors
		inst_rdbuf_in_rdy, inst_rdbuf_in_ack, inst_rdbuf_out_rdy, inst_rdbuf_out_ack, inst_rdbuf_out_cnt,
		inst_wrbuf_in_rdy, inst_wrbuf_in_ack, inst_wrbuf_out_rdy, inst_wrbuf_out_ack, inst_wrbuf_out_cnt,
		inst_fifo_1r_in_rdy, inst_fifo_1r_in_ack, inst_fifo_1r_out_rdy, inst_fifo_1r_out_ack, inst_fifo_1r_out_cnt,
		inst_fifo_r2_in_rdy, inst_fifo_r2_in_ack, inst_fifo_r2_out_rdy, inst_fifo_r2_out_ack, inst_fifo_r2_out_cnt,
		inst_fifo_2o_in_rdy, inst_fifo_2o_in_ack, inst_fifo_2o_out_rdy, inst_fifo_2o_out_ack, inst_fifo_2o_out_cnt,
		inst_layer1_write_ready, inst_layer1_data_in_ready, inst_layer1_data_in_valid,
		inst_layer2_write_ready, inst_layer2_data_in_ready, inst_layer2_data_in_valid,
		-- Various counters
		out_getres, out_gotall,
		-- Master AXI sensors
		mymaster_busyw, mymaster_busyr, mymaster_sensor
	)
	begin

		slv_reg_rddata <= (others => '0');

		-- Address decoding for reading registers
		case slv_reg_rdaddr is

			when b"0000" =>
				slv_reg_rddata <= slv_reg0;

			when b"0001" =>
				slv_reg_rddata <= slv_reg1;

			when b"0010" =>
				slv_reg_rddata <= slv_reg2;

			when b"0011" =>
				slv_reg_rddata <= slv_reg3;

				slv_reg_rddata(8)  <= reset_reg;

				slv_reg_rddata(9)  <= mymaster_busyw;
				slv_reg_rddata(10) <= mymaster_busyr;

				slv_reg_rddata(11) <= out_getres;
				slv_reg_rddata(12) <= out_gotall;

			when b"0100" =>
				--slv_reg_rddata <= slv_reg4;

				slv_reg_rddata <= mymaster_sensor;

			when b"0101" =>
				--slv_reg_rddata <= slv_reg5;

			when b"0110" =>
				slv_reg_rddata <= slv_reg6;

			when b"0111" =>
				--slv_reg_rddata <= slv_reg7;

			when b"1000" =>
				slv_reg_rddata <= slv_reg8;
				-- to pop data from the fifo between l1 and recode 
				-- THE RECODE CAN NOT POP FIFO FROM THE FIFO
				-- slv_reg_rddata <= inst_fifo_1r_out_data;
				--slv_reg_rddata <= inst_fifo_r2_out_data;
				-- slv_reg_rddata <= inst_rdbuf_out_data;

			when b"1001" =>
				--slv_reg_rddata <= slv_reg9;

			when b"1010" =>
				slv_reg_rddata <= slv_reg10;

			when b"1011" =>
				slv_reg_rddata <= slv_reg11;

			when b"1100" =>
				slv_reg_rddata <= slv_reg12;

			when b"1101" =>
				slv_reg_rddata <= slv_reg13;

			when b"1110" =>
				slv_reg_rddata <= slv_reg14;

				-- Read the amount of data still present in the FIFOs
				slv_reg_rddata(7 downto 0)   <= inst_fifo_1r_out_cnt;
				slv_reg_rddata(15 downto 8)  <= inst_fifo_r2_out_cnt;
				slv_reg_rddata(23 downto 16) <= inst_fifo_2o_out_cnt;

				slv_reg_rddata(31 downto 24) <= inst_rdbuf_out_cnt;

			when b"1111" =>
				slv_reg_rddata <= slv_reg15;

				slv_reg_rddata(7 downto 0) <= inst_wrbuf_out_cnt;

				-- Read the FIFO sync signals
				slv_reg_rddata(12) <= inst_rdbuf_in_rdy;
				slv_reg_rddata(13) <= inst_rdbuf_in_ack;
				slv_reg_rddata(14) <= inst_rdbuf_out_rdy;
				slv_reg_rddata(15) <= inst_rdbuf_out_ack;

				slv_reg_rddata(16) <= inst_fifo_1r_in_rdy;
				slv_reg_rddata(17) <= inst_fifo_1r_in_ack;
				slv_reg_rddata(18) <= inst_fifo_1r_out_rdy;
				slv_reg_rddata(19) <= inst_fifo_1r_out_ack;

				slv_reg_rddata(20) <= inst_fifo_r2_in_rdy;
				slv_reg_rddata(21) <= inst_fifo_r2_in_ack;
				slv_reg_rddata(22) <= inst_fifo_r2_out_rdy;
				slv_reg_rddata(23) <= inst_fifo_r2_out_ack;

				slv_reg_rddata(24) <= inst_fifo_2o_in_rdy;
				slv_reg_rddata(25) <= inst_fifo_2o_in_ack;
				slv_reg_rddata(26) <= inst_fifo_2o_out_rdy;
				slv_reg_rddata(27) <= inst_fifo_2o_out_ack;

				slv_reg_rddata(28) <= inst_wrbuf_in_rdy;
				slv_reg_rddata(29) <= inst_wrbuf_in_ack;
				slv_reg_rddata(30) <= inst_wrbuf_out_rdy;
				slv_reg_rddata(31) <= inst_wrbuf_out_ack;

			when others =>
				slv_reg_rddata <= (others => '0');

		end case;

	end process;


	----------------------------------
	-- FIFO to hold data read from DDR
	----------------------------------

	-- Instantiate the FIFO for the read values
	i_rdbuf : circbuf_fast
		generic map (
			DATAW => 32,
			DEPTH => DDRFIFOS_DEPTH,
			CNTW  => FIFOS_CNTW
		)
		port map (
			clk           => S_AXI_ACLK,
			reset         => inst_rdbuf_clear,
			fifo_in_data  => inst_rdbuf_in_data,
			fifo_in_rdy   => inst_rdbuf_in_rdy,
			fifo_in_ack   => inst_rdbuf_in_ack,
			fifo_in_cnt   => inst_rdbuf_in_cnt,
			fifo_out_data => inst_rdbuf_out_data,
			fifo_out_rdy  => inst_rdbuf_out_rdy,
			fifo_out_ack  => inst_rdbuf_out_ack,
			fifo_out_cnt  => inst_rdbuf_out_cnt
		);

		inst_rdbuf_clear   <= reset_reg;
		inst_rdbuf_in_data <= mymaster_fifor_data;
		-- for the debug
		--inst_rdbuf_in_data <= slv_reg9;
		inst_rdbuf_in_ack  <= mymaster_fifor_en;
		-- for the debug
		--inst_rdbuf_in_ack  <= '1' when ((slv_reg_wraddr = b"1001") and (slv_reg_wren = '1')) else '0';
		inst_rdbuf_out_ack <=
			(recv_cfgl1 and inst_layer1_write_ready) or
			(recv_cfgr1 and inst_recode_write_ready) or
			(recv_cfgl2 and inst_layer2_write_ready) or
			(recv_frame and inst_layer1_data_in_ready);
		-- for debug
		--inst_rdbuf_out_ack <= '1' when ((slv_reg_rdaddr = b"1000") and (slv_reg_rden = '1')) else '0';


	----------------------------------
	-- Instantiation of NN level 1
	----------------------------------

	i_layer1 : nnlayer
		generic map (
			-- Parameters for the neurons
			WDATA   => LAYER1_WDATA,
			WWEIGHT => LAYER1_WWEIGHT,
			WACCU   => LAYER1_WACCU,
			-- Parameters for frame and number of neurons
			FSIZE   => LAYER1_FSIZE,
			NBNEU   => LAYER1_NBNEU
		)
		port map (
			clk            => S_AXI_ACLK,
			clear          => inst_layer1_clear,
			write_mode     => inst_layer1_write_mode,
			write_data     => inst_layer1_write_data,
			write_enable   => inst_layer1_write_enable,
			write_ready    => inst_layer1_write_ready,
			user_fsize     => inst_layer1_user_fsize,
			user_nbneu     => inst_layer1_user_nbneu,
			data_in        => inst_layer1_data_in,
			data_in_valid  => inst_layer1_data_in_valid,
			data_in_ready  => inst_layer1_data_in_ready,
			data_out       => inst_layer1_data_out,
			data_out_valid => inst_layer1_data_out_valid,
			end_of_frame   => inst_layer1_end_of_frame,
			out_fifo_room  => inst_layer1_out_fifo_room
		);

	-- Set inputs
	inst_layer1_clear         <= reset_reg;
	inst_layer1_write_mode    <= recv_cfgl1;
	inst_layer1_write_data    <= inst_rdbuf_out_data(LAYER1_WDATA-1 downto 0);
	inst_layer1_write_enable  <= inst_rdbuf_out_rdy and recv_cfgl1;
	inst_layer1_user_fsize    <= slv_reg0(15 downto 0);
	inst_layer1_user_nbneu    <= slv_reg1(15 downto 0);
	inst_layer1_data_in       <= inst_rdbuf_out_data(LAYER1_WDATA-1 downto 0);
	-- protection from reading into the 1st FIFO during configuration of others 
	inst_layer1_data_in_valid <= inst_rdbuf_out_rdy and recv_frame;
	inst_layer1_out_fifo_room <= std_logic_vector(resize(unsigned(inst_fifo_1r_in_cnt), 16));


	----------------------------------
	-- FIFO between level 1 and recode
	----------------------------------

	i_fifo1r : circbuf_fast
		generic map (
			DATAW => LAYER1_WACCU,
			DEPTH => DDRFIFOS_DEPTH,
			CNTW  => FIFOS_CNTW
		)
		port map (
			clk           => S_AXI_ACLK,
			reset         => inst_fifo_1r_clear,
			fifo_in_data  => inst_fifo_1r_in_data,
			fifo_in_rdy   => inst_fifo_1r_in_rdy,
			fifo_in_ack   => inst_fifo_1r_in_ack,
			fifo_in_cnt   => inst_fifo_1r_in_cnt,
			fifo_out_data => inst_fifo_1r_out_data,
			fifo_out_rdy  => inst_fifo_1r_out_rdy,
			fifo_out_ack  => inst_fifo_1r_out_ack,
			fifo_out_cnt  => inst_fifo_1r_out_cnt
		);

	-- Set inputs
	inst_fifo_1r_clear   <= reset_reg;
	inst_fifo_1r_in_data <= inst_layer1_data_out;
	inst_fifo_1r_in_ack  <= inst_layer1_data_out_valid;

	inst_fifo_1r_out_ack <= (inst_recode_data_in_ready and recv_frame);
	-- For debug, le recode can not read data from this fifo
	--inst_fifo_1r_out_ack <= '1' when ((slv_reg_rdaddr = b"1000") and (slv_reg_rden = '1')) else '0';



	----------------------------------
	-- Recode between levels 1 and 2
	----------------------------------

	i_recode : recode
		generic map (
			WDATA => RECODE_WDATA,
			WWEIGHT => RECODE_WWEIGHT,
			WOUT  => RECODE_WOUT,
			FSIZE => RECODE_FSIZE
		)
		port map (
			clk            => S_AXI_ACLK,
			addr_clear     => inst_recode_addr_clear,
			write_mode     => inst_recode_write_mode,
			write_data     => inst_recode_write_data,
			write_enable   => inst_recode_write_enable,
			write_ready    => inst_recode_write_ready,
			user_nbneu     => inst_recode_user_nbneu,
			data_in        => inst_recode_data_in,
			data_in_valid  => inst_recode_data_in_valid,
			data_in_ready  => inst_recode_data_in_ready,
			data_out       => inst_recode_data_out,
			data_out_valid => inst_recode_data_out_valid,
			out_fifo_room  => inst_recode_out_fifo_room
		);

	-- Set inputs
	inst_recode_addr_clear    <= reset_reg;
	inst_recode_write_mode    <= recv_cfgr1;
	inst_recode_write_data    <= inst_rdbuf_out_data;
	inst_recode_write_enable  <= inst_rdbuf_out_rdy and recv_cfgr1;
	inst_recode_user_nbneu    <= slv_reg1(15 downto 0);
	inst_recode_data_in       <= inst_fifo_1r_out_data;
	inst_recode_data_in_valid <= inst_fifo_1r_out_rdy and recv_frame;
	inst_recode_out_fifo_room <= std_logic_vector(resize(unsigned(inst_fifo_r2_in_cnt), 16));


	----------------------------------
	-- FIFO between recode and level 2
	----------------------------------

	i_fifor2 : circbuf_fast
		generic map (
			DATAW => RECODE_WOUT,
			DEPTH => DDRFIFOS_DEPTH,
			CNTW  => FIFOS_CNTW
		)
		port map (
			clk           => S_AXI_ACLK,
			reset         => inst_fifo_r2_clear,
			fifo_in_data  => inst_fifo_r2_in_data,
			fifo_in_rdy   => inst_fifo_r2_in_rdy,
			fifo_in_ack   => inst_fifo_r2_in_ack,
			fifo_in_cnt   => inst_fifo_r2_in_cnt,
			fifo_out_data => inst_fifo_r2_out_data,
			fifo_out_rdy  => inst_fifo_r2_out_rdy,
			fifo_out_ack  => inst_fifo_r2_out_ack,
			fifo_out_cnt  => inst_fifo_r2_out_cnt
		);

	-- Set inputs
	inst_fifo_r2_clear   <= reset_reg;
	inst_fifo_r2_in_data <= inst_recode_data_out;
	inst_fifo_r2_in_ack  <= inst_recode_data_out_valid;

	inst_fifo_r2_out_ack <= inst_layer2_data_in_ready and recv_frame;
	-- for debug
	--inst_fifo_r2_out_ack <= '1' when ((slv_reg_rdaddr = b"1000") and (slv_reg_rden = '1')) else '0';


	----------------------------------
	-- Instantiation of NN level 2
	----------------------------------

	i_layer2 : nnlayer
		generic map (
			-- Parameters for the neurons
			WDATA   => LAYER2_WDATA,
			WWEIGHT => LAYER2_WWEIGHT,
			WACCU   => LAYER2_WACCU,
			-- Parameters for frame and number of neurons
			FSIZE   => LAYER2_FSIZE,
			NBNEU   => LAYER2_NBNEU
		)
		port map (
			clk            => S_AXI_ACLK,
			clear          => inst_layer2_clear,
			write_mode     => inst_layer2_write_mode,
			write_data     => inst_layer2_write_data,
			write_enable   => inst_layer2_write_enable,
			write_ready    => inst_layer2_write_ready,
			user_fsize     => inst_layer2_user_fsize,
			user_nbneu     => inst_layer2_user_nbneu,
			data_in        => inst_layer2_data_in,
			data_in_valid  => inst_layer2_data_in_valid,
			data_in_ready  => inst_layer2_data_in_ready,
			data_out       => inst_layer2_data_out,
			data_out_valid => inst_layer2_data_out_valid,
			end_of_frame   => inst_layer2_end_of_frame,
			out_fifo_room  => inst_layer2_out_fifo_room
		);

	-- Set inputs
	inst_layer2_clear         <= reset_reg;
	inst_layer2_write_mode    <= recv_cfgl2;
	inst_layer2_write_data    <= inst_rdbuf_out_data(inst_layer2_write_data'length-1 downto 0);
	inst_layer2_write_enable  <= inst_rdbuf_out_rdy and recv_cfgl2;
	inst_layer2_user_fsize    <= slv_reg1(15 downto 0);
	inst_layer2_user_nbneu    <= slv_reg2(15 downto 0);
	inst_layer2_data_in       <= inst_fifo_r2_out_data;
	inst_layer2_data_in_valid <= inst_fifo_r2_out_rdy and recv_frame;
	inst_layer2_out_fifo_room <= std_logic_vector(resize(unsigned(inst_fifo_2o_in_cnt), 16));


	----------------------------------
	-- FIFO after level 2
	----------------------------------

	i_fifo2o : circbuf_fast
		generic map (
			DATAW => LAYER2_WACCU,
			DEPTH => DDRFIFOS_DEPTH,
			CNTW  => FIFOS_CNTW
		)
		port map (
			clk           => S_AXI_ACLK,
			reset         => inst_fifo_2o_clear,
			fifo_in_data  => inst_fifo_2o_in_data,
			fifo_in_rdy   => inst_fifo_2o_in_rdy,
			fifo_in_ack   => inst_fifo_2o_in_ack,
			fifo_in_cnt   => inst_fifo_2o_in_cnt,
			fifo_out_data => inst_fifo_2o_out_data,
			fifo_out_rdy  => inst_fifo_2o_out_rdy,
			fifo_out_ack  => inst_fifo_2o_out_ack,
			fifo_out_cnt  => inst_fifo_2o_out_cnt
		);

	-- Set inputs
	inst_fifo_2o_clear   <= reset_reg;
	inst_fifo_2o_in_data <= inst_layer2_data_out;
	inst_fifo_2o_in_ack  <= inst_layer2_data_out_valid;


	----------------------------------
	-- FIFO to write to DDR
	----------------------------------

	i_wrbuf : circbuf_fast
		generic map (
			DATAW => 32,
			DEPTH => DDRFIFOS_DEPTH,
			CNTW  => FIFOS_CNTW
		)
		port map (
			clk           => S_AXI_ACLK,
			reset         => inst_wrbuf_clear,
			fifo_in_data  => inst_wrbuf_in_data,
			fifo_in_rdy   => inst_wrbuf_in_rdy,
			fifo_in_ack   => inst_wrbuf_in_ack,
			fifo_in_cnt   => inst_wrbuf_in_cnt,
			fifo_out_data => inst_wrbuf_out_data,
			fifo_out_rdy  => inst_wrbuf_out_rdy,
			fifo_out_ack  => inst_wrbuf_out_ack,
			fifo_out_cnt  => inst_wrbuf_out_cnt
		);

	-- Set inputs
	inst_wrbuf_clear   <= reset_reg;
	inst_wrbuf_in_data <= std_logic_vector(resize(signed(inst_fifo_2o_out_data), 32));
	inst_wrbuf_out_ack <= mymaster_fifow_en;


	----------------------------------
	-- Talk to the Master port
	----------------------------------

	mymaster_fifow_data <= inst_wrbuf_out_data;

	mymaster_fifor_cnt <= std_logic_vector(resize(unsigned(inst_rdbuf_in_cnt), 16));
	mymaster_fifow_cnt <= std_logic_vector(resize(unsigned(inst_wrbuf_out_cnt), 16));

	mymaster_addr_inr <= slv_reg10;
	mymaster_addr_inw <= slv_reg11;

	mymaster_burstnb_inr <= slv_reg12;
	mymaster_burstnb_inw <= slv_reg13;

	mymaster_startr <= req_start_recv;
	mymaster_startw <= req_start_send;

end arch_imp;
