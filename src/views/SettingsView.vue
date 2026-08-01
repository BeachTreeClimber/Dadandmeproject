<script setup>
import { ref, onMounted } from 'vue'
import { useUsers } from '../composables/useUsers'

const { users, loading, error, fetchUsers, updateRole } = useUsers()
const updating = ref({})

onMounted(fetchUsers)

const toggleEditRole = async (user, add) => {
  if (add) {
    if (!confirm(`Give ${user.email || 'this user'} edit access? They will be able to edit the shared planner.`)) return
  } else {
    if (!confirm(`Remove edit access for ${user.email || 'this user'}? They will no longer be able to edit the planner.`)) return
  }
  updating.value[user.id] = true
  try {
    await updateRole(user.id, 'edit', add)
  } catch (e) {
    alert(e.message)
  } finally {
    updating.value[user.id] = false
  }
}

const initials = (user) => {
  const name = user.display_name || user.email || ''
  return name.charAt(0).toUpperCase()
}
</script>

<template>
  <div class="py-8 px-4 flex flex-col items-center justify-start">
    <div class="w-full max-w-3xl">
      <div class="bg-gradient-to-b from-[#fdfdfb] to-[#f6f5ef] border-[10px] border-[#c9c2ab] rounded-lg shadow-2xl p-6 md:p-8">

        <div class="pb-4 border-b-2 border-[#b9b4a4] mb-6">
          <h1 class="text-3xl md:text-4xl font-bold text-[#1f5fbf]" style="font-family: 'Kalam', cursive;">Settings</h1>
          <p class="text-slate-500 mt-1 text-sm">
            Assign roles to people who can sign in. Users with <b>edit</b> access can view and edit the shared planner with you.
          </p>
        </div>

        <p v-if="loading" class="text-slate-500 text-sm">Loading...</p>
        <p v-else-if="error" class="text-sm text-red-600">{{ error }}</p>

        <div v-else-if="users.length === 0" class="bg-white/70 border border-[#b9b4a4] rounded-lg p-8 text-center">
          <p class="text-slate-500">No users yet. Add emails on the Manage Access page first.</p>
        </div>

        <div v-else class="bg-white/70 border border-[#b9b4a4] rounded-lg overflow-hidden">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-[#b9b4a4] bg-[#faf9f5]">
                <th class="px-4 py-3 text-sm font-semibold text-slate-600">User</th>
                <th class="px-4 py-3 text-sm font-semibold text-slate-600">Role</th>
                <th class="px-4 py-3 text-sm font-semibold text-slate-600"></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="user in users" :key="user.id" class="border-b border-slate-100 hover:bg-slate-50">
                <td class="px-4 py-3">
                  <div class="flex items-center gap-3">
                    <span class="w-8 h-8 rounded-full bg-[#1f5fbf] text-white text-sm font-bold flex items-center justify-center shrink-0">
                      {{ initials(user) }}
                    </span>
                    <div class="min-w-0">
                      <p class="text-sm font-medium text-slate-900 truncate">{{ user.display_name || 'Unknown' }}</p>
                      <p class="text-xs text-slate-500 truncate">{{ user.email }}</p>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-3">
                  <div class="flex flex-wrap gap-1.5">
                    <span v-if="user.roles.includes('admin')" class="inline-flex items-center px-2 py-0.5 bg-purple-100 text-purple-700 text-xs rounded-full">Admin</span>
                    <span v-if="user.roles.includes('edit')" class="inline-flex items-center px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs rounded-full">Edit</span>
                    <span v-if="!user.roles.length" class="inline-flex items-center px-2 py-0.5 bg-slate-100 text-slate-500 text-xs rounded-full">No role</span>
                  </div>
                </td>
                <td class="px-4 py-3 text-right">
                  <button
                    v-if="!user.roles.includes('admin')"
                    @click="toggleEditRole(user, !user.roles.includes('edit'))"
                    :disabled="updating[user.id]"
                    :class="user.roles.includes('edit')
                      ? 'inline-flex items-center px-3 py-1.5 bg-amber-600 text-white text-sm rounded-lg hover:bg-amber-700 transition-colors disabled:opacity-50'
                      : 'inline-flex items-center px-3 py-1.5 bg-emerald-600 text-white text-sm rounded-lg hover:bg-emerald-700 transition-colors disabled:opacity-50'">
                    {{ updating[user.id] ? 'Saving...' : user.roles.includes('edit') ? 'Remove edit access' : 'Give edit access' }}
                  </button>
                  <span v-else class="text-xs text-slate-400">Owner</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="mt-6 bg-white/50 border border-[#b9b4a4]/60 rounded-lg p-4 text-xs text-slate-500">
          <p><b>How sharing works:</b> The app has one shared planner. You (admin) and anyone with <b>edit</b> access see and edit the same board. Only you can add or remove people.</p>
        </div>

      </div>
    </div>
  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Kalam:wght@400;700&family=Inter:wght@400;500;600;700&display=swap');
</style>
