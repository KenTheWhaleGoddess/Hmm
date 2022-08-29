// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./CloneLib.sol";
import "./INLL.sol";

contract NLLFactory is Ownable {

    address implementation;
    address multisig;
    uint256 counter;

    mapping(address => uint256) nftToNllIndex;
    mapping(uint256 => address) deployedImplementations;

    function nftToDeployedImplementation(address _nft) public view returns (address) {
        uint c = nftToNllIndex[_nft];
        //if (c == 0) return address(0); omitted for gas
        return deployedImplementations[c];
    }
    function nftToNotLarvaLabsIndex(address _nft) public view returns (uint) {
        return nftToNllIndex[_nft];
    }

    constructor (address _multisig, address _nft) {
        transferOwnership(_multisig);
        clone(_nft);
    }


    function clone(address _nft) public {
        require(nftToNllIndex[_nft] == 0, "we already have a NLL for this collection");
        counter++;

        address impl = LibClone.clone(implementation);

        INLL implStruct = INLL(impl);
        implStruct.init(address(this), _nft, multisig);

        deployedImplementations[counter] = impl;
        nftToNllIndex[_nft] = counter;
    }  

    function migrateCloner(address newCloner) external onlyOwner {
        for(uint i; i < counter; i++) {
            INLL(deployedImplementations[i]).setNewCloner(newCloner);
        }
    }

    function pauseFor(address _address) external onlyOwner {
        address nll = nftToDeployedImplementation(_address);
        require(nll != address(0), "stop");
        INLL(nll).pause();
    }
    function unpauseFor(address _address) external onlyOwner {
        address nll = nftToDeployedImplementation(_address);
        require(nll != address(0), "stop");
        INLL(nll).unpause();
    }
    function pauseForIdx(uint c) external onlyOwner {
        require(c != 0, "stop");
        address nll = deployedImplementations[c];
        require(nll != address(0), "drop");
        INLL(nll).pause();
    }
    function unpauseForIdx(uint c) external onlyOwner {
        require(c != 0, "stop");
        address nll = deployedImplementations[c];
        require(nll != address(0), "drop");
        INLL(nll).unpause();
    }

    function pauseAll() external onlyOwner {
        for(uint i; i < counter; i++) {
            INLL(deployedImplementations[i]).pause();
        }
    }
    function unpauseAll() external onlyOwner {
        for(uint i; i < counter; i++) {
            INLL(deployedImplementations[i]).unpause();
        }
    }

    function setImplementation(address impl) external onlyOwner {
        implementation = impl;
    }
}
