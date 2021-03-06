// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./Common.sol";

contract Third is Ownable {
    using SafeMath for uint256;
    uint256 public pause = 0;

    mapping (address => address) public routers;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address public DOT = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402;
    address public UNI = 0xBf5140A22578168FD562DCcF235E5D43A02ce9B1;
    address public LINK = 0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD;
    address public BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address public USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    function setPause(uint256 _pause) public onlyOwner{
        pause = _pause;
    }
    // execute when major bug appears 
    // Prevent problems with third-party platforms
    // safe User assets
    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public onlyOwner {
        require(pause==1,'can not execute');
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // solium-disable-next-line security/no-call-value
        (bool success, ) = target.call{value:value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");
    }

    // pid => allShares
    mapping (uint256 => uint256) public allShares;

    // pid => address => shares
    mapping (uint256 => mapping(address => uint256)) public userShares;

    function _burn(uint256 _pid,uint256 _shares,address _user) internal {
        require(allShares[_pid] >= _shares,'allShares not enough!');
        allShares[_pid] = allShares[_pid].sub(_shares);
        require(userShares[_pid][_user] >= _shares,'user shares not enough!');
        userShares[_pid][_user] = userShares[_pid][_user].sub(_shares);
    }
    
    // _allBalance is the third platform shares
    // _amount is the deposit new shares
    function _mint(uint256 _pid,uint256 _amount,address _user,uint256 _allBalance) internal {
        uint256 _shares = 0;
        if (allShares[_pid] == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount.mul(allShares[_pid])).div(_allBalance);
        }
        allShares[_pid] = allShares[_pid].add(_shares);
        userShares[_pid][_user] = userShares[_pid][_user].add(_shares);
    }
    
    function getWithdrawBalance(uint256 _pid,uint256 _shares,uint256 _allBalance) public view returns(uint256){
        return (_allBalance.mul(_shares)).div(allShares[_pid]);
    }
    
    function getWithdrawShares(uint256 _pid,uint256 _amount,address _user,uint256 _userBalance) public view returns(uint256){
        return _amount.mul(userShares[_pid][_user]).div(_userBalance);
    }
    
    function userSharesReward(uint256 _pid,address _user,uint256 _allReward) public view returns(uint256){
        return _allReward.mul(userShares[_pid][_user]).div(allShares[_pid]);
    }

    function addRouter(address a,address b) public {
        routers[a] = b;
    }

    function removeRouter(address a) public {
        routers[a] = address(0);
    }

    function swap(IUniswapV2Router02 router,address token0,address token1,uint256 input) internal {
        if(routers[token1]==address(0)){
            address[] memory path = new address[](2);
            path[0] = token0;        
            path[1] = token1;
            router.swapExactTokensForTokens(input, uint256(0), path, address(this), block.timestamp.add(1800));
        } else{
            address[] memory path = new address[](3);
            path[0] = token0;        
            path[1] = routers[token1];
            path[2] = token1;
            router.swapExactTokensForTokens(input, uint256(0), path, address(this), block.timestamp.add(1800));
        }
    }

}