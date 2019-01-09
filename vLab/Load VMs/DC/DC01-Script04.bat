w32tm /config /computer:dc01.plab.varandas.com /manualpeerlist:time.windows.com /syncfromflags:manual /update
sc config srv start=demand
pause