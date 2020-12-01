Option Explicit

' -----------------------------------------------------------------------------
' AntiVirus Installed Check
' Output the current status of security centre av check to the Dashboard
' -----------------------------------------------------------------------------

' -----------------------------------------------------------------------------
' $Rev: 66053 $
' $LastChangedDate
' -----------------------------------------------------------------------------

Const MODE_ANY = "ANY"
Const MODE_ALL = "ALL"

Const RESULT_PASS = 0
Const RESULT_FAIL = 1
Const RESULT_NOT_FOUND = 2
Const RESULT_UNKNOWN = 3

Dim Result
Dim Mode
Dim Products
Dim UpToDateProductsCount

SetMode()
CheckInstalledAVProducts()
PrintSummary()
WScript.Quit(Result)

Function SetMode()
	Mode = MODE_ALL
	If WScript.Arguments.Count > 0 Then 
		If UCase(WScript.Arguments(0)) = "ANY" Then
			Mode = MODE_ANY
		End If
	End If
End Function

Function CheckInstalledAVProducts()
	CheckInstalledAVProductWin7()
	If Result = RESULT_UNKNOWN Then
		CheckInstalledAVProductXP()
	End If
End Function

Function CheckInstalledAVProductXP()
	On Error Resume Next
	Dim WMI
	Set WMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\SecurityCenter")
	If Err.Number <> 0 Then
		Result = RESULT_UNKNOWN
		Err.Clear
		Exit Function
	End If
	
	Set Products = WMI.ExecQuery("Select * from AntiVirusProduct")
	If Products.Count > 0 Then
		ProcessProductsXP()
		SetResult()
	Else 
		Result = RESULT_NOT_FOUND
	End If
End Function

Function CheckInstalledAVProductWin7()
	On Error Resume Next
	Dim WMI
	Set WMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\SecurityCenter2")
	If Err.Number <> 0 Then
		Result = RESULT_UNKNOWN
		Err.Clear
		Exit Function
	End If
	
	Set Products = WMI.ExecQuery("Select * from AntiVirusProduct")
	If Products.Count > 0 Then
		ProcessProductsWin7()
		SetResult()
	Else 
		Result = RESULT_NOT_FOUND
	End If
End Function

Function ProcessProductsXP() 
	UpToDateProductsCount = 0
	Dim Product
	For Each Product In Products
		Dim Status
		Status = Product.displayName & ": "
		
		If Product.onAccessScanningEnabled = True Then
			Status = Status & "Enabled, "
		Else 
			Status = Status & "Disabled, "
		End If
		
		If Product.productUptoDate = True Then
			Status = Status & "up-to-date"
		Else
			Status = Status & "out-of-date"
		End If
		
		WScript.Echo Status
		
		If Product.onAccessScanningEnabled = True And Product.productUptoDate = True Then
			UpToDateProductsCount = UpToDateProductsCount + 1
		End If
	Next
End Function

Function ProcessProductsWin7() 
	UpToDateProductsCount = 0
	Dim Product
	For Each Product In Products
		Dim Status
		Status = Product.displayName & ": "
		
		Dim ProductState
		ProductState = Hex(Product.productState)
		
		If Mid(ProductState, 2, 1) = 1 Then
			Status = Status & "Enabled, "
		Else 
			Status = Status & "Disabled, "
		End If
		
		If Mid(ProductState, 4, 1) = 0 Then
			Status = Status & "up-to-date"
		Else
			Status = Status & "out-of-date"
		End If
		
		WScript.Echo Status
		
		If Mid(ProductState, 4, 1) = 0 And Mid(ProductState, 2, 1) = 1 Then
			UpToDateProductsCount = UpToDateProductsCount + 1
		End If
	Next
End Function

Function SetResult()
	If Mode = MODE_ALL Then
		If UpToDateProductsCount = Products.Count Then 
			Result = RESULT_PASS
		Else
			Result = RESULT_FAIL
		End If
	Else 
		If UpToDateProductsCount > 0 Then 
			Result = RESULT_PASS
		Else
			Result = RESULT_FAIL
		End If
	End If
End Function

Function PrintSummary()
	WScript.Echo ""
	If Result = RESULT_PASS Then
		If Mode = MODE_ANY Then 
			WScript.Echo "At least one Anti-Virus product is installed, enabled and up-to-date"
		Else
			WScript.Echo "All installed Anti-Virus products are enabled and up-to-date"
		End If
	End If	
	If Result = RESULT_NOT_FOUND Then
		WScript.Echo "No Anti-Virus products installed"
	End If
	If Result = RESULT_FAIL Then
		If Mode = MODE_ANY Then 
			WScript.Echo "No installed Anti-Virus products enabled and up-to-date"
		Else
			WScript.Echo "Not all installed Anti-Virus products are enabled and up-to-date"
		End If
	End If
	If Result = RESULT_UNKNOWN Then
		WScript.Echo "Unable to determine Anti-Virus presence and state"
	End If
End Function
