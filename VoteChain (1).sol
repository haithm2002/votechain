// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VoteChain {

    // --- VARIABLES ---
    address public owner;
    bool public electionOpen;
    string public electionName;
    uint256 public totalVotesCast;

    // --- CANDIDATE STRUCTURE ---
    struct Candidate {
        uint256 id;
        string name;
        string party;
        uint256 voteCount;
    }

    // --- LISTS & MAPPINGS ---
    Candidate[] public candidates;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public hasVoted;

    // --- EVENTS ---
    event CandidateAdded(uint256 id, string name);
    event VoteCast(address voter, uint256 candidateId);
    event ElectionStateChanged(bool isOpen);
    event VoterWhitelisted(address voter);

    // --- ACCESS CONTROL ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier electionIsOpen() {
        require(electionOpen, "Election is not open");
        _;
    }

    modifier electionIsClosed() {
        require(!electionOpen, "Election is currently open");
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(string memory _electionName) {
        require(bytes(_electionName).length > 0, "Name cannot be empty");
        owner = msg.sender;
        electionName = _electionName;
        electionOpen = false;
    }

    // --- ADMIN FUNCTIONS ---
    function addCandidate(string calldata _name, string calldata _party)
        external onlyOwner electionIsClosed {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_party).length > 0, "Party cannot be empty");
        uint256 newId = candidates.length;
        candidates.push(Candidate(newId, _name, _party, 0));
        emit CandidateAdded(newId, _name);
    }

    function whitelistVoter(address _voter) external onlyOwner {
        require(_voter != address(0), "Invalid address");
        require(!isWhitelisted[_voter], "Already whitelisted");
        isWhitelisted[_voter] = true;
        emit VoterWhitelisted(_voter);
    }

    function openElection() external onlyOwner electionIsClosed {
        require(candidates.length >= 2, "Need at least 2 candidates");
        electionOpen = true;
        emit ElectionStateChanged(true);
    }

    function closeElection() external onlyOwner electionIsOpen {
        electionOpen = false;
        emit ElectionStateChanged(false);
    }

    // --- VOTER FUNCTIONS ---
    function castVote(uint256 _candidateId) external electionIsOpen {
        // SECURITY: Checks-Effects-Interactions pattern
        require(isWhitelisted[msg.sender], "You are not whitelisted");
        require(!hasVoted[msg.sender], "You already voted");
        require(_candidateId < candidates.length, "Invalid candidate");

        hasVoted[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
        totalVotesCast += 1;

        emit VoteCast(msg.sender, _candidateId);
    }

    // --- VIEW FUNCTIONS (free, no gas) ---
    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }

    function getCandidate(uint256 _id) external view
        returns (uint256, string memory, string memory, uint256) {
        require(_id < candidates.length, "Invalid candidate");
        Candidate storage c = candidates[_id];
        return (c.id, c.name, c.party, c.voteCount);
    }

    function getElectionStatus() external view
        returns (string memory, bool, uint256, uint256) {
        return (electionName, electionOpen, totalVotesCast, candidates.length);
    }
}