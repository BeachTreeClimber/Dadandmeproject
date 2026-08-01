import { ref } from 'vue'
import { supabase } from '../supabase/client'

export function useAllowedEmails() {
  const emails = ref([])
  const loading = ref(false)
  const error = ref(null)

  const fetchEmails = async () => {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase
        .from('user_login_emails')
        .select('*')
        .order('created_at', { ascending: false })

      if (err) throw err

      const { data: profiles } = await supabase
        .from('user_profiles')
        .select('id')

      const profileIds = (profiles || []).map(p => p.id)
      let profileEmails = new Set()

      if (profileIds.length > 0) {
        const { data: authInfo } = await supabase
          .rpc('get_auth_user_info', { user_ids: profileIds })

        if (authInfo) {
          profileEmails = new Set(authInfo.map(a => a.email?.toLowerCase()).filter(Boolean))
        }
      }

      emails.value = (data || []).map(e => ({
        ...e,
        has_account: profileEmails.has(e.email?.toLowerCase()),
      }))
    } catch (err) {
      error.value = err.message || 'Failed to fetch allowed emails'
      emails.value = []
    } finally {
      loading.value = false
    }
  }

  const addEmail = async (email) => {
    error.value = null
    try {
      const { error: err } = await supabase
        .from('user_login_emails')
        .insert({ email: email.toLowerCase().trim() })

      if (err) throw err
      await fetchEmails()
    } catch (err) {
      error.value = err.message || 'Failed to add email'
      throw err
    }
  }

  const removeEmail = async (id) => {
    error.value = null
    try {
      const { error: err } = await supabase
        .from('user_login_emails')
        .delete()
        .eq('id', id)

      if (err) throw err
      await fetchEmails()
    } catch (err) {
      error.value = err.message || 'Failed to remove email'
      throw err
    }
  }

  return { emails, loading, error, fetchEmails, addEmail, removeEmail }
}
