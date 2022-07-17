<script setup lang="ts">
interface Props {
  isLoading?: boolean
}
const {
  isLoading,
} = defineProps<Props>()
</script>
<template>
  <button type="button" class="border border-transparent rounded-md font-medium bg-gray-900 shadow-sm text-base text-white py-2 px-4 inline-flex justify-center sm:text-sm hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500">
    <eos-icons:loading v-show="isLoading" class="mr-2" />
    <slot />
  </button>
</template>
