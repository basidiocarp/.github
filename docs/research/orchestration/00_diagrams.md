
## High Level
```mermaid
flowchart LR
    A["Human (A)"] --> B["Planner (B1/B2)"]
    B --> V1["Decomposition Verify (V1)"]
    V1 --> C["Execution (C1/C2)"]
    C --> V2["Output Verify (V2)"]

    V2 -->|Pass| DONE["Done"]
    V2 -->|Fail| R["Repair"]
    R --> V3["Re-verify"]
    V3 -->|Pass| DONE
    V3 -->|Fail| ESC["Escalate"]

    ESC --> B
    ESC --> A
```
---

## Execution Pipeline
```mermaid
flowchart LR
    B2["Task Compiler"] --> V1["Decomposition Verify"]

    V1 -->|Valid| C1["Coordinator"]
    V1 -->|Invalid| B2

    C1 --> C2["Executor"]
    C2 --> C1

    C1 --> V2["Output Verify"]

    V2 -->|Pass| DONE["Done"]
    V2 -->|Fail| DECIDE{"Repair?"}

    DECIDE -->|Yes| R["Repair"]
    DECIDE -->|No| ESC["Escalate"]

    R --> V3["Re-verify"]
    V3 -->|Pass| DONE
    V3 -->|Fail| ESC
```
---

## Control Plane
```mermaid
flowchart LR
    O["Orchestrator"] --> Q["Task Queue"]

    Q --> C1["Coordinator"]
    C1 --> Q

    O --> V1["Decomp Verify"]
    O --> V2["Output Verify"]
    O --> R["Repair"]

    O --> ESC["Escalation Router"]

    ESC --> B2["Recompile"]
    ESC --> B1["Replan"]
    ESC --> A["Human"]
```

---

## Feedback Loop
```mermaid
flowchart LR
    EXEC["Execution Results"]
    VER["Verification Results"]
    REP["Repair Logs"]
    ESC["Escalations"]

    EXEC --> OBS["Observability"]
    VER --> OBS
    REP --> OBS
    ESC --> OBS

    OBS --> LEARN["Learning Loop"]

    LEARN --> B1["Planner"]
    LEARN --> B2["Compiler"]
    LEARN --> ROUTE["Routing Logic"]
```
---

## Swimlanes
### Swimlane A
```mermaid
flowchart LR
    subgraph A["Human"]
        A1["Spec"]
    end

    subgraph B["Planning"]
        B1["Plan"]
        B2["Compile"]
    end

    subgraph V["Verification"]
        V1["Decomp Check"]
        V2["Output Check"]
        V3["Re-check"]
    end

    subgraph C["Execution"]
        C1["Coordinate"]
        C2["Execute"]
    end

    subgraph R["Repair"]
        R1["Fix"]
    end

    A1 --> B1 --> B2 --> V1 --> C1 --> C2 --> C1 --> V2
    V2 -->|fail| R1 --> V3
```

### Swimlanes B
```mermaid
flowchart LR

    subgraph L1["Human Lane"]
        A1["Author spec<br/>constraints<br/>acceptance criteria"]
    end

    subgraph L2["Planning Lane"]
        B1["B1 Strategic Planner<br/>build task graph"]
        B2["B2 Task Compiler<br/>compile task packets<br/>assign model tier"]
    end

    subgraph L3["Verification Lane"]
        V1["V1 Decomposition Verify"]
        V2["V2 Output Verify"]
        V3["V3 Re-verify"]
    end

    subgraph L4["Execution Lane"]
        O["Orchestrator / Scheduler"]
        C1["C1 Medium Coordinator"]
        C2["C2 Small Executor"]
    end

    subgraph L5["Repair Lane"]
        R["Repair Agent"]
    end

    subgraph L6["Learning Lane"]
        OBS["Observability / Metrics"]
        FB["Learning Feedback Loop"]
    end

    A1 --> B1 --> B2 --> V1

    V1 -->|valid| O
    V1 -->|invalid| B2

    O --> C1
    C1 --> C2
    C2 --> C1
    C1 --> V2

    V2 -->|pass| DONE["Done"]
    V2 -->|fail, repair allowed| R
    V2 -->|fail, no repair| ESC["Escalate / Recompile / Replan"]

    R --> V3
    V3 -->|pass| DONE
    V3 -->|fail| ESC

    ESC --> O
    O --> B2
    O --> B1
    O --> A1

    V1 -.-> OBS
    V2 -.-> OBS
    V3 -.-> OBS
    C1 -.-> OBS
    C2 -.-> OBS
    O  -.-> OBS
    R  -.-> OBS

    OBS --> FB
    FB --> B1
    FB --> B2
    FB --> O
```

### Swimlanes C
```mermaid
flowchart TB

    subgraph Human["Human"]
        A["Spec Authority"]
    end

    subgraph Planning["Planning"]
        B1["Strategic Planner"]
        B2["Task Compiler"]
    end

    subgraph Verification["Verification"]
        V1["Decomposition Verifier"]
        V2["Output Verifier"]
        V3["Re-verifier"]
    end

    subgraph Execution["Execution"]
        O["Orchestrator"]
        C1["Medium Coordinator"]
        C2["Small Executor"]
    end

    subgraph Repair["Repair"]
        R["Repair Agent"]
    end

    subgraph Feedback["Feedback"]
        OBS["Observability"]
        L["Learning Loop"]
    end

    A --> B1 --> B2 --> V1
    V1 -->|approved| O
    V1 -->|rejected| B2

    O --> C1 --> C2 --> C1 --> V2
    V2 -->|pass| D["Done"]
    V2 -->|fail| X{"Repair allowed?"}

    X -->|yes| R --> V3
    X -->|no| E["Escalate"]

    V3 -->|pass| D
    V3 -->|fail| E

    E --> O
    O --> B2
    O --> B1
    O --> A

    O --> OBS
    V1 --> OBS
    V2 --> OBS
    V3 --> OBS
    R --> OBS
    C1 --> OBS
    C2 --> OBS

    OBS --> L
    L --> B1
    L --> B2
    L --> O
```

---

## Sequence Diagrams
```mermaid
sequenceDiagram
    autonumber

    actor A as Human Spec Authority
    participant B1 as B1 Strategic Planner
    participant B2 as B2 Task Compiler
    participant V1 as V1 Decomposition Verifier
    participant O as Orchestrator
    participant C1 as C1 Medium Coordinator
    participant C2 as C2 Small Executor
    participant V2 as V2 Output Verifier
    participant R as Repair Agent
    participant V3 as V3 Re-verifier
    participant OBS as Observability / Feedback

    A->>B1: Submit spec, constraints, acceptance criteria
    B1->>B2: Build task graph and planning intent
    B2->>V1: Emit compiled task packets
    V1->>OBS: Record decomposition validation result

    alt Decomposition invalid
        V1-->>B2: Reject packet (scope/context/dependency issue)
        B2->>B1: Request replan or recompilation
        B1-->>A: Escalate only if spec is ambiguous
    else Decomposition valid
        V1->>O: Approve task packet
        O->>C1: Assign parent task / subtree
        C1->>C2: Dispatch bounded subtask
        C2-->>C1: Return execution result
        C1->>V2: Submit aggregated result + evidence
        V2->>OBS: Record output verification result

        alt Output valid
            V2->>O: Mark task complete
            O->>OBS: Emit success metrics
        else Output invalid
            alt Repair allowed
                V2->>R: Send localized repair request
                R->>V3: Submit repaired output
                V3->>OBS: Record re-verification result

                alt Repair valid
                    V3->>O: Mark repaired task complete
                    O->>OBS: Emit repaired-success metrics
                else Repair invalid
                    V3->>O: Escalate failure
                    O->>B2: Recompile or reroute task
                    O->>OBS: Emit escalation metrics
                end
            else Repair not allowed
                V2->>O: Escalate failure
                O->>B2: Recompile or reroute task
                O->>OBS: Emit escalation metrics
            end
        end
    end

    OBS-->>B1: Feedback on decomposition quality
    OBS-->>B2: Feedback on task sizing / context budgets
    OBS-->>O: Feedback on routing / retry policy
```

---


```mermaid
flowchart TD
    A["A: Human Spec Authority<br/>Intent, constraints, acceptance criteria"]

    B1["B1: Strategic Planner<br/>Builds task graph, dependencies, scope"]
    B2["B2: Task Compiler / Context Budgeter<br/>Compiles task packets, assigns tier, enforces contracts"]

    V1["V1: Decomposition Verifier<br/>Checks scope, dependencies, context fit, contract completeness"]

    C1["C1: Medium Coordinators<br/>Own subtree, delegate, aggregate, first-pass review"]
    C2["C2: Small Executors<br/>Perform narrow bounded work"]

    V2["V2: Output Verifier<br/>Validates outputs against contract"]
    R["R: Repair Agents<br/>Apply localized fixes only"]
    V3["V3: Re-verifier<br/>Independently validates repaired outputs"]

    O["Orchestrator / Scheduler<br/>Queues, routing, state transitions, retries, escalation"]
    Q["Task / Message Queues"]
    OBS["Observability / Metrics<br/>Tracing, costs, latency, failures"]
    L["Learning Feedback Loop<br/>Policy tuning, routing updates, task sizing"]

    E1{"Spec ambiguity?"}
    E2{"Decomposition valid?"}
    E3{"Execution complete?"}
    E4{"Output valid?"}
    E5{"Repair allowed?"}
    E6{"Repair valid?"}

    A --> B1
    B1 --> B2
    B2 --> V1
    V1 --> E2

    E2 -- "Yes" --> O
    E2 -- "No" --> B2
    B1 --> E1
    E1 -- "Yes" --> A
    E1 -- "No" --> B2

    O --> Q
    Q --> C1
    C1 --> C2
    C2 --> C1
    C1 --> E3

    E3 -- "No: retryable" --> O
    E3 -- "No: non-retryable" --> V2
    E3 -- "Yes" --> V2

    V2 --> E4
    E4 -- "Yes" --> DONE["DONE"]
    E4 -- "No" --> E5

    E5 -- "Yes" --> R
    E5 -- "No" --> ESC["ESCALATE<br/>to B2 / B1 / A depending on failure type"]

    R --> V3
    V3 --> E6
    E6 -- "Yes" --> DONE
    E6 -- "No" --> ESC

    ESC --> O
    O --> B2
    O --> B1
    O --> A

    %% Observability hooks
    A -. emits spec metadata .-> OBS
    B1 -. planning metrics .-> OBS
    B2 -. task sizing / routing data .-> OBS
    V1 -. decomposition failures .-> OBS
    C1 -. coordination / retry stats .-> OBS
    C2 -. execution outputs .-> OBS
    V2 -. verification outcomes .-> OBS
    R -. repair metadata .-> OBS
    V3 -. re-verification results .-> OBS
    O -. queue / latency / state transitions .-> OBS

    %% Learning loop
    OBS --> L
    L --> B1
    L --> B2
    L --> O
    L --> V1
    L --> V2

    %% Styling
    classDef human fill:#f9f,stroke:#333,stroke-width:1px;
    classDef planner fill:#bbf,stroke:#333,stroke-width:1px;
    classDef verify fill:#bfb,stroke:#333,stroke-width:1px;
    classDef exec fill:#ffd,stroke:#333,stroke-width:1px;
    classDef repair fill:#fdd,stroke:#333,stroke-width:1px;
    classDef infra fill:#ddd,stroke:#333,stroke-width:1px;

    class A human;
    class B1,B2 planner;
    class V1,V2,V3 verify;
    class C1,C2 exec;
    class R repair;
    class O,Q,OBS,L infra;
```
---

```mermaid
flowchart LR
    A["Human Spec Authority"]
    B1["Strategic Planner"]
    B2["Task Compiler"]
    V1["Decomposition Verifier"]
    C1["Medium Coordinators"]
    C2["Small Executors"]
    V2["Output Verifier"]
    R["Repair Agents"]
    V3["Re-verifier"]
    O["Orchestrator"]
    L["Learning Loop"]

    A --> B1 --> B2 --> V1 --> O --> C1 --> C2 --> C1 --> V2
    V2 -- pass --> DONE["Done"]
    V2 -- fail --> R --> V3
    V3 -- pass --> DONE
    V3 -- fail --> O

    O -- recompile --> B2
    O -- replan --> B1
    O -- escalate --> A

    B1 --> L
    B2 --> L
    V1 --> L
    V2 --> L
    R --> L
    O --> L
    L --> B1
    L --> B2
    L --> O
```
