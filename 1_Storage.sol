// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SchoolProjectCrowdfunding {
    struct Project {
        uint id;
        string name;
        string description;
        address payable creator;
        uint goal;
        uint deadline;
        uint fundsRaised;
        bool completed;
        mapping(address => uint) backers;
    }

    struct Stake {
        uint amount;
        uint reward;
        uint unlockTime;
    }

    uint public projectCount;
    mapping(uint => Project) public projects;
    mapping(address => Stake[]) public stakes;
    uint public rewardRate = 10; // 10% reward
    uint public stakingPeriod = 30 days;

    event ProjectCreated(uint id, string name, address creator, uint goal, uint deadline);
    event Funded(uint projectId, address backer, uint amount);
    event GoalReached(uint projectId);
    event Staked(address staker, uint amount, uint reward, uint unlockTime);
    event StakeClaimed(address staker, uint amount);

    function createProject(string memory _name, string memory _description, uint _goal, uint _duration) public {
        require(_goal > 0, "Goal must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");

        projectCount++;
        Project storage newProject = projects[projectCount];
        newProject.id = projectCount;
        newProject.name = _name;
        newProject.description = _description;
        newProject.creator = payable(msg.sender);
        newProject.goal = _goal;
        newProject.deadline = block.timestamp + _duration;
        newProject.fundsRaised = 0;
        newProject.completed = false;

        emit ProjectCreated(projectCount, _name, msg.sender, _goal, newProject.deadline);
    }

    function fundProject(uint _projectId) public payable {
        Project storage project = projects[_projectId];
        require(block.timestamp <= project.deadline, "Project funding period has ended");
        require(!project.completed, "Project funding is already completed");
        require(msg.value > 0, "Funding amount must be greater than zero");

        project.backers[msg.sender] += msg.value;
        project.fundsRaised += msg.value;

        emit Funded(_projectId, msg.sender, msg.value);

        if (project.fundsRaised >= project.goal) {
            project.completed = true;
            emit GoalReached(_projectId);
        }
    }

    function withdrawFunds(uint _projectId) public {
        Project storage project = projects[_projectId];
        require(msg.sender == project.creator, "Only the project creator can withdraw funds");
        require(project.completed, "Project funding goal has not been reached");

        uint amount = project.fundsRaised;
        project.fundsRaised = 0;
        project.creator.transfer(amount);
    }

    function stake() public payable {
        require(msg.value > 0, "Stake amount must be greater than zero");

        uint reward = (msg.value * rewardRate) / 100;
        uint unlockTime = block.timestamp + stakingPeriod;

        stakes[msg.sender].push(Stake({
            amount: msg.value,
            reward: reward,
            unlockTime: unlockTime
        }));

        emit Staked(msg.sender, msg.value, reward, unlockTime);
    }

    function claimStake(uint _stakeIndex) public {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");
        Stake storage userStake = stakes[msg.sender][_stakeIndex];
        require(block.timestamp >= userStake.unlockTime, "Stake is still locked");

        uint totalAmount = userStake.amount + userStake.reward;
        userStake.amount = 0;
        userStake.reward = 0;

        payable(msg.sender).transfer(totalAmount);
        emit StakeClaimed(msg.sender, totalAmount);
    }

    fallback() external payable {}
    receive() external payable {}
}
