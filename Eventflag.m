%% event= Eventflag(Event,Task,Run,Trial,runStart)
%% This function creates formated flags for events during eyetracking experiments.
% takes input of Run and trial as number values
%requires ENUM- GenFlags 

function event= Eventflag(Event,Task,Run,Trial,runStart)
tmpRun=0;
tmpTrial=0;

tmpRun(3-floor(log10(Run)))=Run;
Run= regexprep(num2str(tmpRun),'[^\w'']',''); % creates run string whithout spaces 

tmpTrial(3-floor(log10(Trial)))=Trial;
Trial= regexprep(num2str(tmpTrial),'[^\w'']',''); % creates Trial string whithout spaces 

Trial=num2str(Trial);
event=['flag_',Event,'_Task',Task,'_Run',Run,'_Trial',Trial,'_Time',num2str(GetSecs-runStart)];

end