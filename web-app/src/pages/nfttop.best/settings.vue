<script setup lang="ts">
const { addSuccess } = $(notificationStore())
const { storeJson } = $(useNFTStorage())
const { initContract, walletAddress } = $(useWeb3Auth())

let { name, avatar, description, updateCache } = $(userStore())
let isSubmiting = $ref(false)
let editAvatar = $ref(avatar)
const doSubmit = async () => {
  if (isSubmiting) return
  isSubmiting = true

  // 1. store json
  const data = {
    walletAddress,
    name,
    avatar: editAvatar,
    description
  }
  const profileCID = await storeJson(data)
  // 2. submit on to chain
  const contractWriter = await initContract('NTBListing', true)
  const tx = await contractWriter.updateProfile(profileCID)
  await tx.wait()
  isSubmiting = false
  updateCache({
    name,
    avatar: editAvatar,
    description
  })
  addSuccess('Update profile success, the data will not refresh right now, pls check after some minutes!')
}

</script>
<template>
  <main class="bg-white rounded-lg h-full mx-auto max-w-4xl p-10 relative">
    <div class="space-y-6">
      <div>
        <h1 class="font-medium text-lg text-gray-900 leading-6">Settings</h1>
        <p class="mt-1 text-sm text-gray-500">Let’s get started by filling in the information below to setup your profile and settings.</p>
      </div>

      <div class="pb-3 lg:(flex pb-0) ">
        <div class="mr-10 mb-6">
          <label for="thumbnail" class="font-medium text-sm text-gray-700 block">Avatar</label>
          <FileUploaderThumbnail v-model="editAvatar" title="Avatar" />
        </div>
        <div class="space-y-6 flex-1">
          <div>
            <label for="name" class="font-medium text-sm text-gray-700 block"> Name </label>
            <div class="mt-1">
              <input type="text" name="name" id="name" v-model="name" class="rounded-md border-gray-300 shadow-sm w-full block sm:text-sm focus:border-green-500 focus:ring-green-500" placeholder="Your name" />
            </div>
          </div>
          <div>
            <label for="description" class="font-medium text-sm text-gray-700 block"> Description </label>
            <div class="mt-1">
              <textarea id="description" name="description" v-model="description" rows="7" class="border rounded-md border-gray-300 shadow-sm w-full p-2 block sm:text-sm focus:border-green-500 focus:ring-green-500" />
            </div>
          </div>
        </div>
      </div>
      <div class="border-t flex border-gray-200 pt-6 justify-end">
        <btn-green class="" :isLoading="isSubmiting" @click="doSubmit">Save</btn-green>
      </div>
    </div>
  </main>
</template>

<route lang="yaml">
meta:
  layout: nfttop.best
</route>
