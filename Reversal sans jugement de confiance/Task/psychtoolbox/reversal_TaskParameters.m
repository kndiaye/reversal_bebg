%% Machine used in DEBUG mode
DEBUG_machines = { ...
    'Puma-Ndiaye.local' ...
    'puma-ndiaye.lan' ...
    'MacBook-Air-de-Marine.local' ...
    'Bakunin.local' ... %'pdelld420ab' ...
    %'MALLET-11' ... %ordi manip
    %'HPC3F9' ... % ordi MEG
    };

SESSIONS = {
    'Comportement pre-op', 'comportementpreop'; ...
    'Comportement+MEG pre-op', 'megpreop'; ...
    'Per-operative recordings','perop';...
    'LFP+MEG post-op',     'lfpmeg';
    'Comportement post-op',        'comportementpostop'};

%% Default Experiment flags
flags.with_training          = 1; % with initial training bloc?
flags.with_response_lumina   = 1;%now>datenum(2014,2,27,8,0,0); % Lumina buttons
flags.with_response_mouse    = 0; % "Lena"-Mouse buttons
flags.with_response_keyboard = 1; % Keyboard letters
flags.with_triggers   = 1  % send triggers on parallel port
flags.with_triggers_1bit = 0; % Have only 1 bit available
flags.with_eyetracker = strcmpi('HPC3F9',hostname()); % with eye-tracker?
flags.starting_block  = 1;


%% Useful inline functions
% Easier screen-blink compatible timing
% Typical use:
%       >> Screen('Flip',video.h,last_flip+roundfp(duration,ifi));
roundfp = @(dt,ifi)(round(dt/ifi)-0.5)*ifi;

% Chase 2011:
%
% Stimuli remained on the screen until the subject made a response on the
% button box, then, after a 1000-msec delay, feedback was presented for
% 500 msec. The feedback/subsequent stimuli delay was jittered between 750
% and 1250 msec to ensure that feedback-related activity was not confounded
% by presentation of the next stimulus.

%% Timing of events
timing.intertrial = @() 1+0.5*(rand-.5);
% timing.fixation = .25;
% timing.interseq = 5;
timing.startofblock = 1.5;
timing.response_release = .2;
timing.prefeedback = .75;
timing.feedback = .5;

%% Reversal task (+couleurs plus bas)
task.n_reversals = 40; % Number of reversals across whole session
task.prob_error = [20/100 20/100]; % probabilistic error rate on (+) and (-) stim
task.crit_rev = 6; % number of correct trials before rerv
task.prob_rev = 0.25; %[1-cumprod((1-.25)*ones(1,5)) 1]; 
task.pause_every_n_rev = 10 ;
task.end_after_n_rev = 40 ;


% "pourcentage" de chance pour que le bon stim ait pour feedback 'faux'
%     ppe(2)=60/100; % "pourcentage" de chance pour que le mauvais stim ait pour feedback 'faux'
%     nrrepmin=4; % nombre de bonnes reps consï¿½cutives avant reversal (min)
%     nrrepmax=4;
%     prev=25; %probabilitï¿½ de reversal aprï¿½s nrrep bonnes reps consï¿½cutives
%     ntrialsmax = 2000;
%     esppause=30; %nombre d'essais sï¿½parant les pauses
%     EndTime=3660; %temps max
%     Pointsmax= 1200;

%% keyboard/buttons inputs
KbName('UnifyKeyNames');
keywait = KbName('space'); % break waiting period
% break and restart current block:
keystop = KbName('ESCAPE');
% abort experiment:
if ispc
    keyquit = KbName('BackSpace');
elseif ismac
    keyquit = KbName('DELETE'); % break and restart current bloc
end
keyconfirm = KbName('Return');
keyredo = KbName('r');
% Response keys on KEYBOARD MODE
keyresp = KbName({'q','m'}); % response buttons ('L' 'R')
if ismac
    % i have to figure out why this is so...
    keyresp = [ 4 51 ];
end
% Lumina buttons codes:
%  |     Y[50] |  | G[51]     |
%  | B[49]     |  |     R[52] |
datresp = [50,51]; % codes of lumina response buttons (Left, Right)
lptresp = [4,8]; % codes of mouse buttons on parallel port (Left, Right)


%% training parameters
training.ntrials = 20;
training.nfeedbacktrials = 10;

%% triggers
% values sent to recording sytems on the parallel port

trig.start      = 255;

trig.stim.onset   =  1+2;
trig.stim.leftright   = [0 16];
trig.stim.is_reversal = 32 ;

trig.resp.onset   =  1+4 ;
trig.resp.button  = [ 0 16 0 0 0];   % L / R

trig.fb.onset  = 1+8 ;
trig.fb.is_correct  = 64;
trig.fb.is_proberror= 128;

% Block number (iblock at the start of each block will be coded on 5 bits
trig.blockbits = 5; 

%% eyelink eye-tracker variable:
eyelink=[];

%% screen/display parameters
lumibg          = 0.0;
ppd             = 80;