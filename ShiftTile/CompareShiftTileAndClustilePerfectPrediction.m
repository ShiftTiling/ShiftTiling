clc;
clear all;
close all;

Height = 1440;     %֡�߶�
Width = 2880;     %֡���
V_Height = (Height/180*100)/2-1;%�Ӵ��߶�
V_Width = (Width/360*100)/2-1; %�Ӵ����
BasicWidth = 20;   %BasicTile���
UserNumber = 30;   %�û�����
frameGap = 30;     %֡�� 30fps
H = Height / BasicWidth; %���ж���BasicTile
W = Width / BasicWidth;  %���ж���BasicTile

for videoid =VideoIndex
    matData2 = load(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\LoadRawData\',num2str(frameGap),'_ShiftTile_Opt/' , num2str(videoid) , '.mat']);
    tilingMethod = matData2.Method;
    clusterNumber = matData2.clusterNumber;
    wasteRatio =  matData2.Performace;
    vid = sprintf('%03d', videoid);
    [~, totalseconds] = size(wasteRatio);
    clusterLst = matData2.clusterLst;
    [~, userNumber] = size(clusterLst);
    temp_Clus = [];
    temp_Shift = [];
    Bitrate_Shift = 0;
    Bitrate_Clus  = 0;
    Storage_Shift = 0;
    Storage_Clus = 0;
    
    for seconds = SecondIndex %��tʱ��Ԥ�� t+5ʱ�̣�Ȼ��ʣ�µĲ�ȫ
        %cluser_seconds_0
        %����storageSize
        %Clustile
        %Shifttile
        for c =1:6
            fname = ['outputVideo_Shift/',num2str(videoid),'/','out_',num2str(c),'_',num2str(seconds-1),'_0.mp4'];
            fid = fopen(fname);
            fseek(fid,0,'eof');
            fsize_Shift = ftell(fid);
            fsize_Shift = fsize_Shift / 1024;
            fsize_Shift =  fsize_Shift * 8;
            Storage_Shift =  Storage_Shift + fsize_Shift;
        end
        sss = load(['outputvideo_Clus\',num2str(videoid),'\',num2str(seconds-1),'\ServerStorageSize.txt']);
        Storage_Clus =    Storage_Clus + sss(1);
        
        
        
        %���￪ʼ������������
        for uN = 1:userNumber
           % try
                %����shifttile������
                c = clusterLst(seconds,uN) + 1; %shifttile�±��1��ʼ
                fname = ['outputVideo_Shift/',num2str(videoid),'/','out_',num2str(c),'_',num2str(seconds-1),'_0.mp4'];
                fid = fopen(fname);
                fseek(fid,0,'eof');
                fsize_Shift = ftell(fid);
                fsize_Shift = fsize_Shift / 1024;
                fsize_Shift =  fsize_Shift * 8;
                fclose(fid);
            
                %����clusttile������
                data = load(['outputvideo_Clus\',num2str(videoid),'\',num2str(seconds-1),'\',num2str(uN-1),'.txt']);
                [x, y] = size(data);
                fsize_Clus = 0;
                for i =1:1
                    fsize_Clus_temp = data(i,1); %�Ѿ�����1024 �˹�8��
                    fsize_Clus =   fsize_Clus_temp;
                end
                if fsize_Clus>100000 || fsize_Clus<=300
                    continue
                end
                temp_Shift = [temp_Shift,fsize_Shift];
                temp_Clus = [temp_Clus,fsize_Clus];
                Bitrate_Clus = Bitrate_Clus + fsize_Clus;
                Bitrate_Shift = Bitrate_Shift + fsize_Shift;
%             catch
%                 continue
%             end
        end
        
 
        
        
        
    end
    
end


round(Bitrate_Clus)
round(Bitrate_Shift)
(Bitrate_Clus -  Bitrate_Shift) / Bitrate_Clus

abs(round(Storage_Shift)-round(Storage_Clus))/round(Storage_Clus)




bar([Bitrate_Shift,Bitrate_Clus]/359)
set(gca,'xticklabel',{'ShiftTile','ClusTile'})
xlabel('method')
ylabel('Bitrate(kbps)')

bar([Storage_Shift,Storage_Clus])
set(gca,'xticklabel',{'ShiftTile','ClusTile'})
xlabel('method')
ylabel('Storage(kb)')












