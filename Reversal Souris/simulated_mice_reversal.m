%% Simulated mice reversal
crit = 10;
ntrial_per_block = 1000;
nmice = 1000;
N = [];
if ~exist('randpick','file')
    randpick = @(x) x(floor(rand*numel(x))+1);
end

PHENOTYPES = {'binomial','D20', 'perseverative'}
PHENOTYPE = PHENOTYPES{listdlg('ListString', ...
    PHENOTYPES,...
    'SelectionMode','single','PromptString','Which phenotype?')};
if isequal(PHENOTYPE,'perseverative')
	prob_switch =.20;
end

for i=1:nmice % :100
    fprintf('Mouse #%d... ',i);
    ntrial = 0;
    nreversal = 0;
    goodlever = randpick(1:2);
    while ntrial <= ntrial_per_block
        rev = false ;
        while ~rev && ntrial <= ntrial_per_block
            switch PHENOTYPE
                
                case 'binomial'
                    % Totally random mouse
                    consecutive_correct = 0;
                    while consecutive_correct < crit && ntrial <= ntrial_per_block
                        ntrial = ntrial+1;
                        if randpick(1:2) == goodlever
                            consecutive_correct = consecutive_correct +1;
                        else
                            consecutive_correct = 0;
                        end
                    end
                    if consecutive_correct >= crit
                        rev = true;
                        nreversal = nreversal + 1;
                    end
                    
                    
                case 'D20'
                    % Some other random mouse
                    dice20 = randpick(1:20);
                    coin = randpick(1:2);
                    
                    if dice20 >= crit && goodlever==coin
                        rev = true;
                        ntrial = ntrial+crit;
                        nreversal = nreversal + 1;
                    else
                        ntrial = ntrial + dice20;
                    end
                    
                case 'perseverative'
                    % Perseverative mouse: switch to other lever 33% of time                   
                    lever = randpick(1:2);
                    consecutive_correct = 0;
                    while consecutive_correct < crit && ntrial <= ntrial_per_block
                        ntrial = ntrial+1;
                        if lever == goodlever
                            consecutive_correct = consecutive_correct +1;
                        else
                            consecutive_correct = 0;
                        end
                        if rand < prob_switch
                            lever = 3-lever;
                        end
                    end
                    if consecutive_correct >= crit
                        rev = true;
                        nreversal = nreversal + 1;
                    end
                    
            end
        end
        % Now we reverse
        goodlever = 3-goodlever;
        
    end
    N(i,1) = nreversal;
    fprintf(' did %d reversals (according to criteria)\n',nreversal);
end

fprintf('CONCLUSION:\n');

fprintf('With the "%s" phenotype, we observed on average %f reversals across our %d mice, each performing %d trials.\n', PHENOTYPE, mean(N(:)), nmice,ntrial_per_block);