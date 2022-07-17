<script setup lang="ts">
interface Props {
  src?: string,
}
const {
  src,
} = defineProps<Props>()

const theSrc = $computed(() => {
  if(!src) return ''
  return src.replace('ipfs://', 'https://nftstorage.link/ipfs/')
})

let isLoaded = $ref(false)
</script>
<template>
  <div v-if="!isLoaded" v-bind="$attrs" class="bg-black flex bg-opacity-75 justify-center items-center">
    <eos-icons:loading class="h-10 text-white w-10" />
  </div>
  <img :src="theSrc" v-bind="$attrs" v-else loading="lazy" />
  <img :src="theSrc" @load="isLoaded = true" class="h-0 w-0" />
</template>
