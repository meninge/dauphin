library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myaxifullmaster_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 6;

		-- Parameters of Axi Master Bus Interface M00_AXI
		C_M00_AXI_TARGET_SLAVE_BASE_ADDR	: std_logic_vector	:= x"40000000";
		C_M00_AXI_BURST_LEN	: integer	:= 16;
		C_M00_AXI_ID_WIDTH	: integer	:= 1;
		C_M00_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M00_AXI_DATA_WIDTH	: integer	:= 32;
		C_M00_AXI_AWUSER_WIDTH	: integer	:= 0;
		C_M00_AXI_ARUSER_WIDTH	: integer	:= 0;
		C_M00_AXI_WUSER_WIDTH	: integer	:= 0;
		C_M00_AXI_RUSER_WIDTH	: integer	:= 0;
		C_M00_AXI_BUSER_WIDTH	: integer	:= 0
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXI
		m00_axi_aclk	: in std_logic;
		m00_axi_aresetn	: in std_logic;
		m00_axi_awid	: out std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
		m00_axi_awaddr	: out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
		m00_axi_awlen	: out std_logic_vector(7 downto 0);
		m00_axi_awsize	: out std_logic_vector(2 downto 0);
		m00_axi_awburst	: out std_logic_vector(1 downto 0);
		m00_axi_awlock	: out std_logic;
		m00_axi_awcache	: out std_logic_vector(3 downto 0);
		m00_axi_awprot	: out std_logic_vector(2 downto 0);
		m00_axi_awqos	: out std_logic_vector(3 downto 0);
		m00_axi_awuser	: out std_logic_vector(C_M00_AXI_AWUSER_WIDTH-1 downto 0);
		m00_axi_awvalid	: out std_logic;
		m00_axi_awready	: in std_logic;
		m00_axi_wdata	: out std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
		m00_axi_wstrb	: out std_logic_vector(C_M00_AXI_DATA_WIDTH/8-1 downto 0);
		m00_axi_wlast	: out std_logic;
		m00_axi_wuser	: out std_logic_vector(C_M00_AXI_WUSER_WIDTH-1 downto 0);
		m00_axi_wvalid	: out std_logic;
		m00_axi_wready	: in std_logic;
		m00_axi_bid	: in std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
		m00_axi_bresp	: in std_logic_vector(1 downto 0);
		m00_axi_buser	: in std_logic_vector(C_M00_AXI_BUSER_WIDTH-1 downto 0);
		m00_axi_bvalid	: in std_logic;
		m00_axi_bready	: out std_logic;
		m00_axi_arid	: out std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
		m00_axi_araddr	: out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
		m00_axi_arlen	: out std_logic_vector(7 downto 0);
		m00_axi_arsize	: out std_logic_vector(2 downto 0);
		m00_axi_arburst	: out std_logic_vector(1 downto 0);
		m00_axi_arlock	: out std_logic;
		m00_axi_arcache	: out std_logic_vector(3 downto 0);
		m00_axi_arprot	: out std_logic_vector(2 downto 0);
		m00_axi_arqos	: out std_logic_vector(3 downto 0);
		m00_axi_aruser	: out std_logic_vector(C_M00_AXI_ARUSER_WIDTH-1 downto 0);
		m00_axi_arvalid	: out std_logic;
		m00_axi_arready	: in std_logic;
		m00_axi_rid	: in std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
		m00_axi_rdata	: in std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
		m00_axi_rresp	: in std_logic_vector(1 downto 0);
		m00_axi_rlast	: in std_logic;
		m00_axi_ruser	: in std_logic_vector(C_M00_AXI_RUSER_WIDTH-1 downto 0);
		m00_axi_rvalid	: in std_logic;
		m00_axi_rready	: out std_logic
	);
end myaxifullmaster_v1_0;

architecture arch_imp of myaxifullmaster_v1_0 is

	-- component declaration
	component myaxifullmaster_v1_0_S00_AXI is
		generic (
			C_S_AXI_DATA_WIDTH	: integer	:= 32;
			C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (

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

			S_AXI_ACLK	: in std_logic;
			S_AXI_ARESETN	: in std_logic;
			S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
			S_AXI_AWVALID	: in std_logic;
			S_AXI_AWREADY	: out std_logic;
			S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
			S_AXI_WVALID	: in std_logic;
			S_AXI_WREADY	: out std_logic;
			S_AXI_BRESP	: out std_logic_vector(1 downto 0);
			S_AXI_BVALID	: out std_logic;
			S_AXI_BREADY	: in std_logic;
			S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
			S_AXI_ARVALID	: in std_logic;
			S_AXI_ARREADY	: out std_logic;
			S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_RRESP	: out std_logic_vector(1 downto 0);
			S_AXI_RVALID	: out std_logic;
			S_AXI_RREADY	: in std_logic
		);
	end component myaxifullmaster_v1_0_S00_AXI;

	component myaxifullmaster_v1_0_M00_AXI is
		generic (
			C_M_AXI_BURST_LEN	: integer	:= 16;
			C_M_AXI_ID_WIDTH	: integer	:= 1;
			C_M_AXI_ADDR_WIDTH	: integer	:= 32;
			C_M_AXI_DATA_WIDTH	: integer	:= 32;
			C_M_AXI_AWUSER_WIDTH	: integer	:= 0;
			C_M_AXI_ARUSER_WIDTH	: integer	:= 0;
			C_M_AXI_WUSER_WIDTH	: integer	:= 0;
			C_M_AXI_RUSER_WIDTH	: integer	:= 0;
			C_M_AXI_BUSER_WIDTH	: integer	:= 0
		);
		port (

			mymaster_addr_inw : in std_logic_vector(31 downto 0);
			mymaster_addr_inr : in std_logic_vector(31 downto 0);

			mymaster_startw : in std_logic;
			mymaster_startr : in std_logic;
			mymaster_busyw  : out std_logic;
			mymaster_busyr  : out std_logic;
			mymaster_sensor : out std_logic_vector(31 downto 0);  -- For various debug signals

			mymaster_burstnb_inw : in std_logic_vector(31 downto 0);
			mymaster_burstnb_inr : in std_logic_vector(31 downto 0);

			mymaster_fifor_data : out std_logic_vector(31 downto 0);
			mymaster_fifor_en   : out std_logic;
			mymaster_fifor_cnt  : in std_logic_vector(15 downto 0);

			mymaster_fifow_data : in std_logic_vector(31 downto 0);
			mymaster_fifow_en   : out std_logic;
			mymaster_fifow_cnt  : in std_logic_vector(15 downto 0);

			M_AXI_ACLK	: in std_logic;
			M_AXI_ARESETN	: in std_logic;
			M_AXI_AWID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
			M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
			M_AXI_AWLEN	: out std_logic_vector(7 downto 0);
			M_AXI_AWSIZE	: out std_logic_vector(2 downto 0);
			M_AXI_AWBURST	: out std_logic_vector(1 downto 0);
			M_AXI_AWLOCK	: out std_logic;
			M_AXI_AWCACHE	: out std_logic_vector(3 downto 0);
			M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
			M_AXI_AWQOS	: out std_logic_vector(3 downto 0);
			M_AXI_AWUSER	: out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);
			M_AXI_AWVALID	: out std_logic;
			M_AXI_AWREADY	: in std_logic;
			M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
			M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
			M_AXI_WLAST	: out std_logic;
			M_AXI_WUSER	: out std_logic_vector(C_M_AXI_WUSER_WIDTH-1 downto 0);
			M_AXI_WVALID	: out std_logic;
			M_AXI_WREADY	: in std_logic;
			M_AXI_BID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
			M_AXI_BRESP	: in std_logic_vector(1 downto 0);
			M_AXI_BUSER	: in std_logic_vector(C_M_AXI_BUSER_WIDTH-1 downto 0);
			M_AXI_BVALID	: in std_logic;
			M_AXI_BREADY	: out std_logic;
			M_AXI_ARID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
			M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
			M_AXI_ARLEN	: out std_logic_vector(7 downto 0);
			M_AXI_ARSIZE	: out std_logic_vector(2 downto 0);
			M_AXI_ARBURST	: out std_logic_vector(1 downto 0);
			M_AXI_ARLOCK	: out std_logic;
			M_AXI_ARCACHE	: out std_logic_vector(3 downto 0);
			M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
			M_AXI_ARQOS	: out std_logic_vector(3 downto 0);
			M_AXI_ARUSER	: out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);
			M_AXI_ARVALID	: out std_logic;
			M_AXI_ARREADY	: in std_logic;
			M_AXI_RID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
			M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
			M_AXI_RRESP	: in std_logic_vector(1 downto 0);
			M_AXI_RLAST	: in std_logic;
			M_AXI_RUSER	: in std_logic_vector(C_M_AXI_RUSER_WIDTH-1 downto 0);
			M_AXI_RVALID	: in std_logic;
			M_AXI_RREADY	: out std_logic
		);
	end component myaxifullmaster_v1_0_M00_AXI;

	signal mymaster_addr_inw : std_logic_vector(31 downto 0);
	signal mymaster_addr_inr : std_logic_vector(31 downto 0);

	signal mymaster_burstnb_inw : std_logic_vector(31 downto 0);
	signal mymaster_burstnb_inr : std_logic_vector(31 downto 0);

	signal mymaster_startw   : std_logic;
	signal mymaster_startr   : std_logic;
	signal mymaster_busyw    : std_logic;
	signal mymaster_busyr    : std_logic;
	signal mymaster_sensor   : std_logic_vector(31 downto 0);

	signal mymaster_fifor_data : std_logic_vector(31 downto 0);
	signal mymaster_fifor_en   : std_logic;
	signal mymaster_fifor_cnt  : std_logic_vector(15 downto 0);

	signal mymaster_fifow_data : std_logic_vector(31 downto 0);
	signal mymaster_fifow_en   : std_logic;
	signal mymaster_fifow_cnt  : std_logic_vector(15 downto 0);

begin

-- Instantiation of Axi Bus Interface S00_AXI
myaxifullmaster_v1_0_S00_AXI_inst : myaxifullmaster_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (

		mymaster_addr_inw => mymaster_addr_inw,
		mymaster_addr_inr => mymaster_addr_inr,

		mymaster_burstnb_inw => mymaster_burstnb_inw,
		mymaster_burstnb_inr => mymaster_burstnb_inr,

		mymaster_startw => mymaster_startw,
		mymaster_startr => mymaster_startr,
		mymaster_busyw  => mymaster_busyw,
		mymaster_busyr  => mymaster_busyr,
		mymaster_sensor => mymaster_sensor,

		mymaster_fifor_data => mymaster_fifor_data,
		mymaster_fifor_en   => mymaster_fifor_en,
		mymaster_fifor_cnt  => mymaster_fifor_cnt,

		mymaster_fifow_data => mymaster_fifow_data,
		mymaster_fifow_en   => mymaster_fifow_en,
		mymaster_fifow_cnt  => mymaster_fifow_cnt,

		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

-- Instantiation of Axi Bus Interface M00_AXI
myaxifullmaster_v1_0_M00_AXI_inst : myaxifullmaster_v1_0_M00_AXI
	generic map (
		C_M_AXI_BURST_LEN	=> C_M00_AXI_BURST_LEN,
		C_M_AXI_ID_WIDTH	=> C_M00_AXI_ID_WIDTH,
		C_M_AXI_ADDR_WIDTH	=> C_M00_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_M00_AXI_DATA_WIDTH,
		C_M_AXI_AWUSER_WIDTH	=> C_M00_AXI_AWUSER_WIDTH,
		C_M_AXI_ARUSER_WIDTH	=> C_M00_AXI_ARUSER_WIDTH,
		C_M_AXI_WUSER_WIDTH	=> C_M00_AXI_WUSER_WIDTH,
		C_M_AXI_RUSER_WIDTH	=> C_M00_AXI_RUSER_WIDTH,
		C_M_AXI_BUSER_WIDTH	=> C_M00_AXI_BUSER_WIDTH
	)
	port map (

		mymaster_addr_inw => mymaster_addr_inw,
		mymaster_addr_inr => mymaster_addr_inr,

		mymaster_burstnb_inw => mymaster_burstnb_inw,
		mymaster_burstnb_inr => mymaster_burstnb_inr,

		mymaster_startw => mymaster_startw,
		mymaster_startr => mymaster_startr,
		mymaster_busyw  => mymaster_busyw,
		mymaster_busyr  => mymaster_busyr,
		mymaster_sensor => mymaster_sensor,

		mymaster_fifor_data => mymaster_fifor_data,
		mymaster_fifor_en   => mymaster_fifor_en,
		mymaster_fifor_cnt  => mymaster_fifor_cnt,

		mymaster_fifow_data => mymaster_fifow_data,
		mymaster_fifow_en   => mymaster_fifow_en,
		mymaster_fifow_cnt  => mymaster_fifow_cnt,

		M_AXI_ACLK	=> m00_axi_aclk,
		M_AXI_ARESETN	=> m00_axi_aresetn,
		M_AXI_AWID	=> m00_axi_awid,
		M_AXI_AWADDR	=> m00_axi_awaddr,
		M_AXI_AWLEN	=> m00_axi_awlen,
		M_AXI_AWSIZE	=> m00_axi_awsize,
		M_AXI_AWBURST	=> m00_axi_awburst,
		M_AXI_AWLOCK	=> m00_axi_awlock,
		M_AXI_AWCACHE	=> m00_axi_awcache,
		M_AXI_AWPROT	=> m00_axi_awprot,
		M_AXI_AWQOS	=> m00_axi_awqos,
		M_AXI_AWUSER	=> m00_axi_awuser,
		M_AXI_AWVALID	=> m00_axi_awvalid,
		M_AXI_AWREADY	=> m00_axi_awready,
		M_AXI_WDATA	=> m00_axi_wdata,
		M_AXI_WSTRB	=> m00_axi_wstrb,
		M_AXI_WLAST	=> m00_axi_wlast,
		M_AXI_WUSER	=> m00_axi_wuser,
		M_AXI_WVALID	=> m00_axi_wvalid,
		M_AXI_WREADY	=> m00_axi_wready,
		M_AXI_BID	=> m00_axi_bid,
		M_AXI_BRESP	=> m00_axi_bresp,
		M_AXI_BUSER	=> m00_axi_buser,
		M_AXI_BVALID	=> m00_axi_bvalid,
		M_AXI_BREADY	=> m00_axi_bready,
		M_AXI_ARID	=> m00_axi_arid,
		M_AXI_ARADDR	=> m00_axi_araddr,
		M_AXI_ARLEN	=> m00_axi_arlen,
		M_AXI_ARSIZE	=> m00_axi_arsize,
		M_AXI_ARBURST	=> m00_axi_arburst,
		M_AXI_ARLOCK	=> m00_axi_arlock,
		M_AXI_ARCACHE	=> m00_axi_arcache,
		M_AXI_ARPROT	=> m00_axi_arprot,
		M_AXI_ARQOS	=> m00_axi_arqos,
		M_AXI_ARUSER	=> m00_axi_aruser,
		M_AXI_ARVALID	=> m00_axi_arvalid,
		M_AXI_ARREADY	=> m00_axi_arready,
		M_AXI_RID	=> m00_axi_rid,
		M_AXI_RDATA	=> m00_axi_rdata,
		M_AXI_RRESP	=> m00_axi_rresp,
		M_AXI_RLAST	=> m00_axi_rlast,
		M_AXI_RUSER	=> m00_axi_ruser,
		M_AXI_RVALID	=> m00_axi_rvalid,
		M_AXI_RREADY	=> m00_axi_rready
	);

	-- Add user logic here

	-- User logic ends

end arch_imp;
