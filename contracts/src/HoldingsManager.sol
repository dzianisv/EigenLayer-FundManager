// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

interface IEigenLayerOperator {
    // Example function (assuming what might be relevant)
    function getDetails() external view returns (string memory);
}

contract HoldingsManager is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Mapping of operators to their stake in basis points
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private _operatorStakes;  // Target Portfolio holdings map: MyOperatorAddress:TargetStakeInBps

    constructor(address admin) {
        // The deploying user sets the admin and initial manager
        require(admin != address(0), "Admin address cannot be zero");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    // caller must have DEFAULT_ADMIN_ROLE
    // Add a manager -> grantRole(MANAGER_ROLE, address)
    // Remove a manager -> revokeRole(MANAGER_RILE, address)

    // Set or update an MyOperator's stake
    function setOperator(address operator, uint256 stake_bps) external onlyRole(MANAGER_ROLE) {
        require(operator != address(0), "Invalid operator address");
        _operatorStakes.set(operator, stake_bps);
    }

    function removeOperator(address operator) external onlyRole(MANAGER_ROLE){
        require(operator != address(0), "Invalid operator address");
        _operatorStakes.remove(operator);
    }

    function getOperatorStake(address operator) external view returns (uint256) {
        return _operatorStakes.get(operator);
    }

    function existsOperator(address operator) external view returns (bool) {
        return _operatorStakes.contains(operator);
    }

    function numberOfOperators() external view returns (uint256) {
        return _operatorStakes.length();
    }

    // Get all operators and their stakes
    function getAllOperatorStakes() public view returns (address[] memory, uint256[] memory) {
        uint256 length = _operatorStakes.length();
        address[] memory operators = new address[](length);
        uint256[] memory stakes = new uint256[](length);
        
        for (uint i = 0; i < length; i++) {
            (address operator, uint256 stake) = _operatorStakes.at(i);
            operators[i] = operator;
            stakes[i] = stake;
        }

        return (operators, stakes);
    }
}