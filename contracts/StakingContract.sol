// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.22 <0.9.0;

// сделай рефакторинг и всю проверочную логику выноси в modifier.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract StakingContract is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeERC20 for IERC20;

    address[] internal stakeholders; 
    address public lpTokenAddress; // 0xF4927988BB35a7C0469C183f0e29adC8B16f0878
    address public rewardTokenAddress; // 0xe1686F0785008f01f5fAFcf34458B4a3049fBBdF
    // IERC20 public lpTokenAddress;
    // IERC20 public rewardTokenAddress;
    mapping(address => uint256) internal stakes; 
    mapping(address => uint256) internal rewards; 
    mapping(address => uint256) private holdersTimeStamps; 
    mapping(address => uint256) private interestRate;
    mapping(address => uint256) private WETHContractBalance;
    uint16 internal rewardPerHour1; // 2000 0,05% за 3600 секунд (час)
    uint16 internal rewardPerHour2; // 1000 0,1% за 3600 секунд (час)
    uint16 private freezTime; // 60 мин
    event CreateStake(
        address indexed stakeholder,
        uint256 amount,
        uint256 timestamp
    );
    event RemoveStake(
        address indexed stakeholder,
        uint256 amount,
        uint256 timestamp
    );
    event RemoveStakeholder(address indexed stakeholder, uint256 timestamp);
    event WithdrawReward(
        address indexed stakeholder,
        uint256 amount,
        uint256 timestamp
    );

    // uint8 private interestRate;
    constructor(
        address _lpTokenAddress,
        address _rewardTokenAddress,
        uint16 _timeMinutes,
        uint16 _rewardPerHour1,
        uint16 _rewardPerHour2 
    ) {
        // lpTokenAddress = IERC20(_lpTokenAddress);
        // rewardTokenAddress = IERC20(_rewardTokenAddress);
        lpTokenAddress = _lpTokenAddress;
        rewardTokenAddress = _rewardTokenAddress;
        freezTime = _timeMinutes; // * 60; // in sec (6*6 36)
        rewardPerHour1 = _rewardPerHour1;
        rewardPerHour2 = _rewardPerHour2;
    }

      modifier isStakeHolder(address _stakeholder) {
            (bool _isStakeholder, ) = isStakeholder(_stakeholder);
            require(_isStakeholder, "this address is not the stakeHolder");
        _;
    }   
    modifier checkFreezTime() {
        require(
            block.timestamp > holdersTimeStamps[msg.sender] + freezTime,
            "it's been less than an 1 hour"
        );
        _;
    }

     modifier amount(uint256 _stake) {
        require( _stake > 0, "Amount must be more than 0");
        _;
    }
    // ---------- STAKES ----------
    function createStake(
        uint256 _stake 
    ) public amount(_stake) {
        IERC20(lpTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _stake
        );
        // lpTokenAddress.safeTransferFrom(msg.sender, address(this), _stake);
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
        if (!_isStakeholder) {
            addStakeholder(msg.sender);
            stakes[msg.sender] = stakes[msg.sender].add(_stake);
            holdersTimeStamps[msg.sender] = block.timestamp;
            calculateInterestRate(stakes[msg.sender]);
            emit CreateStake(msg.sender, _stake, block.timestamp);
        } else {
            stakes[msg.sender] = stakes[msg.sender].add(_stake);
            holdersTimeStamps[msg.sender] +
                (block.timestamp - holdersTimeStamps[msg.sender]);
            calculateInterestRate(stakes[msg.sender]);
            emit CreateStake(msg.sender, _stake, block.timestamp);
        }
    }

    function calculateInterestRate(uint256 _stake)
        internal
        returns (uint256 stake)
    {
        stake = _stake / (10**18);
        if (stake == 0) {
            return interestRate[msg.sender];
        } else if (stake > 0 wei && stake < 50) {
            return interestRate[msg.sender] = rewardPerHour1;
        } else if (stake >= 50) {
            return interestRate[msg.sender] = rewardPerHour2;
        }
    }

    function chekStakeTimePresent(address _stakeholder)
        public
        view
        isStakeHolder(_stakeholder)
        returns (uint256 timeInMin)
    {
        return
            timeInMin = (block.timestamp - holdersTimeStamps[_stakeholder]) / 60; // в минутах. служебная
    }

    function chekInterestRate()
        public
        view
        isStakeHolder(msg.sender)
        returns (uint256)
    {
        return interestRate[msg.sender];
    }

    function removeStake( 
        uint256 _stake 
    ) public checkFreezTime amount(_stake) {
        if (stakes[msg.sender] == 0) {
            removeStakeholder(msg.sender);
        } else {
            (bool reward) = withdrawReward();
            require(reward == true, "withdrawReward return false");
            IERC20(lpTokenAddress).safeTransfer(msg.sender, _stake);
            stakes[msg.sender] = stakes[msg.sender].sub(_stake);
            calculateInterestRate(stakes[msg.sender]);
            emit RemoveStake(msg.sender, _stake, block.timestamp);
            // lpTokenAddress.safeTransferFrom(address(this), msg.sender, _stake);
        }
    }

    function stakeOf(
        address _stakeholder 
    ) public view isStakeHolder(msg.sender) returns (uint256) {

        return stakes[_stakeholder];
    }

    function totalStakes()
        public
        view
        onlyOwner
        returns (
            uint256
        )
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------
    function isStakeholder(
        address _address 
    ) public view returns (bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function addStakeholder(
        address _stakeholder 
    ) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function removeStakeholder(
        address _stakeholder 
    ) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakes[msg.sender] = 0;
            holdersTimeStamps[msg.sender] = 0;
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
        emit RemoveStakeholder(_stakeholder, block.timestamp);
    }

    // ---------- REWARDS ----------
    function rewardOf(
        address _stakeholder 
    ) public isStakeHolder(msg.sender) returns (uint256 reward) { 
        (uint256 _reward) = calculateReward(_stakeholder);
        reward = _reward;
        return reward; 
    }

    function totalRewards()
        public
        onlyOwner
        returns (uint256 _totalRewards)
    {
        _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            uint256 reward = calculateReward(stakeholders[s]);
            _totalRewards += reward;
        }
        return _totalRewards;
    }

    function calculateReward(
        address _stakeholder // 1 minutes для быстрых тестов без forka (по планам 1 hour)
    ) internal returns (uint256) {
        uint256 _reward;
        if (interestRate[msg.sender] == rewardPerHour1) {
            _reward =
                (((block.timestamp - holdersTimeStamps[_stakeholder]) /
                    1 minutes) * stakes[_stakeholder]) /
                rewardPerHour1;
            rewards[_stakeholder] = rewards[_stakeholder].add(_reward);
            return (rewards[_stakeholder]);
        } else if (interestRate[msg.sender] == rewardPerHour2) {
            _reward =
                (((block.timestamp - holdersTimeStamps[_stakeholder]) /
                    1 minutes) * stakes[_stakeholder]) /
                rewardPerHour2;
            rewards[_stakeholder] = rewards[_stakeholder].add(_reward);
            return (rewards[_stakeholder]);
        }
        // return stakes[_stakeholder] * interestRate / 100;
    }

    function withdrawReward() public checkFreezTime isStakeHolder(msg.sender) returns (bool) {
        (uint256 reward) = calculateReward(msg.sender);
        if (reward != 0) {
            IERC20(rewardTokenAddress).safeTransfer(msg.sender, reward);
            rewards[msg.sender] = rewards[msg.sender].sub(reward);
            holdersTimeStamps[msg.sender] = block.timestamp;
            WETHContractBalance[address(this)] = WETHContractBalance[
                address(this)
            ].sub(reward);
            // rewardTokenAddress.safeTransfer(msg.sender, reward);
            emit WithdrawReward(msg.sender, reward, block.timestamp);
            return true;
        } else {
            return false;
        }
    }

    function sendRewardTokenToStakeContract(uint256 _amount) public amount(_amount) onlyOwner { 
        IERC20(rewardTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        WETHContractBalance[address(this)] = WETHContractBalance[address(this)]
            .add(_amount);
    }

    function withdrawRewardTokenFromStakeContract(uint256 _amount) public amount(_amount) onlyOwner {
        IERC20(rewardTokenAddress).safeTransfer(msg.sender, _amount);
        WETHContractBalance[address(this)] = WETHContractBalance[address(this)]
            .sub(_amount);
    }

    function getWETHContractBalance() public view onlyOwner returns (uint256) {
        return WETHContractBalance[address(this)];
    }

    function distributeRewards() // резервная 
        public
        onlyOwner
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
            holdersTimeStamps[stakeholders[s]] = block.timestamp; 
        }
    }
}
