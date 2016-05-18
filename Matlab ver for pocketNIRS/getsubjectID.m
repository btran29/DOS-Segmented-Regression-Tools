function [ subjectIdentifier ] = getsubjectID( filename )
%LDF Summary of this function goes here
% Find subject IDs via regex and multiple expressions. Expressions are
% tried sequentially.
%
% Input
% 	1. filename, string
%   Formats which the current expressions work with:
%   	subject IDs are 3 or 4 digit numbers
%  		pocket_nirs_log_20160101_13.23.19_999_AA_CH1_right_CH2_left_15WR.PNI
%  		pocket_nirs_log_20160101_13_03_39_Test_9999_AA_CH1_left_CH2_right_WR15.PNI
%  		9999_AA_CH1right_CH2left_15wts_pocket_nirs_log_20160101_13.23.19.PNI
%
% Output
%	1. subjectIdentifier, string
%

% Rules for cleaning up file names
expression = '\d\d\d\d_[A-Z][A-Z]_'; % Search for ID + 2 lett initials
expression2 = '\d\d\d\d_[A-Z][A-Z][A-Z]_'; % ID + 3 letter initials
expression3 = '\d\d\d_[A-Z][A-Z]_'; % 3 number ID + 2 lett initials

% Use expression 1
idx = regexp(filename,expression);
if isempty(idx) == 1
    idx = regexp(filename,expression);
end
% If expression 1 does not work, use expression 2
if isempty(idx) == 1
    idx = regexp(filename,expression2);
end
% If expression 2 does not work, use expression 3
if isempty(idx) == 1
    idx = regexp(filename,expression3);
end

% Remove excess alphabetic characters and underscores
subjectIdentifier = filename(idx:idx+4);
subjectIdentifier = strrep(subjectIdentifier,'_','');
subjectIdentifier = regexprep(subjectIdentifier,'[A-Z]','');
end

