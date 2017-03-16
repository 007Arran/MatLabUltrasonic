% combination lock
function project2
    NUM_COMBO_VALUES = 4;

    % setup arduino
    if ~exist('a','var')
        a = arduino('com3', 'uno');
    end

    if ~exist('combination','var')
        combination = zeros(1, NUM_COMBO_VALUES);
    end
    configurePin(a, 'D12', 'pullup');
    
    main_loop(a, combination, NUM_COMBO_VALUES);
end

function main_loop(a, combination, NUM_COMBO_VALUES)
    correct_combo = false;
    while(true)
       open_command = read_opening_command(a);
       if (open_command) % continue looping until the user presses the button
           continue;
       end
       
       setting_combo = false;
       if correct_combo % if the user has previously entered a correct combo and holds down the button, choose to set the combo 
           pause(0.1);
            button_pressed = readDigitalPin(a, 'D12');
            if (button_pressed == 0)
                setting_combo = true;
            end
       end
       
       if setting_combo
           disp('Setting combo');
       else
           disp('Initiate credential verification');
       end
       
       new_combo = set_evaluate_combo(a, setting_combo, combination, NUM_COMBO_VALUES);
       if new_combo(1) ~= -1 % if the error code is NOT present, set the combo/accept the credentials
           if setting_combo
               combination = new_combo; % set the new combo
           else
               correct_combo = true; % accept credentials
           end
       else
           correct_combo = false;
       end
    end
end

function command_given = read_opening_command(a)
    % replace -->
    button_pressed = readDigitalPin(a, 'D12');
    if button_pressed == 1
        command_given = true;
    else
        command_given = false;
    end
    % <-- replace
end

function combination = set_evaluate_combo(a, setting_combo, combination, NUM_COMBO_VALUES)
    % read in the combination/set values
    i = 1;
    correct_combo = true;
    while(i < NUM_COMBO_VALUES + 1)
        pause(1);   
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

        writeDigitalPin(a, 'D11', 1);
        pause(0.1);
        writeDigitalPin(a, 'D11', 0);
    end
    if ~setting_combo
       if correct_combo
           disp('Credentials accepted');
       else
           disp('Credentials rejected');
           combination(1) = -1; % set the first integer to -1 as an error code
       end
    else
        disp('Credentials set');
    end
end