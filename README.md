# dauphin
VHDL code for the neural network on FPGA

Architecture:
* `./` : contains components
  * recode : recode stage
  * fsm : controls neurons
  * neuron : basic unit
  * nnlayer : contains a neuron level and a fsm to control them
  * distribuf : component to dispatch data efficiently
  * circbuf_fast : FIFO
  * myaxifullmaster_v1_00 : top file
  * myaxifullmaster_v1_00_S00_AXI : AXI slave, contains all elements of neural net
  * myaxifullmaster_v1_00_M00_AXI : AXI master
* `./test_bench/ : contains some test benches

