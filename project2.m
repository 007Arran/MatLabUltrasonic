% combination lock
function project2
    NUM_COMBO_VALUES = 6;
    TIME_BETWEEN_COMBO_VALUES = 1.5;

    % setup arduino
    if ~exist('a','var')
        % Add the library for the Ultrasonic Sensor
        a = arduino('COM3', 'Uno', 'Libraries', 'JrodrigoTech/HCSR04');
    end
    
    % Test to see if there is already a combo, if not then set to all zeros
    if ~exist('combination','var')
        combination = zeros(1, NUM_COMBO_VALUES);
    end
    configurePin(a, 'D12', 'pullup');
    
    % Start the unlocking sequence
    main_loop(a, combination, NUM_COMBO_VALUES, TIME_BETWEEN_COMBO_VALUES);
end

function main_loop(a, combination, NUM_COMBO_VALUES, TIME_BETWEEN_COMBO_VALUES)
    % Combo is incorrect until it is
    num_incorrect_attempts = 0;
    correct_combo = false;
    % Infinite loop for testing at all times
    while(true)
       % See if open command as been given to start the unlock process
       combo_command = read_combo_command(a);
       % continue looping until the user presses the button
       if (combo_command) 
           continue;
       end
       
       setting_combo = false;
       % if the user has previously entered a correct combo and holds down the button, choose to set the combo
       if correct_combo  
           pause(0.3);
           button_pressed = readDigitalPin(a, 'D12');
           if (button_pressed == 0)
               setting_combo = true;
           end
       end
       
       % Display combo setting or credential verification
       if setting_combo
           disp('Setting combo');
       else
           disp('Initiate credential verification');
       end
       
       % Setting a new combo
       new_combo = set_evaluate_combo(a, setting_combo, combination, NUM_COMBO_VALUES, TIME_BETWEEN_COMBO_VALUES);
       if new_combo(1) ~= -1 % if the error code is NOT present, set the combo/accept the credentials
           if setting_combo
               combination = new_combo; % set the new combo
           else
               correct_combo = true; % accept credentials
           end
       else
           correct_combo = false;
           num_incorrect_attempts = num_incorrect_attempts + 1;
           if num_incorrect_attempts > 2
              num_incorrect_attempts = 0;
              disp('Too many wrong attempts. Please try again in three minutes.');
              for i=0:180 % wait three minutes
                  pause(1);
                  fprintf('%d seconds waited\n', i);
              end
           end
       end
    end
end

% Used in setting combo, will not change
function command_given = read_combo_command(a)
    button_pressed = readDigitalPin(a, 'D12');
    if button_pressed == 1
        command_given = true;
    else
        command_given = false;
    end
end

function combination = set_evaluate_combo(a, setting_combo, combination, NUM_COMBO_VALUES, TIME_BETWEEN_COMBO_VALUES)
    % read in the combination/set values
    i = 1;
    correct_combo = true;
    while(i < NUM_COMBO_VALUES + 1)
        pause(TIME_BETWEEN_COMBO_VALUES);   
        voltage = floor(readVoltage(a, 'A0'));
        if setting_combo
            combination(i) = voltage;
        else
            if (voltage ~= combination(i))
                correct_combo = false;
            end
        end
        disp(voltage);
        i = i + 1;

        % Blue LED
        writeDigitalPin(a, 'D11', 1);
        pause(0.1);
        writeDigitalPin(a, 'D11', 0);
    end
    
    if ~setting_combo
       if correct_combo
           disp('Credentials accepted');
           % Set up the sensor
           sensor = addon(a, 'JRodrigoTech/HCSR04', 'D2', 'D3');
           % Give user 5 seconds to unlock door
           t = 0;
               
           while t < 12
               % Get distance in inches
               mDist = readTravelTime(sensor);
               mDist = (mDist*340)/2; % distance in meters
               distIN = mDist/.0254; % distance in inches
               x = distIN*ones(1,20);
               y = 0:19;
               plot(x,y, 'LineWidth', .5)
               xlim([0 10]);
               ylim([0 10]);
               xlabel('Distance from Sensor in inches')
               drawnow;
               % Break the loop if unlocked
               if distIN < 5 && distIN > 1
                   break;
               end
               
               pause(0.5)
               t = t+1;
           end
           % Unlock the door (Green LED)
           writeDigitalPin(a, 'D7', 1);
           writeDigitalPin(a,'D4',1)
           % Pause and then relock the door
           pause(5)
           writeDigitalPin(a,'D4',0)
           writeDigitalPin(a, 'D7', 0);
           
       else
           disp('Credentials rejected');
           combination(1) = -1; % set the first integer to -1 as an error code
           % Flash red LED
           for i = 0:5
               writeDigitalPin(a, 'D8', 1)
               pause(0.1)
               writeDigitalPin(a, 'D8', 0)
               pause(0.1)
           end
           
       end
    else
        disp('Credentials set');
    end
end
