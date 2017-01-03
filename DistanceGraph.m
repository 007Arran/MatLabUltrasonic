% This creates the arduino and tells MATLAB the port it is located and any
% extra libraries needed to run this script.  By using this it tells MATLAB
% to look at HCSR04.m (under toolboxes and the addon for the sensnsor)
% for functions like readDistance() and readTravelTime()
a = arduino('COM3', 'Uno', 'Libraries', 'JrodrigoTech/HCSR04');

% Creates sensor object and tells it what library to use and which pins are
% used, Trigger (Green) then Echo
sensor = addon(a, 'JRodrigoTech/HCSR04', 'D10', 'D11'); 
oldDist = 0;
% Shows graph that displays where object is located 
for i = 0:200
    % Use readTravelTime() as it is more accurate than readDistance()
    mDist = readTravelTime(sensor);
    mDist = (mDist*340)/2; % distance in meters
    distIN = mDist/.0254; % distance in inches
%     sprintf('The distance in meters is %.4f\n', mDist)
%     sprintf('The distance in inches is %.4f', distIN)
    pause(.01);
    
    x = distIN*ones(1,20);
    y = 0:19;
    plot(x,y, 'LineWidth', .5)
    xlim([0 10]);
    ylim([0 10]);
    xlabel('Distance from Sensor in inches')
    drawnow;
 
end

% Test that displays how thing is moving
for i = 0:10
    % Use readTravelTime() as it is more accurate than readDistance()
    mDist = readTravelTime(sensor);
    mDist = (mDist*340)/2; % distance in meters
    distIN = mDist/.0254; % distance in inches
    % sprintf('The distance in meters is %.4f\n', mDist)
    if i == 0
        ;
    else 
        if oldDist >= distIN+(distIN*.1)
            sprintf('Moving Towards')
        elseif oldDist <= distIN-(distIN*.1)
            sprintf('Moving Away')
        else
            sprintf('Not Moving')
        end
    end
    oldDist = distIN;
    %has to be a slow repeat or your 10% movement is too small to do
    %anything
    pause(.5);
end

writeDigitalPin(a, 'D13', 0);
% Light that shows when thing is moving
for i = 0:20
    % Use readTravelTime() as it is more accurate than readDistance()
    mDist = readTravelTime(sensor);
    mDist = (mDist*340)/2; % distance in meters
    distIN = mDist/.0254; % distance in inches
    % sprintf('The distance in meters is %.4f\n', mDist)
    if i == 0
        ;
    else 
        if oldDist >= distIN+(distIN*.1)
            writeDigitalPin(a, 'D13', 1);
        elseif oldDist <= distIN-(distIN*.1)
            writeDigitalPin(a, 'D13', 1);
        else
            writeDigitalPin(a, 'D13', 0);
        end
    end
    oldDist = distIN;
    %has to be a slow repeat or your 10% movement is too small to do
    %anything
    pause(.5);
end

clear;

