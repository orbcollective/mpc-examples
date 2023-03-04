// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

// This contract shows an example of how a managed pool controller can modify a pools weight
// gradual weight updates over 7 days for each change
import "@balancer-labs/v2-interfaces/contracts/pool-utils/IManagedPool.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/ILastCreatedPoolFactory.sol";

contract WeightChanger {
    // Assets WETH/USDC
    IERC20[] private _tokens;

    // Rebalance duration
    uint256 private constant _REBALANCE_DURATION = 7 days;

    // Minimum and maximum weight limits
    uint256 private constant _MIN_WEIGHT = 1e16; // 1%
    uint256 private constant _MAX_WEIGHT = 99e16; // 99%

    IVault private immutable _vault;
    bytes32 private immutable _poolId;
    IManagedPool private immutable _pool;

    constructor(IVault vault) {
        // Get poolId from the factory
        bytes32 poolId = IManagedPool(ILastCreatedPoolFactory(msg.sender).getLastCreatedPool()).getPoolId();

        // Verify that this is a real Vault and the pool is registered - this call will revert if not.
        vault.getPool(poolId);

        _vault = vault;
        _poolId = poolId;

        _pool = _getPoolFromId(poolId);
    }

    function make5050() public {
        uint256[] memory fiftyFifty = new uint256[](2);
        fiftyFifty[0] = 50e16;
        fiftyFifty[2] = 50e16;
        _updateWeights(block.timestamp, block.timestamp + _REBALANCE_DURATION, _tokens, fiftyFifty);
    }

    function make8020() public {
        uint256[] memory eightyTwenty = new uint256[](2);
        eightyTwenty[0] = 80e16;
        eightyTwenty[2] = 20e16;
        _updateWeights(block.timestamp, block.timestamp + _REBALANCE_DURATION, _tokens, eightyTwenty);
    }

    function make9901() public {
        uint256[] memory nintynineOne = new uint256[](2);
        nintynineOne[0] = 99e16;
        nintynineOne[2] = 1e16;
        _updateWeights(block.timestamp, block.timestamp + _REBALANCE_DURATION, _tokens, nintynineOne);
    }

    // Returns the time until weights are updated
    function _updateWeights(
        uint256 startBlock,
        uint256 endBlock,
        IERC20[] memory tokens,
        uint256[] memory weights
    ) internal returns (uint256) {
        _pool.updateWeightsGradually(startBlock, endBlock, tokens, weights);
        return endBlock - startBlock;
    }

    // === Public Getters ===
    function getMaximumWeight() public pure returns (uint256) {
        return _MAX_WEIGHT;
    }

    function getMinimumWeight() public pure returns (uint256) {
        return _MIN_WEIGHT;
    }

    function getCurrentWeights() public view returns (uint256[] memory) {
        return _pool.getNormalizedWeights();
    }

    function getPoolTokens() public view returns (IERC20[] memory) {
        (IERC20[] memory tokens, , ) = _vault.getPoolTokens(_poolId);
        return tokens;
    }

    function getPoolId() public view returns (bytes32) {
        return _poolId;
    }

    function getVault() public view returns (IVault) {
        return _vault;
    }

    /// === Private and Internal ===
    function _getPoolFromId(bytes32 poolId) internal pure returns (IManagedPool) {
        // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
        // since the logical shift already sets the upper bits to zero.
        return IManagedPool(address(uint256(poolId) >> (12 * 8)));
    }
}
