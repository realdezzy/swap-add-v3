// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';


contract SwapAddLiquidityV3 is IERC721Receiver {
    /// @notice Represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;
    uint256[] public tokenIds;

    // Pancake smartRouter: 0x1b81D678ffb9C0263b24A97847620C99d213eB14
    ISwapRouter immutable swapRouter;

    // Pancake NonFungiblePositionManager: 0x46A15B0b27311cedF172AB29E4f4766fbE7F4364
    INonfungiblePositionManager immutable nonFungiblePositionManager;

    constructor(ISwapRouter _swapRouter, INonfungiblePositionManager _nonFungiblePositionManager) {
        swapRouter = _swapRouter;
        nonFungiblePositionManager = _nonFungiblePositionManager;
    }

    function swap(ISwapRouter.ExactInputSingleParams memory _params) internal returns(uint256 amountOut){

        // Transfer the specified amount of USDT to this contract.
        TransferHelper.safeTransferFrom(_params.tokenIn, msg.sender, address(this), _params.amountIn);

        // Approve the router to spend USDT.
        TransferHelper.safeApprove(_params.tokenIn, address(swapRouter), _params.amountIn);

        // Perform swap using the swaprouter
        amountOut = swapRouter.exactInputSingle(_params);

    }

    function addLiquidity(INonfungiblePositionManager.MintParams memory _params) internal {

        // Transfer the specified amount of USDT to this contract.
        TransferHelper.safeTransferFrom(_params.token0, msg.sender, address(this), _params.amount0Desired);
        // Approve the router to spend Token0.
        TransferHelper.safeApprove(_params.token0, address(nonFungiblePositionManager), _params.amount0Desired);

        // Approve the router to spend Token1.
        TransferHelper.safeApprove(_params.token1, address(nonFungiblePositionManager), _params.amount1Desired);
        
        //add liquidity
        nonFungiblePositionManager.mint(_params);
    
    }


    function swapAndAddLiquidity(bytes calldata data) external {

        uint16 fee = 100;
        // Decode calldata data 
        (ISwapRouter.ExactInputSingleParams memory swapParams
        ) = abi.decode(data, (ISwapRouter.ExactInputSingleParams));
        
        // Swap tokens
        uint256 token1Amount = swap(swapParams);

        // Create mint params
        INonfungiblePositionManager.MintParams memory liquidityParams = INonfungiblePositionManager.MintParams({
            token0: swapParams.tokenIn,
            token1: swapParams.tokenOut,
            fee: fee,
            tickLower: -2,
            tickUpper: 2,
            amount0Desired: token1Amount,
            amount1Desired: token1Amount,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 15 minutes
        });

        // Add liquidity
        addLiquidity(liquidityParams);

    }

     // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {

        _createDeposit(operator, tokenId);

        return this.onERC721Received.selector;
    }

    function _createDeposit(address owner, uint256 tokenId) internal {
        (, , address token0, address token1, , , , uint128 liquidity, , , , ) =
            nonFungiblePositionManager.positions(tokenId);

        // set the owner and data for position
        // operator is msg.sender
        deposits[tokenId] = Deposit({owner: owner, liquidity: liquidity, token0: token0, token1: token1});

        tokenIds.push(tokenId);
    }
}