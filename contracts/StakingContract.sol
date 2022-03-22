    // SPDX-License-Identifier: Unlicense
    pragma solidity >=0.4.22 <0.9.0;

    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/math/SafeMath.sol";
    contract StakingContract is Ownable {
        using SafeMath for uint256;
        using SafeMath for uint16;
        using SafeERC20 for IERC20;

        address[] internal stakeholders; 
        address public lpTokenAddress;  // 0xF4927988BB35a7C0469C183f0e29adC8B16f0878 
        address public rewardTokenAddress; // WETH 0xe1686F0785008f01f5fAFcf34458B4a3049fBBdF 
        // IERC20 public lpTokenAddress;
        // IERC20 public rewardTokenAddress;
        mapping(address => uint256) internal stakes; 
        mapping(address => uint256) internal rewards; 
        mapping(address => uint256) private holdersTimeStamps;
        mapping(address => uint256) private interestRate;
        mapping(address => uint256) private WETHContractBalance;
        uint16 internal rewardPerHour1; // 2000 0,05% за 3600 секунд (в час)
        uint16 internal rewardPerHour2; // 1000 0,1% за 3600 секунд (в час)
        uint16 private freezTime;  // произвольная в мин 
        event CreateStake(address indexed stakeholder, uint256 amount, uint256 timestamp);
        event RemoveStake(address indexed stakeholder, uint256 amount, uint256 timestamp);
        event RemoveStakeholder(address indexed stakeholder, uint256 timestamp);
        event WithdrawReward(address indexed stakeholder, uint256 amount, uint256 timestamp);
        // uint8 private interestRate;
        constructor(address _lpTokenAddress, address _rewardTokenAddress, uint16 _timeMinutes, uint16 _rewardPerHour1, uint16 _rewardPerHour2) // "ERC20token", "BLR2", 18
        {   
            // lpTokenAddress = IERC20(_lpTokenAddress);
            // rewardTokenAddress = IERC20(_rewardTokenAddress);
            lpTokenAddress = _lpTokenAddress;
            rewardTokenAddress = _rewardTokenAddress;
            freezTime = _timeMinutes * 60; // in sec (6*6 36)
            rewardPerHour1 = _rewardPerHour1;
            rewardPerHour2 = _rewardPerHour2;
        }   
        modifier checkFreezTime() {
            require(
                block.timestamp > holdersTimeStamps[msg.sender] + freezTime, 
                "it's been less than an 1 hour"
            );
            _;  
        }   
        // STAKES
        function createStake(uint256 _stake)
            public
        {
            require(_stake > 0, "Amount must be more than 0"); 
            IERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), _stake);
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
                holdersTimeStamps[msg.sender] + (block.timestamp - holdersTimeStamps[msg.sender]) ;
                calculateInterestRate(stakes[msg.sender]);
            emit CreateStake(msg.sender, _stake, block.timestamp);
            }
        }

        function calculateInterestRate(uint256 _stake) internal returns(uint256 stake) {

        stake = _stake / (10**18);  
        if (stake == 0) {
                return interestRate[msg.sender];
            } else if  (stake > 0 wei && stake < 50 ) {
                return  interestRate[msg.sender] = rewardPerHour1;
                } else if (stake >= 50) { 
                    return interestRate[msg.sender] = rewardPerHour2;
                } 
            }

        function chekStakeTimePresent(address _stakeholder) public view returns(uint256 timeInMin) {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder); // моя проверка 
        require(_isStakeholder, "this address is not the stakeHolder"); 
        return timeInMin = (block.timestamp - holdersTimeStamps[msg.sender]) / 60; // в минутах. служебная 
        }     

        function chekInterestRate(address _stakeholder) public view returns(uint256) { 
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);  
        require(_isStakeholder, "this address is not the stakeHolder"); 
        return interestRate[_stakeholder];
        }

        function removeStake(uint256 _stake) 
            public
            checkFreezTime
        {
            require(_stake > 0, "Amount must be more than 0");

            stakes[msg.sender] = stakes[msg.sender].sub(_stake); 
            IERC20(lpTokenAddress).safeTransfer(msg.sender, _stake);
            // lpTokenAddress.safeTransferFrom(address(this), msg.sender, _stake);
            calculateInterestRate(stakes[msg.sender]);
            if(stakes[msg.sender] == 0) {
            removeStakeholder(msg.sender);
        }
            emit RemoveStake(msg.sender, _stake, block.timestamp);
        }
        function stakeOf(address _stakeholder) 
            public
            view
            returns(uint256)
        {   
            (bool _isStakeholder, ) = isStakeholder(_stakeholder); 
            require(_isStakeholder, "this address is not the stakeHolder"); 
            return stakes[_stakeholder];
        }

        function totalStakes() 
            public
            view
            returns(uint256)
        {
            uint256 _totalStakes = 0;
            for (uint256 s = 0; s < stakeholders.length; s += 1){
                _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
            }
            return _totalStakes;
        }
        // STAKEHOLDERS
        function isStakeholder(address _address) 
            public
            view
            returns(bool, uint256)
        {
            for (uint256 s = 0; s < stakeholders.length; s += 1){
                if (_address == stakeholders[s]) return (true, s);
            }
            return (false, 0);
        }
        function addStakeholder(address _stakeholder) 
            internal
        {
            (bool _isStakeholder, ) = isStakeholder(_stakeholder);
            if(!_isStakeholder) stakeholders.push(_stakeholder);
        }
        function removeStakeholder(address _stakeholder) 
            internal
        {
            (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
            if(_isStakeholder){
                stakeholders[s] = stakeholders[stakeholders.length - 1];
                stakeholders.pop(); 
                 interestRate[msg.sender] == 0;
            } 
            emit RemoveStakeholder(_stakeholder, block.timestamp);
        }

        // REWARDS
        function rewardOf(address _stakeholder) 
            public
            view
            returns(uint256)
        {
            (bool _isStakeholder, ) = isStakeholder(_stakeholder); 
            require(_isStakeholder, "this address is not the stakeHolder"); 
            return rewards[_stakeholder];
        }
        function totalRewards() 
            public
            view
            onlyOwner
            returns(uint256)
        {
            uint256 _totalRewards = 0;
            for (uint256 s = 0; s < stakeholders.length; s += 1){
                _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
            }
            return _totalRewards;
        }

      
        function calculateReward(address _stakeholder) // Flexible Staking (counting every hour)
            public
            view 
            returns(uint256 reward)
        {            
            if (interestRate[msg.sender] == rewardPerHour1) 
            {  // 1 hours (для тестов в ремикс 1 minutes)
            reward = (((block.timestamp - holdersTimeStamps[_stakeholder]) / 1 minutes) * stakes[_stakeholder]) / rewardPerHour1;
            return reward;
            } else if (interestRate[msg.sender] == rewardPerHour2) { 
            reward = (((block.timestamp - holdersTimeStamps[_stakeholder]) / 1 minutes) * stakes[_stakeholder]) / rewardPerHour2;
            return reward;
            }

            // return stakes[_stakeholder] * interestRate / 100; // Бессрочный стекинг (Flexible Staking)
        }
         function withdrawReward() 
            public
            checkFreezTime
        {   
            (bool _isStakeholder, ) = isStakeholder(msg.sender); 
            require(_isStakeholder, "this address is not the stakeHolder"); 
            uint256 reward = calculateReward(msg.sender);
            rewards[msg.sender] = rewards[msg.sender].sub(reward);
            IERC20(rewardTokenAddress).safeTransfer(msg.sender, reward);
            // rewardTokenAddress.safeTransfer(msg.sender, reward);
            emit WithdrawReward(msg.sender, reward, block.timestamp);
        }

        function getRewardToken(uint256 _amount) public onlyOwner {
            require(_amount > 0, "Amount must be more than 0");
            WETHContractBalance[address(this)] = WETHContractBalance[address(this)].add(_amount);
             IERC20(rewardTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        } 
         function withdrawRewardToken(uint256 _amount) public onlyOwner {
            require(_amount > 0, "Amount must be more than 0");
            WETHContractBalance[address(this)] = WETHContractBalance[address(this)].sub(_amount);
             IERC20(rewardTokenAddress).safeTransfer(msg.sender, _amount);
        } 
         function geWETHContractBalance() public onlyOwner returns(uint256) {
            return WETHContractBalance[address(this)]; 
        } 


        // function distributeRewards() // распределения вознаграждений между всеми заинтересованными сторонами.
        //     public
        //     onlyOwner   
        // {
        //     for (uint256 s = 0; s < stakeholders.length; s += 1){
        //         address stakeholder = stakeholders[s];
        //         uint256 reward = calculateReward(stakeholder);
        //         rewards[stakeholder] = rewards[stakeholder].add(reward);
        //     }
        // }
    }