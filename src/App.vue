<script setup>
import { ref } from 'vue'

// State variables
const newTaskText = ref('')
const tasks = ref([
  { id: 1, text: 'Explore the new Daily Planner app', completed: false },
  { id: 2, text: 'Connect Supabase backend', completed: false }
])

// Add a task
const addTask = () => {
  if (!newTaskText.value.trim()) return
  tasks.value.push({
    id: Date.now(),
    text: newTaskText.value,
    completed: false
  })
  newTaskText.value = ''
}

// Delete a task
const deleteTask = (id) => {
  tasks.value = tasks.value.filter(task => task.id !== id)
}
</script>

<template>
  <div class="min-h-screen py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden md:max-w-2xl p-6">
      
      <!-- Header -->
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-indigo-600">Daily Planner</h1>
        <p class="text-slate-500 mt-2">Your simple space to plan and conquer the day.</p>
      </div>

      <!-- Input Form -->
      <form @submit.prevent="addTask" class="flex gap-2 mb-6">
        <input 
          v-model="newTaskText"
          type="text" 
          placeholder="What do you need to do today?" 
          class="flex-1 px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
        />
        <button 
          type="submit"
          class="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2 rounded-lg font-medium transition"
        >
          Add Task
        </button>
      </form>

      <!-- Task List -->
      <div class="space-y-3">
        <div v-if="tasks.length === 0" class="text-center py-6 text-slate-400">
          No tasks yet. Add one above to get started!
        </div>

        <div 
          v-for="task in tasks" 
          :key="task.id"
          class="flex items-center justify-between p-3 bg-slate-50 border border-slate-200 rounded-lg hover:bg-slate-100 transition"
        >
          <div class="flex items-center gap-3">
            <input 
              type="checkbox" 
              v-model="task.completed"
              class="w-5 h-5 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
            />
            <span :class="{ 'line-through text-slate-400': task.completed }" class="text-slate-700 font-medium">
              {{ task.text }}
            </span>
          </div>
          <button 
            @click="deleteTask(task.id)"
            class="text-slate-400 hover:text-red-500 text-sm font-semibold transition"
          >
            Delete
          </button>
        </div>
      </div>

    </div>
  </div>
</template>
