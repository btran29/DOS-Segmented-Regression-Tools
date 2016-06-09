function [  ] = makeFolderCheck( currentDir,folder,label )
%makeFolderCheck check for folder, if not present, mkdir
%   Requires administrative rights to make a directory.
%
% Inputs
%   1. currentDir, string
%        current directory to check if the folder is present
%   2. folder, string
%        name that you would like to check for, then make if not present
%
% Outputs
%   None
%
if exist(...
        [currentDir '\' folder],...
        'dir') == 0
    mkdir(folder)
end

% Create a new variables subfolder if not already present
if exist(...
        [currentDir '\' folder '\' label],...
        'dir') == 0
    cd([currentDir '\' folder])
    mkdir(label)
    cd(currentDir)
end

end

