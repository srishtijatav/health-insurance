
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DecentralizedHealthInsurance
 * @dev A smart contract for managing decentralized health insurance policies
 */
contract DecentralizedHealthInsurance {
    address public owner;
    uint256 public policyCounter;
    uint256 public claimCounter;
    
    struct Policy {
        uint256 id;
        address policyHolder;
        uint256 premium;
        uint256 coverageAmount;
        uint256 startDate;
        uint256 endDate;
        bool active;
    }
    
    struct Claim {
        uint256 id;
        uint256 policyId;
        address claimant;
        uint256 amount;
        string description;
        bool approved;
        bool processed;
    }
    
    mapping(uint256 => Policy) public policies;
    mapping(uint256 => Claim) public claims;
    mapping(address => uint256[]) public userPolicies;
    
    event PolicyCreated(uint256 policyId, address policyHolder, uint256 premium, uint256 coverageAmount);
    event ClaimSubmitted(uint256 claimId, uint256 policyId, address claimant, uint256 amount);
    event ClaimProcessed(uint256 claimId, bool approved);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    modifier onlyPolicyHolder(uint256 policyId) {
        require(policies[policyId].policyHolder == msg.sender, "Only the policy holder can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        policyCounter = 0;
        claimCounter = 0;
    }
    
    /**
     * @dev Creates a new insurance policy
     * @param _coverageAmount The maximum amount that can be claimed
     * @param _duration The duration of the policy in days
     * @return The ID of the newly created policy
     */
    function createPolicy(uint256 _coverageAmount, uint256 _duration) external payable returns (uint256) {
        require(msg.value > 0, "Premium must be greater than 0");
        require(_coverageAmount > 0, "Coverage amount must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        
        uint256 policyId = policyCounter++;
        
        Policy storage newPolicy = policies[policyId];
        newPolicy.id = policyId;
        newPolicy.policyHolder = msg.sender;
        newPolicy.premium = msg.value;
        newPolicy.coverageAmount = _coverageAmount;
        newPolicy.startDate = block.timestamp;
        newPolicy.endDate = block.timestamp + (_duration * 1 days);
        newPolicy.active = true;
        
        userPolicies[msg.sender].push(policyId);
        
        emit PolicyCreated(policyId, msg.sender, msg.value, _coverageAmount);
        
        return policyId;
    }
    
    /**
     * @dev Submits a claim on an active policy
     * @param _policyId The ID of the policy to claim against
     * @param _amount The amount being claimed
     * @param _description Description of the medical procedure/reason
     * @return The ID of the newly created claim
     */
    function submitClaim(uint256 _policyId, uint256 _amount, string memory _description) 
        external 
        onlyPolicyHolder(_policyId) 
        returns (uint256) 
    {
        Policy storage policy = policies[_policyId];
        
        require(policy.active, "Policy is not active");
        require(block.timestamp <= policy.endDate, "Policy has expired");
        require(_amount <= policy.coverageAmount, "Claim amount exceeds coverage");
        
        uint256 claimId = claimCounter++;
        
        Claim storage newClaim = claims[claimId];
        newClaim.id = claimId;
        newClaim.policyId = _policyId;
        newClaim.claimant = msg.sender;
        newClaim.amount = _amount;
        newClaim.description = _description;
        newClaim.approved = false;
        newClaim.processed = false;
        
        emit ClaimSubmitted(claimId, _policyId, msg.sender, _amount);
        
        return claimId;
    }
    
    /**
     * @dev Processes a submitted claim (approve or reject)
     * @param _claimId The ID of the claim to process
     * @param _approved Whether the claim is approved or not
     */
    function processClaim(uint256 _claimId, bool _approved) external onlyOwner {
        Claim storage claim = claims[_claimId];
        Policy storage policy = policies[claim.policyId];
        
        require(!claim.processed, "Claim has already been processed");
        require(policy.active, "Policy is no longer active");
        
        claim.approved = _approved;
        claim.processed = true;
        
        if (_approved) {
            require(address(this).balance >= claim.amount, "Contract has insufficient funds");
            payable(claim.claimant).transfer(claim.amount);
        }
        
        emit ClaimProcessed(_claimId, _approved);
    }
}
