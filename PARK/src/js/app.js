App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  hasVoted: false,
  WeitoEth: 10 ** 18,

  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    // TODO: refactor conditional
    if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },

  initContract: function() {
    $.getJSON("Parking.json", function(parking) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.Parking = TruffleContract(parking);
      // Connect provider to interact with contract
      App.contracts.Parking.setProvider(App.web3Provider);

      App.listenForEvents();

      return App.render();
    });
  },

  // Listen for events emitted from the contract
  listenForEvents: function() {
    App.contracts.Parking.deployed().then(function(instance) {
      // Restart Chrome if you are unable to receive this event
      // This is a known issue with Metamask
      // https://github.com/MetaMask/metamask-extension/issues/2393



      instance.transferEvent({}, {
        fromBlock: 0,
        toBlock: 'latest'
      }).watch(function(error, event) {
        console.log("event triggered", event)
        // Reload when a new vote is recorded
        //App.render();
      });
    });
  },

  render: function() {
    var electionInstance;
    var loader = $("#loader");
    var content = $("#content");
    var adminRegister = $("#airParking_register");
    var userRegister = $("#user_register");





    loader.show();
    content.hide();

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);

        // Call a function to update the UI with the new account
        web3.eth.getBalance(App.account, function(err, balance) {

            $("#userBalance").html("Balance: " + balance/App.WeitoEth);
        });


      }
    });

    //monitor account
    var accountInterval = setInterval(function() {
        // Check if account has changed

        //console.log("monitor account");

        if (App.account!== web3.eth.accounts[0]) {
          console.log('Account changed!!');

          App.account = web3.eth.accounts[0];


          $("#accountAddress").html("Address: " + App.account);



          // Call a function to update the UI with the new account
          web3.eth.getBalance(App.account, function(err, balance) {

              $("#userBalance").html("Balance: " + balance/App.WeitoEth);
          });

          App.contracts.Parking.deployed().then(function(instance) {
            parkingInstance = instance;

            return parkingInstance.ContractOwner();
          }).then(function(contractOwner) {
            if (contractOwner !== App.account) {
              $("#userRignt").html("You are User");
              adminRegister.hide();
              userRegister.show();

            } else {
              $("#userRignt").html("AirParking Admin");
              adminRegister.show();
              userRegister.hide();
            }

          });



        } else {

        }

    }, 1000);



    // Load contract data
    App.contracts.Parking.deployed().then(function(instance) {
      parkingInstance = instance;

      return parkingInstance.ContractAddress();
    }).then(function(contractAddress) {
      $("#contractAddress").html("Contract Address: " + contractAddress);

      return parkingInstance.ContractOwner();
    }).then(function(contractOwner) {
      $("#contractOwner").html("Contract Owner: " + contractOwner);
      if (contractOwner !== App.account) {
        $("#userRignt").html("You are a User");
        adminRegister.hide();
        userRegister.show();
      } else {
        $("#userRignt").html("AirParking Admin");
        adminRegister.show();
        userRegister.hide();
      }

      return parkingInstance.ParkLotNumber();
    }).then(function(parklotNumber) {
      var parkLotInfo = $("#parkLotInfo");
      parkLotInfo.empty();

      var parkingLotSelect = $('#parkingLotSelect');
      parkingLotSelect.empty();


      for (var i = 1; i <= parklotNumber; i++) {

        parkingInstance.park_info(i).then(function(info) {
          var id = info[0]
          var empty = info[1];
          var total = info[2];
          var price = info[3];
          var deposit = info[4];
          var parkaddress = info[5];
          var valid = info[6];

          var parkLotInfoTemplate = "<tr><th>" + id + "</th><td>" + empty + "</td><td>" + total + "</td><td>" + price/App.WeitoEth + "</td><td>" + deposit/App.WeitoEth + "</td><td>" + parkaddress + "</td><td>" + valid +"</td></tr>";
          parkLotInfo.append(parkLotInfoTemplate);


          var parkingLotSelecTemp = "<option value='" + id + "' >" + "ID:" + id + " " +"empty:" + empty +"</ option>"
          parkingLotSelect.append(parkingLotSelecTemp);

        });
      }


      return electionInstance.candidatesCount();
    }).then(function(candidatesCount) {
      var candidatesResults = $("#candidatesResults");
      candidatesResults.empty();

      var candidatesSelect = $('#candidatesSelect');
      candidatesSelect.empty();

      for (var i = 1; i <= candidatesCount; i++) {
        electionInstance.candidates(i).then(function(candidate) {
          var id = candidate[0];
          var name = candidate[1];
          var voteCount = candidate[2];

          // Render candidate Result
          var candidateTemplate = "<tr><th>" + id + "</th><td>" + name + "</td><td>" + voteCount + "</td></tr>"
          candidatesResults.append(candidateTemplate);

          // Render candidate ballot option
          var candidateOption = "<option value='" + id + "' >" + name + "</ option>"
          candidatesSelect.append(candidateOption);
        });
      }
      return electionInstance.voters(App.account);
    }).then(function(hasVoted) {
      // Do not allow a user to vote
      if(hasVoted) {
        $('form').hide();
      }
      loader.hide();
      content.show();
    }).catch(function(error) {
      console.warn(error);
    });
  },

  Book: function() {
    var parkId = $('#parkingLotSelect').val();
    var startBookTime = $('#booktime').val();
    var spaceId = $('#spaceId').val();
    var depositEth = $('#depositEth').val();
    console.log("parkingLotSelect= ", parkingLotSelect);
    console.log("startBookTime= ", startBookTime);
    console.log("spaceId= ", spaceId);



    App.contracts.Parking.deployed().then(function(instance) {
      parkingInstance = instance;

      return parkingInstance.park_info(parkId);
    }).then(function(parkInfo) {
      var deposit = parkInfo[4];
      console.log("deposit:", deposit);


      return parkingInstance.ParkReserve(parkId, spaceId, startBookTime, {value: deposit});
    }).then(function(result) {
      // Wait for votes to update
      App.render();
    }).catch(function(err) {
      console.error(err);
    });
  },

  ParkRegister: function() {
    var total = $('#total').val();
    var parkingID = $('#parkingID').val();
    var price = $('#price').val();
    var deposit = $('#deposit').val();
    var parkingOwner = $('#parkingOwner').val();
    App.contracts.Parking.deployed().then(function(instance) {
      return instance.ParkRegister(total, price, deposit, parkingOwner);
    }).then(function(result) {
      // Wait for votes to update
      App.render();
      console.log(result);
    }).catch(function(err) {
      console.error(err);
    });
  },

  SearchSpace: function() {
    var parkId = $('#parkingLotSelect').val();

    App.contracts.Parking.deployed().then(function(instance) {


      return instance.GetSpaceInfo(parkId);
    }).then(function(result) {
      var status = result[0];
      var reserveId= result[1];
      $("#spaceInfo").html("Status: " + status + " Book Id: " + reserveId);
    }).catch(function(err) {
      console.error(err);
    });
  },

  ReserveCheck: function() {
    var reserveId = $('#reserveId').val();
    var reserveInfo = $('#reserveInfo');
    reserveInfo.empty();


    App.contracts.Parking.deployed().then(function(instance) {


      return instance.reserve_info(reserveId);
    }).then(function(result) {
      var reservarionInformation = {
        ParkID : result[0],
        SpaceID : result[1],
        SpaceHour : result[2],
        State : result[3],
        ReservedTime : result[4],
        User : result[5],
      }

      // console.log("resule.length=", result.length)
      // console.log("reservarionInformation=", reservarionInformation)
      for (var i = 0; i < result.length; i++) {
        var reserveKey = Object.keys(reservarionInformation)[i]
        if (reserveKey === "ReservedTime") {
            var dataTime = App.timestampToTime(reservarionInformation[reserveKey]);
            var reserveIdTemplate = "<p>" + reserveKey + ":" + dataTime + "</p>"
        } else {
          var reserveIdTemplate = "<p>" + reserveKey + ":" + reservarionInformation[reserveKey] + "</p>"
        }


        reserveInfo.append(reserveIdTemplate);
      }



    }).catch(function(err) {
      console.error(err);
    });
  },

  ReservationCancel: function() {
    var reserveId = $('#reserveId').val();

    App.contracts.Parking.deployed().then(function(instance) {


      return instance.UpdateReserve(reserveId, 0);
    }).then(function(result) {
      alert("cancel success!")
      App.render();
    }).catch(function(err) {
      console.error(err);
      alert("cancel fail!")
    });
  },

  ReservationParking: function() {
    var reserveId = $('#reserveId').val();

    App.contracts.Parking.deployed().then(function(instance) {


      return instance.UpdateReserve(reserveId, 1);
    }).then(function(result) {
      alert("parking success!")
      App.render();
    }).catch(function(err) {
      console.error(err);
      alert("parking fail : reservation is not allowed!")
    });
  },

  ChangeReserveTime: function() {
    var reserveId = $('#reserveId').val();
    var changeTime = $('#changeTime').val();

    App.contracts.Parking.deployed().then(function(instance) {


      return instance.ChangeReservedTime(reserveId, changeTime);
    }).then(function(result) {

    }).catch(function(err) {
      console.error(err);

    });
  },

  timestampToTime : function (timestamp) {

        var  date = new Date(timestamp * 1000);//时间戳为10位需*1000，时间戳为13位的话不需乘1000

        var Y = date.getFullYear() + '-';

        var M = (date.getMonth()+1 < 10 ? '0'+(date.getMonth()+1) : date.getMonth()+1) + '-';

        var D = date.getDate() + ' ';

        var h = date.getHours() + ':';

        var m = date.getMinutes() + ':';

        var s = date.getSeconds();

        return Y+M+D+h+m+s;

    }
      // ---------------------
      // 作者：calmlc
      // 来源：CSDN
      // 原文：https://blog.csdn.net/Lc_style/article/details/80626748
      // 版权声明：本文为博主原创文章，转载请附上博文链接！


};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
