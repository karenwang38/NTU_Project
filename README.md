# NTU_Project
## 智能合約Solidity
    目的：讓使用者查詢各停車場的空位、價格及預訂功能。
### 各參數內容/函式功能
    Parameter：
        struct ParkInfo : 停車場訊息，包含空位數、總數、停車格狀態、預約ID、價格、押金、車廠管理員、車廠地址（收ＥＴＨ）等。
        struct ReserveInfo : 預約訊息，包含停車場ID、停車格ID、預約停車起始時間、預約狀態、何時預約、使用者地址。
    Event：
        event transferEvent : 紀錄eth付款訊息。
    modifier :
        onlyContractOwner : AirParking 合約創始者可執行。
        onlyAdmin : AirParking 管理員可執行。
        onlyParkAdmin (uint _parkId) : 停車場管理員可執行。
    Funciton :
        function UpdetAdmin : 增加/刪除 AirParking 管理員權限。
        function UpdetParkAdmin : 增加/刪除 停車場 管理員權限。
        function ParkRegister : 停車場在AirParking註冊。
        function ChangeParkInfo : 更改停車場訊息。
        function GetParkInfo : 獲取/查詢停車場訊息。
        function UpdateParkEmpty : 更新停車場空位數量。
        function ParkReserve : 預約停車。
        function UpdateReserve : 更新預約狀態。
        function ParkPay : 支付停車費用。
        function getContractBalance : 查詢合約餘額（wei)。
        ＝＝＝＝＝＝＝ 以下為測試函數 ＝＝＝＝＝＝＝＝
        function ChangeReservedTime : 改變預約時間。
        



