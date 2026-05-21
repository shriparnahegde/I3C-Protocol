#MIPI I3C Master Controller

This repository houses the complete RTL implementation and protocol-level verification of a Modular MIPI I3C Master Controller. As modern System-on-Chip (SoC) architectures demand higher sensor density, legacy protocols like I2C and SPI often struggle with bandwidth limitations and high pin counts. This project provides a scalable, high-speed, and power-efficient hardware solution tailored for next-generation embedded systems.

Designed with a strong emphasis on maintainable VLSI practices, the architecture avoids the pitfalls of monolithic state machines. Instead, it utilizes a strictly layered, synchronous Finite State Machine (FSM) framework. This modular methodology cleanly decouples the command interpretation layer from the physical bit-level transmission engine. The result is a synthesizable, deterministically timed controller that easily scales for future complex SoC integration.

Key Hardware Features:

1.Dynamic Physical Layer: Precise, run-time transitions between Open-Drain (for arbitration) and Push-Pull (for high-speed data) signaling without bus contention.

2.Dynamic Address Assignment (ENTDAA): Automated multi-target arbitration and dynamic address allocation, eliminating legacy static address conflicts.

3.High Data Rate Double Data Rate (HDR-DDR): A dual-edge clock transmission engine that effectively doubles data throughput while utilizing a single synchronous clock domain.

4.Common Command Codes (CCC): Implementation of broadcast and directed administrative commands for centralized bus management.

5.Legacy I2C Coexistence: Designed to safely manage high-speed I3C traffic on a mixed bus without triggering false starts in legacy targets.

Verification Methodology-
The design’s robustness is proven through cycle-accurate, protocol-level verification using SystemVerilog testbenches executed within the Cadence Xcelium environment. The simulation strategy rigorously targets the most critical protocol transitions. It specifically validates the wired-AND bus physics during multi-target ENTDAA arbitration and ensures data setup and hold stability during HDR-DDR burst transmissions.

This project serves as a practical blueprint for transitioning theoretical MIPI specifications into synthesizable RTL. It is an excellent resource for those developing expertise in advanced serial protocols, dual-edge transmission logic, and modular hardware design.
