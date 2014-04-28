function [varargout] = reversal_task(varargin)
% Run the REVERSAL TASK
if nargin<1
    varargout=start();
elseif ischar(varargin{1})
    varargout=feval(varargin{1},varargin{2:end});
else
    varargout=expe_trycatch(varargin{:});
end
varargout={varargout};
return


function Passation = start()
%% 1/ Initialize matlab to run the experiment
diary;
%clear('import')
close('all');
clc;
sca;
%figure;

% initialise random number generator
seed = sum(100*clock);
rand('twister',seed);
%randn('state',seed);

% add toolbox to path
taskfolder = fileparts(mfilename('fullpath'));
fprintf('Running in folder: %s\n',taskfolder);
cd(taskfolder);
addpath(taskfolder);
addpath(fullfile(taskfolder,'Toolbox'));
addpath(fullfile(taskfolder,'kndtoolbox'));
addpath(fullfile(taskfolder,'ParPort64'));

set(0,'defaultfigurewindowstyle','docked');

%% Initialize variables etc.
clear('all');
clear('java');
global DEBUG
KbName('UnifyKeyNames');

% Import Task parameters from m file
run('reversal_TaskParameters')

global participant
% Handles various setups on various Machines
participant.date = datestr(now,'yyyymmdd-HHMM');
participant.hostname=hostname();
fprintf('Running on machine: %s\n', participant.hostname);
if isempty(DEBUG)
    DEBUG = false;
end
if any(strcmpi(participant.hostname, DEBUG_machines))
    DEBUG=true;
    fprintf('This is supposed to be a DEBUG machine!\n');
end
if DEBUG
    % shorter timings
    timing.cueduration = 1.5;
    flags.with_response_keyboard = 1;
    if exist('/Users/ndiaye/','dir')
        flags.with_response_lumina = 0;
    end
    selection = 1;
end

participant.identifier = 'TEST';
if ~DEBUG
    % Participant Info
    answer=inputdlg({'Participant ID?'},'Participant',1,{'TEST'});
    if isempty(answer)
        error('Experiment cancelled during setup!');
    end
    participant.identifier = answer{1};
end
if ~DEBUG
    [selection,ok] = listdlg(...
        'PromptString','Select a condition',...
        'SelectionMode','single',...
        'ListString',SESSIONS(:,1), ...
        'ListSize', [ 200 100 ], ...
        'InitialValue', 1+  ...
        0 ... %+(strmatch('perop',SESSIONS(:,2))-1)*strcmp('MALLET-11',participant.hostname)...
        );
    if ~ok
        error('Experiment cancelled!');
    end
end
participant.session = selection;
participant.session_name = SESSIONS{selection,2};

% Flags
participant.flags=flags;
% prompt = fieldnames(flags);
% answer=inputdlg(fieldnames(flags),'flags',1,...
%     arrayfun(@(x) eval(num2str(getfield(flags,x{1})),...
%     fieldnames(flags),'UniformOutput', 0));
% if isempty(answer)
%     error('Experiment cancelled!');
% end
% for i=1:numel(answer)
%     participant.flags.(prompt{i}) = str2double(answer{i});
% end

fprintf('PARTICIPANT INFORMATION:\n\n');
disp(participant);
disp(participant.flags);

%% 3/ Run experiment and save data
Screen('CloseAll');
close('all');

Passation = expe_trycatch(participant);

% save data
save(Passation.Filename,'Passation');
diary off
if ~DEBUG
    % Let the experimenter add some comments?
    Passation.ExpostComments = inputdlg('Ex-post Commentary','Any comments?',5);
    % re-save
    save(Passation.Filename,'Passation')
end

% Export to CSV format
exportCSV(Passation)


% rethrow error message
if ~isempty(Passation.ErrorMsg)
    psychrethrow(Passation.ErrorMsg);
end
diary('OFF')


assignin('base','Passation',Passation);
%% THIS IS THE END

return

function csvfile = exportCSV(Passation)
csvfile=[Passation.Filename '.csv'];
fprintf('Exporting data to: %s\n', csvfile);
fid =fopen(csvfile, 'wt');
[t,h]=Data2tab(Passation.Data);
fprintf(fid,'%s,', h{:});
fprintf(fid,'\n');
fclose(fid);
dlmwrite(csvfile,t, '-append', 'delimiter', ',');

function [t,h]=Data2tab(Data)
h={'Trial' 'Block' 'Reversal' 'Trial/Block' 'Trial/Pair' ...
    'StimLeft' 'StimRight' 'TargetSide' 'Response' 'RT' 'Accuracy' ...
    'Prob.Error' 'Feedback'};
t=[ ...
    Data.i_trial(:) ...
    Data.i_rev(:) ...
    Data.newblock(:) ...
    Data.i_trial_per_rev(:) ...
    Data.i_trial_per_stims(:) ...
    Data.stims ...
    Data.side(:) ...
    Data.resp(:) ...
    Data.rt(:)*1000 ...
    Data.accu(:) ...
    Data.prob_error(:) ...
    Data.fb(:)...
    ];



function Passation = expe_trycatch(participant)
global DEBUG
if DEBUG
    % run experiment
    assignin('base','participant',participant);
    %try
    [Passation,Passation.ErrorMsg] = expe(participant);
    %catch ME
    %    rethrow(ME);
    %end
else
    try
        % run experiment
        [Passation,Passation.ErrorMsg] = expe(participant);
    catch ME
        Priority(0);
        Screen('CloseAll');
        FlushEvents;
        ListenChar(0);
        ShowCursor;
        video = [];
        disp(ME)
        rethrow(ME);
        diary('OFF')
        return
    end
end



function [Passation,errormsg]=expe(participant)

global DEBUG
Passation=[];
errormsg =[];
io = []; %input/output systems

fprintf('\n');
fprintf('=======================================\n');
fprintf('======= START OF THE EXPERIMENT =======\n');
fprintf('=======================================\n');
fprintf('\n');

% Are we in DEBUG mode?
Passation.DEBUG = DEBUG;
if DEBUG
    fprintf('\n');
    fprintf('       **********************\n');
    fprintf('       **********************\n');
    fprintf('       ***   DEBUG MODE   ***\n');
    fprintf('       **********************\n');
    fprintf('       **********************\n');
    fprintf('\n');
end

% Keep track of the actual scripts that are being used (along with the data)
Passation.Running = dbstack;
for i=1:length(Passation.Running)
    Passation.Running(i).fullpath = which(Passation.Running(i).file);
    Passation.Running(i).filedate = getfield(dir(Passation.Running(i).fullpath),'date');
    Passation.Running(i).mcode    = ...
        textread(Passation.Running(i).fullpath,'%s','delimiter','\n'); %#ok<DTXTRD>
end

% Define various parameters
run('reversal_TaskParameters');
Passation.TaskParameters = ...
    textread(which('reversal_TaskParameters'),'%s','delimiter','\n'); %#ok<DTXTRD>

% Set the participant data accordingly
Passation.Participant = participant;
Passation.DataFolder = fullfile(...
    fileparts(fileparts(mfilename('fullpath'))),...
    '..','data', ...
    participant.identifier);
fprintf('Data folder should be: %s\n', Passation.DataFolder);
if not(exist(Passation.DataFolder, 'dir'))
    if DEBUG
        fprintf('Missing folder! %s\n', Passation.DataFolder);
        % When debugging, save in temporary folder
        Passation.DataFolder = fullfile(fileparts(tempname));
        fprintf('Data will be saved in: %s\n', Passation.DataFolder);
    else
        error('reversal:MissingDataFolder','Missing data folder! %s\n', Passation.DataFolder);
    end
end

% Import sequences from the participant folder
% [Data] = ImportSequences(Passation);
% if isempty(Data)
%     %Cancel
%     error('reversal:SequencesCancel','Cancelled by experimenter when importing sequences');
% end
% Passation.Data=Data;

% Define the filename to save the info
Passation.Filename=fullfile(...
    Passation.DataFolder,...
    sprintf('reversal_%s_%s',...
    datestr(now,'yyyymmdd-HHMM'),...
    participant.session_name));
fprintf('Saving session data in: %s\n', Passation.Filename);
diary(Passation.Filename)

%% Let's start playing with I/O now!!
if participant.flags.with_response_lumina
    % Open port to be used with LUMINA buttons
    % NB : Baud rate is set to 115200
    %      Mode should be 'ASCII/MEDx' on the LSC-400B Controller
    IOPort('CloseAll')
    if IsWin
        [io.hport] = IOPort('OpenSerialPort','COM1');
    elseif IsLinux
        io.hport = IOPort('OpenSerialPort','/dev/ttyS0');
    end
    IOPort('ConfigureSerialPort',io.hport,'BaudRate=115200');
    IOPort('Purge',io.hport);
else
    io.hport = [];
end

if participant.flags.with_triggers
    % Open trigger port & define sendtrigger
    if ispc
        CloseParPort;
        OpenParPort;
        io.trigger = @(trig) SendTriggerWin(trig);
    elseif IsLinux
        io.trigger = @(trig) SendTriggerLinux(trig);
    elseif ismac
        io.trigger = @(x)[];
    end
    io.trigger(0);
    fprintf('Triggers will be sent on parallel port.\n');
else
    % Do nothing on trigger() function calls
    io.trigger = @(x)[];
end

% Remove keyboard outputs to matlab screen
if ~DEBUG
    fprintf('Hiding cursor and key strokes.\n');
    HideCursor;
    FlushEvents;
    ListenChar(2);
end

% Open a new Psychtoolbox Screen
io.video = OpenPTBScreen;
DrawText(io.video.h,'Demarrage...');
Screen('Flip',io.video.h);
%SetMouse(0,0);

io.video.roundfp = @(t) roundfp(t,io.video.ifi);

% Start the eyetracker
if participant.flags.with_eyetracker
    if IsWin
        if EyelinkInit() ~= 1
            error('Could not initialize EyeLink connection!');
        end
    elseif IsLinux
        dummymode = 0; % set to 1 to run in dummymode (using mouse as pseudo-eyetracker)
        % Initialization of the connection with the Eyelink Gazetracker.
        % exit program if this fails.
        if ~EyelinkInit(0, 1)
            fprintf('Eyelink Init aborted./n');
            cleanup(useTrigger);  % cleanup function
            return
        end
        [v vs]=Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker./n', vs );
    end
    io.eyelink = EyelinkInitDefaults(io.video.h);
    %eyelink=InitializeEyeTracker(video,eyelink);
end

% BADCODING:
stimfolder='../stimuli';

% Make the textures for each shape
[io.gfx.stimuli,io.gfx.feedback]=CreateStimuli(io.video,stimfolder);
io.gfx.fix.width = (io.gfx.stimuli.rec(1,3)-io.gfx.stimuli.rec(1))/2;

task.timing = timing;

%% Here starts the task proper

DrawText(io.video.h,'Nous allons commencer la tache...');
if DEBUG
    DrawText(io.video.h, { ...
        'DEBUG mode' '' ...
        'Indiquez  votre choix en appuyant sur "Q" ou sur "M"'},'bm');
end
Screen('Flip',io.video.h);
pause
%KbTriggerWait(KbName('space'));
Screen('Flip',io.video.h);

% Here starts the task proper
[Passation.Data,stopped,Passation.EyelinkFilename] = reversals(task,io,Passation);

% Clean up afterwards
if participant.flags.with_response_lumina
    % Close response port
    IOPort('Close',io.hport);
end

if participant.flags.with_triggers
    % close trigger port
    CloseParPort;
end

if participant.flags.with_eyetracker
    Eyelink('StopRecording');
    Eyelink('CloseFile');
end

% Rename data log file
if stopped
    sufx = '_stopped';
else
    sufx = '';
end
Passation.Filename=[Passation.Filename sufx];
% Save data
save(Passation.Filename,'Passation');
% Mark sequence as "used"

% Close video etc.
Priority(0);
Screen('CloseAll');
FlushEvents;
ListenChar(0);
ShowCursor;
video = [];

%% THIS IS THE END
return



function [Data,stopped,EyelinkFilename] = reversals(parameters,io,Passation)
global DEBUG
stopped = 0;
Data=[];
EyelinkFilename = '';

% BAD should be using 'parameters' argin here
run('reversal_TaskParameters');
participant = parameters
participant.flags = flags 
video = io.video;
stimuli=io.gfx.stimuli;
hport=io.hport;

assignin('base','io',io)
reversaltype = 'standard'; % | 'avoidance' 'perseveration'

i_rev = 1;
i_trial = 0;
i_trial_per_rev = 0;
i_trial_per_stims = 0;
n_correct_in_a_row = 0;
n_points = 100;

% Let's roll it!
newblock  = true;
completed = false;
stopped   = false;
stims = [0 0]; % No stims to ignore on 1st block

while ~stopped && ~completed
    
    if i_trial_per_stims == 0
        % (Re)starting (after a pause)
        if DEBUG
        fprintf('\n');
            fprintf('[ DEBUG ] ');
            fprintf('\n');        
        end
        fprintf('\n\n\n');     
        fprintf(' * * * STARTING NEW BLOCK/REVERSAL: %02d * * * \n',i_rev);

        if flags.with_eyetracker 
            fprintf('Setting up the eye-tracker...\n');
            fprintf('Eyelink is probably waiting for "ESC" to continue...\n');
            EyelinkDoTrackerSetup(io.eyelink);
            fprintf('Eye-tracker ready!\n');
            DrawText('.')
            Screen('FillRect',io.video.h,0);
        end
        
        DrawText(io.video.h,{'Ca va demarrer.'});
        Screen('Flip',io.video.h);
        
        fprintf('Appuyez sur [%s] pour demarrer le bloc ',KbName(keywait));
        %         if is_training
        %             fprintf('d''entrainement \n');
        %         else
        %             fprintf(' %d \n',iblock);
        %         end
        fprintf('!! Appuyez sur [%s] pour terminer l''experience !!\n',KbName(keyquit));
        fprintf('\n');
        key = WaitKeyPress([keywait keyquit]);
        if isequal(key,2)
            fprintf(' !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf(' !!  Etes vous certain de vouloir quitter ??  !!\n');
            fprintf('     Appuyez sur [%s] pour terminer  !!\n',KbName(keyconfirm));
            fprintf(' !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('\n');
            key = WaitKeyPress();
            if isequal(key,keyconfirm)
                stopped = true;
                break;
            end
        end        
        
        if participant.flags.with_eyetracker 
            Eyelink('OpenFile','reversal');
            Eyelink('StartRecording');
            fprintf('Eyetracker is recording.\n');
            fprintf('\n\n\n');
        end
        
        % Dead time before starting the block
        if ~DEBUG
            WaitSecs(timing.startofblock);
        end
        
        fprintf('C''est parti ([%s] pour interrompre en cours de bloc)\n',KbName(keystop));
        fprintf('\n');
        
        if flags.with_triggers
            WriteParPort(0);
            WaitSecs(0.2);
        end
        t_start=Screen('Flip',io.video.h);
        t = t_start;
        if flags.with_triggers
            for i=1:3
                io.trigger(255);
                WaitSecs(.050);
            end
        end
        fprintf('Time0: Data.timecode.t_start(%d) = %g\n',i_rev,t_start);
        Data.timecode.t_start(i_rev) = t_start;
        % Pick at random two new stimuli (different from previous ones)
        stims = setdiff(1:numel(stimuli.tex),stims);
        stims = randpick(stims,2);
        
    end
    
    i_trial = i_trial+1;
    i_trial_per_rev   = i_trial_per_rev   + 1;
    i_trial_per_stims = i_trial_per_stims + 1;
    
    fprintf('Trial %03d :',i_trial);
    
    % Display each stimulus in a random spatial order (no clear mode)
    side = 2-round(rand);
    Screen('DrawTexture',io.video.h,stimuli.tex(stims(1)),[],stimuli.rec(  side,:));
    Screen('DrawTexture',io.video.h,stimuli.tex(stims(2)),[],stimuli.rec(3-side,:));
    t=Screen('Flip',io.video.h,t+io.video.roundfp(timing.intertrial()),1);
    if flags.with_triggers
        trig.stim.onset+trig.stim.leftright(side)+trig.stim.is_reversal(i_trial_per_rev==1);
        io.trigger(trig.stim.onset+trig.stim.leftright(side)+trig.stim.is_reversal*(i_trial_per_rev==1));
    end
    Data.timecode.t_stim(i_trial) = t;
    
    if side==1
        fprintf('[(% 2d)  % 2d] ',stims);
    else
        fprintf('[% 2d  (% 2d)] ',stims([2 1]));
    end
    
    % Collect response from buttons, keyboard or mouse
    resp   = 0;
    resp_t = NaN;
    
    % Clear the response button port, to collect response
    if participant.flags.with_response_lumina
        IOPort('Purge',hport);
    end
    while resp==0 && ~stopped
        % Now, if not, look at each response mode:
        if ~resp && participant.flags.with_response_lumina
            [dat, resp_t] = IOPort('Read',hport);
            resp_t = resp_t(1);
            if ~isempty(dat) && ismember(dat(1),datresp)
                resp = find(datresp == dat(1));
            end
        end
        if ~resp && participant.flags.with_response_mouse
            [~,~,b]=GetMouse;
            resp_t = GetSecs;
            resp=max([1*b(1) 2*b(2+IsWindows)]);
        end
        if ~resp && participant.flags.with_response_keyboard
            [resp,resp_t]=CheckKeyPress(keyresp);
        end        
        % Stop by experimenter ?
        if CheckKeyPress(keystop)
            t = NaN;
            fprintf('... stopped!\n');
            stopped = true;
            Screen('Flip',video.h);
            break;
        end      
    end
    if stopped
        break;
    end
    if flags.with_triggers
        io.trigger(trig.resp.onset+trig.resp.button(resp));
        % io.trigger(255);
        % io.trigger(255*(resp==1));
        % io.trigger(255);
    end
    Data.timecode.t_resp(i_trial) = resp_t;
    
    % Reaction time
    rt = resp_t-t;
    fprintf('resp: %d %3.0fms, ',resp,1000*rt);
    
    % Highlight the chosen stimulus
    Screen('FrameRect',io.video.h,80,stimuli.rec(resp,:));
    t=Screen('Flip',io.video.h,0,1);
    
    fprintf('choice was ');
    accu=resp==side;
    if accu
        fprintf('correct');
        n_correct_in_a_row = n_correct_in_a_row + 1;
        n_points = n_points + 1 ;
    else
        fprintf('wrong');
        n_correct_in_a_row = 0;  
        n_points = n_points - 1 ;
    end
    fb = accu;
    prob_error = rand<task.prob_error(2-accu);
    if prob_error
        % introduce probabilistic wrong feedback
        fb = ~fb;
        fprintf('-> prob. error = ');
        if fb
            fprintf('"correct"');
        else
            fprintf('"wrong"');
        end
    end
    
    % Give feedback
    Screen('DrawTexture',io.video.h,io.gfx.feedback.tex(2-fb),[],io.gfx.feedback.rec);
    t=Screen('Flip',io.video.h,t+io.video.roundfp(timing.prefeedback));
    if flags.with_triggers
        ttl = trig.fb.onset+trig.fb.is_correct*accu+trig.fb.is_proberror*prob_error;
        io.trigger(ttl);
        if flags.with_triggers_1bit
                 io.trigger(255);
                 io.trigger(255*accu);
                 io.trigger(255*fb);
                 io.trigger(255);
        end
    end
    Data.timecode.t_feedback(i_trial) = t;
    
    Data.i_trial(i_trial) = i_trial;
    Data.i_rev(i_trial) = i_rev;
    Data.i_trial_per_rev(i_trial)  = i_trial_per_rev;
    Data.i_trial_per_stims(i_trial) = i_trial_per_stims;
    
    Data.newblock(i_trial) = newblock;
    Data.stims(i_trial,1:2) = stims([side 3-side]);
    Data.side(i_trial) = side;
    Data.resp(i_trial) = resp;
    Data.rt(i_trial) = rt;
    Data.accu(i_trial) = accu;
    Data.prob_error(i_trial) = prob_error;
    Data.fb(i_trial) = fb;
    
    smalltext = '';
    newblock=false;
    if n_correct_in_a_row >= task.crit_rev
        smalltext=sprintf('t: %d, r: %d',i_trial,i_rev);
        fprintf(', %d >= %d trials were correct: ',n_correct_in_a_row,task.crit_rev);
        if rand < task.prob_rev(1) || n_correct_in_a_row >= 15
            fprintf(' now we reverse!\n');
            newblock = true;
            stims = stims([2 1]);                       
            i_rev              = i_rev+1;
            i_trial_per_rev    = 0;
            n_correct_in_a_row = 0;
                        
        end
    end
    
    fprintf('\n');

    textsize=Screen('TextSize', io.video.h);
    Screen('TextSize', io.video.h, 10);
    DrawText(io.video.h,smalltext,'bl',70);
    Screen('TextSize', io.video.h, textsize);
    
    t=Screen('Flip',io.video.h,t+io.video.roundfp(timing.feedback));
    
    if i_rev > task.end_after_n_rev
        completed=true;
        fprintf('C''est fini...\n');
        DrawText(io.video.h, { 'FIN DE L''ETUDE' })
    else
        fprintf('Pause...\n');
        DrawText(io.video.h, { 'On va faire une pause...' ...
            sprintf('(%d/%d)',i_rev-1,task.end_after_n_rev) ...
            sprintf('[ %d ]',n_points) ...
            })
        % New stims
        stims = randpick(setdiff(1:numel(stimuli.tex),stims),2);
        fprintf('New stims: %d %d\n',stims);
        i_trial_per_stims = 0;
    end
    if (i_trial_per_rev==0 && i_rev>1 && mod(i_rev-1,task.pause_every_n_rev)==0)            
        Screen('Flip',io.video.h);
        % save eye-tracker data
        if  flags.with_eyetracker
            EyelinkFilename = sprintf('%s_rev%02d.edf',Passation.Filename,i_rev-1);
            fprintf('Saving eye tracker data into: %s\n', EyelinkFilename);
            Eyelink('StopRecording');
            Eyelink('CloseFile');
            nattempts = 0;
            WaitSecs(5);
            while nattempts < 10
                nattempts = nattempts+1;
                status = Eyelink('ReceiveFile',[],EyelinkFilename);
                if status > 0
                    break
                end
            end
            if status <= 0
                warning('reversal_MEg:EyetrackerWarning','Could not receive eye-tracker datafile %s!',EyelinkFilename );
            end
        end% eyetracker data        
    end
end % trial loop
if stopped
    EyelinkFilename = sprintf('%s_rev%02d_stopped.edf',Passation.Filename,i_rev-1);
    fprintf('Saving eye tracker data into: %s\n', EyelinkFilename);
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    nattempts = 0;
    WaitSecs(5);
    while nattempts < 10
        nattempts = nattempts+1;
        fprintf('Attempt #%d\n', nattempts);
        status = Eyelink('ReceiveFile',[],EyelinkFilename);
        if status > 0
            break
        end
    end
    if status <= 0
        warning('reversal_MEg:EyetrackerWarning','Could not receive eye-tracker datafile %s!',EyelinkFilename );
    end
end
return






%
%
%
%
% wW = 200
% wH = 200;
%
%
% FixationCross(io.video.h,wW,wH,stimW);
% DrawArrow(w,wW,wH,stimW,[1,2,3,-1,-2,-3])
% Screen(w, 'Flip');
%
% % Prepare logging variables
% nseq = length(Data.Sequence);
% response       = [];
% response.resp = cell(1,nseq); % response
% response.rt   = cell(1,nseq); % response time (s)
% response.accu = cell(1,nseq); % response accuracy
% timecode       = [];
% timecode.start = cell(1,nseq); % start of bloc
% timecode.cue_onset  = cell(1,nseq); % onset of cue
% timecode.cue_offset = cell(1,nseq); % offset of cue
% timecode.stim_onset = cell(1,nseq); % onset of stim
% timecode.stim_offset = cell(1,nseq); % offset of stim
% timecode.resp_press   = cell(1,nseq); % button press
% timecode.resp_release = cell(1,nseq); % button release
%
%
% % Loop over the blocks
% iblock = participant.flags.starting_block;
% stopped = false;
% nextblock = true;
% seqidx = iblock;
% while seqidx <= nseq && nextblock
%     stopped = false;
%
%     seq = Data.Sequence{seqidx};
%     target = Data.Target{seqidx};
%     side   = Data.Side{seqidx};
%     ntrials = length(seq);
%
%     % create zeros arrays to save the data
%     response.resp{iblock} = NaN*zeros(1,ntrials);
%     response.rt{iblock}   = NaN*zeros(1,ntrials);
%     response.accu{iblock} = NaN*zeros(1,ntrials);
%
%     timecode.start{iblock}       = NaN;
%     timecode.cue_onset{iblock}   = NaN;
%     timecode.cue_offset{iblock}  = NaN;
%     timecode.stim_onset{iblock}  = NaN*zeros(1,ntrials);
%     timecode.stim_offset{iblock} = NaN*zeros(1,ntrials);
%     timecode.resp_press{iblock}  = NaN*zeros(1,ntrials);
%     timecode.resp_release{iblock}= NaN*zeros(1,ntrials);
%
%     Passation.Data.Trials.seqidx{iblock}   = NaN*zeros(1,ntrials);
%     Passation.Data.Trials.trialidx{iblock} = NaN*zeros(1,ntrials);
%
%     % Keep the experimenter updated in the matlab command window...
%     if DEBUG
%         fprintf('[ DEBUG ] ');
%     end
%     fprintf('\n\n\n');
%     fprintf('STARTING NEW BLOCK: %02d, seq %02d/%02d, target = %d, side = %d\n', iblock, seqidx, nseq, target, side);
%     if participant.flags.with_eyetracker && ~is_training
%         fprintf('Setting up the eye-tracker...\n');
%         fprintf('Eyelink is probably waiting for "ESC" to continue...\n');
%         EyelinkDoTrackerSetup(eyelink);
%         fprintf('Eye-tracker ready!\n');
%         Screen('FillRect',video.h,0);
%     end
%
%     if is_training
%         DrawText(video.h,'Entrainement...', 'tm');
%     end
%     DrawText(video.h,{'Ca va demarrer.'});
%     Screen('Flip',video.h);
%
%     fprintf('Appuyez sur [%s] pour demarrer le bloc ',KbName(keywait));
%     if is_training
%         fprintf('d''entrainement \n');
%     else
%         fprintf(' %d (seq #%d) \n',iblock,seqidx);
%     end
%     if seqidx>1
%         fprintf('!! Appuyez sur [%s] pour recommencer la sequence precedente (%d)\n',KbName(keyredo),seqidx-1);
%     end
%     fprintf('!! Appuyez sur [%s] pour terminer l''experience !!\n',KbName(keyquit));
%     fprintf('\n');
%     if iblock<=1
%         key = WaitKeyPress([keywait keyquit]);
%     else
%         key = WaitKeyPress([keywait keyquit keyredo]);
%     end
%     if isequal(key,2)
%         fprintf(' !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
%         fprintf(' !!  Etes vous certain de vouloir quitter ??  !!\n');
%         fprintf('     Appuyez sur [%s] pour terminer  !!\n',KbName(keyquit));
%         fprintf(' !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
%         fprintf('\n');
%         key = WaitKeyPress();
%         if isequal(key,keyconfirm)
%             nextblock = false;
%             stopped = true;
%             break;
%         end
%     end
%
%     % Relaunch ONE block back
%     if isequal(key,3)
%         seqidx = seqidx-1;
%         fprintf('On va rejouer la SEQ %d pour le BLOCK %d\n',seqidx,iblock);
%     end
%
%     if participant.flags.with_eyetracker && ~is_training
%         Eyelink('OpenFile','reversal');
%         Eyelink('StartRecording');
%         fprintf('Eyetracker is recording.\n');
%         fprintf('\n\n\n');
%     end
%
%     % Dead time before starting the block
%     if ~DEBUG
%         WaitSecs(timing.startofblock);
%     end
%
%     fprintf('C''est parti ([%s] pour interrompre en cours de bloc)\n',KbName(keystop));
%     fprintf('\n');
%
%     % Parallel port back to 0
%     if participant.flags.with_triggers
%         WriteParPort(0);
%         WaitSecs(0.2);
%         fprintf('Sending BLOCK #%d | SEQ #%d code ',iblock, seqidx);
%     end
%     % Initial time stamp:
%     t = Screen('Flip',video.h);
%     timecode.start{iblock} = t;
%     if participant.flags.with_triggers
%         % Send block specific trigger at the start of the bloc
%         WriteParPort(trig.start);
%         WaitSecs(0.050);
%         WriteParPort(0);
%         WaitSecs(0.010);
%         c=flipud(str2num(dec2bin(iblock,trig.blockbits)'));
%         for i=c(:)'
%             if i
%                 WriteParPort(trig.start);
%             else
%                 WriteParPort(0);
%             end
%             WaitSecs(0.010);
%             WriteParPort(0);
%             WaitSecs(0.010);
%             if DEBUG
%                 fprintf('%d ',i);
%             end
%         end
%         WriteParPort(trig.start);
%         WaitSecs(0.050);
%         WriteParPort(0);
%         WaitSecs(0.010);
%         if DEBUG
%             fprintf('| ');
%         end
%         WriteParPort(0);
%         WaitSecs(0.010);
%         c=flipud(str2num(dec2bin(seqidx,trig.blockbits)'));
%         for i=c(:)'
%             if i
%                 WriteParPort(trig.start);
%             else
%                 WriteParPort(0);
%             end
%             WaitSecs(0.010);
%             WriteParPort(0);
%             WaitSecs(0.010);
%             if DEBUG
%                 fprintf('%d ',i);
%             end
%         end
%         fprintf('sent on parallel port.\n');
%     end
%
%     if is_training
%         DrawText(video.h,'Entrainement...', 'tm');
%     end
%
%     % Display cue designating the target shape and side of response
%     Screen('DrawTexture',video.h,texstim{target},[],stimrec);
%     Screen('DrawTexture',video.h,texcue,[],cuerec{side});
%
%     Screen('DrawingFinished',video.h);
%     tonset = Screen('Flip',video.h);
%     timecode.cue_onset{iblock}   = tonset;
%     if participant.flags.with_triggers
%         trigger(trig.cue.onset+trig.cue.shape(target)+trig.cue.side(side));
%     end
%     if CheckKeyPress(keystop)
%         stopped = true;
%         break;
%     end
%     % Cue is displayed for ... sec
%     t = Screen('Flip',video.h,tonset+roundfp(timing.cueduration,video.ifi));
%     timecode.cue_offset{iblock}  = t;
%     % Beware to keep a 't' variable that will be used to set the next
%     % stimulus onset time.
%
%     if CheckKeyPress(keystop)
%         stopped = true;
%         break;
%     end
%
%     % Loop over trials
%     itrial = 1;
%     while itrial <= ntrials && ~stopped
%         if DEBUG
%             fprintf('[ DEBUG ] ');
%         end
%         stim = seq(itrial);
%         if is_training
%             fprintf('** Training ** ');
%         end
%
%         fprintf('TRIAL: % 3d | Stim: %d',itrial,stim);
%         if stim==target
%             fprintf('*');
%         else
%             fprintf(' ');
%         end
%         if DEBUG
%             % Reserve typographic space for the chronometer
%             fprintf(' xxxxxx');
%         end
%
%         % Stop if experimenter is pressing on ESCAPE
%         if CheckKeyPress(keystop)
%             stopped = true;
%             break
%         end
%
%         % Display the stimulus on screen
%         Screen('DrawTexture',video.h,texstim{stim},[],stimrec);
%         if is_training
%             DrawText(video.h,'[Entrainement]', 't');
%         end
%         Screen('DrawingFinished',video.h);
%         tonset = Screen('Flip',video.h,t+...
%             roundfp(timing.interstim(),video.ifi));
%         % Send trigger right after stimulus display
%         trigger(trig.stim.onset+trig.stim.shape(stim));
%         timecode.stim_onset{iblock}(itrial) = tonset;
%
%         if is_training
%             DrawText(video.h,'[Entrainement]', 't');
%         end
%         % Clear the response button port, to collect response
%         if participant.flags.with_response_lumina
%             IOPort('Purge',hport);
%         end
%
%         % Now collect the response
%         t = tonset;
%         resp = 0;
%         while resp==0 && ~stopped
%             % Stop by experimenter ?
%             if CheckKeyPress(keystop)
%                 t = NaN;
%                 fprintf('... stopped!\n');
%                 stopped = true;
%                 Screen('Flip',video.h);
%                 break;
%             end
%             % Now, if not, look at each response mode:
%             if ~resp && participant.flags.with_response_lumina
%                 [dat, t] = IOPort('Read',hport);
%                 t = t(1);
%                 if ~isempty(dat) && ismember(dat(1),datresp)
%                     resp = find(datresp == dat(1));
%                 end
%             end
%             if ~resp && participant.flags.with_response_mouse
%                 dat = ReadParPort();
%                 t   = GetSecs;
%                 if ~isempty(dat) && any(ismember(dat,datresp))
%                     resp = find(datresp == dat(1));
%                 end
%             end
%             if ~resp && participant.flags.with_response_keyboard
%                 [resp,t]=CheckKeyPress(keyresp);
%             end
%             if DEBUG
%                 % When no response, display chronometer only in DEBUG mode
%                 fprintf('\b\b\b\b\b\b% 6d',round(1000*(GetSecs-tonset)));
%             end
%         end
%         if stopped
%             break;
%         end
%
%         % Send "RESPONSE" trigger
%         trigger(trig.resp.onset+trig.resp.button(resp));
%         toffset = Screen('Flip',video.h);
%         rt = t-tonset;
%         accu = ((stim==target)&&(resp==side)) ||...
%             (   (stim~=target)&&(resp~=side));
%
%         % Log data
%         response.resp{iblock}(itrial) = resp;
%         response.rt{iblock}(itrial) = rt;
%         response.accu{iblock}(itrial) = accu;
%         timecode.stim_offset{iblock}(itrial) = toffset;
%         timecode.resp_press{iblock}(itrial) = t;
%
%         % Display on experimenter control monitor
%         resptype    = 'N/A ';
%         if accu && stim==target
%             resptype=('hit       ');
%         elseif accu && stim~=target
%             resptype=('c.rej.    ');
%         elseif ~accu && stim==target
%             resptype=('      miss');
%         elseif ~accu && stim~=target
%             resptype=('    f.pos.');
%         end
%         if DEBUG
%             fprintf('\b\b\b\b\b\b');
%         end
%         fprintf('|RT:% 6dms',round(rt*1000));
%         fprintf(' resp:[%d] = %s', resp, resptype);
%
%         % Wait patient to release the buttons
%         if participant.flags.with_response_lumina ...
%                 && ~participant.flags.with_response_keyboard...
%                 && ~participant.flags.with_response_mouse
%             % NB : in ASCII/MEDx mode, Lumina buttons send a single
%             % trigger when pressing the buttons i.e. cannot detect
%             % relase nor continuous press
%             fprintf(' [n/a with lumina] ');
%             timecode.resp_release{iblock}(itrial) = NaN;
%             t=WaitSecs('UntilTime',t+timing.response_release);
%         else
%             pressed=true;
%             lastkeypress=t;
%             fprintf(' [waiting release... ');
%             while pressed || (t-lastkeypress) < timing.response_release
%                 pressed=0;
%                 if participant.flags.with_response_keyboard
%                     pressed = pressed || CheckKeyPress(keyresp);
%                 end
%                 if participant.flags.with_response_mouse
%                     %TO DO
%                 end
%                 t = GetSecs;
%                 if pressed
%                     lastkeypress=t;
%                 end
%             end
%             timecode.resp_release{iblock}(itrial) = lastkeypress;
%             fprintf(' %03.0fms]',1000*(timecode.resp_release{iblock}(itrial)-timecode.resp_press{iblock}(itrial)));
%         end
%
%         if is_training && ~stopped
%             if accu
%                 Snd('Play', sin([1:500 ]*pi*1/050)*.2);
%             else
%                 Snd('Play', sin([1:5000]*pi*1/100)*.5);
%             end
%             DrawText(video.h,'[Entrainement]', 't');
%             t = Screen('Flip',video.h,t+timing.prefeedbackduration);
%
%             if itrial < training.nfeedbacktrials
%                 DrawText(video.h,'[Entrainement]', 't');
%                 if accu
%                     DrawText(video.h,'Correct !');
%                 else
%                     DrawText(video.h,'Erreur !');
%                 end
%                 t = Screen('Flip',video.h);
%                 DrawText(video.h,'[Entrainement]', 't');
%                 t = Screen('Flip',video.h,t+timing.feedbackduration);
%             end
%         end
%
%         % The trials that has just been collected
%         Passation.Data.Trials.seqidx{iblock}(itrial) = seqidx;
%         Passation.Data.Trials.trialidx{iblock}(itrial) = itrial;
%
%         % Save data in temporary file just in case...
%         Passation.Data.Response = response;
%         Passation.Data.Timecode = timecode;
%
%         % Temporary backup
%         save([Passation.Filename '_tmp'],'Passation');
%         assignin('base','Passation', Passation);
%
%         % Go to next trial
%         itrial = itrial + 1;
%         fprintf('\n');
%
%     end % loop on trials within a block
%     fprintf('Fin du BLOCK\n');
%     if itrial>10
%         try
%             OnlineMonitoring(Passation,iblock);
%         catch
%             fprintf('Error during OnlineMonitoring!\n');
%         end
%     end
%     if participant.flags.with_eyetracker && ~is_training
%         fprintf('Stopping Eyetracker ...');
%         Eyelink('StopRecording');
%         fprintf('recording stopped.\n');
%     end
%
%     if is_training
%         if ~stopped
%             fprintf('Un autre block de training? \n');
%             t=GetSecs;
%             while (GetSecs()-t)<5 && ~stopped && ~stopped
%                 DrawText(video.h,{...
%                     '...',...
%                     '',...
%                     sprintf('%d',round(5-(GetSecs()-t)))});
%                 Screen('Flip',video.h,tonset);
%                 if CheckKeyPress(keystop)
%                     stopped = true;
%                 end
%             end
%             Data.Sequence  = num2cell(randi(3,[1,ntrials]),2)';
%             Data.Target    = num2cell(randi(3),2)';
%             Data.Side      = num2cell(randi(2),2)';
%         else
%             % Training was manually stopped. Continue with the task?
%             fprintf('L''entrainement interrompu.\n');
%             is_training = false;
%             stopped=false;
%             DrawText(video.h,{...
%                 'Cette fois, nous allons passer' ...
%                 'a la tache proprement dite.'},'tm');
%             fprintf('On continue vers blocs de t�che...\n');
%             WaitSecs(.3);
%             Data=Passation.Data;
%         end
%     else
%         if stopped
%             fprintf('Bloc interrompu!\n');
%             if nextblock
%                 stopped = false;
%             end
%         end
%         save([Passation.Filename],'Passation');
%         fprintf('Session data are saved in: %s\n', Passation.Filename);
%
%         % save eye-tracker data
%         if ~is_training && participant.flags.with_eyetracker
%             Passation.EyelinkFilename = sprintf('%s_bloc%02d.edf',Passation.Filename,iblock);
%             Eyelink('StopRecording');
%             Eyelink('CloseFile');
%             nattempts = 0;
%             WaitSecs(5);
%             while nattempts < 10
%                 nattempts = nattempts+1;
%                 status = Eyelink('ReceiveFile',[],Passation.EyelinkFilename);
%                 if status > 0
%                     break
%                 end
%             end
%             if status <= 0
%                 warning('Could not receive eye-tracker datafile %s!',Passation.EyelinkFilename );
%             end
%         end% eyetracker data
%         iblock = iblock + 1;
%         seqidx = seqidx + 1;
%     end
% end
%
% if participant.flags.with_response_lumina
%     % Close response port
%     IOPort('Close',hport);
% end
%
% if participant.flags.with_triggers
%     % close trigger port
%     CloseParPort;
% end
%
% if participant.flags.with_eyetracker
%     Eyelink('StopRecording');
%     Eyelink('CloseFile');
% end
%
% if stopped
%     sufx = '_stopped';
% else
%     sufx = '';
% end
% Passation.Filename=[Passation.Filename sufx];
%
% % Save data
% save(Passation.Filename,'Passation');
% % Mark sequence as "used"
% fprintf('Renaming  sequence*.mat  file into  *.mat_used \n');
% movefile(Passation.Data.SequenceFile,[Passation.Data.SequenceFile '.used']);
%
% % Close video etc.
% Priority(0);
% Screen('CloseAll');
% FlushEvents;
% ListenChar(0);
% ShowCursor;
% video = [];
%
% %% THIS IS THE END
% return



% function [E]=ImportSequences(Passation)
% % Read sequences form file
% global DEBUG;
% E=[];
% if nargin<1
%     SequenceFile=[];
% else
%     fprintf('Searching for ''sequence*.mat'' in: %s\n', Passation.DataFolder);
%     % Try to find sequence file in participant data folder
%     SequenceFile = dir(fullfile(Passation.DataFolder,'sequence*.mat'));
%     SequenceFile = arrayfun(@(x)fullfile(Passation.DataFolder, x{1}),...
%         {SequenceFile.name}, 'UniformOutput', 0);
% end
% if DEBUG
%     SequenceFile = fullfile(fileparts(mfilename('fullpath')),'..','sequences');
%     [filename, pathname] = uigetfile('sequence*.mat', 'Pick a sequence MAT file',SequenceFile);
%     if isequal(filename,0) || isequal(pathname,0)
%         disp('User pressed cancel')
%         return
%     end
%     SequenceFile=fullfile(pathname,filename);
% end
% if isempty(SequenceFile)
%     error('reversal:NoSequence', 'No sequence file found in in data folder %s', Passation.DataFolder)
% end
% if iscell(SequenceFile)
%     if numel(SequenceFile)>1 && ~strcmp(Passation.Participant.session_name, 'perop')
%         error('reversal:MultipleSequence','Multiple sequence files in data folder %s', Passation.DataFolder)
%     end
%     SequenceFile = sort(SequenceFile);
%     SequenceFile = SequenceFile{1};
% end
% fprintf('Using stimulus sequence from Experience #%d in file: %s\n', i, SequenceFile);
% load(SequenceFile)
%
% E = Experience;
% E.SequenceFile = SequenceFile;
% if ~isfield(E, 'Target')
%     error('reversal:NoTarget','No target defined in sequence file');
%     %E.Target = num2cell([ 1 1  2 2  3 3  1 1  2 2  3 3 ]);
% end
% if ~isfield(E, 'Side')
%     t=cell2mat(Experience.Target);
%     E.Side=zeros(1,numel(t));
%     for j = unique(t(:)')
%         n=sum(t==j);
%         E.Side(t==j)=randpick(repmat(1:2,1,ceil(n/2)),n);
%     end
%     E.Side = num2cell(E.Side);
% end


function trig=SendTriggerWin(trig)
WriteParPort(trig);
WaitSecs(0.010);
WriteParPort(0);
if numel(trig)>1
    for t=trig(2:end)'
        WaitSecs(0.010);
        WriteParPort(trig);
        WaitSecs(0.010);
        WriteParPort(0);
    end
end
return

function trig=SendTriggerLinux(trig)
command = sprintf('./TRIGGER/trigger %d',trig);
system(command);
if numel(trig)>1
    for t=trig(2:end)'
        WaitSecs(0.010);
        system(command);
    end
end
return

function video = OpenPTBScreen()
global DEBUG
ppd=evalin('caller', 'ppd');
Screen('Preference','VisualDebuglevel',3);
%Screen('Preference','VisualDebuglevel',3);
PsychImaging('PrepareConfiguration');
%PsychImaging('AddTask','General','UseFastOffscreenWindows');
%PsychImaging('AddTask','General','NormalizedHighresColorRange');
% By default we display on the auxillary monitor (ie. not the main one=0)
video.i = max(Screen('Screens'));
frame = []; % full screen
video.res = Screen('Resolution',video.i);
if DEBUG
    Screen('Preference', 'SkipSyncTests', 1);
else
    Screen('Preference', 'SkipSyncTests', 0);
end
if video.i<=1
    if DEBUG
        % In DEBUG mode, we may use the main one, and not full screen
        if video.i > 0
            frame = [];
        else
            frame = [video.res.width video.res.height]*1/2;
            frame = [0 0 frame];
            frame = video.res.width/4*[1 0 1 0]+video.res.width/8*[0 1 0 1]+frame;
            frame= round(frame);
            fprintf('Opening frame: %d %d %d %d\n',frame);
            %frame = [ video.res.width/6 50 video.res.width/6*5 video.res.height/3*2];
        end
    else
        warning('reversal:SingleMonitor', 'reversal is running on single monitor display!')
    end
end

bgcol = 0;

% Now open a Psychtoolbox Window
try
    if isempty(frame)
        video.h = PsychImaging('OpenWindow',video.i,bgcol);
    else
        video.h = PsychImaging('OpenWindow',video.i,bgcol,frame);
    end
catch
    video.h = Screen('OpenWindow',video.i,bgcol,frame);
end
[video.x,video.y] = Screen('WindowSize',video.h);
video.colortable.black=BlackIndex(video.h);
video.colortable.white=WhiteIndex(video.h);
Screen('TextFont',video.h,'Arial');
Screen('TextSize',video.h,round(0.33*ppd));
Screen('TextStyle',video.h,0);
video.ifi = 1/60;
if DEBUG
    return
end
% Some further setup
video.ifi = Screen('GetFlipInterval',video.h,100,50e-6,10);
fprintf('Real IFI: %g\n', video.ifi);
Screen('BlendFunction',video.h,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
return
Priority(MaxPriority(video.h));


function FixationCross(video, w, e)
rec = CenterRectOnPoint([0 0 w w],video.x/2,video.y/2);
color = 60;
rec = [rec mean(reshape(rec,2,2)')];
e=2; % epaisseur croix
Screen('DrawLine',video.h,color, rec(1), rec(6), rec(3), rec(6), e);
Screen('DrawLine',video.h,color, rec(5), rec(2), rec(5), rec(4), e);
%Screen('DrawLine',w,colcroix, croixW-l, croixH+l, croixW+l, croixH-l, e);


function DrawArrow(w,wW,wH,stimW,pos)
long=(wW/5)-(stimW/2);
haut=wH/60; %hauteur fleche
larg=wW/60;
if length(pos)==1
    e=5;
    colFlech=[0 0 255];
else
    e=2;
    colFlech=[150 150 250];
end
for i=1:length(pos)
    if pos(i)>0
        signe=1;
    else
        signe=-1;
    end
    emp=(4*wW/10)+(stimW/2)+pos(i)*long/4;
    Screen('DrawLine',w,colFlech, emp+signe*larg , wH/2, emp, (wH/2)+haut,  e);
    Screen('DrawLine',w,colFlech, emp+signe*larg , wH/2, emp, (wH/2)-haut,  e);
end


function [stimuli, feedback]=CreateStimuli(video,imgfolder)
% Load the pictures of the cue and stims in graphical memory
DrawText(video.h,'Loading...');
Screen('Flip',video.h);
fprintf('Reading Image files into Textures...\n');
fprintf('From folder: %s\n',imgfolder);
f=dir(fullfile(imgfolder,'Stim*.bmp'));
fprintf('Found: %d\n',numel(f));
for i=1:numel(f)
    fprintf('... processing: %s\n',f(i).name);
    bmp = double(imread(fullfile(imgfolder,f(i).name)));
    bmp = bmp*2/3;
    stimuli.tex(i)=Screen('MakeTexture',video.h,bmp);
end
stimuli.tex = reshape(stimuli.tex,2,[])';

% BADCODING:
stimH=135; %hauteur originale des stimss
stimW=102; %largeur originale des stims
zoom=1.2;
stimuli.rec(1,:) = CenterRectOnPoint([0 0 stimH stimW]*zoom,video.x/2-160,video.y/2);
stimuli.rec(2,:) = CenterRectOnPoint([0 0 stimH stimW]*zoom,video.x/2+160,video.y/2);
feedback.rec = CenterRectOnPoint([0 0 30 30]*zoom,video.x/2,video.y/2);

% happy face
bmp = double(imread(fullfile(imgfolder,'FB-green-face100.png')));
bmp = bmp*2/3;
feedback.tex(1) = Screen('MakeTexture',video.h,bmp);
% sad face
bmp = double(imread(fullfile(imgfolder,'FB-red-face100.png')));
bmp = bmp*2/3;
feedback.tex(2) = Screen('MakeTexture',video.h,bmp);


function el=InitializeEyeTracker(video,el)
% Start the Eyelink eye tracker
if nargin<2
    el=[];
end
if isempty(el)
    if EyelinkInit() ~= 1
        error('Could not initialize EyeLink connection!');
    end
    el = EyelinkInitDefaults(video.h);
end
EyelinkDoTrackerSetup(el);


function hport=OpenParallelPort
global DEBUG
% open trigger port
OpenParPort;
ReadParPort;
global DEBUG;
if DEBUG
    return
end
% Test each response buttons
fprintf('\n\n\n');
fprintf('TESTING RESPONSE BUTTONS...\n');
for i = 1:2
    fprintf('WAITING FOR [%s] BUTTON... ',lptresp{i});
    dat = [];
    while isempty(dat)
        if CheckKeyPress(keyquit)
            fprintf('ABORTED!\n');
            error('Experiment aborted!');
        end
        dat = ReadParPort();
    end
    if dat(1) == lptresp(i)
        fprintf('OK!\n');
    else
        fprintf('ERROR! (found %d)\n',dat(1));
        error('Invalid configuration of [%s] button!',i);
    end
end
fprintf('\n\n\n');



function [datresp] = TestButtons()

addpath('./Toolbox/');

catresp = {'majeur gauche','index gauche','index droit','majeur droit'}; % response buttons
datresp = zeros(1,4); % codes of response buttons

KbName('UnifyKeyNames');
keyquit = KbName('ESCAPE'); % abort test

hport = [];
try
    
    % listen to key events
    FlushEvents;
    ListenChar(2);
    
    % open response port
    hport = IOPort('OpenSerialPort','COM1');
    IOPort('ConfigureSerialPort',hport,'BaudRate=115200');
    IOPort('Purge',hport);
    
    % wait 1 s
    WaitSecs(1.000);
    
    % test response buttons
    fprintf('\n\n\n');
    aborted = false;
    for i = 1:4
        fprintf('WAITING FOR [%s] BUTTON... ',catresp{i});
        dat = [];
        while isempty(dat)
            if CheckKeyPress(keyquit)
                fprintf('ABORTED!\n');
                aborted = true;
                break
            end
            dat = IOPort('Read',hport);
        end
        IOPort('Purge',hport);
        datresp(i) = dat(1);
        fprintf('%d\n',datresp(i));
    end
    fprintf('\n\n\n');
    
    % close response port
    IOPort('Close',hport);
    
    % stop listening to key events
    FlushEvents;
    ListenChar(0);
    
    if aborted
        datresp = [];
    end
    
catch
    LE = lasterror
    
    % stop listening to key events
    FlushEvents;
    ListenChar(0);
    
    % close response port
    if isequal(LE.stack(1).name,mfilename)% && LE.stack(1).line==19
        IOPort('CloseAll');
    else
        IOPort('Close',hport);
    end
    
    psychrethrow(lasterror);
    
end



function testParPort

% Define various parameters
run('reversal_TaskParameters');
addpath('ParPort64')

OpenParPort;
for i=1:5
    WriteParPort(255);
    fprintf('255 ');
    WaitSecs(.25);
    WriteParPort(0);
    fprintf('0 ');
    WaitSecs(.25);
end
for f=fieldnames(trig)'
    if isstruct(trig.(f{1}))
        for g=fieldnames(trig.(f{1}))'
            WriteParPort(sum(trig.(f{1}).(g{1})));
            WaitSecs(.05);
            WriteParPort(0);
            WaitSecs(.05);
        end
    else
        WriteParPort(sum(trig.(f{1})));
        WaitSecs(.05);
        WriteParPort(0);
        WaitSecs(.05);
    end
end
fprintf('\n');



