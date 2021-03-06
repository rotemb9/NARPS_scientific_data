%% Modified by Roni Iwanir - March 2017
% added output file
% changed screen color to gray
% added "condition" input
%%
%function MixedGamblesTask(sub_id,run_number,inputDevice,experimenter_device,Scan)
clear all; %%%NEW

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 0);  %%%NEW

sub_id=input('Enter subject Number: ','s');
Scan=1;% MRI

if Scan==1
    run_number=input('Enter run number (1-4): '); 
    while run_number<1 || run_number>4
        run_number=input('INVALID ENTRY - Enter run number (1-4): ');
    end
else
    run_number=1;
end

WorkingDir=pwd;
okEyeTracker = [0 1];

use_eyetracker = input('Do you want eyetracker (1-yes, 0-no)?: ');
while isempty(use_eyetracker) || sum(okEyeTracker==use_eyetracker)~=1
    disp('ERROR: input must be 0 or 1 . Please try again.');
    use_eyetracker = input('Do you want eyetracker (1-yes, 0-no)?: ');
end
fprintf(['\n\nsubjectID is: ' num2str(sub_id) '\n']);
fprintf(['Run # is: ' num2str(run_number) '\n']);
fprintf(['Scan is: ' num2str(Scan) '\n']);
disp(['use eyetracker is: ' num2str(use_eyetracker)]);
fprintf('\n')

GoOn=input('are all variables ok? (1-yes, 0-no)');
if GoOn==0
    error('please check you numbers and start again')
end

%%
[script_name]='Mixed-Gambles Task'; %Risk Acceptability'; % 4 runs decision only: by Sabrina Tom, modified by Eliza Congdon
script_version=3'; % behav version 1, scan version 2 (EC), 3 for DEMO
revision_date='13-03-17'; % FOR SCANNING (EC)

fprintf('%s %s (revised %s)\n',script_name, script_version, revision_date);

%%  read in subject information

ConditionNames={'equalRange','equalIndifference'};

%Assigns condition for the 4 runs
SubNum=str2double(sub_id(end-1:end));
SubNumStr='100';
SubNumStr(end-floor(log10(SubNum)):end)=num2str(SubNum);
Condition=mod(SubNum,2); % assigns prospects matrix
Order=mod(ceil(SubNum/2),8)+1; % assigns randomization
gain_side=mod(Order,2)+1;
Task='MGT'; % 

%% Load Hebrew instructions image files
%  --------------------------------------------
if Scan==1 % MRI
    Instructions=dir([WorkingDir '/Instructions/*MGT.jpg']);
else % DEMO
    Instructions=dir([WorkingDir '/Instructions/*MGT_demo.jpg']);
end

Trigger = dir([WorkingDir '/Instructions/Trigger.jpg' ]);
Trigger_image = imread([WorkingDir '/Instructions/' Trigger(1).name]);
Instructions_name=struct2cell(rmfield(Instructions,{'date','bytes','isdir','datenum'}));
Instructions_image=imread([WorkingDir '/Instructions/' sprintf(Instructions_name{1})]);


%% write trial-by-trial data to a text logfile
c=clock;
hr = sprintf('%02d', c(4));
minutes = sprintf('%02d', c(5));
timestamp = [date,'_',hr,'h',minutes,'m'];

Current_folder=WorkingDir;


% Assign output folders
if Scan==1 % MRI
    logsFolder=[Current_folder '/logs/'];
    OutputsFolder=[Current_folder '/Outputs/'];
else
    logsFolder=[Current_folder '/logs/demo/'];
    OutputsFolder=[Current_folder '/Outputs/demo/'];
end

logfile=[logsFolder sprintf('NRPS_sub-%s.log',SubNumStr)];
OutputFile=[OutputsFolder sprintf('sub-%s_task-%s_run-0%d.txt',SubNumStr,Task,run_number)];


fprintf('A log of this session will be saved to %s\n',logfile);
fid1=fopen(logfile,'a');
if fid1<1       %%%%NEW
    error('could not open logfile!');
end            %%%%NEW

fprintf(fid1,'\n\n\n\n%s %s (revised %s)\n',script_name,script_version, ...
    revision_date);
fprintf(fid1,'Run #%d\nStarted: %s %2.0f:%2.0f\n',run_number,date,c(4),c(5));
fid2=fopen(OutputFile,'W'); % formated output file
fprintf(fid2,'subjectID\tCondition\tOrder\tRunNum\tTrialNum\tonsettime\tTrialStart\tWinSum\tLoseSum\tGainSide\tRT\tResponseKey\tResponse\tBinaryResp\n'); %write the header line

fprintf('Setting up the screen - this may take several seconds...\n');
WaitSecs(1);

if run_number>4
    run_number=run_number-4;
end

%% reads list of prospect numbers to present for each of 4 runs (according to experimental condition).
if Condition==1
    load('equalIndifference_design.mat');
else
    load('equalRange_design.mat');
end



%% setting up stuff (standard to all programs)
%  % pixelSize=32;

stim_duration=4;
delay=0.5;

screennum = min(Screen('Screens'));
%[w] = Screen('OpenWindow',screennum,[],[0 0 900 600],32); %debug Screen
[w, screenRect] = Screen(screennum,'OpenWindow',[],[],32);
HideCursor;

black=BlackIndex(w); % Should equal 0.
gray=WhiteIndex(w)/2;
white=WhiteIndex(w); % Should equal 255.
green=[0 210 0]; %0 220 0
red=[240 0 0];

% set up screen positions for stimuli
[wWidth, wHeight]=Screen('WindowSize', w); %new command taken from naomi's script.
xcenter=wWidth/2;
ycenter=wHeight/2;

Screen('FillRect', w, gray); %creates blank, Gray screen
Screen('Flip', w);

stim_rect=[xcenter-180 ycenter-180 xcenter+180 ycenter+180];
%spin_screen=Screen('OpenOffscreenWindow',w,white, screenRect);
Screen('TextSize',w,48);
Screen('TextFont',w,'Arial');

%% Initializing eye tracking system %
%-----------------------------------------------------------------
% use_eyetracker=1; % set to 1/0 to turn on/off eyetracker functions
if use_eyetracker
    dummymode=0;
    
    % STEP 2
    % Provide Eyelink with details about the graphics environment
    % and perform some initializations. The information is returned
    % in a structure that also contains useful defaults
    % and control codes (e.g. tracker state bit and Eyelink key values).
    el=EyelinkInitDefaults(w);
    % Disable key output to Matlab window:
    
    el.backgroundcolour = gray;
    el.backgroundcolour = gray;
    el.foregroundcolour = white;
    el.msgfontcolour    = white;
    el.imgtitlecolour   = white;
    el.calibrationtargetcolour = el.foregroundcolour;
    EyelinkUpdateDefaults(el);
    
    % STEP 3
    % Initialization of the connection with the Eyelink Gazetracker.
    % exit program if this fails.
    if ~EyelinkInit(dummymode, 1)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end
    
    [v,ELversion]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', ELversion );
    
    % make sure that we get gaze data from the Eyelink
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,HREF,AREA');
    
    % open file to record data to

    edfFile=[Task,'','.edf'];
    Eyelink('Openfile', edfFile);
    
    % STEP 4
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    
    % do a final check of calibration using driftcorrection
    EyelinkDoDriftCorrection(el);
    
    %     % STEP 5
    %     % start recording eye position
    %     Eyelink('StartRecording');
    %     % record a few samples before we actually start displaying
    %     WaitSecs(0.1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % Finish Initialization %
    %%%%%%%%%%%%%%%%%%%%%%%%%
end


%% define run variables %%%%
%n_blocks=1;
%n_trials=7 % debug
n_trials=length(Prospect{run_number,Order});% should be 64;

if Scan == 0 %If Demo
    n_trials = 4;
end


rt=zeros(n_trials,2); % for each trial, there will 1 row with 2 columns. :,1=absolute start of trial :,2=rt
%reaction time for all trials of block would be rt(:,2)
resp=cell(n_trials,1); % 1 column, 85 rows, each row has one response
resp(:)={'NoResp'};

%
%     %%% FEEDBACK VARIABLES
%     if Scan==1,
%         trigger = KbName('t');
%         strongly_accept = KbName('b');
%         weakly_accept = KbName('y');
%         weakly_reject = KbName('g');
%         strongly_reject = KbName('r');
%
%     else
%         strongly_accept='1';
%         weakly_accept='2';
%         weakly_reject='3';
%         strongly_reject='4';
%     end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get ready to go
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Show Instructions
Screen('PutImage',w,Instructions_image);
Screen(w,'Flip');


noresp = 1;
while noresp
    [keyIsDown] = KbCheck(-1); % deviceNumber=keyboard
    if keyIsDown && noresp
        noresp = 0;
    end
end
if Scan==1 % MRI Scan
  
    fprintf('waiting for trigger...\n');
    Screen('PutImage',w,Trigger_image);
    Screen('Flip',w);
    escapeKey = KbName('t');
    while 1
        [keyIsDown,~,keyCode] = KbCheck(-1);
        if keyIsDown && keyCode(escapeKey)
            break;
        end
    end
    
    fprintf('got it!\n');
   


else % If using the keyboard, allow any key as input
    noresp=1;
    while noresp
        [keyIsDown,secs,keyCode] = KbCheck(-1);
        if keyIsDown && noresp
            noresp=0;
        end
    end
    WaitSecs(1.0);   % prevent key spillover--ONLY FOR BEHAV VERSION
    
end


DisableKeysForKbCheck(KbName('t'));   % So trigger is no longer detected

tic

% -- command doesn't work in OSX? FlushEvents('keyDown');	 % clear any keypresses out of the buffer

% how screen() works:
% first argument: which screen to use (in this case, w, which is the main screen)
% second argument: what to do (in this case, 'DrawText')
% subsequent arguments depend upon what you've chosen to do

% if MRI==1
% noresp=1;
%        while noresp
%            [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
%            if keyIsDown && noresp
% %                tmp=KbName(keyCode); % makes ok to use keyboard collection of 5, otherwise collects 5 but also %
% %                if strcmp(tmp(1),'5') %wait for '5' from trigger to begin
%                noresp=0;
% %                end
%            end
%            WaitSecs(0.001);
%        end


Screen('FillRect', w, gray);
Screen('Flip', w); % copy blank screen onto main window
WaitSecs(4)

showme1 = zeros(64,1);
showme2 = zeros(64,1);
showme3 = zeros(64,1);
showme4 = zeros(64,1);
showme5 = zeros(64,1);
showme6 = zeros(64,1);
%% STEP 2- StartRecording --> 

if use_eyetracker
    % start recording eye position
    %---------------------------
    Eyelink('StartRecording');
    %   Eyelink MSG
    % ---------------------------
    % messages to save on each trial ( trial number, onset and RT)
    
end
    
%pointer- runStart=GetSecs;

%%
run_anchor=GetSecs;

Screen('TextSize',w,52);

%%%%% Present trials for decision only phase

%if run_number<3,    %decision only runs are 1&2
runStart=GetSecs;
if use_eyetracker
    Eyelink('Message', Eventflag(GenFlags.RunStart.str,Task,run_number,1,runStart)); % mark start time in file
end  %Event,Run,Trial,runStart

for trial=1:n_trials
    BinaryResp=0;
    showme6(trial) = GetSecs - run_anchor;
    
    while GetSecs - run_anchor < stimons{run_number,Order}(trial)
    end
    showme1(trial) = GetSecs - run_anchor;
    
    %while GetSecs - run_anchor < stim_onset(t), end; %don't start to execute what follows until the onset time for that trial is reached
    %%%% - need this command? Screen('CopyWindow',blank_screen,spin_screen); %clear screen
    Screen('FillRect', w, gray);
    Screen('Flip', w); % copy blank screen onto main window
    
    showme2(trial) = GetSecs - run_anchor;
    
    if gain_side==1
        %draw gain/loss prospects
        Screen('DrawText',w,sprintf('+%d',Prospect{run_number,Order}(trial,2)),xcenter-150,ycenter-20,green); %gain: for row t (corresponds to trial #) in column 1 (run #)
        Screen('DrawText',w,sprintf('-%d',Prospect{run_number,Order}(trial,3)),xcenter+40,ycenter-20,red); %loss: for row t (corresponds to trial #) in column 1 (run #)
        
        %draw spinner
        Screen('FrameOval',w,black,stim_rect,3,3,[]); %Screen(windowPtr,'FrameOval',[color],[rect],[penWidth],[penHeight],[penMode])
        Screen('DrawLine',w,black,xcenter,ycenter-180,xcenter,ycenter+180,7);
        Screen('Flip',w);
    else %if gain_side==2;
        Screen('DrawText',w,sprintf('-%d',Prospect{run_number,Order}(trial,3)),xcenter-140,ycenter-20,red); %loss on LEFT: for row t (corresponds to trial #) in column 1 (run #)
        Screen('DrawText',w,sprintf('+%d',Prospect{run_number,Order}(trial,2)),xcenter+30,ycenter-20,green); %gain on RIGHT
        
        %draw spinner
        Screen('FrameOval',w,black,stim_rect,3,3,[]); %Screen(windowPtr,'FrameOval',[color],[rect],[penWidth],[penHeight],[penMode])
        Screen('DrawLine',w,black,xcenter,ycenter-180,xcenter,ycenter+180,7);
        Screen('Flip',w);
    end
    showme3(trial) = GetSecs - run_anchor;
    
    if use_eyetracker
        Eyelink('Message', Eventflag(GenFlags.TrialStart.str,Task,run_number,trial,runStart)); % mark start time in file
    end
    
    noresp=1;
    start_time=GetSecs;
    rt(trial,1)=start_time-run_anchor;
    while (GetSecs < start_time + stim_duration)
        [keyIsDown,secs,keyCode] = KbCheck(-1);
        
        if keyIsDown && noresp
            resp(trial)={KbName(keyCode)};
            rt(trial,2)=secs-start_time;
            noresp=0;
            if use_eyetracker
                Eyelink('Message', Eventflag(GenFlags.Response.str,Task,run_number,trial,runStart)); % mark start time in file
            end
            Screen('FillRect', w, gray);
            Screen('Flip', w); % copy blank screen onto main window
        end
       
        WaitSecs(0.1);
    end
    showme4(trial) = GetSecs - run_anchor;  % checked difference between showme4 - showme1 and it equals stim_dur = 4 seconds; Good.
    
    Screen('FillRect', w, gray);
    Screen('Flip', w); % copy blank screen onto main window
if iscell(resp{trial})
    resp{trial}=resp{trial}{1};
end
    switch resp{trial}
        case 'b'
            SubResponse = 'strongly_accept';
            BinaryResp=1;
        case 'y'
            SubResponse = 'weakly_accept';
            BinaryResp=1;
        case 'g'
            SubResponse ='weakly_reject';
            BinaryResp=0;
        case 'r'
            SubResponse ='strongly_reject';
            BinaryResp=0;
        otherwise
            SubResponse ='NoResp';
    end
    % print trial info to logfile
    fprintf(fid1,'%d\t%d\t%0.3f\t%d\t%d\t%0.3f\t%c\n',trial,stimons{run_number,Order}(trial),rt(trial,1),...
        Prospect{run_number,Order}(trial,2),-1*Prospect{run_number,Order}(trial,3),rt(trial,2),char(resp{trial}));
    
    fprintf(fid2,'%s\t%s\t%d\t%d\t%d\t%0.3f\t%0.3f\t%d\t%d\t%d\t%0.3f\t%s\t%s\t%d\n',SubNumStr,ConditionNames{Condition+1},Order,run_number,trial,stimons{run_number,Order}(trial),rt(trial,1),Prospect{run_number,Order}(trial,2),-1*Prospect{run_number,Order}(trial,3),gain_side,rt(trial,2),resp{trial},SubResponse,BinaryResp); %write the header line
    
    
    
    %fprintf('%d\t%s\n',trial,resp{trial});  % print responses to screen
end	%ends trial 'for' loop

if use_eyetracker
    Eyelink('Message', Eventflag(GenFlags.RunEnd.str,Task,run_number,trial,runStart)); % mark start time in file
end
WaitSecs(8) %keep scan going to catch few secs of hrf for last trial.
toc

%% End of Run
fclose('all');
if run_number<4
    EndOfRun=dir( [WorkingDir '/Instructions/*RunEnd.jpg']);
else
    EndOfRun=dir( [WorkingDir '/Instructions/*TaskEnd.jpg']);
end
InstructionsEnd_name=struct2cell(rmfield(EndOfRun,{'date','bytes','isdir','datenum'}));
Instructions_image=imread([WorkingDir '/Instructions/' sprintf(InstructionsEnd_name{1})]);

Screen('PutImage',w,Instructions_image);
Screen(w,'Flip');


%end; %ends main 'if' loop

if use_eyetracker
    
    %---------------------------------------------------------------
    %%   Finishing eye tracking system %
    %---------------------------------------------------------------
    
    % STEP 7
    %---------------------------
    % finish up: stop recording eye-movements,
    % close graphics window, close data file and shut down tracker
    Eyelink('StopRecording');
    WaitSecs(.1);
    Eyelink('CloseFile');
    
    
    % download data file
    try
        fprintf('Receiving data file ''%s''\n', edfFile );
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(edfFile, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
        end
    catch rdf
        fprintf('Problem receiving data file ''%s''\n', edfFile );
        rdf;
    end
    
    eyetracking_filename = [OutputsFolder 'sub-' SubNumStr '_task-' Task '_run-' num2str(run_number) '_' timestamp '.edf'];
    movefile(edfFile,eyetracking_filename);
end

WaitSecs(4) %keep scan going to catch few secs of hrf for last trial.
% Screen('TextSize',w,50);
% Screen('TextFont',w,'Ariel');
% Screen('DrawText',w,'Great Job. Thank you!',xcenter-200,ycenter);
% Screen('Flip',w);

Screen('CloseAll'); % Close all screens, return to mac os platform.





ShowCursor;
