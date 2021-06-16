%用来切分所有basic tile以及整个大的视频
clc;
clear all;
close all;
vs = 1;
ve = 1;

Gap_Height = 126;
Gap_Width = 126;
for videoid = VideoIndex
    for seconds = SecondIndex
        data = [];
        for i = 1:15
            for j =1:30
                data = [data;i,i,j,j];
            end
        end
        [x,~] = size(data);
        parfor i = 1:x
            StartRow = data(i,1);
            EndRow = data(i,2);
            StartCol = data(i,3);
            EndCol = data(i,4);
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
        end
        
        data = [1,15,1,30];
        
        [x,~] = size(data);
        for i = 1:x
            StartRow = data(i,1);
            EndRow = data(i,2);
            StartCol = data(i,3);
            EndCol = data(i,4);
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
        end
    end
    
end