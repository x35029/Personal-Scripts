w32tm /config /computer:dc1.vlab.varandas.com /manualpeerlist:time.windows.com /syncfromflags:manual /update
sc config srv start=demand
pause