#Carbon IIS Setup


function Join-CIisVirtualPath {
    <#
    .SYNOPSIS
    Combines a path and a child path for an IIS website, application, virtual directory into a single path.  

    .DESCRIPTION
    Removes extra slashes.  Converts backward slashes to forward slashes.  Relative portions are not removed.  Sorry.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Join-CIisVirtualPath 'SiteName' 'Virtual/Path'

    Demonstrates how to join two IIS paths together.  REturns `SiteName/Virtual/Path`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        # The parent path.
        $Path,

        [Parameter(Position = 1)]
        [string]
        $ChildPath
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ( $ChildPath ) {
        $Path = Join-Path -Path $Path -ChildPath $ChildPath
    }
    $Path.Replace('\', '/').Trim('/')
}


function Write-IisVerbose {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        # The name of the site.
        $SiteName,

        [string]
        $VirtualPath = '',

        [Parameter(Position = 1)]
        [string]
        # The name of the setting.
        $Name,

        [Parameter(Position = 2)]
        [string]
        $OldValue = '',

        [Parameter(Position = 3)]
        [string]
        $NewValue = ''
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ( $VirtualPath ) {
        $SiteName = Join-CIisVirtualPath -Path $SiteName -ChildPath $VirtualPath
    }

    Write-Verbose -Message ('[IIS Website] [{0}] {1,-34} {2} -> {3}' -f $SiteName, $Name, $OldValue, $NewValue)
}


function Unlock-CIisConfigurationSection {
    <#
    .SYNOPSIS
    Unlocks a section in the IIS server configuration.

    .DESCRIPTION
    Some sections/areas are locked by IIS, so that websites can't enable those settings, or have their own custom configurations.  This function will unlocks those locked sections.  You have to know the path to the section.  You can see a list of locked sections by running:

        C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Unlock-IisConfigSection -Name 'system.webServer/cgi'

    Unlocks the CGI section so that websites can configure their own CGI settings.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]
        # The path to the section to unlock.  For a list of sections, run
        #
        #     C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?
        $SectionPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $SectionPath |
    ForEach-Object {
        $section = Get-CIisConfigurationSection -SectionPath $_
        $section.OverrideMode = 'Allow'
        if ( $pscmdlet.ShouldProcess( $_, 'unlocking IIS configuration section' ) ) {
            $section.CommitChanges()
        }
    }
}


function Uninstall-CIisWebsite {
    <#
    .SYNOPSIS
    Removes a website

    .DESCRIPTION
    Pretty simple: removes the website named `Name`.  If no website with that name exists, nothing happens.

    Beginning with Carbon 2.0.1, this function is not available if IIS isn't installed.

    .LINK
    Get-CIisWebsite
    
    .LINK
    Install-CIisWebsite
    
    .EXAMPLE
    Uninstall-CIisWebsite -Name 'MyWebsite'
    
    Removes MyWebsite.

    .EXAMPLE
    Uninstall-CIisWebsite 1

    Removes the website whose ID is 1.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        # The name or ID of the website to remove.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if ( Test-CIisWebsite -Name $Name ) {
        $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
        try {
            $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
            $manager.Sites.Remove( $site )
            $manager.CommitChanges()
        }
        finally {
            $manager.Dispose()
        }
    }
}

Set-Alias -Name 'Remove-IisWebsite' -Value 'Uninstall-CIisWebsite'



function Test-CIisWebsite {
    <#
    .SYNOPSIS
    Tests if a website exists.

    .DESCRIPTION
    Returns `True` if a website with name `Name` exists.  `False` if it doesn't.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Test-CIisWebsite -Name 'Peanuts'

    Returns `True` if the `Peanuts` website exists.  `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The name of the website whose existence to check.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
    try {
        $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
        if ( $site ) {
            return $true
        }
        return $false
    }
    finally {
        $manager.Dispose()
    }
}

Set-Alias -Name Test-IisWebsiteExists -Value Test-CIisWebsite



function Test-CIisAppPool {
    <# 
    .SYNOPSIS
    Checks if an app pool exists.

    .DESCRIPTION 
    Returns `True` if an app pool with `Name` exists.  `False` if it doesn't exist.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Test-CIisAppPool -Name Peanuts

    Returns `True` if the Peanuts app pool exists, `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The name of the app pool.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $Name
    if ( $appPool ) {
        return $true
    }
    
    return $false
}

Set-Alias -Name 'Test-IisAppPoolExists' -Value 'Test-CIisAppPool'

function Set-CIisWindowsAuthentication {
    <#
    .SYNOPSIS
    Configures the settings for Windows authentication.

    .DESCRIPTION
    By default, configures Windows authentication on a website.  You can configure Windows authentication at a specific path under a website by passing the virtual path (*not* the physical path) to that directory.
    
    The changes only take effect if Windows authentication is enabled (see `Enable-CIisSecurityAuthentication`).

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx
    
    .LINK
    Disable-CIisSecurityAuthentication
    
    .LINK
    Enable-CIisSecurityAuthentication

    .EXAMPLE
    Set-CIisWindowsAuthentication -SiteName Peanuts

    Configures Windows authentication on the `Peanuts` site to use kernel mode.

    .EXAMPLE
    Set-CIisWindowsAuthentication -SiteName Peanuts -VirtualPath Snoopy/DogHouse -DisableKernelMode

    Configures Windows authentication on the `Doghouse` directory of the `Peanuts` site to not use kernel mode.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The site where Windows authentication should be set.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path where Windows authentication should be set.
        $VirtualPath = '',
        
        [Switch]
        # Turn on kernel mode.  Default is false.  [More information about Kerndel Mode authentication.](http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx)
        $DisableKernelMode
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $useKernelMode = 'True'
    if ( $DisableKernelMode ) {
        $useKernelMode = 'False'
    }
    
    $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath -Windows
    $authSettings.SetAttributeValue( 'useKernelMode', $useKernelMode )

    $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath
    if ( $pscmdlet.ShouldProcess( $fullPath, "set Windows authentication" ) ) {
        $authSettings.CommitChanges()
    }
}



function Install-CIisWebsite {
    <# 
    .SYNOPSIS
    Installs a website.

    .DESCRIPTION
    `Install-CIisWebsite` installs an IIS website. Anonymous authentication is enabled, and the anonymous user is set to the website's application pool identity. Before Carbon 2.0, if a website already existed, it was deleted and re-created. Beginning with Carbon 2.0, existing websites are modified in place. 
    
    If you don't set the website's app pool, IIS will pick one for you (usually `DefaultAppPool`), and `Install-CIisWebsite` will never manage the app pool for you (i.e. if someone changes it manually, this function won't set it back to the default). We recommend always supplying an app pool name, even if it is `DefaultAppPool`.

    By default, the site listens on (i.e. is bound to) all IP addresses on port 80 (binding `http/*:80:`). Set custom bindings with the `Bindings` argument. Multiple bindings are allowed. Each binding must be in this format (in BNF):

        <PROTOCOL> '/' <IP_ADDRESS> ':' <PORT> ':' [ <HOSTNAME> ]

     * `PROTOCOL` is one of `http` or `https`.
     * `IP_ADDRESS` is a literal IP address, or `*` for all of the computer's IP addresses.  This function does not validate if `IPADDRESS` is actually in use on the computer.
     * `PORT` is the port to listen on.
     * `HOSTNAME` is the website's hostname, for name-based hosting.  If no hostname is being used, leave off the `HOSTNAME` part.

    Valid bindings are:

     * http/*:80:
     * https/10.2.3.4:443:
     * http/*:80:example.com

     ## Troubleshooting

     In some situations, when you add a website to an application pool that another website/application is part of, the new website will fail to load in a browser with a 500 error saying `Failed to map the path '/'.`. We've been unable to track down the root cause. The solution is to recycle the app pool, e.g. `(Get-CIisAppPool -Name 'AppPoolName').Recycle()`.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Get-CIisWebsite
    
    .LINK
    Uninstall-CIisWebsite

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com

    Creates a website named `Peanuts` serving files out of the `C:\Peanuts.com` directory.  The website listens on all the computer's IP addresses on port 80.

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com -Binding 'http/*:80:peanuts.com'

    Creates a website named `Peanuts` which uses name-based hosting to respond to all requests to any of the machine's IP addresses for the `peanuts.com` domain.

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com -AppPoolName 'PeanutsAppPool'

    Creates a website named `Peanuts` that runs under the `PeanutsAppPool` app pool
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        # The name of the website.
        $Name,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [Alias('Path')]
        [string]
        # The physical path (i.e. on the file system) to the website. If it doesn't exist, it will be created for you.
        $PhysicalPath,
        
        [Parameter(Position = 2)]
        [Alias('Bindings')]
        [string[]]
        # The site's network bindings.  Default is `http/*:80:`.  Bindings should be specified in protocol/IPAddress:Port:Hostname format.  
        #
        #  * Protocol should be http or https. 
        #  * IPAddress can be a literal IP address or `*`, which means all of the computer's IP addresses.  This function does not validate if `IPAddress` is actually in use on this computer.
        #  * Leave hostname blank for non-named websites.
        $Binding = @('http/*:80:'),
        
        [string]
        # The name of the app pool under which the website runs.  The app pool must exist.  If not provided, IIS picks one for you.  No whammy, no whammy! It is recommended that you create an app pool for each website. That's what the IIS Manager does.
        $AppPoolName,

        [int]
        # The site's IIS ID. IIS picks one for you automatically if you don't supply one. Must be greater than 0.
        #
        # The `SiteID` switch is new in Carbon 2.0.
        $SiteID,

        [Switch]
        # Return a `Microsoft.Web.Administration.Site` object for the website.
        #
        # The `PassThru` switch is new in Carbon 2.0.
        $PassThru,

        [Switch]
        # Deletes the website before installation, if it exists. Preserves default beheaviro in Carbon before 2.0.
        #
        # The `Force` switch is new in Carbon 2.0.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $bindingRegex = '^(?<Protocol>https?):?//?(?<IPAddress>\*|[\d\.]+):(?<Port>\d+):?(?<HostName>.*)$'

    filter ConvertTo-Binding {
        param(
            [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
            [string]
            $InputObject
        )

        Set-StrictMode -Version 'Latest'

        $InputObject -match $bindingRegex | Out-Null
        [pscustomobject]@{ 
            'Protocol'  = $Matches['Protocol'];
            'IPAddress' = $Matches['IPAddress'];
            'Port'      = $Matches['Port'];
            'HostName'  = $Matches['HostName'];
        } |
        Add-Member -MemberType ScriptProperty -Name 'BindingInformation' -Value { '{0}:{1}:{2}' -f $this.IPAddress, $this.Port, $this.HostName } -PassThru
    }

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath
    if ( -not (Test-Path $PhysicalPath -PathType Container) ) {
        New-Item $PhysicalPath -ItemType Directory | Out-String | Write-Verbose
    }
    
    $invalidBindings = $Binding | 
    Where-Object { $_ -notmatch $bindingRegex } 
    if ( $invalidBindings ) {
        $invalidBindings = $invalidBindings -join "`n`t"
        $errorMsg = "The following bindings are invalid. The correct format is protocol/IPAddress:Port:Hostname. Protocol and IP address must be separted by a single slash, not ://. IP address can be * for all IP addresses. Hostname is optional. If hostname is not provided, the binding must end with a colon.`n`t{0}" -f $invalidBindings
        Write-Error $errorMsg
        return
    }

    if ( $Force ) {
        Uninstall-CIisWebsite -Name $Name
    }

    [Microsoft.Web.Administration.Site]$site = $null
    $modified = $false
    if ( -not (Test-CIisWebsite -Name $Name) ) {
        Write-Verbose -Message ('Creating website ''{0}'' ({1}).' -f $Name, $PhysicalPath)
        $firstBinding = $Binding | Select-Object -First 1 | ConvertTo-Binding
        $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
        $site = $mgr.Sites.Add( $Name, $firstBinding.Protocol, $firstBinding.BindingInformation, $PhysicalPath )
        $mgr.CommitChanges()
    }

    $site = Get-CIisWebsite -Name $Name

    $expectedBindings = New-Object 'Collections.Generic.Hashset[string]'
    $Binding | ConvertTo-Binding | ForEach-Object { [void]$expectedBindings.Add( ('{0}/{1}' -f $_.Protocol, $_.BindingInformation) ) }

    $bindingsToRemove = $site.Bindings | Where-Object { -not $expectedBindings.Contains(  ('{0}/{1}' -f $_.Protocol, $_.BindingInformation ) ) }
    foreach ( $bindingToRemove in $bindingsToRemove ) {
        Write-IisVerbose $Name 'Binding' ('{0}/{1}' -f $bindingToRemove.Protocol, $bindingToRemove.BindingInformation)
        $site.Bindings.Remove( $bindingToRemove )
        $modified = $true
    }

    $existingBindings = New-Object 'Collections.Generic.Hashset[string]'
    $site.Bindings | ForEach-Object { [void]$existingBindings.Add( ('{0}/{1}' -f $_.Protocol, $_.BindingInformation) ) }
    $bindingsToAdd = $Binding | ConvertTo-Binding | Where-Object { -not $existingBindings.Contains(  ('{0}/{1}' -f $_.Protocol, $_.BindingInformation ) ) }
    foreach ( $bindingToAdd in $bindingsToAdd ) {
        Write-IisVerbose $Name 'Binding' '' ('{0}/{1}' -f $bindingToAdd.Protocol, $bindingToAdd.BindingInformation)
        $site.Bindings.Add( $bindingToAdd.BindingInformation, $bindingToAdd.Protocol ) | Out-Null
        $modified = $true
    }
    
    [Microsoft.Web.Administration.Application]$rootApp = $null
    if ( $site.Applications.Count -eq 0 ) {
        $rootApp = $site.Applications.Add("/", $PhysicalPath)
        $modifed = $true
    }
    else {
        $rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
    }

    if ( $site.PhysicalPath -ne $PhysicalPath ) {
        Write-IisVerbose $Name 'PhysicalPath' $site.PhysicalPath $PhysicalPath 
        [Microsoft.Web.Administration.VirtualDirectory]$vdir = $rootApp.VirtualDirectories | Where-Object { $_.Path -eq '/' }
        $vdir.PhysicalPath = $PhysicalPath
        $modified = $true
    }
    
    if ( $AppPoolName ) {
        if ( $rootApp.ApplicationPoolName -ne $AppPoolName ) {
            Write-IisVerbose $Name 'AppPool' $rootApp.ApplicationPoolName $AppPoolName 
            $rootApp.ApplicationPoolName = $AppPoolName
            $modified = $true
        }
    }

    if ( $modified ) {
        $site.CommitChanges()
    }
    
    if ( $SiteID ) {
        Set-CIisWebsiteID -SiteName $Name -ID $SiteID
    }
    
    # Make sure anonymous authentication is enabled and uses the application pool identity
    $security = Get-CIisSecurityAuthentication -SiteName $Name -VirtualPath '/' -Anonymous
    Write-IisVerbose $Name 'Anonymous Authentication UserName' $security['username'] ''
    $security['username'] = ''
    $security.CommitChanges()

    # Now, wait until site is actually running
    $tries = 0
    $website = $null
    do {
        $website = Get-CIisWebsite -SiteName $Name
        $tries += 1
        if ($website.State -ne 'Unknown') {
            break
        }
        else {
            Start-Sleep -Milliseconds 100
        }
    }
    while ( $tries -lt 100 )

    if ( $PassThru ) {
        return $website
    }
}


function Install-CIisVirtualDirectory {
    <#
    .SYNOPSIS
    Installs a virtual directory.

    .DESCRIPTION
    The `Install-CIisVirtualDirectory` function creates a virtual directory under website `SiteName` at `/VirtualPath`, serving files out of `PhysicalPath`.  If a virtual directory at `VirtualPath` already exists, it is updated in palce. (Before Carbon 2.0, the virtual directory was deleted before installation.)

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Install-CIisVirtualDirectory -SiteName 'Peanuts' -VirtualPath 'DogHouse' -PhysicalPath C:\Peanuts\Doghouse

    Creates a /DogHouse virtual directory, which serves files from the C:\Peanuts\Doghouse directory.  If the Peanuts website responds to hostname `peanuts.com`, the virtual directory is accessible at `peanuts.com/DogHouse`.

    .EXAMPLE
    Install-CIisVirtualDirectory -SiteName 'Peanuts' -VirtualPath 'Brown/Snoopy/DogHouse' -PhysicalPath C:\Peanuts\DogHouse

    Creates a DogHouse virtual directory under the `Peanuts` website at `/Brown/Snoopy/DogHouse` serving files out of the `C:\Peanuts\DogHouse` directory.  If the Peanuts website responds to hostname `peanuts.com`, the virtual directory is accessible at `peanuts.com/Brown/Snoopy/DogHouse`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The site where the virtual directory should be created.
        $SiteName,
        
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [string]
        # The name of the virtual directory.  This can contain multiple directory segments for virtual directories not at the root of the website, e.g. First/Second/VirtualDirectory.
        $VirtualPath,
        
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [string]
        # The file system path to the virtual directory.
        $PhysicalPath,

        [Switch]
        # Deletes the virttual directory before installation, if it exists. Preserves default beheaviro in Carbon before 2.0.
        # 
        # *Does not* delete custom configuration for the virtual directory, just the virtual directory. If you've customized the location of the virtual directory, those customizations will remain in place.
        #
        # The `Force` switch is new in Carbon 2.0.
        $Force
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -Name $SiteName
    [Microsoft.Web.Administration.Application]$rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
    if ( -not $rootApp ) {
        Write-Error ('Default website application not found.')
        return
    }

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath

    $VirtualPath = $VirtualPath.Trim('/')
    $VirtualPath = '/{0}' -f $VirtualPath

    $vdir = $rootApp.VirtualDirectories | Where-Object { $_.Path -eq $VirtualPath }
    if ( $Force -and $vdir ) {
        Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'REMOVE' '' ''
        $rootApp.VirtualDirectories.Remove($vdir)
        $site.CommitChanges()
        $vdir = $null

        $site = Get-CIisWebsite -Name $SiteName
        $rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
    }

    $modified = $false

    if ( -not $vdir ) {
        [Microsoft.Web.Administration.ConfigurationElementCollection]$vdirs = $rootApp.GetCollection()
        $vdir = $vdirs.CreateElement('virtualDirectory')
        Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'VirtualPath' '' $VirtualPath
        $vdir['path'] = $VirtualPath
        [void]$vdirs.Add( $vdir )
        $modified = $true
    }

    if ( $vdir['physicalPath'] -ne $PhysicalPath ) {
        Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'PhysicalPath' $vdir['physicalPath'] $PhysicalPath
        $vdir['physicalPath'] = $PhysicalPath
        $modified = $true
    }

    if ( $modified ) {
        $site.CommitChanges()
    }
}


function Install-CIisAppPool {
    <#
    .SYNOPSIS
    Creates a new app pool.
    
    .DESCRIPTION
    By default, creates a 64-bit app pool running as the `ApplicationPoolIdentity` service account under .NET v4.0 with an integrated pipeline.    
    You can control which version of .NET is used to run an app pool with the `ManagedRuntimeVersion` parameter: versions `v1.0`, `v1.1`, `v2.0`, and `v4.0` are supported. Use an empty string if you're running .NET Core or to set the .NET framework version to `No Managed Code`.
    To run an application pool using the classic pipeline mode, set the `ClassicPipelineMode` switch.
    To run an app pool using the 32-bit version of the .NET framework, set the `Enable32BitApps` switch.
    An app pool can run as several built-in service accounts, by passing one of them as the value of the `ServiceAccount` parameter: `NetworkService`, `LocalService`, or `LocalSystem`  The default is `ApplicationPoolIdentity`, which causes IIS to create and use a custom local account with the name of the app pool.  See [Application Pool Identities](http://learn.iis.net/page.aspx/624/application-pool-identities/) for more information.
    To run the app pool as a specific user, pass the credentials with the `Credential` parameter. (In some versions of Carbon, there is no `Credential` parameter, so use the `UserName` and `Password` parameters instead.) The user will be granted the `SeBatchLogonRight` privilege.
    If an existing app pool exists with name `Name`, it's settings are modified.  The app pool isn't deleted.  (You can't delete an app pool if there are any websites using it, that's why.)
    By default, this function will create an application pool running the latest version of .NET, with an integrated pipeline, as the NetworkService account.
    Beginning with Carbon 2.0, the `PassThru` switch will cause this function to return a `Microsoft.Web.Administration.ApplicationPool` object for the created/updated application pool.
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://learn.iis.net/page.aspx/624/application-pool-identities/

    .LINK
    New-CCredential
    
    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne -ServiceAccount NetworkService

    Creates a new Cyberdyne application pool, running as NetworkService, using .NET 4.0 and an integrated pipeline.  If the Cyberdyne app pool already exists, it is modified to run as NetworkService, to use .NET 4.0 and to use an integrated pipeline.

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne -ServiceAccount NetworkService -Enable32BitApps -ClassicPipelineMode

    Creates or sets the Cyberdyne app pool to run as NetworkService, in 32-bit mode (i.e. 32-bit applications are enabled), using the classic IIS request pipeline.

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne -Credential $charlieBrownCredential

    Creates or sets the Cyberdyne app pool to run as the `PEANUTS\charliebrown` domain account, under .NET 4.0, with an integrated pipeline.
    #>
    [CmdletBinding(DefaultParameterSetName = 'AsServiceAccount')]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The app pool's name.
        $Name,
        
        [string]
        [ValidateSet('v1.0', 'v1.1', 'v2.0', 'v4.0', '')]
        # The managed .NET runtime version to use.  Default is 'v4.0'.  Valid values are `v1.0`, `v1.1`, `v2.0`, or `v4.0`. Use an empty string if you're using .NET Core or to set the .NET framework version to `No Managed Code`.
        $ManagedRuntimeVersion = 'v4.0',
        
        [int]
        [ValidateScript( { $_ -gt 0 })]
        #Idle Timeout value in minutes. Default is 0.
        $IdleTimeout = 0,
        
        [Switch]
        # Use the classic pipeline mode, i.e. don't use an integrated pipeline.
        $ClassicPipelineMode,
        
        [Switch]
        # Enable 32-bit applications.
        $Enable32BitApps,
        
        [string]
        [ValidateSet('NetworkService', 'LocalService', 'LocalSystem')]
        # Run the app pool under the given local service account.  Valid values are `NetworkService`, `LocalService`, and `LocalSystem`.  The default is `ApplicationPoolIdentity`, which causes IIS to create a custom local user account for the app pool's identity.  The default is `ApplicationPoolIdentity`.
        $ServiceAccount,
        
        [Parameter(ParameterSetName = 'AsSpecificUser', Mandatory = $true, DontShow = $true)]
        [string]
        # OBSOLETE. The `UserName` parameter will be removed in a future major version of Carbon. Use the `Credential` parameter instead.
        $UserName,
        
        [Parameter(ParameterSetName = 'AsSpecificUser', Mandatory = $true, DontShow = $true)]
        # OBSOLETE. The `Password` parameter will be removed in a future major version of Carbon. Use the `Credential` parameter instead.
        $Password,

        [Parameter(ParameterSetName = 'AsSpecificUserWithCredential', Mandatory = $true)]
        [pscredential]
        # The credential to use to run the app pool.
        #
        # The `Credential` parameter is new in Carbon 2.0.
        $Credential,

        [Switch]
        # Return an object representing the app pool.
        $PassThru
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if ( $PSCmdlet.ParameterSetName -like 'AsSpecificUser*' ) {
        if ( $PSCmdlet.ParameterSetName -notlike '*WithCredential' ) {
            Write-Warning ('`Install-CIisAppPool` function''s `UserName` and `Password` parameters are obsolete and will be removed in a future major version of Carbon. Please use the `Credential` parameter instead.')
            $Credential = New-CCredential -UserName $UserName -Password $Password
        }
    }

    if ( $PSCmdlet.ParameterSetName -eq 'AsSpecificUser' -and -not (Test-CIdentity -Name $Credential.UserName) ) {
        Write-Error ('Identity {0} not found. {0} IIS websites and applications assigned to this app pool won''t run.' -f $Credential.UserName, $Name)
    }
    
    if ( -not (Test-CIisAppPool -Name $Name) ) {
        Write-Verbose ('Creating IIS Application Pool {0}' -f $Name)
        $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
        $appPool = $mgr.ApplicationPools.Add($Name)
        $mgr.CommitChanges()
    }

    $appPool = Get-CIisAppPool -Name $Name
    
    $updated = $false

    if ( $appPool.ManagedRuntimeVersion -ne $ManagedRuntimeVersion ) {
        Write-Verbose ('IIS Application Pool {0}: Setting ManagedRuntimeVersion = {0}' -f $Name, $ManagedRuntimeVersion)
        $appPool.ManagedRuntimeVersion = $ManagedRuntimeVersion
        $updated = $true
    }

    $pipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Integrated
    if ( $ClassicPipelineMode ) {
        $pipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Classic
    }
    if ( $appPool.ManagedPipelineMode -ne $pipelineMode ) {
        Write-Verbose ('IIS Application Pool {0}: Setting ManagedPipelineMode = {0}' -f $Name, $pipelineMode)
        $appPool.ManagedPipelineMode = $pipelineMode
        $updated = $true
    }

    $idleTimeoutTimeSpan = New-TimeSpan -Minutes $IdleTimeout
    if ( $appPool.ProcessModel.IdleTimeout -ne $idleTimeoutTimeSpan ) {
        Write-Verbose ('IIS Application Pool {0}: Setting idle timeout = {0}' -f $Name, $idleTimeoutTimeSpan)
        $appPool.ProcessModel.IdleTimeout = $idleTimeoutTimeSpan 
        $updated = $true
    }

    if ( $appPool.Enable32BitAppOnWin64 -ne ([bool]$Enable32BitApps) ) {
        Write-Verbose ('IIS Application Pool {0}: Setting Enable32BitAppOnWin64 = {0}' -f $Name, $Enable32BitApps)
        $appPool.Enable32BitAppOnWin64 = $Enable32BitApps
        $updated = $true
    }
    
    if ( $PSCmdlet.ParameterSetName -like 'AsSpecificUser*' ) {
        if ( $appPool.ProcessModel.UserName -ne $Credential.UserName ) {
            Write-Verbose ('IIS Application Pool {0}: Setting username = {0}' -f $Name, $Credential.UserName)
            $appPool.ProcessModel.IdentityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::SpecificUser
            $appPool.ProcessModel.UserName = $Credential.UserName
            $appPool.ProcessModel.Password = $Credential.GetNetworkCredential().Password

            # On Windows Server 2008 R2, custom app pool users need this privilege.
            Grant-CPrivilege -Identity $Credential.UserName -Privilege SeBatchLogonRight -Verbose:$VerbosePreference
            $updated = $true
        }
    }
    else {
        $identityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::ApplicationPoolIdentity
        if ( $ServiceAccount ) {
            $identityType = $ServiceAccount
        }

        if ( $appPool.ProcessModel.IdentityType -ne $identityType ) {
            Write-Verbose ('IIS Application Pool {0}: Setting IdentityType = {0}' -f $Name, $identityType)
            $appPool.ProcessModel.IdentityType = $identityType
            $updated = $true
        }
    }

    if ( $updated ) {
        $appPool.CommitChanges()
    }
    
    # TODO: Pull this out into its own Start-IisAppPool function.  I think.
    $appPool = Get-CIisAppPool -Name $Name
    if ($appPool -and $appPool.state -eq [Microsoft.Web.Administration.ObjectState]::Stopped ) {
        try {
            $appPool.Start()
        }
        catch {
            Write-Error ('Failed to start {0} app pool: {1}' -f $Name, $_.Exception.Message)
        }
    }

    if ( $PassThru ) {
        $appPool
    }
}


function Install-CIisApplication {
    <#
    .SYNOPSIS
    Creates a new application under a website.
    
    .DESCRIPTION
    Creates a new application at `VirtualPath` under website `SiteName` running the code found on the file system under `PhysicalPath`, i.e. if SiteName is is `example.com`, the application is accessible at `example.com/VirtualPath`.  If an application already exists at that path, it is removed first.  The application can run under a custom application pool using the optional `AppPoolName` parameter.  If no app pool is specified, the application runs under the same app pool as the website it runs under.

    Beginning with Carbon 2.0, returns a `Microsoft.Web.Administration.Application` object for the new application if one is created or modified.

    Beginning with Carbon 2.0, if no app pool name is given, existing application's are updated to use `DefaultAppPool`.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Install-CIisApplication -SiteName Peanuts -VirtualPath CharlieBrown -PhysicalPath C:\Path\To\CharlieBrown -AppPoolName CharlieBrownPool
    
    Creates an application at `Peanuts/CharlieBrown` which runs from `Path/To/CharlieBrown`.  The application runs under the `CharlieBrownPool`.
    
    .EXAMPLE
    Install-CIisApplication -SiteName Peanuts -VirtualPath Snoopy -PhysicalPath C:\Path\To\Snoopy
    
    Create an application at Peanuts/Snoopy, which runs from C:\Path\To\Snoopy.  It uses the same application as the Peanuts website.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The site where the application should be created.
        $SiteName,
        
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [string]
        # The name of the application.
        $VirtualPath,
        
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [string]
        # The path to the application.
        $PhysicalPath,
        
        [string]
        # The app pool for the application. Default is `DefaultAppPool`.
        $AppPoolName,

        [Switch]
        # Returns IIS application object. This switch is new in Carbon 2.0.
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -SiteName $SiteName
    if ( -not $site ) {
        Write-Error ('[IIS] Website ''{0}'' not found.' -f $SiteName)
        return
    }

    $iisAppPath = Join-CIisVirtualPath $SiteName $VirtualPath

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath
    if ( -not (Test-Path $PhysicalPath -PathType Container) ) {
        Write-Verbose ('IIS://{0}: creating physical path {1}' -f $iisAppPath, $PhysicalPath)
        $null = New-Item $PhysicalPath -ItemType Directory
    }

    $appPoolDesc = ''
    if ( $AppPoolName ) {
        $appPoolDesc = '; appPool: {0}' -f $AppPoolName
    }
    
    $apps = $site.GetCollection()

    $appPath = "/{0}" -f $VirtualPath
    $app = Get-CIisApplication -SiteName $SiteName -VirtualPath $VirtualPath
    $modified = $false
    if ( -not $app ) {
        Write-Verbose ('IIS://{0}: creating application' -f $iisAppPath)
        $app = $apps.CreateElement('application') |
        Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru
        $app['path'] = $appPath
        $apps.Add( $app ) | Out-Null
        $modified = $true
    }

    if ( $app['path'] -ne $appPath ) {
        $app['path'] = $appPath
        $modified = $true
    }
        
    if ( $AppPoolName -and $app['applicationPool'] -ne $AppPoolName) {
        $app['applicationPool'] = $AppPoolName
        $modified = $true
    }

    $vdir = $null
    if ( $app | Get-Member 'VirtualDirectories' ) {
        $vdir = $app.VirtualDirectories |
        Where-Object { $_.Path -eq '/' }
    }

    if ( -not $vdir ) {
        Write-Verbose ('IIS://{0}: creating virtual directory' -f $iisAppPath)
        $vdirs = $app.GetCollection()
        $vdir = $vdirs.CreateElement('virtualDirectory')
        $vdir['path'] = '/'
        $vdirs.Add( $vdir ) | Out-Null
        $modified = $true
    }

    if ( $vdir['physicalPath'] -ne $PhysicalPath ) {
        Write-Verbose ('IIS://{0}: setting physical path {1}' -f $iisAppPath, $PhysicalPath)
        $vdir['physicalPath'] = $PhysicalPath
        $modified = $true
    }

    if ( $modified ) {
        Write-Verbose ('IIS://{0}: committing changes' -f $iisAppPath)
        $app.CommitChanges()
    }

    if ( $PassThru ) {
        return Get-CIisApplication -SiteName $SiteName -VirtualPath $VirtualPath
    }

}


function Get-CIisWebsite {
    <#
    .SYNOPSIS
    Returns all the websites installed on the local computer, or a specific website.
    
    .DESCRIPTION
    Returns a Microsoft.Web.Administration.Site object.

    Each object will have a `CommitChanges` script method added which will allow you to commit/persist any changes to the website's configuration.
     
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    Microsoft.Web.Administration.Site.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.web.administration.site.aspx

    .EXAMPLE
    Get-CIisWebsite

    Returns all installed websites.
     
    .EXAMPLE
    Get-CIisWebsite -SiteName 'WebsiteName'
     
    Returns the details for the site named `WebsiteName`.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        [string]
        [Alias('SiteName')]
        # The name of the site to get.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ( $Name -and -not (Test-CIisWebsite -Name $Name) ) {
        return $null
    }
    
    $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
    $mgr.Sites | 
    Where-Object {
        if ( $Name ) {
            $_.Name -eq $Name
        }
        else {
            $true
        }
    } | Add-IisServerManagerMember -ServerManager $mgr -PassThru
}


function Get-CIisConfigurationSection {
    <#
    .SYNOPSIS
    Gets a Microsoft.Web.Adminisration configuration section for a given site and path.
    
    .DESCRIPTION
    Uses the Microsoft.Web.Administration API to get a `Microsoft.Web.Administration.ConfigurationSection`.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    Microsoft.Web.Administration.ConfigurationSection.
    
    .EXAMPLE
    Get-CIisConfigurationSection -SiteName Peanuts -Path Doghouse -Path 'system.webServer/security/authentication/anonymousAuthentication'

    Returns a configuration section which represents the Peanuts site's Doghouse path's anonymous authentication settings.    
    #>
    [CmdletBinding(DefaultParameterSetName = 'Global')]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ForSite')]
        [string]
        # The site where anonymous authentication should be set.
        $SiteName,
        
        [Parameter(ParameterSetName = 'ForSite')]
        [Alias('Path')]
        [string]
        # The optional site path whose configuration should be returned.
        $VirtualPath = '',
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ForSite')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Global')]
        [string]
        # The path to the configuration section to return.
        $SectionPath,
        
        [Type]
        # The type of object to return.  Optional.
        $Type = [Microsoft.Web.Administration.ConfigurationSection]
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
    $config = $mgr.GetApplicationHostConfiguration()
    
    $section = $null
    $qualifier = ''
    try {
        if ( $PSCmdlet.ParameterSetName -eq 'ForSite' ) {
            $qualifier = Join-CIisVirtualPath $SiteName $VirtualPath
            $section = $config.GetSection( $SectionPath, $Type, $qualifier )
        }
        else {
            $section = $config.GetSection( $SectionPath, $Type )
        }
    }
    catch {
    }
        
    if ( $section ) {
        $section | Add-IisServerManagerMember -ServerManager $mgr -PassThru
    }
    else {
        Write-Error ('IIS:{0}: configuration section {1} not found.' -f $qualifier, $SectionPath)
        return
    }
}


function Get-CIisAppPool {
    <#
    .SYNOPSIS
    Gets a `Microsoft.Web.Administration.ApplicationPool` object for an application pool.
    
    .DESCRIPTION
    The `Get-CIisAppPool` function returns an IIS application pools as a `Microsoft.Web.Administration.ApplicationPool` object. Use the `Name` parameter to return the application pool. If that application pool isn't found, `$null` is returned.

    Carbon adds a `CommitChanges` method on each object returned that you can use to save configuration changes.

    Beginning in Carbon 2.0, `Get-CIisAppPool` will return all application pools installed on the current computer.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.web.administration.applicationpool(v=vs.90).aspx
    
    .OUTPUTS
    Microsoft.Web.Administration.ApplicationPool.

    .EXAMPLE
    Get-CIisAppPool

    Demonstrates how to get *all* application pools.
    
    .EXAMPLE
    Get-CIisAppPool -Name 'Batcave'
    
    Gets the `Batcave` application pool.
    
    .EXAMPLE
    Get-CIisAppPool -Name 'Missing!'
    
    Returns `null` since, for purposes of this example, there is no `Missing~` application pool.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        [string]
        # The name of the application pool to return. If not supplied, all application pools are returned.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-Object Microsoft.Web.Administration.ServerManager
    $mgr.ApplicationPools |
    Where-Object { 
        if ( -not $PSBoundParameters.ContainsKey('Name') ) {
            return $true
        }
        return $_.Name -eq $Name 
    } |
    Add-IisServerManagerMember -ServerManager $mgr -PassThru
}

function Get-CIisApplication {
    <#
    .SYNOPSIS
    Gets an IIS application as an `Application` object.

    .DESCRIPTION
    Uses the `Microsoft.Web.Administration` API to get an IIS application object.  If the application doesn't exist, `$null` is returned.

    The objects returned have two dynamic properties and one dynamic methods added.

     * `ServerManager { get; }` - The `ServerManager` object which created the `Application` object.
     * `CommitChanges()` - Persists any configuration changes made to the object back into IIS's configuration files.
     * `PhysicalPath { get; }` - The physical path to the application.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    Microsoft.Web.Administration.Application.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar`

    Gets all the applications running under the `DeathStar` website.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar' -VirtualPath '/'

    Demonstrates how to get the main application for a website: use `/` as the application name.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar' -VirtualPath 'MainPort/ExhaustPort'

    Demonstrates how to get a nested application, i.e. gets the application at `/MainPort/ExhaustPort` under the `DeathStar` website.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The site where the application is running.
        $SiteName,
        
        [Parameter()]
        [Alias('Name')]
        [string]
        # The name of the application.  Default is to return all applications running under the website `$SiteName`.
        $VirtualPath
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -SiteName $SiteName
    if ( -not $site ) {
        return
    }

    $site.Applications |
    Where-Object {
        if ( $VirtualPath ) {
            return ($_.Path -eq "/$VirtualPath")
        }
        return $true
    } | 
    Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru
}


function Enable-CIisSsl {
    <#
    .SYNOPSIS
    Turns on and configures SSL for a website or part of a website.

    .DESCRIPTION
    This function enables SSL and optionally the site/directory to: 

     * Require SSL (the `RequireSsl` switch)
     * Ignore/accept/require client certificates (the `AcceptClientCertificates` and `RequireClientCertificates` switches).
     * Requiring 128-bit SSL (the `Require128BitSsl` switch).

    By default, this function will enable SSL, make SSL connections optional, ignores client certificates, and not require 128-bit SSL.

    Changing any SSL settings will do you no good if the website doesn't have an SSL binding or doesn't have an SSL certificate.  The configuration will most likely succeed, but won't work in a browser.  So sad.
    
    Beginning with IIS 7.5, the `Require128BitSsl` parameter won't actually change the behavior of a website since [there are no longer 128-bit crypto providers](https://forums.iis.net/p/1163908/1947203.aspx) in versions of Windows running IIS 7.5.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://support.microsoft.com/?id=907274

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts

    Enables SSL on the `Peanuts` website's, making makes SSL connections optional, ignoring client certificates, and making 128-bit SSL optional.

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts -VirtualPath Snoopy/DogHouse -RequireSsl
    
    Configures the `/Snoopy/DogHouse` directory in the `Peanuts` site to require SSL.  It also turns off any client certificate settings and makes 128-bit SSL optional.

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts -AcceptClientCertificates

    Enables SSL on the `Peanuts` website and configures it to accept client certificates, makes SSL optional, and makes 128-bit SSL optional.

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts -RequireSsl -RequireClientCertificates

    Enables SSL on the `Peanuts` website and configures it to require SSL and client certificates.  You can't require client certificates without also requiring SSL.

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts -Require128BitSsl

    Enables SSL on the `Peanuts` website and require 128-bit SSL.  Also, makes SSL connections optional and ignores client certificates.

    .LINK
    Set-CIisWebsiteSslCertificate
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'IgnoreClientCertificates')]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The website whose SSL flags should be modifed.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The path to the folder/virtual directory/application under the website whose SSL flags should be set.
        $VirtualPath = '',
        
        [Parameter(ParameterSetName = 'IgnoreClientCertificates')]
        [Parameter(ParameterSetName = 'AcceptClientCertificates')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RequireClientCertificates')]
        [Switch]
        # Should SSL be required?
        $RequireSsl,
        
        [Switch]
        # Requires 128-bit SSL.  Only changes IIS behavior in IIS 7.0.
        $Require128BitSsl,
        
        [Parameter(ParameterSetName = 'AcceptClientCertificates')]
        [Switch]
        # Should client certificates be accepted?
        $AcceptClientCertificates,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'RequireClientCertificates')]
        [Switch]
        # Should client certificates be required?  Also requires SSL ('RequireSsl` switch).
        $RequireClientCertificates
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $SslFlags_Ssl = 8
    $SslFlags_SslNegotiateCert = 32
    $SslFlags_SslRequireCert = 64
    $SslFlags_SslMapCert = 128
    $SslFlags_Ssl128 = 256

    $intFlag = 0
    $flags = @()
    if ( $RequireSSL -or $RequireClientCertificates ) {
        $flags += 'Ssl'
        $intFlag = $intFlag -bor $SslFlags_Ssl
    }
    
    if ( $AcceptClientCertificates -or $RequireClientCertificates ) {
        $flags += 'SslNegotiateCert'
        $intFlag = $intFlag -bor $SslFlags_SslNegotiateCert
    }
    
    if ( $RequireClientCertificates ) {
        $flags += 'SslRequireCert'
        $intFlag = $intFlag -bor $SslFlags_SslRequireCert
    }
    
    if ( $Require128BitSsl ) {
        $flags += 'Ssl128'
        $intFlag = $intFlag -bor $SslFlags_Ssl128
    }

    $section = Get-CIisConfigurationSection -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath 'system.webServer/security/access'
    if ( -not $section ) {
        return
    }

    $flags = $flags -join ','
    $currentIntFlag = $section['sslFlags']
    $currentFlags = @( )
    if ( $currentIntFlag -band $SslFlags_Ssl ) {
        $currentFlags += 'Ssl'
    }
    if ( $currentIntFlag -band $SslFlags_SslNegotiateCert ) {
        $currentFlags += 'SslNegotiateCert'
    }
    if ( $currentIntFlag -band $SslFlags_SslRequireCert ) {
        $currentFlags += 'SslRequireCert'
    }
    if ( $currentIntFlag -band $SslFlags_SslMapCert ) {
        $currentFlags += 'SslMapCert'
    }
    if ( $currentIntFlag -band $SslFlags_Ssl128 ) {
        $currentFlags += 'Ssl128'
    }

    if ( -not $currentFlags ) {
        $currentFlags += 'None'
    }

    $currentFlags = $currentFlags -join ','


    if ( $section['sslFlags'] -ne $intFlag ) {
        Write-IisVerbose $SiteName 'SslFlags' ('{0} ({1})' -f $currentIntFlag, $currentFlags) ('{0} ({1})' -f $intFlag, $flags) -VirtualPath $VirtualPath
        $section['sslFlags'] = $flags
        if ( $pscmdlet.ShouldProcess( (Join-CIisVirtualPath $SiteName $VirtualPath), "enable SSL" ) ) {
            $section.CommitChanges()
        }
    }
}

function Enable-CIisDirectoryBrowsing {
    <#
    .SYNOPSIS
    Enables directory browsing under all or part of a website.

    .DESCRIPTION
    Enables directory browsing (i.e. showing the contents of a directory by requesting that directory in a web browser) for a website.  To enable directory browsing on a directory under the website, pass the virtual path to that directory as the value to the `Directory` parameter.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Enable-CIisDirectoryBrowsing -SiteName Peanuts

    Enables directory browsing on the `Peanuts` website.

    .EXAMPLE
    Enable-CIisDirectoryBrowsing -SiteName Peanuts -Directory Snoopy/DogHouse

    Enables directory browsing on the `/Snoopy/DogHouse` directory under the `Peanuts` website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The name of the site where the virtual directory is located.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The directory where directory browsing should be enabled.
        $VirtualPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $section = Get-CIisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/directoryBrowse'

    if ( $section['enabled'] -ne 'true' ) {
        Write-IisVerbose $SiteName 'Directory Browsing' 'disabled' 'enabled'
        $section['enabled'] = $true
        $section.CommitChanges()
    }

}


filter Add-IisServerManagerMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        # The object on which the server manager members will be added.
        $InputObject,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Web.Administration.ServerManager]
        # The server manager object to use as the basis for the new members.
        $ServerManager,
        
        [Switch]
        # If set, will return the input object.
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $InputObject | 
    Add-Member -MemberType NoteProperty -Name 'ServerManager' -Value $ServerManager -PassThru |
    Add-Member -MemberType ScriptMethod -Name 'CommitChanges' -Value { $this.ServerManager.CommitChanges() }
        
    if ( $PassThru ) {
        return $InputObject
    }
}


function Add-CIisDefaultDocument {
    <#
    .SYNOPSIS
    Adds a default document name to a website.
    
    .DESCRIPTION
    If you need a custom default document for your website, this function will add it.  The `FileName` argument should be a filename IIS should use for a default document, e.g. home.html.
    
    If the website already has `FileName` in its list of default documents, this function silently returns.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Add-CIisDefaultDocument -SiteName MySite -FileName home.html
    
    Adds `home.html` to the list of default documents for the MySite website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The name of the site where the default document should be added.
        $SiteName,
        
        [Parameter(Mandatory = $true)]
        [string]
        # The default document to add.
        $FileName
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $section = Get-CIisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/defaultDocument'
    if ( -not $section ) {
        return
    }

    [Microsoft.Web.Administration.ConfigurationElementCollection]$files = $section.GetCollection('files')
    $defaultDocElement = $files | Where-Object { $_["value"] -eq $FileName }
    if ( -not $defaultDocElement ) {
        Write-IisVerbose $SiteName 'Default Document' '' $FileName
        $defaultDocElement = $files.CreateElement('add')
        $defaultDocElement["value"] = $FileName
        $files.Add( $defaultDocElement )
        $section.CommitChanges() 
    }
}

