clear;

a = arduino('COM3','Uno');

% for i = 1:15
%     writeDigitalPin(a,'D11',1);
%     pause(.5);
%     writeDigitalPin(a,'D11',0);
%     pause(1);
%     writeDigitalPin(a, 'D8', 1);
%     pause(1)
%     writeDigitalPin(a, 'D8', 0);
%     pause(.5)
% end

time = 100;
while time > 0
    % Read if the button is closed
    d = readDigitalPin(a,'D2');
    % When the button is pushed, power pin 8
    if d == 1
        writeDigitalPin(a,'D8',1);
    end
    % When the button is let go of, cut power to pin 8
    if d == 0
        writeDigitalPin(a,'D8',0);
    end
    % Iterate Time
    time = time - 1;
    pause(0.1);
end
