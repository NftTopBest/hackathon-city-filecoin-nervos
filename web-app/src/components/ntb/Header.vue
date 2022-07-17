<script setup lang="ts">
import {
  Disclosure,
  DisclosureButton,
  DisclosurePanel,
  Menu,
  MenuButton,
  MenuItem,
  MenuItems,
} from '@headlessui/vue'
import { SearchIcon, UserCircleIcon } from '@heroicons/vue/solid'
import { BellIcon, MenuIcon, XIcon,  } from '@heroicons/vue/outline'
import { shortAddress } from '~/helpers/web3'

let { name, avatar, description, updateCache } = $(userStore())
const { getJson } = $(useNFTStorage())

const user = $(userStore())
const navigation = [
  { name: 'Home', href: '/' },
  { name: 'Submit', href: '/submit' },
]

const {
  initContract,
  isLoading,
  walletAddress,
  doLogin,
  doLogout,
} = $(web3Store())

const userNavigation = [
  // { name: 'Your Profile', href: '#' },
  { name: 'Settings', href: '/settings' },
  { name: 'Sign out', onClick: doLogout },
]
const text = $computed(() => isLoading ? 'Loading' : 'Login')

const queryData = async () => {
  const contractReader = await initContract('NTBListing', false)
  const profileCID = await contractReader.userProfileMap(walletAddress)
  if (!profileCID) return

  const data = await getJson(profileCID)
  name = data.name
  avatar = data.avatar
  description = data.description
  updateCache({
    name,
    avatar,
    description
  })
}
watchEffect(async () => {
  if (!walletAddress) return

  await queryData()
})
</script>
<template>
  <Disclosure v-slot="{ open }" as="nav" class="bg-gray-700" aria-label="Global">
    <div class="mx-auto mb-4 max-w-6xl px-2 sm:px-4 lg:px-8">
      <div class="flex h-16 justify-between">
        <div class="flex px-2 items-center lg:px-0">
          <router-link to="/">
            <h1 class="rounded-full flex font-bold bg-green-400 h-10  text-white text-xl w-10 justify-center items-center">
              N
            </h1>
          </router-link>
          <!-- main nav lg -->
          <div class="hidden lg:(flex space-x-4 ml-12) ">
            <router-link v-for="item in navigation" :key="item.name" :to="item.href" class="rounded-md font-medium text-sm text-white py-2 px-3 hover:bg-green-400">
              {{ item.name }}
            </router-link>
          </div>
        </div>
        <!-- search -->
        <div class="flex flex-1 px-1 items-center justify-center lg:ml-6 lg:justify-end">
          <div class="max-w-lg w-full lg:max-w-xs">
            <label for="search" class="sr-only">Search</label>
            <div class="text-white relative focus-within:text-gray-400">
              <div class="flex pl-3 inset-y-0 left-0 absolute items-center pointer-events-none">
                <SearchIcon class="flex-shrink-0 h-5 w-5" aria-hidden="true" />
              </div>
              <input id="search" name="search" class="border-transparent rounded-md bg-gray-600 placeholder-white text-base w-full py-2 pr-3 pl-10 leading-5 block sm:text-sm focus:bg-white focus:border-white focus:outline-none focus:placeholder-gray-400 focus:ring-0 focus:text-gray-900" placeholder="Search" type="search">
            </div>
          </div>
        </div>
        <div class="flex items-center lg:hidden">
          <!-- Mobile menu button -->
          <DisclosureButton class="rounded-md p-2 text-sky-200 inline-flex items-center justify-center hover:bg-green-400 hover:text-white focus:outline-none focus:ring-inset focus:ring-white focus:ring-2">
            <span class="sr-only">{{ $t('Open menu') }}</span>
            <MenuIcon v-if="!open" class="h-6 w-6 block" aria-hidden="true" />
            <XIcon v-else class="h-6 w-6 block" aria-hidden="true" />
          </DisclosureButton>
        </div>
        <div class="hidden lg:flex lg:ml-4 lg:items-center">
          <button type="button" class="rounded-full bg-gray-500 flex-shrink-0 p-1 text-sky-200 hover:text-white focus:outline-none focus:ring-white focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-500">
            <span class="sr-only">{{ $t('Notificaitons') }}</span>
            <BellIcon class="h-6 w-6" aria-hidden="true" />
          </button>

          <!-- Profile dropdown -->
          <Menu as="div" class="flex-shrink-0 ml-4 relative" v-if="walletAddress">
            <div>
              <MenuButton class="rounded-full flex bg-gray-500 text-sm focus:outline-none focus:ring-white focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-500">
                <span class="sr-only">{{ $t('Open user menu') }}</span>
                <ipfs-img class="rounded-full h-8 w-8" :src="user.avatar" alt="" v-if="user.avatar" />
                <UserCircleIcon class="rounded-full h-8 text-white w-8" v-else />
              </MenuButton>
            </div>
            <transition enter-active-class="transition ease-out duration-100" enter-from-class="transform opacity-0 scale-95" enter-to-class="transform opacity-100 scale-100" leave-active-class="transition ease-in duration-75" leave-from-class="transform opacity-100 scale-100" leave-to-class="transform opacity-0 scale-95">
              <MenuItems class="bg-white rounded-md shadow-lg ring-black mt-2 py-1 origin-top-right right-0 ring-1 ring-opacity-5 w-48 z-999 absolute focus:outline-none">
                <MenuItem v-for="item in userNavigation" :key="item.name" v-slot="{ active }">
                <button v-if="item.onClick" class="text-sm text-left w-full py-2 px-4 text-gray-700 hover:bg-gray-100" @click="item.onClick">
                  {{ item.name }}
                </button>
                <router-link v-else :to="item.href" :class="[active ? 'bg-gray-100' : '', 'block px-4 py-2 text-sm text-gray-700']">
                  {{ item.name }}
                </router-link>
                </MenuItem>
              </MenuItems>
            </transition>
          </Menu>
          <btn-green :disabled="isLoading" @click="doLogin" :isLoading="isLoading" v-else class="ml-2">
            {{ text }}
          </btn-green>
        </div>
      </div>
    </div>

    <DisclosurePanel class="lg:hidden">
      <div class="space-y-1 px-2 pt-2 pb-3">
        <DisclosureButton v-for="item in navigation" :key="item.name" as="template" class="rounded-md font-medium text-base text-white py-2 px-3 block hover:bg-green-400 hover:text-white">
          <router-link :to="item.href">
            {{ item.name }}
          </router-link>
        </DisclosureButton>
      </div>
      <div class="border-t border-gray-500 pt-4 pb-3">
        <div class="flex px-4 items-center">
          <div class="flex-shrink-0">
            <ipfs-img class="rounded-full h-10 w-10" :src="user.avatar" alt="" v-if="user.avatar" />
            <UserCircleIcon class="rounded-full h-10 text-white w-10" v-else />
          </div>
          <div class="ml-3">
            <div class="font-medium text-base text-white">
              {{ user.name }}
            </div>
            <div class="font-medium text-sm text-sky-200">
              {{ shortAddress(user.walletAddress) }}
            </div>
          </div>
          <button type="button" class="rounded-full ml-auto bg-gray-500 flex-shrink-0 p-1 text-sky-200 hover:text-white focus:outline-none focus:ring-white focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-500">
            <span class="sr-only">View notifications</span>
            <BellIcon class="h-6 w-6" aria-hidden="true" />
          </button>
        </div>
        <div class="mt-3 px-2">
          <DisclosureButton v-for="item in userNavigation" :key="item.name" as="a" :href="item.href" class="rounded-md font-medium text-base py-2 px-3 text-sky-200 block hover:bg-green-400 hover:text-white">
            {{ item.name }}
          </DisclosureButton>
        </div>
      </div>
    </DisclosurePanel>
  </Disclosure>
</template>
