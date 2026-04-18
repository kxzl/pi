---
name: diagram
description: Generate architecture diagrams, flowcharts, and component maps of the codebase as SVG or PNG files using Mermaid. Use when asked to visualize project structure, data flow, module dependencies, class relationships, API call sequences, or system architecture. Can open the result in the live browser for immediate viewing.
---

# Architecture Diagram Generator

Generates editable Mermaid diagrams and renders them to SVG/PNG.

## Workflow

### 1. Explore the codebase

Use the available tools to understand the project before diagramming:
```bash
scc --format json /workspace          # language/file overview (if scc skill available)
find /workspace/src -name "*.ts" -o -name "*.js" | head -40
```
Read key entry points, index files, and any existing architecture docs.

### 2. Write the Mermaid diagram

Choose the right diagram type for what you're visualising (see types below), write the Mermaid source to a file:

```
write /workspace/diagram.mmd
<mermaid source here>
```

### 3. Render to SVG

```bash
mmdc -i /workspace/diagram.mmd -o /workspace/diagram.svg -p /usr/local/lib/mmdc-config.json
```

Or render to PNG:
```bash
mmdc -i /workspace/diagram.mmd -o /workspace/diagram.png -p /usr/local/lib/mmdc-config.json
```

### 4. View the result (optional)

Open in the live browser:
```bash
node /usr/local/lib/browser.js '{"action":"navigate","url":"file:///workspace/diagram.svg"}'
```

Or open Mermaid Live editor for interactive editing:
```bash
node /usr/local/lib/browser.js '{"action":"navigate","url":"https://mermaid.live"}'
```
(Then paste the `.mmd` file contents into the editor.)

## Diagram Types

### Flowchart — data flow, logic, processes

```mermaid
flowchart TD
    A[User Request] --> B{Auth?}
    B -->|Yes| C[Route Handler]
    B -->|No| D[401 Error]
    C --> E[Service Layer]
    E --> F[(Database)]
    F --> G[Response]
```

### Component / Architecture

```mermaid
flowchart LR
    subgraph Frontend
        UI[React UI]
        Store[Zustand Store]
    end
    subgraph Backend
        API[Express API]
        Worker[BullMQ Worker]
    end
    subgraph Storage
        DB[(PostgreSQL)]
        Cache[(Redis)]
    end

    UI --> API
    UI --> Store
    API --> DB
    API --> Cache
    Worker --> DB
    Worker --> Cache
```

### Class diagram — OOP relationships

```mermaid
classDiagram
    class UserService {
        +create(data) User
        +findById(id) User
        -db Database
    }
    class User {
        +id string
        +email string
        +createdAt Date
    }
    UserService --> User : returns
    UserService --> Database : uses
```

### Sequence diagram — API calls, message flows

```mermaid
sequenceDiagram
    participant C as Client
    participant A as API
    participant D as Database

    C->>A: POST /users
    A->>D: INSERT user
    D-->>A: user row
    A-->>C: 201 {id, email}
```

### ER diagram — database schema

```mermaid
erDiagram
    USER {
        uuid id PK
        string email
        timestamp created_at
    }
    POST {
        uuid id PK
        uuid user_id FK
        string title
        text body
    }
    USER ||--o{ POST : "writes"
```

### State diagram — lifecycle, state machines

```mermaid
stateDiagram-v2
    [*] --> Pending
    Pending --> Processing : job picked up
    Processing --> Done : success
    Processing --> Failed : error
    Failed --> Pending : retry
    Done --> [*]
```

## Tips

- **Start simple** — one diagram per concept is better than one huge diagram
- **Focus on boundaries** — show how major modules/services communicate, not internal details
- **Label edges** — arrows without labels are often meaningless
- **Use subgraphs** to group related components
- If mmdc fails, paste the `.mmd` source into `https://mermaid.live` via the browser skill for instant rendering
