%{
    This script loads the excel files from the directory selected by the 
    user and performs following operations:
        1)  Loops through excel file for each worm in each trial.
        2)  Calculates the velocities of the worms for the entire period of
            time.
        3)  Calculates the average velocities and standard deviation for
            each of the worms and saves these results to excel files.
%}

clc;clear all;close all

% Load files from the directory
parent = './../good_trials';
files = dir(parent);

% Initialization params
concentrations = [{'5mM'};{'2mM'};{'1mM'};{'100uM'};{'10uM'}];
stages = [{'pre'};{'post'};{'rec'}];

[c,~] = listdlg('PromptString','Select a drug concentration',...
                'SelectionMode','single',...
                'ListString',concentrations);
c = concentrations{c};

[s,~] = listdlg('PromptString','Select a drug concentration',...
                'SelectionMode','single',...
                'ListString',stages);
s = stages{s};
index = 1;
comparison = ['\w+',c,'\w+',s,'\w+','excel'];
totaldata = 0;
average_velocities = [];
ave_std = cell(3,2);
ave_std(1,1) = {'Average'};
ave_std(2,1) = {'Std'};
ave_std(3,1) = {'Data Points'};
padding = 0;
data = [];
velocity = [];

% Loop through all the excel files in the directory
for i = 1:length(files)
    % Validate excel files by pattern matching
    if(regexp(files(i).name,comparison))
        subfiles = dir([parent,'/',files(i).name]);
        for j = 1:length(subfiles)
            if(regexp(subfiles(j).name,'\w+.txt'))
                % Process each excel file listed in the text file
                h = readtable([parent,'/',files(i).name,'/',...
                    subfiles(j).name],'delimiter','\t');

                % Loop through each worm
                data = [data,NaN(600,2*width(h))];
                velocity = [velocity,NaN(599,2*width(h))];
                for k = 1:width(h)
                    % Loop through each excel file for each worm and load
                    % data into arrays
                    for z = 1:height(h)
                        file_num = num2str(h{z,k});
                        for m = 1:length(subfiles)
                            if(regexp(subfiles(m).name,['\w+','worm',...
                                    file_num,'.xls']))
                                [~,~,raw] = xlsread([parent,'/',...
                                    files(i).name,'/',subfiles(m).name],...
                                    'A1:B600');
                                for y = 1:length(raw)
                                    if(~isnan(raw{y,1}))
                                        data(y,padding+k*2-1) = raw{y,1};
                                        data(y,padding+k*2) = raw{y,2};
                                    end
                                end
                            end
                        end
                    end
                    % Calculate the velocities of the worms
                    for z = 1:length(data)-1
                        if(~isnan(data(z,padding+k*2)) && ...
                                ~isnan(data(z+1,padding+k*2)))
                            velocity(z,padding+k*2-1) = sqrt((...
                                data(z,padding+k*2-1)...
                                -data(z+1,padding+k*2-1))^2 + ...
                                (data(z,padding+k*2)- ...
                                data(z+1,padding+k*2))^2);
                            totaldata = totaldata + 1;
                            if(velocity(z,padding+k*2-1)>10)
                                velocity(z,padding+k*2-1)=10;
                            end
                        end
                    end
                    % Calculate the average velocities of the worms
                    velocity(1,padding+k*2) = mean(velocity...
                        (~isnan(velocity(:,padding+k*2-1)),...
                        padding+k*2-1));
                    average_velocities = [average_velocities,...
                        velocity(1,padding+k*2)];
                end
 
                padding = padding + 2*width(h);
            end
        end 
    end
end

% Calculate the mean and standard deviation of the average velocities
ave_std(1,2) = {mean(average_velocities)};
ave_std(2,2) = {std(average_velocities)};
ave_std(3,2) = {totaldata};

% Save the reuslts to excel files
xlswrite([parent,'/Results/',c,'_',s,'_total.xls'],...
                num2cell(data),'Position');
xlswrite([parent,'/Results/',c,'_',s,'_total.xls'],...
                num2cell(velocity),'Velocity');
xlswrite([parent,'/Results/',c,'_',s,'_total.xls'],...
                num2cell(average_velocities),'Ave Velocity');
xlswrite([parent,'/Results/',c,'_',s,'_total.xls'],ave_std,'Summary');

% Handle empty data exceptions
if(~isempty(average_velocities))
    disp(['Total length of data ',num2str(totaldata)]);
    disp(['Average velocity ',num2str(mean(average_velocities))]);
    disp(['Standard deviation ',num2str(std(average_velocities))]);
else
    disp('Total length of data 0');
end

