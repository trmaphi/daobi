// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDAObi3 {
    // Events
    event ClaimAttempted(address indexed _claimant, uint160 _votes);
    event ClaimSucceeded(address indexed _claimant, uint160 _votes);
    event NewChancellor(address indexed _newChanc);
    event VoteContractChange(address _newVoteScheme);
    event DaobiMinted(uint256 indexed amount);
    event SealContractChange(address _newSealAddr);
    event DAORetargeted(address _newDAO);
    event chancellorPaid(address _chancellor);

    // View functions
    function chancellor() external view returns (address);
    function votingContract() external view returns (address);
    function sealContract() external view returns (address);
    function DAOvault() external view returns (address);
    function swapFee() external view returns (uint24);
    function chancellorSalary() external view returns (uint256);
    function salaryInterval() external view returns (uint256);
    function lastSalaryClaim() external view returns (uint256);

    // State-changing functions
    function initialize() external;
    function updateContract() external;
    function retargetVoting(address _voteContract) external;
    function retargetSeal(address _sealContract) external;
    function pause() external;
    function unpause() external;
    function mint(uint256 amount) external;
    function claimChancellorSalary() external;
    function adjustSalaryInterval(uint _newInterval) external;
    function adjustSalaryAmount(uint _newSalary) external;
    function retargetDAO(address _newVault) external;
    function setSwapFee(uint24 _swapFee) external;
    function makeClaim() external;
    function recoverSeal() external;
}