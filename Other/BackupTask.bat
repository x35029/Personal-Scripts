robocopy e: j:\backup_2 /MIR /R:3 /W:10 /XF *.db *.!ut *.dat /XA:SHT /xd E:\backup_data\Media E:\$RECYCLE.BIN\ "E:\System Volume Information" /log:"C:\Users\rodri\OneDrive\Dev\Logs\backup_2.txt"
robocopy d: e:\backup_data /MIR /R:3 /W:10 /XF *.db *.!ut *.dat /XA:SHT /xd D:\Lab D:\Programs D:\Game D:\Plex D:\$RECYCLE.BIN\ "D:\System Volume Information" /log:"C:\Users\rodri\OneDrive\Dev\Logs\backup_data.txt"
robocopy D:\Game\Local e:\backup_games /MIR /R:3 /W:10 /XF *.db *.!ut *.dat /XA:SHT /log:"C:\Users\rodri\OneDrive\Dev\Logs\backup_games.txt"
@powershell C:\Users\rodri\Documents\GitHub\Scripts\vLab\Backup-VM.ps1
#powershell C:\Users\rodri\Dropbox\Dev\Scripts\Powershell\fullnamedump.ps1
#powershell C:\Users\rodri\Dropbox\Dev\Scripts\Powershell\installedApps.ps1
#robocopy D:\Estudos\Concurso\ C:\Users\rodri\Dropbox\Concurso\ *.pdf /xo /e /R:3 /W:10 /log:"C:\Users\rodri\Dropbox\Dev\Logs\backup_concursos.txt"
#robocopy D:\Estudos\Concurso R:\Estudos\Concurso /MIR /R:3 /W:10 /XF *.db *.!ut *.dat /XA:SHT /log:"C:\Users\rodri\Dropbox\Dev\Logs\backup_mat_concursos.txt"