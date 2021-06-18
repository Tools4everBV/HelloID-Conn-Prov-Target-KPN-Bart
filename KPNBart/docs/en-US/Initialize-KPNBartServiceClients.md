---
external help file: KPNBart-help.xml
Module Name: KPNBart
online version:
schema: 2.0.0
---

# Initialize-KPNBartServiceClients

## SYNOPSIS
Initializes the KPN Bart BulkCommand, Command and QueryService clients

## SYNTAX

```
Initialize-KPNBartServiceClients [[-Username] <String>] [[-Password] <String>] [[-BaseUrl] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Initializes the KPN Bart BulkCommand, Command and QueryService clients.
This function creates three highlevel $script variables
so that the clients can be used througout this module

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Username
The UserName for the user that has administrative access to the KPN Bart environment

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
The password for the user

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseUrl
The BaseUrl to your KPN Bart enviromnemt

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
