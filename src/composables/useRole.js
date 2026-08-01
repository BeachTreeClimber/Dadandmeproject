import { ref, onMounted } from 'vue'
import { supabase } from '../supabase/client'

const roles = ref([])
const loading = ref(true)
const initialized = ref(false)

export function useRole() {
  const fetchRole = async () => {
    loading.value = true
    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        roles.value = []
        loading.value = false
        initialized.value = true
        return []
      }

      const { data, error } = await supabase
        .from('user_roles')
        .select('roles(name)')
        .eq('user_id', session.user.id)

      if (error) {
        roles.value = []
      } else {
        roles.value = (data || [])
          .map(r => r.roles?.name)
          .filter(Boolean)
      }
    } catch {
      roles.value = []
    } finally {
      loading.value = false
      initialized.value = true
    }
    return roles.value
  }

  const clearRole = () => {
    roles.value = []
    loading.value = false
    initialized.value = false
  }

  const hasRole = (...allowed) => {
    if (!roles.value.length) return false
    return roles.value.some(r => allowed.includes(r))
  }

  onMounted(() => {
    if (!initialized.value) {
      fetchRole()
    }
  })

  return { role: roles, roles, loading, initialized, fetchRole, clearRole, hasRole }
}
