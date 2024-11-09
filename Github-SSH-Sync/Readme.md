## Anleitung: Einrichtung der automatischen GitHub SSH-Key-Aktualisierung

Dieses Skript richtet alles ein, um die öffentlichen SSH-Keys aller Mitglieder einer GitHub-Organisation herunterzuladen und automatisch jede Stunde zu aktualisieren. Der gesamte Prozess wird mit einem einzigen `curl`-Befehl gestartet.

### Voraussetzungen
- **Debian 12** oder eine ähnliche Linux-Distribution.
- **GitHub Personal Access Token (PAT)** mit den folgenden Berechtigungen:
  - `read:org`: Um die Mitgliedschaftsinformationen der Organisation zu lesen.
  - `read:user`: Um die öffentlichen SSH-Keys der Benutzer zu lesen.

### Schritt 1: Erstelle einen GitHub Personal Access Token (PAT)

1. **Gehe zu GitHub** und navigiere zu **Settings** > **Developer settings** > **Personal access tokens**.
2. Klicke auf **Generate new token** (oder **Generate new token (classic)**).
3. Wähle einen **Token-Namen** und ein Ablaufdatum.
4. Unter **Select scopes** aktiviere:
   - `read:org` für den Zugriff auf die Mitgliedschaftsinformationen der Organisation.
   - `read:user` für den Zugriff auf öffentliche Benutzerinformationen und SSH-Keys.
5. Klicke auf **Generate token** und **kopiere den Token**, um ihn später einzugeben.

### Schritt 2: Führe das Setup-Skript mit `curl` aus

Führe den folgenden Befehl aus, um das Setup-Skript herunterzuladen und auszuführen:

```bash
curl -sL https://raw.githubusercontent.com/BabsyIT/Babsy-Infra_Public/refs/heads/main/Github-SSH-Sync/update_github_org_ssh_keys.sh | sudo bash
```

### Was das Skript macht

Das Skript erledigt die folgenden Schritte automatisch:

1. **Speicherung des GitHub PAT-Tokens**: Du wirst aufgefordert, deinen GitHub PAT-Token einzugeben, der dann sicher in `/opt/github-ssh/.github_token` gespeichert wird.
2. **Erstellung des Hauptskripts**: Es wird das Skript `/opt/github-ssh/update_github_org_ssh_keys.sh` erstellt, welches die SSH-Keys der GitHub-Organisation abruft und speichert.
3. **Installation von `jq`**: Falls `jq` nicht installiert ist, wird es für die Verarbeitung von JSON-Daten automatisch installiert.
4. **Einrichtung eines Cronjobs**: Ein Cronjob wird erstellt, der das Skript jede Stunde ausführt, um die SSH-Keys der Organisation zu aktualisieren.

### Überprüfung der Einrichtung

1. **Manuelles Ausführen des Hauptskripts**:

   Um sicherzustellen, dass das Skript korrekt funktioniert, kannst du es manuell ausführen:

   ```bash
   sudo /opt/github-ssh/update_github_org_ssh_keys.sh
   ```

2. **Überprüfen des Cronjobs**:

   Der folgende Befehl zeigt den Cronjob an, der das Skript jede Stunde ausführt:

   ```bash
   sudo crontab -l | grep update_github_org_ssh_keys.sh
   ```

   Die Ausgabe sollte so aussehen:
   
   ```plaintext
   0 * * * * /opt/github-ssh/update_github_org_ssh_keys.sh
   ```

### Hinweise zur weiteren Nutzung

- **Manuelles Aktualisieren**: Das Skript kann jederzeit manuell ausgeführt werden, um die SSH-Keys sofort zu aktualisieren.
- **Automatische Aktualisierung**: Der Cronjob sorgt dafür, dass die SSH-Keys jede Stunde aktualisiert werden, ohne weiteres Zutun.

Mit diesem Setup wird dein Server regelmäßig die öffentlichen SSH-Keys der GitHub-Organisation abrufen und in der Datei `~/.ssh/github_authorized_keys` speichern, sodass der Zugriff für die Mitglieder der Organisation stets auf dem neuesten Stand ist.
