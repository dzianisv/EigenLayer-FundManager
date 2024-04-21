// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./EigenLayerContracts.sol";
import "./MyOperator.sol";


interface IEigenLayerOperator {
    // Example function (assuming what might be relevant)
    function getDetails() external view returns (string memory);
}

struct OperatorInfo {
    address operator;
    uint256 weight;
}

contract HoldingsManager is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private _operators;  // Target Portfolio holdings map: MyOperatorAddress:TargetStakeInBps

    // Mapping of operators to their stake in basis points
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private _operatorWeights;  // Target Portfolio holdings map: MyOperatorAddress:TargetStakeInBps

    IEigenLayerContracts eigenLayerContracts;

    constructor(address admin, IEigenLayerContracts _eigenLayerContracts) {
        // The deploying user sets the admin and initial manager
        require(admin != address(0), "Admin address cannot be zero");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        eigenLayerContracts = _eigenLayerContracts;
    }

    // caller must have DEFAULT_ADMIN_ROLE
    // Add a manager -> grantRole(MANAGER_ROLE, address)
    // Remove a manager -> revokeRole(MANAGER_RILE, address)

    // Set or update an MyOperator's stake
    function setOperator(address operator, uint256 weight) external onlyRole(MANAGER_ROLE) {
        require(operator != address(0), "Invalid operator address");
        
        if (!_operators.contains(operator)) {
            MyOperator myOperator = new MyOperator(operator, eigenLayerContracts);
            _operators.set(operator, uint160(address(myOperator)));
        }

        _operatorWeights.set(operator, weight);
    }

    function removeOperator(address operator) external onlyRole(MANAGER_ROLE){
        require(operator != address(0), "Invalid operator address");
        _operatorWeights.remove(operator);
        _operators.remove(operator);
    }

    function getOperatorWeight(address operator) external view returns (uint256) {
        return _operatorWeights.get(operator);
    }

    function existsOperator(address operator) external view returns (bool) {
        return _operatorWeights.contains(operator);
    }

    function numberOfOperators() external view returns (uint256) {
        return _operatorWeights.length();
    }

    // Get all operators and their stakes
    function getOperatorsWeights() public view returns (MyOperator[] memory, uint256[] memory) {
        uint256 length = _operatorWeights.length();
        MyOperator[] memory operators = new MyOperator[](length);
        uint256[] memory stakes = new uint256[](length);
        
        for (uint i = 0; i < length; i++) {
            (address operator, uint256 stake) = _operatorWeights.at(i);
            operators[i] = MyOperator(address(uint160(_operators.get(operator))));
            stakes[i] = stake;
        }

        return (operators, stakes);
    }

    // Get all operators and their stakes as OperatorInfo[]
    function getOperatorsInfo() public view returns (OperatorInfo[] memory) {
        uint256 length = _operatorWeights.length();
        OperatorInfo[] memory operatorInfos = new OperatorInfo[](length);
        
        for (uint i = 0; i < length; i++) {
            (address operator, uint256 weight) = _operatorWeights.at(i);
            operatorInfos[i] = OperatorInfo({
                operator: operator,
                weight: weight
            });
        }

        return operatorInfos;
    }
}