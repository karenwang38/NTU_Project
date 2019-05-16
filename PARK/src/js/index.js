var header = new Vue({
	el: '#header',
	data: {
		message: 'AirParking'
	}

})

var purchase_coin = new Vue({
	el: '#purchasecoin',
	data: {
    	message: '1 AirCoin = 50 NTD'
  	},
  	// 在 `methods` 对象中定义方法
  	methods: {
    	purchase: function (event) {
      	// `this` 在方法里指向当前 Vue 实例
      	alert('You have purchase 5 AirCoin !')
    	}
  	}
})

var start_booking = new Vue({
	el: '#startbooking',
  	// 在 `methods` 对象中定义方法
  	methods: {
    	booking: function (event) {
      	// `this` 在方法里指向当前 Vue 实例
      	alert('Success !')
    	}
  	}
})
