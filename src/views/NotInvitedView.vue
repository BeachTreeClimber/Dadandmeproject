<script setup>
import { useRouter } from 'vue-router'
import { supabase } from '../supabase/client'
import { useUserProfile } from '../composables/useUserProfile'
import { useRole } from '../composables/useRole'

const router = useRouter()
const { clearProfile } = useUserProfile()
const { clearRole } = useRole()

const handleSignOut = async () => {
  try {
    await supabase.auth.signOut()
  } catch (err) {
    console.error('Sign out error:', err)
  } finally {
    clearProfile()
    clearRole()
    router.push('/login')
  }
}
</script>

<template>
  <div class="py-12 flex items-center justify-center p-4">
    <div class="bg-white/95 rounded-2xl shadow-2xl border border-[#c9c2ab] p-8 max-w-md w-full text-center">
      <div class="w-14 h-14 bg-amber-100 text-amber-600 rounded-full flex items-center justify-center mx-auto mb-6 font-bold text-2xl">
        ?
      </div>
      <h2 class="text-2xl font-bold text-slate-900 mb-2">You haven't been invited yet</h2>
      <p class="text-slate-500 text-sm mb-8 leading-relaxed">
        Your email address is not on the approved list. Ask an administrator to add you, then sign in again.
      </p>
      <button @click="handleSignOut"
        class="w-full py-2.5 px-4 bg-[#1f5fbf] text-white font-medium rounded-lg hover:bg-[#1a4f9e] transition-colors text-sm">
        Sign out
      </button>
    </div>
  </div>
</template>
