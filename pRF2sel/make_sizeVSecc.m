 %% plots prf fits as circles
% rl, 08/14

clear all; clc; close all; 
bookKeeping;

% turn off text interpreter
set(0, 'DefaultTextInterpreter', 'none'); 

%% don't modify here
tem.groupControls    = 1:10; 
tem.groupPoorReaders = 11;
tem.groupEveryone    = 1:11; 

%% modify here

% will we threshold the data?
tem.YNthreshold = 1; 

% which subjects or group to look at?
tem.subjectsToAnalyze = tem.groupControls; 

% description of group if applicable
tem.groupName = 'Controls'; 

% are we going to average and boostrap over the group?
tem.YNgroupAverage = 1; 

% degree of polynomial to fit for the individual
tem.polyDegInd = 1; 

tem.listRoi = {
%    'left_wordVscramble_all'
    'left_wordVscramble_restrict'
%     'LV1'
%     'LV2d'
%     'LV2v'
%     'LV3d'
%     'LV3v'
%     'LV3ab'
%     'LhV4'
%     'LVO-1'
%     'LVO-2'
%     'LTO-1'
%     'LTO-2'
%     'LIPS-0'  
%    'right_wordVscramble_all'
    'right_wordVscramble_restrict'
%     'RV1'
%     'RV2d'
%     'RV2v'
%     'RV3d'
%     'RV3v'
%     'RV3ab'
%     'RhV4'
%     'RVO-1'
%     'RVO-2'
%     'RTO-1'
%     'RTO-2'
%     'RIPS-0'
%     'CwordVscramble_all'
    'CwordVscramble_restrict'
%     'CV1'
%     'CV2d'
%     'CV2v'
%     'CV3d'
%     'CV3v'
%     'CV3ab'
%     'ChV4'
%     'CVO-1'
%     'CVO-2'
%     'CTO-1'
%     'CTO-2'
%     'CIPS-0'   
    };


%% thresholds on roi and plotting
h.threshco      = 0.1;       % minimum of co
h.threshecc     = [.5 12];   % range of ecc
h.threshsigma   = [0 24];    % range of sigma
h.minvoxelcount = 10;        % minimum number of voxels in roi

%% parameters for making prf coverage
vfc.prf_size        = true;      % if 0 will only plot the centers
vfc.fieldRange      = 12;        % radius of stimulus
vfc.method          = 'maximum profile';        % method for doing coverage.  another choice is density
vfc.newfig          = true;      % any value greater than -1 will result in a plot
vfc.nboot           = 200;       % number of bootstraps
vfc.normalizeRange  = true;      % set max value to 1
vfc.smoothSigma     = true;      % this smooths the sigmas in the stimulus space.  so takes the 
                                 % median of all sigmas within
vfc.cothresh        = h.threshco;        
vfc.eccthresh       = h.threshecc; 
vfc.nSamples        = 128;       % fineness of grid used for making plots     
vfc.meanThresh      = 0;         % threshold by mean map, no way to use this at the moment
vfc.weight          = 'fixed';  
vfc.weight          = 'variance explained';
vfc.weightBeta      = 0;         % weight the height of the gaussian
vfc.cmap            = 'hot';						
vfc.clipn           = 'fixed';                    
vfc.threshByCoh     = false;                
vfc.addCenters      = true;                 
vfc.verbose         = 1;         % print stuff or not
vfc.dualVEthresh    = 0;
vfc.binsize         = 0.5;


%% save folder paths and logistics
tem.saveFolderSub    = ['co' num2str(h.threshco) ...
    '.ecc' num2str(h.threshecc(1)) '_' num2str(h.threshecc(2)) ...
    '.sig' num2str(h.threshsigma(1)) '_' num2str(h.threshsigma(2))...
    '.minvox' num2str(h.minvoxelcount)]; 
tem.saveFolderSingle = ['/biac4/wandell/data/reading_prf/forAnalysis/images/single/sizeVSecc/' tem.saveFolderSub '/'];
tem.saveFolderGroup  = ['/biac4/wandell/data/reading_prf/forAnalysis/images/group/sizeVSecc/' tem.saveFolderSub '/']; 

% make these directories if they do not exist
if ~exist(tem.saveFolderSingle, 'dir'), mkdir(tem.saveFolderSingle), end
if ~exist(tem.saveFolderGroup, 'dir'), mkdir(tem.saveFolderGroup), end


for jj = 1%:length(tem.listRoi)
    
     tem.roi = tem.listRoi{jj};  
    
    % load the RM struct for this roi
    tem.RMfolder    = '/biac4/wandell/data/reading_prf/forAnalysis/structs/'; 
    tem.RMpath      = cellstr([tem.RMfolder 'RM_' tem.roi '.mat']);
    tem.RMpath      = tem.RMpath{1}; 
    load(tem.RMpath); 
    
    
    %% if THRESHOLDING the data
    if tem.YNthreshold
        
        % threshold the data 
        % RM_th will be a struct of size equal to or less than RM.
        % squeezing out empty matrices
        RM_th = ff_thresholdRMData(RM,h);
        tem.goodCounter = 0; 
        
        for ii = 1:length(tem.subjectsToAnalyze)
            
            iisub = tem.subjectsToAnalyze(ii); 
            
            % check that subject has corresponding good data for roi
            tem.passesThreshold = ff_checkRMThreshFor(list_sub{iisub}, RM_th); 
            
            % if subject passes threshold
            if tem.passesThreshold
                tem.goodCounter = tem.goodCounter + 1; 
                
                % find the RM_th index corresponding to iisub
                iisubRMth = ff_checkRMThreshForIndOf(list_sub{iisub}, RM_th); 
                
                % redefine for ease of use
                rm_th = RM_th{iisubRMth}; 
                
                %% function for plotting size vs ecc (below here)
                figure();
                plot(rm_th.ecc, rm_th.sigma1,'.k'); 
                xlabel('Eccentricity (degrees)', 'FontSize', 14)
                ylabel('pRF sigmas','FontSize',14)
                hold on
                
                % solve for the regression line
                % polyfit returns a vector of lower order terms to higher
                % order terms
                tem.regCoef = polyfit(rm_th.ecc, rm_th.sigma1,1);  
                
                % plot the regression line
                tem.x = linspace(0,round(max(rm_th.ecc))); 
                tem.y = polyval(tem.regCoef, tem.x); 
                
                plot(tem.x, tem.y); 
                xlabel('Eccentricity of pRF centers in degrees','FontSize', 14); 
                ylabel('Size of pRF sigmas in degrees','FontSize', 14); 
                legend('Raw'); 
                %% function for plotting size vs ecc (above here)
                
                title([rm_th.subject '. ' tem.roi], 'FontSize', 24)
                %* saveas(tem.handleContour, [tem.saveFolderSingle, tem.roi '_' RM_th{iisubRMth}.subject '.jpg'])
            
                
                
                %% function for getting bootstraps for the individual 
                % as opposed to the group
                booti.nsteps = 500;  % number of bootstrapping steps
                
                % for each bootstrapping test, sample from the data with
                % replacement
                
                % - initialize matrix for all samples
                % booti.allSamples is a m x n matrix, where m is the number
                % of prf centers and n is the number of bootstrapping steps
                booti.allSamplesEcc = zeros(length(rm_th.ecc), booti.nsteps); 
                booti.allSamplesSig = zeros(length(rm_th.sigma1), booti.nsteps); 
                booti.allCoefs      = zeros(length(rm_th.ecc), 2); 
                
                % - intialize vector of random numbers
                booti.rind = randi(length(rm_th.ecc), [1 booti.nsteps]); 
                
                % sample with replacement
                for nn = 1:booti.nsteps
                    for mm = 1:length(rm_th.ecc)
                        booti.allSamplesEcc(mm,nn) = rm_th.ecc(booti.rind(mm)); 
                        booti.allSamplesSig(mm,nn) = rm_th.sigma1(booti.rind(mm));
                    end 
                    
                    % fit a line for each bootstrapping step
                    tem.x = booti.allSamplesEcc(:,nn); 
                    tem.y = booti.allSamplesSig(:,nn); 
                    % and store them
                    booti.allCoefs(nn,:) = polyval(tem.x, tem.y , tem.polyDegInd); 
                    
                end
                
                % we can then take the mean over all these fitted lines
                booti.meanCoefs = mean(booti.allCoefs); 
                
                % and plot it
                tem.xx = linspace(0,round(max(rm_th.ecc))); 
                tem.yy = polval(tem.xx, booti.meanCoefs); 
                
                hold on
                plot(tem.xx, tem.yy); 
               
               
                
                
                %% 
                
                
            % if subject DOES NOT pass the threshold
            else
                figure()
                tem.fh = gcf;
                title([list_sub{iisub} '. ' tem.roi], 'FontSize', 24)
                saveas(tem.fh, [tem.saveFolderSingle, tem.roi '_' list_sub{iisub} '.jpg']); 
                
            end %% END: whether or not subject passes threshold, RFcov behavior
            
        end %% END: for every subject in tem.subjectsToAnalyze
        
    end %% END: if we are thresholding the data
  
    
    
    
%      %% group bootstrapping (if applicable). if want to bootstrap, must threshold data
% 
%     switch tem.YNgroupAverage
%         
%         case 0
%             % don't do anything
%         
%         case 1
%             % make there are elements in this group to boostrap over
%             if exist('RFcov','var')
%                 % number of bootstrapping steps
%                 boot.nsteps     = 100; 
% 
%                 % variable to hold all nsteps of bootstrap samples
%                 boot.allSamples = zeros(size(RFcov{1}), size(RFcov{1}), boot.nsteps); 
%                 % variable for individual bootstrap passes
%                 boot.oneSample = zeros(size(RFcov{1}), size(RFcov{1}), length(RFcov)); 
% 
%                 for bb = 1:boot.nsteps
%                    % get a random sample
%                    boot.ind = randi(length(RFcov), [1 length(RFcov)]); 
% 
%                    % extract those images
%                    for bx = 1:length(boot.ind)
%                         boot.oneSample(:,:,bx) = RFcov{boot.ind(bx)}; 
%                    end
% 
%                    % take mean and add to boot.allSamples
%                    boot.allSamples(:,:,bb) = mean(boot.oneSample, 3); 
% 
%                 end
% 
%                 figure(); 
%                 tem.figHandleBoot = ff_pRFasContours(mean(boot.allSamples,3));
%                 title(['Group Average:' num2str(tem.groupName) tem.roi],'FontSize',24);
%                 saveas(tem.figHandleBoot, [tem.saveFolderGroup, tem.roi '_' tem.groupName '_GroupAverage'  '.jpg'])
%                 
%             end
%             
%     end %% END: switch tem.YNgroupAverage
%     
%     
%     
%     clear RM RM_th RFcov tem.roi
%     close all; 
        
    
    
end