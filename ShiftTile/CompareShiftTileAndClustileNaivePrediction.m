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
vs = 1;             %��Ƶ��ʼid
ve = 1;             %��Ƶ����id
Gap_Width = 126;
Gap_Height = 126;

for videoid = VideoIndex
    matData2 = load(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\LoadRawData\',num2str(frameGap),'_ShiftTile_Opt/' , num2str(videoid) , '.mat']);
    %��3d���ݴ���Ϊ2d���ݣ������
    
    tilingMethod = matData2.Method;
    clusterNumber = matData2.clusterNumber;
    wasteRatio =  matData2.Performace;
    viewPoint = matData2.Method_Peruser;
    vid = sprintf('%03d', videoid);
    [~, totalseconds] = size(wasteRatio);
    clusterLst = matData2.clusterLst;
    [~, userNumber] = size(clusterLst);
    temp_Clus = [];
    temp_ClusPredict = [];
    temp_Shift = [];
    temp_ShiftPredict = [];
    Debug = [];
    Bitrate_Shift = 0;
    Bitrate_Clus  = 0;
    Storage_Shift = 0;
    Storage_Clus = 0;
    basic_Shift = [];
    basic_Clus = [];
    for seconds = SecondIndex %��tʱ��Ԥ�� [t+3,t+4)ʱ�̣�Ȼ��ʣ�µĲ�ȫ
        %cluser_seconds_0
        %����storageSize
        
        %����Shifttile��Server�洢
        %         for c =1:6
        %             fname = ['outputVideoShift/',num2str(videoid),'/','out_',num2str(c),'_',num2str(seconds-1),'_0.mp4'];
        %             fid = fopen(fname);
        %             fseek(fid,0,'eof');
        %             fsize_Shift = ftell(fid);
        %             fsize_Shift = fsize_Shift / 1024;
        %             fsize_Shift =  fsize_Shift * 8;
        %             Storage_Shift =  Storage_Shift + fsize_Shift;
        %         end
        %
        %         %����Clustile��Server�洢
        %         sss = load(['outputvideoClus\',num2str(videoid),'\',num2str(seconds-1),'\ServerStorageSize.txt']);
        %         Storage_Clus = Storage_Clus + sss(1);
        %
        %         Storage_Basic = 0;
        %         for r = 1:15
        %             for c = 1:30
        %                     fname_i = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str((r-1)*Gap_Height),'_',num2str((c-1)*Gap_Width),'_',num2str((r-r+1)*Gap_Height),'_',num2str((c-c+1)*Gap_Width),'.mp4'];
        %                     fid = fopen(fname_i);
        %                     fseek(fid,0,'eof');
        %                     fsize = ftell(fid);
        %                     fclose(fid);
        %                     fsize = fsize /1024;
        %                     fsize = fsize*8;
        %                     Storage_Basic = Storage_Basic + fsize;
        %             end
        %         end
        %         Storage_Clus = Storage_Clus + Storage_Basic;
        %         Storage_Shift = Storage_Shift + Storage_Basic;
        seconds
        %���￪ʼ������������,д������������һ��PSNR�Ĳ��
        for uN = UserIndex
            uN
            % try
            %����shifttile������
            bs = 0;
            bc = 0;
            co = clusterLst(seconds,uN) + 1; %shifttile�±��1��ʼ
            %���Ȼ�ȡsec-3ʱ�̵���ʵ�ӵ������������ʵ���û��ӵ㸲�Ǿ���
            B_real_sec_backward_3 = reshape(viewPoint(seconds-3,uN,:,:,:),[30,72,144]);
            B_real_sec = reshape(viewPoint(seconds,uN,:,:,:),[30,72,144]);
            %����ǰʱ�̸��Ǿ�����������Ƶ�ѡ��,��select_cluster���������зֹ����û��ӵ㸲�Ǿ���
            B_sec = reshape(tilingMethod(seconds,:,:,:,:),[clusterNumber(seconds),30,72,144]);
            max_cover = -1;
            select_cluster = 1;
            %����ʵ�ӵ�����Ĳ���
            for i = 1:clusterNumber(seconds)
                cover_cont = 0;
                total_cont = 0;
                for f = 1:30
                    temp1 = reshape(B_sec(i,f,:,:),[72,144]);
                    temp2 = reshape(B_real_sec_backward_3(f,:,:),[72,144]);
                    temp = temp1 .* temp2;
                    cover_cont = cover_cont + sum(sum(temp));
                    total_cont = total_cont + sum(sum(temp2));
                end
                cover_ratio = cover_cont / total_cont;
                if cover_ratio > max_cover
                    max_cover = cover_ratio;
                    select_cluster = i;
                end
            end
            %-----------------------------------------����������Debug������3s�������û��ӵ�͵�ǰs��������֮��Ľ������ǰٷֱ�,shftTile
            cover_cont = 0;
            total_cont = 0;
            for f = 1:30
                temp1 = reshape(B_sec(co,f,:,:),[72,144]);
                temp2 = reshape(B_real_sec_backward_3(f,:,:),[72,144]);
                temp = temp1 .* temp2;
                cover_cont = cover_cont + sum(sum(temp));
                total_cont = total_cont + sum(sum(temp2));
            end
            cover_ratio = cover_cont / total_cont;
            %-----------------------------------------����������Debug������3s�������û��ӵ�͵�ǰs��������֮��Ľ������ǰٷֱ�,shftTile
            
            
            %-----------------------------------------����������Debug�����㵱ǰs�����û��ӵ�͵�ǰs��ѡ���֮��Ľ�������������,shftTile
            cover_cont = 0;
            total_cont = 0;
            for f = 1:30
                temp1 = reshape(B_sec(select_cluster,f,:,:),[72,144]);
                temp2 = reshape(B_real_sec(f,:,:),[72,144]);
                temp = temp1 .* temp2;
                cover_cont = cover_cont + sum(sum(temp));
                total_cont = total_cont + sum(sum(temp1));
            end
            total_cont_shift =  total_cont;
            cover_cont_shift = cover_cont;
            cover_ratio_shift_select = cover_cont / total_cont;
            %-----------------------------------------����������Debug�����㵱ǰs�����û��ӵ�͵�ǰs��ѡ���֮��Ľ�������������,shftTile
            %��͵�ǰs��ʵ�ӵ�Ĳ���
            
            temp_C = zeros(72,144);
            temp_CC = zeros(72,144);  %�����Ĳ��������Լ�
            select_sec = reshape(B_sec(select_cluster,:,:,:),[30,72,144]);
            for f = 1:30
                temp1 = reshape(B_real_sec(f,:,:),[72,144]);
                temp2 = reshape(select_sec(f,:,:),[72,144]);
                temp_C =temp_C | (temp1>temp2);
                temp_CC = temp_CC + temp2;
            end
            
            fname = ['outputVideoShift/',num2str(videoid),'/','out_',num2str(select_cluster),'_',num2str(seconds-1),'_0.mp4'];
            fid = fopen(fname);
            fseek(fid,0,'eof');
            fsize_Shift = ftell(fid);
            fsize_Shift = fsize_Shift / 1024;
            fsize_Shift =  fsize_Shift * 8;
            fclose(fid);
            fsize_ShiftPerfect = fsize_Shift;
            
            
            %���������򲹵Ŀ�
            clus_C = zeros(15,30);
            for i = 1:72
                for j = 1:144
                    if (temp_C(i,j)==1)
                        clus_C(ceil(i*(15.0/72)),ceil(j*(30.0/144))) = 1;
                    end
                end
            end
            %test = zeros(15,30);
%             img = zeros(1440,2880);
%             for i = 1:72
%                 for j =1:144
%                     if(temp_C(i,j)==1)
%                         img((i-1)*20+1:i*20,(j-1)*20+1:j*20) = 1;
%                     end
%                 end
%             end
%             for i = 1:15
%                 for j = 1:30
%                     temp = img((i-1)*96+1:i*96,(j-1)*96+1:j*96);
%                     if sum(sum(temp>0))>0
%                         clus_C(i,j) = 1;
%                     end
%                 end
%             end
            %������ֱ�Ӵ�shifttile���ʻ��Ǵ�basictile����
            fsize_shift_basic_temp = 0;
            for r = 1:15
                for c = 1:30
                    if (clus_C(r,c)==1)
                        fname_i = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str((r-1)*Gap_Height),'_',num2str((c-1)*Gap_Width),'_',num2str((r-r+1)*Gap_Height),'_',num2str((c-c+1)*Gap_Width),'.mp4'];
                        fid = fopen(fname_i);
                        fseek(fid,0,'eof');
                        fsize = ftell(fid);
                        fclose(fid);
                        fsize = fsize /1024;
                        fsize = fsize*8;
                        fsize_shift_basic_temp  = fsize_shift_basic_temp + fsize;
                    end
                end
            end
            
            fname = ['outputVideoShift/',num2str(videoid),'/','out_',num2str(co),'_',num2str(seconds-1),'_0.mp4'];
            fid = fopen(fname);
            fseek(fid,0,'eof');
            fsize_shift_temp = ftell(fid);
            fsize_shift_temp = fsize_shift_temp / 1024;
            fsize_shift_temp =  fsize_shift_temp * 8;
            fclose(fid);
            if fsize_shift_temp > fsize_shift_basic_temp
                fsize_Shift = fsize_Shift + fsize_shift_basic_temp;
                bs = bs + fsize_shift_basic_temp; 
            else
                fsize_Shift = fsize_Shift + fsize_shift_temp;
                select_sec = reshape(B_sec(co,:,:,:),[30,72,144]);
                temp_C(temp_C==1) = 0;
                for f = 1:30
                    temp2 = reshape(select_sec(f,:,:),[72,144]);
                    temp_CC = temp_CC + temp2;
                end
            end
            
            
            %�����Ŀ��δ���Ŀ���������ɫ
            mkdir('Debug\ShiftDistribution\')
            debug_img_Shift = uint8(zeros(72,144,3));
            for i = 1:72
                for j = 1:144
                    if temp_CC(i,j)>=1
                        debug_img_Shift(i,j,1)= uint8(temp_CC(i,j)/60*255);
                        debug_img_Shift(i,j,2)= uint8(temp_CC(i,j)/60*255);
                        debug_img_Shift(i,j,3)= uint8(temp_CC(i,j)/60*255);
                    end
                    if temp_C(i,j)==1
                        debug_img_Shift(i,j,1)= 0;
                        debug_img_Shift(i,j,3)= 255;
                        debug_img_Shift(i,j,2)= 0;
                    end
                end
            end
            imwrite(debug_img_Shift,['Debug\ShiftDistribution\',num2str(seconds),'_',num2str(uN),'.png']);
            
            
            
            
            %�����Ŀ��δ���Ŀ���������ɫ
            mkdir('Debug\ClusDistribution\')
            debug_img_Clus = uint8(zeros(15,30,3));
            cover_Clus = zeros(15,30);
            %����clusttile������
            data_old = load(['outputvideoClus\',num2str(videoid),'\',num2str(seconds-1),'\',num2str(uN-1),'_old.txt']);
            [x, y] = size(data_old);
            exit_flag = 0;
            fsize_ClusPredict = 0;
            for i =1:x
                if (data_old(i,3)>30 || data_old(i,4)>30)
                    exit_flag = 1;
                    break;
                end
                temp=[double(data_old(i,1)-1)*Gap_Height,double(data_old(i,3)-1)*Gap_Width,double(data_old(i,2)-data_old(i,1)+1)*Gap_Height,double(data_old(i,4)-data_old(i,3)+1)*Gap_Width];
                fname_i = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'];
                fid = fopen(fname_i);
                fseek(fid,0,'eof');
                fsize = ftell(fid);
                fclose(fid);
                fsize = fsize /1024;
                fsize = fsize*8;
                fsize_ClusPredict =  fsize_ClusPredict + fsize;
                debug_img_Clus(data_old(i,1):data_old(i,2),data_old(i,3):data_old(i,4),1)= 255;
                debug_img_Clus(data_old(i,1):data_old(i,2),data_old(i,3):data_old(i,4),2)= 255;
                debug_img_Clus(data_old(i,1):data_old(i,2),data_old(i,3):data_old(i,4),3)= 255;
                cover_Clus(data_old(i,1):data_old(i,2),data_old(i,3):data_old(i,4)) = cover_Clus(data_old(i,1):data_old(i,2),data_old(i,3):data_old(i,4)) + 1;
            end
            %-----------------------------------------����������Debug�����㵱ǰs�����û��ӵ�͵�ǰs��ѡ���֮��Ľ������ǰٷֱ�,clustile
            temp1 = zeros(72,144);
            for i = 1:72
                for j = 1:144
                    if cover_Clus(ceil(i*(15.0/72)),ceil(j*(30.0/144))) >= 1
                        temp1(i,j) = cover_Clus(ceil(i*(15.0/72)),ceil(j*(30.0/144)));
                    end
                end
            end
            cover_cont = 0;
            total_cont = 0;
            for f = 1:30
                temp2 = reshape(B_real_sec(f,:,:),[72,144]);
                temp = temp1 & temp2;
                cover_cont = cover_cont + sum(sum(temp));
                total_cont = total_cont + sum(sum(temp1));
            end
            total_cont_clus =  total_cont;
            cover_cont_clus = cover_cont;
            cover_ratio_clus_select = cover_cont / total_cont;
            %-----------------------------------------����������Debug�����㵱ǰs�����û��ӵ�͵�ǰs��ѡ���֮��Ľ������ǰٷֱ�,shftTile
            %                 if(data(i,5)==0)
            %                     bc =  bc + fsize;
            %                 end
            data_new = load(['outputvideoClus\',num2str(videoid),'\',num2str(seconds-1),'\',num2str(uN-1),'_new.txt']);
            [x, y] = size(data_new);
            for i = 1:x
                if (data_new(i,3)>30 || data_new(i,4)>30)
                    exit_flag = 1;
                    break;
                end
                temp=[double(data_new(i,1)-1)*Gap_Height,double(data_new(i,3)-1)*Gap_Width,double(data_new(i,2)-data_new(i,1)+1)*Gap_Height,double(data_new(i,4)-data_new(i,3)+1)*Gap_Width];
                fname_i = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'];
                fid = fopen(fname_i);
                fseek(fid,0,'eof');
                fsize = ftell(fid);
                fclose(fid);
                fsize = fsize /1024;
                fsize = fsize*8;
                fsize_ClusPredict = fsize_ClusPredict + fsize;
                debug_img_Clus(data_new(i,1):data_new(i,2),data_new(i,3):data_new(i,4),1)= 0;
                debug_img_Clus(data_new(i,1):data_new(i,2),data_new(i,3):data_new(i,4),3)= 255;
                debug_img_Clus(data_new(i,1):data_new(i,2),data_new(i,3):data_new(i,4),2)= 0;
                cover_Clus(data_new(i,1):data_new(i,2),data_new(i,3):data_new(i,4)) = cover_Clus(data_new(i,1):data_new(i,2),data_new(i,3):data_new(i,4)) + 1;
            end
          
            debug_img_Clus = imresize(debug_img_Clus,[72,144]);
            
            if fsize_ClusPredict>100000 || fsize_ClusPredict<=300 || exit_flag==1 ||(seconds==6)||(seconds==9)
                continue
            end
            
            Debug = [Debug;double(seconds-1),double(uN-1),double(select_cluster-1),double(max_cover), double(co-1) ,double(cover_ratio),cover_ratio_shift_select,cover_ratio_clus_select,(-fsize_Shift + fsize_ClusPredict)/fsize_ClusPredict,total_cont_clus,total_cont_shift,cover_cont_clus,cover_cont_shift];
            temp_ShiftPredict = [temp_ShiftPredict,fsize_Shift];
            temp_Shift = [temp_Shift,fsize_ShiftPerfect];
            temp_ClusPredict = [temp_ClusPredict,fsize_ClusPredict];
            basic_Shift = [basic_Shift, bs];
            basic_Clus = [basic_Clus, bc];
            imwrite(debug_img_Clus,['Debug\ClusDistribution\',num2str(seconds),'_',num2str(uN),'.png']);
            %             catch
            %                 continue
            %             end
        end
        
        
        
        
        
    end
    
end
figure
[x, y] = size(Debug);
for i = 1:x
    hold on 
    plot(Debug(i,7)-Debug(i,8),Debug(i,9),'r*')
end


sum(temp_ShiftPredict)
sum(temp_Shift)
sum(temp_ClusPredict)
sum(basic_Shift)
sum(basic_Clus)

% plot(temp_ShiftPredict,'r-')
% hold on
% plot(temp_Shift,'r-')
% sum(temp_ShiftPredict)
% sum(temp_ClusPredict)
% sum(temp_Shift)

% round(Bitrate_Clus)
% round(Bitrate_Shift)
% (Bitrate_Clus -  Bitrate_Shift) / Bitrate_Clus
% abs(round(Storage_Shift)-round(Storage_Clus)) / round(Storage_Clus)
%
%
%
%
figure
bar([sum(temp_ShiftPredict), sum(temp_ClusPredict)]/140)
set(gca,'xticklabel',{'ShiftTile','ClusTile'})
xlabel('method')
ylabel('Bitrate(kbps)')

figure
bar([5.2e+04,6.2e+04])
set(gca,'xticklabel',{'ShiftTile','ClusTile'})
xlabel('method')
ylabel('Storage(kb)')












