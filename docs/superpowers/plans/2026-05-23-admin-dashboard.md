# StepUp Admin Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a React 18 admin SPA that lets admins monitor platform metrics, manage challenges, review anti-cheat flags, approve payouts, and manage users.

**Architecture:** Vite SPA in `admin/` subdirectory of the StepUp repo, deployed to Vercel. Reads data directly from Supabase using the service role key (bypasses RLS — acceptable for internal admin tool; note: for production hardening move reads behind a Vercel serverless function). Write operations use direct Supabase updates for simple flag reviews; complex mutations (challenge creation, payout processing) POST to the Node.js API. TanStack Query v5 manages all async state with automatic cache invalidation on mutation.

**Tech Stack:** React 18, TypeScript 5, Vite 5, TanStack Query v5, React Router v6, Tailwind CSS v3, Recharts 2, @supabase/supabase-js v2, Axios 1, Vitest 1 + React Testing Library 16 + MSW 2

---

## File Map

| Path | Responsibility |
|------|---------------|
| `admin/package.json` | Deps + scripts |
| `admin/vite.config.ts` | Vite + React plugin |
| `admin/vitest.config.ts` | Vitest + jsdom |
| `admin/tailwind.config.ts` | Dark neon theme tokens |
| `admin/postcss.config.js` | Tailwind + autoprefixer |
| `admin/tsconfig.json` | TypeScript config |
| `admin/index.html` | HTML entry |
| `admin/vercel.json` | SPA catch-all rewrite |
| `admin/.env.example` | Env var template |
| `admin/src/main.tsx` | React root mount |
| `admin/src/App.tsx` | QueryClientProvider + RouterProvider |
| `admin/src/index.css` | Tailwind directives |
| `admin/src/router.tsx` | All route definitions |
| `admin/src/lib/supabase.ts` | Two clients: supabaseAuth (anon) + supabaseAdmin (service role) |
| `admin/src/lib/api.ts` | Axios instance — injects session JWT on every request |
| `admin/src/lib/queryClient.ts` | TanStack Query singleton |
| `admin/src/types/index.ts` | All shared TypeScript types |
| `admin/src/hooks/useAuth.ts` | Session state + signIn + signOut |
| `admin/src/hooks/useDashboard.ts` | Stats + 7-day chart queries |
| `admin/src/hooks/useChallenges.ts` | Challenge list + create + cancel mutations |
| `admin/src/hooks/useFlags.ts` | Flag list + review mutation |
| `admin/src/hooks/usePayouts.ts` | Pending withdrawals + approve/reject mutations |
| `admin/src/hooks/useUsers.ts` | User search + user detail query |
| `admin/src/components/Layout.tsx` | Sidebar nav + Outlet shell |
| `admin/src/components/ProtectedRoute.tsx` | Redirects to /login if no session |
| `admin/src/components/StatCard.tsx` | Single metric summary card |
| `admin/src/components/DataTable.tsx` | Generic sortable table |
| `admin/src/components/StatusBadge.tsx` | Colored status chip |
| `admin/src/pages/Login.tsx` | Admin email/password login form |
| `admin/src/pages/Dashboard.tsx` | Metrics overview + step sync chart |
| `admin/src/pages/Challenges.tsx` | Challenge list + create/cancel actions |
| `admin/src/pages/ChallengeForm.tsx` | Create/edit challenge form (used as modal) |
| `admin/src/pages/FraudAnalytics.tsx` | Anti-cheat flag review table |
| `admin/src/pages/PayoutApprovals.tsx` | Pending payout table + approve/reject |
| `admin/src/pages/UserManagement.tsx` | User search table |
| `admin/src/pages/UserDetail.tsx` | Single user profile + badge + transaction history |
| `admin/src/test/setup.ts` | Vitest + jsdom + MSW global setup |
| `admin/src/test/handlers.ts` | MSW Node.js API request handlers |
| `admin/src/test/useDashboard.test.ts` | Dashboard hook unit tests |
| `admin/src/test/useChallenges.test.ts` | Challenge hook unit tests |
| `admin/src/test/useFlags.test.ts` | Flag hook unit tests |
| `admin/src/test/usePayouts.test.ts` | Payout hook unit tests |
| `admin/src/test/useUsers.test.ts` | User hook unit tests |
| `admin/src/test/Login.test.tsx` | Login component tests |
| `admin/src/test/Dashboard.test.tsx` | Dashboard page render tests |
| `admin/src/test/FraudAnalytics.test.tsx` | Fraud analytics interaction tests |

---

### Task 1: Project Scaffolding

**Files:**
- Create: `admin/package.json`
- Create: `admin/vite.config.ts`
- Create: `admin/vitest.config.ts`
- Create: `admin/tailwind.config.ts`
- Create: `admin/postcss.config.js`
- Create: `admin/tsconfig.json`
- Create: `admin/index.html`
- Create: `admin/vercel.json`
- Create: `admin/.env.example`
- Create: `admin/src/main.tsx`
- Create: `admin/src/App.tsx`
- Create: `admin/src/index.css`
- Create: `admin/src/lib/supabase.ts`
- Create: `admin/src/lib/api.ts`
- Create: `admin/src/lib/queryClient.ts`
- Create: `admin/src/types/index.ts`
- Create: `admin/src/test/setup.ts`
- Create: `admin/src/test/handlers.ts`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p admin/src/{lib,types,hooks,components,pages,test}
```
Expected: `admin/` with all subdirectories created.

- [ ] **Step 2: Create `admin/package.json`**

```json
{
  "name": "stepup-admin",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.43.4",
    "@tanstack/react-query": "^5.40.0",
    "axios": "^1.7.2",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.23.1",
    "recharts": "^2.12.7"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.4.6",
    "@testing-library/react": "^16.0.0",
    "@testing-library/user-event": "^14.5.2",
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "@vitest/coverage-v8": "^1.6.0",
    "autoprefixer": "^10.4.19",
    "jsdom": "^24.1.0",
    "msw": "^2.3.1",
    "postcss": "^8.4.39",
    "tailwindcss": "^3.4.4",
    "typescript": "^5.4.5",
    "vite": "^5.3.1",
    "vitest": "^1.6.0"
  }
}
```

- [ ] **Step 3: Create config files**

`admin/vite.config.ts`:
```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
```

`admin/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    globals: true,
  },
})
```

`admin/tailwind.config.ts`:
```ts
import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        background: '#0c0c18',
        card: 'rgba(255,255,255,0.04)',
        border: 'rgba(255,255,255,0.07)',
        primary: '#6366f1',
        accent: '#8b5cf6',
        neon: '#34d399',
        amber: '#fbbf24',
        pink: '#f472b6',
      },
    },
  },
} satisfies Config
```

`admin/postcss.config.js`:
```js
export default {
  plugins: { tailwindcss: {}, autoprefixer: {} },
}
```

`admin/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true
  },
  "include": ["src"]
}
```

`admin/index.html`:
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>StepUp Admin</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

`admin/vercel.json`:
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

`admin/.env.example`:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_SUPABASE_SERVICE_KEY=your-service-role-key
VITE_API_URL=https://your-api.up.railway.app
VITE_ADMIN_EMAILS=admin@stepup.in
```

- [ ] **Step 4: Create `admin/src/types/index.ts`**

```ts
export interface AdminUser {
  id: string
  email: string
}

export interface PrizeDistribution {
  top_percent: number
  winner_share: number
  platform_share: number
  sponsor_share: number
}

export interface Challenge {
  id: string
  title: string
  type: string
  step_goal: number
  entry_fee: number
  prize_pool: number
  max_participants: number
  start_time: string
  end_time: string
  status: 'upcoming' | 'active' | 'completed' | 'cancelled'
  prize_distribution: PrizeDistribution
  created_by: string
  sponsor_name: string | null
}

export interface ChallengeFormData {
  title: string
  type: string
  step_goal: number
  entry_fee: number
  max_participants: number
  start_time: string
  end_time: string
  prize_distribution: PrizeDistribution
  sponsor_name: string
}

export interface StepFlag {
  id: string
  user_id: string
  step_log_id: string
  reason: string
  reviewed: boolean
  created_at: string
  users: { name: string; phone: string } | null
  step_logs: { steps: number; synced_at: string } | null
}

export interface WalletTransaction {
  id: string
  user_id: string
  type: string
  amount: number
  idempotency_key: string
  reference_id: string | null
  description: string
  created_at: string
  users: { name: string; phone: string } | null
}

export interface User {
  id: string
  phone: string
  name: string
  city: string
  language: string
  goal_tier: string
  xp: number
  streak_days: number
  league: string
  avatar_url: string | null
  kyc_verified: boolean
  created_at: string
}

export interface UserBadge {
  id: string
  user_id: string
  badge_slug: string
  earned_at: string
}

export interface DashboardStats {
  active_users_today: number
  step_syncs_today: number
  open_challenges: number
  pending_flags: number
  revenue_today: number
}

export interface ChartPoint {
  date: string
  syncs: number
}
```

- [ ] **Step 5: Create `admin/src/lib/supabase.ts`**

```ts
import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string
const serviceKey = import.meta.env.VITE_SUPABASE_SERVICE_KEY as string

export const supabaseAuth = createClient(url, anonKey)
export const supabaseAdmin = createClient(url, serviceKey)
```

- [ ] **Step 6: Create `admin/src/lib/api.ts`**

```ts
import axios from 'axios'
import { supabaseAuth } from './supabase'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL as string,
})

api.interceptors.request.use(async (config) => {
  const { data } = await supabaseAuth.auth.getSession()
  if (data.session) {
    config.headers.Authorization = `Bearer ${data.session.access_token}`
  }
  return config
})

export default api
```

- [ ] **Step 7: Create `admin/src/lib/queryClient.ts`**

```ts
import { QueryClient } from '@tanstack/react-query'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, retry: 1 },
  },
})
```

- [ ] **Step 8: Create entry files**

`admin/src/index.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
body { background-color: #0c0c18; color: white; }
```

`admin/src/main.tsx`:
```tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

`admin/src/App.tsx`:
```tsx
import { QueryClientProvider } from '@tanstack/react-query'
import { RouterProvider } from 'react-router-dom'
import { queryClient } from './lib/queryClient'
import { router } from './router'

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  )
}
```

- [ ] **Step 9: Create test setup**

`admin/src/test/setup.ts`:
```ts
import '@testing-library/jest-dom'
import { afterEach, beforeAll, afterAll } from 'vitest'
import { cleanup } from '@testing-library/react'
import { server } from './handlers'

beforeAll(() => server.listen({ onUnhandledRequest: 'warn' }))
afterEach(() => { cleanup(); server.resetHandlers() })
afterAll(() => server.close())
```

`admin/src/test/handlers.ts`:
```ts
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

const API = 'http://localhost:4000'

export const handlers = [
  http.get(`${API}/challenges`, () =>
    HttpResponse.json([
      {
        id: 'c1', title: 'Morning Walk', type: 'weekly_free',
        step_goal: 70000, entry_fee: 0, prize_pool: 0,
        max_participants: 1000,
        start_time: '2026-05-23T00:00:00Z',
        end_time: '2026-05-29T23:59:59Z',
        status: 'active',
        prize_distribution: { top_percent: 10, winner_share: 0.8, platform_share: 0.1, sponsor_share: 0.1 },
        created_by: 'admin-uuid', sponsor_name: null,
      },
    ])
  ),
  http.post(`${API}/challenges`, () => HttpResponse.json({ id: 'new-c1' }, { status: 201 })),
  http.post(`${API}/admin/payouts/:id/approve`, () => HttpResponse.json({ success: true })),
  http.post(`${API}/admin/payouts/:id/reject`, () => HttpResponse.json({ success: true })),
]

export const server = setupServer(...handlers)
```

- [ ] **Step 10: Install dependencies and run zero-test check**

```bash
cd admin && npm install
npm test
```
Expected: `No test files found` (or 0 tests, 0 failures). Dependency install completes without errors.

- [ ] **Step 11: Commit**

```bash
git add admin/
git commit -m "feat: admin scaffold — vite + react + tailwind + supabase + query client"
```

---

### Task 2: Auth — Login Page + useAuth Hook + ProtectedRoute

**Files:**
- Create: `admin/src/hooks/useAuth.ts`
- Create: `admin/src/components/ProtectedRoute.tsx`
- Create: `admin/src/pages/Login.tsx`
- Create: `admin/src/router.tsx` (stub — login route only)
- Test: `admin/src/test/Login.test.tsx`

- [ ] **Step 1: Write the failing test**

`admin/src/test/Login.test.tsx`:
```tsx
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, it, expect, beforeEach } from 'vitest'
import Login from '../pages/Login'

const mockSignIn = vi.fn()
const mockNavigate = vi.fn()

vi.mock('../hooks/useAuth', () => ({
  useAuth: () => ({ signIn: mockSignIn, user: null, loading: false, signOut: vi.fn() }),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return { ...actual, useNavigate: () => mockNavigate }
})

describe('Login', () => {
  beforeEach(() => { mockSignIn.mockReset(); mockNavigate.mockReset() })

  it('renders email and password fields', () => {
    render(<Login />, { wrapper: MemoryRouter })
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
  })

  it('calls signIn with credentials and navigates on success', async () => {
    mockSignIn.mockResolvedValue(undefined)
    render(<Login />, { wrapper: MemoryRouter })
    await userEvent.type(screen.getByLabelText(/email/i), 'admin@stepup.in')
    await userEvent.type(screen.getByLabelText(/password/i), 'secret123')
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }))
    await waitFor(() => expect(mockSignIn).toHaveBeenCalledWith('admin@stepup.in', 'secret123'))
    expect(mockNavigate).toHaveBeenCalledWith('/dashboard')
  })

  it('shows error message when signIn rejects', async () => {
    mockSignIn.mockRejectedValue(new Error('Invalid credentials'))
    render(<Login />, { wrapper: MemoryRouter })
    await userEvent.type(screen.getByLabelText(/email/i), 'admin@stepup.in')
    await userEvent.type(screen.getByLabelText(/password/i), 'wrong')
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }))
    await waitFor(() => expect(screen.getByText('Invalid credentials')).toBeInTheDocument())
    expect(mockNavigate).not.toHaveBeenCalled()
  })
})
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd admin && npm test -- Login.test.tsx
```
Expected: FAIL — `Cannot find module '../pages/Login'`

- [ ] **Step 3: Create `admin/src/hooks/useAuth.ts`**

```ts
import { useEffect, useState } from 'react'
import { supabaseAuth } from '../lib/supabase'
import type { AdminUser } from '../types'

const ALLOWED = (import.meta.env.VITE_ADMIN_EMAILS as string ?? '')
  .split(',')
  .map((e) => e.trim())

export function useAuth() {
  const [user, setUser] = useState<AdminUser | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabaseAuth.auth.getSession().then(({ data }) => {
      const s = data.session
      if (s && ALLOWED.includes(s.user.email ?? '')) {
        setUser({ id: s.user.id, email: s.user.email! })
      }
      setLoading(false)
    })

    const { data: listener } = supabaseAuth.auth.onAuthStateChange((_event, s) => {
      if (s && ALLOWED.includes(s.user.email ?? '')) {
        setUser({ id: s.user.id, email: s.user.email! })
      } else {
        setUser(null)
      }
    })

    return () => listener.subscription.unsubscribe()
  }, [])

  async function signIn(email: string, password: string) {
    const { error } = await supabaseAuth.auth.signInWithPassword({ email, password })
    if (error) throw new Error(error.message)
    if (!ALLOWED.includes(email)) {
      await supabaseAuth.auth.signOut()
      throw new Error('Not authorized as admin')
    }
  }

  async function signOut() {
    await supabaseAuth.auth.signOut()
    setUser(null)
  }

  return { user, loading, signIn, signOut }
}
```

- [ ] **Step 4: Create `admin/src/pages/Login.tsx`**

```tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

export default function Login() {
  const { signIn } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await signIn(email, password)
      navigate('/dashboard')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign in failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="w-full max-w-sm p-8 rounded-2xl bg-card border border-border">
        <h1 className="text-2xl font-bold text-white mb-1">StepUp Admin</h1>
        <p className="text-gray-400 text-sm mb-8">Internal platform dashboard</p>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-xs text-gray-400 mb-1">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full px-3 py-2 rounded-lg bg-white/5 border border-border text-white text-sm focus:outline-none focus:border-primary"
            />
          </div>
          <div>
            <label htmlFor="password" className="block text-xs text-gray-400 mb-1">
              Password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full px-3 py-2 rounded-lg bg-white/5 border border-border text-white text-sm focus:outline-none focus:border-primary"
            />
          </div>
          {error && <p className="text-red-400 text-sm">{error}</p>}
          <button
            type="submit"
            disabled={loading}
            className="w-full py-2.5 rounded-lg bg-primary text-white font-semibold text-sm hover:bg-primary/90 disabled:opacity-50 transition-colors"
          >
            {loading ? 'Signing in…' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Create `admin/src/components/ProtectedRoute.tsx`**

```tsx
import { Navigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

export default function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <p className="text-gray-400 text-sm">Loading…</p>
      </div>
    )
  }
  if (!user) return <Navigate to="/login" replace />
  return <>{children}</>
}
```

- [ ] **Step 6: Create stub `admin/src/router.tsx` (login route only)**

```tsx
import { createBrowserRouter, Navigate } from 'react-router-dom'
import Login from './pages/Login'

export const router = createBrowserRouter([
  { path: '/login', element: <Login /> },
  { path: '*', element: <Navigate to="/login" replace /> },
])
```

- [ ] **Step 7: Run test — verify it passes**

```bash
cd admin && npm test -- Login.test.tsx
```
Expected: PASS — 3 tests passing.

- [ ] **Step 8: Commit**

```bash
git add admin/src/hooks/useAuth.ts admin/src/components/ProtectedRoute.tsx admin/src/pages/Login.tsx admin/src/router.tsx admin/src/test/Login.test.tsx
git commit -m "feat: admin auth — login page, useAuth hook, protected route"
```

---

### Task 3: Layout + Router + Shared Components

**Files:**
- Create: `admin/src/components/Layout.tsx`
- Create: `admin/src/components/StatCard.tsx`
- Create: `admin/src/components/DataTable.tsx`
- Create: `admin/src/components/StatusBadge.tsx`
- Modify: `admin/src/router.tsx` — add all protected routes

- [ ] **Step 1: Create `admin/src/components/StatusBadge.tsx`**

```tsx
type Status =
  | 'upcoming' | 'active' | 'completed' | 'cancelled'
  | 'pending' | 'approved' | 'rejected'
  | 'flagged' | 'reviewed'

const MAP: Record<Status, string> = {
  upcoming: 'bg-amber/20 text-amber',
  active: 'bg-neon/20 text-neon',
  completed: 'bg-primary/20 text-primary',
  cancelled: 'bg-red-500/20 text-red-400',
  pending: 'bg-amber/20 text-amber',
  approved: 'bg-neon/20 text-neon',
  rejected: 'bg-red-500/20 text-red-400',
  flagged: 'bg-pink/20 text-pink',
  reviewed: 'bg-gray-500/20 text-gray-400',
}

export default function StatusBadge({ status }: { status: Status }) {
  return (
    <span className={`inline-block px-2 py-0.5 rounded-full text-xs font-medium ${MAP[status]}`}>
      {status}
    </span>
  )
}
```

- [ ] **Step 2: Create `admin/src/components/StatCard.tsx`**

```tsx
type Color = 'primary' | 'neon' | 'amber' | 'pink' | 'accent'

const COLOR_MAP: Record<Color, string> = {
  primary: 'text-primary',
  neon: 'text-neon',
  amber: 'text-amber',
  pink: 'text-pink',
  accent: 'text-accent',
}

interface StatCardProps {
  label: string
  value: string | number
  color?: Color
  sub?: string
}

export default function StatCard({ label, value, color = 'primary', sub }: StatCardProps) {
  return (
    <div className="p-5 rounded-2xl bg-card border border-border flex flex-col gap-1">
      <p className="text-xs text-gray-400 uppercase tracking-wider">{label}</p>
      <p className={`text-3xl font-bold ${COLOR_MAP[color]}`}>{value}</p>
      {sub && <p className="text-xs text-gray-500">{sub}</p>}
    </div>
  )
}
```

- [ ] **Step 3: Create `admin/src/components/DataTable.tsx`**

```tsx
interface Column<T> {
  key: string
  header: string
  render: (row: T) => React.ReactNode
}

interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  keyField: keyof T
  emptyMessage?: string
}

export default function DataTable<T>({
  columns,
  data,
  keyField,
  emptyMessage = 'No data',
}: DataTableProps<T>) {
  return (
    <div className="rounded-2xl border border-border overflow-hidden">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border bg-white/[0.02]">
            {columns.map((col) => (
              <th
                key={col.key}
                className="px-4 py-3 text-left text-xs text-gray-400 uppercase tracking-wider font-medium"
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.length === 0 ? (
            <tr>
              <td colSpan={columns.length} className="px-4 py-8 text-center text-gray-500 text-sm">
                {emptyMessage}
              </td>
            </tr>
          ) : (
            data.map((row) => (
              <tr
                key={String(row[keyField])}
                className="border-b border-border/50 hover:bg-white/[0.02] transition-colors"
              >
                {columns.map((col) => (
                  <td key={col.key} className="px-4 py-3 text-gray-200">
                    {col.render(row)}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  )
}
```

- [ ] **Step 4: Create `admin/src/components/Layout.tsx`**

```tsx
import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const NAV = [
  { to: '/dashboard', label: 'Dashboard' },
  { to: '/challenges', label: 'Challenges' },
  { to: '/fraud', label: 'Fraud Analytics' },
  { to: '/payouts', label: 'Payouts' },
  { to: '/users', label: 'Users' },
]

export default function Layout() {
  const { user, signOut } = useAuth()

  return (
    <div className="flex h-screen bg-background overflow-hidden">
      <aside className="w-52 flex-shrink-0 flex flex-col border-r border-border">
        <div className="px-4 py-4 border-b border-border">
          <span className="font-bold text-primary text-sm">StepUp</span>
          <span className="text-gray-500 text-xs ml-1">Admin</span>
        </div>
        <nav className="flex-1 p-2 space-y-0.5 overflow-y-auto">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `block px-3 py-2 rounded-lg text-sm transition-colors ${
                  isActive
                    ? 'bg-primary/20 text-primary font-medium'
                    : 'text-gray-400 hover:text-white hover:bg-white/5'
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="p-4 border-t border-border">
          <p className="text-xs text-gray-500 truncate mb-2">{user?.email}</p>
          <button onClick={signOut} className="text-xs text-red-400 hover:text-red-300 transition-colors">
            Sign out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-y-auto">
        <Outlet />
      </main>
    </div>
  )
}
```

- [ ] **Step 5: Update `admin/src/router.tsx` with all protected routes**

```tsx
import { createBrowserRouter, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import Dashboard from './pages/Dashboard'
import Challenges from './pages/Challenges'
import FraudAnalytics from './pages/FraudAnalytics'
import PayoutApprovals from './pages/PayoutApprovals'
import UserManagement from './pages/UserManagement'
import UserDetail from './pages/UserDetail'

export const router = createBrowserRouter([
  { path: '/login', element: <Login /> },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <Layout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <Navigate to="/dashboard" replace /> },
      { path: 'dashboard', element: <Dashboard /> },
      { path: 'challenges', element: <Challenges /> },
      { path: 'fraud', element: <FraudAnalytics /> },
      { path: 'payouts', element: <PayoutApprovals /> },
      { path: 'users', element: <UserManagement /> },
      { path: 'users/:id', element: <UserDetail /> },
    ],
  },
  { path: '*', element: <Navigate to="/login" replace /> },
])
```

Note: The page components imported above (Dashboard, Challenges, etc.) are stub files at this stage — create each as a minimal placeholder:

```tsx
// admin/src/pages/Dashboard.tsx (stub)
export default function Dashboard() { return <div className="p-6"><h1 className="text-xl font-bold">Dashboard</h1></div> }

// admin/src/pages/Challenges.tsx (stub)
export default function Challenges() { return <div className="p-6"><h1 className="text-xl font-bold">Challenges</h1></div> }

// admin/src/pages/FraudAnalytics.tsx (stub)
export default function FraudAnalytics() { return <div className="p-6"><h1 className="text-xl font-bold">Fraud Analytics</h1></div> }

// admin/src/pages/PayoutApprovals.tsx (stub)
export default function PayoutApprovals() { return <div className="p-6"><h1 className="text-xl font-bold">Payouts</h1></div> }

// admin/src/pages/UserManagement.tsx (stub)
export default function UserManagement() { return <div className="p-6"><h1 className="text-xl font-bold">Users</h1></div> }

// admin/src/pages/UserDetail.tsx (stub)
export default function UserDetail() { return <div className="p-6"><h1 className="text-xl font-bold">User Detail</h1></div> }

// admin/src/pages/ChallengeForm.tsx (stub)
export default function ChallengeForm() { return null }
```

- [ ] **Step 6: Run tests**

```bash
cd admin && npm test
```
Expected: PASS — Login tests still pass (3/3).

- [ ] **Step 7: Start dev server and verify routing works**

```bash
cd admin && npm run dev
```
Open `http://localhost:5173` — should redirect to `/login`. After login (requires real Supabase creds), should show sidebar with all nav items.

- [ ] **Step 8: Commit**

```bash
git add admin/src/components/ admin/src/router.tsx admin/src/pages/
git commit -m "feat: admin layout — sidebar nav, stat card, data table, status badge, full router"
```

---

### Task 4: Dashboard Overview Page

**Files:**
- Create: `admin/src/hooks/useDashboard.ts`
- Modify: `admin/src/pages/Dashboard.tsx`
- Test: `admin/src/test/useDashboard.test.ts`
- Test: `admin/src/test/Dashboard.test.tsx`

- [ ] **Step 1: Write the failing hook test**

`admin/src/test/useDashboard.test.ts`:
```ts
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClientProvider } from '@tanstack/react-query'
import { QueryClient } from '@tanstack/react-query'
import { vi, describe, it, expect } from 'vitest'
import { useDashboard, useDailyStepChart } from '../hooks/useDashboard'

vi.mock('../lib/supabase', () => {
  const makeChain = (result: unknown) => ({
    from: () => ({
      select: () => ({
        gte: () => ({ eq: () => Promise.resolve(result) }),
        eq: () => ({ gte: () => Promise.resolve(result) }),
        is: () => Promise.resolve(result),
      }),
    }),
  })
  return {
    supabaseAdmin: makeChain({ data: [], count: 5, error: null }),
  }
})

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>
}

describe('useDashboard', () => {
  it('returns DashboardStats shape', async () => {
    const { result } = renderHook(() => useDashboard(), { wrapper })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    const data = result.current.data!
    expect(data).toHaveProperty('active_users_today')
    expect(data).toHaveProperty('step_syncs_today')
    expect(data).toHaveProperty('open_challenges')
    expect(data).toHaveProperty('pending_flags')
    expect(data).toHaveProperty('revenue_today')
  })
})
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd admin && npm test -- useDashboard.test.ts
```
Expected: FAIL — `Cannot find module '../hooks/useDashboard'`

- [ ] **Step 3: Create `admin/src/hooks/useDashboard.ts`**

```ts
import { useQuery } from '@tanstack/react-query'
import { supabaseAdmin } from '../lib/supabase'
import type { DashboardStats, ChartPoint } from '../types'

export function useDashboard() {
  return useQuery<DashboardStats>({
    queryKey: ['dashboard', 'stats'],
    queryFn: async () => {
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      const todayISO = today.toISOString()

      const [syncsRes, challengesRes, flagsRes, revenueRes, activeRes] = await Promise.all([
        supabaseAdmin
          .from('step_logs')
          .select('id', { count: 'exact', head: true })
          .gte('synced_at', todayISO),
        supabaseAdmin
          .from('challenges')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'active'),
        supabaseAdmin
          .from('step_flags')
          .select('id', { count: 'exact', head: true })
          .eq('reviewed', false),
        supabaseAdmin
          .from('wallet_transactions')
          .select('amount')
          .eq('type', 'fee')
          .gte('created_at', todayISO),
        supabaseAdmin
          .from('step_logs')
          .select('user_id')
          .eq('flagged', false)
          .gte('synced_at', todayISO),
      ])

      const revenue = ((revenueRes.data ?? []) as { amount: number }[]).reduce(
        (sum, t) => sum + t.amount,
        0,
      )
      const activeUsers = new Set(
        ((activeRes.data ?? []) as { user_id: string }[]).map((r) => r.user_id),
      ).size

      return {
        active_users_today: activeUsers,
        step_syncs_today: syncsRes.count ?? 0,
        open_challenges: challengesRes.count ?? 0,
        pending_flags: flagsRes.count ?? 0,
        revenue_today: revenue,
      }
    },
    refetchInterval: 60_000,
  })
}

export function useDailyStepChart() {
  return useQuery<ChartPoint[]>({
    queryKey: ['dashboard', 'chart'],
    queryFn: async () => {
      const sevenDaysAgo = new Date()
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)
      const { data } = await supabaseAdmin
        .from('step_logs')
        .select('synced_at')
        .gte('synced_at', sevenDaysAgo.toISOString())

      const counts: Record<string, number> = {}
      for (let i = 6; i >= 0; i--) {
        const d = new Date()
        d.setDate(d.getDate() - i)
        const key = d.toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })
        counts[key] = 0
      }
      for (const row of (data ?? []) as { synced_at: string }[]) {
        const key = new Date(row.synced_at).toLocaleDateString('en-IN', {
          month: 'short',
          day: 'numeric',
        })
        if (key in counts) counts[key]++
      }

      return Object.entries(counts).map(([date, syncs]) => ({ date, syncs }))
    },
  })
}
```

- [ ] **Step 4: Run hook test — verify it passes**

```bash
cd admin && npm test -- useDashboard.test.ts
```
Expected: PASS — 1 test passing.

- [ ] **Step 5: Write the failing Dashboard page test**

`admin/src/test/Dashboard.test.tsx`:
```tsx
import { render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, it, expect } from 'vitest'
import Dashboard from '../pages/Dashboard'

vi.mock('../hooks/useDashboard', () => ({
  useDashboard: () => ({
    data: {
      active_users_today: 142,
      step_syncs_today: 3201,
      open_challenges: 5,
      pending_flags: 3,
      revenue_today: 12500,
    },
    isLoading: false,
    isError: false,
  }),
  useDailyStepChart: () => ({
    data: [
      { date: 'May 17', syncs: 100 },
      { date: 'May 18', syncs: 150 },
    ],
    isLoading: false,
  }),
}))

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return (
    <QueryClientProvider client={qc}>
      <MemoryRouter>{children}</MemoryRouter>
    </QueryClientProvider>
  )
}

describe('Dashboard', () => {
  it('renders all 5 stat cards', async () => {
    render(<Dashboard />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText('142')).toBeInTheDocument()
      expect(screen.getByText('3201')).toBeInTheDocument()
      expect(screen.getByText('5')).toBeInTheDocument()
      expect(screen.getByText('3')).toBeInTheDocument()
    })
  })
})
```

- [ ] **Step 6: Run test — verify it fails**

```bash
cd admin && npm test -- Dashboard.test.tsx
```
Expected: FAIL — stub Dashboard doesn't render stat values.

- [ ] **Step 7: Replace `admin/src/pages/Dashboard.tsx` with full implementation**

```tsx
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import StatCard from '../components/StatCard'
import { useDashboard, useDailyStepChart } from '../hooks/useDashboard'

export default function Dashboard() {
  const { data: stats, isLoading, isError } = useDashboard()
  const { data: chart } = useDailyStepChart()

  if (isLoading) {
    return <div className="p-6 text-gray-400 text-sm">Loading stats…</div>
  }
  if (isError || !stats) {
    return <div className="p-6 text-red-400 text-sm">Failed to load dashboard</div>
  }

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-xl font-bold text-white">Dashboard</h1>

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard label="Active Users Today" value={stats.active_users_today} color="primary" />
        <StatCard label="Step Syncs Today" value={stats.step_syncs_today.toLocaleString()} color="neon" />
        <StatCard label="Open Challenges" value={stats.open_challenges} color="accent" />
        <StatCard label="Pending Flags" value={stats.pending_flags} color="pink" />
        <StatCard
          label="Revenue Today"
          value={`₹${(stats.revenue_today / 100).toLocaleString('en-IN')}`}
          color="amber"
          sub="platform fees"
        />
      </div>

      {chart && chart.length > 0 && (
        <div className="p-5 rounded-2xl bg-card border border-border">
          <h2 className="text-sm font-semibold text-gray-300 mb-4">Step Syncs — Last 7 Days</h2>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={chart}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="date" tick={{ fill: '#9ca3af', fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: '#9ca3af', fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 8 }}
                labelStyle={{ color: '#e5e7eb' }}
                itemStyle={{ color: '#6366f1' }}
              />
              <Line type="monotone" dataKey="syncs" stroke="#6366f1" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 8: Run all tests — verify they pass**

```bash
cd admin && npm test
```
Expected: PASS — 4 tests passing (Login × 3, Dashboard × 1).

- [ ] **Step 9: Commit**

```bash
git add admin/src/hooks/useDashboard.ts admin/src/pages/Dashboard.tsx admin/src/test/useDashboard.test.ts admin/src/test/Dashboard.test.tsx
git commit -m "feat: admin dashboard — 5 metric cards + 7-day step sync chart"
```

---

### Task 5: Challenge Management

**Files:**
- Create: `admin/src/hooks/useChallenges.ts`
- Modify: `admin/src/pages/Challenges.tsx`
- Modify: `admin/src/pages/ChallengeForm.tsx`
- Test: `admin/src/test/useChallenges.test.ts`

- [ ] **Step 1: Write the failing hook test**

`admin/src/test/useChallenges.test.ts`:
```ts
import { renderHook, waitFor, act } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { vi, describe, it, expect } from 'vitest'
import { useChallenges } from '../hooks/useChallenges'

const mockFrom = vi.fn()
vi.mock('../lib/supabase', () => ({
  supabaseAdmin: { from: mockFrom },
}))

vi.mock('../lib/api', () => ({
  default: {
    post: vi.fn().mockResolvedValue({ data: { id: 'new-c1' } }),
  },
}))

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>
}

describe('useChallenges', () => {
  it('fetches challenge list from Supabase', async () => {
    const challenges = [{ id: 'c1', title: 'Morning Walk', status: 'active' }]
    mockFrom.mockReturnValue({
      select: () => ({ order: () => Promise.resolve({ data: challenges, error: null }) }),
    })

    const { result } = renderHook(() => useChallenges(), { wrapper })
    await waitFor(() => expect(result.current.challenges.isSuccess).toBe(true))
    expect(result.current.challenges.data).toHaveLength(1)
    expect(result.current.challenges.data![0].title).toBe('Morning Walk')
  })
})
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd admin && npm test -- useChallenges.test.ts
```
Expected: FAIL — `Cannot find module '../hooks/useChallenges'`

- [ ] **Step 3: Create `admin/src/hooks/useChallenges.ts`**

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabaseAdmin } from '../lib/supabase'
import api from '../lib/api'
import type { Challenge, ChallengeFormData } from '../types'

export function useChallenges() {
  const qc = useQueryClient()

  const challenges = useQuery<Challenge[]>({
    queryKey: ['challenges'],
    queryFn: async () => {
      const { data, error } = await supabaseAdmin
        .from('challenges')
        .select('*')
        .order('created_at', { ascending: false })
      if (error) throw error
      return data as Challenge[]
    },
  })

  const createChallenge = useMutation({
    mutationFn: async (formData: ChallengeFormData) => {
      const { data } = await api.post<{ id: string }>('/challenges', formData)
      return data
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['challenges'] }),
  })

  const cancelChallenge = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabaseAdmin
        .from('challenges')
        .update({ status: 'cancelled' })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['challenges'] }),
  })

  return { challenges, createChallenge, cancelChallenge }
}
```

- [ ] **Step 4: Run hook test — verify it passes**

```bash
cd admin && npm test -- useChallenges.test.ts
```
Expected: PASS — 1 test passing.

- [ ] **Step 5: Replace `admin/src/pages/Challenges.tsx` with full implementation**

```tsx
import { useState } from 'react'
import DataTable from '../components/DataTable'
import StatusBadge from '../components/StatusBadge'
import ChallengeForm from './ChallengeForm'
import { useChallenges } from '../hooks/useChallenges'
import type { Challenge } from '../types'

export default function Challenges() {
  const { challenges, cancelChallenge } = useChallenges()
  const [showForm, setShowForm] = useState(false)

  const columns = [
    { key: 'title', header: 'Title', render: (r: Challenge) => <span className="font-medium">{r.title}</span> },
    { key: 'type', header: 'Type', render: (r: Challenge) => <span className="text-gray-400 text-xs">{r.type}</span> },
    {
      key: 'entry_fee',
      header: 'Entry Fee',
      render: (r: Challenge) =>
        r.entry_fee === 0 ? (
          <span className="text-gray-500">Free</span>
        ) : (
          <span className="text-neon">₹{r.entry_fee / 100}</span>
        ),
    },
    {
      key: 'participants',
      header: 'Max',
      render: (r: Challenge) => <span>{r.max_participants.toLocaleString()}</span>,
    },
    {
      key: 'start_time',
      header: 'Starts',
      render: (r: Challenge) => (
        <span className="text-xs text-gray-400">
          {new Date(r.start_time).toLocaleDateString('en-IN')}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (r: Challenge) => <StatusBadge status={r.status} />,
    },
    {
      key: 'actions',
      header: '',
      render: (r: Challenge) =>
        r.status === 'upcoming' || r.status === 'active' ? (
          <button
            onClick={() => cancelChallenge.mutate(r.id)}
            disabled={cancelChallenge.isPending}
            className="text-xs text-red-400 hover:text-red-300 disabled:opacity-50"
          >
            Cancel
          </button>
        ) : null,
    },
  ]

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-white">Challenges</h1>
        <button
          onClick={() => setShowForm(true)}
          className="px-4 py-2 rounded-lg bg-primary text-white text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          + New Challenge
        </button>
      </div>

      {challenges.isLoading && <p className="text-gray-400 text-sm">Loading…</p>}
      {challenges.isError && <p className="text-red-400 text-sm">Failed to load challenges</p>}
      {challenges.data && (
        <DataTable columns={columns} data={challenges.data} keyField="id" emptyMessage="No challenges yet" />
      )}

      {showForm && <ChallengeForm onClose={() => setShowForm(false)} />}
    </div>
  )
}
```

- [ ] **Step 6: Replace `admin/src/pages/ChallengeForm.tsx` with full implementation**

```tsx
import { useState } from 'react'
import { useChallenges } from '../hooks/useChallenges'
import type { ChallengeFormData } from '../types'

const CHALLENGE_TYPES = [
  'daily_free', 'weekly_free', 'paid_pool', 'sponsored_free', 'team', 'city_vs_city',
]

const DEFAULTS: ChallengeFormData = {
  title: '',
  type: 'weekly_free',
  step_goal: 70000,
  entry_fee: 0,
  max_participants: 1000,
  start_time: '',
  end_time: '',
  prize_distribution: { top_percent: 10, winner_share: 0.8, platform_share: 0.1, sponsor_share: 0.1 },
  sponsor_name: '',
}

export default function ChallengeForm({ onClose }: { onClose: () => void }) {
  const { createChallenge } = useChallenges()
  const [form, setForm] = useState<ChallengeFormData>(DEFAULTS)
  const [error, setError] = useState('')

  const distTotal =
    form.prize_distribution.winner_share +
    form.prize_distribution.platform_share +
    form.prize_distribution.sponsor_share

  function set<K extends keyof ChallengeFormData>(key: K, value: ChallengeFormData[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  function setDist<K extends keyof ChallengeFormData['prize_distribution']>(
    key: K,
    value: number,
  ) {
    setForm((prev) => ({
      ...prev,
      prize_distribution: { ...prev.prize_distribution, [key]: value },
    }))
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    if (Math.abs(distTotal - 1) > 0.001) {
      setError(`Prize shares must sum to 1.0 (current: ${distTotal.toFixed(2)})`)
      return
    }
    try {
      await createChallenge.mutateAsync(form)
      onClose()
    } catch {
      setError('Failed to create challenge')
    }
  }

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="w-full max-w-lg bg-[#12121f] border border-border rounded-2xl p-6 overflow-y-auto max-h-[90vh]">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold">New Challenge</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white text-xl leading-none">×</button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <Field label="Title">
            <input
              type="text" required value={form.title}
              onChange={(e) => set('title', e.target.value)}
              className="field-input"
            />
          </Field>

          <Field label="Type">
            <select value={form.type} onChange={(e) => set('type', e.target.value)} className="field-input">
              {CHALLENGE_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
            </select>
          </Field>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Step Goal">
              <input type="number" required value={form.step_goal}
                onChange={(e) => set('step_goal', Number(e.target.value))}
                className="field-input" />
            </Field>
            <Field label="Entry Fee (paise)">
              <input type="number" min={0} value={form.entry_fee}
                onChange={(e) => set('entry_fee', Number(e.target.value))}
                className="field-input" />
            </Field>
          </div>

          <Field label="Max Participants">
            <input type="number" required min={2} value={form.max_participants}
              onChange={(e) => set('max_participants', Number(e.target.value))}
              className="field-input" />
          </Field>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Start Time">
              <input type="datetime-local" required value={form.start_time}
                onChange={(e) => set('start_time', e.target.value)}
                className="field-input" />
            </Field>
            <Field label="End Time">
              <input type="datetime-local" required value={form.end_time}
                onChange={(e) => set('end_time', e.target.value)}
                className="field-input" />
            </Field>
          </div>

          <div className="p-4 rounded-xl bg-white/[0.03] border border-border space-y-3">
            <p className="text-xs text-gray-400 font-medium uppercase tracking-wider">
              Prize Distribution (must sum to 1.0)
            </p>
            {(
              [
                ['top_percent', 'Top % Winners', false],
                ['winner_share', 'Winner Share', true],
                ['platform_share', 'Platform Share', true],
                ['sponsor_share', 'Sponsor Share', true],
              ] as const
            ).map(([key, label, isShare]) => (
              <Field key={key} label={label}>
                <input
                  type="number" step={isShare ? '0.01' : '1'} min={0} max={isShare ? 1 : 100}
                  value={form.prize_distribution[key]}
                  onChange={(e) => setDist(key, Number(e.target.value))}
                  className="field-input"
                />
              </Field>
            ))}
            <p className={`text-xs ${Math.abs(distTotal - 1) > 0.001 ? 'text-red-400' : 'text-neon'}`}>
              Share total: {distTotal.toFixed(2)}
            </p>
          </div>

          <Field label="Sponsor Name (optional)">
            <input type="text" value={form.sponsor_name}
              onChange={(e) => set('sponsor_name', e.target.value)}
              className="field-input" />
          </Field>

          {error && <p className="text-red-400 text-sm">{error}</p>}

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose}
              className="flex-1 py-2.5 rounded-lg border border-border text-gray-300 text-sm hover:bg-white/5">
              Cancel
            </button>
            <button type="submit" disabled={createChallenge.isPending}
              className="flex-1 py-2.5 rounded-lg bg-primary text-white text-sm font-semibold disabled:opacity-50">
              {createChallenge.isPending ? 'Creating…' : 'Create Challenge'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-xs text-gray-400 mb-1">{label}</label>
      {children}
    </div>
  )
}
```

Add to `admin/src/index.css`:
```css
.field-input {
  @apply w-full px-3 py-2 rounded-lg bg-white/5 border border-border text-white text-sm focus:outline-none focus:border-primary;
}
```

- [ ] **Step 7: Run all tests**

```bash
cd admin && npm test
```
Expected: PASS — 5 tests passing.

- [ ] **Step 8: Commit**

```bash
git add admin/src/hooks/useChallenges.ts admin/src/pages/Challenges.tsx admin/src/pages/ChallengeForm.tsx admin/src/test/useChallenges.test.ts admin/src/index.css
git commit -m "feat: challenge management — list, create form, cancel action"
```

---

### Task 6: Fraud Analytics

**Files:**
- Create: `admin/src/hooks/useFlags.ts`
- Modify: `admin/src/pages/FraudAnalytics.tsx`
- Test: `admin/src/test/useFlags.test.ts`
- Test: `admin/src/test/FraudAnalytics.test.tsx`

- [ ] **Step 1: Write the failing hook test**

`admin/src/test/useFlags.test.ts`:
```ts
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { vi, describe, it, expect } from 'vitest'
import { useFlags } from '../hooks/useFlags'

const mockFrom = vi.fn()
vi.mock('../lib/supabase', () => ({
  supabaseAdmin: { from: mockFrom },
}))

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>
}

describe('useFlags', () => {
  it('fetches unreviewed flags with user and step_log joins', async () => {
    const flags = [
      {
        id: 'f1', user_id: 'u1', step_log_id: 'sl1',
        reason: 'rate_exceeded', reviewed: false, created_at: '2026-05-23T10:00:00Z',
        users: { name: 'Ravi Kumar', phone: '+919876543210' },
        step_logs: { steps: 55000, synced_at: '2026-05-23T09:45:00Z' },
      },
    ]
    mockFrom.mockReturnValue({
      select: () => ({
        eq: () => ({
          order: () => Promise.resolve({ data: flags, error: null }),
        }),
      }),
    })

    const { result } = renderHook(() => useFlags(), { wrapper })
    await waitFor(() => expect(result.current.flags.isSuccess).toBe(true))
    expect(result.current.flags.data).toHaveLength(1)
    expect(result.current.flags.data![0].reason).toBe('rate_exceeded')
  })
})
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd admin && npm test -- useFlags.test.ts
```
Expected: FAIL — `Cannot find module '../hooks/useFlags'`

- [ ] **Step 3: Create `admin/src/hooks/useFlags.ts`**

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabaseAdmin } from '../lib/supabase'
import type { StepFlag } from '../types'

export function useFlags() {
  const qc = useQueryClient()

  const flags = useQuery<StepFlag[]>({
    queryKey: ['flags', 'unreviewed'],
    queryFn: async () => {
      const { data, error } = await supabaseAdmin
        .from('step_flags')
        .select('*, users(name, phone), step_logs(steps, synced_at)')
        .eq('reviewed', false)
        .order('created_at', { ascending: false })
      if (error) throw error
      return data as StepFlag[]
    },
  })

  const reviewFlag = useMutation({
    mutationFn: async (flagId: string) => {
      const { error } = await supabaseAdmin
        .from('step_flags')
        .update({ reviewed: true })
        .eq('id', flagId)
      if (error) throw error
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['flags'] }),
  })

  return { flags, reviewFlag }
}
```

- [ ] **Step 4: Run hook test — verify it passes**

```bash
cd admin && npm test -- useFlags.test.ts
```
Expected: PASS — 1 test passing.

- [ ] **Step 5: Write the failing page test**

`admin/src/test/FraudAnalytics.test.tsx`:
```tsx
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, it, expect } from 'vitest'
import FraudAnalytics from '../pages/FraudAnalytics'

const mockReviewFlag = vi.fn()

vi.mock('../hooks/useFlags', () => ({
  useFlags: () => ({
    flags: {
      isLoading: false,
      isError: false,
      data: [
        {
          id: 'f1',
          user_id: 'u1',
          step_log_id: 'sl1',
          reason: 'rate_exceeded',
          reviewed: false,
          created_at: '2026-05-23T10:00:00Z',
          users: { name: 'Ravi Kumar', phone: '+919876543210' },
          step_logs: { steps: 55000, synced_at: '2026-05-23T09:45:00Z' },
        },
      ],
    },
    reviewFlag: { mutate: mockReviewFlag, isPending: false },
  }),
}))

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient()
  return (
    <QueryClientProvider client={qc}>
      <MemoryRouter>{children}</MemoryRouter>
    </QueryClientProvider>
  )
}

describe('FraudAnalytics', () => {
  it('renders flag row with user name and reason', () => {
    render(<FraudAnalytics />, { wrapper })
    expect(screen.getByText('Ravi Kumar')).toBeInTheDocument()
    expect(screen.getByText('rate_exceeded')).toBeInTheDocument()
  })

  it('calls reviewFlag.mutate when Dismiss is clicked', async () => {
    render(<FraudAnalytics />, { wrapper })
    await userEvent.click(screen.getByRole('button', { name: /dismiss/i }))
    await waitFor(() => expect(mockReviewFlag).toHaveBeenCalledWith('f1'))
  })
})
```

- [ ] **Step 6: Run test — verify it fails**

```bash
cd admin && npm test -- FraudAnalytics.test.tsx
```
Expected: FAIL — stub FraudAnalytics renders no rows.

- [ ] **Step 7: Replace `admin/src/pages/FraudAnalytics.tsx` with full implementation**

```tsx
import DataTable from '../components/DataTable'
import { useFlags } from '../hooks/useFlags'
import type { StepFlag } from '../types'

export default function FraudAnalytics() {
  const { flags, reviewFlag } = useFlags()

  const columns = [
    {
      key: 'user',
      header: 'User',
      render: (r: StepFlag) => (
        <div>
          <p className="font-medium text-sm">{r.users?.name ?? r.user_id}</p>
          <p className="text-xs text-gray-500">{r.users?.phone}</p>
        </div>
      ),
    },
    {
      key: 'reason',
      header: 'Reason',
      render: (r: StepFlag) => (
        <span className="px-2 py-0.5 rounded bg-pink/20 text-pink text-xs font-medium">
          {r.reason}
        </span>
      ),
    },
    {
      key: 'steps',
      header: 'Steps',
      render: (r: StepFlag) => (
        <span className="font-mono text-sm">{r.step_logs?.steps.toLocaleString() ?? '—'}</span>
      ),
    },
    {
      key: 'synced_at',
      header: 'Synced At',
      render: (r: StepFlag) => (
        <span className="text-xs text-gray-400">
          {r.step_logs?.synced_at
            ? new Date(r.step_logs.synced_at).toLocaleString('en-IN')
            : '—'}
        </span>
      ),
    },
    {
      key: 'flagged_at',
      header: 'Flagged At',
      render: (r: StepFlag) => (
        <span className="text-xs text-gray-400">
          {new Date(r.created_at).toLocaleString('en-IN')}
        </span>
      ),
    },
    {
      key: 'action',
      header: '',
      render: (r: StepFlag) => (
        <button
          onClick={() => reviewFlag.mutate(r.id)}
          disabled={reviewFlag.isPending}
          className="px-3 py-1 rounded-lg bg-neon/10 text-neon text-xs hover:bg-neon/20 disabled:opacity-50 transition-colors"
        >
          Dismiss
        </button>
      ),
    },
  ]

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-white">Fraud Analytics</h1>
        {flags.data && (
          <span className="text-sm text-gray-400">
            {flags.data.length} unreviewed flag{flags.data.length !== 1 ? 's' : ''}
          </span>
        )}
      </div>

      {flags.isLoading && <p className="text-gray-400 text-sm">Loading flags…</p>}
      {flags.isError && <p className="text-red-400 text-sm">Failed to load flags</p>}
      {flags.data && (
        <DataTable
          columns={columns}
          data={flags.data}
          keyField="id"
          emptyMessage="No unreviewed flags — platform is clean"
        />
      )}
    </div>
  )
}
```

- [ ] **Step 8: Run all tests**

```bash
cd admin && npm test
```
Expected: PASS — 8 tests passing.

- [ ] **Step 9: Commit**

```bash
git add admin/src/hooks/useFlags.ts admin/src/pages/FraudAnalytics.tsx admin/src/test/useFlags.test.ts admin/src/test/FraudAnalytics.test.tsx
git commit -m "feat: fraud analytics — flag review table with dismiss action"
```

---

### Task 7: Payout Approvals

**Files:**
- Modify: `backend/src/modules/wallet/wallet.router.ts` — add two new admin-only endpoints
- Modify: `backend/src/modules/wallet/wallet.service.ts` — add `approveWithdrawal` + `rejectWithdrawal`
- Create: `admin/src/hooks/usePayouts.ts`
- Modify: `admin/src/pages/PayoutApprovals.tsx`
- Test: `admin/src/test/usePayouts.test.ts`

**Note:** This task requires two backend changes. The current wallet flow debits the ledger immediately on `/wallet/withdraw`. For admin approval, we add a `pending_approval` status and two new admin endpoints.

- [ ] **Step 1: Add status field to wallet_transactions in backend migration**

Create `backend/supabase/migrations/0002_wallet_payout_status.sql`:
```sql
ALTER TABLE wallet_transactions
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'completed';

UPDATE wallet_transactions SET status = 'completed' WHERE status = '';

-- Pending withdrawal rows: type = 'withdrawal', status = 'pending_approval'
CREATE INDEX IF NOT EXISTS idx_wallet_tx_status ON wallet_transactions(status) WHERE status = 'pending_approval';
```

Run against your Supabase project:
```bash
cd backend && npx supabase db push
```
Expected: migration applied without error.

- [ ] **Step 2: Add `approveWithdrawal` and `rejectWithdrawal` to backend wallet service**

Add to `backend/src/modules/wallet/wallet.service.ts`:
```ts
export async function approveWithdrawal(transactionId: string): Promise<void> {
  const { data: tx, error: fetchErr } = await supabase
    .from('wallet_transactions')
    .select('*')
    .eq('id', transactionId)
    .eq('status', 'pending_approval')
    .single()

  if (fetchErr || !tx) throw new Error('Transaction not found or not pending')

  const { data: user } = await supabase
    .from('users')
    .select('kyc_verified')
    .eq('id', tx.user_id)
    .single()

  if (!user?.kyc_verified) throw new Error('User KYC not verified')

  const payout = await razorpay.payouts.create({
    account_number: process.env.RAZORPAY_ACCOUNT_NUMBER!,
    amount: tx.amount,
    currency: 'INR',
    mode: 'UPI',
    purpose: 'payout',
    fund_account_id: tx.reference_id!,
  })

  await supabase
    .from('wallet_transactions')
    .update({ status: 'processing', reference_id: payout.id })
    .eq('id', transactionId)
}

export async function rejectWithdrawal(transactionId: string): Promise<void> {
  const { data: tx, error: fetchErr } = await supabase
    .from('wallet_transactions')
    .select('amount, user_id')
    .eq('id', transactionId)
    .eq('status', 'pending_approval')
    .single()

  if (fetchErr || !tx) throw new Error('Transaction not found or not pending')

  await supabase.from('wallet_transactions').insert({
    id: crypto.randomUUID(),
    user_id: tx.user_id,
    type: 'refund',
    amount: tx.amount,
    idempotency_key: `refund_${transactionId}`,
    description: 'Withdrawal rejected — refund',
    status: 'completed',
    created_at: new Date().toISOString(),
  })

  await supabase
    .from('wallet_transactions')
    .update({ status: 'rejected' })
    .eq('id', transactionId)
}
```

- [ ] **Step 3: Add admin payout endpoints to backend wallet router**

Add to `backend/src/modules/wallet/wallet.router.ts` (after existing routes):
```ts
// Admin-only: must have admin middleware
router.post('/payout/approve/:id', authMiddleware, async (req, res) => {
  if (!req.user?.is_admin) return res.status(403).json({ error: 'Forbidden' })
  try {
    await approveWithdrawal(req.params.id)
    res.json({ success: true })
  } catch (err) {
    res.status(400).json({ error: (err as Error).message })
  }
})

router.post('/payout/reject/:id', authMiddleware, async (req, res) => {
  if (!req.user?.is_admin) return res.status(403).json({ error: 'Forbidden' })
  try {
    await rejectWithdrawal(req.params.id)
    res.json({ success: true })
  } catch (err) {
    res.status(400).json({ error: (err as Error).message })
  }
})
```

Add `is_admin?: boolean` to the `AuthUser` interface in `backend/src/types/index.ts`:
```ts
interface AuthUser {
  id: string
  email?: string
  is_admin?: boolean
}
```

Update `backend/src/gateway/middleware/auth.ts` to check `users.is_admin` flag:
```ts
// After verifying JWT and fetching user, add:
const { data: profile } = await supabase
  .from('users')
  .select('is_admin')
  .eq('id', session.user.id)
  .single()

req.user = { ...session.user, is_admin: profile?.is_admin ?? false }
```

Add `is_admin bool DEFAULT false` column to users table:
```sql
-- Add to Supabase migration or run manually:
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin bool DEFAULT false;
```

- [ ] **Step 4: Write the failing admin payout hook test**

`admin/src/test/usePayouts.test.ts`:
```ts
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { vi, describe, it, expect } from 'vitest'
import { usePayouts } from '../hooks/usePayouts'

const mockFrom = vi.fn()
vi.mock('../lib/supabase', () => ({
  supabaseAdmin: { from: mockFrom },
}))

vi.mock('../lib/api', () => ({
  default: {
    post: vi.fn().mockResolvedValue({ data: { success: true } }),
  },
}))

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>
}

describe('usePayouts', () => {
  it('fetches pending withdrawal transactions', async () => {
    const txs = [
      {
        id: 'tx1', user_id: 'u1', type: 'withdrawal', amount: 50000,
        idempotency_key: 'ik1', reference_id: null, description: 'Withdrawal',
        created_at: '2026-05-23T10:00:00Z', status: 'pending_approval',
        users: { name: 'Priya Sharma', phone: '+919123456789' },
      },
    ]
    mockFrom.mockReturnValue({
      select: () => ({
        eq: () => ({
          is: () => ({
            order: () => Promise.resolve({ data: txs, error: null }),
          }),
        }),
      }),
    })

    const { result } = renderHook(() => usePayouts(), { wrapper })
    await waitFor(() => expect(result.current.pendingPayouts.isSuccess).toBe(true))
    expect(result.current.pendingPayouts.data).toHaveLength(1)
    expect(result.current.pendingPayouts.data![0].users?.name).toBe('Priya Sharma')
  })
})
```

- [ ] **Step 5: Run test — verify it fails**

```bash
cd admin && npm test -- usePayouts.test.ts
```
Expected: FAIL — `Cannot find module '../hooks/usePayouts'`

- [ ] **Step 6: Create `admin/src/hooks/usePayouts.ts`**

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabaseAdmin } from '../lib/supabase'
import api from '../lib/api'
import type { WalletTransaction } from '../types'

export function usePayouts() {
  const qc = useQueryClient()

  const pendingPayouts = useQuery<WalletTransaction[]>({
    queryKey: ['payouts', 'pending'],
    queryFn: async () => {
      const { data, error } = await supabaseAdmin
        .from('wallet_transactions')
        .select('*, users(name, phone)')
        .eq('type', 'withdrawal')
        .eq('status', 'pending_approval')
        .order('created_at', { ascending: true })
      if (error) throw error
      return data as WalletTransaction[]
    },
  })

  const approve = useMutation({
    mutationFn: (id: string) => api.post(`/wallet/payout/approve/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payouts'] }),
  })

  const reject = useMutation({
    mutationFn: (id: string) => api.post(`/wallet/payout/reject/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payouts'] }),
  })

  return { pendingPayouts, approve, reject }
}
```

- [ ] **Step 7: Run hook test — verify it passes**

```bash
cd admin && npm test -- usePayouts.test.ts
```
Expected: PASS — 1 test passing.

- [ ] **Step 8: Replace `admin/src/pages/PayoutApprovals.tsx` with full implementation**

```tsx
import DataTable from '../components/DataTable'
import { usePayouts } from '../hooks/usePayouts'
import type { WalletTransaction } from '../types'

export default function PayoutApprovals() {
  const { pendingPayouts, approve, reject } = usePayouts()

  const columns = [
    {
      key: 'user',
      header: 'User',
      render: (r: WalletTransaction) => (
        <div>
          <p className="font-medium text-sm">{r.users?.name ?? r.user_id}</p>
          <p className="text-xs text-gray-500">{r.users?.phone}</p>
        </div>
      ),
    },
    {
      key: 'amount',
      header: 'Amount',
      render: (r: WalletTransaction) => (
        <span className="text-neon font-semibold">
          ₹{(r.amount / 100).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
        </span>
      ),
    },
    {
      key: 'description',
      header: 'Description',
      render: (r: WalletTransaction) => <span className="text-xs text-gray-400">{r.description}</span>,
    },
    {
      key: 'requested_at',
      header: 'Requested',
      render: (r: WalletTransaction) => (
        <span className="text-xs text-gray-400">
          {new Date(r.created_at).toLocaleString('en-IN')}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (r: WalletTransaction) => (
        <div className="flex gap-2">
          <button
            onClick={() => approve.mutate(r.id)}
            disabled={approve.isPending || reject.isPending}
            className="px-3 py-1 rounded-lg bg-neon/10 text-neon text-xs hover:bg-neon/20 disabled:opacity-50 transition-colors"
          >
            Approve
          </button>
          <button
            onClick={() => reject.mutate(r.id)}
            disabled={approve.isPending || reject.isPending}
            className="px-3 py-1 rounded-lg bg-red-500/10 text-red-400 text-xs hover:bg-red-500/20 disabled:opacity-50 transition-colors"
          >
            Reject
          </button>
        </div>
      ),
    },
  ]

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-white">Payout Approvals</h1>
        {pendingPayouts.data && (
          <span className="text-sm text-gray-400">
            {pendingPayouts.data.length} pending
          </span>
        )}
      </div>

      {pendingPayouts.isLoading && <p className="text-gray-400 text-sm">Loading payouts…</p>}
      {pendingPayouts.isError && <p className="text-red-400 text-sm">Failed to load payouts</p>}
      {pendingPayouts.data && (
        <DataTable
          columns={columns}
          data={pendingPayouts.data}
          keyField="id"
          emptyMessage="No pending payouts"
        />
      )}
    </div>
  )
}
```

- [ ] **Step 9: Run all tests**

```bash
cd admin && npm test
```
Expected: PASS — 9 tests passing.

- [ ] **Step 10: Commit**

```bash
git add admin/src/hooks/usePayouts.ts admin/src/pages/PayoutApprovals.tsx admin/src/test/usePayouts.test.ts backend/src/modules/wallet/wallet.service.ts backend/src/modules/wallet/wallet.router.ts backend/supabase/migrations/0002_wallet_payout_status.sql
git commit -m "feat: payout approvals — pending withdrawals, approve/reject with refund on reject"
```

---

### Task 8: User Management

**Files:**
- Create: `admin/src/hooks/useUsers.ts`
- Modify: `admin/src/pages/UserManagement.tsx`
- Modify: `admin/src/pages/UserDetail.tsx`
- Test: `admin/src/test/useUsers.test.ts`

- [ ] **Step 1: Write the failing hook test**

`admin/src/test/useUsers.test.ts`:
```ts
import { renderHook, waitFor, act } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { vi, describe, it, expect } from 'vitest'
import { useUserSearch, useUserDetail } from '../hooks/useUsers'

const mockFrom = vi.fn()
vi.mock('../lib/supabase', () => ({
  supabaseAdmin: { from: mockFrom },
}))

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>
}

describe('useUserSearch', () => {
  it('returns empty array when query is blank', () => {
    const { result } = renderHook(() => useUserSearch(''), { wrapper })
    expect(result.current.data).toEqual([])
    expect(result.current.isLoading).toBe(false)
  })

  it('calls Supabase with OR filter when query is provided', async () => {
    const users = [{ id: 'u1', name: 'Ravi Kumar', phone: '+919876543210' }]
    mockFrom.mockReturnValue({
      select: () => ({
        or: () => ({ limit: () => Promise.resolve({ data: users, error: null }) }),
      }),
    })

    const { result } = renderHook(() => useUserSearch('Ravi'), { wrapper })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toHaveLength(1)
  })
})

describe('useUserDetail', () => {
  it('fetches user with badges when userId is provided', async () => {
    const user = { id: 'u1', name: 'Ravi', phone: '+919876543210', user_badges: [] }
    mockFrom.mockReturnValue({
      select: () => ({
        eq: () => ({ single: () => Promise.resolve({ data: user, error: null }) }),
      }),
    })

    const { result } = renderHook(() => useUserDetail('u1'), { wrapper })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data?.name).toBe('Ravi')
  })
})
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd admin && npm test -- useUsers.test.ts
```
Expected: FAIL — `Cannot find module '../hooks/useUsers'`

- [ ] **Step 3: Create `admin/src/hooks/useUsers.ts`**

```ts
import { useQuery } from '@tanstack/react-query'
import { supabaseAdmin } from '../lib/supabase'
import type { User, UserBadge, WalletTransaction } from '../types'

export function useUserSearch(query: string) {
  return useQuery<User[]>({
    queryKey: ['users', 'search', query],
    enabled: query.trim().length > 0,
    queryFn: async () => {
      const { data, error } = await supabaseAdmin
        .from('users')
        .select('*')
        .or(`name.ilike.%${query}%,phone.like.%${query}%`)
        .limit(20)
      if (error) throw error
      return data as User[]
    },
    placeholderData: [],
  })
}

export function useUserDetail(userId: string) {
  return useQuery<User & { user_badges: UserBadge[] }>({
    queryKey: ['users', userId],
    enabled: Boolean(userId),
    queryFn: async () => {
      const { data, error } = await supabaseAdmin
        .from('users')
        .select('*, user_badges(*)')
        .eq('id', userId)
        .single()
      if (error) throw error
      return data as User & { user_badges: UserBadge[] }
    },
  })
}

export function useUserTransactions(userId: string) {
  return useQuery<WalletTransaction[]>({
    queryKey: ['users', userId, 'transactions'],
    enabled: Boolean(userId),
    queryFn: async () => {
      const { data, error } = await supabaseAdmin
        .from('wallet_transactions')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(20)
      if (error) throw error
      return data as WalletTransaction[]
    },
  })
}
```

- [ ] **Step 4: Run hook tests — verify they pass**

```bash
cd admin && npm test -- useUsers.test.ts
```
Expected: PASS — 3 tests passing.

- [ ] **Step 5: Replace `admin/src/pages/UserManagement.tsx` with full implementation**

```tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import DataTable from '../components/DataTable'
import { useUserSearch } from '../hooks/useUsers'
import type { User } from '../types'

export default function UserManagement() {
  const [query, setQuery] = useState('')
  const navigate = useNavigate()
  const { data: users, isLoading } = useUserSearch(query)

  const columns = [
    {
      key: 'name',
      header: 'Name',
      render: (r: User) => (
        <button
          onClick={() => navigate(`/users/${r.id}`)}
          className="font-medium text-primary hover:underline text-left"
        >
          {r.name}
        </button>
      ),
    },
    { key: 'phone', header: 'Phone', render: (r: User) => <span className="text-sm text-gray-300">{r.phone}</span> },
    { key: 'city', header: 'City', render: (r: User) => <span className="text-sm text-gray-400">{r.city}</span> },
    {
      key: 'league',
      header: 'League',
      render: (r: User) => (
        <span className="capitalize text-amber text-xs font-medium">{r.league}</span>
      ),
    },
    { key: 'xp', header: 'XP', render: (r: User) => <span className="font-mono text-sm">{r.xp.toLocaleString()}</span> },
    {
      key: 'kyc',
      header: 'KYC',
      render: (r: User) => (
        <span className={r.kyc_verified ? 'text-neon text-xs' : 'text-gray-500 text-xs'}>
          {r.kyc_verified ? 'Verified' : 'Pending'}
        </span>
      ),
    },
  ]

  return (
    <div className="p-6 space-y-5">
      <h1 className="text-xl font-bold text-white">User Management</h1>

      <input
        type="text"
        placeholder="Search by name or phone…"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        className="w-full max-w-md px-4 py-2 rounded-xl bg-card border border-border text-white text-sm placeholder-gray-500 focus:outline-none focus:border-primary"
      />

      {isLoading && query && <p className="text-gray-400 text-sm">Searching…</p>}

      {users && users.length > 0 && (
        <DataTable columns={columns} data={users} keyField="id" emptyMessage="No users found" />
      )}

      {!query && (
        <p className="text-gray-500 text-sm">Enter a name or phone number to search</p>
      )}
    </div>
  )
}
```

- [ ] **Step 6: Replace `admin/src/pages/UserDetail.tsx` with full implementation**

```tsx
import { useParams, useNavigate } from 'react-router-dom'
import { useUserDetail, useUserTransactions } from '../hooks/useUsers'
import DataTable from '../components/DataTable'
import type { WalletTransaction } from '../types'

export default function UserDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: user, isLoading, isError } = useUserDetail(id!)
  const { data: txs } = useUserTransactions(id!)

  if (isLoading) return <div className="p-6 text-gray-400 text-sm">Loading user…</div>
  if (isError || !user) return <div className="p-6 text-red-400 text-sm">User not found</div>

  const txColumns = [
    {
      key: 'type',
      header: 'Type',
      render: (r: WalletTransaction) => (
        <span className={`text-xs font-medium ${r.type === 'credit' ? 'text-neon' : 'text-pink'}`}>
          {r.type}
        </span>
      ),
    },
    {
      key: 'amount',
      header: 'Amount',
      render: (r: WalletTransaction) => (
        <span className="font-mono text-sm">
          ₹{(r.amount / 100).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
        </span>
      ),
    },
    {
      key: 'description',
      header: 'Description',
      render: (r: WalletTransaction) => <span className="text-xs text-gray-400">{r.description}</span>,
    },
    {
      key: 'date',
      header: 'Date',
      render: (r: WalletTransaction) => (
        <span className="text-xs text-gray-500">
          {new Date(r.created_at).toLocaleString('en-IN')}
        </span>
      ),
    },
  ]

  return (
    <div className="p-6 space-y-6">
      <button onClick={() => navigate('/users')} className="text-xs text-gray-400 hover:text-white mb-2">
        ← Back to Users
      </button>

      <div className="p-5 rounded-2xl bg-card border border-border space-y-4">
        <h1 className="text-xl font-bold">{user.name}</h1>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <Info label="Phone" value={user.phone} />
          <Info label="City" value={user.city} />
          <Info label="Language" value={user.language} />
          <Info label="League" value={user.league} color="text-amber capitalize" />
          <Info label="XP" value={user.xp.toLocaleString()} color="text-primary" />
          <Info label="Streak" value={`${user.streak_days} days`} color="text-pink" />
          <Info label="KYC" value={user.kyc_verified ? 'Verified' : 'Pending'} color={user.kyc_verified ? 'text-neon' : 'text-gray-500'} />
          <Info label="Joined" value={new Date(user.created_at).toLocaleDateString('en-IN')} />
        </div>
      </div>

      {user.user_badges.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-semibold text-gray-300">Badges</h2>
          <div className="flex flex-wrap gap-2">
            {user.user_badges.map((b) => (
              <span key={b.id} className="px-3 py-1 rounded-full bg-accent/20 text-accent text-xs font-medium">
                {b.badge_slug}
              </span>
            ))}
          </div>
        </div>
      )}

      <div className="space-y-3">
        <h2 className="text-sm font-semibold text-gray-300">Recent Transactions</h2>
        {txs ? (
          <DataTable columns={txColumns} data={txs} keyField="id" emptyMessage="No transactions" />
        ) : (
          <p className="text-gray-500 text-sm">Loading…</p>
        )}
      </div>
    </div>
  )
}

function Info({
  label,
  value,
  color = 'text-white',
}: {
  label: string
  value: string
  color?: string
}) {
  return (
    <div>
      <p className="text-xs text-gray-500 mb-0.5">{label}</p>
      <p className={`font-medium ${color}`}>{value}</p>
    </div>
  )
}
```

- [ ] **Step 7: Run all tests**

```bash
cd admin && npm test
```
Expected: PASS — 12 tests passing.

- [ ] **Step 8: Build and verify no TypeScript errors**

```bash
cd admin && npm run build
```
Expected: build completes with 0 errors.

- [ ] **Step 9: Commit**

```bash
git add admin/src/hooks/useUsers.ts admin/src/pages/UserManagement.tsx admin/src/pages/UserDetail.tsx admin/src/test/useUsers.test.ts
git commit -m "feat: user management — search, profile, badge history, wallet transactions"
```

---

### Task 9: Vercel Deployment

**Files:**
- Create: `admin/.gitignore`
- Verify: `admin/vercel.json`

- [ ] **Step 1: Create `admin/.gitignore`**

```
node_modules/
dist/
.env
.env.local
```

- [ ] **Step 2: Build for production**

```bash
cd admin && npm run build
```
Expected: `dist/` created with `index.html` and hashed JS/CSS bundles. No TypeScript errors.

- [ ] **Step 3: Deploy to Vercel**

```bash
cd admin && npx vercel --prod
```
When prompted:
- **Set up and deploy?** Yes
- **Project name:** stepup-admin
- **Framework:** Vite
- **Build command:** `npm run build`
- **Output directory:** `dist`
- **Install command:** `npm install`

After first deploy, add environment variables in Vercel dashboard:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_SUPABASE_SERVICE_KEY`
- `VITE_API_URL`
- `VITE_ADMIN_EMAILS`

Expected: Vercel returns a URL like `https://stepup-admin.vercel.app`.

- [ ] **Step 4: Verify SPA routing**

Open `https://stepup-admin.vercel.app/dashboard` directly (simulate hard refresh).
Expected: app loads (not 404) because `vercel.json` rewrites all paths to `index.html`.

- [ ] **Step 5: Create admin user in Supabase**

In Supabase dashboard → Authentication → Users → Invite user with the email set in `VITE_ADMIN_EMAILS`. Then in SQL editor:
```sql
UPDATE users SET is_admin = true WHERE phone = 'your-phone';
-- Or if admin doesn't have a users row yet (no phone registration):
INSERT INTO users (id, phone, name, city, language, goal_tier, is_admin)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'admin@stepup.in'),
  '', 'Admin', 'Hyderabad', 'English', 'elite', true
) ON CONFLICT (id) DO UPDATE SET is_admin = true;
```

- [ ] **Step 6: Final commit**

```bash
git add admin/.gitignore
git commit -m "chore: admin dashboard complete — deployed to Vercel"
```

---

## Self-Review

**Spec coverage:**
- Admin dashboard (fraud analytics, challenge management, payout approvals) — ✅ Tasks 5, 6, 7
- Auth with admin-only gate — ✅ Task 2
- Dashboard metrics (active users, step syncs, challenges, flags, revenue) — ✅ Task 4
- User management (search, profile, badge history) — ✅ Task 8
- Vercel deployment — ✅ Task 9

**Backend dependencies added by this plan:**
- `wallet_transactions.status` column (Task 7, Step 1)
- `users.is_admin` column (Task 7, Step 3)
- `POST /wallet/payout/approve/:id` and `POST /wallet/payout/reject/:id` endpoints (Task 7, Steps 2–3)
- `is_admin` check in auth middleware (Task 7, Step 3)

These changes must be applied to the backend (`2026-05-23-backend-api.md` plan) before the payout approvals feature can be used in production.

**Type consistency check:**
- `WalletTransaction` used in `usePayouts.ts`, `useUsers.ts`, `PayoutApprovals.tsx`, `UserDetail.tsx` — all import from `types/index.ts` ✅
- `StepFlag` in `useFlags.ts` and `FraudAnalytics.tsx` — consistent `users` and `step_logs` join shape ✅
- `Challenge` and `ChallengeFormData` both exported from types, used in hooks and pages ✅
- `useDashboard` returns `DashboardStats`, `useDailyStepChart` returns `ChartPoint[]` — both exported ✅
