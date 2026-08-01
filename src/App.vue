<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from './supabase/client'
import { APP_NAME } from './config'

document.title = APP_NAME

const router = useRouter()
const session = ref(undefined)

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  session.value = data.session
})

const isLoggedIn = computed(() => !!session.value)
const sessionChecked = computed(() => session.value !== undefined)

const handleSignOut = async () => {
  try {
    await supabase.auth.signOut()
  } catch (err) {
    console.error('Sign out error:', err)
  } finally {
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

          <router-link to="/" class="text-xl sm:text-2xl font-bold text-[#1f5fbf] tracking-tight" style="font-family: 'Kalam', cursive;">
            {{ APP_NAME }}
          </router-link>

          <div class="flex items-center gap-2">
            <template v-if="!sessionChecked">
              <div class="w-5 h-5 border-2 border-[#1f5fbf] border-t-transparent rounded-full animate-spin"></div>
            </template>
            <template v-else-if="isLoggedIn">
              <button @click="handleSignOut"
                class="inline-flex items-center px-4 py-1.5 text-sm font-medium text-slate-700 border border-[#b9b4a4] bg-white hover:bg-slate-100 rounded-lg transition-colors">
                Sign out
              </button>
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
      <router-view :key="session" />
    </main>

  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Kalam:wght@400;700&family=Inter:wght@400;500;600;700&display=swap');
</style>
