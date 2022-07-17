<script setup lang="ts">
import {
  BadgeCheckIcon,
  MinusIcon,
  PhotographIcon,
  ViewGridAddIcon,
  LinkIcon,
  CollectionIcon,
} from '@heroicons/vue/outline'
import { CheckCircleIcon } from '@heroicons/vue/solid'
import { parseEther } from '~/helpers/web3'

const subNavigation = [
  { name: 'Information', icon: ViewGridAddIcon },
  { name: 'Topics', icon: CollectionIcon },
  { name: 'Links', icon: LinkIcon },
  { name: 'Images', icon: PhotographIcon },
  { name: 'Submit', icon: BadgeCheckIcon },
]

const options = [
  'Art',
  'Collectibles',
  'Domain Names',
  'Music',
  'Movie',
  'Code',
  'Open Source',
  'Photography',
  'Sports',
  'Trading Cards',
  'Utility',
  'Blog',
  'DApp',
  'Social',
  'DAO',
].map((name) => {
  return {
    id: name,
    name,
  }
})

const contractAddress = $ref('0xC6E58fb4aFFB6aB8A392b7CC23CD3feF74517F6C')
const name = $ref('Jack Sparrow')
const description = $ref('Former pirate, now retried writing Web3 code to hacking on the BlockChain! Support me, after I get some treasures will share you!')
const topics = $ref([options[0], options[4]])
const content = $ref(`Captain Jack Sparrow is a fictional character and the main protagonist of the Pirates of the Caribbean film series. The character was created by screenwriters Ted Elliott and Terry Rossio and is portrayed by Johnny Depp. The characterization of Sparrow is based on a combination of The Rolling Stones' guitarist Keith Richards and Looney Tunes cartoon character Pepé Le Pew. He first appears in the 2003 film Pirates of the Caribbean: The Curse of the Black Pearl. He later appears in the sequels Dead Man's Chest (2006), At World's End (2007), On Stranger Tides (2011), and Dead Men Tell No Tales (2017).

In the films, Sparrow is one of the nine pirate lords in the Brethren Court, the Pirate Lords of the Seven Seas. He can be treacherous and survives mostly by using wit and negotiation rather than by force, opting to flee most dangerous situations and to fight only when necessary. Sparrow is introduced seeking to regain his ship, the Black Pearl, from his mutinous first mate, Hector Barbossa. Later, he attempts to escape his blood debt to the legendary Davy Jones while fighting the East India Trading Company. In later adventures he searches for the Fountain of Youth and the Trident of Poseidon.

The Pirates of the Caribbean series was inspired by the Disney theme park ride of the same name, and when the ride was revamped in 2006, the character of Captain Jack Sparrow was added to it. He headlined the Legend of Captain Jack Sparrow attraction at Disney's Hollywood Studios, and is the subject of spin-off novels, including a children's book series, Pirates of the Caribbean: Jack Sparrow, which chronicles his childhood years.`)

const selectedTab = $ref(0)
// const thumbnail = $ref('ipfs://bafybeidey35qgvfxu4e2d2shimsk3mbxv25k4h5pkiozkgu67dbcxmtzra')
const thumbnail = $ref('')
// const gallery = $ref(['ipfs://bafybeidg3tnjjsi5rcjtisuvvksuohxpldfz4jqnx2ahszsm6qi6moabz4', 'ipfs://bafkreif7hamjm4iz56ncz5rwlm4qipopzznvejsq325adqqbxpg2t355bu', 'ipfs://bafybeidey35qgvfxu4e2d2shimsk3mbxv25k4h5pkiozkgu67dbcxmtzra'])
const gallery = $ref([])
const links = $ref(['https://en.wikipedia.org/wiki/Jack_Sparrow', 'https://www.imdb.com/title/tt1790809/'])

// status: upcoming, loading, complete, error
// const steps = [
//   { name: 'Store metadata on to IPFS', result: '', status: 'complete' },
//   { name: 'Store metadata on to IPFS', result: 'some error happen', status: 'error' },
//   { name: 'Submit data to the blockchain', result: '', status: 'loading' },
//   { name: 'Submit data to the blockchain', result: '', status: 'upcoming' },
// ]
const steps = $ref([
  { name: 'Store metadata on to IPFS', result: '', status: 'upcoming' },
  { name: 'Submit data to the blockchain', result: '', status: 'upcoming' },
])

const isLoading = $computed(() => steps[0].status === 'loading' || steps[1].status === 'loading')

const { initContract, ethers, getTxUrl } = $(useWeb3Auth())
const { storeJson } = $(useNFTStorage())

let metadataCID = ''
let dialogConfirmShow = $ref(false)
let dialogTitle = $ref('Create token success')
let dialogContent = $ref('The tx need some minutes to finish, pls be patient!')
const router = useRouter()
const closeConfirmDialog = () => {
  router.push(`/`)
}

const doSubmit = async () => {
  if (isLoading) return

  const image = thumbnail
  if (!metadataCID) {
    const metadata = {
      name,
      description,
      image,
      properties: {
        type: "ntb-list",
        contractAddress,
        topics,
        content,
        gallery,
        links,
      }
    }
    // 1. store json to IPFS
    steps[0].status = 'loading'
    steps[0].result = 'loading'

    try {
      metadataCID = await storeJson(metadata)
      console.log('====> metadataCID :', metadataCID)
      steps[0].status = 'complete'
      steps[0].result = 'success'
    } catch (err) {
      steps[0].status = 'error'
      steps[0].result = err
      isLoading = false
      return
    }
  }

  try {
    steps[1].status = 'loading'
    steps[1].result = 'loading'

    const contractWriter = await initContract('NTBListing', true)
    const value = parseEther('0.01')
    const gasLimit = 1000000 // godwoken only
    const tx = await contractWriter.createToken(name, description, image, metadataCID, { value, gasLimit })
    const txUrl = getTxUrl(tx.hash)
    await tx.wait()
   
    steps[1].status = 'complete'
    steps[1].result = 'success'
  } catch (err) {
    steps[1].status = 'error'
    steps[1].result = err.message
    isLoading = false
    return
  }

  // show success result and reset all form data, go to home page? go to tx id page?
  isLoading = false
  dialogConfirmShow = true
}


</script>

<template>
  <main class="bg-white rounded-lg h-full mx-auto max-w-4xl relative">
    <div class=" w-full">
      <TabGroup vertical as="div" class="divide-y divide-gray-200 min-h-[calc(100vh-96px)] lg:divide-x lg:divide-y-0 lg:grid lg:grid-cols-12" :selectedIndex="selectedTab" @change="selectedTab = $event">
        <TabList class="space-y-1 py-6 lg:col-span-3">
          <Tab v-for="(item) in subNavigation" v-slot="{ selected }" :key="item.name" as="template">
            <div :class="[selected ? 'bg-teal-50 border-teal-500 text-teal-700 hover:bg-teal-50 hover:text-teal-700 ' : 'border-transparent text-gray-900 hover:bg-gray-50 hover:text-gray-900', 'group border-l-4 px-3 py-2 flex items-center text-sm font-medium hover:cursor-pointer']" :aria-current="selected ? 'page' : undefined">
              <component :is="item.icon" :class="[selected ? 'text-teal-500 group-hover:text-teal-500' : 'text-gray-400 group-hover:text-gray-500', 'flex-shrink-0 -ml-1 mr-3 h-6 w-6']" aria-hidden="true" />
              <span class="pl-1 truncate">
                {{ item.name }}
              </span>
            </div>
          </Tab>
        </TabList>
        <TabPanels as="div" class="divide-y divide-gray-200 lg:col-span-9">
          <TabPanel>
            <div class="py-6 px-4 sm:p-6 lg:pb-8">
              <div>
                <h2 class="font-medium text-lg text-gray-900 leading-6">
                  Tell us about this NFT
                </h2>
                <p class="mt-1 text-sm text-gray-500">
                  We'll need its contract address, name, tagline, and description.
                </p>
              </div>
              <div class="mt-6 grid gap-10 grid-cols-12">
                <div class="col-span-12">
                  <label for="contractAddress" class="font-medium text-sm text-gray-700 block">NFT contract address</label>
                  <input id="contractAddress" type="text" name="contractAddress" v-model="contractAddress" class="border rounded-md border-gray-300 shadow-sm mt-1 py-2 px-3 w-5/6 block sm:text-sm focus:outline-none focus:border-sky-500 focus:ring-sky-500" placeholder="0x...">
                </div>
                <div class="col-span-12">
                  <label for="name" class="font-medium text-sm text-gray-700 block">NFT name</label>
                  <input id="name" type="text" name="name" v-model="name" class="border rounded-md border-gray-300 shadow-sm mt-1 py-2 px-3 w-5/6 block sm:text-sm focus:outline-none focus:border-sky-500 focus:ring-sky-500" placeholder="Simply the name of the NFT">
                </div>
                <div class="col-span-12">
                  <label for="tagline" class="font-medium text-sm text-gray-700 block">Tagline</label>
                  <input id="tagline" type="text" name="tagline" v-model="description" class="border rounded-md border-gray-300 shadow-sm mt-1 py-2 px-3 w-5/6 block sm:text-sm focus:outline-none focus:border-sky-500 focus:ring-sky-500" placeholder="Concise and descriptive tagline for the NFT">
                  <p class="mt-2 text-sm text-gray-500">
                    Tell us what the NFT does. Avoid hyperbolic words and emoji.
                  </p>
                </div>
                <div class="col-span-12">
                  <label for="name" class="font-medium text-sm text-gray-700 block">Content</label>
                  <div class="flex mt-1 w-full">
                    <EditorDefault v-model="content" />
                  </div>
                </div>
              </div>
            </div>
            <div class="border-t flex border-t-gray-200 mt-10 py-4 px-4 justify-end sm:px-6">
              <button @click="selectedTab+=1" class="border border-transparent rounded-md font-medium bg-green-400 shadow-sm text-sm text-white ml-5 py-2 px-4 inline-flex justify-center hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
                Next
              </button>
            </div>
          </TabPanel>
          <TabPanel>
            <div class="py-6 px-4 sm:p-6 lg:pb-8">
              <div>
                <h2 class="font-medium text-lg text-gray-900 leading-6">
                  Categorize the NFT
                </h2>
                <p class="mt-1 text-sm text-gray-500"></p>
              </div>
              <div class="mt-6 grid gap-10 grid-cols-12">
                <div class="col-span-12">
                  <label for="name" class="font-medium text-sm text-gray-700 block">Topics</label>
                  <div class="flex mt-1 w-5/6">
                    <AutocompleteDefault v-model="topics" :options="options" />
                  </div>
                </div>
              </div>
            </div>
            <div class="border-t flex border-t-gray-200 mt-10 py-4 px-4 justify-end sm:px-6">
              <button @click="selectedTab+=1" class="border border-transparent rounded-md font-medium bg-green-400 shadow-sm text-sm text-white ml-5 py-2 px-4 inline-flex justify-center hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
                Next
              </button>
            </div>
          </TabPanel>
          <TabPanel>
            <div class="py-6 px-4 sm:p-6 lg:pb-8">
              <div>
                <h2 class="font-medium text-lg text-gray-900 leading-6">
                  Connect to other systems.
                </h2>
                <p class="mt-1 text-sm text-gray-500">
                  What is the NFT's home page, twitter, discord...
                </p>
              </div>

              <div class="mt-6 grid gap-10 grid-cols-12">
                <div class="col-span-12">
                  <label for="name" class="font-medium text-sm text-gray-700 block">Links relative to the NFT</label>
                  <div class="flex mt-1" v-for="(item, index) in links" :key="index">
                    <div class="rounded-md flex shadow-sm w-5/6">
                      <span class="border rounded-l-md bg-gray-50 border-r-0 border-gray-300 px-3 text-gray-500 inline-flex items-center sm:text-sm"> https:// </span>
                      <input type="text" v-model="links[index]" class="rounded-none rounded-r-md flex-grow border-gray-300 min-w-0 block sm:text-sm focus:border-sky-500 focus:ring-sky-500">
                    </div>
                    <span class="ml-3">
                      <button type="button" @click="links.splice(index, 1)" class="bg-white border rounded-md font-medium border-gray-300 shadow-sm text-sm py-2 px-4 text-gray-700 inline-flex items-center hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-sky-500">
                        <MinusIcon class="h-5 text-gray-400 w-5" aria-hidden="true" />
                      </button>
                    </span>
                  </div>
                  <div class="text-sm pt-2 text-gray-500 hover:cursor-pointer" @click="links.push('')">
                    <span class="font-bold mr-1 text-red-400 ">+ Add more links</span>
                    <span>Twitter, Discord, Instagram, Facebook...</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="border-t flex border-t-gray-200 mt-10 py-4 px-4 justify-end sm:px-6">
              <button @click="selectedTab+=1" class="border border-transparent rounded-md font-medium bg-green-400 shadow-sm text-sm text-white ml-5 py-2 px-4 inline-flex justify-center hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
                Next
              </button>
            </div>
          </TabPanel>
          <TabPanel>
            <div class="py-6 px-4 sm:p-6 lg:pb-8">
              <div>
                <h2 class="font-medium text-lg text-gray-900 leading-6">
                  Images for NFT landing and listing
                </h2>
                <p class="mt-1 text-sm text-gray-500">
                  Let's make the NFT look nice.
                </p>
              </div>

              <div class="mt-6 grid gap-10 grid-cols-12">
                <div class="col-span-12">
                  <label for="thumbnail" class="font-medium text-sm text-gray-700 block">Thumbnail</label>
                  <FileUploaderThumbnail v-model="thumbnail" title="Thumbnail" class="h-60 w-60 sm:col-span-6" />
                </div>
                <!-- <div class="col-span-12">
                  <FileUploaderBanner v-model="banner" title="Banner" class="sm:col-span-6" />
                </div> -->
                <div class="col-span-12">
                  <FileUploaderGallery v-model="gallery" title="Gallery" class="sm:col-span-6" />
                </div>
              </div>
            </div>
            <div class="border-t flex border-t-gray-200 mt-10 py-4 px-4 justify-end sm:px-6">
              <button @click="selectedTab += 1" class="border border-transparent rounded-md font-medium bg-green-400 shadow-sm text-sm text-white ml-5 py-2 px-4 inline-flex justify-center hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
                Next
              </button>
            </div>
          </TabPanel>
          <TabPanel>
            <div class="py-6 px-4 sm:p-6 lg:pb-8">
              <div>
                <h2 class="font-medium text-lg text-gray-900 leading-6">
                  Submit data to Web3
                </h2>
                <p class="mt-1 text-sm text-gray-500">
                  Let's make all your data on the Web3.
                </p>
              </div>

              <div class="mt-6 grid gap-10 grid-cols-12">
                <div class="col-span-12">
                  <nav class="flex justify-start" aria-label="Progress">
                    <ol role="list" class="space-y-3 w-full">
                      <li v-for="step in steps" :key="step.name">
                        <div v-if="step.status === 'complete'" class="group">
                          <span class="flex items-start justify-between">
                            <span class="font-medium flex-1 text-sm text-gray-500 group-hover:text-gray-900">{{ step.name }}</span>
                            <span class="font-medium text-sm ml-3 text-gray-500 group-hover:text-gray-900">{{ step.result }}</span>
                            <span class="flex flex-shrink-0 h-5 ml-3 w-5 relative items-center justify-center">
                              <CheckCircleIcon class="h-full w-full text-green-600 group-hover:text-green-800" aria-hidden="true" />
                            </span>
                          </span>
                        </div>
                        <div v-else-if="step.status === 'loading'" class="flex items-start justify-between" aria-current="step">
                          <span class="font-medium flex-1 text-sm text-green-600">{{ step.name }}</span>
                          <span class="font-medium text-sm  ml-3 text-green-600">{{ step.result }}</span>
                          <span class="flex flex-shrink-0 h-5 ml-3 w-5 relative items-center justify-center" aria-hidden="true">
                            <!-- <span class="rounded-full bg-green-200 h-4 w-4 absolute" />
                            <span class="rounded-full bg-green-600 h-2 w-2 relative block" /> -->
                            <eos-icons:loading class="text-green-600" />
                          </span>
                        </div>
                        <div v-else-if="step.status === 'error'" class="flex items-start justify-between" aria-current="step">
                          <span class="font-medium flex-1 text-sm text-red-600">{{ step.name }}</span>
                          <span class="font-medium text-sm  ml-3 text-red-600">{{ step.result }}</span>
                          <span class="flex flex-shrink-0 h-5 ml-3 w-5 relative items-center justify-center" aria-hidden="true">
                            <span class="rounded-full bg-red-200 h-4 w-4 absolute" />
                            <span class="rounded-full bg-red-600 h-2 w-2 relative block" />
                          </span>
                        </div>
                        <div v-else class="group">
                          <div class="flex items-start justify-between">
                            <p class="font-medium flex-1 text-sm text-gray-500 group-hover:text-gray-900">{{ step.name }}</p>
                            <p class="font-medium text-sm ml-3 text-gray-500 group-hover:text-gray-900">{{ step.result }}</p>
                            <div class="flex flex-shrink-0 h-5 ml-3 w-5 relative items-center justify-center" aria-hidden="true">
                              <div class="rounded-full bg-gray-300 h-2 w-2 group-hover:bg-gray-400" />
                            </div>
                          </div>
                        </div>
                      </li>
                    </ol>
                  </nav>
                </div>
              </div>
            </div>
            <div class="flex mt-10 py-4 px-4 justify-center sm:px-6">
              <btn-green @click="doSubmit" :isLoading="isLoading">
                Submit now
              </btn-green>
            </div>
          </TabPanel>
        </TabPanels>
      </TabGroup>
    </div>
    <dialog-confirm :show="dialogConfirmShow" @close="closeConfirmDialog" status="success" :title="dialogTitle">
      <p class="text-sm text-gray-500">{{dialogContent}}</p>
      <template #footer>
        <btn-black class="w-full" @click="closeConfirmDialog" :isLoading="false">Go back to token list</btn-black>
      </template>
    </dialog-confirm>
  </main>
</template>

<route lang="yaml">
meta:
  layout: nfttop.best
</route>
