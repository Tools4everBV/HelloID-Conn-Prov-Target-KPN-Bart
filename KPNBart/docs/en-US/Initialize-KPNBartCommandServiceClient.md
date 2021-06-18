---
external help file: KPNBart-help.xml
Module Name: KPNBart
online version:
schema: 2.0.0
---

# Initialize-KPNBartCommandServiceClient

## SYNOPSIS
Initializes the KPN Bart CommandService client

## SYNTAX

```
Initialize-KPNBartCommandServiceClient [-PSCredentials] <PSCredential> [-Uri] <String> [<CommonParameters>]
```

## DESCRIPTION
Initializes the KPN Bart CommandService client and creates a namespace \[CommandService\] so that the KPN Bart methods
can be used througout this module

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -PSCredentials
The credentials object containing the UserName and Password

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uri
The Uri to your KPN Bart environment

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### KPNBartConnectedServices.CommandService.CommandServiceClient
## NOTES

## RELATED LINKS
