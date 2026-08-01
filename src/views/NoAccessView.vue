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
      <div class="w-12 h-12 bg-amber-100 text-amber-600 rounded-full flex items-center justify-center mx-auto mb-4 font-bold text-xl">
        !
      </div>
      <h2 class="text-2xl font-bold text-slate-900 mb-2">No Access Assigned</h2>
      <p class="text-slate-500 text-sm mb-6">
        Your account currently does not have an assigned role. Please contact an administrator to request access.
      </p>
      <button @click="handleSignOut"
        class="w-full py-2.5 px-4 bg-[#1f5fbf] text-white font-medium rounded-lg hover:bg-[#1a4f9e] transition-colors text-sm">
        Sign out
      </button>
    </div>
  </div>
</template>
