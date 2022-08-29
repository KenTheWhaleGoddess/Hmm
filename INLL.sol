pragma solidity 0.8.10;

interface INLL {
    function init(address _cloner, address _nft, address multisig) external;
    function setNewCloner(address _cloner) external;
    function pause() external;
    function unpause() external;
}
