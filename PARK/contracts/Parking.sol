pragma solidity >=0.4.22 <0.6.0;
contract Parking {

    struct ParkInfo {
        uint ParkID;
        uint Empty;     // empty number
        uint Total;     // total number
        uint [] SpaceState;   //0: empty | 1: occupation | other: reservationID\
        uint [] ReserveID;
        uint Price; //
        uint Deposit; // for Reservation
        mapping (address => bool) ParkAdmin; // Park administor has right to change info
        address payable ParkAddress; //receive wei
        bool Valid;
    }

    struct ReserveInfo {
        uint ParkID; // which Park
        uint SpaceID; // which Space
        uint SpaceHour; // reservation for after i-th hour
        uint State; // 0: release, 1: reserved
        uint ReservedTime; // reservation time
        address User;
    }


    //ParkInfo [] public parkinfo;
    mapping(uint => ParkInfo) public park_info; //parkingID mapping to ParkInfo
    mapping(uint => ReserveInfo) public reserve_info; //reservationID map to
    mapping(uint => bool) public parkIDvalid; // check parkID registered
    uint public reservationID;
    uint public ParkLotNumber;
    address public ContractOwner;  //have right to add/cancel Admin
    address public ContractAddress; // contract address for receiving wei
    mapping (address => bool) public Admin; // 1: with right to change AirPark system

    //for test parameter
    uint eth2wei = 10**18;
    uint time_unit = 60*60;
    uint before_reservation_time = 12 hours;
    uint valid_reservation_time = 30 minutes;

    //transfer wei log
    event transferEvent (address _from, address _to, uint _number);

    //initialize BetContract Address & Owner
    constructor () public {
        ContractOwner = msg.sender;
        ContractAddress = address(this);
        Admin[ContractOwner] = true;
        reservationID = 0;
        ParkLotNumber = 0;




    }

    modifier onlyContractOwner () {
        require(msg.sender == ContractOwner, 'only contractOwner have right to it.');
        _;
    }

    modifier onlyAdmin () {
        require(Admin[msg.sender] == true, 'You are not [AirPark Admin].');
        _;
    }

    modifier onlyParkAdmin (uint _parkId) {
        require(park_info[_parkId].ParkAdmin[msg.sender], 'You are not Park Administor');
        _;
    }

    //Give System Admin right
    function UpdetAdmin (bool _right, address _addr) onlyContractOwner onlyAdmin public returns (bool) {
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
    function ParkRegister (uint _total, uint _price, uint _deposit,address payable _parkingOwner)
        onlyContractOwner onlyAdmin public
        returns (uint) {

        //require(parkIDvalid[_parkingID] == false, 'This ID already used.');
        ParkLotNumber ++;
        parkIDvalid[ParkLotNumber] = true;
        uint [] memory _status;
        uint [] memory _reserve_id;
        _status = new uint [] (_total);
        _reserve_id = new uint [] (_total);

        for (uint i = 0; i < _total; i++ ) {
            _status[i] = 0;
            _reserve_id[i] = 0;
        }


        park_info[ParkLotNumber].ParkAdmin[_parkingOwner] = true;

        park_info[ParkLotNumber] = ParkInfo(ParkLotNumber, _total, _total, _status, _reserve_id, _price*eth2wei, _deposit*eth2wei, _parkingOwner, true);
        return ParkLotNumber;
    }

    //only Park administro or contract Owner can change Park Info
    function ChangeParkInfo (uint _parkingID,
                             uint _total,
                             uint _empty,
                             uint _price,
                             uint _spaceID,
                             uint _deposit,
                             uint _space_tatus,
                             uint _reserve_id,
                             bool _valid)
        onlyParkAdmin (_parkingID) public {

        require(parkIDvalid[_parkingID] == true, 'This Park ID is invalid.');
        require(park_info[_parkingID].SpaceState[_spaceID] > 1, 'only 0 and 1 for state.');
        require(park_info[_parkingID].SpaceState.length >= _spaceID, '_spaceID is out of range.');

        park_info[_parkingID].Total = _total;
        park_info[_parkingID].Price = _price * eth2wei;
        park_info[_parkingID].Deposit = _deposit*eth2wei;
        park_info[_parkingID].Empty = _empty;
        park_info[_parkingID].ReserveID[_spaceID] = _reserve_id;
        park_info[_parkingID].SpaceState[_spaceID] = _space_tatus;
        park_info[_parkingID].Valid = _valid;
    }

    //get Parking information (customer, read only, free)
    function GetSpaceInfo (uint _parkingID) public view returns  (uint [] memory space_status,
                                                                  uint [] memory reserve_id) {

        require(parkIDvalid[_parkingID] == true, 'This Park ID is invalid.');

        return (park_info[_parkingID].SpaceState,
                park_info[_parkingID].ReserveID);
    }

    //update ParkInfo for ParkAdmin
    //change space empty/occupation in time
    //update reservation status

    function UpdateParkEmpty (uint _parkingID, uint _spaceID, uint _status) public onlyParkAdmin(_parkingID) {
        //_status: 0 empty, 1 occupation, 2 update for reservation
        require(_status != park_info[_parkingID].SpaceState[_spaceID], 'state is same.');
        require(parkIDvalid[_parkingID] == true, 'This Park ID is invalid.');
        require(park_info[_parkingID].SpaceState.length >= _spaceID, '_spaceID is out of range.');

        //change space empty/occupation in time


        if (_status == 0) {
            park_info[_parkingID].Empty++;
            park_info[_parkingID].SpaceState[_spaceID] = _status;
        } else if (_status == 1) {
            park_info[_parkingID].Empty--;
            park_info[_parkingID].SpaceState[_spaceID] = _status;
        } else {
            //check reserve ID to update reservation status
            for (uint i = 0; i< park_info[_parkingID].ReserveID.length; i++) {
                uint reserveID_check = park_info[_parkingID].ReserveID[i];
                uint reserveTime_check = reserve_info[reserveID_check].ReservedTime + reserve_info[reserveID_check].SpaceHour * time_unit;

                //in reserved state
                if (park_info[_parkingID].ReserveID[i] > 0 && (reserve_info[reserveID_check].State == 1)) {
                        //Occupation in 12hours reservation
                        if ((reserveTime_check >= now) && (reserveTime_check - now < before_reservation_time)) {
                            //occupation from empty within reservation time 12 hours
                            if(park_info[_parkingID].SpaceState[i] == 0) {
                                park_info[_parkingID].SpaceState[i] = 1;
                                park_info[_parkingID].Empty--;
                            }

                        } else if (reserveTime_check < now) {
                        //release reservation when time out
                            reserve_info[reserveID_check].State = 0;
                            park_info[_parkingID].SpaceState[i] = 0;
                            park_info[_parkingID].ReserveID[i] = 0;
                            park_info[_parkingID].Empty++;
                            park_info[_parkingID].ParkAddress.transfer(park_info[_parkingID].Deposit);
                            emit transferEvent (ContractAddress, park_info[_parkingID].ParkAddress, park_info[_parkingID].Deposit);
                        }
                }
            }
        }







        // // check space = 0 or 1 for now
        // uint ocupation_num = 0;
        // for (uint i=0; i<park_info[_parkingID].SpaceStatus.length; i++)
        // {
        //      ocupation_num = ocupation_num + (park_info[_parkingID].SpaceStatus[i] % 2);
        // }
        // park_info[_parkingID].Empty = park_info[_parkingID].Total - ocupation_num;

    }


    //Park reservation
    function ParkReserve (uint _parkingID, uint _spaceID, uint _reserve_hour) public payable returns (uint _reserveIds) {

        require(parkIDvalid[_parkingID] == true, 'This ID is invalid (Parking lot not exit).');
        require(park_info[_parkingID].ReserveID[_spaceID] == 0, 'Reservation exit. Choses other place to reserve.');
        require(park_info[_parkingID].SpaceState[_spaceID] == 0, 'not empty, cant reserve.');
        require(msg.value == (park_info[_parkingID].Deposit), 'deposit not enough.');

        reservationID ++;
        park_info[_parkingID].ReserveID[_spaceID] = reservationID;
        // update ParkInfo when reservation time within before_reservation_time(12 hours)
        if(_reserve_hour * time_unit < before_reservation_time) {
            park_info[_parkingID].SpaceState[_spaceID] = 1;
            park_info[_parkingID].Empty--;
        }


        reserve_info [reservationID] = ReserveInfo(_parkingID, _spaceID, _reserve_hour, 1, now, msg.sender);
        emit transferEvent(msg.sender, ContractAddress, park_info[_parkingID].Deposit);

        return reservationID;
    }

    //Reservation update : cancel or using
    function UpdateReserve (uint _reserveID, uint _operator) public returns (bool, uint check_time) {

        uint check_time = (reserve_info[_reserveID].ReservedTime) + (reserve_info[_reserveID].SpaceHour * time_unit);

        require(reserve_info[_reserveID].User == msg.sender, 'you have no reservation.');
        require(check_time >= now, 'your reservation is time out.');


        require(reserve_info[_reserveID].State == 1, 'only reservation state can cancel or use park.');
        require( _operator == 0 || _operator == 1, '0: for cancel, 1: for park');

        uint park_id = reserve_info[_reserveID].ParkID;
        uint space_id = reserve_info[_reserveID].SpaceID;

        park_info[park_id].ReserveID[space_id] = 0;
        //cancel/using reservation
        if (check_time >= now) {
            //cancle
            if (_operator == 0) {


                if (check_time - now <= before_reservation_time) {
                    park_info[park_id].Empty++;
                    park_info[park_id].SpaceState[space_id] = 0;
                }
            //park
            } else if (_operator == 1) {
                require(check_time - now <= valid_reservation_time, 'not your reservation time.');
                park_info[park_id].SpaceState[space_id] = 1;

            }

            reserve_info[_reserveID].State = 0;
            //user get back deposit
            msg.sender.transfer(park_info[park_id].Deposit);
            emit transferEvent(ContractAddress, msg.sender, park_info[park_id].Deposit);
        }
        // out of reservation time
        return (true,check_time);
    }


    //payment (information from front end sensor)
    function ParkPay (uint _parkingID, uint _price) public payable returns (bool) {
        require( _price*eth2wei == msg.value, 'pay not correct.');


        park_info[_parkingID].ParkAddress.transfer(msg.value);
        emit transferEvent(msg.sender, park_info[_parkingID].ParkAddress, msg.value);
        return true;
    }


    //test
    function ChangeReservedTime (uint _reserveID, uint _time)  public {
        reserve_info[_reserveID].ReservedTime = _time;
    }


    function getContractBalance () public view returns (uint) {
        return ContractAddress.balance;
    }
}
