import { ethers } from "ethers";
import MetaMaskOnboarding from "@metamask/onboarding";
import detectEthereumProvider from "@metamask/detect-provider";
import { CHAIN_ID } from "./../config/CHAIN";
import * as ls from "~/helpers/ls";

const chainId = CHAIN_ID;
const chainMap = CHAIN_MAP;

let onboarding: MetaMaskOnboarding = null;

export const useWeb3Auth = () => {
  const { addSuccess } = $(notificationStore());

  let error = $ref("");
  let isLoading = $ref(false);

  const doOnboard = async () => {
    onboarding.startOnboarding();
  };

  const forceChainSwitch = async (provider) => {
    if (provider.chainId === chainId) return true;

    try {
      await provider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId }],
      });
      return true;
    } catch (switchError) {
      // This error code indicates that the chain has not been added to MetaMask.
      if (switchError.code === 4902) {
        try {
          const rz = await provider.request({
            method: "wallet_addEthereumChain",
            params: [chainMap[chainId]],
          });
          return true;
        } catch (addError) {
          error = addError.message;
          return false;
        }
      }
      error = switchError.message;
    }

    return false;
  };

  // new version
  let accounts = $ref([]);
  const walletAddress = $computed(() => accounts[0]);
  let isShowOnboardModal = $ref(false);
  let rawProvider = $ref(null);
  let web3Provider = $ref(null);
  let signer = $ref(null);

  const handleAccountsChanged = (newAccounts) => {
    const oldAccounts = ls.getItem("accounts", []);

    // means user do not login yet, should notify user about login success
    if (oldAccounts.length === 0) addSuccess("Login Success!");

    accounts = newAccounts;
    ls.setItem("accounts", newAccounts);

    // means user click on logout btn
    if (newAccounts.length === 0) addSuccess("Logout Success!");
  };

  const doRequestAccounts = async () => {
    let provider = "";
    try {
      provider = await detectEthereumProvider();
      if (!provider) return false;
    } catch (err) {
      console.log("====> err :", err);
      return false;
    }

    rawProvider = provider;

    const isSuccess = await forceChainSwitch(provider);
    if (!isSuccess) return;

    try {
      const rz = await provider.request({ method: "eth_requestAccounts" });
      handleAccountsChanged(rz);
    } catch (err) {
      error = err.message;
      return false;
    }

    provider.on("message", (msg) => {
      console.log("====> msg :", msg);
    });
    provider.on("accountsChanged", handleAccountsChanged);
    provider.on("chainChanged", () => {
      window.location.reload();
    });

    web3Provider = new ethers.providers.Web3Provider(provider);
    signer = web3Provider.getSigner();

    return provider;
  };

  const doLogin = async () => {
    if (!MetaMaskOnboarding.isMetaMaskInstalled()) {
      isShowOnboardModal = true;
      return;
    }
    isLoading = true;
    await doRequestAccounts();
    isLoading = false;
    return true;
  };

  const doLogout = async () => {
    handleAccountsChanged([]);
  };

  const initContract = async (key, isWrite = false) => {
    const contractAddress = get(CHAIN_CONTRACT_MAP, `${key}.${CHAIN_ID}`);
    const contractAbi = CHAIN_CONTRACT_ABI_MAP[key];
    if (!contractAbi) throw new Error(`abi not found for ${key}`);

    let provider = "";
    try {
      const rawProvider = await detectEthereumProvider();
      provider = new ethers.providers.Web3Provider(rawProvider);
    } catch (err) {
      isShowOnboardModal = true // TODO: fix detectEthereumProvider bug
      return false;
    }

    if (!isWrite)
      return new ethers.Contract(contractAddress, contractAbi, provider);

    if (!walletAddress) {
      const rz = await doLogin();
      if (!rz) return;
    }

    if (!walletAddress) throw new Error("user do not login yet");

    const signer = provider.getSigner();

    return new ethers.Contract(contractAddress, contractAbi, signer);
  };

  watchEffect(() => {
    if (!MetaMaskOnboarding.isMetaMaskInstalled()) return;
    if (accounts.length > 0) onboarding.stopOnboarding();
  });

  onMounted(async () => {
    onboarding = new MetaMaskOnboarding();
    if (!MetaMaskOnboarding.isMetaMaskInstalled()) return;

    accounts = ls.getItem("accounts", []);
    if (accounts.length === 0) return;
    await doRequestAccounts();
  });
  onUnmounted(async () => {
    const provider = await detectEthereumProvider();
    if (!provider) return;

    if (provider.off) {
      provider.off("accountsChanged", handleAccountsChanged);
    }
  });

  const getTxUrl = (hash) => {
    const prefixUrl = chainMap[chainId]["blockExplorerUrls"];
    return `${prefixUrl}tx/${hash}`;
  };
  return $$({
    initContract,
    getTxUrl,
    error,
    rawProvider,
    isLoading,
    doOnboard,
    chainId,
    doLogin,
    doLogout,
    isShowOnboardModal,
    web3Provider,
    signer,
    walletAddress,
    ethers,
  });
};
