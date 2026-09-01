# FirebirdSQL Tools

Windows-Skripte zur **Validierung, Sicherung und Wiederherstellung von Firebird-SQL-Datenbanken** mit den Firebird-Werkzeugen `gfix` und `gbak`.

Die Skripte sind für die Ausführung direkt auf einem Firebird-Server vorgesehen und unterstützen unter anderem:

* Validierung von Firebird-Datenbanken mit `gfix`
* Erstellung von Backups mit `gbak`
* Wiederherstellung von Backups mit `gbak`
* Rotation vorhandener Backup- und Datenbankdateien
* Protokollierung der ausgeführten Vorgänge
* Stoppen und Starten konfigurierbarer Dienste

> **Wichtig:** Vor Arbeiten an produktiven Datenbanken sollte immer eine zusätzliche, unabhängige Datensicherung vorhanden sein.

---

## Voraussetzungen

* Windows
* Installierter Firebird-Server
* Zugriff auf die Firebird-Werkzeuge `gfix` und `gbak`
* Ausreichende Berechtigungen auf die Datenbank-, Backup- und Log-Verzeichnisse
* Für das Stoppen oder Starten von Windows-Diensten sind entsprechende administrative Berechtigungen erforderlich.

Die Skripte müssen direkt auf dem Firebird-Server ausgeführt werden.

---

## Funktionen

### Validation

Die Validation überprüft die konfigurierten Firebird-Datenbanken mit `gfix`.

Damit können Inkonsistenzen beziehungsweise Fehler innerhalb einer Datenbank erkannt und – abhängig von der verwendeten Konfiguration – weitere Wartungsoperationen durchgeführt werden.

Vor einer Validation sollte eine aktuelle zusätzliche Sicherung der Datenbank vorhanden sein.

---

### Backup

Das Backup wird mit dem Firebird-Werkzeug `gbak` erstellt.

Für jede konfigurierte Datenbank wird eine entsprechende Backup-Datei erzeugt.

Bereits vorhandene Backups können automatisch rotiert werden. Die Anzahl der aufzubewahrenden Sicherungen wird über `maxbackups` gesteuert.

Dadurch können mehrere Generationen einer Datenbanksicherung vorgehalten werden.

---

### Restore

Mit der Restore-Funktion können zuvor mit `gbak` erstellte Firebird-Backups wiederhergestellt werden.

Vorhandene Datenbankdateien können dabei entsprechend der Konfiguration umbenannt beziehungsweise rotiert werden.

**Achtung:** Ein Restore verändert beziehungsweise ersetzt Datenbankdateien. Vor der Ausführung sollte daher unbedingt eine zusätzliche Sicherung der bestehenden Daten vorhanden sein.

---

## Konfiguration

Die Skripte werden über verschiedene Parameter konfiguriert.

### Allgemeine Parameter

| Parameter         | Beschreibung                                                              |
| ----------------- | ------------------------------------------------------------------------- |
| `databasedir`     | Verzeichnis, in dem sich die Firebird-Datenbanken befinden                |
| `databases`       | Namen der zu verarbeitenden Datenbanken, durch Kommas getrennt            |
| `dbextension`     | Dateiendung der Firebird-Datenbanken, z. B. `FDB`                         |
| `backupextension` | Dateiendung der Firebird-Backups, z. B. `FBK`                             |
| `databaseserver`  | Firebird-Server, standardmäßig `localhost`                                |
| `fbport`          | Port des Firebird-Servers, standardmäßig `3050`                           |
| `username`        | Firebird-Benutzer für die Datenbankoperationen                            |
| `password`        | Kennwort des Firebird-Benutzers                                           |
| `logdir`          | Verzeichnis für die erzeugten Protokolldateien                            |
| `services`        | Windows-Dienste, die bei Bedarf gestoppt beziehungsweise gestartet werden |

---

## Backup-Konfiguration

Für die Sicherung der Datenbanken können zusätzliche Parameter verwendet werden.

| Parameter    | Beschreibung                                                 |
| ------------ | ------------------------------------------------------------ |
| `backupdir`  | Zielverzeichnis für die erzeugten Backup-Dateien             |
| `maxbackups` | Anzahl der Backup-Generationen, die aufbewahrt werden sollen |

Ist die maximale Anzahl vorhandener Backups erreicht, werden ältere Sicherungen entsprechend rotiert beziehungsweise entfernt.

---

## Restore-Konfiguration

Für die Wiederherstellung der Datenbanken können zusätzliche Parameter verwendet werden.

| Parameter    | Beschreibung                                                               |
| ------------ | -------------------------------------------------------------------------- |
| `fixcharset` | Aktiviert bei Bedarf die im Skript vorgesehene Korrektur des Zeichensatzes |

---

## Dienste

Die Skripte können so konfiguriert werden, dass Windows-Dienste vor bestimmten Datenbankoperationen gestoppt und anschließend wieder gestartet werden.

Dies ist insbesondere sinnvoll, wenn Anwendungen oder Dienste während einer Wartung dauerhaft auf die Firebird-Datenbank zugreifen.

Für diese Funktionen muss das Skript mit ausreichenden Windows-Berechtigungen ausgeführt werden.

---

## Haftungsausschluss

Die Skripte werden ohne Gewähr bereitgestellt.

Die Verwendung erfolgt auf eigene Verantwortung. Vor der Ausführung auf produktiven Systemen sollten aktuelle und unabhängig geprüfte Sicherungen der betroffenen Datenbanken vorhanden sein.

Der Autor übernimmt keine Haftung für Datenverlust, Ausfallzeiten oder andere Schäden, die durch die Verwendung der Skripte entstehen.
