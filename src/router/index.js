import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../supabase/client'

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
    path: '/',
    name: 'Home',
    component: () => import('../views/HomeView.vue'),
    meta: { requiresAuth: true },
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

  next()
})

export default router
