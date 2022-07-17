<script setup lang="ts">
import { ChevronDownIcon, SearchIcon, SortAscendingIcon } from '@heroicons/vue/solid'

const { initContract, chainId } = $(useWeb3Auth())
const { getJson } = $(useNFTStorage())

let isLoading = $ref(true)
let items = $ref([])
// [
//   {
//     _id: 1,
//     contractAddress: '0x17F6BDF57384FD9F24F1d9A4681c3a9dc839d79e',
//     chain: '0x4',
//     avatar: '/tmp/avatar.jpg',
//     name: 'Jack Sparrow',
//     desc: `Former pirate, now retried writing Web3 code to hacking on the BlockChain!
// Support me, after I get some treasures will share you!`,
//     voteUp: 511,
//     commentCount: 123,
//   },
// ]

let isShow = $ref(false)
let currentItem = $ref({})
let action = $ref('')
const showItem = (item, _action) => {
  isShow = true
  currentItem = item
  action = _action
}

let contractWriter = $ref('')
let total = $ref(0)
onMounted(async() => {
  contractWriter = await initContract('NTBListing', true)
  total = (await contractWriter.tokenIdCounter()).toString()
  const start = '0'
  const limit = total
  const { tokenURIs, voteUpCounts, commentCounts } = await contractWriter.getTokenDataList(start, limit)
  items = await Promise.all(tokenURIs.map(async (cid, index) => {
    const data = await getJson(cid)
    return {
      tokenId: start + index,
      chainId,
      ...data,
      voteUp: voteUpCounts[index],
      commentCount: commentCounts[index]
    }
  }))
  isLoading = false
  // showItem(items[0], 'comments')
})
</script>

<template>
  <main class="bg-white rounded-lg h-full mx-auto max-w-4xl relative">
    <div class="w-full">
      <div class="border-b border-gray-100 p-6 sm:flex sm:items-center sm:justify-between">
        <h3 class="font-medium text-lg text-gray-900 leading-6">
          Popular NFTs
        </h3>
        <div class="mt-3 hidden sm:mt-0 sm:ml-mr-4">
          <label for="mobile-search" class="sr-only">Search</label>
          <label for="desktop-search" class="sr-only">Search</label>
          <div class="rounded-md flex shadow-sm">
            <div class="flex-grow relative focus-within:z-10">
              <div class="flex pl-3 inset-y-0 left-0 absolute items-center pointer-events-none">
                <SearchIcon class="h-5 text-gray-400 w-5" aria-hidden="true" />
              </div>
              <input id="mobile-search" type="text" name="mobile-search" class="rounded-none rounded-l-md border-gray-300 w-full pl-10 block sm:hidden focus:border-indigo-500 focus:ring-indigo-500" placeholder="Search">
              <input id="desktop-search" type="text" name="desktop-search" class="rounded-none rounded-l-md border-gray-300 w-full pl-10 hidden sm:text-sm sm:block focus:border-indigo-500 focus:ring-indigo-500" placeholder="Search">
            </div>
            <button type="button" class="border rounded-r-md font-medium -ml-px bg-gray-50 border-gray-300 text-sm py-2 px-4 text-gray-700 relative inline-flex items-center hover:bg-gray-100 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500">
              <SortAscendingIcon class="h-5 text-gray-400 w-5" aria-hidden="true" />
              <span class="ml-2">Sort</span>
              <ChevronDownIcon class="h-5 -mr-1.5 ml-2.5 text-gray-400 w-5" aria-hidden="true" />
            </button>
          </div>
        </div>
      </div>
      <div class="py-6">
        <div v-show="isLoading" class="flex flex-col justify-center items-center">
          <eos-icons:loading class="h-10 w-10" />
          Loading...
        </div>
        <div v-for="item in items" :key="item.tokenId" class="flex py-3 px-6  hover:(cursor-pointer) ">
          <router-link class="flex flex-1 group" :to="`/${item.chainId}/${item.tokenId}`">
            <div>
              <ipfs-img class="rounded-md h-20 mr-4 w-20 inline-block" :src="item.image" :alt="item.name" />
            </div>
            <div class="flex flex-col  flex-1 pr-3">
              <h3 class="flex font-semibold text-lg items-center">
                {{ item.name }}
                <akar-icons:link-out class="ml-2 hidden group-hover:inline-block" />
              </h3>
              <div class="flex-1">
                <p class="break-all">
                  {{ item.description }}
                </p>
              </div>
            </div>
          </router-link>
          <div class="flex flex-col justify-center items-center lg:flex-row">
            <button class="rounded-md flex flex-col border-1 border-cool-gray-100 mb-2 py-2 px-4 items-center justify-center lg:mb-0 hover:(text-white bg-black) " @click="showItem(item, 'voteUp')">
              <ant-design:caret-up-filled class="h-6 w-6 block" />
              <div class="text-sm ">
                {{ item.voteUp }}
              </div>
            </button>
            <button class="rounded-md flex flex-col border-1 border-cool-gray-100 py-2 px-4 items-center justify-center lg:ml-2 hover:(text-white bg-black) " @click="showItem(item, 'comments')">
              <codicon:comment class="h-6 w-6 block" />
              <div class="text-sm ">
                {{ item.commentCount }}
              </div>
            </button>
          </div>
        </div>
      </div>

      <NtbSlideOver :item="currentItem" :action="action" :show="isShow" @close="isShow=false" />
    </div>
  </main>
</template>

<route lang="yaml">
meta:
  layout: nfttop.best
</route>
