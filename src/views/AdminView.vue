<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAllowedEmails } from '../composables/useAllowedEmails'
import { useUserProfile } from '../composables/useUserProfile'

const { emails, loading, error, fetchEmails, addEmail, removeEmail } = useAllowedEmails()
const { profile } = useUserProfile()
const newEmail = ref('')
const adding = ref(false)

onMounted(fetchEmails)

const handleAdd = async () => {
  const email = newEmail.value.trim()
  if (!email) return
  adding.value = true
  try {
    await addEmail(email)
    newEmail.value = ''
  } catch (e) {
    alert(e.message)
  } finally {
    adding.value = false
  }
}

const currentUserEmail = computed(() => profile.value?.email?.toLowerCase())

const confirmRemove = async (entry) => {
  if (entry.has_account) {
    if (!confirm(`Deactivate ${entry.email}? They will be removed from the allowlist.`)) return
  } else {
    if (!confirm(`Remove access for ${entry.email}? They will no longer be able to log in.`)) return
  }
  try {
    await removeEmail(entry.id)
  } catch (e) {
    alert(e.message)
  }
}
</script>

<template>
  <div class="py-8 px-4 flex flex-col items-center justify-start">
    <div class="w-full max-w-3xl">
      <div class="bg-gradient-to-b from-[#fdfdfb] to-[#f6f5ef] border-[10px] border-[#c9c2ab] rounded-lg shadow-2xl p-6 md:p-8">

        <div class="pb-4 border-b-2 border-[#b9b4a4] mb-6">
          <h1 class="text-3xl md:text-4xl font-bold text-[#1f5fbf]" style="font-family: 'Kalam', cursive;">Manage Access</h1>
          <p class="text-slate-500 mt-1 text-sm">
            Only people on this list can sign in and use the planner. Add your mum's email to share it with her — anyone else is blocked.
          </p>
        </div>

        <!-- Add email -->
        <div class="bg-white/70 border border-[#b9b4a4] rounded-lg p-5 mb-6">
          <label for="new-email" class="block text-sm font-medium text-slate-700 mb-2">Add an email address</label>
          <div class="flex gap-2">
            <input
              id="new-email"
              v-model="newEmail"
              type="email"
              placeholder="mum@example.com"
              @keydown.enter="handleAdd"
              class="flex-1 px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1f5fbf] bg-white text-slate-900"
            />
            <button @click="handleAdd" :disabled="adding || !newEmail.trim()"
              class="px-4 py-2 bg-[#1f5fbf] text-white text-sm font-medium rounded-lg hover:bg-[#1a4f9e] transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
              {{ adding ? 'Adding...' : 'Add' }}
            </button>
          </div>
          <p v-if="error" class="mt-2 text-sm text-red-600">{{ error }}</p>
        </div>

        <p v-if="loading" class="text-slate-500 text-sm">Loading...</p>

        <div v-else-if="emails.length === 0" class="bg-white/70 border border-[#b9b4a4] rounded-lg p-8 text-center">
          <p class="text-slate-500">No login permissions configured. While this list is empty, anyone can sign up.</p>
        </div>

        <div v-else class="bg-white/70 border border-[#b9b4a4] rounded-lg overflow-hidden">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-[#b9b4a4] bg-[#faf9f5]">
                <th class="px-4 py-3 text-sm font-semibold text-slate-600">Email</th>
                <th class="px-4 py-3 text-sm font-semibold text-slate-600">Status</th>
                <th class="px-4 py-3 text-sm font-semibold text-slate-600"></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="entry in emails" :key="entry.id" class="border-b border-slate-100 hover:bg-slate-50">
                <td class="px-4 py-3 text-sm font-medium text-slate-900">{{ entry.email }}</td>
                <td class="px-4 py-3 text-sm text-slate-500">
                  <span v-if="entry.has_account" class="inline-flex items-center px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs rounded-full">Active</span>
                  <span v-else class="inline-flex items-center px-2 py-0.5 bg-slate-100 text-slate-500 text-xs rounded-full">Not signed up yet</span>
                </td>
                <td class="px-4 py-3 text-right">
                  <button v-if="entry.email.toLowerCase() !== currentUserEmail" @click="confirmRemove(entry)"
                    :class="entry.has_account ? 'inline-flex items-center px-3 py-1.5 bg-amber-600 text-white text-sm rounded-lg hover:bg-amber-700 transition-colors' : 'inline-flex items-center px-3 py-1.5 bg-red-600 text-white text-sm rounded-lg hover:bg-red-700 transition-colors'">
                    {{ entry.has_account ? 'Deactivate' : 'Remove access' }}
                  </button>
                  <span v-else class="text-xs text-slate-400">You</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

      </div>
    </div>
  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Kalam:wght@400;700&family=Inter:wght@400;500;600;700&display=swap');
</style>
