Option Explicit

' -----------------------------------------------------------------------------
' Windows Firewall Check
' Output the current status of Windows Firewall to the Dashboard
' -----------------------------------------------------------------------------

Const MODE_ANY = "ANY"
Const MODE_ALL = "ALL"

Const RESULT_PASS = 0
Const RESULT_FAIL = 1
Const RESULT_UNKNOWN = 3

Const WindowsFirewallUnknownMessage = "Windows Firewall: Unable to determine status"
Const ThirdPartyFirewallUnknownMessage = "Third Party Firewalls: Unable to determine status"
Const UnknownResultSummary = "Unable to determine firewall status"

Dim WindowsFirewallMessage
WindowsFirewallMessage = WindowsFirewallUnknownMessage

Dim WindowsFirewallSuccess
WindowsFirewallSuccess = False

Dim ThirdPartyFirewallMessage 
ThirdPartyFirewallMessage = ThirdPartyFirewallUnknownMessage

Dim ResultSummary
ResultSummary = UnknownResultSummary

Dim ThirdpartyFirewallStatus
ThirdpartyFirewallStatus = Array()

Dim SummaryConstructSuccessful
SummaryConstructSuccessful = False

'Default value incase error prevents Result being set 
'Which causes a value of 0 to be returned as the result which equates to a pass
Dim Result
Result = RESULT_UNKNOWN
Dim Mode
Dim Products

Dim EnabledProductsCount
EnabledProductsCount = 0

Dim ProductCount
ProductCount = 1 'set to 1 as Windows firewall should be present

Dim XPProductCount
XPProductCount = 0

Dim Win7ProductCount
Win7ProductCount = 0

On Error Resume Next
SetMode()
CheckWindowsFirewall()
CheckFirewalls()
SetResult()
ConstructSummary()
PrintSummary()
Wscript.Quit(Result)

Function SetMode()
	Mode = MODE_ALL
	If WScript.Arguments.Count > 0 Then 
		If UCase(WScript.Arguments(0)) = "ANY" Then
			Mode = MODE_ANY
		End If
	End If
End Function

Function CheckWindowsFirewall()
	Dim WindowsFirewall
	Set WindowsFirewall = WScript.CreateObject( "HNetCfg.FwMgr" )
	If WindowsFirewall.LocalPolicy.CurrentProfile.FirewallEnabled = True Then
		EnabledProductsCount = EnabledProductsCount + 1
		WindowsFirewallMessage =  "Windows Firewall: enabled"
	Else 
		WindowsFirewallMessage =  "Windows Firewall: disabled"
	End If
	'No errors, so this has been successful
	WindowsFirewallSuccess = True	
End Function

Function CheckFirewalls() 
	On Error Resume Next
	CheckFirewallsXP()
	CheckFirewallsWin7()
End Function

Function CheckFirewallsXP()
	Dim WMI
	Set WMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\SecurityCenter")
	Set Products = WMI.ExecQuery("Select * from FirewallProduct")
	
	If Products.Count > 0 Then
		Dim Product
		For Each Product In Products
			XPProductCount = XPProductCount + 1
			Dim Status
			Status = Status & Product.displayName
			
			If Product.enabled Then
				Status = Status & ": enabled"
				EnabledProductsCount = EnabledProductsCount + 1
			Else 
				Status = Status & ": disabled"
			End If
			'Extend array and add element
			ReDim Preserve ThirdpartyFirewallStatus(UBound(ThirdpartyFirewallStatus) + 1)
			ThirdpartyFirewallStatus(UBound(ThirdpartyFirewallStatus)) = Status
		Next	
	End If
	ProductCount = ProductCount + XPProductCount
End Function

Function CheckFirewallsWin7()
	Dim WMI
	Set WMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\SecurityCenter2")
	Set Products = WMI.ExecQuery("Select * from FirewallProduct")
	If Products.Count > 0 Then
		Dim Product
		For Each Product In Products
			Win7ProductCount = Win7ProductCount + 1
			Dim Status
			Status = Status & Product.displayName
			Dim ProductState
			ProductState = Hex(Product.productState)
			
			If Mid(ProductState, 2, 1) = 1 Then
				Status = Status & ": enabled"
				EnabledProductsCount = EnabledProductsCount + 1
			Else 
				Status = Status & ": disabled"
			End If
			'Extend array and add element
			ReDim Preserve ThirdpartyFirewallStatus (UBound(ThirdpartyFirewallStatus) + 1)
			ThirdpartyFirewallStatus(UBound(ThirdpartyFirewallStatus)) = Status
		Next	
	End If
	ProductCount = ProductCount + Win7ProductCount	
End Function

Function SetResult()
	If Mode = MODE_ALL  Then
		If EnabledProductsCount = ProductCount Then
			Result = RESULT_PASS
		Else
			Result = RESULT_FAIL
		End If
	Else
		If EnabledProductsCount > 0 Then
			Result = RESULT_PASS
		Else
			Result = RESULT_FAIL
		End If
	End If
End Function

Function ConstructSummary()
	If WindowsFirewallSuccess = False Or Result = RESULT_UNKNOWN Then
		WindowsFirewallMessage = "Windows Firewall: Unable to determine status"
	End If
	
	If Result <> RESULT_UNKNOWN And ProductCount = 1  Then
		ThirdPartyFirewallMessage = "Third Party Firewalls: No Third Party Firewalls Found"
	ElseIf Result <> RESULT_UNKNOWN And UBound(ThirdpartyFirewallStatus) >= 0 Then
		ThirdPartyFirewallMessage = ""
		 Dim ThirdPartyStatus
		 Dim NewLine 
		 NewLine = ""
		 For Each ThirdPartyStatus In ThirdpartyFirewallStatus 
		 ThirdPartyFirewallMessage = ThirdPartyFirewallMessage & NewLine & ThirdPartyStatus
		 NewLine = vbNewLine
		 Next
	End If

	If Result = RESULT_PASS Then
		If Mode = MODE_ANY Then
			ResultSummary = "At least one firewall is enabled"
		Else 
			ResultSummary = "All firewalls enabled"
		End If
	ElseIf Result = RESULT_FAIL Then
		If Mode = MODE_ANY Then
			ResultSummary = "All firewalls are disabled"
		Else
			ResultSummary = "At least one firewall is disabled"
		End If
	Else 
		ResultSummary = UnknownResultSummary
	End If
	
	SummaryConstructSuccessful = true
End Function

Function PrintSummary() 
	
	If SummaryConstructSuccessful <> true Then
		WindowsFirewallMessage = WindowsFirewallUnknownMessage
		ThirdPartyFirewallMessage = ThirdPartyFirewallUnknownMessage
		ResultSummary = UnknownResultSummary
		Result = RESULT_UNKNOWN
	End If
	
	Wscript.Echo WindowsFirewallMessage
	Wscript.Echo ""
	Wscript.Echo ThirdPartyFirewallMessage
	Wscript.Echo ""
	Wscript.Echo ResultSummary
	
End Function