Add-Type -AssemblyName System.Windows.Forms

function Validate-IPAddress { 		#Method to validate whether the IP address is in the correct subnet according to the Gateway
    param(
        [string]$IPAddress,
        [string]$SubnetMask,
        [string]$Gateway
    )

    $ip = $IPAddress -as [System.Net.IPAddress]
    $subnet = $SubnetMask -as [System.Net.IPAddress]
    $gatewayIP = $Gateway -as [System.Net.IPAddress]

    if (-not $ip -or -not $subnet -or -not $gatewayIP) {
        return $false
    }

    $subnetMaskBits = $subnet.GetAddressBytes() | ForEach-Object { [System.Convert]::ToString($_, 2).PadLeft(8, '0') }
    $subnetCIDR = ($subnetMaskBits -join '').Replace('0', '').Length

    $network = $ip.GetAddressBytes() | ForEach-Object { [System.Convert]::ToString($_, 2).PadLeft(8, '0') }
    $network = ($network -join '').Substring(0, $subnetCIDR)

    $gatewayNetwork = $gatewayIP.GetAddressBytes() | ForEach-Object { [System.Convert]::ToString($_, 2).PadLeft(8, '0') }
    $gatewayNetwork = ($gatewayNetwork -join '').Substring(0, $subnetCIDR)

    return $network -eq $gatewayNetwork
}

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "VoIP Config Utility"
$mainForm.Size = New-Object System.Drawing.Size(300, 200)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "Sizable"
$mainForm.MinimizeBox = $true

$button1 = New-Object System.Windows.Forms.Button
$button1.Location = New-Object System.Drawing.Point(50, 50)
$button1.Size = New-Object System.Drawing.Size(200, 30)
$button1.Text = "List Adapters"
$button1.Add_Click({
    $adapterListForm = New-Object System.Windows.Forms.Form
    $adapterListForm.Text = "Adapter List"
    $adapterListForm.Size = New-Object System.Drawing.Size(330, 400)
    $adapterListForm.StartPosition = "CenterScreen"

    $adapters = Get-NetAdapter | Select-Object InterfaceIndex, Name
    $y = 50
    foreach ($adapter in $adapters) {
        $radioButton = New-Object System.Windows.Forms.RadioButton
        $radioButton.Text = $adapter.Name
        $radioButton.Location = New-Object System.Drawing.Point(50, $y)
        $radioButton.Size = New-Object System.Drawing.Size(200, 20)
        $radioButton.Name = "RadioButton_" + $adapter.InterfaceIndex
		$radioButton.Add_Click({
            foreach ($control in $adapterListForm.Controls) {
                if ($control -is [System.Windows.Forms.TextBox]) {
                    $control.Visible = $false
                }
            }
            $ipLabel.Visible = $true
            $ipTextBox.Visible = $true
			$subnetLabel.Visible = $true
            $subnetTextBox.Visible = $true
			$gatewayLabel.Visible = $true
            $gatewayTextBox.Visible = $true
        })
        $adapterListForm.Controls.Add($radioButton)
        $y += 20
    }
	
    $ipLabel = New-Object System.Windows.Forms.Label
    $ipLabel.Text = "IP Address:"
    $ipLabel.Location = New-Object System.Drawing.Point(50, ($y + 20))
	$ipLabel.Visible = $false
    $adapterListForm.Controls.Add($ipLabel)

    $ipTextBox = New-Object System.Windows.Forms.TextBox
    $ipTextBox.Location = New-Object System.Drawing.Point(150, ($y + 20))
    $ipTextBox.Size = New-Object System.Drawing.Size(120, 20)
    $ipTextBox.Visible = $false
    $adapterListForm.Controls.Add($ipTextBox)

    $subnetLabel = New-Object System.Windows.Forms.Label
    $subnetLabel.Text = "Subnet Mask:"
    $subnetLabel.Location = New-Object System.Drawing.Point(50, ($y + 50))
    $subnetLabel.Visible = $false
    $adapterListForm.Controls.Add($subnetLabel)

    $subnetTextBox = New-Object System.Windows.Forms.TextBox
    $subnetTextBox.Location = New-Object System.Drawing.Point(150, ($y + 50))
    $subnetTextBox.Size = New-Object System.Drawing.Size(120, 20)
    $subnetTextBox.Visible = $false
    $adapterListForm.Controls.Add($subnetTextBox)

    $gatewayLabel = New-Object System.Windows.Forms.Label
    $gatewayLabel.Text = "Default Gateway:"
    $gatewayLabel.Location = New-Object System.Drawing.Point(50, ($y + 80))
    $gatewayLabel.Visible = $false
    $adapterListForm.Controls.Add($gatewayLabel)

    $gatewayTextBox = New-Object System.Windows.Forms.TextBox
    $gatewayTextBox.Location = New-Object System.Drawing.Point(150, ($y + 80))
    $gatewayTextBox.Size = New-Object System.Drawing.Size(120, 20)
    $gatewayTextBox.Visible = $false
    $adapterListForm.Controls.Add($gatewayTextBox)
	
    $setButton = New-Object System.Windows.Forms.Button
    $setButton.Location = New-Object System.Drawing.Point(50, ($y + 120))
    $setButton.Size = New-Object System.Drawing.Size(100, 30)
    $setButton.Text = "Set"
    $setButton.Add_Click({
		$selectedRadioButton = $adapterListForm.Controls | Where-Object { $_.GetType().Name -eq "RadioButton" -and $_.Checked }
        if ($selectedRadioButton -eq $null) {
            [System.Windows.Forms.MessageBox]::Show("Please select an interface first.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        } else {
			
            $selectedIndex = $selectedRadioButton.Name.Split('_')[1]

        if ([string]::IsNullOrEmpty($ipTextBox.Text) -or [string]::IsNullOrEmpty($subnetTextBox.Text) -or [string]::IsNullOrEmpty($gatewayTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Please fill in all fields.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        $ipAddress = $ipTextBox.Text
        $subnetMask = $subnetTextBox.Text
        $gateway = $gatewayTextBox.Text

        # Check if the IP address, subnet mask, and gateway are valid
        if (-not ($ipAddress -as [System.Net.IPAddress]) -or
            -not ($subnetMask -as [System.Net.IPAddress]) -or
            -not ($gateway -as [System.Net.IPAddress])) {
            [System.Windows.Forms.MessageBox]::Show("Please enter valid IP addresses.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
		
				        # Check if the IP address, subnet mask, and gateway are valid
        if (-not (Validate-IPAddress -IPAddress $ipAddress -SubnetMask $subnetMask -Gateway $gateway)) {
            [System.Windows.Forms.MessageBox]::Show("The IP address is not valid for the subnet and gateway.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
			
		$ipAddress = $ipTextBox.Text # Change this to your desired IP address
		$subnetMask = $subnetTextBox.Text # Change this to your subnet mask
		$gateway = $gatewayTextBox.Text # Change this to your gateway IP		
		
		# Get the network adapter configuration
		$adapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $selectedIndex }
		
		# Set the IP address, subnet mask, and gateway
		$adapter.EnableStatic($ipAddress, $subnetMask)
		$adapter.SetGateways($gateway, 1)
		[System.Windows.Forms.MessageBox]::Show("VoIP Config is set.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
		Write-Host "VoIP config set on $selectedIndex"}
		})
		$adapterListForm.Controls.Add($setButton)
	
		$revertButton = New-Object System.Windows.Forms.Button
		$revertButton.Location = New-Object System.Drawing.Point(170, ($y + 120))
		$revertButton.Size = New-Object System.Drawing.Size(100, 30)
		$revertButton.Text = "Revert"
		$revertButton.Add_Click({
        $selectedRadioButton = $adapterListForm.Controls | Where-Object { $_.GetType().Name -eq "RadioButton" -and $_.Checked }
        if ($selectedRadioButton -eq $null) {
            [System.Windows.Forms.MessageBox]::Show("Please select an interface first.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        } else {
            $selectedIndex = $selectedRadioButton.Name.Split('_')[1]
			
			$adapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $selectedIndex }
			
		if ([string]::IsNullOrEmpty($gatewayTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Default gateway can't be empty", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
		
		$gateway = $gatewayTextBox.Text

		if (-not ($gateway -as [System.Net.IPAddress])) {
            [System.Windows.Forms.MessageBox]::Show("Please enter valid a gateway.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
		
		$matchingRoute = Get-NetRoute -InterfaceIndex $selectedIndex -NextHop $gateway -ErrorAction SilentlyContinue

		if ($matchingRoute -eq $null) {
			[System.Windows.Forms.MessageBox]::Show("No matching route found for the specified gateway.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
			return
		}
        #$matchingConfig = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { 
        #    $_.InterfaceIndex -eq $selectedIndex -and
        #    $_.DefaultIPGateway -contains $gateway
        #}
		#
        #if ($matchingConfig -eq $null) {
        #    [System.Windows.Forms.MessageBox]::Show("No matching configuration found for the specified gateway.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        #    return
        #}
		

		Set-NetIPInterface -InterfaceIndex $selectedIndex -Dhcp Enabled
		Restart-NetAdapter -InterfaceDescription $adapter.Description -Confirm:$false
		Remove-NetRoute -NextHop $gateway -InterfaceIndex $selectedIndex -Confirm:$false
		
		    $ipLabel.Visible = $false
            $ipTextBox.Visible = $false
			$subnetLabel.Visible = $false
            $subnetTextBox.Visible = $false
			$gatewayLabel.Visible = $false
            $gatewayTextBox.Visible = $false
		foreach ($control in $adapterListForm.Controls) {
            if ($control -is [System.Windows.Forms.RadioButton]) {
                $control.Checked = $false
            }
        }
		[System.Windows.Forms.MessageBox]::Show("VoIP Config has been reverted.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        Write-Host "VoIP config removed from $selectedIndex" }
    })
    $adapterListForm.Controls.Add($revertButton)
	
	    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(50, 275)
    $closeButton.Size = New-Object System.Drawing.Size(220, 30)
    $closeButton.Text = "Close"
    $closeButton.Add_Click({
        $adapterListForm.Close()
    })
    $adapterListForm.Controls.Add($closeButton)

    $adapterListForm.ShowDialog()
})
$mainForm.Controls.Add($button1)

$button2 = New-Object System.Windows.Forms.Button
$button2.Location = New-Object System.Drawing.Point(50, 100)
$button2.Size = New-Object System.Drawing.Size(200, 30)
$button2.Text = "Close"
$button2.Add_Click({
    $mainForm.Close()
})
$mainForm.Controls.Add($button2)

$mainForm.add_Resize({
    $button1.Location = New-Object System.Drawing.Point(50, 50)
    $button2.Location = New-Object System.Drawing.Point(50, 100)
})

$mainForm.ShowDialog()


