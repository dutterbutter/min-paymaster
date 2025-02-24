// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@testing-contracts-soldeer-0.0.3/contracts/l2-contracts/interfaces/IPaymaster.sol";
import "@testing-contracts-soldeer-0.0.3/contracts/l2-contracts/interfaces/IPaymasterFlow.sol";
import {PAYMASTER_VALIDATION_SUCCESS_MAGIC} from
    "@testing-contracts-soldeer-0.0.3/contracts/l2-contracts/interfaces/IPaymaster.sol";
import {L2_BOOTLOADER_ADDRESS} from
    "@testing-contracts-soldeer-0.0.3/contracts/l1-contracts/common/L2ContractAddresses.sol";
import {console} from "forge-std-1.9.6/console.sol";
import "@openzeppelin-contracts-5.2.0/access/Ownable.sol";

/// @author Matter Labs
/// @notice This contract does not include any validations other than using the paymaster general flow.
contract Paymaster is IPaymaster, Ownable {
    constructor() Ownable(msg.sender) {}

    modifier onlyBootloader() {
        require(msg.sender == L2_BOOTLOADER_ADDRESS, "Only bootloader can call this method");
        // Continue execution if called from the bootloader.
        _;
    }

    function validateAndPayForPaymasterTransaction(bytes32, bytes32, Transaction calldata _transaction)
        external
        payable
        onlyBootloader
        returns (bytes4 magic, bytes memory context)
    {
        // By default we consider the transaction as accepted.
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;
        require(_transaction.paymasterInput.length >= 4, "The standard paymaster input must be at least 4 bytes long");

        bytes4 paymasterInputSelector = bytes4(_transaction.paymasterInput[0:4]);
        if (paymasterInputSelector == IPaymasterFlow.general.selector) {
            // Note, that while the minimal amount of ETH needed is tx.gasPrice * tx.gasLimit,
            // neither paymaster nor account are allowed to access this context variable.
            uint256 requiredETH = _transaction.gasLimit * _transaction.maxFeePerGas;
            // The bootloader never returns any data, so it can safely be ignored here.
            (bool success,) = payable(L2_BOOTLOADER_ADDRESS).call{value: requiredETH}("");
            require(success, "Failed to transfer tx fee to the Bootloader. Paymaster balance might not be enough.");
        } else {
            revert("Unsupported paymaster flow in paymasterParams.");
        }
    }

    function postTransaction(
        bytes calldata _context,
        Transaction calldata _transaction,
        bytes32,
        bytes32,
        ExecutionResult _txResult,
        uint256 _maxRefundedGas
    ) external payable override onlyBootloader {
        // Refunds are not supported yet.
    }

    function withdraw(address payable _to) external onlyOwner {
        // send paymaster funds to the owner
        uint256 balance = address(this).balance;
        (bool success,) = _to.call{value: balance}("");
        require(success, "Failed to withdraw funds from paymaster.");
    }

    receive() external payable {}
}
