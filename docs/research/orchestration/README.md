# Multi-Agent Orchestration System

## Overview
This repository contains a contract-driven, hierarchical multi-agent orchestration system designed for:
- scalable task decomposition
- reliable execution
- explicit verification and repair
- continuous improvement via feedback loops

---

## Document Index

### Authority
- [RESET-AUTHORITY.md](./RESET-AUTHORITY.md) — Authoritative ownership model, Hymenium as single orchestration authority, Canopy as coordination ledger and operator surface, runtime role names

### Core Architecture
- 01_overview.md
- 02_roles.md
- 03_architecture.md

### Execution Model
- 08_execution_protocol.md
- 14_orchestrator_state_machine.md

### Contracts & Interfaces
- 04_contracts.md
- 10_agent_interfaces.md
- 15_message_schemas.md

### Validation & Routing
- 05_routing.md
- 06_invariants.md
- 09_retry_and_repair_policy.md

### System Optimization
- 11_capability_profiles.md
- 12_cost_and_latency_model.md
- 07_observability.md

### Learning System
- 13_learning_feedback_loop.md

### Implementation
- 16_reference_implementation.md

---

## Key Concepts

- Contract-first execution
- Separation of verification and repair
- Capability-based routing
- Asynchronous, queue-driven pipeline
- Typed failure handling

---

## Getting Started

1. Read architecture (01–03)
2. Understand execution model (08, 14)
3. Review contracts (04, 10, 15)
4. Review routing + retry (05, 09)
5. Review implementation (16)

---

## Design Philosophy

The system prioritizes:
1. correctness
2. debuggability
3. scalability
4. cost efficiency

