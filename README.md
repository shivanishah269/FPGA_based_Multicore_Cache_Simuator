# Cache-accel: FPGA Accelerated Multi-Core Cache Simulator
Designing Parameterized cache simulator with complete hierarchy of cache memory in single core and multi core processors on FPGA which can be partially reconfigured to include prefetching.

I/O of Simulator:
Input: Trace File
Output: Hit and Miss Metric and Latency Metric dumped in file

Board used: Zedboard - Zynq Architecture 
PL - Cache Architecture
PS - To send the Input files and receive the Output file

We run a set of SPEC 2017 benchmarks on Cache-accel and find that it can run nearly 7x and 11.5x faster (on an average) on a single-core framework and 2.61x and 5.33x faster (on an average) on multi-core framework as compared to ChampSim and Snipersim to generate hit/miss rates for several parallel configurations. 

Publications:

1. [FPGA Accelerated Parameterized Cache Simulator](https://ieeexplore.ieee.org/abstract/document/9424272)
2. [Cache-accel: FPGA Accelerated Cache Simulator with Partially Reconfigurable Prefetcher](https://ieeexplore.ieee.org/abstract/document/9556421/)

