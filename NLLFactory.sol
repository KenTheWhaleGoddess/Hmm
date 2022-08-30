// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./CloneLib.sol";
import "./INLL.sol";

contract NLLFactory is Ownable {

    address currentImplementation;
    uint256 counter;

    mapping(address => uint256) nftToNllIndex;
    mapping(uint256 => address) deployedImplementations;


    constructor (address _multisig, address _nft) {
        transferOwnership(_multisig);
        clone(_nft);
        INLL(getDeployedImplementationfromNFT(_nft)).pause();
    }

    //clone

    function clone(address _nft) public returns (uint256) {
        require(nftToNllIndex[_nft] == 0, "we already have a NLL for this collection");
        counter++;

        address impl = LibClone.clone(currentImplementation);

        INLL implStruct = INLL(impl);
        implStruct.init(address(this), _nft);

        deployedImplementations[counter] = impl;
        nftToNllIndex[_nft] = counter;
        return counter;
    }  


    //reading/frontend facing methods

    function getCount() external view returns (uint256) {
        return counter;
    }
    function getCurrentImplementation() external view returns (address) {
        return currentImplementation;
    }

    function getDeployedImplementationfromNFT(address _nft) public view returns (address) {
        uint c = nftToNllIndex[_nft];
        //if (c == 0) return address(0); omitted for gas
        return deployedImplementations[c];
    }

    function getDeployedImplementationfromIdx(uint256 idx) public view returns (address) {
        //if (c == 0) return address(0); omitted for gas
        return deployedImplementations[idx];
    }
    function nftToNotLarvaLabsIndex(address _nft) public view returns (uint) {
        return nftToNllIndex[_nft];
    }


    //owner functions :o


    function migrateCloner(address newCloner) external onlyOwner {
        for(uint i; i < counter; i++) {
            INLL(deployedImplementations[i]).setNewCloner(newCloner);
        }
    }

    function pauseFor(address _address) external onlyOwner {
        address nll = getDeployedImplementationfromNFT(_address);
        require(nll != address(0), "stop");
        INLL(nll).pause();
    }
    function unpauseFor(address _address) external onlyOwner {
        address nll = getDeployedImplementationfromNFT(_address);
        require(nll != address(0), "stop");
        INLL(nll).unpause();
    }
    function pauseForIdx(uint c) external onlyOwner {
        require(c != 0, "stop");
        address nll = getDeployedImplementationfromIdx(c);
        require(nll != address(0), "drop");
        INLL(nll).pause();
    }
    function unpauseForIdx(uint c) external onlyOwner {
        require(c != 0, "stop");
        address nll = getDeployedImplementationfromIdx(c);
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

    function setCurrentImplementation(address impl) external onlyOwner {
        currentImplementation = impl;
    }
}
