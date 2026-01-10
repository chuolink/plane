# Plane Frontend Architecture Documentation

> Complete guide to understanding the Plane monorepo structure and frontend architecture

**Last Updated:** January 10, 2026
**Tech Stack:** React Router v7, TypeScript, Turborepo, PNPM Workspaces, Django API

---

## Table of Contents

1. [Overview](#overview)
2. [Monorepo Structure](#monorepo-structure)
3. [Frontend Applications](#frontend-applications)
4. [Shared Packages](#shared-packages)
5. [Build System](#build-system)
6. [How Everything Connects](#how-everything-connects)
7. [Development Workflow](#development-workflow)
8. [Adding New Features](#adding-new-features)
9. [Environment Configuration](#environment-configuration)
10. [Common Patterns](#common-patterns)

---

## Overview

Plane uses a **monorepo architecture** powered by:

- **PNPM Workspaces**: Package management and linking
- **Turborepo**: Build orchestration and caching
- **React Router v7**: Modern React framework with SSR support
- **TypeScript**: Type safety across all packages

### Why Monorepo?

- **Code Sharing**: UI components, types, and utilities shared across all apps
- **Type Safety**: Shared TypeScript definitions ensure consistency
- **Atomic Changes**: Update types/components once, affects all apps
- **Faster CI/CD**: Turborepo caches unchanged packages
- **Better DX**: One `pnpm install`, everything works

---

## Monorepo Structure

```
plane/
├── apps/                        # Independent applications
│   ├── web/                    # Main Plane app (port 3000)
│   ├── admin/                  # Admin/God Mode (port 3001)
│   ├── space/                  # Public workspace views (port 3002)
│   ├── live/                   # Real-time collaboration server (port 3100)
│   ├── api/                    # Django REST API backend (port 8000)
│   └── proxy/                  # Nginx proxy configuration
│
├── packages/                    # Shared libraries
│   ├── ui/                     # React UI components
│   ├── types/                  # TypeScript type definitions
│   ├── services/               # API service layer (axios)
│   ├── hooks/                  # Custom React hooks
│   ├── utils/                  # Utility functions
│   ├── constants/              # App-wide constants
│   ├── editor/                 # Rich text editor (TipTap)
│   ├── i18n/                   # Internationalization
│   ├── propel/                 # Animation utilities
│   ├── logger/                 # Logging utilities
│   ├── shared-state/           # State management (MobX)
│   ├── decorators/             # TypeScript decorators
│   ├── tailwind-config/        # Shared Tailwind config
│   └── typescript-config/      # Shared TS config
│
├── pnpm-workspace.yaml         # PNPM workspace configuration
├── turbo.json                  # Turborepo build configuration
├── package.json                # Root package.json
└── .env                        # Environment variables
```

---

## Frontend Applications

### 1. Web App (`apps/web/`)

**Primary application where users manage their projects**

```
apps/web/
├── app/
│   ├── routes/                 # React Router routes
│   │   ├── core/              # Core routes (workspace, projects, issues)
│   │   └── extended/          # Extended features
│   ├── layout.tsx             # Root layout
│   ├── provider.tsx           # App providers (auth, state, etc.)
│   └── routes.ts              # Route configuration
├── public/                     # Static assets
├── package.json
└── .env
```

**Key Features:**

- Workspace management
- Project/Issue tracking
- Cycles & Modules
- Analytics & Reports
- User settings
- Team collaboration

**Port:** 3000
**Base Path:** `/`
**Route Pattern:** File-based routing with React Router

**Example Routes:**

```typescript
// apps/web/app/routes.ts
const routes = [
  route("/workspace/:workspaceSlug", "./routes/workspace/page.tsx"),
  route("/workspace/:workspaceSlug/projects/:projectId", "./routes/project/page.tsx"),
  route("/workspace/:workspaceSlug/projects/:projectId/issues/:issueId", "./routes/issue/page.tsx"),
];
```

---

### 2. Admin App (`apps/admin/`)

**Instance administration panel (God Mode)**

```
apps/admin/
├── app/
│   ├── (all)/
│   │   ├── (home)/            # Dashboard
│   │   └── (dashboard)/       # Admin settings
│   │       ├── general/
│   │       ├── workspace/
│   │       ├── authentication/
│   │       ├── email/
│   │       ├── ai/
│   │       └── image/
│   ├── components/
│   └── routes.ts
├── package.json
└── .env
```

**Key Features:**

- Instance configuration
- Workspace management
- Authentication setup (OAuth, SAML)
- Email configuration
- AI/LLM settings
- Image storage settings

**Port:** 3001
**Base Path:** `/god-mode`
**Who Uses It:** Server administrators and instance owners

**Example Admin Routes:**

```typescript
// apps/admin/app/routes.ts
route("general", "./(all)/(dashboard)/general/page.tsx"),
route("authentication", "./(all)/(dashboard)/authentication/page.tsx"),
route("authentication/github", "./(all)/(dashboard)/authentication/github/page.tsx"),
```

---

### 3. Space App (`apps/space/`)

**Public-facing views for external stakeholders**

```
apps/space/
├── app/
│   ├── routes/
│   │   ├── auth/              # Public authentication
│   │   ├── issues/            # Public issue views
│   │   └── projects/          # Public project boards
│   ├── components/
│   └── routes.ts
├── package.json
└── .env
```

**Key Features:**

- Public project views
- Public issue boards
- Share project progress with clients
- No authentication required for viewers

**Port:** 3002
**Base Path:** `/spaces`
**SSR:** Server-side rendering enabled for SEO

---

### 4. Live Server (`apps/live/`)

**Real-time collaborative editing server**

```
apps/live/
├── src/
│   ├── server.ts              # WebSocket server
│   ├── extensions/            # Hocuspocus extensions
│   └── config/
├── package.json
└── .env
```

**Key Features:**

- Real-time document collaboration (Yjs CRDT)
- WebSocket connections
- Redis for multi-instance sync
- Database persistence

**Port:** 3100
**Base Path:** `/live`
**Tech:** Hocuspocus (Yjs WebSocket server), NOT a React app

**Important:** This is a Node.js WebSocket server, not a frontend app!

---

## Shared Packages

### Core Packages

#### `@plane/ui`

**Reusable React UI components**

```
packages/ui/
├── src/
│   ├── components/
│   │   ├── buttons/           # Button components
│   │   ├── dropdowns/         # Dropdown components
│   │   ├── modals/           # Modal components
│   │   ├── forms/            # Form inputs
│   │   └── ...
│   └── index.ts              # Barrel exports
├── package.json
└── tailwind.config.js
```

**Usage Example:**

```typescript
// In any app (web/admin/space)
import { Button, Input, Modal, Dropdown } from "@plane/ui";

export function MyComponent() {
  return (
    <Modal>
      <Input placeholder="Enter name" />
      <Button variant="primary">Save</Button>
    </Modal>
  );
}
```

---

#### `@plane/types`

**Shared TypeScript type definitions**

```typescript
// packages/types/src/project.d.ts
export interface IProject {
  id: string;
  name: string;
  description: string;
  workspace: string;
  created_at: string;
  updated_at: string;
}

export interface IIssue {
  id: string;
  project: string;
  name: string;
  state: string;
  priority: "urgent" | "high" | "medium" | "low" | "none";
  // ... more fields
}
```

**Usage:**

```typescript
import type { IProject, IIssue } from "@plane/types";

function ProjectCard({ project }: { project: IProject }) {
  // TypeScript knows all project fields
}
```

---

#### `@plane/services`

**API service layer with axios**

```
packages/services/
├── src/
│   ├── project.service.ts     # Project API calls
│   ├── issue.service.ts       # Issue API calls
│   ├── workspace.service.ts   # Workspace API calls
│   ├── auth.service.ts        # Authentication
│   └── index.ts
└── package.json
```

**Example Service:**

```typescript
// packages/services/src/project.service.ts
import { APIService } from "./api.service";
import type { IProject } from "@plane/types";

export class ProjectService extends APIService {
  async getProjects(workspaceSlug: string): Promise<IProject[]> {
    return this.get(`/api/workspaces/${workspaceSlug}/projects/`);
  }

  async createProject(workspaceSlug: string, data: Partial<IProject>): Promise<IProject> {
    return this.post(`/api/workspaces/${workspaceSlug}/projects/`, data);
  }
}
```

**Usage in Apps:**

```typescript
import { ProjectService } from "@plane/services";

const projectService = new ProjectService();

async function loadProjects() {
  const projects = await projectService.getProjects("my-workspace");
  console.log(projects);
}
```

---

#### `@plane/hooks`

**Custom React hooks**

```typescript
// packages/hooks/src/use-project.ts
import { useCallback } from "react";
import { ProjectService } from "@plane/services";
import type { IProject } from "@plane/types";

export const useProject = () => {
  const projectService = new ProjectService();

  const createProject = useCallback(async (data: Partial<IProject>) => {
    return await projectService.createProject(data);
  }, []);

  return { createProject };
};
```

**Usage:**

```typescript
import { useProject } from "@plane/hooks";

function CreateProjectForm() {
  const { createProject } = useProject();

  const handleSubmit = async (data) => {
    await createProject(data);
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```

---

#### `@plane/utils`

**Utility functions**

```typescript
// packages/utils/src/date.ts
export function formatDate(date: Date): string {
  return date.toLocaleDateString();
}

// packages/utils/src/string.ts
export function truncate(str: string, length: number): string {
  return str.length > length ? str.slice(0, length) + "..." : str;
}
```

---

#### `@plane/constants`

**App-wide constants**

```typescript
// packages/constants/src/issue.ts
export const ISSUE_PRIORITIES = {
  urgent: { label: "Urgent", color: "#ef4444" },
  high: { label: "High", color: "#f59e0b" },
  medium: { label: "Medium", color: "#10b981" },
  low: { label: "Low", color: "#3b82f6" },
  none: { label: "None", color: "#6b7280" },
};

export const ISSUE_STATES = {
  backlog: "Backlog",
  todo: "Todo",
  in_progress: "In Progress",
  done: "Done",
  cancelled: "Cancelled",
};
```

---

#### `@plane/editor`

**Rich text editor (TipTap-based)**

```
packages/editor/
├── src/
│   ├── core/                  # Editor core
│   ├── extensions/            # Custom TipTap extensions
│   ├── components/            # Editor UI components
│   └── index.ts
└── package.json
```

**Usage:**

```typescript
import { RichTextEditor } from "@plane/editor";

function IssueDescription() {
  return <RichTextEditor value={description} onChange={(html) => setDescription(html)} />;
}
```

---

#### `@plane/shared-state`

**State management with MobX**

```typescript
// packages/shared-state/src/stores/workspace.store.ts
import { makeObservable, observable, action } from "mobx";

export class WorkspaceStore {
  currentWorkspace: string | null = null;

  constructor() {
    makeObservable(this, {
      currentWorkspace: observable,
      setWorkspace: action,
    });
  }

  setWorkspace(slug: string) {
    this.currentWorkspace = slug;
  }
}
```

---

## Build System

### PNPM Workspaces

**Configuration:** `pnpm-workspace.yaml`

```yaml
packages:
  - apps/* # All apps (web, admin, space, live)
  - packages/* # All shared packages
  - "!apps/api" # Exclude Django backend
  - "!apps/proxy" # Exclude nginx proxy

catalog: # Centralized version management
  react: 18.3.1
  typescript: 5.8.3
  vite: 7.1.11
  # ... more shared versions
```

**How It Works:**

- Single `node_modules` at root
- Packages linked with symlinks
- `workspace:*` protocol for internal dependencies
- Shared version catalog for consistency

---

### Turborepo

**Configuration:** `turbo.json`

```json
{
  "tasks": {
    "dev": {
      "dependsOn": ["^build"], // Build dependencies first
      "persistent": true, // Keep running
      "cache": false
    },
    "build": {
      "dependsOn": ["^build"], // Build in dependency order
      "outputs": ["dist/**", "build/**"]
    },
    "check:types": {
      "dependsOn": ["^build"], // Type-check after build
      "outputs": []
    }
  }
}
```

**Execution Flow:**

```
$ pnpm dev

Step 1: Turborepo analyzes dependency graph
  ├─ @plane/types (no dependencies)
  ├─ @plane/constants (no dependencies)
  ├─ @plane/utils (depends on @plane/types)
  ├─ @plane/ui (depends on @plane/types, @plane/utils)
  ├─ @plane/services (depends on @plane/types)
  └─ @plane/hooks (depends on @plane/types, @plane/services)

Step 2: Build packages in parallel (where possible)
  [Building @plane/types...]
  [Building @plane/constants...]
  [Building @plane/utils...] (after @plane/types)
  [Building @plane/ui...] (after dependencies)

Step 3: Start all apps in parallel
  [Starting apps/web on port 3000...]
  [Starting apps/admin on port 3001...]
  [Starting apps/space on port 3002...]
  [Starting apps/live on port 3100...]
```

---

## How Everything Connects

### Dependency Graph

```
┌─────────────────────────────────────────────────────┐
│                  Frontend Apps                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │   Web    │  │  Admin   │  │  Space   │         │
│  │  :3000   │  │  :3001   │  │  :3002   │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       │             │              │                │
│       └─────────────┴──────────────┘                │
│                     │                               │
│                     ↓                               │
│       ┌─────────────────────────────┐              │
│       │   Shared Packages Layer     │              │
│       │                             │              │
│       │  ┌────────┐   ┌──────────┐ │              │
│       │  │   UI   │   │  Editor  │ │              │
│       │  └────────┘   └──────────┘ │              │
│       │                             │              │
│       │  ┌────────┐   ┌──────────┐ │              │
│       │  │ Hooks  │   │ Services │ │              │
│       │  └────────┘   └──────────┘ │              │
│       │                             │              │
│       │  ┌────────┐   ┌──────────┐ │              │
│       │  │ Types  │   │  Utils   │ │              │
│       │  └────────┘   └──────────┘ │              │
│       └─────────────────────────────┘              │
└─────────────────────────────────────────────────────┘
                        │
                        │ HTTP Requests (axios)
                        ↓
┌─────────────────────────────────────────────────────┐
│              Django REST API Backend                │
│                  localhost:8000                     │
│                                                     │
│  /api/workspaces/                                  │
│  /api/projects/                                    │
│  /api/issues/                                      │
│  /api/users/                                       │
│  /api/auth/                                        │
└─────────────────────────────────────────────────────┘
```

### Package Dependencies

**Example: How Web App Uses Packages**

```json
// apps/web/package.json
{
  "dependencies": {
    "@plane/ui": "workspace:*", // UI components
    "@plane/types": "workspace:*", // Type definitions
    "@plane/services": "workspace:*", // API services
    "@plane/hooks": "workspace:*", // React hooks
    "@plane/utils": "workspace:*", // Utilities
    "@plane/constants": "workspace:*", // Constants
    "@plane/editor": "workspace:*", // Rich text editor
    "@plane/i18n": "workspace:*", // i18n
    "@plane/shared-state": "workspace:*", // MobX stores
    "react": "18.3.1",
    "react-router": "7.9.5"
  }
}
```

**workspace:\*** tells PNPM to link to local packages in the monorepo.

---

### Real-World Data Flow Example

**Creating a new project:**

```typescript
// 1. User clicks "Create Project" in apps/web/app/routes/workspace/page.tsx
import { Button } from "@plane/ui";
import { useProject } from "@plane/hooks";
import type { IProject } from "@plane/types";

function WorkspacePage() {
  const { createProject } = useProject();

  const handleCreate = async () => {
    const newProject: Partial<IProject> = {
      name: "My Project",
      description: "Project description",
    };

    // 2. useProject hook calls ProjectService
    await createProject("my-workspace", newProject);
  };

  return <Button onClick={handleCreate}>Create Project</Button>;
}

// 3. packages/hooks/src/use-project.ts
import { ProjectService } from "@plane/services";

export const useProject = () => {
  const projectService = new ProjectService();

  const createProject = async (workspaceSlug: string, data: Partial<IProject>) => {
    // 4. Service makes HTTP request to Django
    return await projectService.createProject(workspaceSlug, data);
  };

  return { createProject };
};

// 5. packages/services/src/project.service.ts
export class ProjectService extends APIService {
  async createProject(workspaceSlug: string, data: Partial<IProject>): Promise<IProject> {
    // 6. POST to Django API at localhost:8000
    return this.post(`/api/workspaces/${workspaceSlug}/projects/`, data);
  }
}

// 7. Django receives request at apps/api/plane/api/views/project.py
// 8. Django saves to PostgreSQL
// 9. Django returns JSON response
// 10. Response flows back through services → hooks → component
// 11. UI updates with new project
```

---

## Development Workflow

### Starting Development

```bash
# Terminal 1: Start Django backend
cd apps/api
set -a && source .env && set +a
source .venv/bin/activate
python manage.py runserver 8000

# Terminal 2: Start all frontend apps
pnpm dev
```

### What Happens When You Run `pnpm dev`

```
1. Turborepo reads turbo.json
2. Checks which packages need building
3. Builds packages in dependency order:
   ├─ @plane/types ✓
   ├─ @plane/constants ✓
   ├─ @plane/utils ✓ (after types)
   ├─ @plane/services ✓ (after types)
   ├─ @plane/hooks ✓ (after services)
   └─ @plane/ui ✓ (after types, utils)

4. Starts all apps in parallel:
   ├─ web (port 3000) ✓
   ├─ admin (port 3001) ✓
   ├─ space (port 3002) ✓
   └─ live (port 3100) ✓

5. Watches for changes:
   - Any change in packages/* triggers rebuild
   - Hot Module Replacement in all apps
```

### Making Changes

#### Scenario 1: Update a UI Component

```typescript
// 1. Edit packages/ui/src/components/buttons/button.tsx
export const Button = ({ variant = "primary", children, ...props }) => {
  return (
    <button
      className={`btn btn-${variant}`} // Changed styling
      {...props}
    >
      {children}
    </button>
  );
};

// 2. Turborepo detects change and rebuilds @plane/ui
// 3. All apps using Button automatically reload (HMR)
// 4. See changes in web (3000), admin (3001), space (3002)
```

#### Scenario 2: Add a New API Service

```typescript
// 1. Add type in packages/types/src/cycle.d.ts
export interface ICycle {
  id: string;
  name: string;
  start_date: string;
  end_date: string;
}

// 2. Add service in packages/services/src/cycle.service.ts
import type { ICycle } from "@plane/types";

export class CycleService extends APIService {
  async getCycles(projectId: string): Promise<ICycle[]> {
    return this.get(`/api/projects/${projectId}/cycles/`);
  }
}

// 3. Add hook in packages/hooks/src/use-cycle.ts
import { CycleService } from "@plane/services";

export const useCycle = () => {
  const cycleService = new CycleService();

  const fetchCycles = async (projectId: string) => {
    return await cycleService.getCycles(projectId);
  };

  return { fetchCycles };
};

// 4. Use in apps/web
import { useCycle } from "@plane/hooks";

function CyclesPage() {
  const { fetchCycles } = useCycle();
  // ... use the hook
}
```

---

## Adding New Features

### Adding a New Shared Component

```bash
# 1. Create component file
touch packages/ui/src/components/card.tsx
```

```typescript
// 2. Implement component
// packages/ui/src/components/card.tsx
import type { ReactNode } from "react";

interface CardProps {
  title: string;
  children: ReactNode;
  footer?: ReactNode;
}

export const Card = ({ title, children, footer }: CardProps) => {
  return (
    <div className="border rounded-lg p-4 shadow">
      <h3 className="text-lg font-semibold">{title}</h3>
      <div className="mt-2">{children}</div>
      {footer && <div className="mt-4 border-t pt-2">{footer}</div>}
    </div>
  );
};
```

```typescript
// 3. Export from package
// packages/ui/src/index.ts
export { Button } from "./components/buttons/button";
export { Input } from "./components/forms/input";
export { Card } from "./components/card"; // Add this
```

```typescript
// 4. Use in any app
// apps/web/app/routes/project.tsx
import { Card } from "@plane/ui";

export default function ProjectPage() {
  return (
    <Card title="Project Overview" footer={<button>View Details</button>}>
      <p>Project content here</p>
    </Card>
  );
}
```

### Adding a New App

```bash
# 1. Create new app directory
mkdir -p apps/my-new-app

# 2. Initialize package.json
cd apps/my-new-app
pnpm init

# 3. Add to pnpm-workspace.yaml (already included via apps/*)

# 4. Install dependencies
pnpm add react react-dom react-router

# 5. Add shared packages
pnpm add @plane/ui@workspace:* @plane/types@workspace:*

# 6. Create app structure
mkdir -p app/routes
touch app/root.tsx
touch app/routes.ts

# 7. Add dev script to package.json
{
  "scripts": {
    "dev": "react-router dev --port 3003"
  }
}

# 8. Turborepo will automatically pick it up on next pnpm dev
```

---

## Environment Configuration

### Root .env

```bash
# Database
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="password"
POSTGRES_DB="plane"

# Redis
REDIS_HOST="localhost"
REDIS_PORT="6379"

# RabbitMQ
RABBITMQ_HOST="localhost"
RABBITMQ_PORT="5672"
```

### App-specific .env files

**apps/api/.env**

```bash
# Django settings
DEBUG=0
SECRET_KEY="your-secret-key"
DATABASE_URL=postgresql://postgres:password@localhost:5432/plane
REDIS_URL="redis://localhost:6379/"
```

**apps/web/.env**

```bash
VITE_API_BASE_URL="http://localhost:8000"
VITE_WEB_BASE_URL="http://localhost:3000"
VITE_ADMIN_BASE_URL="http://localhost:3001"
VITE_SPACE_BASE_URL="http://localhost:3002"
```

**apps/admin/.env**

```bash
VITE_API_BASE_URL="http://localhost:8000"
VITE_ADMIN_BASE_PATH="/god-mode"
```

---

## Common Patterns

### Pattern 1: Sharing UI Logic

```typescript
// packages/hooks/src/use-disclosure.ts
import { useState, useCallback } from "react";

export const useDisclosure = (defaultOpen = false) => {
  const [isOpen, setIsOpen] = useState(defaultOpen);

  const open = useCallback(() => setIsOpen(true), []);
  const close = useCallback(() => setIsOpen(false), []);
  const toggle = useCallback(() => setIsOpen((prev) => !prev), []);

  return { isOpen, open, close, toggle };
};

// Usage in any app
import { useDisclosure } from "@plane/hooks";
import { Modal } from "@plane/ui";

function MyComponent() {
  const { isOpen, open, close } = useDisclosure();

  return (
    <>
      <button onClick={open}>Open Modal</button>
      <Modal isOpen={isOpen} onClose={close}>
        Modal content
      </Modal>
    </>
  );
}
```

### Pattern 2: Type-Safe API Calls

```typescript
// packages/types/src/api.d.ts
export interface APIResponse<T> {
  data: T;
  status: number;
  message?: string;
}

// packages/services/src/api.service.ts
import type { APIResponse } from "@plane/types";

export class APIService {
  async get<T>(url: string): Promise<T> {
    const response = await fetch(url);
    const json: APIResponse<T> = await response.json();
    return json.data;
  }
}

// Usage
import { ProjectService } from "@plane/services";
import type { IProject } from "@plane/types";

const service = new ProjectService();
const projects: IProject[] = await service.getProjects(); // Fully typed!
```

### Pattern 3: Consistent Styling

```typescript
// packages/ui/tailwind.config.js
export default {
  theme: {
    extend: {
      colors: {
        primary: {
          50: "#eff6ff",
          100: "#dbeafe",
          // ... all shades
        },
      },
    },
  },
};

// apps/web/tailwind.config.js
import baseConfig from "@plane/tailwind-config";

export default {
  ...baseConfig,
  content: [
    "./app/**/*.{ts,tsx}",
    "../../packages/ui/src/**/*.{ts,tsx}", // Include UI package
  ],
};
```

---

## Troubleshooting

### Issue: Changes not reflecting

```bash
# Clear Turborepo cache
pnpm turbo clean

# Rebuild everything
pnpm build

# Restart dev
pnpm dev
```

### Issue: Type errors after updating @plane/types

```bash
# Rebuild types package
cd packages/types
pnpm build

# Restart TypeScript server in your IDE
# VSCode: Cmd+Shift+P → "TypeScript: Restart TS Server"
```

### Issue: Module not found

```bash
# Reinstall dependencies
pnpm install

# Check if package is built
cd packages/ui  # or whichever package
pnpm build
```

---

## Summary

### Key Takeaways

1. **Monorepo Structure**: Apps and packages share code via PNPM workspaces
2. **4 Frontend Apps**: Web (main), Admin (god-mode), Space (public), Live (collaboration)
3. **Shared Packages**: UI, types, services, hooks, utils, constants, editor
4. **Build System**: Turborepo orchestrates builds in dependency order
5. **Type Safety**: Shared TypeScript types ensure consistency
6. **Hot Reload**: Changes in packages trigger rebuilds and HMR in apps

### Architecture Benefits

- **Single Source of Truth**: Types, constants, and components defined once
- **Atomic Updates**: Change a type, all apps get updated
- **Faster Development**: Shared components mean less duplication
- **Better Testing**: Test shared packages once, confidence everywhere
- **Scalability**: Easy to add new apps or packages

### Development Principles

1. **Shared First**: If multiple apps need it, put it in packages/
2. **Type Everything**: Use TypeScript for all shared code
3. **Single Responsibility**: Each package has one clear purpose
4. **Minimal Dependencies**: Packages should depend on as few others as possible
5. **Document Changes**: Update types, services, and this doc when adding features

---

## Additional Resources

- [React Router v7 Docs](https://reactrouter.com)
- [Turborepo Docs](https://turbo.build/repo/docs)
- [PNPM Workspaces](https://pnpm.io/workspaces)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [TipTap Editor](https://tiptap.dev)

---

**Questions or suggestions?** Update this document as you learn more about the codebase!
