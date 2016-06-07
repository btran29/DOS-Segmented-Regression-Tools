function [  ] = outputUnbinnedNIRSWithTime(  )
% Output Data - Unbinned CSV format with ramp start adjusted time  %
% TODO: FIX TO WORK WITHOUT USE OF DATASET DATA TYPE

% if nirs2rampstartcsv % manually set to to true or false in script input
%     disp('Outputting unbinned ramp adjusted time CSVs..')
%     % Get current directory if not already present
%     if exist('currentdir','var') == 0 %#ok<UNRCH>
%         currentdir = pwd; 
%     end
% 
%     % Create new binned figures folder if not already present
%     unbinnedrampadjtimefolder = 'Data - unbinned with ramp adjusted time';
%     if exist(...
%             [currentdir '\' unbinnedrampadjtimefolder],...
%             'dir') == 0
%         mkdir(unbinnedrampadjtimefolder)
%     end
% 
%     % Process will take ~1 min for each file
%     % Requires dataset data type support
%     for iFilesOfInterest = 1:length(fileType(idxFilesOfInterest)) 
%         pocketnirslog = importNIRSdata(fileType(iFilesOfInterest).name);
%         pocketnirs
% 
%         % Locate ramp start using selected event marker.
%         for iRow = 1:length(pocketnirslog.Event)
%             if isequal(pocketnirslog.Event,[''' inputrampstarteventmarkers(iFilesOfInterest)])
%                 idxrampstart = iRow
%             end
%         end
%         % Add in adjusted time column
%         pocketnirslog.RampStartAdjTime = pocketnirslog.ElapsedTime - pocketnirslog.ElapsedTime(idxrampstart);
% 
%         % Export to csv file in new folder
%         filename = [strrep(fileType(iFilesOfInterest).name,'.PNI',''),...
%             label, '.csv'];
%         cd([currentdir '\' unbinnedrampadjtimefolder])
%         export(pocketnirslog,'file',filename,'Delimiter',',')
%         cd(currentdir)
%     end
% end
end

