// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] calldata path) 
        external 
        view 
        returns (uint[] memory amounts);
        
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract SnipingBot {
    address private owner;
    IUniswapV2Router02 public uniswapRouter;
    address public wethAddress;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Ethereum Mainnet Addresses
        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }
    
    // Function to trigger a buy if the token price is below the target price
    function snipeToken(
        address tokenAddress, 
        uint256 targetPriceInWei, 
        uint256 amountInETH
    ) external onlyOwner payable {
        require(msg.value >= amountInETH, "Insufficient ETH sent");
        
        // Check current token price via Uniswap router
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(
            amountInETH, 
            getPathForETHtoToken(tokenAddress)
        );
        uint256 currentPrice = amountsOut[amountsOut.length - 1];
        
        // Execute buy if the current price is below the target price
        require(currentPrice <= targetPriceInWei, "Price above target");
        
        // Swap ETH for tokens
        uniswapRouter.swapExactETHForTokens{value: amountInETH}(
            0, // Accept any amount of Tokens
            getPathForETHtoToken(tokenAddress),
            address(this),
            block.timestamp + 15
        );
    }
    
    // Function to withdraw any tokens or ETH sent to the contract
    function withdraw(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw ETH
            (bool success, ) = owner.call{value: address(this).balance}("");
            require(success, "ETH transfer failed");
        } else {
            // Withdraw specified ERC20 token
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(token.transfer(owner, balance), "Transfer failed");
        }
    }
    
    // Get path for ETH to token swap on Uniswap
    function getPathForETHtoToken(address tokenAddress) 
        private 
        view 
        returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = tokenAddress;
        return path;
    }
    
    // Receive ETH into the contract
    receive() external payable {}
    
    // Fallback function
    fallback() external payable {}
}
