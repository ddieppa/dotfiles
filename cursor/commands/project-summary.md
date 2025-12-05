Act as a Principal Software Architect and Technical Writer. 

Your goal is to generate a comprehensive technical documentation file named `PROJECT_SUMMARY.md`. 

You must perform this in two steps:
1. **Discovery:** Scan the codebase for Solution files (`.sln`) or Root Frontend configurations (`package.json`, `vite.config.ts`).
2. **Analysis:** For *each* Solution or Root Folder found, generate a "Solution Architecture" section, followed by the detailed "Project Breakdowns".

Use the following strict Markdown structure for your output:

---

# 🏗️ SOLUTION: [Solution Name / Root Folder Name] 

## 1. Executive System Analysis
[Synthesize the purpose of this entire solution. What business problem does it solve? How do the projects inside interact?]

## 2. System Architecture & Design
- **Architecture Style:** [e.g., N-Tier Monolith, Microservices, Clean Architecture, Modular Monolith]
- **Design Patterns (Solution-Level):** [e.g., Dependency Injection (Unity/ServiceCollection), Repository Pattern, Unit of Work, CQRS]
- **Data Flow:** [Describe how data moves. E.g., Frontend -> Web API -> Business Layer -> Data Layer -> SQL]

## 3. Global Tech Stack
- **Frameworks:** [Highest common denominator, e.g., .NET Framework 4.8, .NET 8, React 18]
- **Data Stores:** [SQL Server, Redis, CosmosDB]
- **Messaging/Async:** [Service Bus, Hangfire, Kafka]
- **Cross-Cutting Concerns:** [Auth (Identity/OAuth), Logging (Serilog), Resiliency (Polly)]

---

## 📂 DETAILED PROJECT BREAKDOWNS

(Loop through every project contained in this solution and provide the following details for each)

### 🔹 [Project Name] - Technical Summary

**Project Overview**
[2-3 sentences on what this specific project does within the larger system.]

**Key Technologies**
- [List specific frameworks/libraries used in this specific project based on .csproj/package.json]

**Architecture & Components**
- **Layer:** [e.g., Data Access, Presentation, Core Business Logic]
- **Key Components:** [List Managers, Controllers, or Services found here]

**Domain Knowledge**
- [Entities and Business Rules handled here. e.g., "Handles Patient Admission logic"]

**Suggested Resume Bullets**
- [Create 2 senior-level bullets based on the code in this project]

---
(End of Project Loop)
(If another .sln is found, repeat the entire structure starting from "SOLUTION: [Name]")