---
description: Scans the entire solution to generate a PROJECT_SUMMARY.md with skills, architecture, and resume bullets.
---

Act as a Senior .NET Technical Lead and Resume Writer. 

Your goal is to analyze the entire solution in this workspace (including all projects found in the .sln or folder structure) and generate a single Markdown file named `PROJECT_SUMMARY.md`.

For EACH project found in the codebase, create a section using the exact structure below. You must infer the functionality, architecture, and skills by reading the `.csproj` files (for NuGet packages/versions), `Startup.cs`/`Program.cs` (for middleware and DI), and the folder structure (to determine patterns like Clean Architecture, Repository Pattern, etc.).

Format each project using this template:

# [Project Name] - Technical Summary

## Project Overview
[Write a 2-3 sentence executive summary of what this specific project does, its business purpose, and who it serves.]

## Key Technologies & Frameworks
### Core Technologies
- [List .NET version, Framework type (Web API, Blazor, Console, Worker), and primary languages]

### Key Libraries & Tools
- **[Library Name]** - [Brief description of how it is used in *this* code. E.g., "Hangfire - Used for background job processing of loan imports"]
- [Analyze .csproj references to fill this list. Look for things like AutoMapper, FluentValidation, MediatR, Serilog, Dapper, EF Core, etc.]

### External Integrations & Cloud
- [List Azure services or 3rd party APIs identified in the code. E.g., Azure Blob Storage, Azure AD, SendGrid, etc.]

## Architecture & Design Patterns
### Project Structure
- [Describe the architecture. E.g., Clean Architecture, N-Layer, Microservices]
- [List specific patterns found. E.g., Repository Pattern, Factory Pattern, CQRS, Mediator Pattern]

### Key Components
1. **[Component/Folder Name]** - [Description of what this layer does]
2. **[Component/Folder Name]** - [Description]

## Core Functionality & Features
[Analyze Controllers, Managers, and Services to list the actual features]
### 1. [Feature Name, e.g., Data Import]
- [Detail 1: e.g., Supports CSV and Excel via CsvHelper]
- [Detail 2: e.g., Validates data using FluentValidation rules]

### 2. [Feature Name, e.g., Reporting]
- [Detail 1]
- [Detail 2]

## DevOps & Quality
- [Analyze if there are Dockerfiles, Azure Pipelines (yaml), or Unit Tests]
- [List Testing frameworks used (xUnit, NUnit, Moq)]

## Domain Knowledge
[Based on the variable names and entities (e.g., Loan, Patient, Order), what business domain is this?]

---

## Suggested Resume Bullet Points
[Generate 3-5 high-impact, senior-level bullet points for a resume based strictly on this code. Focus on: "Architected...", "Designed...", "Implemented...", "Optimized..."]
- [Bullet 1]
- [Bullet 2]
- [Bullet 3]

***
(Repeat the above structure for the next project in the solution)