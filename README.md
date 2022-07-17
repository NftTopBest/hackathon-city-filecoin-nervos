# NftTop.Best: Web3-ProductHunt

NftTop.Best, build on the IPFS and ERC1155.
We store all the detailed data in IPFS and submit the CID into our ERC1155 contract.
And make every one can mint && comment for every new token(as new project).

## Features

* UserA can submit new project by create new token
  * Then the token owned by userA
  * Every new token has created time store by IPFS and get information by `nftStorageClient.status` api
  * New token metadata store on IPFS
  * ERC1155 contract has a map for every token to store the metadata CID: `tokenURIMap`
  * We create a `drag && drop IPFS image && gallery uploader` components that can be re-use for further developer, will pack it into a node_module later then to share with other vue3 developer
* UserB can voteUp and with/without a comment message
  * Store all metadata with voteUp with name, avatar, walletAddress by IPFS
  * Push the CID into the ERC1155 contract that we have a `commentCIDArrayMap` for them
  * Get the comment created time by `nftStorageClient.status` api
* User can see the list of all token
* User can click and slideover to see every token's voteUp && comment list
* User can see the token detail page
  * thumbnail
  * gallery images with click to see modal big image
