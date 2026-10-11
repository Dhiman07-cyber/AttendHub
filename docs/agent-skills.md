# AttendHub — Engineering Skill Inventory

This document catalogs the active specialist skills configured in `.agents/skills/` for the AttendHub project.

---

## 1. Installed Skill Inventory

| Skill | Source Repository | Authority Level | Primary Purpose & Triggers | Overlap / Boundaries |
|---|---|---|---|---|
| `dart-add-unit-test` | `flutter/agent-plugins` | Tier 1 (Official) | Writing unit tests for pure Dart logic, state classes, models, and calculation formulas using `package:test`. | Applies to pure Dart code and unit testing. |
| `dart-run-static-analysis` | `flutter/agent-plugins` | Tier 1 (Official) | Executing `dart analyze` and `dart fix --apply` to detect and fix lint warnings. | Static analysis and code quality. |
| `flutter-add-widget-test` | `flutter/agent-plugins` | Tier 1 (Official) | Writing component-level tests with `WidgetTester` to verify UI rendering and user interactions. | Tests widget tree, input taps, and animations. |
| `flutter-apply-architecture-best-practices` | `flutter/agent-plugins` | Tier 1 (Official) | Structuring Flutter application layers (Presentation, State/Logic, Data/API) with Riverpod. | Ensures feature-first clean architecture without UI business logic. |
| `flutter-build-responsive-layout` | `flutter/agent-plugins` | Tier 1 (Official) | Designing adaptive layouts using `LayoutBuilder`, `MediaQuery`, and flexible containers. | Responsive screen adaptations. |
| `flutter-fix-layout-issues` | `flutter/agent-plugins` | Tier 1 (Official) | Diagnosing and resolving RenderFlex overflow, unbounded height, and constraints errors. | Layout debugging and box constraint resolution. |
| `fastapi-sqlalchemy-postgres` | Project-Local | Tier 1 (Official Guidance) | FastAPI async routers, SQLAlchemy 2.0 async queries, transaction boundaries, Alembic migrations. | Backend architecture and database integrity. |
| `owasp-security-audit` | Project-Local (OWASP ASVS 5.0.0) | Tier 1 (Security Standard) | Verifying authentication, password hashing, IDOR prevention, token management, and input validation. | Enforces security invariants across all endpoints. |
| `systematic-debugging` | `obra/superpowers` | Tier 2 (Process) | Root cause analysis: Observe → Reproduce → Isolate → Root Cause → Patch → Regression Test. | Process discipline for all bug fixing. |
| `test-driven-development` | `obra/superpowers` | Tier 2 (Process) | Writing failing tests before implementing feature additions or bug fixes. | Engineering workflow discipline. |
| `verification-before-completion` | `obra/superpowers` | Tier 2 (Process) | Enforcing verification commands (`pytest`, `flutter test`, `dart analyze`) before claiming success. | Eliminates unsubstantiated claims. |
| `writing-plans` | `obra/superpowers` | Tier 2 (Process) | Structuring multi-step engineering implementation plans before modifying code. | Planning discipline before executing changes. |
| `supabase` | `supabase/agent-skills` | Tier 1 (Official) | Managing Supabase database, Auth, RLS, Storage, edge functions, MCP workflows, and client integrations. | Primary authority for Supabase platform features. |
| `supabase-postgres-best-practices` | `supabase/agent-skills` | Tier 1 (Official) | Postgres schema design, foreign key indexing, query optimization, RLS policies, connection pooling. | Primary authority for Postgres performance & schema design. |

---

## 2. Guidance Hierarchy

When resolving conflicts between recommendations:

```text
Current Official Framework / Language Documentation (Flutter, Dart, FastAPI, SQLAlchemy 2.0)
                           ↓
Current Official Project Guidance & Invariants (context.md, design.md, AGENTS.md)
                           ↓
Authoritative Security Standards (OWASP ASVS 5.0.0, OWASP API Security Top 10)
                           ↓
Selected Specialist Skills (.agents/skills/*)
                           ↓
Agent Memory / Pre-training Assumptions
```
