# Roles & Responsibilities

## A — Human Spec Authority
- Defines intent, constraints, priorities
- Produces structured specs
- Avoids iterative clarification loops

## B1 — Strategic Planner
- Builds task graph
- Defines dependencies and scope
- Assigns capability requirements

## B2 — Task Compiler
- Converts tasks into execution packets
- Applies context budgets
- Enforces schemas

## V1 — Decomposition Verifier
- Validates task structure
- Checks model fit and dependencies

## C1 — Medium Coordinators
- Manage subtasks
- Delegate to small agents
- Aggregate results

## C2 — Small Executors
- Execute narrow tasks
- Stateless and deterministic

## V2 — Output Verifier
- Validates execution against contract

## R — Repair Agents
- Fix localized failures
- Must emit repair metadata

## V3 — Re-verifier
- Independently validates repaired outputs
