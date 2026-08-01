import { ref } from 'vue'
import { supabase } from '../supabase/client'

export function useUsers() {
  const users = ref([])
  const loading = ref(false)
  const error = ref(null)

  const fetchUsers = async () => {
    loading.value = true
    error.value = null

    try {
      const { data: profiles, error: profileErr } = await supabase
        .from('user_profiles')
        .select('*')
        .order('created_at', { ascending: false })

      if (profileErr) throw profileErr

      const { data: roleData, error: roleErr } = await supabase
        .from('user_roles')
        .select('user_id, roles(name)')

      if (roleErr) throw roleErr

      const roleMap = {}
      if (roleData) {
        roleData.forEach(r => {
          if (!roleMap[r.user_id]) roleMap[r.user_id] = []
          if (r.roles?.name) roleMap[r.user_id].push(r.roles.name)
        })
      }

      const ids = (profiles || []).map(p => p.id)
      let authMap = {}
      if (ids.length > 0) {
        const { data: authInfo } = await supabase
          .rpc('get_auth_user_info', { user_ids: ids })

        if (authInfo) {
          authInfo.forEach(a => {
            authMap[a.user_id] = { email: a.email, last_sign_in_at: a.last_sign_in_at }
          })
        }
      }

      const { data: allowedData } = await supabase
        .from('user_login_emails')
        .select('email')

      const allowedEmails = new Set((allowedData || []).map(e => e.email.toLowerCase()))

      users.value = (profiles || []).map(p => {
        const auth = authMap[p.id] || {}
        return {
          ...p,
          email: auth.email || null,
          roles: roleMap[p.id] || [],
          last_sign_in_at: auth.last_sign_in_at || null,
          in_allowlist: auth.email ? allowedEmails.has(auth.email.toLowerCase()) : false,
        }
      })
    } catch (err) {
      error.value = err.message || 'Failed to fetch users'
      users.value = []
    } finally {
      loading.value = false
    }
  }

  const updateRole = async (userId, roleName, add) => {
    error.value = null
    try {
      const { data: role, error: roleErr } = await supabase
        .from('roles')
        .select('id')
        .eq('name', roleName)
        .single()

      if (roleErr || !role) throw new Error(`Role '${roleName}' not found`)

      if (add) {
        const { error: insertErr } = await supabase
          .from('user_roles')
          .insert({ user_id: userId, role_id: role.id })

        if (insertErr && !insertErr.message?.includes('duplicate')) throw insertErr
      } else {
        await supabase
          .from('user_roles')
          .delete()
          .eq('user_id', userId)
          .eq('role_id', role.id)
      }

      await fetchUsers()
    } catch (err) {
      error.value = err.message || 'Failed to update role'
      throw err
    }
  }

  return { users, loading, error, fetchUsers, updateRole }
}
