
function Run_Compare_Robust_Grid(clusterLst,Gap_Width,Gap_Height,tilingMethod,clusterNumber,videoid,seconds)

seconds
try
    predictViewPort_raw = uint8(cell2mat(struct2cell(load(['OutputViewportPred/',num2str(videoid),'/',num2str(seconds-1),'_PredictViewport_CY.mat']))));
    realViewPort_raw = uint8(cell2mat(struct2cell(load(['OutputViewportReal/',num2str(videoid),'/',num2str(seconds-1),'_RealViewport.mat']))));
catch
    return
end
if isstruct( realViewPort_raw )
    realViewPort_raw = uint8(realViewPort_raw.RealViewport);
end
Shift_Robust = uint8(cell2mat(struct2cell(load(['OutputViewportPred/',num2str(videoid),'/',num2str(seconds-1),'_ShiftRobust_CY.mat']))));
Shift_Robust_6_12 = uint8(cell2mat(struct2cell(load(['OutputViewportPred/',num2str(videoid),'/',num2str(seconds-1),'_ShiftRobust_6_12_CY.mat']))));
Clus_Robust = uint8(cell2mat(struct2cell(load(['OutputViewportPred/',num2str(videoid),'/',num2str(seconds-1),'_ClusRobust_CY.mat']))));
bestMatchingUser = uint8(cell2mat(struct2cell(load(['OutputViewportPred/',num2str(videoid),'/',num2str(seconds-1),'_Best_MatchUser.mat']))));
Grid_6_12 = uint8(cell2mat(struct2cell(load(['OutputViewportPred/',num2str(videoid),'/',num2str(seconds-1),'_6_12_CY.mat']))));
seconds
%���￪ʼ������������,д������������һ��PSNR�Ĳ��
X_BandWidth_Shift = [];
X_BandWidth_Clus = [];
Y_PSNR_Shift = [];
Y_PSNR_Clus =[];
X_BandWidth_Grid = [];
Y_PSNR_Grid = [];
target = 10;
for uN = UserIndex
    uN
    %try
        %����shifttile������
        bs = 0;
        bc = 0;
        %co = clusterLst(seconds,uN) + 1; %shifttile�±��1��ʼ
        predictViewPort = uint8(zeros(30,72,144));
        realViewPort = uint8(zeros(30,72,144));
        for f = 1:30
            predictViewPort(f,:,:) = reshape(predictViewPort_raw(uN,f,:,:),[72,144]);
            realViewPort(f,:,:) = reshape(realViewPort_raw(uN,f,:,:),[72,144]);
        end
        
        %���Ȼ�ȡ����ǰs��ȡ��Ԥ���ӵ㣬��������ʵ���û��ӵ㸲�Ǿ���
        %     B_sec_Predict = predictViewPort;
        %     %����ǰʱ�̸��Ǿ�����������Ƶ�ѡ��,��select_cluster���������зֹ����û��ӵ㸲�Ǿ���
        %     B_sec = reshape(tilingMethod(seconds,:,:,:,:),[clusterNumber(seconds),30,72,144]);
        %     max_cover = -1;
        if iscell(clusterLst)
            select_cluster = uint8(clusterLst{seconds}(bestMatchingUser(1,uN))) + 1;
        else
            select_cluster = uint8(clusterLst(seconds,bestMatchingUser(1,uN))) + 1;
        end
        %��͵�ǰs��ʵ�ӵ�Ĳ���
        fname = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\BaseVideo_qp42\out_',num2str(videoid),'_XX30_',num2str(seconds-1),'_base_0.mp4'];
        if ~exist(fname)
            mkdir(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\BaseVideo_qp42']);
            command = ['ffmpeg -r 30 -i H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4',...
                ' -r 30 -an -c:v libx264 -qp ',num2str(42),' -g 30 -f segment ',...
                '-segment_list H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\BaseVideo_qp42\out_',num2str(videoid),'_XX30_',num2str(seconds-1),'_base.m3u8 ','-segment_time 1 ',...
                'H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\BaseVideo_qp42\out_',num2str(videoid),'_XX30_',num2str(seconds-1),'_base_%d.mp4']
            system(command)
        end
        video_baseLayer = VideoReader(fname);
        Height = video_baseLayer.Height;
        Width = video_baseLayer.Width;
        H = Height;
        W = Width;
        Gap_Height = floor(Height / 15);
        Gap_Width = floor(Width / 30);
        fid = fopen(fname);
        fseek(fid,0,'eof');
        fsize_base = ftell(fid);
        fsize_base = fsize_base / 1024;
        fsize_base =  fsize_base * 8;
        fclose(fid);
        
        for qp =22:5:42
            fname = ['F:/outputVideoShift/',num2str(videoid),'/','out_',num2str(select_cluster),'_',num2str(seconds-1),'_',num2str(qp), '_0.mp4'];
            mkdir(['F:/outputVideoShift/',num2str(videoid),'/'])
            if ~exist(fname,'file')
                command = ['ffmpeg -r 30 -i F:/OutputFrameShiftTileOptimization/',num2str(videoid),'/',num2str(seconds-1),'/',num2str(select_cluster),'/%d.png ',...
                    '-r 30 -an -c:v libx264 -qp ',num2str(qp),' -g 30 -f segment ',...
                    '-segment_list F:/outputVideoShift/',num2str(videoid),'/out_',num2str(select_cluster),'_',num2str(seconds-1),'.m3u8 -segment_time 1 ',...
                    'F:/outputVideoShift/',num2str(videoid),'/out_',num2str(select_cluster),'_',num2str(seconds-1),'_',num2str(qp),'_%d.mp4']
                system(command)
                mkdir(['F:/OutputFrame_ShiftTileOptimization_AfterEncoded/',num2str(videoid),'/',num2str(seconds-1),'/',num2str(select_cluster),'/',num2str(qp),'/']);
                command = ['ffmpeg -i F:/outputVideoShift/',num2str(videoid),'/out_',num2str(select_cluster),'_',num2str(seconds-1),'_',num2str(qp),'_0.mp4 -r 30 -q:v 2 -f image2 ','F:/OutputFrame_ShiftTileOptimization_AfterEncoded/',num2str(videoid),'/',num2str(seconds-1),'/',num2str(select_cluster),'/',num2str(qp),'/','%d.png'];
                system(command);
            end
            fid = fopen(fname);
            fseek(fid,0,'eof');
            fsize_ShiftPredict = ftell(fid);
            fsize_ShiftPredict = fsize_ShiftPredict / 1024;
            fsize_ShiftPredict =  fsize_ShiftPredict * 8;
            fclose(fid);
            img_Shift = cell(30,1);
            img_Clus = cell(30,1);
            img_Grid = cell(30,1);
            for f = 1:30
                temp = uint8(rgb2gray(read(video_baseLayer,f)));
                img_Shift{f,1} = temp;
                img_Clus{f,1} = temp;
                img_Grid{f,1} = temp;
            end
            
            
            
            test_15_30= 0;
            test_6_12 = 0;
            %��ǿShifTile³����
            for i = 1:15
                for j = 1:30
                    if Shift_Robust(uN,i,j)==1
                        temp = [double(i-1)*Gap_Height,double(j-1)*Gap_Width,Gap_Height,Gap_Width];
                        fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        if ~exist(fname_i,'file')
                            mkdir(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\'])
                            command = ['ffmpeg -i H:\comparing-trajectory-clustering-methods-master',...
                                '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
                                num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                num2str(temp(1)),' H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            system(command)
                        end
                    end
                end
            end
            
            for i = 1:15
                for j = 1:30
                    if Shift_Robust(uN,i,j)==1
                        temp = [double(i-1)*Gap_Height,double(j-1)*Gap_Width,Gap_Height,Gap_Width];
                        fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        fid = fopen(fname_i);
                        fseek(fid,0,'eof');
                        fsize = ftell(fid);
                        fclose(fid);
                        fsize = fsize /1024;
                        fsize = fsize * 8;
                        fsize_ShiftPredict =  fsize_ShiftPredict + fsize/2;
                        test_15_30 = test_15_30 +fsize/2;
                        video_Shift = VideoReader(fname_i);
                        temp(1) = temp(1) + 1;
                        temp(2) = temp(2) + 1;
                        for f = 1:30
                            frame = uint8(rgb2gray(read(video_Shift, f)));
                            img_Shift{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                        end
                    end
                end
            end

            
            
            %������
            for i = 1:6
                for j = 1:12
                    if Grid_6_12(uN,i,j)==1
                        Gap_H = floor(H/6);
                        if mod(Gap_H,2)~=0
                            Gap_H = Gap_H -1;
                        end
                        Gap_W = floor(W/12);
                        if mod(Gap_W,2)~=0
                            Gap_W = Gap_W -1;
                        end
                        temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
                        fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        if ~exist(fname_i,'file')
                            mkdir(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\'])
                            command = ['ffmpeg -i H:\comparing-trajectory-clustering-methods-master',...
                                '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
                                num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                num2str(temp(1)),' H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            system(command)
                        end
                    end
                end
            end
            
            test_6_12 = 0;
            for i = 1:6
                for j = 1:12
                    if Grid_6_12(uN,i,j)==1
                        % try
                        Gap_H = floor(H/6);
                        if mod(Gap_H,2)~=0
                            Gap_H = Gap_H -1;
                        end
                        Gap_W = floor(W/12);
                        if mod(Gap_W,2)~=0
                            Gap_W = Gap_W -1;
                        end
                        temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
                        fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        fid = fopen(fname_i);
                        fseek(fid,0,'eof');
                        fsize = ftell(fid);
                        fclose(fid);
                        fsize = fsize /1024;
                        fsize = fsize * 8;
                        test_6_12 = test_6_12 + fsize;
                        video_Shift = VideoReader(fname_i);
                        temp(1) = temp(1) + 1;
                        temp(2) = temp(2) + 1;
                        for f = 1:30
                            frame = uint8(rgb2gray(read(video_Shift, f)));
                            img_Grid{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                        end
                        %                     catch
                        %                         continue
                        %                     end
                    end
                end
            end
            
            
            
            tic
            for f = 1:30
                path = ['F:/OutputFrame_ShiftTileOptimization_AfterEncoded/',num2str(videoid),'/',num2str(seconds-1),'/',num2str(select_cluster)];
                temp = rgb2gray(uint8(imread([path, '/',num2str(qp),'/' ,num2str(f), '.png'])));
                temp_raw = rgb2gray(uint8(imread(['F:/OutputFrameShiftTileOptimization/',num2str(videoid),'/',num2str(seconds-1),'/',num2str(select_cluster), '/' ,num2str(f),'.png'])));
                temp_l = uint8(temp_raw==0);
                img_Shift{f,1} = img_Shift{f,1}.* temp_l;
                img_Shift{f,1} = img_Shift{f,1} + temp;
            end
            toc
            
            %����clusttile������
            data_old = load(['outputvideoClus\',num2str(videoid),'\',num2str(seconds-1),'\',num2str(uN),'_old.txt']);
            [x, y] = size(data_old);
            exit_flag = 0;
            fsize_ClusPredict = 0;
            
            for i =1:x
                if (data_old(i,3)>=30)
                    data_old(i,3) = data_old(i,3) -30;
                    data_old(i,4) = data_old(i,4) -30;
                end
            end
            
            for i =1:x
                temp = [double(data_old(i,1))*Gap_Height,double(data_old(i,3))*Gap_Width,double(data_old(i,2)-data_old(i,1)+1)*Gap_Height,double(data_old(i,4)-data_old(i,3)+1)*Gap_Width];
                fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                if ~exist(fname_i,'file')
                    mkdir(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\'])
                    command = ['ffmpeg -i H:\comparing-trajectory-clustering-methods-master',...
                        '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
                        num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                        num2str(temp(1)),' H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                    system(command)
                end
            end
            
            for i =1:x
                temp = [double(data_old(i,1))*Gap_Height,double(data_old(i,3))*Gap_Width,double(data_old(i,2)-data_old(i,1)+1)*Gap_Height,double(data_old(i,4)-data_old(i,3)+1)*Gap_Width];
                fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                fid = fopen(fname_i);
                fseek(fid,0,'eof');
                fsize = ftell(fid);
                fclose(fid);
                fsize = fsize /1024;
                fsize = fsize*8;
                fsize_ClusPredict =  fsize_ClusPredict + fsize;
                video_Clus = VideoReader(fname_i);
                temp(1) = temp(1) + 1;
                temp(2) = temp(2) + 1;
                for f = 1:30
                    frame = uint8(rgb2gray(read(video_Clus, f)));
                    img_Clus{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                end
            end
            
            %��ǿClusTile³����
            for i = 1:15
                for j = 1:30
                    if Clus_Robust(uN,i,j)==1
                        temp = [double(i-1)*Gap_Height,double(j-1)*Gap_Width,Gap_Height,Gap_Width];
                        fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        if ~exist(fname_i,'file')
                            mkdir(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\'])
                            command = ['ffmpeg -i E:\comparing-trajectory-clustering-methods-master',...
                                '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
                                num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                num2str(temp(1)),' H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            system(command)
                        end
                    end
                end
            end
            
            for i = 1:15
                for j = 1:30
                    if Clus_Robust(uN,i,j)==1
                        temp = [double(i-1)*Gap_Height,double(j-1)*Gap_Width,Gap_Height,Gap_Width];
                        fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        fid = fopen(fname_i);
                        fseek(fid,0,'eof');
                        fsize = ftell(fid);
                        fclose(fid);
                        fsize = fsize /1024;
                        fsize = fsize*8;
                        fsize_ClusPredict =  fsize_ClusPredict + fsize;
                        video_Clus = VideoReader(fname_i);
                        temp(1) = temp(1) + 1;
                        temp(2) = temp(2) + 1;
                        for f = 1:30
                            frame = uint8(rgb2gray(read(video_Clus, f)));
                            img_Clus{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                        end
                    end
                end
            end
            
            if fsize_ClusPredict>1000000 || fsize_ClusPredict<=50
                continue
            end
            
            video_raw = VideoReader(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4']);
            %video_raw = VideoReader(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\ShiftSourceVideo\out_',num2str(videoid),'_XX30_',num2str(0),'.mp4']);
            img_raw = cell(30,1);
            for f = 1:30
                img_raw{f,1}=uint8(rgb2gray(read(video_raw, f)));
            end
            MSE_Shift = 0;
            MSE_Clus = 0;
            MSE_Grid = 0;
            p1 = [];
            s = [];
            p2 = [];
            c = [];
            p3 = [];
            ;
            for f = 1:30
                temp =  reshape(realViewPort(f,:,:),[72,144]);
                [h,w,~] = size(img_raw{f,1});
                v = zeros(h,w);
                gh = h /72; gw = w/144;
                for i = 1:72
                    for j = 1:144
                        if temp(i,j)==1
                            v(ceil((i-1)*gh +1):ceil(i*gh),ceil((j-1)*gw +1):ceil(j*gw)) = 1;
                        end
                    end
                end
                [p, temp_shift] = Psnr(img_raw{f,1},img_Shift{f,1},v);
                [pp, temp_clus] = Psnr(img_raw{f,1},img_Clus{f,1},v);
                [ppp, temp_grid] = Psnr(img_raw{f,1},img_Grid{f,1},v);
                p1 =[p1,p];
                p2 = [p2,pp];
                p3 = [p3,ppp];
                s = [s,temp_shift];
                c = [c, temp_clus];
                MSE_Shift = MSE_Shift + temp_shift;
                MSE_Clus = MSE_Clus + temp_clus;
                MSE_Grid = MSE_Grid + temp_grid;
            end
            
            psnr_Shift = 10*log10(255^2 / (MSE_Shift/30));
            psnr_Clus = 10*log10(255^2 / (MSE_Clus/30));
            psnr_Grid = 10*log10(255^2 / (MSE_Grid/30));
            %Debug = [Debug;double(seconds),double(uN),double(select_cluster),double(max_cover), double(c) ,double(cover_ratio)];
            
            X_BandWidth_Shift = [X_BandWidth_Shift,fsize_ShiftPredict+fsize_base];
            X_BandWidth_Clus = [X_BandWidth_Clus,fsize_ClusPredict+fsize_base];
            X_BandWidth_Grid = [X_BandWidth_Grid,test_6_12+fsize_base];
            Y_PSNR_Shift = [Y_PSNR_Shift,psnr_Shift];
            Y_PSNR_Clus =[Y_PSNR_Clus,psnr_Clus];
            Y_PSNR_Grid = [Y_PSNR_Grid,psnr_Grid];
        end
%     catch
%         continue
%     end
end


mkdir(['ComprateBitrateAllocation/',num2str(videoid),'/'])
save(['ComprateBitrateAllocation/',num2str(videoid),'/',num2str(seconds-1),'_XShift.mat'],'X_BandWidth_Shift')
save(['ComprateBitrateAllocation/',num2str(videoid),'/',num2str(seconds-1),'_YShift.mat'],'Y_PSNR_Shift')
save(['ComprateBitrateAllocation/',num2str(videoid),'/',num2str(seconds-1),'_XClus.mat'],'X_BandWidth_Clus')
save(['ComprateBitrateAllocation/',num2str(videoid),'/',num2str(seconds-1),'_YClus.mat'],'Y_PSNR_Clus')
save(['ComprateBitrateAllocation/',num2str(videoid),'/',num2str(seconds-1),'_XGrid.mat'],'X_BandWidth_Grid')
save(['ComprateBitrateAllocation/',num2str(videoid),'/',num2str(seconds-1),'_YGrid.mat'],'Y_PSNR_Grid')
end

function [PSNR, MSE] = Psnr(X, Y, V)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% �����ֵ�����PSNR
% ��RGBת��YCbCr��ʽ���м���
% ���ֱ�Ӽ�����ת�����ֵҪС2dB���ң���Ȼ�Ǹ�����ԣ�
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(X,3)~=1   %�ж�ͼ��ʱ���ǲ�ɫͼ������ǣ����Ϊ3������Ϊ1
    org=rgb2ycbcr(X);
    test=rgb2ycbcr(Y);
    Y1=org(:,:,1);
    Y2=test(:,:,1);
    Y1=double(Y1);  %����ƽ��ʱ����Ҫת��double���ͣ�����uchar���ͻᶪʧ����
    Y2=double(Y2);
else              %�Ҷ�ͼ�񣬲���ת��
    Y1=double(X);
    Y2=double(Y);
end
Y1 = Y1.*V;
Y2 = Y2.*V;
if nargin<2
    D = Y1;
else
    if any(size(Y1)~=size(Y2))
        error('The input size is not equal to each other!');
    end
    D = Y1 - Y2;
end
MSE = sum(D(:).*D(:)) / sum(sum(V>0));
PSNR = 10*log10(255^2 / MSE);
end

function de()
Y = load(['ComprateBitrateAllocation/',num2str(videoid),'/',num2str(seconds-1),'_YShift.mat']);
Y = Y.Y_PSNR_Shift
end

