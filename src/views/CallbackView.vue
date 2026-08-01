<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase/client'

const router = useRouter()

onMounted(async () => {
  const { data: { session }, error } = await supabase.auth.getSession()

  if (error || !session) {
    router.push({ name: 'Login' })
    return
  }

  router.push({ name: 'Home' })
})
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#d9d4c4] via-[#c7c1ac] to-[#b8b19a]">
    <p class="text-slate-600 font-medium">Completing sign in...</p>
  </div>
</template>
