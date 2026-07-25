<script setup>
import { ref, onMounted } from 'vue'

const STORAGE_KEY = 'day-planner-state-v2'

// Date header
const plannerDate = ref(new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }))

// Hours schedule
const hours = ref([
  { time: '7:00 AM', chips: [], note: '' },
  { time: '8:00 AM', chips: [], note: '' },
  { time: '9:00 AM', chips: [], note: '' },
  { time: '10:00 AM', chips: [], note: '' },
  { time: '11:00 AM', chips: [], note: '' },
  { time: '12:00 PM', chips: [], note: '' },
  { time: '1:00 PM', chips: [], note: '' },
  { time: '2:00 PM', chips: [], note: '' },
  { time: '3:00 PM', chips: [], note: '' },
  { time: '4:00 PM', chips: [], note: '' },
  { time: '5:00 PM', chips: [], note: '' },
  { time: '6:00 PM', chips: [], note: '' },
  { time: '7:00 PM', chips: [], note: '' },
  { time: '8:00 PM', chips: [], note: '' },
])

// Categories & items
const categories = ref([
  {
    key: 'jobs',
    label: 'Jobs',
    color: 'bg-blue-600',
    items: ['Dishes', 'Clothes', 'Clean room', 'Mop', 'Vacuum', 'Mow the lawn', 'Wash car']
  },
  {
    key: 'breaks',
    label: 'Breaks',
    color: 'bg-emerald-600',
    items: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Outside', 'Read', 'Rest']
  },
  {
    key: 'rewards',
    label: 'Rewards',
    color: 'bg-purple-600',
    items: ['Lego', 'Coding', 'Gaming', 'Movie/TV', 'Mall', 'Family time', 'Baking']
  },
  {
    key: 'exercise',
    label: 'Exercise',
    color: 'bg-amber-600',
    items: ['Swimming', 'Footy', 'Run', 'Trampoline', 'Bike']
  }
])

const armedItem = ref(null)
const saveStatus = ref('saved') // 'saved', 'saving'
let saveTimer = null

// Load saved state on mount
onMounted(() => {
  const saved = localStorage.getItem(STORAGE_KEY)
  if (saved) {
    try {
      const data = JSON.parse(saved)
      if (data.date) plannerDate.value = data.date
      if (data.hours) hours.value = data.hours
    } catch (e) {
      console.error('Failed to load saved planner', e)
    }
  }
})

const triggerSave = () => {
  saveStatus.value = 'saving'
  clearTimeout(saveTimer)
  saveTimer = setTimeout(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      date: plannerDate.value,
      hours: hours.value
    }))
    saveStatus.value = 'saved'
  }, 400)
}

const selectItem = (item, catColor) => {
  if (armedItem.value && armedItem.value.label === item) {
    armedItem.value = null
  } else {
    armedItem.value = { label: item, color: catColor }
  }
}

const dropOnHour = (hourIndex) => {
  if (armedItem.value) {
    hours.value[hourIndex].chips.push({ ...armedItem.value })
    armedItem.value = null
    triggerSave()
  }
}

const removeChip = (hourIndex, chipIndex) => {
  hours.value[hourIndex].chips.splice(chipIndex, 1)
  triggerSave()
}

const clearDay = () => {
  if (confirm('Clear all tasks and notes for this day?')) {
    hours.value.forEach(h => {
      h.chips = []
      h.note = ''
    })
    triggerSave()
  }
}
</script>

<template>
  <div class="min-h-screen py-8 px-4 flex flex-col items-center justify-start bg-gradient-to-br from-[#d9d4c4] via-[#c7c1ac] to-[#b8b19a]">
    
    <!-- Decorative top hanger -->
    <div class="w-1 h-6 bg-[#8f8a76] rounded-sm mb-[-2px]"></div>

    <!-- Main Board -->
    <div class="w-full max-w-6xl bg-gradient-to-b from-[#fdfdfb] to-[#f6f5ef] border-[10px] border-[#c9c2ab] rounded-lg shadow-2xl p-6 md:p-8 relative">
      
      <!-- Header -->
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b-2 border-[#b9b4a4] mb-6">
        <div class="flex items-baseline gap-4">
          <h1 class="text-3xl md:text-4xl font-bold text-[#1f5fbf]" style="font-family: 'Kalam', cursive;">Today</h1>
          <input 
            v-model="plannerDate" 
            @input="triggerSave"
            type="text" 
            class="text-xl text-[#1f2430] bg-transparent border-b-2 border-dotted border-[#b9b4a4] focus:outline-none focus:border-[#1f5fbf] px-1"
          />
        </div>

        <div class="flex flex-col items-start md:items-end gap-2">
          <!-- Legend -->
          <div class="flex flex-wrap gap-4 text-xs font-semibold text-slate-700">
            <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-blue-600"></span>Jobs</div>
            <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-emerald-600"></span>Breaks</div>
            <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-purple-600"></span>Rewards</div>
            <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-amber-600"></span>Exercise</div>
          </div>

          <!-- Save status & reset -->
          <div class="flex items-center gap-3 text-xs text-slate-500 font-medium">
            <span class="flex items-center gap-1.5">
              <span :class="['w-2 h-2 rounded-full transition-colors', saveStatus === 'saved' ? 'bg-emerald-600' : 'bg-amber-500 animate-pulse']"></span>
              {{ saveStatus === 'saved' ? 'saved' : 'saving...' }}
            </span>
            <button @click="clearDay" class="border border-[#b9b4a4] bg-white hover:bg-slate-100 text-slate-700 px-2.5 py-1 rounded-md transition flex items-center gap-1">
              Clear day
            </button>
          </div>
        </div>
      </div>

      <!-- Main Layout Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
        
        <!-- Schedule Column -->
        <div class="border-[1.5px] border-[#b9b4a4] bg-white/50 rounded-md overflow-hidden">
          <div v-for="(slot, index) in hours" :key="index" class="flex border-b border-[#d8d4c8] last:border-b-0 min-h-[50px] items-stretch">
            
            <!-- Time label -->
            <div class="w-24 bg-[#f6f5ef] border-r border-[#b9b4a4] flex items-center justify-center font-bold text-slate-800 text-sm select-none" style="font-family: 'Kalam', cursive;">
              {{ slot.time }}
            </div>

            <!-- Drop area & notes -->
            <div 
              @click="dropOnHour(index)"
              class="flex-1 px-3 py-2 flex items-center flex-wrap gap-2 cursor-pointer hover:bg-amber-50/30 transition"
            >
              <!-- Placed Chips -->
              <span 
                v-for="(chip, cIdx) in slot.chips" 
                :key="cIdx"
                :class="['inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold text-white shadow-sm', chip.color]"
              >
                {{ chip.label }}
                <button @click.stop="removeChip(index, cIdx)" class="hover:opacity-80 font-bold ml-0.5">&times;</button>
              </span>

              <!-- Note input for this hour -->
              <input 
                v-model="slot.note"
                @input="triggerSave"
                type="text" 
                placeholder="note..."
                class="flex-1 min-w-[80px] text-sm text-slate-700 bg-transparent focus:outline-none placeholder:text-slate-400 font-serif"
              />
            </div>

          </div>
        </div>

        <!-- Categories / Tiles Sidebar -->
        <div class="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-1 gap-4">
          <div 
            v-for="cat in categories" 
            :key="cat.key"
            class="border-[1.5px] border-[#b9b4a4] bg-white rounded-md overflow-hidden shadow-sm"
          >
            <!-- Category Header -->
            <div :class="['py-2 px-3 text-white font-bold text-center text-sm tracking-wide', cat.color]" style="font-family: 'Kalam', cursive;">
              {{ cat.label }}
            </div>
            <!-- Category Items -->
            <div class="p-2.5 flex flex-col gap-2 bg-[#faf9f5]">
              <div 
                v-for="item in cat.items" 
                :key="item"
                @click="selectItem(item, cat.color)"
                :class="[
                  'py-1.5 px-3 rounded-md text-xs font-semibold text-white text-center cursor-pointer shadow-sm transition hover:opacity-90 select-none',
                  cat.color,
                  armedItem && armedItem.label === item ? 'ring-4 ring-yellow-400 ring-offset-1' : ''
                ]"
              >
                {{ item }}
              </div>
            </div>
          </div>
        </div>

      </div>

    </div>

    <!-- Footer Help Hint -->
    <div class="mt-6 max-w-xl text-center text-xs text-slate-600 bg-white/60 backdrop-blur border border-[#b9b4a4]/40 rounded-lg p-3">
      Click a coloured tile in the sidebar to <b>arm</b> it, then click any time slot on the schedule to place it. Changes save instantly.
    </div>

  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Kalam:wght@400;700&family=Inter:wght@400;500;600;700&display=swap');
</style>
