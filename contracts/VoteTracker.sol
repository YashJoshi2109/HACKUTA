pragma solidity >=0.4.21 <0.9.0;
pragma experimental ABIEncoderV2;
import "./VoteLibrary.sol";

contract VoteTracker {
    string private secret = "123456"; // Changed to 'private'

    mapping(uint => VoteLibrary.Vote) public VoteStore;
    uint256 public voterCount = 0;

    mapping(uint => VoteLibrary.Party) public PartyStore;
    uint256 public partyCount = 0;

    mapping(uint => VoteLibrary.Identity) public IdentityStore;
    uint256 public identityCount = 0;

    event IdentityCreate(string add, string adhaarNumber, string email);
    event PartyCreate(string name, uint voteCount);
    event VoteGenerate(uint voteCount, uint time, string partyName, string adhaar, string constituency);

    function registerUser(string memory _add, string memory _adhaarNumber, string memory _email) public returns (uint256) {
        require(checkIfAccCanExist(_add), "Account already exists");
        require(checkIfIdCanExist(_adhaarNumber), "ID already exists");
        identityCount++;
        IdentityStore[identityCount] = VoteLibrary.Identity(_add, _adhaarNumber, _email);
        emit IdentityCreate(_add, _adhaarNumber, _email);
        return identityCount;
    }

    function generateVote(string memory _adder, string memory _partyName, string memory _adhaar, string memory _constituency) public returns (uint256) {
        require(!checkIfAccCanExist(_adder), "Account not registered");
        require(!checkIfIdCanExist(_adhaar), "ID not registered");
        require(checkIfCanVote(_adhaar), "Already voted");
        require(!checkIfCanExist(_partyName), "Party does not exist");

        voterCount++;
        VoteStore[voterCount] = VoteLibrary.Vote(voterCount, block.timestamp, _partyName, _adhaar, _constituency);
        uint partyIndex = getParty(_partyName);
        PartyStore[partyIndex].voteCount++;

        emit VoteGenerate(voterCount, block.timestamp, _partyName, _adhaar, _constituency);
        return voterCount;
    }

    function createParty(string memory _name) public returns (uint256) {
        require(checkIfCanExist(_name), "Party already exists");
        partyCount++;
        PartyStore[partyCount] = VoteLibrary.Party(_name, 0);
        emit PartyCreate(_name, 0);
        return partyCount;
    }

    function getAdminKey() public view returns (string memory) {
        return secret;
    }

    function checkIfCanExist(string memory _namer) private view returns (bool) {
        for (uint i = 1; i <= partyCount; i++) {
            if (keccak256(abi.encodePacked(PartyStore[i].name)) == keccak256(abi.encodePacked(_namer))) {
                return false;
            }
        }
        return true;
    }

    function checkIfIdCanExist(string memory _namered) private view returns (bool) {
        for (uint i = 1; i <= identityCount; i++) {
            if (keccak256(abi.encodePacked(IdentityStore[i].adhaarNumber)) == keccak256(abi.encodePacked(_namered))) {
                return false;
            }
        }
        return true;
    }

    function checkIfAccCanExist(string memory _namerer) private view returns (bool) {
        for (uint i = 1; i <= identityCount; i++) {
            if (keccak256(abi.encodePacked(IdentityStore[i].add)) == keccak256(abi.encodePacked(_namerer))) {
                return false;
            }
        }
        return true;
    }

    function checkIfCanVote(string memory _adhaarer) private view returns (bool) {
        for (uint i = 1; i <= voterCount; i++) {
            if (keccak256(abi.encodePacked(VoteStore[i].adhaar)) == keccak256(abi.encodePacked(_adhaarer))) {
                return false;
            }
        }
        return true;
    }

    function getParty(string memory _partyNamer) private view returns (uint) {
        for (uint i = 1; i <= partyCount; i++) {
            if (keccak256(abi.encodePacked(PartyStore[i].name)) == keccak256(abi.encodePacked(_partyNamer))) {
                return i;
            }
        }
        revert("Party not found");
    }

    function getPartyCount() public view returns (uint) {
        return partyCount;
    }

    function getNames(uint _id) public view returns (uint, string memory) {
        require(_id <= partyCount, "Invalid party ID");
        return (PartyStore[_id].voteCount, PartyStore[_id].name);
    }
}
