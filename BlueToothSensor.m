% Bluetooth Sensor

% 11 RXD
% 10 TXD

%creat a bluetooth object
%HC-05 channel default is 1 
b = Bluetooth('HC-05',1);
fopen(b);

%write and read function
fwrite(b,Bluetooth_Write,'uchar');
Bluetooth_Read=fgets(b);
%close and clear
fclose(b);
clear(b); 