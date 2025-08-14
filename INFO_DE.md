Mit dem KPN Bart Connector, jetzt bekannt als der KPN Citrix Arbeitsplatz, integrieren Sie die Identity & Access Management (IAM)-Lösung HelloID von Tools4ever nahtlos mit verschiedenen Quellsystemen. Diese Integration hebt die Verwaltung von Benutzerkonten und Berechtigungen in KPN Bart auf ein höheres Niveau, wobei die Daten aus Ihrem Quellsystem führend sind. Dies sorgt für Fehlervermeidung, Zeitersparnis, ein verbessertes Serviceniveau und optimale Unterstützung für den Rest Ihrer Organisation.

## Was ist KPN Bart?

KPN Bart ist eine Lösung von KPN, die sich auf das Management und die Sicherung von Benutzerkonten, Systemen und anderen Ressourcen innerhalb von Microsoft Active Directory-basierten Unternehmensnetzwerken konzentriert. Sie fungiert nicht nur als Identity Provider (IDP), sondern auch als zentraler Zugangspunkt zu verschiedenen Ressourcen innerhalb des Unternehmensnetzwerks.

## Warum ist eine KPN Bart-Verbindung nützlich?

Mit dem KPN Bart Connector heben Sie Microsoft Active Directory-basierte Unternehmensnetzwerke auf ein höheres Niveau. Dadurch können Sie Ihre IT-Umgebung effizienter und effektiver unterstützen, was zu einer Zeitersparnis und einer verbesserten allgemeinen Dienstleistung führt.

Der KPN Bart Connector bietet Integration mit verschiedenen beliebten Quellsystemen, darunter:
* Visma Raet
* AFAS

Weitere Details zur Integration mit diesen Quellsystemen werden im weiteren Verlauf des Artikels behandelt.

## HelloID für KPN Bart hilft Ihnen bei

**Angemessenes Management von Benutzerkonten:** HelloID erkennt automatisch Änderungen im HR-System und synchronisiert diese Informationen mit KPN Bart. Dies reduziert den Bedarf an manuellen Eingriffen und sorgt für eine reibungslose Informationsübermittlung, sodass Benutzerkonten schnell und effizient verwaltet werden.
**Fehlerfreie Verwaltung von Berechtigungen:** Mithilfe von Business Rules verwaltet HelloID die Mitgliedschaften in KPN Bart-Ressourcengruppen. Dies erleichtert die Zuweisung oder den Entzug von Mitgliedschaften, während KPN Bart die konsistente Anwendung von Berechtigungen auf alle Gruppenmitglieder sicherstellt.
**Anpassen von Attributen:** HelloID automatisiert den Prozess der Zuweisung von Gruppenmitgliedschaften basierend auf Attributen aus dem Quellsystem. Dies bietet eine kontrollierte und effiziente Methode zur Zuweisung von Konten und Rechten in KPN Bart.

## Wie HelloID in KPN Bart integriert

Sie können KPN Bart als Zielsystem mit HelloID integrieren, wodurch Sie den gesamten Lebenszyklus eines Benutzers innerhalb von KPN Bart über HelloID verwalten können. Da KPN Bart lokal gehostet wird, muss ein spezifischer HelloID-Agent in der Serverumgebung von KPN Bart implementiert werden. Dieser Server muss bereitgestellt werden und die Anforderungen des HelloID-Agents erfüllen. Der KPN Bart-Connector ist ein HelloID PowerShell-Zielconnector, mit dem HelloID über das von Tools4ever entwickelte PowerShell-Modul mit den Webdiensten von KPN Bart kommuniziert.

| Änderung im Quellsystem                  | Verfahren in Zielsystemen KPN Bart |
|------------------------------------------|------------------------------------| 
| **Neuer Mitarbeiter** | Wenn ein neuer Mitarbeiter eintritt, ist es entscheidend, dass dieser schnell einsatzbereit ist. Dies erfordert die richtigen Konten und Berechtigungen. Dank der Integration zwischen KPN Bart und HelloID verläuft dieser Prozess mühelos. HelloID generiert automatisch die benötigten Konten in KPN Bart basierend auf dem HR-System und weist die entsprechenden Rollen zu. Die zugehörigen Berechtigungen werden anschließend über KPN Bart zugewiesen.|
| **Funktionwechsel eines Mitarbeiters** | Für Mitarbeiter, die aufsteigen oder die Funktion wechseln, sind oft andere Berechtigungen erforderlich. Dank der Verbindung zwischen HelloID und KPN Bart wird dies automatisch geregelt. Dadurch bleiben die Rollen und Berechtigungen im Einklang mit den Funktionsänderungen innerhalb der Organisation.|
| **Austritt eines Mitarbeiters** | HelloID deaktiviert automatisch das Benutzerkonto in KPN Bart, wenn ein Mitarbeiter aus dem Dienst ausscheidet. Alle beteiligten Mitarbeiter werden sofort informiert. Nach einer gewissen Zeit löscht HelloID das KPN Bart-Konto automatisch, was den Clear-Prozess in KPN Bart in Gang setzt.|

## Verbindung mit Quellsystemen:

HelloID ermöglicht die Integration mit verschiedenen Quellsystemen, darunter Visma Raet und AFAS. Durch diese Integration optimieren Sie das Management von Benutzern und Berechtigungen, wodurch Ihre Organisation effizienter arbeitet und die Compliance-Anforderungen erfüllt. Mit über 200 verfügbaren Connectoren bietet HelloID eine breite Palette an Integrationsmöglichkeiten, sodass Sie mit allen gängigen Systemen zusammenarbeiten können.