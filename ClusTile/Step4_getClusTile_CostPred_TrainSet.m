clear all;
close all;
clc;

tic
root='data';
dirVid = dir(root);
dirVid = dirVid(3:end);
parfor vidIndex = 1:length(dirVid) %��
    vid = dirVid(vidIndex).name;
    vid
    %mkdir([resultPath,'/',num2str(vid)]);
    ClusFunction(vid);
end
'4 tiling����'
toc
% timeTotal = toc;
% timeP1 / timeTotal
% timeP2 / timeTotal
% timeILP / timeTotal