pragma solidity >0.4.99 <0.6.0;

contract APtoken {
  // Name
  string public name = 'AP Token';

  // Symbol
  string public symbol = 'APT';

  // Standard
  string public standard = 'AP Token Ver 1.0';
  // Constructor
  // Set the total number of token
  // Read the total number of token
  uint256 public totalSupply;

  //1 eth = ? ETH2APtoken
  uint256 public ETH2APtoken;
  uint256 public ETH2Wei;

  //token owner
  address payable tokenOwner;



  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
    );

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value);

  event ethTransfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
    );

  mapping(address => uint256) public balanceOf;

  mapping(address => mapping(address => uint256)) public allowance;

  constructor(uint256 _initialSupply, uint256 _eth2token) public {
    tokenOwner = msg.sender;
    balanceOf[tokenOwner] = _initialSupply;
    totalSupply = _initialSupply;
    ETH2APtoken = _eth2token;
    ETH2Wei = 10 ** 18;

  }

  modifier onlyTokenOwner () {
        require(msg.sender == tokenOwner, 'only token Oowner have right to it.');
        _;
  }

  function transfer(address _to, uint256 _value) public returns (bool success){
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender]-= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender,_to,_value);
    return true;
  }

  // Delegated Transfer

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
    require(allowance[_from][msg.sender] >= _value && balanceOf[_from] >= _value);
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from,_to,_value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns(bool success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender,_spender,_value);
    return true;
  }



  function buyToken(uint _ethAmount) payable public returns(bool) {
      require(msg.value ==  _ethAmount * ETH2Wei, 'eth not correct.');
      require(balanceOf[tokenOwner] >= _ethAmount * ETH2APtoken, 'AP token not enought to sell');
      tokenOwner.transfer(msg.value);
      emit ethTransfer(msg.sender, tokenOwner, msg.value);
      balanceOf[tokenOwner] -= _ethAmount * ETH2APtoken;
      balanceOf[msg.sender] += _ethAmount * ETH2APtoken;
      emit Transfer(tokenOwner, msg.sender, _ethAmount * ETH2APtoken);
      return true;

  }

}
