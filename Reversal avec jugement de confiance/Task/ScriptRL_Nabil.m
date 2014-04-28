
function data=run
if ~IsPsychJavaPathSet, AddPsychJavaPath, end
try
    clear all
    clc
    Screen('Preference', 'SkipSyncTests', 1);
    KbName('UnifyKeyNames');
    screenId=0;
    flipSpd=13;
    [machine,machine]=system('hostname');
    machine=machine(1:end-1);
    
    %PARAMETRES (+couleurs plus bas)
    %     nblocs=1000; %nombre de reversal
    %
    %     ppe(1)=30/100;  % "pourcentage" de chance pour que le bon stim ait pour feedback 'faux'
    %     ppe(2)=60/100; % "pourcentage" de chance pour que le mauvais stim ait pour feedback 'faux'
    %     nrrepmin=4; % nombre de bonnes reps consï¿½cutives avant reversal (min)
    %     nrrepmax=4;
    %     prev=25; %probabilitï¿½ de reversal aprï¿½s nrrep bonnes reps consï¿½cutives
    %     ntrialsmax = 2000;
    %     esppause=30; %nombre d'essais sï¿½parant les pauses
    %     EndTime=3660; %temps max
    %     Pointsmax= 1200;
    
    
    %Nom=input('Nom? : ','s');
    Nom=strcat('subject',num2str(getRealNumber()));
    
    switch machine
        case 'experiment-desktop'
            [w, wRect]=Screen('OpenWindow', screenId, 0, [1280 0 1280+1680 1050]);
            consdir='/home/experiment/bebg/RL/Consignes';
        case 'bebg-7cb864a14e'
            [w, wRect]=Screen('OpenWindow', screenId, 0);%, [0 0 800 600]);
            consdir='C:/Documents and Settings/Gabrielle Florin/Mes documents/Mes images/Consignes';
        case 'SFX-Ultrabook' % Laptop Nabil
            [w, wRect]=Screen('OpenWindow', screenId, 0);%, [0 0 1920 1080]);
            consdir='D:\SFX\Perso\Recherche\Psycho expé\Probabilistic reversal lerning\Consignes';

        otherwise
            [w, wRect]=Screen('OpenWindow', screenId, 0, [0 0 800 600]);
            consdir=fullfile(fileparts(mfilename('fullpath')),'Consignes');
    end
    
    [wW, wH]=WindowSize(w);
    
    black=BlackIndex(w);
    white=WhiteIndex(w);
    
    colbg=white; %couleur background
    
    monitorFlipInterval=Screen('GetFlipInterval', w);
    
    Cons{1}=imread(fullfile(consdir,'Cons1.PNG'));
    Cons{2}=imread(fullfile(consdir,'Cons2.PNG'));
    Cons{3}=imread(fullfile(consdir,'Cons3.PNG'));
    Cons{4}=imread(fullfile(consdir,'Cons4.PNG'));
    Cons{5}=imread(fullfile(consdir,'Cons5.PNG'));
    
    Screen('TextSize', w , 25);
    
    consignes(w, wW, wH, Cons{1});
    
    Expe('training1',Nom,machine,w,wRect,wW,wH,black,white,colbg,3,[0 1],4,4,25,6,100,300,1000);
    Screen('FillRect',w,colbg);
    Screen(w, 'Flip');
    WaitSecs(1);
    
    consignes(w, wW, wH,Cons{2});
    consignes(w, wW, wH,Cons{3});
    
    Expe('training2',Nom,machine,w,wRect,wW,wH,black,white,colbg,1,[20/100 80/100],15,15,100,6,100,420,1000);
    Screen('FillRect',w,colbg);
    Screen(w, 'Flip');
    WaitSecs(1);
    
    consignes(w, wW, wH,Cons{4});
    consignes(w, wW, wH,Cons{5});
    
    Expe('Main',Nom,machine,w,wRect,wW,wH,black,white,colbg,1000,[20/100 80/100], 5 ,7,25,Inf,50,15*60,Inf);
    
catch %ME
    cleanexit()%fid)
    %rethrow(ME)
    %fprintf('Il y a eu une erreur !\n')
    
end
cleanexit()%fid)

function Expe(Etape,Nom,machine,w,wRect,wW,wH,black,white,colbg,nblocs,ppe,nrrepmin,nrrepmax, prev,ntrialsmax,esppause, EndTime,Pointsmax)
% ppe = err probabiliste 
% nrrepmin : min number of repetition
% prev = prob reversal en %
% ntrialsmax : 

data = struct;
data.Etape=Etape;
data.hostname=machine;
stimHor=102; %hauteur originale des stims
stimWor=135; %largeur originale des stims
Points1= 0;%
Points=0;
randprev=100;

Date=datestr(now,30);
ListenChar(2);
data.subjectname = Nom;
data.ppe(1)=ppe(1);
data.ppe(2)=ppe(2);
data.start_time = GetSecs();
% Nom/Num de version du script
data.mfilename = mfilename;
data.filename = fullfile(pwd, sprintf('reversal_%s_%s_%s',Nom,Etape,datestr(now,30)));
data.textfile = strcat(Nom, '.txt');
fid = fopen(data.textfile, 'at');
fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'machine', 'sujet','Etape','date','kblocs','ntrials','nrrep','trep','prep','grep','fdrep','time','presstime','ftime','fpresstime','fkey','conf','nh');

kblocs=0;
stimF=7*stimWor/wW;
stimW=stimWor/stimF;
stimH=stimHor/stimF;


Screen('FillRect',w,colbg);
Screen(w, 'Flip');
WaitSecs(1);

HideCursor;

%tï¿½lï¿½chargement images
%stimdir = '/Users/ndiaye/expe/Symbols/';

switch data.hostname
    case 'experiment-desktop'
        stimdir= '/home/experiment/bebg/stims/agathodaimon';
    case 'lscp-Ulm03'
        stimdir='D:/Gabrielle/RL/Stims';
    case 'bebg-7cb864a14e'
        stimdir= 'C:/Documents and Settings/Gabrielle Florin/Mes documents/Mes images/Stims';
    otherwise
        stimdir=fullfile(fileparts(mfilename('fullpath')),'Stims');      
end

if not(exist(stimdir))
    error(['No folder: ' stimdir]);
end
listeStim= dir(stimdir);


numStim(1)=randi([3,length(listeStim)-1]);
numStim(2)=numStim(1);

while numStim(2)==numStim(1)
    numStim(2)=randi([3,length(listeStim)-1]);
end

Stim{1}=imread(fullfile(stimdir,listeStim(numStim(1)).name));
Stim{2}=imread(fullfile(stimdir,listeStim(numStim(2)).name));
data.Stim{1} =listeStim(numStim(1)).name;
data.Stim{2} =listeStim(numStim(2)).name;

assignin('base', 'data', data)

ntrials = 1;
rev=0;
krrep=0;
trep=randi([1,2]);

Screen('FillRect',w, colbg);
Screen(w, 'Flip');

while kblocs<nblocs && ntrials <= ntrialsmax && GetSecs()-data.start_time<EndTime
    
    nrrep=randi([nrrepmin,nrrepmax]); %nombre de bonnes rï¿½ponses consï¿½cutives nï¿½cessaires pour changer la trep
    data.trial(ntrials).nrrep = nrrep;
    
    %     l1=ones(1,nrr);
    %     l2=ones(1,ppe)+1;
    %     liste=[l1 l2];
    %     liste=liste(:,randperm(size(liste,2)));
    
    
    while ((krrep<nrrep && rev<=1)||rev==1) &&ntrials <= ntrialsmax&& Points<Pointsmax
        Screen('FillRect',w, colbg);
        
        %codage du feedback par stimulus (1: bon stim/2: mauvais stim)
        for i=1:2
            if rand>ppe(i)
                frep(i)=1; %feedback 'vrai' (vert)
            else
                frep(i)=0;   %feedback 'faux' (rouge)
            end
            data.trial(ntrials).frep(i) = frep(i) ;
        end
        
        %Affichage des Stims
        randlieu=randi([0,1]);
        prep='d';
        %             for i=1:2
        %                 k=(xor(randlieu==1,i==1)*2+1);
        %                 lieu(i) = [ k*wW/5 (wH/2)-(stimH/2) (k*wW/5)+stimW (wH/2)+(stimH/2)];
        %             end
        
        if randlieu==1
            lieu{1}=[  wW/5 (wH/2)-(stimH/2) (  wW/5)+stimW (wH/2)+(stimH/2)];
            lieu{2}=[3*wW/5 (wH/2)-(stimH/2) (3*wW/5)+stimW (wH/2)+(stimH/2)];
            if trep==1
                prep='g';
            end
        else
            lieu{1}=[3*wW/5 (wH/2)-(stimH/2) (3*wW/5)+stimW (wH/2)+(stimH/2)];
            lieu{2}=[wW/5 (wH/2)-(stimH/2) (wW/5)+stimW (wH/2)+(stimH/2)];
            if trep==2
                prep='g';
            end
        end
        data.trial(ntrials).prep = prep;
        
        texture1=Screen('MakeTexture', w, double(Stim{1}));
        Screen('DrawTexture', w, texture1, [], lieu{1});
        texture2=Screen('MakeTexture', w, double(Stim{2}));
        Screen('DrawTexture', w, texture2, [], lieu{2});
        Croix(w,wW,wH,stimW);
        Flech(w,wW,wH,stimW,[1,2,3,-1,-2,-3])
        Screen(w, 'Flip');
        
        %frep=liste(krr);
        
        %collecte de la rï¿½ponse
        k=0;
        t=GetSecs();
        compt=0;
        c=38;
        first=0;
        nh=1; %nombre d'hï¿½sitations
        while not(isequal(KbName(c),'DownArrow'))||compt==0
            %attends une rï¿½ponse
            while k==0
                [k,s,c]=KbCheck;
            end
            k2=1;
            while k2==1
                [k2,s2,c2]=KbCheck;
            end
            presstime = s2-s;
            time=s-t;
            key=KbName(c);
            
            data.trial(ntrials).event(nh).presstime=presstime;
            data.trial(ntrials).event(nh).time=time;
            data.trial(ntrials).event(nh).key=key;
            
            %relï¿½ve la premiï¿½re frappe
            if first==0
                ftime=time;
                fpresstime=presstime;
                fkey=key;
                first=1;
                data.trial(ntrials).event(nh).fpresstime=fpresstime;
                data.trial(ntrials).event(nh).ftime=ftime;
                data.trial(ntrials).event(nh).fkey=fkey;
            end
            
            
            
            %dï¿½place le curseur
            if isequal(key,'LeftArrow')&&compt>-3
                compt=compt-1;
                if compt==0
                    compt=compt-1;
                end
            elseif isequal(key,'RightArrow')&&compt<3
                compt=compt+1;
                if compt==0
                    compt=compt+1;
                end
            elseif isequal(key,'a')
                cleanexit(fid);
            elseif isequal(key,'z')
                pause1(w, wW, wH)
            end
            
            data.trial(ntrials).event(nh).compt=compt;
            
            texture1=Screen('MakeTexture', w, double(Stim{1}));
            Screen('DrawTexture', w, texture1, [], lieu{1});
            texture2=Screen('MakeTexture', w, double(Stim{2}));
            Screen('DrawTexture', w, texture2, [], lieu{2});
            Croix(w,wW,wH,stimW);
            Flech(w,wW,wH,stimW,[1,2,3,-1,-2,-3]);
            if compt~=0
                Flech(w,wW,wH,stimW,[compt]);
            end
            
            Screen(w, 'Flip');
            k=0;
            k2=1;
            nh=nh+1;
        end
        
        nh=nh-2-abs(compt); % compte les mouvements superflus
        
        if compt<0
            lieuRep=[(wW/5)-15 (wH/2)-(stimH/2)-15 (wW/5)+stimW+15 (wH/2)+(stimH/2)+15];
            if prep=='g'
                grep=trep;
                afrep=frep(1);
            else
                grep=-(trep-3);
                afrep=frep(2);
            end
        elseif compt>0
            lieuRep=[3*wW/5-15 (wH/2)-(stimH/2)-15 (3*wW/5)+stimW+15 (wH/2)+(stimH/2)+15];
            if prep=='d'
                grep=trep;
                afrep=frep(1);
            else
                grep=-(trep-3);
                afrep=frep(2);
            end
        end
        
        data.trial(ntrials).grep=grep;
        data.trial(ntrials).afrep=afrep;
        
        Screen('FillRect',w, colbg);
        if afrep==1
            colRep=[0 255 0];
            Points1=Points1+1;
            if abs(compt)==1
                score='+1';
            elseif abs(compt)==2
                score='+3';
            elseif abs(compt)==3
                score='+4';
            end
        else
            colRep=[255 0 0];
            if abs(compt)==1
                score='0';
            elseif abs(compt)==2
                score='-2';
            elseif abs(compt)==3
                score='-4';
            end
        end
        Points=Points+str2double(score) 
        fprintf('Compt: %+d \t Points: %d\n',compt, Points);
        
        %affiche la rï¿½ponse
        Screen('FillRect',w, colRep, lieuRep);
        texture1=Screen('MakeTexture', w, double(Stim{1}));
        Screen('DrawTexture', w, texture1, [], lieu{1});
        texture2=Screen('MakeTexture', w, double(Stim{2}));
        Screen('DrawTexture', w, texture2, [], lieu{2});
        Croix(w,wW,wH,stimW);
        if Etape(1)=='t'
            Screen('DrawText', w, strcat(score,' points!'),(wW/2)-20, (wH/2)+200, [0 0 0]);
        end
        
        Screen(w, 'Flip');
        WaitSecs(0.75);
        
        
        if grep==trep
            krrep=krrep+1; %compte les bonnes rï¿½ponses consï¿½cutives
        else
            krrep=0;
            rev=0;
        end
        
        if rev==1
            rev=2;
        end
        
        %         %donne le feedback
        %         Screen('FillRect',w, colbg);
        %         if grep==frep
        %             Screen('DrawText', w, 'vrai' ,wW/3 ,wH/2 ,[0 255 0]);
        %         else
        %             Screen('DrawText', w, 'faux' ,wW/3 ,wH/2 ,[255 0 0]);
        %         end
        %         Screen(w, 'Flip');
        %         tic
        %         while toc<0.7
        %             ;
        %         end
        %
        fprintf(fid,'%s\t%s\t%s\t%s\t%g\t%g\t%g\t%g\t%s\t%g\t%g\t%g\t%g\t%g\t%g\t%s\t%g\t%g\n', data.hostname, Nom, Etape,Date, kblocs, ntrials, nrrep, trep, prep, grep, afrep, time, presstime, ftime, fpresstime, fkey, abs(compt), nh);
        
        if mod(ntrials,esppause)==0
            pause(w,wW,wH,Points,Points1,ntrials);
        end
        Screen('FillRect',w, colbg);
        Croix(w,wW,wH,stimW);
        Screen(w, 'Flip');
        tic
        while toc<0.3
            ;
        end
        ntrials = ntrials +1;
        
        %         fprintf('%d points  |   %d trials  |  Bloc de BR consecutives: %d \n', Points, ntrials,krrep);
        fprintf('%d trep  | %d grep  | %d reversal  | %d trials  | %d probnnrev | Bloc de BR consecutives: %d \n', trep,grep,kblocs, ntrials,randprev,krrep);
        assignin('base', 'data', data);
        save(data.filename, 'data');
        paiement(Points,Etape);
        
    end
    rev=1;
    randprev=randi([0,100]);
    
    if  randprev<=prev&&rev==1
        trep=-(trep-3);
        rev=0;
        krrep=0;
        kblocs=kblocs+1;%nombre de rï¿½versals
        %         elseif  rev==1
        %             rev=0;
        %             krrep=krrep
    end
    
    data.trial(ntrials).trep =trep;
    
end
   
    
if Etape(1)=='M'
    Etape='Fini';
    paiement(Points,Etape)    
    Screen('FillRect',w, [255,255,255]);
    Screen('DrawText', w,'Fin de l''expérience',50, 30, [0 0 0]);
    Screen('DrawText', w, strcat('Vous avez gagné  ',num2str(floor((Points+99)/100)),' euros'),50, (wH/2)-10, [0 0 0]);
    Screen(w, 'Flip');
    kfin='fini';
    while not(isequal(kfin,'Return'))
        i=0;
        while i==0
            [i,s3,c3]=KbCheck;
        end
        kfin=KbName(c3);
    end
end
paiement(Points,Etape)    
save(data.filename, 'data');
fprintf('%s %d\n %s %d\n','pourcentage erreurs probabilistiques : ',ppe, 'changement de rep tous les ',nrrep);


function cleanexit()%fid)
ListenChar(0)
Screen('CloseAll')
%fclose(fid);
ShowCursor;
exit;

function pause(w, wW, wH,Points,Points1,ntrials)
Screen('FillRect',w, [255,255,255]);
t1=GetSecs();
t2=GetSecs();
tpause=30;
while t2-t1<tpause
    Screen('DrawText', w, strcat('Pause. Reprise dans : ',num2str(floor(tpause-t2+t1))),50, (wH/2)-100, [0 0 0]);
    Screen('DrawText', w, strcat('Vous avez : ',num2str(Points),' points'),50, (wH/2)-10, [0 0 0]);
    Screen(w, 'Flip');
    t2=GetSecs();
end

function paiement(Points,Etape)
finifid = fopen('paiement.txt', 'wt');
paie = ceil(Points/100);
fprintf(finifid,'%s %d %d %d\n',Etape,Points, paie, paie+5);
fclose(finifid);

function pause1(w, wW, wH)
Screen('FillRect',w, [255,255,255]);
Screen('DrawText', w, 'Pause. Pour reprendre appuyer sur Entree',50, (wH/2)-10, [0 0 0]);
Screen(w, 'Flip');
kpause='oups';
while not(isequal(kpause,'Return'))
    i=0;
    while i==0
        [i,s3,c3]=KbCheck;
    end
    kpause=KbName(c3);
end

function consignes(w, wW, wH, Cons)
Screen('FillRect',w, [255,255,255]);
texture=Screen('MakeTexture', w, double(Cons));
Screen('DrawTexture', w, texture, []);
Screen(w, 'Flip');
WaitSecs(2)
kcons='oups';
while not(isequal(kcons,'Return'))
    i=0;
    while i==0
        [i,s3,c3]=KbCheck;
    end
    kcons=KbName(c3);
end



function Croix(w,wW,wH,stimW)
croixH= wH/2;
croixW=(4*wW/10)+(stimW/2);
colcroix=[0 0 0];
l=10; %longueur croix
e=2; %ï¿½paisseur croix

Screen('DrawLine',w,colcroix, croixW-l, croixH-l, croixW+l, croixH+l,  e);
Screen('DrawLine',w,colcroix, croixW-l, croixH+l, croixW+l, croixH-l,  e);


function Flech(w,wW,wH,stimW,pos)
long=(wW/5)-(stimW/2);
haut=wH/60; %hauteur flï¿½che
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

function [nsub compname]=getRealNumber()
address=java.net.InetAddress.getLocalHost;
IPaddress=char(address.getHostAddress);
compname=char(address.getHostName);
ipstring=regexp(IPaddress,'\.','split');
nsub=str2double(ipstring{4});

