clear all;
close all;
clc;

tic
root='dataOpTile';
dirVid = dir(root);
dirVid = dirVid(3:end);
parfor vidIndex = 1:length(dirVid) %¸Ä
    vid = dirVid(vidIndex).name;

    vid
    %mkdir([resultPath,'/',num2str(vid)]);
    OpTile_SegFunction(vid);
end

'3 tiling'
toc
% timeTotal = toc;
% timeP1 / timeTotal
% timeP2 / timeTotal
% timeILP / timeTotal