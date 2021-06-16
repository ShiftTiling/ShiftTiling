clear all;
close all;
clc;
%root = 'F:\shiftTile\DriftTileStaticTile';
root = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\data';

load('BPnet.mat');%%%
tic
dirVid = dir(root);
for vid=1:45
    vid
    for secID = 1:60
        try
            C_Input = load([root,'\',num2str(vid),'\',num2str(secID),'\C_Input.txt']);
        catch
            [vid,secID,1:5]
            continue;
        end
        
        for clusID = 0:4
            disp([num2str(vid),'\',num2str(secID),'\',num2str(clusID)]);
            input = load([root,'\',num2str(vid),'\',num2str(secID),'\',num2str(clusID),'\C_Input.txt']);
            normalInput = input(input(:,5)<1e7,5:9);
            normalInput=normalInput';
            mapInput = mapminmax('apply',normalInput,setting1);
            mapResult = sim(net,mapInput);
            normalResult = mapminmax('reverse',mapResult,setting2);
            
            normalResult = normalResult';
            
            result = zeros(size(input,1),1);
            result(input(:,5)<1e7,1) = normalResult;
            result(input(:,5)>=1e7,1) = 1e8;
            %result(result(:,1)<input(:,10),1) = 1e8;
            for row=1:size(result,1)
                if result(row,1)>1e7
                    continue;
                end
                area=(input(row,2)-input(row,1)+1)*(input(row,4)-input(row,3)+1);
                result(row,1)=max(result(row,1),area*input(row,10)*0.5);
            end
            dlmwrite([root,'\',num2str(vid),'\',num2str(secID),'\',num2str(clusID),'\C.txt'], result,' ');
            % fid=fopen([path,'C.txt'],'a');
            % for i=1:length(result)
            %     fprintf(fid,'%f\t',result(i));
            % end
            % fclose(fid);
        end
    end
end
toc