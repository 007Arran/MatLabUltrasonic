% Unlock Sensing with ultrasonic Sensor
clear;

a = arduino('COM3', 'Uno', 'Libraries', 'JrodrigoTech/HCSR04');
% D11 is for Trig
% D10 is for Echo
sensor = addon(a, 'JRodrigoTech/HCSR04', 'D11', 'D10');

count = 0;
while(true)
    mDist = readTravelTime(sensor);
    mDist = (mDist*340)/2; % distance in meters
    distIN = mDist/.0254; % distance in inches
    if distIN < 5 && distIN > 1
        count = count+1;
        fprintf('Unlocked %f \n', count)
    end
end
