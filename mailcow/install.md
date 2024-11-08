# Anleitung: Mailcow (Mailserver) installieren und einrichten - Bennet Richter
**Tipp**: Sie können für alle Dateinamen und Verzeichnisse die automatische Vervollständigung mithilfe der Tab-Taste nutzen, sodass Sie nicht die kompletten Datei- oder Verzeichnisnamen manuell eintippen müssen.

**Hinweis**: Für die gesamte Anleitung wird beispielhaft die Domain "testdomain.de" verwendet. Immer, wenn "testdomain.de" erwähnt wird, müssen Sie an diesen Stellen selbstverständlich Ihre Domain angeben.

Diese Anleitung wurde am 03.04.2023 zuletzt überprüft und aktualisiert.

Sind Sie auf der Suche nach sehr guten, leistungsstarken und günstigen Servern?  
Ich miete meine Server seit über 10 Jahren bei [Contabo](https://contabo.com/de/vps/?fbcid=1030&utm_source=bennetrichter-de&utm_medium=paidreferral&utm_campaign=vps) und kann [Contabo](https://contabo.com/de/vps/?fbcid=1030&utm_source=bennetrichter-de&utm_medium=paidreferral&utm_campaign=vps) sehr empfehlen!

###### **Vorbereitungen**

Bevor Sie mit der eigentlichen Installation von Mailcow beginnen können, müssen Sie erst einige Vorbereitungen treffen, welche hauptsächlich die DNS-Einstellungen Ihrer Domain, die Sie für den Empfang und Versand von E-Mails nutzen möchten, betreffen. Führen Sie dazu die folgenden Schritte durch:

1.  Der Hostname Ihres Servers sollte bestenfalls "**mail**" und der FQDN entsprechend "**mail.testdomain.de**" lauten.
2.  Fügen Sie einen **A-Record** für die Subdomain "**mail**" (**mail.testdomain.de**) hinzu und lassen diesen auf die IP-Adresse des Mailservers zeigen.
3.  Fügen Sie einen **MX-Record** für Ihre Domain hinzu und setzen den Wert auf die soeben angelegte Mail-Subdomain (**mail.testdomain.de**) mit der Priorität 10.
4.  Definieren Sie jeweils einen **CNAME-Record** für die Subdomains "**autodiscover**" sowie "**autoconfig**" und setzen das Ziel beider CNAME-Records ebenfalls auf die Mail-Subdomain (**mail.testdomain.de**).
5.  Fügen Sie nun einen **TXT-Record** für Ihre Domain hinzu und setzen den Wert auf "**v=spf1 mx ~all**", damit der Server, welcher im MX-Record angegeben ist (der Mailserver, auf dem Mailcow installiert wird) zum Senden von E-Mails mit Ihrer Domain als Absender berechtigt wird. Das "**~all**" bedeutet, dass andere Server keine E-Mails von Ihrer Domain senden dürften, aber diese E-Mails trotzdem noch ankämen (Softfail).
6.  Definieren Sie einen **PTR-Record** (Reverse DNS) für die IP-Adresse Ihres Servers und setzen Sie den Wert auf den **FQDN Ihres Servers** (i.d.R. "**mail.testdomain.de**"). Diesen PTR-Record können Sie bei vielen guten Server-Hostern (wie beispielsweise bei [Contabo](https://contabo.com/de/vps/?fbcid=1030&utm_source=bennetrichter-de&utm_medium=paidreferral&utm_campaign=vps)) direkt im Webinterface setzen, bei einigen Anbietern hingegen müssen Sie hierfür eine E-Mail bzw. ein Support-Ticket schreiben.

###### **Installation von Mailcow**

1.  Falls Sie es noch nicht getan haben, laden Sie das Programm "[PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)" herunter.
2.  Verbinden Sie sich mithilfe von [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) via SSH mit Ihrem Root- oder vServer. Hierfür öffnen Sie [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) und geben im Textfeld "Host Name (or IP address)" die Domain oder IP-Adresse Ihres Servers ein. Klicken Sie anschließend unten auf "OK".
3.  Aktualisieren Sie nun Ihre Paketlisten mit dem Befehl `apt update`.
4.  Installieren Sie jetzt möglicherweise verfügbare Updates der auf Ihrem Server bereits installieren Pakete mit dem Befehl `apt upgrade -y`.
5.  Als nächstes installieren Sie Pakete, die für die weiteren Installationen benötigt werden, mit folgendem Befehl: `apt install curl nano git apt-transport-https ca-certificates gnupg2 software-properties-common -y`
6.  Installieren Sie Docker, indem Sie folgende Schritte durchführen:
    1.  Fügen Sie mithilfe des folgenden Befehls den für die Docker-Paketquelle benötigen Key hinzu:  
        **Für Debian:** `curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg`  
        **Für Ubuntu:** `curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg`
    2.  Fügen Sie mit diesem Befehl nun die für die Installation von Docker benötigte Paketquelle hinzu:  
        **Für Debian:** `echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list`  
        **Für Ubuntu:** `echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list`
    3.  Aktualisieren Sie nun erneut Ihre Paketlisten mit dem Befehl `apt update`.
    4.  Installieren Sie nun Docker, indem Sie den Befehl `apt install docker-ce docker-ce-cli -y` ausführen.
7.  Laden Sie nun Docker-Compose mit dem Befehl `curl -L https://github.com/docker/compose/releases/download/v$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose` herunter.
8.  Vergeben Sie mithilfe des Befehls `chmod +x /usr/local/bin/docker-compose` nun noch die Rechte zum Ausführen von Docker-Compose.
9.  Wechseln Sie mit dem Befehl `cd /opt` in das Verzeichnis "/opt"
10.  Laden Sie Mailcow bzw. den Master Branch des entsprechenden Repositorys jetzt mit folgendem Befehl herunter: `git clone https://github.com/mailcow/mailcow-dockerized`
11.  Begeben Sie sich mit dem Befehl `cd mailcow-dockerized` in das Mailcow-Verzeichnis.
12.  Nun muss die Konfigurationsdatei für Mailcow generiert werden. Nutzen Sie hierzu den Befehl `./generate_config.sh`. Sie werden anschließend nach einem FQDN gefragt. Geben Sie hier den FQDN Ihres Servers an (i.d.R. "**mail.testdomain.de**") und bestätigen Sie die Eingabe mit der Enter-Taste. Die Abfrage nach der Zeitzone können Sie einfach mit Enter bestätigen, da standardmäßig "**Europe/Berlin**" erkannt werden sollte. Wählen Sie abschließend den Branch "master", indem Sie "**1**" eingeben und mit Enter bestätigen.
13.  Die Konfigurationsdatei ist nun generiert. Sie können diese mit dem Befehl `nano mailcow.conf` optional anpassen, wenn Sie beispielsweise bereits einen Webserver installiert haben und Sie deswegen die Ports ("**HTTP\_PORT**" und "**HTTPS\_PORT**") des Mailcow-Webservers ändern möchten. Zudem können Sie z.B. den Wert des Parameters "**SKIP\_LETS\_ENCRYPT**" auch auf "**y**" setzen, falls Sie nicht möchten, dass automatisch ein SSL-Zertifikat bei Let's Encrypt beantragt wird. Änderungen an der Konfiguration können Sie speichern, indem Sie **STRG + X, danach die "Y"-Taste und anschließend Enter** drücken.
14.  Laden Sie die für Mailcow benötigten Images mit folgendem Befehl herunter: `docker-compose pull`
15.  Starten Sie den Mailcow-Container nun, indem Sie den Befehl `docker-compose up -d` ausführen.
16.  Mailcow beantragt automatisch ein **Let's Encrypt SSL-Zertifikat** für die Domain, welche als Hostname gesetzt ist ("acme-mailcow"-Container), sofern diese Funktion nicht explizit über die Konfigurationsdatei deaktiviert wurde. Somit können Sie das Mailcow-Webinterface per HTTPS aufrufen. Um HTTP-Anfragen automatisch zu HTTPS umzuleiten, führen Sie folgende Schritte durch:
    1.  Erstellen Sie eine Nginx-Konfigurationsdatei mithilfe des Befehls `nano /opt/mailcow-dockerized/data/conf/nginx/redirect.conf`.
    2.  Fügen Sie in diese Konfigurationsdatei nun folgenden Inhalt ein:
        
        `server {     root /web;     listen 80 default_server;     listen [::]:80 default_server;     include /etc/nginx/conf.d/server_name.active;     if ( $request_uri ~* "%0A|%0D" ) { return 403; }     location ^~ /.well-known/acme-challenge/ {       allow all;       default_type "text/plain";     }     location / {       return 301 https://$host$uri$is_args$args;     }   }`
        
    3.  Speichern Sie Ihre Änderungen der Konfiguration, indem Sie **STRG + X, danach die "Y"-Taste und anschließend Enter** drücken.
    4.  Starten Sie Nginx daraufhin neu, indem Sie den Befehl `docker-compose restart nginx-mailcow` ausführen. Nun werden HTTP-Anfragen automatisch zu HTTPS umgeleitet.

###### **Einrichtung von Mailcow**

1.  Rufen Sie das Mailcow-Webinterface unter der Domain Ihres Servers im Browser via HTTPS auf. Falls Sie den Webserver-Port in der Konfigurationsdatei geändert haben, müssen Sie diesen nun natürlich mit angeben (z.B. "**https://mail.testdomain.de:4433**").
2.  Loggen Sie sich mit dem Benutzernamen "**admin**" und dem Passwort "**moohoo**" ein.
3.  Klicken Sie oben im Menü auf "**System**" und dann auf "**Konfiguration**".
4.  Klicken Sie nun unter "**Administrator bearbeiten**" rechts neben der Zeile des Benutzers "**admin**" auf "**Bearbeiten**".
5.  Ändern Sie das Passwort des Administrator-Benutzers und passen Sie, wenn gewünscht, auch den Benutzernamen an. Klicken Sie danach auf den Button "**Änderungen speichern**".
6.  Wechseln Sie nun zur E-Mail Konfiguration, indem Sie oben auf "**E-Mail**" und anschließend auf "**Konfiguration**" klicken.
7.  Der Reiter "**Domains**" ist bereits ausgewählt. Fügen Sie hier Ihre Domain durch einen Klick auf den Button "**Domain hinzufügen**" hinzu. Geben Sie im Dialog, welcher erscheint, die Domain im Textfeld "**Domain**" und eine Beschreibung im Textfeld "**Beschreibung**" an. Die restlichen Einstellungen (z.B. die maximale Anzahl oder Größe der Postfächer) können Sie anpassen, jedoch sollten die Standard-Werte i.d.R. ausreichend sein. Klicken Sie anschließend auf den Button "**Domain hinzufügen und SOGo neustarten**".
8.  Wechseln Sie zum Reiter "**Mailboxen**", klicken Sie dort erneut auf "**Mailboxen**" und fügen mithilfe des Buttons "**Mailbox hinzufügen**" eine neue Mailbox (Postfach) hinzu. Dabei müssen Sie folgende Angaben machen:
    
    *   **Benutzername**: Linker Teil der E-Mail Adresse (vor dem "@")
    *   **Domain**: Domain, zu der das Postfach gehört
    *   **Vor- und Nachname**: Vor- und Nachname des Postfach-Nutzers
    *   **Speicherplatz (MiB)**: Speicherplatz für das Postfach (standardmäßig 3072 MiB)
    *   **Passwort**: Passwort des Postfach-Nutzers
    
    Klicken Sie daraufhin auf den Button "**Hinzufügen**", um das Postfach zu erstellen.
9.  Mailcow ist nun grundsätzlich eingerichtet. Es ist jedoch empfehlenswert, weitere Konfigurationen wie z.B. die **DKIM-Konfiguration** durchzuführen. Die DKIM-Konfiguration wird in dieser Anleitung im nächsten Schritt erklärt. Für weitere Informationen ist u.a. die [Dokumentation von Mailcow](https://docs.mailcow.email/) hilfreich.

###### **DKIM-Konfiguration**

1.  Loggen Sie sich in das Mailcow-Webinterface ein und klicken Sie oben im Menü auf "**System**" und anschließend auf "**Konfiguration**".
2.  Klicken Sie auf den Reiter "**Einstellungen**" und danach auf "**ARC/DKIM-Keys**"
3.  Für jede konfigurierte Domain wird bereits automatisch ein DKIM-Key mit dem Selektor "dkim" und einer Schlüssellänge von 2048 Bit generiert. Kopieren Sie den Inhalt der Textbox oben (Public-Key passend zur Domain, beginnend mit "v=DKIM1;k=rsa;t=s;s=email;p=") unter "**ARC/DKIM-Keys**".
4.  Fügen Sie abschließend einen TXT-Eintrag für "**dkim.\_domainkey.testdomain.de**" (passend zum gewählten DKIM-Selektor) in den DNS-Einstellungen Ihrer Domain hinzu und setzen Sie den vorhin kopierten Inhalt aus der Textbox als Wert des TXT-Eintrags.

###### **Nutzung des Webmail-Clients "SOGo"**

Mailcow liefert - unabhängig von der Möglichkeit, normale E-Mail Clients wie Thunderbird, Outlook o.ä. zu nutzen - praktischerweise direkt einen Webmail-Client mit. Somit können Sie Ihre E-Mails folgendermaßen auch direkt im Browser abrufen:

1.  Klicken Sie im Menü des Mailcow-Webinterfaces oben auf "**Apps**" und dann auf "**Webmail**" oder rufen Sie den Webmail-Client direkt auf, indem Sie an die Domain Ihres Servers "**/SOGo**" anhängen.
2.  Loggen Sie sich nun ein. Geben Sie hierfür als Benutzernamen die vollständige E-Mail Adresse des Postfachs und als Passwort das entsprechende Passwort ein.
3.  Sie sollten im Posteingang bereits eine E-Mail sehen (Erstellung eines persönlichen Kalenders) und können den Webmail-Client nun verwenden.

###### **Einrichtung in E-Mail Clients (z.B. Thunderbird)**

Sie können Ihrer Postfächer natürlich auch zu herkömmlichen E-Mail Clients wie beispielsweise Thunderbird, Outlook oder Apple Mail hinzufügen. Im Normalfall müssen Sie nur den **Benutzernamen** (E-Mail Adresse des Postfachs) und das **Passwort** angeben, die Server-Einstellungen sollten automatisch ermittelt werden. Falls dies nicht funktioniert, dann verwenden Sie die folgenden Server-Einstellungen:



* Server: Posteingangsserver
  * Protokoll: IMAP
  * Server-Adresse: FQDN des Mailservers (i.d.R. mail.testdomain.de)
  * Port: 993
  * SSL: SSL/TLS
  * Authentifizierung: Passwort, normal
* Server: Postausgangsserver
  * Protokoll: SMTP
  * Server-Adresse: FQDN des Mailservers (i.d.R. mail.testdomain.de)
  * Port: 587
  * SSL: STARTTLS
  * Authentifizierung: Passwort, normal
