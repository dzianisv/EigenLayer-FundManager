// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 Hodlings Manager contains the map of EigenLayer operators
 1. Import EigenLayer operator contract interface
 2. Create a map of the Operator-> uind265 stake_bps
 3. Create an array of `address[] managers;` to store `managers` of the Fund
 4. Implment addManager, deleteManager. Any manager can remove or add a new manager. Manager shouldn't be able to delete itself.
 6. Implement `setOperator(Operator operator, uint265 stake_bps)`, this funciton could be called just by manager
 7. Implement the getter that returns the array of the structs {Operator, stake_bps}
 8. The user who is deploying this smart contract has to pass the address of the first `manager`.
*/

interface IEigenLayerOperator {
    // Example function (assuming what might be relevant)
    function getDetails() external view returns (string memory);
}

contract HoldingsManager {
    // TODO: replace address by the Operator smart contract (or what ever smart contract that reprensents the Operator)
    // Mapping of operators to their stake in basis points
    mapping(address => uint256) public operatorStakes;

    // Array to store managers
    address[] public managers;

    // Modifier to restrict function access to managers only
    modifier onlyManager() {
        require(isManager(msg.sender), "Caller is not a manager");
        _;
    }

    constructor(address initialManager) {
        // The deploying user sets the initial manager
        require(initialManager != address(0), "Manager address cannot be zero");
        managers.push(initialManager);
    }

    // Check if an address is a manager
    function isManager(address user) public view returns (bool) {
        for (uint i = 0; i < managers.length; i++) {
            if (managers[i] == user) {
                return true;
            }
        }
        return false;
    }

    // Add a new manager
    function addManager(address newManager) public onlyManager {
        require(newManager != address(0), "Invalid manager address");
        require(!isManager(newManager), "Address is already a manager");
        managers.push(newManager);
    }

    // Remove an existing manager
    function deleteManager(address manager) public onlyManager {
        require(manager != msg.sender, "Managers cannot remove themselves");
        require(isManager(manager), "Address is not a manager");

        for (uint i = 0; i < managers.length; i++) {
            if (managers[i] == manager) {
                managers[i] = managers[managers.length - 1];
                managers.pop();
                break;
            }
        }
    }

    // Set or update an operator's stake
    function setOperator(address operator, uint256 stake_bps) public onlyManager {
        require(operator != address(0), "Invalid operator address");
        operatorStakes[operator] = stake_bps;
    }

    // Get all operators and their stakes
    function getAllOperators() public view returns (address[] memory, uint256[] memory) {
        uint256 count = 0;
        address[] memory ops = new address[](managers.length);
        uint256[] memory stakes = new uint256[](managers.length);
        
        for (uint i = 0; i < managers.length; i++) {
            if (operatorStakes[managers[i]] > 0) {
                ops[count] = managers[i];
                stakes[count] = operatorStakes[managers[i]];
                count++;
            }
        }

        return (ops, stakes);
    }
}