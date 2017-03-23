% combination lock
function project2
    NUM_COMBO_VALUES = 6;
    TIME_BETWEEN_COMBO_VALUES = 1.5;
    % Create and open a results file for data logging
    file = 'results.txt';
    file = fopen('results.txt','w');

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
    main_loop(a, combination, NUM_COMBO_VALUES, TIME_BETWEEN_COMBO_VALUES, file);
end

function main_loop(a, combination, NUM_COMBO_VALUES, TIME_BETWEEN_COMBO_VALUES, file)
    % Attempt counts for the data file
    total_incorrect_attempts = 0;
    total_correct_attempts = 0;
    num_incorrect_attempts = 0;
    
    % Combo is set to incorrect by default; it must be verified to become
    % correct
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
       
       % Display combo setting if button has been held down long enough, else start credential verification
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
               % Tally correct attempts and accept credentials
               total_correct_attempts = total_correct_attempts + 1;
               correct_combo = true; % accept credentials
           end
       else
           % Tally incorrect attempts and lock out user if wrong too many times
           correct_combo = false;
           total_incorrect_attempts = total_incorrect_attempts + 1;
           num_incorrect_attempts = num_incorrect_attempts + 1;
           if num_incorrect_attempts > 2
              num_incorrect_attempts = 0;
              disp('Too many wrong attempts. Please try again in three minutes.');
              fprintf(file, 'Lockout initiated/n');
              for i=0:180 % wait three minutes
                  pause(1);
                  fprintf('%d seconds waited\n', i);
              end
           end
       end
       % print stat-keeping information at the end of each iteration
       fprintf(file, 'Current combination: ');
       fprintf(file, '%d', combination);
       fprintf(file, '\nTotal correct attempts: %d, total incorrect attempts: %d\n', total_correct_attempts, total_incorrect_attempts);
    end
end

% Used for setting a combo
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
        % Read voltage from potentiometer for combo number
        voltage = floor(readVoltage(a, 'A0'));
        % Save the new combination
        if setting_combo
            combination(i) = voltage;
        % Test if each number matches the combination
        else
            if (voltage ~= combination(i))
                correct_combo = false;
            end
        end
        
        % Made with help from eewriter on EEStuffs.com
        % Plotting the real time data for the potentiometer
        % Time for each value of the combination
        tmax = 1.5; 
        % Creating and labeling the plot
        figure(1),
        xlabel ('Time (s)'), ylabel('Voltage');
        axis([0 2 -.25 6]);

        % setting starting values
        k = 0;  %index
        v = 0;  %voltage
        t = 0;  %time

        tic % Start timer
        while toc <= tmax
            k = k + 1;
            v(k) = readVoltage(a,'A0');
            t(k) = toc;

            % Plotting the Data
            if k > 1
                line([t(k-1) t(k)],[v(k-1) v(k)]);
                drawnow;
            end

        end

        disp(voltage);
        % Clear the figure after each number inputted
        clf;
        i = i + 1;

        % Light Blue LED when number for combo is read
        writeDigitalPin(a, 'D11', 1);
        pause(0.1);
        writeDigitalPin(a, 'D11', 0);
    end
    
    if ~setting_combo
       if correct_combo
           disp('Credentials accepted');
           % Set up the Ultrasonic sensor
           sensor = addon(a, 'JRodrigoTech/HCSR04', 'D2', 'D3');
           % Set time variable used below
           t = 0;
           % Give user 5.5 seconds to unlock door
           while t < 12
               % Get distance in inches
               mDist = readTravelTime(sensor);
               mDist = (mDist*340)/2; % distance in meters
               distIN = mDist/.0254; % distance in inches
               % Create things to plot
               x = distIN*ones(1,20);
               y = 0:19;
               % Plot the Ultrasonic Sensor's Data
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
           % Unlock the door and light the Green LED
           writeDigitalPin(a, 'D7', 1);
           writeDigitalPin(a,'D4',1)
           % Pause and then relock the door and turn off Green LED
           pause(10)
           writeDigitalPin(a,'D4',0)
           writeDigitalPin(a, 'D7', 0);
       % If credentials are wrong    
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
    % If user was setting combination, display that it was correctly saved
    else
        disp('Credentials set');
    end
end
