<script setup lang="ts">
// https://www.patreon.com/jrgarciadev
// https://tailwindui.com/components/ecommerce/components/product-overviews
// https://tailwindui.com/components/application-ui/forms/textareas
import { UseTimeAgo } from '@vueuse/components'
import VMdPreview from '@kangc/v-md-editor/lib/preview'
import { chatLink, parseEther } from '~/helpers/web3';

const { getJson, storeJson, getStatus } = $(useNFTStorage())
const { initContract, walletAddress } = $(useWeb3Auth())
const route = useRoute()

const tokenId = $computed(() => route.params.tokenId)
let currentItem = $ref({})
let properties = $ref({})
let gallery = $ref([])
let contractWriter = $ref('')
let voteUpCount = $ref(0)
let commentCount = $ref(0)

let dialogConfirmShow = $ref(false)
let dialogTitle = $ref('Project do not exist')
let dialogContent = $ref('The project you are trying to view do not exist!')
const router = useRouter()
const closeConfirmDialog = () => {
  router.push(`/`)
}

const { addSuccess } = $(notificationStore())

let isShowActionForm = $ref(false)
let mintAmount = $ref(10)
const updateMintAmount = delta => {
  const newMintAmount = mintAmount + delta
  if (newMintAmount <= 0) return
  mintAmount = newMintAmount
}
let withComment = $ref(true)
let comment = $ref('Very good project, I like it! Vote up with some CKB!')
let isSubmitting = $ref(false)

let isShow = $ref(false)
let action = $ref('')
const showItem = ( _action) => {
  isShow = true
  action = _action
}

const doVoteUp = async () => {
  if (isSubmitting) return
  
  isSubmitting = true

  let commentCID = ''
  if (withComment) {
    commentCID = await storeJson({
      author: unref(walletAddress),
      tokenId,
      comment,
    })
  }

  contractWriter = await initContract('NTBListing', true)
  const value = parseEther('0.01').mul(mintAmount)
  const tx = await contractWriter.voteUp(tokenId, mintAmount, commentCID, { value })
  await tx.wait()
  comment = ''
  withComment = false
  mintAmount = 10
  isShowActionForm = false
  addSuccess('Add comment success, the data will not refresh right now, pls check after some minutes!')
}

let status = $ref('')
let ownerProfile = $ref('')
const queryTokenData = async () => {
  const contractReader = await initContract('NTBListing', false)
  const { tokenURIs, voteUpCounts, commentCounts } = await contractReader.getTokenDataList(tokenId, 1)
  if (tokenURIs.length === 0) {
    dialogConfirmShow = true
    return
  }

  const data = await getJson(tokenURIs[0])
  properties = data.properties
  gallery = properties.gallery
  voteUpCount = voteUpCounts[0].toString()
  commentCount = commentCounts[0].toString()

  currentItem = {
    ...data,
    tokenId,
    voteUp: voteUpCount,
    commentCount,
  }

  try {
    status = await getStatus(tokenURIs[0])
    const owner = await contractReader.tokenOwnerMap(tokenId)
    const ownerProfileCID = await contractReader.userProfileMap(owner)
    if (ownerProfileCID) {
      ownerProfile = await getJson(ownerProfileCID)
    }
  } catch (err) {
    console.log('====> err :', err)
  }

}
watchEffect(async () => {
  try {
    await queryTokenData()
  } catch (error) {
    dialogConfirmShow = true
  }
})

</script>
<template>
  <div>
    <main class="mx-auto min-h-screen max-w-4xl relative">
      <div class="flex flex-col  text-center p-10 justify-center items-center">
        <ipfs-img class="rounded-full h-40 w-40" :src="currentItem.image" />
        <h1 class=" font-extrabold my-4 tracking-tight text-2xl text-gray-900 sm:text-3xl">
          {{currentItem.name}}
        </h1>
        <div class="pt-2 text-2xl">
          {{currentItem.description}}
        </div>
      </div>
      <div class="bg-white pt-3 relative">
        <div class="-mt-3 -ml-18 justify-around fixed">
          <button class="rounded-md flex flex-col bg-green-400 border-1 border-cool-gray-100 text-white mb-2 py-2 px-4 items-center justify-center hover:(text-white bg-black) " @click="showItem('voteUp')">
            <ant-design:caret-up-filled class="h-6 w-6 block" />
            <div class="text-sm ">
              {{ voteUpCount }}
            </div>
          </button>
          <button class="bg-white rounded-md flex flex-col border-1 border-cool-gray-100 py-2 px-4 items-center justify-center hover:(text-white bg-black) " @click="showItem('comments')">
            <codicon:comment class="h-6 w-6 block" />
            <div class="text-sm ">
              {{ commentCount }}
            </div>
          </button>
        </div>

        <div class="mx-auto mt-6 max-w-2xl sm:px-6 lg:max-w-7xl lg:grid lg:px-8 lg:gap-x-8 lg:grid-cols-3">
          <div class="rounded-lg hidden overflow-hidden aspect-w-3 aspect-h-4 lg:block">
            <ipfs-img class="h-full object-center object-cover w-full" :src="gallery[0]" />
          </div>
          <div class="hidden lg:grid lg:gap-y-8 lg:grid-cols-1">
            <div class="rounded-lg overflow-hidden aspect-w-3 aspect-h-2">
              <ipfs-img class="h-full object-center object-cover w-full" :src="gallery[1]" />
            </div>
            <div class="rounded-lg overflow-hidden aspect-w-3 aspect-h-2">
              <ipfs-img class="h-full object-center object-cover w-full" :src="gallery[2]" />
            </div>
          </div>
          <div class="sm:rounded-lg aspect-w-4 aspect-h-5 sm:overflow-hidden lg:aspect-w-3 lg:aspect-h-4">
            <ipfs-img class="h-full object-center object-cover w-full" :src="gallery[3]" />
          </div>
        </div>

        <div class="mx-auto max-w-2xl px-4 pt-10 pb-16 sm:px-6 lg:max-w-4xl lg:grid lg:px-8 lg:pt-10 lg:pb-24 lg:gap-x-8 lg:grid-cols-4 lg:grid-rows-[auto,auto,1fr]">
          <div class="lg:col-span-4">
            <h1 class="flex font-extrabold tracking-tight text-2xl text-gray-900 items-center sm:text-3xl">
              <div class="flex flex-1 items-center">
                <span class="mr-2">{{currentItem.name}}</span>
                <span v-for="item in properties.topics" :key="item.id" class="rounded-full font-medium mx-1 text-xs py-0.5 px-2.5 text-gray-800 inline-flex items-center" :class="{
                  'bg-green-200': item.name === 'Art',
                  'bg-indigo-200': item.name === 'Movie',
                }"> {{item.name}} </span>
              </div>
              <div class="flex font-normal text-sm text-gray-400 items-center">
                <a :href="chatLink(ownerProfile.walletAddress)" target="_blank" v-if="ownerProfile">
                  <ipfs-img class="rounded-full h-10 mr-2 w-10" :src="ownerProfile.avatar" />
                </a>
                <UseTimeAgo v-slot="{ timeAgo }" :time="status.created" v-if="status.created">
                  {{ timeAgo }}
                </UseTimeAgo>
              </div>
            </h1>
          </div>
          <div class="py-10 lg:pt-6  lg:pb-16 lg:col-start-1 lg:col-span-4">
            <div>
              <h3 class="sr-only">
                Description
              </h3>
              <div class="space-y-6">
                <p class="text-base text-gray-900">
                  <v-md-preview :text="properties.content" />
                </p>
                <div class="space-y-1">
                  <a v-for="item in properties.links" :href="item" :key="item" class="text-blue-400 block hover:underline" target="_blank">
                    {{item}}
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
    <NtbSlideOver :item="currentItem" :action="action" :show="isShow" @close="isShow=false" />

    <dialog-confirm :show="dialogConfirmShow" @close="closeConfirmDialog" status="error" :title="dialogTitle">
      <p class="text-sm text-gray-500">{{dialogContent}}</p>
      <template #footer>
        <btn-black class="w-full" @click="closeConfirmDialog" :isLoading="false">Go back to token list</btn-black>
      </template>
    </dialog-confirm>
    <dialog-default :show="isShowActionForm" @close="isShowActionForm = false">
      <h2 class="font-extrabold my-6 text-center text-3xl text-gray-900">Vote Up</h2>
      <div class="mt-2 text-center text-2xl">
        {{mintAmount*0.01}} CKB
      </div>
      <div class="flex mt-2 custom-number-input justify-center items-center">
        <div class="bg-transparent rounded-lg flex flex-row h-10 mt-1  relative">
          <button data-action="decrement" class="rounded-l cursor-pointer h-full outline-none bg-gray-300 text-gray-600 w-20 hover:bg-gray-400 hover:text-gray-700" @click="updateMintAmount(-1)">
            <span class="font-thin m-auto text-2xl">−</span>
          </button>
          <input v-model="mintAmount" type="number" class="flex font-semibold outline-none bg-gray-300 text-center text-md w-full text-gray-700 items-center  md:text-basecursor-default hover:text-black focus:outline-none focus:text-black  " name="custom-input-number">
          <button data-action="increment" class="rounded-r cursor-pointer h-full bg-gray-300 text-gray-600 w-20 hover:bg-gray-400 hover:text-gray-700" @click="updateMintAmount(1)">
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

<style lang="stylus">
.github-markdown-body
  padding 0
</style>

<route lang="yaml">
meta:
  layout: nfttop.best
</route>
