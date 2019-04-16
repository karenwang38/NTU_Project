pragma solidity >=0.4.22 <0.6.0;
/*
- 搜尋：
    -停車場、可租車位
    -空位數
- 預約
    -時段
    -金額
    -支付
    -取消

- 出租
    -加入
    -時段
    -金額
    -取消

- 停車場訊息
    -增加
    -取消
*/


contract Parking {

    struct ParkInfo {
        uint Empty;     // empty number
        uint Total;     // total number
        bool [] SpaceStatus;   //0: empty | 1: occupation
        uint Price;
        mapping (address => bool) ParkAdmin; // Park administor has right to change info
        address payable ParkAddress; //receive wei
    }

    struct ReserveInfo {
        uint ParkID; // which Park
        uint SpaceID; // which Space
        uint State; // 0: release, 1: reserved, 2: using,
        address User;
    }


    //ParkInfo [] public parkinfo;
    mapping(uint => ParkInfo) public park_info; //parkingID mapping to ParkInfo
    mapping(uint => ReserveInfo) public reserve_info; //reservationID map to
    mapping(uint => bool) public parkIDvalid; // check parkID registered
    uint public reservationID;
    address public ContractOwner;  //have right to add/cancel Admin
    mapping (address => bool) public Admin; // 1: with right to change data

    //transfer wei log
    event transferEvent (address _from, address _to, uint _number);

    //initialize BetContract Address & Owner
    constructor () public {
        ContractOwner = msg.sender;
        Admin[ContractOwner] = true;
        reservationID = 0;
    }

    modifier onlyContractOwner () {
        require(msg.sender == ContractOwner, 'only contractOwner have right to it.');
        _;
    }

    modifier onlyAdmin () {
        require(Admin[msg.sender] == true, 'You are not Admin.');
        _;
    }

    modifier onlyParkAdmin (uint _parkId) {
        require(park_info[_parkId].ParkAdmin[msg.sender], 'You are not Park Administor');
        _;
    }

    //Give System Admin right
    function UpdetAdmin (bool _right, address _addr) public returns (bool) {
        Admin[_addr] = _right;
        return true;
    }

    //Give Park Admin right
    function UpdetParkAdmin (uint _parkingID, bool _right, address _addr) onlyParkAdmin (_parkingID) public
        returns (bool) {
        park_info[_parkingID].ParkAdmin[_addr] = _right;
        return true;
    }

    //Register Parking Info
    function ParkRegister (uint _total, uint _parkingID, uint _price, address payable _parkingOwner) onlyContractOwner onlyAdmin public
        returns (bool) {
        //parkingID ++;
        //parkNum2ID[_parkNum] = parkingID;
        require(parkIDvalid[_parkingID] == false, 'This ID already used.');
        parkIDvalid[_parkingID] = true;
        bool [] memory _status;
        _status = new bool [] (_total);

        for (uint i = 0; i < _total; i++ ) {
            _status[i] = false;
        }


        park_info[_parkingID].ParkAdmin[_parkingOwner] = true;

        park_info[_parkingID] = ParkInfo(_total, _total, _status, _price, _parkingOwner);
        return true;
    }

    //only Park administro or contract Owner can change Park Info
    function ChangeParkInfo (uint _parkingID, uint _total, uint _empty, uint _price) onlyParkAdmin (_parkingID) public {
        park_info[_parkingID].Total = _total;
        park_info[_parkingID].Empty = _empty;
        park_info[_parkingID].Price = _price;
    }

    //get Parking information
    function GetParkInfo (uint _parkingID) public view returns  (uint,
                                                                 uint,
                                                                 bool [] memory,
                                                                 uint) {

        require(parkIDvalid[_parkingID] == true, 'This ID is invalid.');
        return (park_info[_parkingID].Empty,
                park_info[_parkingID].Total,
                park_info[_parkingID].SpaceStatus,
                park_info[_parkingID].Price);
    }

    //Park reservation
    function ParkReserve (uint _parkingID, uint _spaceID) public payable returns (uint _reserveIds) {
        reservationID ++;
        require(parkIDvalid[_parkingID] == true, 'This ID is invalid (Parking lot not exit).');
        require(park_info[_parkingID].Empty != 0, 'There is no empty space.');
        require(park_info[_parkingID].SpaceStatus[_spaceID] == false, 'This space is not empty');

        park_info[_parkingID].SpaceStatus[_spaceID] = true;
        reserve_info [reservationID] = ReserveInfo(_parkingID, _spaceID, 1,msg.sender);
        park_info[_parkingID].Empty --;

        return reservationID;
    }

    //Reservation update : cancel or using
    function UpdateReserve (uint _reserveID, uint _state) public returns (bool) {

        require(reserve_info[_reserveID].User != msg.sender, 'you have no reservation.');
        require( (_state == 0 ) || (_state == 2), 'only cancel _state = 0 or using park _state = 2.');

        reserve_info[_reserveID].State = _state;

        uint parkId_temp = reserve_info[_reserveID].ParkID;
        uint parkSpaceId_temp = reserve_info[_reserveID].SpaceID;

        if (_state == 0) {
            // cancel reservation
            reserve_info[_reserveID] = ReserveInfo(0, 0, 0, address(0));
            park_info[parkId_temp].Empty ++;
            park_info[parkId_temp].SpaceStatus[parkSpaceId_temp]= false;

        } else {
            //using park
            reserve_info[_reserveID].State = _state;
        }

        return true;


    }

    //Park Order
    function ParkOrder (uint _parkingID,uint _spaceID) public returns (bool) {
        park_info[_parkingID].Empty--;
        park_info[_parkingID].SpaceStatus[_spaceID] = true;
        return true;
    }

    //payment
    function ParkPay (uint _reserveId, uint _parkingID, uint _spaceID) public payable returns (bool) {
        require(park_info[_parkingID].Price == msg.value, 'pay not correct.');

        park_info[_parkingID].Empty++;
        park_info[_parkingID].SpaceStatus[_spaceID] = false;

        //pay for Order
        if (_reserveId != 0) {
            reserve_info[_reserveId].State = 0;
        }

        park_info[_parkingID].ParkAddress.transfer(msg.value);
        emit transferEvent(msg.sender, park_info[_parkingID].ParkAddress, msg.value);
        return true;
    }


}
