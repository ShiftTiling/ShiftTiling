
clc;
clear all;
close all;
vs = 1;
ve = 1;

Gap_Height = 126;
Gap_Width = 126;
for videoid = VideoIndex
    for userid = UserIndex
        for seconds = SecondIndex
            for c = 0:5
                data = load(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\LoadRawData\OutputBNM_Xls\',num2str(videoid),'\',num2str(seconds-1),'\',num2str(c),'\C_input.txt']); 
                [x, y] = size(data);
                parfor i = 1:x
                    StartRow = data(i,1);
                    EndRow = data(i,2);
                    StartCol = data(i,3);
                    EndCol = data(i,4);
                    if (EndCol<=30)
                        temp=[(StartRow-1)*Gap_Height,(StartCol-1)*Gap_Width,(EndRow-StartRow+1)*Gap_Height,(EndCol-StartCol+1)*Gap_Width];
                        % i j k l
                        % l k j i
                        command = ['ffmpeg -i E:\comparing-trajectory-clustering-methods-master',...
                            '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
                            num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -c:v libx264  -qp 22 -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                            num2str(temp(1)),' E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'];
                        if ~exist(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'],'file')
                            system(command)
                        end
                    else
                        if StartCol>30
                            temp=[(StartRow-1)*Gap_Height,(StartCol-30-1)*Gap_Width,(EndRow-StartRow+1)*Gap_Height,(EndCol-StartCol+1)*Gap_Width];
                            command = ['ffmpeg -i E:\comparing-trajectory-clustering-methods-master',...
                                '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
                                num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -c:v libx264  -qp 22 -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                num2str(temp(1)),' E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'];
                            if ~exist(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'],'file')
                                system(command)
                            end
                        end
                    end
                    
                    [num2str(seconds),' ',num2str(c),' ',num2str(i),' of ',num2str(x)]
                end
            end
        end
    end
    
end