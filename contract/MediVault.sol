// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Store only hashes/CIDs of ENCRYPTED files. Everything on-chain is public.
contract MediVault {
    address public admin = msg.sender;
    struct Hospital { string name; bool active; }
    struct Record { address hospital; string category; string fileHash; string note; uint256 time; }

    mapping(address => Hospital) public hospitals;
    address[] private hospitalList;
    mapping(address => Record[]) private records;
    mapping(address => mapping(address => uint256)) public accessUntil; // patient => doctor => expiry
    mapping(address => address[]) private doctorList;
    mapping(address => mapping(address => bool)) private listed;

    event HospitalAdded(address indexed hospital, string name);
    event HospitalRemoved(address indexed hospital);
    event AccessGranted(address indexed patient, address indexed doctor, uint256 until);
    event AccessRevoked(address indexed patient, address indexed doctor);
    event RecordAdded(address indexed patient, address indexed hospital, uint256 id);

    modifier onlyAdmin() { require(msg.sender == admin, "admin only"); _; }

    function transferAdmin(address a) external onlyAdmin { require(a != address(0), "zero"); admin = a; }

    function addHospital(address h, string calldata name) external onlyAdmin {
        require(h != address(0) && bytes(name).length > 0, "invalid");
        if (bytes(hospitals[h].name).length == 0) hospitalList.push(h);
        hospitals[h] = Hospital(name, true);
        emit HospitalAdded(h, name);
    }
    function removeHospital(address h) external onlyAdmin { hospitals[h].active = false; emit HospitalRemoved(h); }
    function hospitalCount() external view returns (uint256) { return hospitalList.length; }
    function hospitalAt(uint256 i) external view returns (address, string memory, bool) {
        address h = hospitalList[i]; return (h, hospitals[h].name, hospitals[h].active);
    }

    function grant(address doctor, uint256 daysValid) external {
        require(doctor != address(0) && doctor != msg.sender && daysValid > 0 && daysValid <= 365, "invalid");
        uint256 until = block.timestamp + daysValid * 1 days;
        accessUntil[msg.sender][doctor] = until;
        if (!listed[msg.sender][doctor]) { listed[msg.sender][doctor] = true; doctorList[msg.sender].push(doctor); }
        emit AccessGranted(msg.sender, doctor, until);
    }
    function revoke(address doctor) external { accessUntil[msg.sender][doctor] = 0; emit AccessRevoked(msg.sender, doctor); }
    function myDoctors() external view returns (address[] memory d, uint256[] memory until) {
        d = doctorList[msg.sender]; until = new uint256[](d.length);
        for (uint256 i; i < d.length; i++) until[i] = accessUntil[msg.sender][d[i]];
    }
    function hasAccess(address patient, address viewer) public view returns (bool) {
        return viewer == patient || accessUntil[patient][viewer] > block.timestamp;
    }

    function addRecord(address patient, string calldata category, string calldata fileHash, string calldata note) external {
        require(hospitals[msg.sender].active, "not an approved hospital");
        require(patient != address(0) && bytes(category).length > 0, "invalid");
        records[patient].push(Record(msg.sender, category, fileHash, note, block.timestamp));
        emit RecordAdded(patient, msg.sender, records[patient].length - 1);
    }
    function recordCount(address patient) external view returns (uint256) { return records[patient].length; }
    function getRecord(address patient, uint256 id) external view returns (address, string memory, string memory, string memory, uint256) {
        Record storage r = records[patient][id];
        require(hasAccess(patient, msg.sender) || r.hospital == msg.sender, "no access");
        return (r.hospital, r.category, r.fileHash, r.note, r.time);
    }
}
