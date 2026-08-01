import { ref, onMounted } from 'vue'
import { supabase } from '../supabase/client'

const profile = ref(null)
const loading = ref(true)
const initialized = ref(false)
const needsInvite = ref(false)

function mergeAuthInfo(profileData, authInfo) {
  if (!profileData) return null
  return {
    ...profileData,
    email: authInfo?.email || null,
    last_sign_in_at: authInfo?.last_sign_in_at || null,
  }
}

export function useUserProfile() {
  const fetchProfile = async () => {
    loading.value = true
    needsInvite.value = false
    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        profile.value = null
        loading.value = false
        initialized.value = true
        needsInvite.value = false
        return null
      }

      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', session.user.id)
        .maybeSingle()

      if (!error && data) {
        const { data: authInfo } = await supabase
          .rpc('get_auth_user_info', { user_ids: [session.user.id] })

        profile.value = mergeAuthInfo(data, authInfo?.[0])
        needsInvite.value = false
      } else {
        const { data: created, error: rpcErr } = await supabase
          .rpc('try_create_profile')

        if (!rpcErr && created) {
          const { data: newData } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', session.user.id)
            .maybeSingle()

          if (newData) {
            const { data: authInfo } = await supabase
              .rpc('get_auth_user_info', { user_ids: [session.user.id] })

            profile.value = mergeAuthInfo(newData, authInfo?.[0])
            needsInvite.value = false
          } else {
            profile.value = null
            needsInvite.value = true
          }
        } else {
          profile.value = null
          needsInvite.value = true
        }
      }
    } catch {
      profile.value = null
      needsInvite.value = false
    } finally {
      loading.value = false
      initialized.value = true
    }
    return profile.value
  }

  const clearProfile = () => {
    profile.value = null
    loading.value = false
    initialized.value = false
    needsInvite.value = false
  }

  onMounted(() => {
    if (!initialized.value) {
      fetchProfile()
    }
  })

  return { profile, loading, initialized, needsInvite, fetchProfile, clearProfile }
}
