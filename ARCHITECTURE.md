# Daily Planner Application — Architecture & Technical Guide

Welcome! This document outlines the architectural blueprint, technology choices, database structure, and step-by-step roadmap for building your interactive Daily Planner application.

---

## 1. Technology Stack Overview

| Layer | Recommended Technology | Why This Choice? |
| :--- | :--- | :--- |
| **Frontend Framework** | **Vue 3** (Composition API) + **Vite** | Vue 3 is clean, intuitive, and beginner-friendly. Single-file components (`.vue`) keep HTML, CSS, and JS together cleanly. Vite provides lightning-fast build speeds. |
| **Styling & UI** | **Tailwind CSS** | Allows rapid styling using utility classes without managing massive custom CSS files. Perfect for modern, pretty UI. |
| **Backend / Database** | **Supabase** | Open-source Firebase alternative powered by PostgreSQL. Handles User Authentication, Database CRUD, and Row Level Security (RLS) out-of-the-box. |
| **State & Routing** | **Pinia** + **Vue Router** | Pinia handles global app state (e.g., current user, active date), while Vue Router manages page navigation (`/login`, `/planner`, `/share/:shareToken`). |
| **Hosting & Deployment**| **Cloudflare Pages** | Free, fast global CDN hosting. Syncs directly with your GitHub repository to auto-deploy on every `git push`. |

---

## 2. System Architecture & Data Flow

```
+-------------------------------------------------------------+
|                      Cloudflare Pages                       |
|  Vue 3 Single Page Application (SPA) + Tailwind CSS        |
|                                                             |
|   +-------------------+    +----------------------------+   |
|   |  Auth Views       |    |  Daily Planner Views       |   |
|   |  (Login/Register) |    |  (Tasks, Notes, Calendar)  |   |
|   +-------------------+    +----------------------------+   |
+-------------------------------------------------------------+
                              |
                     @supabase/supabase-js
                              |
                              v
+-------------------------------------------------------------+
|                          Supabase                           |
|                                                             |
|  +--------------------+   +------------------------------+  |
|  | Auth Service       |   | PostgreSQL Database          |  |
|  | (JWT, User Accounts|   | (Profiles, Planners, Tasks)  |  |
|  +--------------------+   +------------------------------+  |
|                                          |                  |
|                           Row Level Security (RLS)          |
+-------------------------------------------------------------+
```

---

## 3. Database Schema Design (Supabase PostgreSQL)

### A. Tables

1. **`profiles`**
   - `id` (uuid, primary key, references `auth.users.id`)
   - `display_name` (text)
   - `created_at` (timestamp)

2. **`planners`** (Daily planner entry for a user on a given date)
   - `id` (uuid, primary key, default `gen_random_uuid()`)
   - `user_id` (uuid, references `profiles.id`)
   - `planner_date` (date) — e.g. `2026-07-25`
   - `daily_goal` (text)
   - `notes` (text)
   - `is_public` (boolean, default `false`) — Controls whether the planner can be shared via link
   - `share_token` (uuid, default `gen_random_uuid()`) — Unique link for public sharing
   - `created_at` (timestamp)

3. **`tasks`**
   - `id` (uuid, primary key, default `gen_random_uuid()`)
   - `planner_id` (uuid, references `planners.id` with CASCADE delete)
   - `title` (text)
   - `category` (text) — e.g. "Work", "Personal", "Health"
   - `time_block` (text) — e.g. "09:00 - 10:00"
   - `is_completed` (boolean, default `false`)
   - `position` (integer) — For drag-and-drop or re-ordering tasks
   - `created_at` (timestamp)

---

## 4. Sharing Mechanism Strategy

To share a daily planner with other users cleanly and securely:
1. **Public Share Link**: Each planner has an `is_public` boolean flag and a unique `share_token`.
2. When the user toggles **"Share Planner"**, `is_public` becomes `true`.
3. The app generates a shareable URL: `https://your-domain.pages.dev/planner/share/:share_token`.
4. **Row Level Security (RLS)** in Supabase ensures:
   - Users can read, update, and delete their own planners.
   - Anyone (even non-logged-in users) can read a planner if `is_public = true` matching the `share_token`.

---

## 5. Recommended Project Directory Structure

```
daily-planner/
├── public/
│   └── favicon.ico
├── src/
│   ├── assets/          # Stylesheets, icons, images
│   ├── components/      # Reusable UI components (TaskItem.vue, CalendarHeader.vue)
│   ├── views/           # Route pages (HomeView.vue, PlannerView.vue, SharedView.vue)
│   ├── stores/          # Pinia stores (authStore.js, plannerStore.js)
│   ├── lib/             # Supabase client setup (supabase.js)
│   ├── router/          # Vue Router configuration
│   ├── App.vue          # Root Vue Component
│   └── main.js          # Vue app entry point
├── .env.example         # Template for Supabase URL & Key
├── index.html
├── package.json
└── vite.config.js
```

---

## 6. Implementation Roadmap

1. **Phase 1: Project Scaffolding & Setup**
   - Initialize Vue 3 + Vite project with Tailwind CSS.
   - Setup Supabase project on `supabase.com` and obtain project keys.
   - Configure local environment variables (`.env`).

2. **Phase 2: Authentication & Database Tables**
   - Create tables (`profiles`, `planners`, `tasks`) and RLS policies in Supabase SQL editor.
   - Implement Login / Sign Up views using Supabase Auth.

3. **Phase 3: Core Daily Planner Features**
   - Date picker to switch between days.
   - Task creation, completion toggles, deletion, and editing.
   - Daily goal and notes text input with auto-save or save button.

4. **Phase 4: Sharing & Social Features**
   - "Share Day" toggle & share link generator.
   - Shared viewer page (read-only view for visitors with shared link).

5. **Phase 5: Deployment to Cloudflare Pages**
   - Push code to GitHub repository.
   - Link GitHub repo to Cloudflare Pages for automatic deployments.
