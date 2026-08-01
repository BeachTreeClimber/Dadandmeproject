<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserProfile } from './composables/useUserProfile'
import { useRole } from './composables/useRole'
import { supabase } from './supabase/client'
import { APP_NAME } from './config'
import NotInvitedView from './views/NotInvitedView.vue'

document.title = APP_NAME

const router = useRouter()
const { profile, loading: profileLoading, needsInvite, clearProfile } = useUserProfile()
const { roles, loading: roleLoading, hasRole, clearRole } = useRole()

const session = ref(undefined)

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  session.value = data.session
})

const isLoggedIn = computed(() => !!session.value)
const sessionChecked = computed(() => session.value !== undefined)
const initials = computed(() => {
  const name = profile.value?.display_name || profile.value?.email || ''
  return name.charAt(0).toUpperCase()
})

const handleSignOut = async () => {
  try {
    await supabase.auth.signOut()
  } catch (err) {
    console.error('Sign out error:', err)
  } finally {
    clearProfile()
    clearRole()
    session.value = null
    router.push('/login')
  }
}
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-[#d9d4c4] via-[#c7c1ac] to-[#b8b19a] text-slate-800">

    <nav class="bg-[#f6f5ef]/95 backdrop-blur border-b border-[#c9c2ab] sticky top-0 z-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6">
        <div class="flex items-center justify-between min-h-14 gap-2">

          <div class="flex items-center gap-4 min-w-0">
            <router-link to="/" class="text-xl sm:text-2xl font-bold text-[#1f5fbf] tracking-tight shrink-0" style="font-family: 'Kalam', cursive;">
              {{ APP_NAME }}
            </router-link>

            <router-link v-if="isLoggedIn && hasRole('admin') && !roleLoading" to="/admin"
              class="text-sm font-medium text-slate-600 hover:text-[#1f5fbf] transition-colors shrink-0">
              Manage Access
            </router-link>

            <router-link v-if="isLoggedIn && hasRole('admin') && !roleLoading" to="/settings"
              class="text-sm font-medium text-slate-600 hover:text-[#1f5fbf] transition-colors shrink-0">
              Settings
            </router-link>
          </div>

          <div class="flex items-center gap-2 shrink-0">
            <template v-if="!sessionChecked">
              <div class="w-5 h-5 border-2 border-[#1f5fbf] border-t-transparent rounded-full animate-spin"></div>
            </template>

            <template v-else-if="isLoggedIn && profile && !roleLoading">
              <div class="flex items-center gap-2">
                <span class="w-8 h-8 rounded-full bg-[#1f5fbf] text-white text-sm font-bold flex items-center justify-center">
                  {{ initials }}
                </span>
                <button @click="handleSignOut"
                  class="inline-flex items-center px-4 py-1.5 text-sm font-medium text-slate-700 border border-[#b9b4a4] bg-white hover:bg-slate-100 rounded-lg transition-colors">
                  Sign out
                </button>
              </div>
            </template>

            <template v-else-if="isLoggedIn">
              <div class="w-5 h-5 border-2 border-[#1f5fbf] border-t-transparent rounded-full animate-spin"></div>
            </template>

            <router-link v-else to="/login"
              class="inline-flex items-center px-4 py-1.5 text-sm font-medium text-white bg-[#1f5fbf] hover:bg-[#1a4f9e] rounded-lg transition-colors">
              Login
            </router-link>
          </div>
        </div>
      </div>
    </nav>

    <main>
      <div v-if="!sessionChecked || (isLoggedIn && profileLoading)" class="flex items-center justify-center py-16">
        <div class="flex flex-col items-center gap-3">
          <div class="w-8 h-8 border-4 border-[#1f5fbf] border-t-transparent rounded-full animate-spin"></div>
          <p class="text-sm font-medium text-slate-600">Loading...</p>
        </div>
      </div>

      <NotInvitedView v-else-if="needsInvite" />

      <router-view v-else :key="session" />
    </main>

  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Kalam:wght@400;700&family=Inter:wght@400;500;600;700&display=swap');
</style>
