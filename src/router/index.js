import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../supabase/client'
import { useRole } from '../composables/useRole'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
  },
  {
    path: '/callback',
    name: 'Callback',
    component: () => import('../views/CallbackView.vue'),
  },
  {
    path: '/no-access',
    name: 'NoAccess',
    component: () => import('../views/NoAccessView.vue'),
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('../views/SettingsView.vue'),
    meta: { requiresAuth: true, role: ['admin'] },
  },
  {
    path: '/admin',
    name: 'Admin',
    component: () => import('../views/AdminView.vue'),
    meta: { requiresAuth: true, role: ['admin'] },
  },
  {
    path: '/',
    name: 'Home',
    component: () => import('../views/HomeView.vue'),
    meta: { requiresAuth: true, role: ['admin', 'edit'] },
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/',
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to, from, next) => {
  const { data: { session } } = await supabase.auth.getSession()

  if (to.meta.requiresAuth && !session) {
    next({ name: 'Login' })
    return
  }

  if (session && to.name === 'Login') {
    next({ name: 'Home' })
    return
  }

  if (session && to.meta.role) {
    const { fetchRole } = useRole()
    const userRoles = await fetchRole()

    if (!userRoles.some(r => to.meta.role.includes(r))) {
      if (to.name === 'NoAccess') {
        next()
      } else {
        next({ name: 'NoAccess' })
      }
      return
    }
  }

  next()
})

export default router
