

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol";
import "https://github.com/aave/aave-v3-core/blob/master/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPoolAddressesProvider.sol";
import "https://github.com/aave/aave-v3-core/blob/master/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";


contract SimpleFlashLoan is FlashLoanSimpleReceiverBase {

    address payable owner;
    address public token1;
    address public token2;
    uint24 public fee1;
    uint24 public fee2;
    address public uniswapRouter3;
    address public pancake2;
    address public pancake3;
    uint24 public min;
    uint public time;
    uint256 public OutMin3; 
    address public aave;

    constructor(address _AAVE)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_AAVE))
    {
    owner = payable(msg.sender);
    uniswapRouter3 = 0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2;
    pancake2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    pancake3=0x1b81D678ffb9C0263b24A97847620C99d213eB14;
    aave=_AAVE;
    min=95;
    time=30;
    OutMin3=0;
    }

    function fn_RequestFlashLoan( address  _token1,address  _token2,uint256  _amount,uint24  _fee1,uint24  _fee2,uint8  _mode ) public {
        address receiverAddress = address(this);
        token1=_token1;
        address asset = token1;
        uint256 amount = _amount;
        bytes memory params = abi.encode(_mode);
        uint16 referralCode = 0;
        token2=_token2;
        fee1=_fee1;
        fee2=_fee2;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }



    
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {

        uint256 amountOwed = amount + premium;

        (uint8 mode) = abi.decode(params, ( uint8));
        address firstRouter;
        address secondRouter;

        if (mode == 5) {
            //5. Pancake v3 → Pancake V2  
            firstRouter = pancake3;  
            secondRouter = pancake2;
            swap_v3_v2(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3, fee1, time);
        }
        else if (mode == 8) {
            //8. Uniswap v3 → Pancake V2  

            firstRouter = uniswapRouter3;  
            secondRouter = pancake2;
            swap_v3_v2(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3, fee1, time);      
        }

        //////////////////////// v3 to v3
        if (mode == 3){
            //3 Pancake V3 ➝ Uniswap V3
            firstRouter = pancake3;  
            secondRouter = uniswapRouter3;
            swap_v3_v3(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3, fee1, fee2, time);
 
        }else if (mode == 1) {
             //1 Uniswap V3 ➝ pancake V3
            firstRouter = uniswapRouter3;  
            secondRouter = pancake3;
            swap_v3_v3(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3, fee1, fee2, time);
       
        }else if (mode == 2) {
             //2. Uniswap v3 → Uniswap v3  

            firstRouter = uniswapRouter3;  
            secondRouter = uniswapRouter3;
            swap_v3_v3(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3, fee1, fee2, time);
        }else if (mode == 4) {
            //4. Pancake v3 → Pancake v3  
            firstRouter = pancake3;  
            secondRouter = pancake3;
            swap_v3_v3(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3, fee1, fee2, time);
        }    
     
        ///////////////////////// V2  to V2
        if (mode == 7){
            //7. Pancake V2 → Pancake V2  
            firstRouter = pancake2;  
            secondRouter = pancake2;
            swap_v2_v2(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3);
        }                  
        ////////////////v2 to v3
        if (mode == 9){
            //9. Pancake V2 → Uniswap v3
            firstRouter = pancake2;  
            secondRouter = uniswapRouter3;
            swap_v2_v3(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3, fee2, time);
        }else if(mode == 6){
            //6. Pancake V2 → Pancake v3  
            firstRouter = pancake2;  
            secondRouter = pancake3;
            swap_v2_v3(firstRouter, secondRouter, asset, token2, amount, amountOwed, OutMin3, fee2, time);
        }
        
        uint256 receivedfinal = IERC20(asset).balanceOf(address(this));

        uint256 finaly= receivedfinal- amountOwed;
        require(IERC20(asset).approve(address(POOL), amountOwed), "Approval for loan repayment failed...!");
        if (finaly > 0) {
            require(IERC20(asset).transfer(owner, finaly), "Transfer to owner failed..Why!?");
        }
        return true;
    }
    


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function swap_v3_v2(
        address firstRouter,
        address secondRouter,
        address asset,
        address token2,
        uint256 amount,
        uint256 amountOwed,
        uint256 OutMin3,
        uint24 fee1,
        uint256 time
    ) internal returns (bool) {
        require(IERC20(asset).approve(firstRouter, amount), "error Approval _swap 1_ v3 to v2");

        uint256 receivedAmount;
        try ISwapRouter(firstRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: asset,
                tokenOut: token2,
                fee: fee1,
                recipient: address(this),
                amountIn: amount,
                amountOutMinimum: OutMin3,
                sqrtPriceLimitX96: 0,
                deadline: block.timestamp + time
            })
        ) returns (uint256 _receivedAmount) {
            receivedAmount = _receivedAmount;
        } catch {
            revert("Swap failed_swap 1_ v3 to v2");
        }

        require(receivedAmount > 0, "No tokens received_swap 1_ v3 to v2");
        require(IERC20(token2).approve(secondRouter, receivedAmount), "error Approval _swap 2_ v3 to v2");

        address[] memory path = new address[](2);
        path[0] = token2;
        path[1] = asset;

        uint256[] memory amounts = IPancakeRouter02(secondRouter).swapExactTokensForTokens(
            receivedAmount,
            OutMin3,
            path,
            address(this),
            block.timestamp
        );

        require(amounts[amounts.length - 1] >= amountOwed, "Insufficient funds to repay loan_v3 to v2");

        return true;
    }




    function swap_v3_v3(
        address firstRouter,
        address secondRouter,
        address asset,
        address token2,
        uint256 amount,
        uint256 amountOwed,
        uint256 OutMin3,
        uint24 fee1,
        uint24 fee2,
        uint256 time
    ) internal returns (bool) {
        require(IERC20(asset).approve(firstRouter, amount), "error Approval _swap 1_ v3 to v3");

        uint256 receivedAmount;
        try ISwapRouter(firstRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: asset,
                tokenOut: token2,
                fee: fee1,
                recipient: address(this),
                amountIn: amount,
                amountOutMinimum: OutMin3,
                sqrtPriceLimitX96: 0,
                deadline: block.timestamp + time
            })
        ) returns (uint256 _receivedAmount) {
            receivedAmount = _receivedAmount;
        } catch {
            revert("Swap failed_swap 1_ v3 to v3");
        }

        require(receivedAmount > 0, "No tokens received_swap 1_ v3 to v3");
        require(IERC20(token2).approve(secondRouter, receivedAmount), "error Approval _swap 1_ v3 to v3");

        try ISwapRouter(secondRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token2,
                tokenOut: asset,
                fee: fee2,
                recipient: address(this),
                amountIn: receivedAmount,
                amountOutMinimum: OutMin3,
                sqrtPriceLimitX96: 0,
                deadline: block.timestamp + time
            })
        ) returns (uint256 _receivedAmount) {
            receivedAmount = _receivedAmount;
        } catch {
            revert("Swap failed_swap 2_ v3 to v3");
        }

        uint256 finalUSDCBalance = IERC20(asset).balanceOf(address(this));
        require(finalUSDCBalance >= amountOwed, "Insufficient funds to repay the loan_ v3 to v3");

        return true;
    }



    function swap_v2_v2(
        address firstRouter,
        address secondRouter,
        address asset,
        address token2,
        uint256 amount,
        uint256 amountOwed,
        uint256 OutMin3
    ) internal returns (bool) {
        require(IERC20(asset).approve(firstRouter, amount), "Approval failed for swap 1 (V2 to V2)");

        address[] memory path2 = new address[](2);
        path2[0] = asset;
        path2[1] = token2;

        uint256[] memory amounts2 = IPancakeRouter02(firstRouter).swapExactTokensForTokens(
            amount,
            OutMin3,
            path2,
            address(this),
            block.timestamp
        );

        require(amounts2[amounts2.length - 1] > 0, "Swap 1 failed (V2 to V2)");

        uint256 volume = IERC20(token2).balanceOf(address(this));
        require(IERC20(token2).approve(secondRouter, volume), "Approval failed for swap 2 (V2 to V2)");

        address[] memory path3 = new address[](2);
        path3[0] = token2;
        path3[1] = asset;

        uint256[] memory amounts3 = IPancakeRouter02(secondRouter).swapExactTokensForTokens(
            volume,
            OutMin3, 
            path3,
            address(this),
            block.timestamp
        );

        require(amounts3[amounts3.length - 1] >= amountOwed, "Insufficient funds to repay loan (V2 to V2)");

        return true;
    }





    function swap_v2_v3(
        address firstRouter,
        address secondRouter,
        address asset,
        address token2,
        uint256 amount,
        uint256 amountOwed,
        uint256 OutMin3,
        uint24 fee2,
        uint256 time
    ) internal returns (bool) {
        require(IERC20(asset).approve(firstRouter, amount), "Approval failed for swap 1 (V2 to V3)");

        address[] memory path4 = new address[](2);
        path4[0] = asset;
        path4[1] = token2;

        uint256[] memory amounts = IPancakeRouter02(firstRouter).swapExactTokensForTokens(
            amount,
            OutMin3,
            path4,
            address(this),
            block.timestamp
        );

        require(amounts[amounts.length - 1] > 0, "Swap 1 failed (V2 to V3)");

        uint256 receivedVolume = IERC20(token2).balanceOf(address(this));
        require(IERC20(token2).approve(secondRouter, receivedVolume), "Approval failed for swap 2 (V2 to V3)");

        uint256 finalAmount;
        try ISwapRouter(secondRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token2,
                tokenOut: asset,
                fee: fee2,
                recipient: address(this),
                amountIn: receivedVolume,
                amountOutMinimum: OutMin3,
                sqrtPriceLimitX96: 0,
                deadline: block.timestamp + time
            })
        ) returns (uint256 _finalAmount) {
            finalAmount = _finalAmount;
        } catch {
            revert("Swap 2 failed (V2 to V3)");
        }

        require(IERC20(asset).balanceOf(address(this)) >= amountOwed, "Insufficient funds to repay loan (V2 to V3)");

        return true;
    }

// Functions to change parameters and withdraw

    function C_OutMin3(uint24 _min) external onlyOwner{
        OutMin3=_min;
    }

    function C_aave(address aavee) external onlyOwner {
        aave = aavee;
    }
        function C_pancake3(address _pancake3) external onlyOwner {
        pancake3 = _pancake3;
    }
        function C_pancake2(address _pancake2) external onlyOwner {
        pancake2 = _pancake2;
    }
        function C_uniswapRouter3(address _uniswapRouter3) external  onlyOwner{
        uniswapRouter3 = _uniswapRouter3;
    }

    function getBalance(address _tokenAddress) external view onlyOwner returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) payable onlyOwner  external  {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }


    function withdra_networktoken(uint256 _amount, address payable _to) public onlyOwner  {
        require(address(this).balance >= _amount, "Not enough balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function getBalance_networktoken() public view onlyOwner returns (uint256) {
    return address(this).balance;//این تابع فقط توکن بومی را نشان میدهد 
    }

    receive() external payable {}
}
