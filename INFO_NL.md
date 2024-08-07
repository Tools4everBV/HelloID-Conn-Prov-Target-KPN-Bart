Met de KPN Bart Connector, nu bekend als de KPN Citrix Werkplek, integreer je de Identity & Access Management (IAM)-oplossing HelloID van Tools4ever naadloos met verschillende bronsystemen. Deze integratie brengt het beheer van gebruikersaccounts en autorisaties in KPN Bart naar een hoger niveau, waarbij de gegevens uit je bronsysteem leidend zijn. Dit zorgt voor foutpreventie, tijdsbesparing, verbeterd serviceniveau en optimale ondersteuning voor de rest van je organisatie.

## Wat is KPN Bart?

KPN Bart is een oplossing van KPN die gericht is op het beheren en beveiligen van gebruikersaccounts, systemen en andere middelen binnen Microsoft Active Directory-gebaseerde bedrijfsnetwerken. Het fungeert niet alleen als identity provider (IDP), maar ook als het centrale toegangspunt tot verschillende bronnen binnen het bedrijfsnetwerk.

## Waarom is een KPN Bart koppeling handig?

Met de KPN Bart Connector til je Microsoft Active Directory-gebaseerde bedrijfsnetwerken naar een hoger niveau. Hierdoor kun je je IT-omgeving efficiënter en effectiever ondersteunen, wat leidt tot tijdsbesparing en een verbeterde algehele dienstverlening.

De KPN Bart Connector biedt integratie met verschillende populaire bronsystemen, waaronder:
*	Visma Raet
*	AFAS
  
Meer details over de integratie met deze bronsystemen worden verderop in het artikel behandeld.

## HelloID voor KPN Bart helpt je met

**Gebruikersaccounts adequaat beheren:** HelloID detecteert automatisch wijzigingen in het HR-systeem en synchroniseert deze informatie met KPN Bart. Dit vermindert de behoefte voor handmatige handelingen en zorgt voor een vlotte overdracht van informatie, waardoor gebruikersaccounts snel en efficiënt worden beheerd.
**Foutloos beheer van autorisaties:** Met behulp van business rules beheert HelloID de lidmaatschappen van KPN Bart resourcegroepen. Dit maakt het eenvoudig om lidmaatschappen toe te wijzen of in te trekken, terwijl KPN Bart zorgt voor de consistente toepassing van autorisaties op alle groepsleden.
**Attributen aanpassen:** HelloID automatiseert het proces van het toekennen van groepslidmaatschappen op basis van attributen uit het bronsysteem. Dit biedt een gecontroleerde en efficiënte manier om accounts en rechten toe te wijzen in KPN Bart.

## Hoe HelloID integreert met KPN Bart 

Je kunt KPN Bart integreren als doelsysteem met HelloID, waardoor je de gehele levenscyclus van een gebruiker binnen KPN Bart via HelloID kunt beheren. Aangezien KPN Bart lokaal wordt gehost, moet er binnen de serveromgeving van KPN Bart een specifieke HelloID-agent worden geïmplementeerd. Deze server moet beschikbaar worden gesteld en voldoen aan de vereisten van de HelloID-agent. De KPN Bart-connector is een HelloID PowerShell-doelconnector, waarmee HelloID via de door Tools4ever ontwikkelde PowerShell-module communiceert met de webservices van KPN Bart.

| Wijziging in bronsysteem                  | Procedure in doelsystemen KPN Bart |
|-------------------------------------------|------------------------------------| 
| **Nieuwe medewerker** |	Wanneer een nieuwe medewerker in dienst treedt, is het cruciaal dat deze snel operationeel is. Dit vereist de juiste accounts en autorisaties. Dankzij de integratie tussen KPN Bart en HelloID verloopt dit proces moeiteloos. HelloID genereert automatisch de benodigde accounts in KPN Bart op basis van het HR-systeem en wijst de juiste rollen toe. De bijbehorende autorisaties worden vervolgens via KPN Bart toegewezen.|  
| **Andere functie medewerker** |	Voor medewerkers die doorgroeien of van functie veranderen, zijn vaak andere autorisaties nodig. Dankzij de koppeling tussen HelloID en KPN Bart wordt dit automatisch geregeld. Hierdoor blijven de rollen en autorisaties in lijn met de functiewijzigingen binnen de organisatie.|
| **Medewerker treedt uit dienst** |	HelloID schakelt automatisch het gebruikersaccount in KPN Bart uit wanneer een medewerker uit dienst treedt. Alle betrokken medewerkers worden direct op de hoogte gebracht. Na verloop van tijd verwijdert HelloID automatisch het KPN Bart-account, wat het clearproces in KPN Bart in gang zet.|

## Koppeling met bronsystemen:

HelloID maakt integratie mogelijk met diverse bronsystemen, waaronder Visma Raet en AFAS. Door deze integratie optimaliseer je het beheer van gebruikers en autorisaties, waardoor je organisatie efficiënter werkt en voldoet aan compliance-eisen. Met ruim 200 beschikbare connectoren biedt HelloID een breed scala aan integratiemogelijkheden, waardoor je met alle populaire systemen kunt samenwerken.
