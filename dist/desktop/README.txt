Permit Management System - Desktop Application
==============================================

Installation Instructions:
--------------------------

Linux:
- Ubuntu/Debian: sudo dpkg -i *.deb
- CentOS/RHEL: sudo rpm -i *.rpm
- Or run the executable directly: ./PermitManagement/bin/PermitManagement

macOS:
- Double-click the .dmg file and drag to Applications
- Or run the executable: ./PermitManagement.app/Contents/MacOS/PermitManagement

Windows:
- Double-click the .msi file to install
- Or run the executable: PermitManagement.exe

Configuration:
--------------
The application will connect to your Permit Management System server.
Default server: http://localhost:8081

To change the server URL, edit the configuration file:
- Linux: ~/.config/PermitManagement/config.properties
- macOS: ~/Library/Application Support/PermitManagement/config.properties
- Windows: %APPDATA%/PermitManagement/config.properties

Add the line: server.url=https://your-server.com

System Requirements:
-------------------
- Java 17 or higher (included in installer packages)
- 512MB RAM minimum
- 100MB disk space
- Network connection to server

Support:
--------
For support and documentation, visit:
https://github.com/yourusername/permitmanagementsystem
