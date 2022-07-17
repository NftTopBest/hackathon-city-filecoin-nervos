<script setup lang="ts">
import {
  Dialog,
  DialogPanel,
  TransitionChild,
  TransitionRoot,
} from '@headlessui/vue'
import { parseEther } from '~/helpers/web3'

interface Props {
  item: Object
  action: string
  show: boolean
}
const {
  item,
  action,
  show,
} = defineProps<Props>()

const tokenId = $computed(() => item.tokenId)
const { name, avatar, walletAddress } = $(userStore())
const {
  initContract
} = $(useWeb3Auth())

let isLoading = $ref(true)
let currentTab = $ref('comments')

// const tabs = $computed(() => {
//   return [
//     {
//       name: `Comments(${item.commentCount})`, action: 'comments',
//     },
//     { name: `Vote Up(${item.voteUp})`, action: 'voteUp' },
//   ];
// })

let voteUpItems = $ref([])
let commentItems = $ref([])

const { storeJson } = $(useNFTStorage())
const { addSuccess } = $(notificationStore())

let isShowActionForm = $ref(false)
let amount = $ref(1)
const updateamount = delta => {
  const newamount = amount + delta
  if (newamount <= 0) return
  amount = newamount
}
let withComment = $ref(true)
let comment = $ref('')
let isSubmitting = $ref(false)

const showActionForm = isWithComment => {
  isShowActionForm = true
  withComment = isWithComment
}
const doVoteUp = async () => {
  if (isSubmitting) return

  isSubmitting = true

  const voteUpCID = await storeJson({
    author: walletAddress,
    avatar,
    name,
    amount,
    tokenId,
    comment,
  })

  const commentCID = withComment ? voteUpCID : ''

  const contractWriter = await initContract('NTBListing', true)
  const value = parseEther('0.01').mul(amount)
  const tx = await contractWriter.voteUp(tokenId, amount, voteUpCID, commentCID, { value })
  await tx.wait()
  comment = ''
  withComment = false
  amount = 10
  isShowActionForm = false
  addSuccess('Add comment success, the data will not refresh right now, pls check after some minutes!')
}

const queryTokenData = async () => {
  isLoading = true
  const contractReader = await initContract('NTBListing', false)
  const start = 0
  const limit = 100
  const data = await Promise.all([
    contractReader.getList(0, tokenId, start, limit),
    // contractReader.getList(1, tokenId, start, limit),
  ])
  voteUpItems = data[0]
  isLoading = false
  // commentItems = data[1]
}

watchEffect(() => {
  if (!tokenId) return
  
  currentTab = action
  queryTokenData()
})

</script>
<template>
  <div>
    <TransitionRoot as="div" :show="show">
      <Dialog as="div" class="z-10 relative" @close="$emit('close')">
        <TransitionChild as="template" enter="ease-in-out duration-500" enter-from="opacity-0" enter-to="opacity-100" leave="ease-in-out duration-500" leave-from="opacity-100" leave-to="opacity-0">
          <div class="bg-black bg-opacity-75 inset-0 transition-opacity fixed" />
        </TransitionChild>

        <div class="inset-0 fixed overflow-hidden">
          <div class="inset-0 absolute overflow-hidden">
            <div class="flex max-w-full pr-10 inset-y-0 left-0 pointer-events-none fixed sm:pr-16">
              <TransitionChild as="template" enter="transform transition ease-in-out duration-500 sm:duration-700" enter-from="-translate-x-full" enter-to="translate-x-0" leave="transform transition ease-in-out duration-500 sm:duration-700" leave-from="translate-x-0" leave-to="-translate-x-full">
                <DialogPanel class="max-w-md w-screen pointer-events-auto">
                  <div class="bg-white flex flex-col h-full shadow-xl overflow-y-scroll">
                    <div class="mt-4 mb-10 px-4 flow-root sm:flex  sm:px-6 sm:items-end">
                      <div class="flex-row flex  w-full justify-between">
                        <router-link :to="`/${item.chainId}/${item.tokenId}`" class="border-white rounded-lg flex overflow-hidden">
                          <ipfs-img class="h-48 w-48" :src="item.image" :alt="item.name" />
                        </router-link>
                        <div class="flex flex-col pr-2 justify-end items-start">
                          <router-link :to="`/${item.chainId}/${item.tokenId}`" class="flex font-bold flex-1 text-lg mb-2 text-gray-900 items-center sm:text-2xl">
                            {{ item.name }}
                          </router-link>
                          <btn-green class="mb-2 w-full" @click="showActionForm(false)">
                            <ant-design:caret-up-filled class="h-6 mr-2 w-6 block" />
                            {{ item.voteUp }}
                          </btn-green>
                          <btn-black class="w-full" @click="showActionForm(true)">
                            <codicon:comment class="h-6 mr-2 w-6 block" />
                            {{ item.commentCount }}
                          </btn-black>
                        </div>
                      </div>
                    </div>

                    <!-- <div class="border-b border-gray-200">
                      <div class="px-6">
                        <nav class="flex -mb-px space-x-6" x-descriptions="Tab component">
                          <button v-for="tab in tabs" :key="tab.name" @click="currentTab = tab.action" :class="[currentTab === tab.action ? 'border-green-500 text-green-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300', 'whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm']">{{ tab.name }}</button>
                        </nav>
                      </div>
                    </div> -->
                    <!-- <IpfsComments v-show="currentTab === 'comments'" :items="commentItems" class="divide-y divide-gray-200 flex-1 overflow-y-auto" /> -->
                    <div v-show="isLoading" class="flex flex-col justify-center items-center">
                      <eos-icons:loading class="h-10 w-10" />
                      Loading...
                    </div>
                    <IpfsComments :items="voteUpItems" class="divide-y divide-gray-200 flex-1 overflow-y-auto" />
                  </div>
                </DialogPanel>
              </TransitionChild>
            </div>
          </div>
        </div>
      </Dialog>
    </TransitionRoot>
    <dialog-default :show="isShowActionForm" @close="isShowActionForm = false">
      <h2 class="font-extrabold my-6 text-center text-3xl text-gray-900">Vote Up</h2>
      <div class="mt-2 text-center text-2xl">
        {{ amount * 0.01 }} CKB
      </div>
      <div class="flex mt-2 custom-number-input justify-center items-center">
        <div class="bg-transparent rounded-lg flex flex-row h-10 mt-1  relative">
          <button data-action="decrement" class="rounded-l cursor-pointer h-full outline-none bg-gray-300 text-gray-600 w-20 hover:bg-gray-400 hover:text-gray-700" @click="updateamount(-1)">
            <span class="font-thin m-auto text-2xl">−</span>
          </button>
          <input v-model="amount" type="number" class="flex font-semibold outline-none bg-gray-300 text-center text-md w-full text-gray-700 items-center  md:text-basecursor-default hover:text-black focus:outline-none focus:text-black  " name="custom-input-number">
          <button data-action="increment" class="rounded-r cursor-pointer h-full bg-gray-300 text-gray-600 w-20 hover:bg-gray-400 hover:text-gray-700" @click="updateamount(1)">
            <span class="font-thin m-auto text-2xl">+</span>
          </button>
        </div>
      </div>
      <div class="mt-6">
        <div class="flex  items-center justify-end">
          <label for="with-comment" class="text-sm mr-2 text-gray-900 block">With comment</label>
          <input id="with-comment" name="with-comment" type="checkbox" v-model="withComment" class="rounded border-gray-300 h-4 text-green-600 w-4 focus:ring-green-500" />
        </div>
        <div class="mt-3" v-if="withComment">
          <textarea rows="4" name="comment" id="comment" v-model="comment" class="rounded-md border-gray-300 shadow-sm w-full p-2 block sm:text-sm focus:border-green-500 focus:ring-green-500" />
        </div>
      </div>
      <btn-black class="mt-4 mb-6 w-full" @click="doVoteUp" :isLoading="isSubmitting">Submit Vote</btn-black>
    </dialog-default>
  </div>
</template>
