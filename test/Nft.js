const { toWei, fromWei } = require('web3-utils');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const Nft = artifacts.require('Sample');

contract('Nft', async ([owner, client, parentCompany]) => {
  it('deploy smart contract', async () => {
    //
    let nft = await Nft.new({ from: owner });

    const whitelists = [
      [
        client,
        '0xc18E78C0F67A09ee43007579018b2Db091116B4C',
        '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4',
        '0xBCb03471E33C68BCdD2bA1D846E4737fedb768Fa',
        '0x590AD8E5Fd87f05B064FCaE86703039d1F0e4350',
        '0x989b691745F7B0139a429d2B36364668a01A39Cf',
      ].map((a) => a.toLowerCase()),
      ['1234'].map((a) => a.toLowerCase()),
    ];

    const tree = (n) => new MerkleTree(whitelists[n], keccak256, {
      hashLeaves: true,
      sortPairs: true,
    });

    // setting lists on eth scan
    await nft.setClaimList(0, tree[0].getHexRoot(), { from: owner });
    await nft.setClaimList(1, tree[1].getHexRoot(), { from: owner });
    await nft.setClaimList(2, tree[2].getHexRoot(), { from: owner });

    await nft.setClaimActiveTime(0);
    await nft.purchaseClaimSpot(1, tree[0].getHexProof(keccak256(client)), {
      value: toWei('0.09'),
      from: client,
    });
    console.log(fromWei(await web3.eth.getBalance(owner)));
    await nft.withdraw({ from: owner });
    console.log(fromWei(await web3.eth.getBalance(owner)));
  });
});
